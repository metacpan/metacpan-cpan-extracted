package Peta::Synth::Engine::GPU;
# ABSTRACT: the voices rendered on the graphics card

# The engine on the graphics card (pperl's Peta::WebGPU): every partial of
# every voice of a quantum at once, in 32-bit floats.
#
# A quantum is four compute passes, sent to the card as one batch:
#
#   edges   one invocation per partial: its amplitude at every block's edge
#           and its phase where every block begins. The phase goes on block
#           by block, wrapped, so that it never grows past what a 32-bit
#           float holds to a hundred-thousandth of a radian.
#   noise   one invocation per voice with noise: its bands' filters, and
#           the low-pass of its noise on the partials, are recursions,
#           sample after sample, and stay so.
#   voices  one invocation per sample of every voice: the sum of its
#           partials (sin of the phase brought back to [-pi, pi], where the
#           card computes it accurately), its noise, under its envelope.
#           A workgroup of 64 is a control block.
#   mix     one invocation per sample: the voices under their channels'
#           gains, into left, right and the reverb send.
#
# The phases are carried from quantum to quantum on the CPU, in double
# precision: where a quantum ends is where it began plus the partial's
# angle through it, one multiplication per partial. So is the band-pass's
# state, which the card returns with the samples.
#
# render_reverb runs Peta::Synth::Reverb on the card too, in the same
# batch: its lines are longer than a chunk of the quantum (a chunk is no
# longer than the shortest), so within a chunk every line reads what was
# written before it. Per chunk three passes: the lines read, one per
# sample and line; the damping, a recursion, one invocation per line; the
# lines mixed (Hadamard), the wet sound and the lines written, one per
# sample. The predelay before them, read and then written. The lines stay
# on the card, one reverb's at a time; the reverb can fetch them back
# (its elsewhere), which it does before it goes on in Perl, and which
# another reverb taking the card does for it.

use v5.36;

use Peta::WebGPU;
use Peta::Synth::Voice;
use Scalar::Util qw(weaken);

our $VERSION = '0.2610180';

use constant BLOCK  => 64;
use constant TWO_PI => 6.283185307179586;
use constant STATE  => 34;    # floats of a voice's state in `out`, after the samples

# Every pass sees the same parameters. A voice's controls are a row of
# `stride` floats in `ctl`:
#
#   0 first block   1 partials   2 its first partial in `parts`   3 bands of noise (0 .. 3)
#   4 t0   5 the filter's mode (0 none)   6, 7 the noise on the partials: depth, a
#   8 + 3 b: band b's g, k, mode (0 band-, 1 high-, 2 low-pass; 4 more: four poles)
#   17 a string (0, 1)   18 its level   19 g   20 s1
#   21 FM (0, 1)   22 its level   23 feedback   24 + o: operator o's ratio
#   28 .. 33 a34 a24 a23 a14 a13 a12   34 + o: operator o a carrier (0, 1)
#   38 the string's delay besides the line   39 its stiffness's allpasses (0, 4)   40 their a
#   41 copies read from wave sequences (0: none; its partials then are none)
#   42 where their controls begin in `ctl`, after every voice's row: for
#      each copy, for each block, 7 floats: the two tables' first samples in
#      `wav` (u32, bitcast), the crossfade where the block begins and its
#      step, where in the period it begins and the read step (table
#      samples), the period (Peta::Synth::Engine::Perl::wave_blocks)
#   43 (HEAD) w[nb]; then, nb + 1 each (E): env gl gr gs fx fq, the bands'
#   levels (3), the operators' levels (4)
#
# `wav` holds every wave sequence's tables, each uploaded once and kept.
use constant HEAD => 43;
my $COMMON = <<'WGSL';
struct Params { n: u32, nb: u32, voices: u32, stride: u32, dt: f32, b: f32, pad0: f32, pad1: f32 }
const TWO_PI: f32 = 6.283185307179586;
const HEAD: u32 = 43u;
const STATE: u32 = 34u;
WGSL

# name => [ bindings ("r" read-only, "w" read-write; "4" an array of vec4,
# "2" of vec2, else of f32), body ]. The parameters are the last binding, `u`.
my %SHADER = (

    # (ratio, amp, decay, attack) of partial `at`; tab[at][j] = (phase where
    # block j begins, amplitude at edge j). Before a voice's first block its
    # envelope is zero; the amplitude is taken at time 0 there, which is finite.
    edges => [ [qw(r4:parts r:phase r:ctl w2:tab)], <<'WGSL' ],
    let k = id.x; let v = id.y;
    if (v >= u.voices) { return; }
    let c = v * u.stride;
    if (k >= u32(ctl[c + 1u])) { return; }
    let first = u32(ctl[c]);
    let at = u32(ctl[c + 2u]) + k;
    let q = parts[at];
    let t0 = ctl[c + 4u];
    var ph = phase[at];
    let row = at * (u.nb + 1u);
    let mode = u32(ctl[c + 5u]);
    let fx = c + HEAD + u.nb + 4u * (u.nb + 1u);
    let fq = fx + u.nb + 1u;
    for (var j = 0u; j <= u.nb; j++) {
        let t = max(t0 + f32(j) * u.dt, 0.0);
        var a = q.y * exp(-q.z * t);
        if (q.w > 0.0) { a *= 1.0 - exp(-t / q.w); }
        if (mode != 0u) {
            // The filter's gain (Peta::Synth::Voice::filter_gain).
            let x = q.x * ctl[fx + j]; let x2 = x * x; let r = ctl[fq + j];
            let d = sqrt((1.0 - x2) * (1.0 - x2) + x2 / (r * r));
            let steep = sqrt(1.0 + x2 * x2);
            if (mode == 1u) { a /= d; }
            else if (mode == 2u) { a /= d * steep; }
            else if (mode == 3u) { a *= x2 / d; }
            else if (mode == 4u) { a *= x2 * x2 / (d * steep); }
            else { a *= x / r / d; }
        }
        tab[row + j] = vec2<f32>(ph, a);
        if (j < u.nb && j >= first) {
            ph += q.x * ctl[c + HEAD + j] * u.b;
            ph -= TWO_PI * floor(ph / TWO_PI);
        }
    }
WGSL

    # The bands of noise: white noise from the table through each band's
    # filter (state-variable: band-, high- or low-pass; with four poles, a
    # second the same after it), under its level, summed into nz; the noise
    # on the partials, white noise through a one-pole low-pass, as the
    # factor am. Their states come in nstate, eight vec4 a voice (band b's
    # ic1, ic2, table position at b, its second stage's at 4 + b; the
    # low-pass's and its position at 3), and are returned after the samples
    # (band b's at 4 b and 28 + 2 b; the low-pass's at 12).
    noise => [ [qw(r:ctl r4:nstate r:table w:nz w:am w:out)], <<'WGSL' ],
    let v = id.x;
    if (v >= u.voices) { return; }
    let c = v * u.stride;
    let first = u32(ctl[c]);
    let bands = u32(ctl[c + 3u]);
    let size = arrayLength(&table);
    let o = 3u * u.n + STATE * v;
    for (var b = 0u; b < bands; b++) {
        let g = ctl[c + 8u + 3u * b]; let kq = ctl[c + 9u + 3u * b]; let kind = u32(ctl[c + 10u + 3u * b]);
        let mode = kind & 3u; let four = kind >= 4u;
        let a1 = 1.0 / (1.0 + g * (g + kq)); let a2 = g * a1; let a3 = g * a2;
        let s = nstate[8u * v + b];
        var ic1 = s.x; var ic2 = s.y; var index = u32(s.z);
        let s2 = nstate[8u * v + 4u + b];
        var jc1 = s2.x; var jc2 = s2.y;
        let ne = c + HEAD + u.nb + (6u + b) * (u.nb + 1u);
        for (var j = first; j < u.nb; j++) {
            var level = ctl[ne + j];
            let step = (ctl[ne + j + 1u] - level) / u.b;
            let base = v * u.n + j * 64u;
            for (var m = 0u; m < 64u; m++) {
                let v0 = table[index];
                index += 1u;
                if (index >= size) { index = 0u; }
                let v3 = v0 - ic2;
                let v1 = a1 * ic1 + a2 * v3;
                let v2 = ic2 + a2 * ic1 + a3 * v3;
                ic1 = 2.0 * v1 - ic1;
                ic2 = 2.0 * v2 - ic2;
                var y = kq * v1;
                if (mode == 1u) { y = v0 - kq * v1 - v2; } else if (mode == 2u) { y = v2; }
                if (four) {
                    let u0 = y;
                    let u3 = u0 - jc2;
                    let u1 = a1 * jc1 + a2 * u3;
                    let u2 = jc2 + a2 * jc1 + a3 * u3;
                    jc1 = 2.0 * u1 - jc1;
                    jc2 = 2.0 * u2 - jc2;
                    y = kq * u1;
                    if (mode == 1u) { y = u0 - kq * u1 - u2; } else if (mode == 2u) { y = u2; }
                }
                if (b == 0u) { nz[base + m] = level * y; } else { nz[base + m] += level * y; }
                level += step;
            }
        }
        out[o + 4u * b] = ic1; out[o + 4u * b + 1u] = ic2; out[o + 4u * b + 2u] = f32(index);
        out[o + 28u + 2u * b] = jc1; out[o + 29u + 2u * b] = jc2;
    }
    let depth = ctl[c + 6u];
    if (depth != 0.0) {
        let a = ctl[c + 7u];
        var y = nstate[8u * v + 3u].x; var index = u32(nstate[8u * v + 3u].y);
        for (var i = first * 64u; i < u.n; i++) {
            y += a * (table[index] - y);
            index += 1u;
            if (index >= size) { index = 0u; }
            am[v * u.n + i] = 1.0 + depth * y;
        }
        out[o + 12u] = y; out[o + 13u] = f32(index);
    }
WGSL

    # The strings (Peta::Synth::Engine::Perl::string): one invocation per
    # voice, a recursion through its delay line in sbuf (sst[2 v]: where it
    # begins, its size, where it writes, the low-pass's last input; sst[2 v
    # + 1]: the fractional allpass's last input and output, how much of the
    # pluck is fed, how much there is), after the line in sbuf the
    # stiffness's allpasses' last inputs and outputs (8), then the pluck
    # while it is fed; sample after sample into st; the state after the
    # samples, at 16 and 26 of the voice's STATE floats (the stiffness's in
    # sbuf).
    strings => [ [qw(r:ctl r4:sst w:sbuf w:st w:out)], <<'WGSL' ],
    let v = id.x;
    if (v >= u.voices) { return; }
    let c = v * u.stride;
    if (ctl[c + 17u] == 0.0) { return; }
    let first = u32(ctl[c]);
    let level = ctl[c + 18u]; let g = ctl[c + 19u]; let s1 = ctl[c + 20u]; let s0 = 1.0 - s1;
    let off = ctl[c + 38u]; let stiff = ctl[c + 39u] != 0.0; let a = ctl[c + 40u];
    let base = u32(sst[2u * v].x); let size = i32(sst[2u * v].y);
    var pos = i32(sst[2u * v].z); var prev = sst[2u * v].w;
    var ax = sst[2u * v + 1u].x; var ay = sst[2u * v + 1u].y;
    let ds = base + u32(size);
    var dx = vec4<f32>(sbuf[ds], sbuf[ds + 1u], sbuf[ds + 2u], sbuf[ds + 3u]);
    var dy = vec4<f32>(sbuf[ds + 4u], sbuf[ds + 5u], sbuf[ds + 6u], sbuf[ds + 7u]);
    var fed = u32(sst[2u * v + 1u].z); let todo = u32(sst[2u * v + 1u].w);
    for (var j = first; j < u.nb; j++) {
        let d = clamp(TWO_PI / ctl[c + HEAD + j] - off, 1.1, f32(size) - 2.0);
        let whole = i32(floor(d - 0.1));
        let frac = d - f32(whole);
        let eta = (1.0 - frac) / (1.0 + frac);
        for (var m = 0u; m < 64u; m++) {
            var r = pos - whole;
            if (r < 0) { r += size; }
            let x = sbuf[base + u32(r)];
            var y = eta * x + ax - eta * ay;
            ax = x; ay = y;
            if (stiff) {
                var t = a * (y - dy.x) + dx.x; dx.x = y; dy.x = t;
                y = a * (t - dy.y) + dx.y; dx.y = t; dy.y = y;
                t = a * (y - dy.z) + dx.z; dx.z = y; dy.z = t;
                y = a * (t - dy.w) + dx.w; dx.w = t; dy.w = y;
            }
            var o = g * (s0 * y + s1 * prev);
            if (fed < todo) { o += sbuf[ds + 8u + fed]; fed += 1u; }
            prev = y;
            sbuf[base + u32(pos)] = o;
            pos += 1;
            if (pos >= size) { pos = 0; }
            st[v * u.n + j * 64u + m] = level * o;
        }
    }
    let o = 3u * u.n + STATE * v + 16u;
    out[o] = f32(pos); out[o + 1u] = prev; out[o + 2u] = ax; out[o + 3u] = ay; out[o + 10u] = f32(fed);
    sbuf[ds] = dx.x; sbuf[ds + 1u] = dx.y; sbuf[ds + 2u] = dx.z; sbuf[ds + 3u] = dx.w;
    sbuf[ds + 4u] = dy.x; sbuf[ds + 5u] = dy.y; sbuf[ds + 6u] = dy.z; sbuf[ds + 7u] = dy.w;
WGSL

    # FM (Peta::Synth::Engine::Perl::fm): one invocation per voice, operator
    # 4's feedback a recursion; added to st (where a string is, after it).
    # fst[2 v]: the phases; fst[2 v + 1]: operator 4's last two outputs; the
    # same after the samples, at 20 of the voice's STATE floats.
    fm => [ [qw(r:ctl r4:fst w:st w:out)], <<'WGSL' ],
    let v = id.x;
    if (v >= u.voices) { return; }
    let c = v * u.stride;
    if (ctl[c + 21u] == 0.0) { return; }
    let first = u32(ctl[c]);
    let level = ctl[c + 22u]; let fb = ctl[c + 23u];
    let a34 = ctl[c + 28u]; let a24 = ctl[c + 29u]; let a23 = ctl[c + 30u];
    let a14 = ctl[c + 31u]; let a13 = ctl[c + 32u]; let a12 = ctl[c + 33u];
    let add = ctl[c + 17u] != 0.0;
    var p = fst[2u * v];
    var h1 = fst[2u * v + 1u].x; var h2 = fst[2u * v + 1u].y;
    let e = u.nb + 1u;
    let lv = c + HEAD + u.nb + 9u * e;
    for (var j = first; j < u.nb; j++) {
        let w = ctl[c + HEAD + j];
        let d = w * vec4<f32>(ctl[c + 24u], ctl[c + 25u], ctl[c + 26u], ctl[c + 27u]);
        var l = vec4<f32>(ctl[lv + j], ctl[lv + e + j], ctl[lv + 2u * e + j], ctl[lv + 3u * e + j]);
        let s = (vec4<f32>(ctl[lv + j + 1u], ctl[lv + e + j + 1u], ctl[lv + 2u * e + j + 1u], ctl[lv + 3u * e + j + 1u]) - l) / u.b;
        for (var m = 0u; m < 64u; m++) {
            // The phases from the block's start: one rounding, not 64.
            let q = p + d * f32(m);
            let u4 = sin(q.w + fb * 0.5 * (h1 + h2));
            h2 = h1; h1 = u4;
            let o4 = l.w * u4;
            let o3 = l.z * sin(q.z + a34 * o4);
            let o2 = l.y * sin(q.y + a24 * o4 + a23 * o3);
            let o1 = l.x * sin(q.x + a14 * o4 + a13 * o3 + a12 * o2);
            let x = level * (ctl[c + 34u] * o1 + ctl[c + 35u] * o2 + ctl[c + 36u] * o3 + ctl[c + 37u] * o4);
            let at = v * u.n + j * 64u + m;
            if (add) { st[at] += x; } else { st[at] = x; }
            l += s;
        }
        p += d * 64.0;
        p -= TWO_PI * floor(p / TWO_PI);
    }
    let o = 3u * u.n + STATE * v + 20u;
    out[o] = p.x; out[o + 1u] = p.y; out[o + 2u] = p.z; out[o + 3u] = p.w; out[o + 4u] = h1; out[o + 5u] = h2;
WGSL

    # y[v][i]: voice v's sample i, its partials (or its wave sequences),
    # string and noise under its envelope.
    voices => [ [qw(r4:parts r:ctl r2:tab r:nz r:am r:st r:wav w:y)], <<'WGSL' ],
    let i = id.x; let v = id.y;
    if (i >= u.n || v >= u.voices) { return; }
    let c = v * u.stride;
    let j = i / 64u;
    var x = 0.0;
    if (j >= u32(ctl[c])) {
        let m = f32(i % 64u);
        let frac = m / u.b;
        let count = u32(ctl[c + 1u]);
        let off = u32(ctl[c + 2u]);
        let w = m * ctl[c + HEAD + j];
        for (var k = 0u; k < count; k++) {
            let row = (off + k) * (u.nb + 1u) + j;
            let e0 = tab[row];
            let a1 = tab[row + 1u].y;
            var arg = e0.x + w * parts[off + k].x;
            arg -= TWO_PI * round(arg / TWO_PI);
            x += (e0.y + (a1 - e0.y) * frac) * sin(arg);
        }
        let copies = u32(ctl[c + 41u]);
        for (var q = 0u; q < copies; q++) {
            let b = u32(ctl[c + 42u]) + (q * u.nb + j) * 7u;
            let oa = bitcast<u32>(ctl[b]);
            let ob = bitcast<u32>(ctl[b + 1u]);
            let size = ctl[b + 6u];
            var pos = ctl[b + 4u] + m * ctl[b + 5u];
            pos -= size * floor(pos / size);
            let at = min(u32(pos), u32(size) - 1u);
            let f = pos - f32(at);
            let ta = wav[oa + at] + f * (wav[oa + at + 1u] - wav[oa + at]);
            let tb = wav[ob + at] + f * (wav[ob + at + 1u] - wav[ob + at]);
            x += ta + (ctl[b + 2u] + m * ctl[b + 3u]) * (tb - ta);
        }
        if (ctl[c + 17u] != 0.0 || ctl[c + 21u] != 0.0) { x += st[v * u.n + i]; }
        if (ctl[c + 6u] != 0.0) { x *= am[v * u.n + i]; }
        if (ctl[c + 3u] != 0.0) { x += nz[v * u.n + i]; }
        let ev = c + HEAD + u.nb + j;
        x *= ctl[ev] + (ctl[ev + 1u] - ctl[ev]) * frac;
    }
    y[v * u.n + i] = x;
WGSL

    # left, right, send: the voices under their channels' gains.
    mix => [ [qw(r:ctl r:y w:out)], <<'WGSL' ],
    let i = id.x;
    if (i >= u.n) { return; }
    let j = i / 64u;
    let frac = f32(i % 64u) / u.b;
    let edges = u.nb + 1u;
    var l = 0.0; var r = 0.0; var s = 0.0;
    for (var v = 0u; v < u.voices; v++) {
        let x = y[v * u.n + i];
        if (x == 0.0) { continue; }
        let gl = v * u.stride + HEAD + u.nb + edges + j;
        let gr = gl + edges;
        let gs = gr + edges;
        l += x * (ctl[gl] + (ctl[gl + 1u] - ctl[gl]) * frac);
        r += x * (ctl[gr] + (ctl[gr + 1u] - ctl[gr]) * frac);
        s += x * (ctl[gs] + (ctl[gs + 1u] - ctl[gs]) * frac);
    }
    out[i] = l; out[u.n + i] = r; out[2u * u.n + i] = s;
WGSL
);

# The reverb. rvp, its parameters for a chunk: 0-8 the lines' and the
# predelay's offsets in rvl, 9-17 their lengths, 18-26 their positions
# where the quantum begins; 27 damp, 28 1 - damp, 29 the wet level, 30-37
# the lines' gains; 38 where the chunk begins, 39 its length, 40 where in
# out the wet left and right go. rvx: the predelayed input (n), then the
# lines' outputs (8 n). rvs: the lines' low-passes.
$SHADER{rv_in} = [ [qw(r:out r:rvl r:rvp w:rvx)], <<'WGSL' ];
    let i = id.x;
    if (i >= u.n) { return; }
    let lp = u32(rvp[17]);
    if (i >= lp) { rvx[i] = out[2u * u.n + i - lp]; }
    else { rvx[i] = rvl[u32(rvp[8]) + (u32(rvp[26]) + i) % lp]; }
WGSL
$SHADER{rv_inw} = [ [qw(r:out r:rvp w:rvl)], <<'WGSL' ];
    let i = id.x;
    let lp = u32(rvp[17]);
    if (i >= u.n || i + lp < u.n) { return; }
    rvl[u32(rvp[8]) + (u32(rvp[26]) + i) % lp] = out[2u * u.n + i];
WGSL
$SHADER{rv_read} = [ [qw(r:rvl r:rvp w:rvx)], <<'WGSL' ];
    let i = id.x; let l = id.y;
    if (i >= u32(rvp[39]) || l >= 8u) { return; }
    let t = u32(rvp[38]) + i;
    rvx[u.n + l * u.n + t] = rvl[u32(rvp[l]) + (u32(rvp[18u + l]) + t) % u32(rvp[9u + l])];
WGSL
$SHADER{rv_damp} = [ [qw(r:rvp w:rvx w:rvs)], <<'WGSL' ];
    let l = id.x;
    if (l >= 8u) { return; }
    let damp = rvp[27]; let keep = rvp[28];
    let base = u.n + l * u.n + u32(rvp[38]);
    let count = u32(rvp[39]);
    var s = rvs[l];
    for (var i = 0u; i < count; i++) {
        s = keep * rvx[base + i] + damp * s;
        rvx[base + i] = s;
    }
    rvs[l] = s;
WGSL
$SHADER{rv_mix} = [ [qw(r:rvp r:rvx w:rvl w:out)], <<'WGSL' ];
    let i = id.x;
    if (i >= u32(rvp[39])) { return; }
    let t = u32(rvp[38]) + i;
    var s: array<f32, 8>;
    for (var l = 0u; l < 8u; l++) { s[l] = rvx[u.n + l * u.n + t]; }
    let level = rvp[29];
    let wb = u32(rvp[40]);
    out[wb + t]       = level * (s[0] - s[1] + s[2] - s[3] + s[4] - s[5] + s[6] - s[7]);
    out[wb + u.n + t] = level * (s[0] + s[1] - s[2] - s[3] + s[4] + s[5] - s[6] - s[7]);
    let a0 = s[0] + s[1]; let a1 = s[0] - s[1]; let a2 = s[2] + s[3]; let a3 = s[2] - s[3];
    let a4 = s[4] + s[5]; let a5 = s[4] - s[5]; let a6 = s[6] + s[7]; let a7 = s[6] - s[7];
    let b0 = a0 + a2; let b1 = a1 + a3; let b2 = a0 - a2; let b3 = a1 - a3;
    let b4 = a4 + a6; let b5 = a5 + a7; let b6 = a4 - a6; let b7 = a5 - a7;
    let h = 0.35355339059327373;
    let x = rvx[t];
    var v: array<f32, 8>;
    v[0] = (b0 + b4) * h + x; v[1] = (b1 + b5) * h + x; v[2] = (b2 + b6) * h + x; v[3] = (b3 + b7) * h + x;
    v[4] = (b0 - b4) * h - x; v[5] = (b1 - b5) * h - x; v[6] = (b2 - b6) * h - x; v[7] = (b3 - b7) * h - x;
    for (var l = 0u; l < 8u; l++) {
        rvl[u32(rvp[l]) + (u32(rvp[18u + l]) + t) % u32(rvp[9u + l])] = rvp[30u + l] * v[l];
    }
WGSL

my %ACCESS = (r => 'read', w => 'read_write');
my %TYPE   = ('' => 'f32', 2 => 'vec2<f32>', 4 => 'vec4<f32>');

# One device per process: a device does not cross a fork, so a forked
# child opens its own the first time it renders.
my ($DEVICE, $OWNER, %PIPELINE, %BUFFER, %BINDING, $PARAMS, $TABLE);
# The wave sequences' tables: as they went to the card, how much of that
# has gone, and where each sequence's begin there (floats).
my ($WAV_BYTES, $WAV_SENT, %WAV_AT) = ('', 0);
# The reverb whose lines the card holds, and their version.
my ($CARD_REVERB, $CARD_VERSION);

sub new ($class, %arg) {
    die "no usable GPU adapter\n" if !Peta::WebGPU::have_gpu();
    _device();
    return bless { %arg }, $class;
}

sub name ($self) { return 'gpu' }

# Whether voices should be read from wave sequences here: the card turns
# partials for next to nothing, while a wave sequence's controls are worked
# out and packed in Perl, block by block (on a band piece, 17.3 s against 21.0).
# It reads them all the same where they are asked for.
sub reads_waves ($self) { return 0 }

sub adapter ($self) { return _device()->info }

sub _device () {
    if (!$DEVICE || $OWNER != $$) {
        (%PIPELINE, %BUFFER, %BINDING, %WAV_AT) = ();
        ($WAV_BYTES, $WAV_SENT) = ('', 0);
        $CARD_REVERB = undef;
        $DEVICE = Peta::WebGPU::Device->new(power => 'high-performance');
        $OWNER  = $$;
        $PARAMS = $DEVICE->uniform_buffer(32);
        $TABLE  = $DEVICE->storage_buffer(pack 'f*', @{ Peta::Synth::Voice::noise_table() });
    }
    return $DEVICE;
}

sub _pipeline ($name) {
    return $PIPELINE{$name} //= do {
        my ($bindings, $body) = @{ $SHADER{$name} };
        my $source = $COMMON;
        my $slot   = 0;
        for my $binding (@$bindings) {
            my ($access, $type, $var) = $binding =~ /\A([rw])(\d?):(\w+)\z/ or die "bad binding $binding";
            $source .= sprintf "\@group(0) \@binding(%d) var<storage, %s> %s: array<%s>;\n", $slot++, $ACCESS{$access}, $var, $TYPE{$type};
        }
        $source .= sprintf "\@group(0) \@binding(%d) var<uniform> u: Params;\n", $slot;
        $source .= "\@compute \@workgroup_size(64)\nfn main(\@builtin(global_invocation_id) id: vec3<u32>) {\n$body}\n";
        $DEVICE->pipeline($DEVICE->shader($source), 'main');
    };
}

# A buffer of at least $bytes, kept and grown by doubling; the bindings
# that held the old one go with it.
sub _buffer ($name, $bytes) {
    $bytes = 16 if $bytes < 16;
    my $buffer = $BUFFER{$name};
    return $buffer if $buffer && $buffer->size >= $bytes;
    my $size = 1024;
    $size *= 2 while $size < $bytes;
    %BINDING = ();
    return $BUFFER{$name} = $DEVICE->storage_buffer($size);
}

my %BUFFERS_OF = (
    edges  => [qw(parts phase ctl tab)],
    noise   => [qw(ctl nstate table nz am out)],
    strings => [qw(ctl sst sbuf st out)],
    fm      => [qw(ctl fst st out)],
    voices  => [qw(parts ctl tab nz am st wav y)],
    mix    => [qw(ctl y out)],
    rv_in   => [qw(out rvl rvp rvx)],
    rv_inw  => [qw(out rvp rvl)],
    rv_read => [qw(rvl rvp rvx)],
    rv_damp => [qw(rvp rvx rvs)],
    rv_mix  => [qw(rvp rvx rvl out)],
);

# Where a wave sequence's tables begin in `wav` (floats): added to what goes
# to the card the first time, kept after.
sub _wav_at ($sequence) {
    return $WAV_AT{$sequence} //= do {
        my $at = length($WAV_BYTES) / 4;
        $WAV_BYTES .= pack 'f*', map { @$_ } @{ $sequence->{tables} };
        $at;
    };
}

# What is new of the tables onto the card; all of them into a larger buffer
# when they outgrow it.
sub _wav_upload () {
    my $buffer = $BUFFER{wav};
    if (!$buffer || $buffer->size < length $WAV_BYTES) {
        $buffer = _buffer(wav => length $WAV_BYTES);
        $WAV_SENT = 0;
    }
    $buffer->write(substr($WAV_BYTES, $WAV_SENT), $WAV_SENT) if length($WAV_BYTES) > $WAV_SENT;
    $WAV_SENT = length $WAV_BYTES;
    return;
}

sub _run ($name, $x, $y = 1) {
    my $binding = $BINDING{$name} //= _pipeline($name)->bind([ (map { $_ eq 'table' ? $TABLE : $BUFFER{$_} } @{ $BUFFERS_OF{$name} }), $PARAMS ]);
    $DEVICE->run($binding, $x, $y);
    return;
}

sub render ($self, $voices, $n, $rate) { return $self->_render($voices, $n, $rate, undef) }

# The voices and the reverb of their send: left, right, send, and the wet
# left and right (none when the reverb is off).
sub render_reverb ($self, $voices, $n, $rate, $reverb) {
    return $self->_render($voices, $n, $rate, $reverb->active ? $reverb : undef);
}

# The reverb's lines onto the card, unless they are there: another
# reverb's given back to it first.
sub _reverb_onto_card ($reverb) {
    return if $CARD_REVERB && $CARD_REVERB == $reverb && $CARD_VERSION == $reverb->{version} && $reverb->{elsewhere};
    if ($CARD_REVERB && $CARD_REVERB != $reverb && (my $back = delete $CARD_REVERB->{elsewhere})) { $back->() }
    my $lines = pack 'f*', @{ $reverb->{buffer} };
    _buffer(rvl => length $lines)->write($lines, 0);
    _buffer(rvs => 32)->write(pack('f8', @{ $reverb->{lp} }), 0);
    ($CARD_REVERB, $CARD_VERSION) = ($reverb, $reverb->{version});
    weaken $CARD_REVERB;
    my $owner = $$;
    my $weak = $reverb;
    weaken $weak;
    $reverb->{elsewhere} = sub {
        return if !$weak || $owner != $$ || !$CARD_REVERB || $CARD_REVERB != $weak;    # the card is not this process's
        my ($l, $s);
        $DEVICE->batch(sub { $l = $BUFFER{rvl}->read(0, length $lines); $s = $BUFFER{rvs}->read(0, 32) });
        $weak->{buffer} = [ unpack 'f*', $l ];
        $weak->{lp}     = [ unpack 'f8', $s ];
        $CARD_REVERB = undef;
    };
    return;
}

sub _render ($self, $voices, $n, $rate, $reverb) {
    my $B  = BLOCK;
    my $nb = $n / $B;
    return ([ (0.0) x $n ], [ (0.0) x $n ], [ (0.0) x $n ]) if !@$voices && !$reverb;
    _device();

    my $V      = @$voices;
    my $stride = HEAD + $nb + 13 * ($nb + 1);
    my $packed = _pack_voices($voices, $nb, $rate, $stride);
    _upload_voices($packed, $V, $n, $nb) if $V;

    my $wet    = 3 * $n + STATE * $V;    # where the wet sound goes in out
    my $floats = $wet + ($reverb ? 2 * $n : 0);
    my $out    = _buffer(out => 4 * $floats);
    $PARAMS->write(pack('L4 f4', $n, $nb, $V, $stride, $B / $rate, $B, 0, 0), 0);

    my ($chunks, $fixed) = $reverb ? _reverb_chunks($reverb, $n) : ([], []);

    my ($bytes, $sbytes);
    my $groups = sub ($count) { int(($count + 63) / 64) };    # workgroups of 64
    $DEVICE->batch(sub {
        if ($V) {
            _run(edges   => $groups->($packed->{most}), $V) if $packed->{most};
            _run(noise   => $groups->($V));
            _run(strings => $groups->($V)) if $packed->{sfloats};
            _run(fm      => $groups->($V)) if $packed->{fms};
            _run(voices  => $nb, $V);
            _run(mix     => $groups->($n));
        }
        else {
            $out->write(pack('f*', (0.0) x (3 * $n)), 0);
        }
        for my $k (0 .. $#$chunks) {
            my ($c0, $len) = @{ $chunks->[$k] };
            $BUFFER{rvp}->write(pack('f*', @$fixed, $c0, $len, $wet), 0);
            if ($k == 0) {
                _run(rv_in  => $groups->($n));
                _run(rv_inw => $groups->($n));
            }
            _run(rv_read => $groups->($len), 8);
            _run(rv_damp => 1);
            _run(rv_mix  => $groups->($len));
        }
        $bytes  = $out->read(0, 4 * $floats);
        $sbytes = $BUFFER{sbuf}->read(0, 4 * $packed->{sfloats}) if $packed->{sfloats};
    });

    my @f       = unpack 'f*', $bytes;
    my @strings = $packed->{sfloats} ? unpack('f*', $sbytes) : ();
    _carry_on($voices, \@f, \@strings, $n);

    my @mix = map { [ @f[ $_ * $n .. ($_ + 1) * $n - 1 ] ] } 0 .. 2;
    return @mix if !$reverb;

    my @wet = map { [ @f[ $wet + $_ * $n .. $wet + ($_ + 1) * $n - 1 ] ] } 0, 1;
    $reverb->advance($n, $mix[2], @wet);
    return (@mix, @wet);
}

# Every voice packed for the card: { parts, phase, ctl (and the wave
# sequences' controls after it), nstate, sst, sbuf, fst; offset (the
# partials), most (the most partials a voice has), sfloats (the strings'
# floats), fms (voices with FM) }.
sub _pack_voices ($voices, $nb, $rate, $stride) {
    my %p = map { $_ => '' } qw(parts phase ctl waves nstate sst sbuf fst);
    @p{qw(offset most sfloats fms)} = (0, 0, 0, 0);
    my $wave_at = @$voices * $stride;    # where the wave sequences' controls begin in ctl

    for my $voice (@$voices) {
        my $count = $voice->{wave} ? 0 : @{ $voice->{ratio} };    # read from wave sequences instead
        if (!$voice->{wave}) {
            $p{parts} .= $voice->{gpu_parts} //= pack 'f*', map {
                ($voice->{ratio}[$_], $voice->{amp}[$_], $voice->{decay}[$_], $voice->{attack}[$_])
            } 0 .. $count - 1;
            $p{phase} .= pack 'f*', @{ $voice->{phase} };
        }

        my $controls = $wave_at + length($p{waves}) / 4;
        my $copies   = 0;
        for my $c (@{ $voice->{wave} ? Peta::Synth::Engine::Perl::wave_blocks($voice, $nb, $rate) : [] }) {
            $p{waves} .= _wave_controls($c, $nb);
            $copies++;
        }

        my $string = $voice->{string};
        if ($string) {
            my $size = @{ $string->{buf} };
            my $todo = @{ $string->{exc} };
            $p{sst}  .= pack 'f8', $p{sfloats}, $size, @$string{qw(pos prev ax ay fed)}, $todo;
            $p{sbuf} .= pack 'f*', @{ $string->{buf} }, @{ $string->{disp} }, @{ $string->{exc} };
            $p{sfloats} += $size + 8 + $todo;
        }
        else {
            $p{sst} .= pack 'f8', (0) x 8;
        }

        my $fm = $voice->{fm};
        $p{fst} .= $fm ? pack('f8', @{ $fm->{phase} }, @{ $fm->{hist} }, 0, 0) : pack('f8', (0) x 8);
        $p{fms}++ if $fm;

        my @bands = @{ $voice->{bands} // [] };
        $p{nstate} .= pack 'f32',
            (map { $bands[$_] ? (@{ $bands[$_]{state} }[ 0 .. 2 ], 0) : (0, 0, 0, 0) } 0 .. 2),
            $voice->{rough} ? (@{ $voice->{rstate} }, 0, 0) : (0, 0, 0, 0),
            (map { $bands[$_] ? (@{ $bands[$_]{state} }[ 3, 4 ], 0, 0) : (0, 0, 0, 0) } 0 .. 2),
            0, 0, 0, 0;

        $p{ctl} .= _control_row($voice, $nb, $count, $p{offset}, $copies, $controls);
        $p{offset} += $count;
        $p{most} = $count if $count > $p{most};
    }
    $p{ctl} .= delete $p{waves};
    return \%p;
}

# A copy's wave sequence controls, block by block: the two tables' first
# samples in `wav`, the crossfade and its step, where in the period the
# block begins and the read step, the period.
sub _wave_controls ($c, $nb) {
    my $at = _wav_at($c->{sequence});
    my ($size, $last) = @$c{qw(size last)};
    my @table = @{ $c->{table} };
    return join '', map {
        my $k    = $table[$_];
        my $next = $k < $last ? $k + 1 : $k;
        pack 'L2 f5', $at + $k * ($size + 1), $at + $next * ($size + 1),
            $c->{mix}[$_], $c->{dmix}[$_], $c->{start}[$_], $c->{step}[$_], $size;
    } 0 .. $nb - 1;
}

# A voice's row of controls in `ctl`, as the table above HEAD lays it out.
sub _control_row ($voice, $nb, $count, $offset, $copies, $controls) {
    my $mode   = $voice->{fmode} // 0;
    my @bands  = @{ $voice->{bands} // [] };
    my $rough  = $voice->{rough};
    my $string = $voice->{string};
    my $fm     = $voice->{fm};
    my $edges  = $nb + 1;

    return pack 'f*',
        $voice->{first}, $count, $offset, scalar @bands,                         # 0 .. 3
        $voice->{t0}, $mode,                                                      # 4, 5
        $rough ? @$rough : (0, 0),                                                # 6, 7
        (map { $bands[$_] ? _band_row($bands[$_]) : (0, 0, 0) } 0 .. 2),          # 8 .. 16
        $string ? (1, @$string{qw(level g s1)}) : (0, 0, 0, 0),                   # 17 .. 20
        $fm ? (1, $fm->{level}, $fm->{fb}, @{ $fm->{ratio} }, @{ $fm->{coef} }, @{ $fm->{carrier} })
            : (0) x 17,                                                           # 21 .. 37
        $string ? @$string{qw(off stages a)} : (0, 0, 0),                         # 38 .. 40
        $copies, $controls,                                                       # 41, 42
        @{ $voice->{w} },                                                         # HEAD: w[nb]
        @{ $voice->{env} }, @{ $voice->{gl} }, @{ $voice->{gr} }, @{ $voice->{gs} },
        $mode ? (@{ $voice->{fx} }, @{ $voice->{fq} }) : ((0.0) x $edges, (1.0) x $edges),
        (map { $bands[$_] ? @{ $bands[$_]{env} } : (0.0) x $edges } 0 .. 2),
        (map { $fm ? @{ $fm->{lv}[$_] } : (0.0) x $edges } 0 .. 3);
}

# A band of noise's filter in a voice's row: g, k, and its mode, 4 more with four poles.
sub _band_row ($band) { return (@$band{qw(g k)}, $band->{mode} + ($band->{poles} == 4 ? 4 : 0)) }

# The packed voices onto the card, and room for what the passes write.
sub _upload_voices ($p, $V, $n, $nb) {
    # The voice pass binds the partials even when no voice has any (a
    # string, a drum of noise alone).
    my $partials = _buffer(parts => length $p->{parts});
    $partials->write($p->{parts}, 0) if length $p->{parts};
    _buffer(phase  => length $p->{phase})->write($p->{phase}, 0) if length $p->{phase};
    _buffer(ctl    => length $p->{ctl})->write($p->{ctl}, 0);
    _wav_upload();
    _buffer(nstate => length $p->{nstate})->write($p->{nstate}, 0);
    _buffer(tab    => 8 * $p->{offset} * ($nb + 1));
    _buffer(nz     => 4 * $V * $n);
    _buffer(am     => 4 * $V * $n);
    _buffer(st     => 4 * $V * $n);
    _buffer(sst    => length $p->{sst})->write($p->{sst}, 0);
    _buffer(sbuf   => length $p->{sbuf})->write($p->{sbuf}, 0) if length $p->{sbuf};
    _buffer(fst    => length $p->{fst})->write($p->{fst}, 0);
    _buffer(y      => 4 * $V * $n);
    return;
}

# The reverb onto the card, and its chunks: [ where each begins, its
# length ], as long as the shortest line at most; and the parameters every
# chunk shares (rvp's first 38).
sub _reverb_chunks ($reverb, $n) {
    _reverb_onto_card($reverb);
    _buffer(rvx => 4 * 9 * $n);
    _buffer(rvp => 4 * 41);

    my $damp  = $reverb->{damp};
    my @fixed = (@{ $reverb->{offset} }, @{ $reverb->{len} }, $reverb->{pre}, @{ $reverb->{pos} },
        $damp, 1.0 - $damp, $reverb->{level} * 0.35, @{ $reverb->{g} });

    my $shortest = $n;
    for (@{ $reverb->{len} }) { $shortest = $_ if $_ < $shortest }
    my @chunks;
    for (my $c0 = 0; $c0 < $n; $c0 += $shortest) {
        push @chunks, [ $c0, $n - $c0 < $shortest ? $n - $c0 : $shortest ];
    }
    return (\@chunks, \@fixed);
}

# Where the quantum leaves the voices, from what the card returned: the
# partials' phases (carried on here, in double precision), the noise's
# filters, FM's phases, the strings.
sub _carry_on ($voices, $f, $strings, $n) {
    my $B     = BLOCK;
    my $sfrom = 0;
    for my $v (0 .. $#$voices) {
        my $voice = $voices->[$v];
        if (!$voice->{wave}) {    # a voice read from wave sequences went on in wave_blocks
            my $turn = 0.0;
            $turn += $_ for @{ $voice->{w} };
            $turn *= $B;
            my @ratio = @{ $voice->{ratio} };
            my @phase = @{ $voice->{phase} };
            for my $k (0 .. $#phase) {
                my $p = $phase[$k] + $ratio[$k] * $turn;
                $phase[$k] = $p - TWO_PI * int($p / TWO_PI);
            }
            $voice->{phase} = \@phase;
        }

        my $o = 3 * $n + STATE * $v;    # the voice's state in out
        my $b = 0;
        for my $band (@{ $voice->{bands} // [] }) {
            $band->{state} = [ @$f[ $o + 4 * $b, $o + 4 * $b + 1 ], int $f->[ $o + 4 * $b + 2 ], @$f[ $o + 28 + 2 * $b, $o + 29 + 2 * $b ] ];
            $b++;
        }
        $voice->{rstate} = [ $f->[ $o + 12 ], int $f->[ $o + 13 ] ] if $voice->{rough};
        if (my $fm = $voice->{fm}) {
            $fm->{phase} = [ @$f[ $o + 20 .. $o + 23 ] ];
            $fm->{hist}  = [ @$f[ $o + 24, $o + 25 ] ];
        }
        if (my $string = $voice->{string}) {
            my $size = @{ $string->{buf} };
            @$string{qw(pos prev ax ay)} = (int $f->[ $o + 16 ], @$f[ $o + 17 .. $o + 19 ]);
            $string->{buf}  = [ @$strings[ $sfrom .. $sfrom + $size - 1 ] ];
            $string->{disp} = [ @$strings[ $sfrom + $size .. $sfrom + $size + 7 ] ];
            $sfrom += $size + 8 + @{ $string->{exc} };
            $string->{fed} = int $f->[ $o + 26 ];
            $string->{exc} = [] if $string->{fed} >= @{ $string->{exc} };
        }
    }
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Engine::GPU - the voices rendered on the graphics card

=head1 VERSION

version 0.2610180

=head1 DESCRIPTION

Every partial of every voice of a quantum at once, in compute shaders,
through pperl's L<Peta::WebGPU>; 32-bit floats, so it agrees with the Perl
engine to about a hundred-thousandth of full scale. Needs pperl and a
graphics card. See L<Peta::Synth::Engine> for the interface.

=head1 METHODS

=head2 new, name

C<new(%arg)> makes the engine (it dies where it cannot run here); C<name> is C<gpu>.

=head2 adapter

The graphics card it renders on: C<name>, C<backend>, C<driver> and more.

=head2 render

C<render(\@voices, $n, $rate)>: the voices' next C<$n> samples, mixed, as
array references: left, right and the reverb send.

=head2 render_reverb

C<render_reverb(\@voices, $n, $rate, $reverb)>: as C<render>, and the
L<Peta::Synth::Reverb>'s wet left and right of the send, on the card (none
when the reverb is off).

=head2 reads_waves

False: the card turns partials for next to nothing, while a wave
sequence's controls are worked out and packed in Perl; it reads them where
they are asked for all the same.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
