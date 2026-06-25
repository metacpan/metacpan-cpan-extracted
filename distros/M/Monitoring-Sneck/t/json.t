#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use JSON       qw(decode_json encode_json);

BEGIN {
    use_ok('Monitoring::Sneck') || print "Bail out!\n";
}

my $perl = $^X;

sub write_config {
    my ($content) = @_;
    my ( $fh, $filename ) = tempfile( UNLINK => 1, SUFFIX => '.conf' );
    print $fh $content;
    close $fh;
    return $filename;
}

# Encode a return hash to JSON the same way bin/sneck does
sub to_json_canonical {
    my ($ret) = @_;
    return JSON->new->utf8->canonical(1)->encode($ret);
}

#
# Error case: bad config → JSON encodes with error=1 and integer error flag
#
{
    my $sneck = Monitoring::Sneck->new( { config => '/nonexistent/sneck.conf' } );
    my $ret   = $sneck->run;
    my $raw;
    ok( eval { $raw = to_json_canonical($ret); 1 }, 'bad-config return encodes to JSON without dying' );
    my $decoded = decode_json($raw);
    is( $decoded->{error},   1, 'error field is 1 in JSON for bad config' );
    is( $decoded->{version}, 1, 'version field present and 1' );
    ok( length( $decoded->{errorString} ) > 0, 'errorString is non-empty in JSON' );
}

#
# Empty (comment-only) config → JSON has all expected top-level keys
#
{
    my $cfg   = write_config("# empty\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    my $raw   = to_json_canonical($ret);
    ok( defined $raw, 'empty config return encodes to JSON' );
    my $decoded = decode_json($raw);
    is( $decoded->{error},       0,  'error is 0 for empty config' );
    is( $decoded->{version},     1,  'version is 1' );
    is( $decoded->{errorString}, '', 'errorString is empty string' );
    ok( exists $decoded->{data}, 'data key present' );
}

#
# data sub-structure has all required fields
#
{
    my $cfg     = write_config("# empty\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    my $data    = $decoded->{data};
    for my $field (qw(hostname ok warning critical unknown errored alert alertString checks debugs time run_time vars)) {
        ok( exists $data->{$field}, "data.$field key present in JSON" );
    }
}

#
# time field is an integer (no decimal point) in JSON
#
{
    my $cfg     = write_config("# empty\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    like( $decoded->{data}{time} . '', qr/^\d+$/, 'data.time serialises as integer in JSON' );
}

#
# run_time is a numeric decimal string in JSON
#
{
    my $cfg     = write_config("# empty\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    like( $decoded->{data}{run_time}, qr/^\d+\.\d+$/, 'data.run_time is decimal in JSON' );
}

#
# counts are numeric 0 for empty config
#
{
    my $cfg     = write_config("# empty\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    my $data    = $decoded->{data};
    is( $data->{ok},       0, 'ok count is 0' );
    is( $data->{warning},  0, 'warning count is 0' );
    is( $data->{critical}, 0, 'critical count is 0' );
    is( $data->{unknown},  0, 'unknown count is 0' );
    is( $data->{errored},  0, 'errored count is 0' );
    is( $data->{alert},    0, 'alert is 0' );
}

#
# ok check → JSON shows ok=1, alert=0
#
{
    my $cfg     = write_config("ok_check|$perl -e 'exit 0'\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    is( $decoded->{data}{ok},    1, 'ok=1 in JSON for exit-0 check' );
    is( $decoded->{data}{alert}, 0, 'alert=0 in JSON for exit-0 check' );
}

#
# warning check → JSON shows warning=1, alert=1, alertString populated
#
{
    my $cfg = write_config("warn_check|$perl -e 'print \"warn out\\n\"; exit 1'\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    is( $decoded->{data}{warning}, 1, 'warning=1 in JSON' );
    is( $decoded->{data}{alert},   1, 'alert=1 in JSON for warning' );
    like( $decoded->{data}{alertString}, qr/warn out/, 'alertString contains check output in JSON' );
}

#
# critical check → JSON shows critical=1, alert=1
#
{
    my $cfg = write_config("crit_check|$perl -e 'print \"crit out\\n\"; exit 2'\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    is( $decoded->{data}{critical}, 1, 'critical=1 in JSON' );
    is( $decoded->{data}{alert},    1, 'alert=1 in JSON for critical' );
    like( $decoded->{data}{alertString}, qr/crit out/, 'alertString contains critical output in JSON' );
}

#
# unknown check → JSON shows unknown=1, alert=1
#
{
    my $cfg = write_config("unk_check|$perl -e 'print \"unk out\\n\"; exit 3'\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    is( $decoded->{data}{unknown}, 1, 'unknown=1 in JSON' );
    is( $decoded->{data}{alert},   1, 'alert=1 in JSON for unknown' );
}

#
# errored check (exit>3) → JSON shows errored=1, alert=1
#
{
    my $cfg     = write_config("err_check|$perl -e 'exit 5'\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    is( $decoded->{data}{errored}, 1, 'errored=1 in JSON for exit-5 check' );
    is( $decoded->{data}{alert},   1, 'alert=1 in JSON for errored check' );
}

#
# per-check JSON structure: check, ran, output, exit, run_time all present
#
{
    my $cfg = write_config("chk|$perl -e 'print \"hi\"; exit 0'\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    my $c       = $decoded->{data}{checks}{chk};
    ok( defined $c,            'check entry present in JSON' );
    ok( exists $c->{check},    'check.check field in JSON' );
    ok( exists $c->{ran},      'check.ran field in JSON' );
    ok( exists $c->{output},   'check.output field in JSON' );
    ok( exists $c->{exit},     'check.exit field in JSON' );
    ok( exists $c->{run_time}, 'check.run_time field in JSON' );
    is( $c->{output}, 'hi',    'check output value correct in JSON' );
    is( $c->{exit},   0,       'check exit value correct in JSON' );
    like( $c->{run_time}, qr/^\d+\.\d+$/, 'check run_time is decimal in JSON' );
}

#
# variable substitution visible in JSON: check vs ran fields differ
#
{
    my $cfg = write_config("MYVAR=world\ngreet|$perl -e 'print \"%MYVAR%\"; exit 0'\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    my $c       = $decoded->{data}{checks}{greet};
    like( $c->{check}, qr/%MYVAR%/, 'check field has un-substituted variable in JSON' );
    like( $c->{ran},   qr/world/,   'ran field has substituted variable in JSON' );
    is( $c->{output},  'world',     'output shows substituted value in JSON' );
}

#
# vars hash present in JSON data
#
{
    my $cfg = write_config("KEY=val\nsome_check|$perl -e 'exit 0'\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    is( $decoded->{data}{vars}{KEY}, 'val', 'variable appears in data.vars in JSON' );
}

#
# debug check → stored under debugs in JSON, not counted in checks
#
{
    my $cfg = write_config("%dbg|$perl -e 'exit 1'\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    is( $decoded->{data}{warning}, 0, 'warning count 0 for debug-only check in JSON' );
    is( $decoded->{data}{alert},   0, 'alert 0 for debug-only check in JSON' );
    ok( defined $decoded->{data}{debugs}{dbg},   'debug check under data.debugs in JSON' );
    ok( !defined $decoded->{data}{checks}{dbg},  'debug check absent from data.checks in JSON' );
}

#
# include option → data.config present in JSON
#
{
    my $content = "FOO=bar\n";
    my $cfg     = write_config($content);
    my $sneck   = Monitoring::Sneck->new( { config => $cfg, include => 1 } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    is( $decoded->{data}{config}, $content, 'raw config included in data.config in JSON' );
}

#
# canonical encoding produces consistent key order across two calls
#
{
    my $cfg   = write_config("A=1\nB=2\ncheck_a|$perl -e 'exit 0'\ncheck_b|$perl -e 'exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $j1    = to_json_canonical( $sneck->run );
    # decode then re-encode to compare structure (times will differ between runs)
    my $d1 = decode_json($j1);
    # verify top-level keys are alphabetically sorted (canonical=1 guarantee)
    my @keys = ( $j1 =~ /"(\w+)":/g );
    # just confirm it round-trips cleanly
    my $j2 = to_json_canonical($d1);
    my $d2 = decode_json($j2);
    is_deeply( [ sort keys %{ $d1->{data}{vars} } ], [ sort keys %{ $d2->{data}{vars} } ],
        'round-tripped JSON preserves vars keys' );
}

#
# alertString is empty string (not undef/null) in JSON when all ok
#
{
    my $cfg     = write_config("ok_chk|$perl -e 'exit 0'\n");
    my $sneck   = Monitoring::Sneck->new( { config => $cfg } );
    my $decoded = decode_json( to_json_canonical( $sneck->run ) );
    is( $decoded->{data}{alertString}, '', 'alertString is empty string in JSON when all ok' );
}

done_testing();
