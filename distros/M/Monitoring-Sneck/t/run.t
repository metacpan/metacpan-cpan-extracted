#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

BEGIN {
    use_ok('Monitoring::Sneck') || print "Bail out!\n";
}

sub write_config {
    my ($content) = @_;
    my ( $fh, $filename ) = tempfile( UNLINK => 1, SUFFIX => '.conf' );
    print $fh $content;
    close $fh;
    return $filename;
}

# Find a perl we can use for exit-code checks
my $perl = $^X;

#
# run() when good=0 returns error without running checks
#
{
    my $sneck = Monitoring::Sneck->new( { config => '/nonexistent/sneck.conf' } );
    my $ret   = $sneck->run;
    is( $ret->{error}, 1, 'run returns error hash when good=0' );
    ok( !defined $ret->{data}{time}, 'time not set when good=0' );
}

#
# run() sets hostname and time in return data
#
{
    my $cfg   = write_config("# empty\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    ok( defined $ret->{data}{hostname}, 'hostname is set' );
    like( $ret->{data}{hostname}, qr/\S/, 'hostname is non-empty' );
    ok( defined $ret->{data}{time}, 'time is set' );
    like( $ret->{data}{time}, qr/^\d+$/, 'time is an integer (no decimal point)' );
    ok( defined $ret->{data}{run_time}, 'run_time is set' );
    like( $ret->{data}{run_time}, qr/^\d+\.\d+$/, 'run_time is a decimal number' );
}

#
# run() ok check (exit 0) increments ok, alert stays 0
#
{
    my $cfg   = write_config("ok_check|$perl -e 'exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{ok},       1, 'ok count is 1 for exit-0 check' );
    is( $ret->{data}{warning},  0, 'warning count is 0' );
    is( $ret->{data}{critical}, 0, 'critical count is 0' );
    is( $ret->{data}{unknown},  0, 'unknown count is 0' );
    is( $ret->{data}{errored},  0, 'errored count is 0' );
    is( $ret->{data}{alert},    0, 'alert is 0 for ok check' );
}

#
# run() warning check (exit 1) increments warning, sets alert
#
{
    my $cfg   = write_config("warn_check|$perl -e 'print \"warning output\\n\"; exit 1'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{ok},      0, 'ok count is 0 for warning check' );
    is( $ret->{data}{warning}, 1, 'warning count is 1' );
    is( $ret->{data}{alert},   1, 'alert is 1 for warning check' );
    is( $ret->{data}{checks}{warn_check}{exit}, 1, 'exit code stored as 1' );
    like( $ret->{data}{alertString}, qr/warning output/, 'alertString contains warning output' );
}

#
# run() critical check (exit 2) increments critical, sets alert
#
{
    my $cfg   = write_config("crit_check|$perl -e 'print \"critical output\\n\"; exit 2'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{critical}, 1, 'critical count is 1' );
    is( $ret->{data}{alert},    1, 'alert is 1 for critical check' );
    is( $ret->{data}{checks}{crit_check}{exit}, 2, 'exit code stored as 2' );
    like( $ret->{data}{alertString}, qr/critical output/, 'alertString contains critical output' );
}

#
# run() unknown check (exit 3) increments unknown, sets alert
#
{
    my $cfg   = write_config("unk_check|$perl -e 'print \"unknown output\\n\"; exit 3'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{unknown}, 1, 'unknown count is 1' );
    is( $ret->{data}{alert},   1, 'alert is 1 for unknown check' );
    like( $ret->{data}{alertString}, qr/unknown output/, 'alertString contains unknown output' );
}

#
# run() errored check (exit > 3) increments errored, sets alert
#
{
    my $cfg   = write_config("err_check|$perl -e 'exit 4'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{errored}, 1, 'errored count is 1 for exit-4 check' );
    is( $ret->{data}{alert},   1, 'alert is 1 for errored check' );
}

#
# run() check result contains check, ran, output, exit, run_time fields
#
{
    my $cfg   = write_config("my_check|$perl -e 'print \"hello\"; exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    my $c     = $ret->{data}{checks}{my_check};
    ok( defined $c,                'check result hash exists' );
    ok( defined $c->{check},      'check field present' );
    ok( defined $c->{ran},        'ran field present' );
    ok( defined $c->{output},     'output field present' );
    ok( defined $c->{exit},       'exit field present' );
    ok( defined $c->{run_time},   'run_time field present' );
    like( $c->{run_time}, qr/^\d+\.\d+$/, 'check run_time is a decimal number' );
    is( $c->{output}, 'hello', 'check output captured correctly' );
}

#
# run() variable substitution in checks
#
{
    my $cfg = write_config("MYVAR=world\ngreet_check|$perl -e 'print \"%MYVAR%\"; exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{checks}{greet_check}{output}, 'world', 'variable substituted in check output' );
    like( $ret->{data}{checks}{greet_check}{ran}, qr/world/, 'ran field shows post-substitution command' );
    unlike( $ret->{data}{checks}{greet_check}{check}, qr/world/, 'check field shows pre-substitution command' );
}

#
# run() debug check (% prefix) stored under debugs, not counted in ok/warning/etc
#
{
    my $cfg   = write_config("%dbg_check|$perl -e 'exit 1'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{ok},      0, 'ok count 0 for debug-only run' );
    is( $ret->{data}{warning}, 0, 'warning count 0 for debug check' );
    is( $ret->{data}{alert},   0, 'alert stays 0 for debug check' );
    ok( defined $ret->{data}{debugs}{dbg_check}, 'debug check stored under debugs' );
    ok( !defined $ret->{data}{checks}{dbg_check}, 'debug check not stored under checks' );
}

#
# run() multiple checks — counts accumulate correctly
#
{
    my $cfg = write_config(
        "ok1|$perl -e 'exit 0'\n"
            . "ok2|$perl -e 'exit 0'\n"
            . "warn1|$perl -e 'exit 1'\n"
            . "crit1|$perl -e 'exit 2'\n"
    );
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{ok},       2, 'two ok checks counted' );
    is( $ret->{data}{warning},  1, 'one warning check counted' );
    is( $ret->{data}{critical}, 1, 'one critical check counted' );
    is( $ret->{data}{alert},    1, 'alert set when any non-ok check present' );
}

#
# run() vars returned in data
#
{
    my $cfg   = write_config("TESTKEY=testval\nsome_check|$perl -e 'exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{vars}{TESTKEY}, 'testval', 'vars hash returned in run data' );
}

#
# run() alertString is empty when all checks ok
#
{
    my $cfg   = write_config("all_ok|$perl -e 'print \"fine\"; exit 0'\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    my $ret   = $sneck->run;
    is( $ret->{data}{alertString}, '', 'alertString empty when all checks ok' );
}

done_testing();
