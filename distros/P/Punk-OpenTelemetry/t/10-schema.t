#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use OTelWire qw(pb_parse pb_field pb_fields);
use Punk::OpenTelemetry;
use Punk::OpenTelemetry::Schema;

# Schema URLs and the version converter.

# A three-version file where ONE attribute is renamed TWICE. That is the case
# a flattened rename map gets wrong, and it is why versions are applied one at
# a time, in order.
my $YAML = <<'Y';
file_format: 1.1.0
schema_url: https://example.test/schemas/1.3.0
versions:
  1.3.0:
    spans:
      changes:
        - rename_attributes:
            attribute_map:
              middle.name: final.name
  1.2.0:
    spans:
      changes:
        - rename_attributes:
            attribute_map:
              original.name: middle.name
    all:
      changes:
        - rename_attributes:
            attribute_map:
              everywhere.old: everywhere.new
  1.1.0:
    spans:
      changes:
        - rename_attributes:
            attribute_map:
              gone: kept
Y

my $schema = eval { Punk::OpenTelemetry::Schema->load(text => $YAML) };
plan skip_all => "no usable YAML parser: $@" unless $schema;

sub payload {
    my (%attrs) = @_;
    return { resource_spans => [ {
        resource    => { attributes => { %attrs } },
        scope_spans => [ { scope => { name => 's' },
                           spans => [ { name => 'x', attributes => { %attrs } } ] } ],
    } ] };
}
sub span_attrs {
    $_[0]{resource_spans}[0]{scope_spans}[0]{spans}[0]{attributes};
}

# ---- the file ----------------------------------------------------------------
{
    is($schema->schema_url, 'https://example.test/schemas/1.3.0',
        'the schema url is read');
    is_deeply([ $schema->versions ], [qw(1.1.0 1.2.0 1.3.0)],
        'versions come back in SEMANTIC order, not string order');
    ok($schema->knows('1.2.0'), 'a declared version is known');
    ok(!$schema->knows('9.9.9'), 'an undeclared one is not');

    ok(!eval { Punk::OpenTelemetry::Schema->load(text => "just: a map\n"); 1 },
        'a file with no versions is refused rather than half-used');
}

# ---- semantic version ordering ----------------------------------------------
# "1.10.0" sorts before "1.9.0" as a string, which would apply the changes
# backwards and silently.
{
    my $s = Punk::OpenTelemetry::Schema->load(text => <<'Y');
file_format: 1.1.0
schema_url: https://example.test/s
versions:
  1.9.0: {}
  1.10.0: {}
  1.2.0: {}
Y
    is_deeply([ $s->versions ], [qw(1.2.0 1.9.0 1.10.0)],
        '1.10.0 sorts AFTER 1.9.0, which string order would get wrong');
}

# ---- a single rename, both directions ---------------------------------------
{
    my $p = payload('gone' => 1);
    $schema->convert($p, from => '1.0.0', to => '1.1.0', signal => 'spans');
    is_deeply([sort keys %{ span_attrs($p) }], ['kept'],
        'forward: the attribute is renamed');

    my $b = payload('kept' => 1);
    $schema->convert($b, from => '1.1.0', to => '1.0.0', signal => 'spans');
    is_deeply([sort keys %{ span_attrs($b) }], ['gone'],
        'backward: the rename is undone');
}

# ---- THE test: an attribute renamed TWICE -----------------------------------
# original.name -> middle.name in 1.2.0, middle.name -> final.name in 1.3.0.
# A flattened map holds both as independent entries and stops at middle.name.
{
    my $p = payload('original.name' => 'v');
    $schema->convert($p, from => '1.1.0', to => '1.3.0', signal => 'spans');
    my @k = sort keys %{ span_attrs($p) };
    is_deeply(\@k, ['final.name'],
        'forward across TWO renames lands on final.name, not middle.name');
    is(span_attrs($p)->{'final.name'}, 'v', 'and the value came with it');

    my $b = payload('final.name' => 'v');
    $schema->convert($b, from => '1.3.0', to => '1.1.0', signal => 'spans');
    is_deeply([sort keys %{ span_attrs($b) }], ['original.name'],
        'and backward across both lands on original.name');
    is(span_attrs($b)->{'original.name'}, 'v', 'with its value');
}

# ---- a partial walk stops where it was told ---------------------------------
{
    my $p = payload('original.name' => 'v');
    $schema->convert($p, from => '1.1.0', to => '1.2.0', signal => 'spans');
    is_deeply([sort keys %{ span_attrs($p) }], ['middle.name'],
        'converting only as far as 1.2.0 stops at middle.name');
}

# ---- `all` applies to every signal ------------------------------------------
{
    my $p = payload('everywhere.old' => 1);
    $schema->convert($p, from => '1.1.0', to => '1.2.0', signal => 'spans');
    is_deeply([sort keys %{ span_attrs($p) }], ['everywhere.new'],
        'an `all` section applies alongside the signal section');
}

# ---- every attribute hash in the payload, not just the span -----------------
{
    my $p = payload('gone' => 1);
    $p->{resource_spans}[0]{scope_spans}[0]{spans}[0]{events} =
        [ { name => 'e', attributes => { gone => 1 } } ];
    $p->{resource_spans}[0]{scope_spans}[0]{spans}[0]{links} =
        [ { attributes => { gone => 1 } } ];
    $schema->convert($p, from => '1.0.0', to => '1.1.0', signal => 'spans');

    my $sp = $p->{resource_spans}[0]{scope_spans}[0]{spans}[0];
    is_deeply([keys %{ $p->{resource_spans}[0]{resource}{attributes} }], ['kept'],
        'the RESOURCE attributes are converted');
    is_deeply([keys %{ $sp->{events}[0]{attributes} }], ['kept'],
        'and a span event');
    is_deeply([keys %{ $sp->{links}[0]{attributes} }], ['kept'],
        'and a link');
}

# ---- no-op conversions -------------------------------------------------------
{
    my $p = payload('gone' => 1);
    $schema->convert($p, from => '1.1.0', to => '1.1.0', signal => 'spans');
    is_deeply([keys %{ span_attrs($p) }], ['gone'],
        'converting to the same version changes nothing');

    my $q = payload('unrelated' => 1);
    $schema->convert($q, from => '1.0.0', to => '1.3.0', signal => 'spans');
    is_deeply([keys %{ span_attrs($q) }], ['unrelated'],
        'an attribute no version mentions passes through untouched');
}

# ---- metrics: the metric NAME as well as its attributes ---------------------
{
    my $m = Punk::OpenTelemetry::Schema->load(text => <<'Y');
file_format: 1.1.0
schema_url: https://example.test/m
versions:
  1.1.0:
    metrics:
      changes:
        - rename_metrics:
            old.metric: new.metric
        - rename_attributes:
            attribute_map:
              old.dim: new.dim
Y
    my $p = { resource_metrics => [ { scope_metrics => [ {
        metrics => [ { name => 'old.metric',
                       data_points => [ { attributes => { 'old.dim' => 1 } } ] } ]
    } ] } ] };
    $m->convert($p, from => '1.0.0', to => '1.1.0', signal => 'metrics');
    my $met = $p->{resource_metrics}[0]{scope_metrics}[0]{metrics}[0];
    is($met->{name}, 'new.metric', 'the metric itself is renamed');
    is_deeply([keys %{ $met->{data_points}[0]{attributes} }], ['new.dim'],
        'and its data point attributes');

    $m->convert($p, from => '1.1.0', to => '1.0.0', signal => 'metrics');
    is($p->{resource_metrics}[0]{scope_metrics}[0]{metrics}[0]{name},
       'old.metric', 'and both undo');
}

# ---- nothing fetches over the network ---------------------------------------
{
    ok(!Punk::OpenTelemetry::Schema->can('fetch'),
        'there is no fetch method: a telemetry layer does not get to add a '
      . 'network dependency in the request path');
    # Half of this module is C now, so scanning only the .pm would leave the
    # guarantee half-checked - and passing for the wrong reason is exactly
    # what a promise like this must not do.
    my @sources = grep { defined && -f $_ }
        $INC{'Punk/OpenTelemetry/Schema.pm'},
        'include/otel_schema.h', 'xs/schema.xs';
    ok(scalar @sources >= 1, 'found the module source to scan');
    for my $f (@sources) {
        my $src = do { open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> };
        unlike($src, qr/LWP|HTTP::Tiny|Fetch->new|getaddrinfo|socket\(/,
            "no HTTP client is reachable from $f");
    }
}

# ---- the emitted schema_url reaches the wire, on all three signals ----------
{
    my $url = Punk::OpenTelemetry::Instrument::schema_url();
    like($url, qr{^https://opentelemetry\.io/schemas/}, 'the pinned url');

    # traces: ResourceSpans field 3, ScopeSpans field 3
    my $tp = { resource_spans => [ {
        schema_url => $url,
        scope_spans => [ { schema_url => $url, spans => [ { name => 'x' } ] } ],
    } ] };
    my $req = pb_parse(Punk::OpenTelemetry::Encode::traces_protobuf($tp));
    my $rs  = pb_parse(pb_field($req, 1));
    is(pb_field($rs, 3), $url, 'ResourceSpans.schema_url');
    is(pb_field(pb_parse(pb_field($rs, 2)), 3), $url, 'ScopeSpans.schema_url');

    # metrics: ResourceMetrics field 3, ScopeMetrics field 3
    my $mp = { resource_metrics => [ {
        schema_url => $url,
        scope_metrics => [ { schema_url => $url, metrics => [
            { name => 'm', aggregation => 1,
              data_points => [ { count => 1, sum => 1 } ] } ] } ],
    } ] };
    $req = pb_parse(Punk::OpenTelemetry::Encode::metrics_protobuf($mp));
    my $rm = pb_parse(pb_field($req, 1));
    is(pb_field($rm, 3), $url, 'ResourceMetrics.schema_url');
    is(pb_field(pb_parse(pb_field($rm, 2)), 3), $url,
        'ScopeMetrics.schema_url - which was silently dropped before');

    # logs: ResourceLogs field 3, ScopeLogs field 3
    my $lp = { resource_logs => [ {
        schema_url => $url,
        scope_logs => [ { schema_url => $url,
                          log_records => [ { body => 'x' } ] } ],
    } ] };
    $req = pb_parse(Punk::OpenTelemetry::Encode::logs_protobuf($lp));
    my $rl = pb_parse(pb_field($req, 1));
    is(pb_field($rl, 3), $url, 'ResourceLogs.schema_url - also dropped before');
    is(pb_field(pb_parse(pb_field($rl, 2)), 3), $url, 'ScopeLogs.schema_url');
}

# ---- different schema URLs are not merged -----------------------------------
# The grouping key is the resource PLUS the schema url. Coalescing two
# ResourceSpans that disagree about their vocabulary would relabel one of
# them.
{
    my $p = { resource_spans => [
        { schema_url => 'https://example.test/a',
          scope_spans => [ { spans => [ { name => 'one' } ] } ] },
        { schema_url => 'https://example.test/b',
          scope_spans => [ { spans => [ { name => 'two' } ] } ] },
    ] };
    my $req = pb_parse(Punk::OpenTelemetry::Encode::traces_protobuf($p));
    my @rs = pb_fields($req, 1);
    is(scalar @rs, 2, 'two ResourceSpans stay two on the wire');
    is(pb_field(pb_parse($rs[0]), 3), 'https://example.test/a', 'the first url');
    is(pb_field(pb_parse($rs[1]), 3), 'https://example.test/b',
        'and the second, distinct - they are never coalesced');
}

# ---- what the file can and cannot answer for --------------------------------
# A schema file lists the versions at which something CHANGED, not every
# version that existed. A `from` below the lowest entry is ordinary: it means
# "produced before any of these changes".
{
    my $p = payload('gone' => 1);
    ok(eval { $schema->convert($p, from => '1.0.0', to => '1.1.0',
                               signal => 'spans'); 1 },
        'converting from below the lowest declared version is allowed');

    # above its own version it genuinely cannot know, and saying so beats
    # returning unconverted telemetry that looks converted
    ok(!eval { $schema->convert(payload(), from => '1.3.0', to => '9.0.0',
                                signal => 'spans'); 1 },
        'converting ABOVE the file\'s own version is an error');
    like($@, qr/cannot convert 9\.0\.0/, 'and says which version it cannot do');
}

# ---- the schema file the dist SHIPS ------------------------------------------
# The converter is worth nothing without a real file, and the version this
# dist emits is the one a caller almost always wants - so it ships, and
# loading it takes no configuration and no download.
{
    my $v = Punk::OpenTelemetry::Schema->shipped_version;
    is($v, '1.30.0', 'the shipped version is the pinned one');
    like(Punk::OpenTelemetry::Instrument::schema_url(), qr/\Q$v\E$/,
        'and it is DERIVED from the C pin, so the two cannot drift');

    my $f = Punk::OpenTelemetry::Schema->file_for($v);
    ok(defined $f && -f $f, 'the file is on disk beside the module')
        or diag "file_for returned " . (defined $f ? $f : 'undef');

    my $s = Punk::OpenTelemetry::Schema->load;
    is($s->schema_url, "https://opentelemetry.io/schemas/$v",
        'load() with no arguments gets the shipped file');
    cmp_ok(scalar($s->versions), '>', 20,
        'which is the real upstream file, not a stub');
    my @v = $s->versions;
    is($v[-1], $v, 'its highest version is the one we emit');

    # a rename that really happened upstream, across several versions
    my $p = payload('http.method' => 'GET');
    $s->convert($p, from => '1.20.0', to => '1.30.0', signal => 'spans');
    is_deeply([sort keys %{ span_attrs($p) }], ['http.request.method'],
        'http.method -> http.request.method through the REAL file');

    # and one renamed in a single upstream step, both directions
    my $q = payload('code.function' => 'handler');
    $s->convert($q, from => '1.23.0', to => '1.30.0', signal => 'spans');
    is_deeply([sort keys %{ span_attrs($q) }], ['code.function.name'],
        'code.function -> code.function.name');
    $s->convert($q, from => '1.30.0', to => '1.23.0', signal => 'spans');
    is_deeply([sort keys %{ span_attrs($q) }], ['code.function'],
        'and back again');
}

# ---- the search path ---------------------------------------------------------
# An operator on a version this release predates needs somewhere to put the
# file. That is what the search path is for, and it is the ONLY answer to
# "where does a schema file come from" that is not the network.
{
    is(Punk::OpenTelemetry::Schema->file_for('9.9.9'), undef,
        'an unknown version has no file');
    is(Punk::OpenTelemetry::Schema->for_url('https://example.test/schemas/9.9.9'),
        undef,
        'and an unknown schema url loads as undef - the caller emits the '
      . 'telemetry unchanged rather than reaching out for it');
    ok(Punk::OpenTelemetry::Schema->for_url(
           'https://opentelemetry.io/schemas/1.30.0'),
        'a known one resolves from the shipped directory');

    # a directory the caller supplies wins, so a newer file can be dropped in
    # without a release
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/2.0.0.yaml" or die $!;
    print $fh "file_format: 1.1.0\nschema_url: https://example.test/2.0.0\n"
            . "versions:\n  2.0.0:\n    spans:\n      changes:\n"
            . "        - rename_attributes:\n            attribute_map:\n"
            . "              a: b\n";
    close $fh;
    my $s = Punk::OpenTelemetry::Schema->load(version => '2.0.0', dir => $dir);
    is($s->schema_url, 'https://example.test/2.0.0',
        'a caller-supplied directory supplies versions the dist never shipped');

    local $ENV{OTEL_SCHEMA_DIR} = $dir;
    ok(Punk::OpenTelemetry::Schema->for_url('https://example.test/schemas/2.0.0'),
        'and OTEL_SCHEMA_DIR does the same for an operator with no code');

    # ... but a traversal dressed as a version does not become a file path
    is(Punk::OpenTelemetry::Schema->file_for('../../etc/passwd'), undef,
        'a version that is not a version is refused, not concatenated');
}

# ---- a scope may carry a DIFFERENT schema url than its resource -------------
{
    my $t = Punk::OpenTelemetry::Tracer->new(
        sampler          => 'always_on',
        scope_name       => 'punk',
        schema_url       => 'https://example.test/resource',
        scope_schema_url => 'https://example.test/scope',
    );
    $t->enqueue($t->start('op'));
    my $p = $t->drain;
    is($p->{resource_spans}[0]{schema_url}, 'https://example.test/resource',
        'the resource keeps its own schema url');
    is($p->{resource_spans}[0]{scope_spans}[0]{schema_url},
       'https://example.test/scope',
        'and the scope keeps a DIFFERENT one - they are not the same field');
}

done_testing;
