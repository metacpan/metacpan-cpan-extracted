package Peta::NN::Backend::WebGPU;
# ABSTRACT: Peta::NN on the graphics card

# The GPU backend: a tensor is [ $buffer, $rows, $cols ], a storage buffer of
# 32-bit floats on the card, and every operation is one compute shader
# dispatched over it. Tensors stay on the card between operations; only
# flat() and the per-batch loss cross the bus.
#
# 32-bit floats are all WGSL has, so results agree with the plain backend to
# about six digits, not to rounding.

use v5.36;

use Peta::WebGPU;

use parent -norequire, 'Peta::NN::Backend';
use Peta::NN::Backend;

our $VERSION = '0.2610090';

my $FLOAT_BYTES = 4;
my $GROUP_1D    = 64;    # must match @workgroup_size in the 1D shaders
my $GROUP_2D    = 8;     # and in the 2D ones

# Every shader sees the same parameter block: eight integers, eight floats.
my $PARAMS = <<'WGSL';
struct Params { n0: u32, n1: u32, n2: u32, n3: u32, n4: u32, n5: u32, n6: u32, n7: u32,
                f0: f32, f1: f32, f2: f32, f3: f32, f4: f32, f5: f32, f6: f32, f7: f32 }
WGSL

my %KIND_CODE = (relu => 0, tanh => 1, sigmoid => 2);

# name => [ bindings ("r" read-only floats, "w" read-write floats, "u" read-only
# unsigned), body ]. The parameter block is always the last binding, as `p`.
my %SHADER = (

    # y[s][j] = b[j] + sum_i w[j][i] x[s][i]          n0 n_in, n1 n_out, n2 batch
    # An invocation computes four outputs of one sample, so the sample's row
    # is read once for the four.
    affine => [ [qw(r:x r:w r:b w:y)], 2, <<'WGSL' ],
    let j = id.x * 4u; let s = id.y;
    if (j >= p.n1 || s >= p.n2) { return; }
    let xa = s * p.n0;
    var acc = vec4<f32>(0.0);
    for (var i = 0u; i < p.n0; i++) {
        acc += vec4<f32>(w[j * p.n0 + i], w[(j + 1u) * p.n0 + i], w[(j + 2u) * p.n0 + i], w[(j + 3u) * p.n0 + i]) * x[xa + i];
    }
    y[s * p.n1 + j] = b[j] + acc.x;
    if (j + 1u < p.n1) { y[s * p.n1 + j + 1u] = b[j + 1u] + acc.y; }
    if (j + 2u < p.n1) { y[s * p.n1 + j + 2u] = b[j + 2u] + acc.z; }
    if (j + 3u < p.n1) { y[s * p.n1 + j + 3u] = b[j + 3u] + acc.w; }
WGSL

    # gw[j][i] = sum_s dy[s][j] x[s][i], four samples at a time
    affine_gw => [ [qw(r:x r:dy w:gw)], 2, <<'WGSL' ],
    let i = id.x; let j = id.y;
    if (i >= p.n0 || j >= p.n1) { return; }
    var acc = vec4<f32>(0.0);
    let whole = (p.n2 / 4u) * 4u;
    for (var s = 0u; s < whole; s += 4u) {
        acc += vec4<f32>(dy[s * p.n1 + j], dy[(s + 1u) * p.n1 + j], dy[(s + 2u) * p.n1 + j], dy[(s + 3u) * p.n1 + j])
             * vec4<f32>(x[s * p.n0 + i], x[(s + 1u) * p.n0 + i], x[(s + 2u) * p.n0 + i], x[(s + 3u) * p.n0 + i]);
    }
    var sum = acc.x + acc.y + acc.z + acc.w;
    for (var s = whole; s < p.n2; s++) { sum += dy[s * p.n1 + j] * x[s * p.n0 + i]; }
    gw[j * p.n0 + i] = sum;
WGSL

    # gb[j] = sum_s dy[s][j]
    affine_gb => [ [qw(r:dy w:gb)], 1, <<'WGSL' ],
    let j = id.x;
    if (j >= p.n1) { return; }
    var sum = 0.0;
    for (var s = 0u; s < p.n2; s++) { sum += dy[s * p.n1 + j]; }
    gb[j] = sum;
WGSL

    # dx[s][i] = sum_j w[j][i] dy[s][j]
    affine_dx => [ [qw(r:dy r:w w:dx)], 2, <<'WGSL' ],
    let i = id.x; let s = id.y;
    if (i >= p.n0 || s >= p.n2) { return; }
    var sum = 0.0;
    for (var j = 0u; j < p.n1; j++) { sum += w[j * p.n0 + i] * dy[s * p.n1 + j]; }
    dx[s * p.n0 + i] = sum;
WGSL

    # n0 elements, n1 the activation: 0 relu, 1 tanh, 2 sigmoid
    activate => [ [qw(r:x w:y)], 1, <<'WGSL' ],
    let i = id.x;
    if (i >= p.n0) { return; }
    let v = x[i];
    if (p.n1 == 0u)      { y[i] = max(v, 0.0); }
    else if (p.n1 == 1u) { y[i] = tanh(v); }
    else                 { y[i] = 1.0 / (1.0 + exp(-v)); }
WGSL

    activate_grad => [ [qw(r:y r:dy w:dx)], 1, <<'WGSL' ],
    let i = id.x;
    if (i >= p.n0) { return; }
    let v = y[i];
    if (p.n1 == 0u)      { dx[i] = select(0.0, dy[i], v > 0.0); }
    else if (p.n1 == 1u) { dx[i] = dy[i] * (1.0 - v * v); }
    else                 { dx[i] = dy[i] * v * (1.0 - v); }
WGSL

    # y[n][k] = e[tok[n]][k]                          n0 dim, n1 tokens in the batch
    embed => [ [qw(r:e u:tok w:y)], 1, <<'WGSL' ],
    let i = id.x;
    if (i >= p.n0 * p.n1) { return; }
    y[i] = e[tok[i / p.n0] * p.n0 + i % p.n0];
WGSL

    # The token rows of a batch out of rows that are already on the card (see
    # epoch_data): row s of the batch is row ord[start + s] of them all.
    #   n0 tokens per row, n1 start, n2 rows in the batch
    rows_at => [ [qw(u:tok u:ord x:out)], 1, <<'WGSL' ],
    let i = id.x;
    if (i >= p.n0 * p.n2) { return; }
    out[i] = tok[ord[p.n1 + i / p.n0] * p.n0 + i % p.n0];
WGSL

    # ge[v][k] = sum over the tokens equal to v of dx[n][k]. Written per table
    # cell, not per token, so no two invocations ever write the same cell.
    # (One invocation per table row, gathering the row in one pass over the
    # tokens, is less work and five times slower: a hundred long loops do not
    # fill a card, sixteen hundred short ones do.)
    # The tokens are looked at four at a time; most fours hold no v at all.
    embed_grad => [ [qw(u:tok r:dx w:ge)], 1, <<'WGSL' ],
    let i = id.x;
    if (i >= p.n0 * p.n2) { return; }
    let v = i / p.n0; let k = i % p.n0;
    var sum = 0.0;
    let whole = (p.n1 / 4u) * 4u;
    for (var n = 0u; n < whole; n += 4u) {
        let hit = vec4<u32>(tok[n], tok[n + 1u], tok[n + 2u], tok[n + 3u]) == vec4<u32>(v);
        if (any(hit)) {
            if (hit.x) { sum += dx[n * p.n0 + k]; }
            if (hit.y) { sum += dx[(n + 1u) * p.n0 + k]; }
            if (hit.z) { sum += dx[(n + 2u) * p.n0 + k]; }
            if (hit.w) { sum += dx[(n + 3u) * p.n0 + k]; }
        }
    }
    for (var n = whole; n < p.n1; n++) { if (tok[n] == v) { sum += dx[n * p.n0 + k]; } }
    ge[i] = sum;
WGSL

    # The same for rows on the card: class and weight of row s are those of
    # row ord[start + s], and its loss is left at loss[start + s], on the card.
    #   n0 cols, n1 rows, n2 start
    softmax_ce_at => [ [qw(r:z u:cls r:wt u:ord w:d w:loss)], 1, <<'WGSL' ],
    let s = id.x;
    if (s >= p.n1) { return; }
    let at = s * p.n0;
    let row = ord[p.n2 + s];
    var top = z[at];
    for (var i = 1u; i < p.n0; i++) { top = max(top, z[at + i]); }
    var sum = 0.0;
    for (var i = 0u; i < p.n0; i++) { sum += exp(z[at + i] - top); }
    for (var i = 0u; i < p.n0; i++) { d[at + i] = exp(z[at + i] - top) / sum; }
    let hit = at + cls[row];
    loss[p.n2 + s] = -wt[row] * log(max(d[hit], 1e-37));
    d[hit] -= 1.0;
    for (var i = 0u; i < p.n0; i++) { d[at + i] *= wt[row]; }
WGSL

    # per row: d = softmax(z) - onehot(cls), loss = -log p[cls]     n0 cols, n1 rows
    softmax_ce => [ [qw(r:z u:cls r:wt w:d w:loss)], 1, <<'WGSL' ],
    let s = id.x;
    if (s >= p.n1) { return; }
    let at = s * p.n0;
    var top = z[at];
    for (var i = 1u; i < p.n0; i++) { top = max(top, z[at + i]); }
    var sum = 0.0;
    for (var i = 0u; i < p.n0; i++) { sum += exp(z[at + i] - top); }
    for (var i = 0u; i < p.n0; i++) { d[at + i] = exp(z[at + i] - top) / sum; }
    let hit = at + cls[s];
    loss[s] = -wt[s] * log(max(d[hit], 1e-37));
    d[hit] -= 1.0;
    for (var i = 0u; i < p.n0; i++) { d[at + i] *= wt[s]; }
WGSL

    mse => [ [qw(r:o r:t r:wt w:d w:loss)], 1, <<'WGSL' ],
    let s = id.x;
    if (s >= p.n1) { return; }
    let at = s * p.n0;
    var sum = 0.0;
    for (var i = 0u; i < p.n0; i++) {
        let diff = o[at + i] - t[at + i];
        sum += diff * diff;
        d[at + i] = wt[s] * 2.0 * diff / f32(p.n0);
    }
    loss[s] = wt[s] * sum / f32(p.n0);
WGSL

    # every value times f0: weight decay
    decay => [ [qw(w:q)], 1, <<'WGSL' ],
    let i = id.x;
    if (i >= p.n0) { return; }
    q[i] *= p.f0;
WGSL

    # f0 lr, f1 momentum, f2 scale
    sgd => [ [qw(w:q r:g w:v)], 1, <<'WGSL' ],
    let i = id.x;
    if (i >= p.n0) { return; }
    v[i] = p.f1 * v[i] - p.f0 * p.f2 * g[i];
    q[i] += v[i];
WGSL

    # f0 rate, f1 beta1, f2 beta2, f3 epsilon, f4 scale
    adam => [ [qw(w:q r:g w:m w:v)], 1, <<'WGSL' ],
    let i = id.x;
    if (i >= p.n0) { return; }
    let grad = p.f4 * g[i];
    m[i] = p.f1 * m[i] + (1.0 - p.f1) * grad;
    v[i] = p.f2 * v[i] + (1.0 - p.f2) * grad * grad;
    q[i] -= p.f0 * m[i] / (sqrt(v[i]) + p.f3);
WGSL
);

my %ACCESS = (
    r => 'var<storage, read> %s: array<f32>',
    w => 'var<storage, read_write> %s: array<f32>',
    u => 'var<storage, read> %s: array<u32>',
    x => 'var<storage, read_write> %s: array<u32>',
);

# One device and one set of compiled pipelines per process, however many
# networks use the backend. A forked child does not share its parent's: a
# device does not cross a fork, so the first backend made in a child opens
# the child's own. Tensors made before the fork stay the parent's.
my ($DEVICE, $OWNER, %PIPELINE, %PARAM_BUFFER);

sub new ($class) {
    die "no usable GPU adapter\n" if !Peta::WebGPU::have_gpu();
    if (!$DEVICE || $OWNER != $$) {
        (%PIPELINE, %PARAM_BUFFER) = ();
        $DEVICE = Peta::WebGPU::Device->new(power => 'high-performance');
        $OWNER  = $$;
    }
    return bless {}, $class;
}

sub name ($self) { return 'gpu' }

sub adapter ($self) { return $DEVICE->info }

# For other modules that compute on the card with shaders of their own, on
# this device and beside these operations: define() adds a shader under a
# name (bindings and body as in the table above, "x" being unsigned integers
# that are written), dispatch() runs one over a grid of invocations with up
# to eight integers in its parameter block, and buffer() puts bytes on the
# card, or reserves that many when given a number.
sub define ($self, $name, $bindings, $dims, $body, $functions = '') {
    $SHADER{$name} //= [ $bindings, $dims, $body, $functions ];
    return;
}

sub dispatch ($self, $name, $buffers, $ints, $nx, $ny = 1) {
    _run($name, $buffers, _params($ints), $nx, $ny);
    return;
}

sub buffer ($self, $content) { return $DEVICE->storage_buffer($content) }

sub _pipeline ($name) {
    return $PIPELINE{$name} //= do {
        my ($bindings, $dims, $body, $functions) = @{ $SHADER{$name} };
        my $slot   = 0;
        my $source = $PARAMS;
        for my $binding (@$bindings) {
            my ($access, $var) = split /:/, $binding;
            $source .= sprintf "\@group(0) \@binding(%d) $ACCESS{$access};\n", $slot++, $var;
        }
        $source .= sprintf "\@group(0) \@binding(%d) var<uniform> p: Params;\n", $slot;
        $source .= $functions // '';
        $source .= sprintf "\@compute \@workgroup_size(%s)\n", $dims == 2 ? "$GROUP_2D, $GROUP_2D" : $GROUP_1D;
        $source .= "fn main(\@builtin(global_invocation_id) id: vec3<u32>) {\n$body}\n";
        [ $DEVICE->pipeline($DEVICE->shader($source), 'main'), $dims ];
    };
}

# The parameter block for a dispatch. Blocks of integers only (sizes) recur
# all the time and are kept; one with floats (an optimizer step) is new at
# every step and is not.
sub _params ($ints, $floats = undef) {
    my $bytes = pack 'L8 f8', (@$ints, (0) x 8)[ 0 .. 7 ], (@{ $floats // [] }, (0) x 8)[ 0 .. 7 ];
    return $DEVICE->uniform_buffer($bytes) if $floats;
    return $PARAM_BUFFER{$bytes} //= $DEVICE->uniform_buffer($bytes);
}

# Run a shader over a grid of $nx by $ny invocations.
sub _run ($name, $buffers, $params, $nx, $ny = 1) {
    my ($pipeline, $dims) = @{ _pipeline($name) };
    my $group = $dims == 2 ? $GROUP_2D : $GROUP_1D;
    $DEVICE->run($pipeline, [ @$buffers, $params ],
                 int(($nx + $group - 1) / $group), $dims == 2 ? int(($ny + $group - 1) / $group) : 1);
    return;
}

sub _empty ($rows, $cols) {
    return [ $DEVICE->storage_buffer($FLOAT_BYTES * $rows * $cols), $rows, $cols ];
}

sub tensor ($self, $flat, $cols) {
    return [ $DEVICE->storage_buffer(pack 'f*', @$flat), @$flat / $cols, $cols ];
}

# [ buffer of unsigned indices, how many, how many per row ]
sub tokens ($self, $flat, $per_row) {
    return [ $DEVICE->storage_buffer(pack 'L*', @$flat), scalar @$flat, $per_row ];
}

sub flat ($self, $tensor) {
    my ($buffer, $rows, $cols) = @$tensor;
    return [ unpack 'f' . ($rows * $cols), $buffer->read ];
}

sub zeros_like ($self, $tensor) { return _empty(@$tensor[ 1, 2 ]) }

sub affine ($self, $X, $W, $b) {
    my ($batch, $n_in) = @$X[ 1, 2 ];
    my $n_out = $W->[1];
    my $Y = _empty($batch, $n_out);
    _run('affine', [ $X->[0], $W->[0], $b->[0], $Y->[0] ], _params([ $n_in, $n_out, $batch ]), int(($n_out + 3) / 4), $batch);
    return $Y;
}

sub affine_grad ($self, $X, $W, $dY, $need_dx) {
    my ($batch, $n_in) = @$X[ 1, 2 ];
    my $n_out  = $W->[1];
    my $params = _params([ $n_in, $n_out, $batch ]);
    my $gW = _empty($n_out, $n_in);
    my $gb = _empty(1, $n_out);
    _run('affine_gw', [ $X->[0], $dY->[0], $gW->[0] ], $params, $n_in, $n_out);
    _run('affine_gb', [ $dY->[0], $gb->[0] ], $params, $n_out);
    return ($gW, $gb) if !$need_dx;
    my $dX = _empty($batch, $n_in);
    _run('affine_dx', [ $dY->[0], $W->[0], $dX->[0] ], $params, $n_in, $batch);
    return ($gW, $gb, $dX);
}

sub _kind ($kind) { return $KIND_CODE{$kind} // die "unknown activation '$kind'\n" }

sub activate ($self, $kind, $X) {
    my ($rows, $cols) = @$X[ 1, 2 ];
    my $Y = _empty($rows, $cols);
    _run('activate', [ $X->[0], $Y->[0] ], _params([ $rows * $cols, _kind($kind) ]), $rows * $cols);
    return $Y;
}

sub activate_grad ($self, $kind, $Y, $dY) {
    my ($rows, $cols) = @$Y[ 1, 2 ];
    my $dX = _empty($rows, $cols);
    _run('activate_grad', [ $Y->[0], $dY->[0], $dX->[0] ], _params([ $rows * $cols, _kind($kind) ]), $rows * $cols);
    return $dX;
}

sub embed ($self, $E, $tokens) {
    my $dim = $E->[2];
    my ($buffer, $count, $per_row) = @$tokens;
    my $Y = _empty($count / $per_row, $per_row * $dim);
    _run('embed', [ $E->[0], $buffer, $Y->[0] ], _params([ $dim, $count ]), $count * $dim);
    return $Y;
}

sub embed_grad ($self, $E, $tokens, $dX) {
    my ($vocab, $dim) = @$E[ 1, 2 ];
    my $gE = _empty($vocab, $dim);
    _run('embed_grad', [ $tokens->[0], $dX->[0], $gE->[0] ], _params([ $dim, $tokens->[1], $vocab ]), $vocab * $dim);
    return $gE;
}

# Both losses leave one loss per row on the card; reading those back is the
# one place a training step waits for the GPU.
sub _row_losses ($buffer, $rows) {
    my $sum = 0;
    $sum += $_ for unpack "f$rows", $buffer->read;
    return $sum;
}

# One weight per row for the losses; all ones when the caller gives none.
sub _row_weights ($weights, $rows) {
    return $DEVICE->storage_buffer(pack 'f*', $weights ? @$weights : (1) x $rows);
}

sub softmax_ce ($self, $logits, $classes, $weights = undef) {
    my ($rows, $cols) = @$logits[ 1, 2 ];
    my $d    = _empty($rows, $cols);
    my $loss = $DEVICE->storage_buffer($FLOAT_BYTES * $rows);
    my $cls  = $DEVICE->storage_buffer(pack 'L*', @$classes);
    _run('softmax_ce', [ $logits->[0], $cls, _row_weights($weights, $rows), $d->[0], $loss ], _params([ $cols, $rows ]), $rows);
    return (_row_losses($loss, $rows), $d);
}

# --- an epoch that stays on the card --------------------------------------------
# What crosses the bus per training step is what limits a card: here the
# token rows, classes and weights of ALL the samples go up once
# (epoch_data), the order they are taken in once per epoch (epoch_order), a
# step picks its rows on the card (batch_at, softmax_ce_at), and the losses
# stay there until the epoch is over (epoch_loss).

# All the samples of a training run: their token rows, classes and weights.
sub epoch_data ($self, $rows, $per_row, $classes, $weights = undef) {
    my $count = @$classes;
    return {
        count   => $count,
        per_row => $per_row,
        tokens  => $DEVICE->storage_buffer(pack 'L*', @$rows),
        classes => $DEVICE->storage_buffer(pack 'L*', @$classes),
        weights => _row_weights($weights, $count),
    };
}

# The order the samples are taken in this epoch, and a clean slate of losses.
sub epoch_order ($self, $data, $order) {
    $data->{order} = $DEVICE->storage_buffer(pack 'L*', @$order);
    $data->{loss}  = $DEVICE->storage_buffer($FLOAT_BYTES * $data->{count});
    return;
}

# The token rows of $count samples from position $start of the order, as
# embed() takes them.
sub batch_at ($self, $data, $start, $count) {
    my $per_row = $data->{per_row};
    my $rows    = $DEVICE->storage_buffer(4 * $count * $per_row);
    _run('rows_at', [ @$data{qw(tokens order)}, $rows ], _params([ $per_row, $start, $count ]), $count * $per_row);
    return [ $rows, $count * $per_row, $per_row ];
}

# The gradient of the loss of those samples; their losses stay on the card.
sub softmax_ce_at ($self, $logits, $data, $start) {
    my ($rows, $cols) = @$logits[ 1, 2 ];
    my $d = _empty($rows, $cols);
    _run('softmax_ce_at', [ $logits->[0], @$data{qw(classes weights order)}, $d->[0], $data->{loss} ], _params([ $cols, $rows, $start ]), $rows);
    return $d;
}

# The summed loss of the epoch: the one read of the epoch.
sub epoch_loss ($self, $data) { return _row_losses($data->{loss}, $data->{count}) }

sub mse ($self, $out, $targets, $weights = undef) {
    my ($rows, $cols) = @$out[ 1, 2 ];
    my $d    = _empty($rows, $cols);
    my $loss = $DEVICE->storage_buffer($FLOAT_BYTES * $rows);
    my $want = $DEVICE->storage_buffer(pack 'f*', @$targets);
    _run('mse', [ $out->[0], $want, _row_weights($weights, $rows), $d->[0], $loss ], _params([ $cols, $rows ]), $rows);
    return (_row_losses($loss, $rows), $d);
}

sub decay ($self, $P, $factor) {
    my $count = $P->[1] * $P->[2];
    _run('decay', [ $P->[0] ], _params([$count], [$factor]), $count);
    return;
}

sub sgd_update ($self, $P, $G, $V, $lr, $momentum, $scale) {
    my $count = $P->[1] * $P->[2];
    _run('sgd', [ $P->[0], $G->[0], $V->[0] ], _params([$count], [ $lr, $momentum, $scale ]), $count);
    return;
}

sub adam_update ($self, $P, $G, $M, $V, $rate, $b1, $b2, $eps, $scale) {
    my $count = $P->[1] * $P->[2];
    _run('adam', [ $P->[0], $G->[0], $M->[0], $V->[0] ], _params([$count], [ $rate, $b1, $b2, $eps, $scale ]), $count);
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Backend::WebGPU - Peta::NN on the graphics card

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    my $net = Peta::NN->new(input => 2, layers => [ [dense => 2] ], backend => 'gpu');

=head1 DESCRIPTION

Selected with C<< backend => 'gpu' >>. Needs a pperl built with the
C<webgpu> feature and a usable adapter. For a small model on few samples
the per-operation dispatch costs more than the arithmetic saves, and a
network with C<< backend => 'auto' >> comes here only when a few timed steps
say it is faster (L<Peta::NN/train>). It pays with wide layers, large batches
and many samples: L<Peta::NN> then keeps the samples of a training run on the
card (see C<epoch_data> below), and a step carries nothing there or back.

Single precision: results agree with the plain backend to about six digits.
See L<Peta::NN::Backend> for the operations.

=head1 METHODS

This class implements the backend interface described in
L<Peta::NN::Backend/"THE BACKEND INTERFACE"> and adds these methods to it.

=head2 adapter

What the graphics adapter the backend computes on says of itself, as a table.

=head2 epoch_data, epoch_order, batch_at, softmax_ce_at, epoch_loss

An epoch that stays on the card. C<epoch_data(\@token_rows, $per_row,
\@classes, \@weights)> puts all the samples of a training run on the card,
once; C<epoch_order($data, \@order)> the order they are taken in, once per
epoch; C<batch_at($data, $start, $count)> gives the token rows of a step as
C<embed> takes them, picked on the card; C<softmax_ce_at($logits, $data,
$start)> returns the gradient and leaves the losses on the card;
C<epoch_loss($data)> reads their sum when the epoch is over. L<Peta::NN>
trains this way when its backend has these methods.

=head2 define

C<define($name, \@bindings, $dimensions, $body, $functions)>: adds a compute shader under
a name, for a module that brings its own (L<Peta::NN::Fused> does). A binding
is C<"r:name"> (floats, read), C<"w:name"> (floats, written), C<"u:name">
(unsigned integers, read) or C<"x:name"> (unsigned integers, written); the
body is WGSL and sees the invocation as C<id> and the parameter block as C<p>;
C<$functions>, optional, is WGSL functions the body calls.

=head2 dispatch

C<dispatch($name, \@buffers, \@integers, $nx, $ny)>: runs a shader over a
grid of invocations, with up to eight integers in its parameter block.

=head2 buffer

C<buffer($bytes)>: a storage buffer on the card holding the bytes, or, given
a number, one of that many bytes.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
