#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

# Detailed parsing is tested in t/config.t. This tests how Monitoring::Sneck
# uses Monitoring::Sneck::Config.

BEGIN {
    use_ok('Monitoring::Sneck') || print "Bail out!\n";
}

# Helper: write a temp config file with given content, return path
sub write_config {
    my ($content) = @_;
    my ( $fh, $filename ) = tempfile( UNLINK => 1, SUFFIX => '.conf' );
    print $fh $content;
    close $fh;
    return $filename;
}

#
# new() with missing config file
#
{
    my $sneck = Monitoring::Sneck->new( { config => '/nonexistent/path/sneck.conf' } );
    ok( defined $sneck, 'new returns object even with missing config' );
    is( $sneck->{good},             0, 'good is false when config file missing' );
    is( $sneck->{to_return}{error}, 1, 'error flag set when config file missing' );
    like(
        $sneck->{to_return}{errorString},
        qr/^Failed to read in the config file "\/nonexistent\/path\/sneck\.conf"/,
        'errorString mentions read failure and the file'
    );
}

#
# new() with a valid config
#
{
    my $cfg   = write_config("FOO=bar\nchk|/bin/true\n%dbg|/bin/true\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good},             1,  'good is true for valid config' );
    is( $sneck->{to_return}{error}, 0,  'no error for valid config' );
    is( $sneck->{to_return}{errorString}, '', 'errorString empty for valid config' );
    isa_ok( $sneck->{parsed_config}, 'Monitoring::Sneck::Config' );
    is( $sneck->{config}, $cfg, 'config path stored' );
}

#
# new() with an invalid config reports every error with line numbers
#
{
    my $cfg   = write_config("FOO=first\nFOO=second\nthis is not valid\nempty|\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good},             0, 'good is false for invalid config' );
    is( $sneck->{to_return}{error}, 1, 'error set for invalid config' );
    is(
        $sneck->{to_return}{errorString},
        'line 2: variable "FOO" is redefined; '
            . 'line 3: "this is not valid" is not a understood line; '
            . 'line 4: check "empty" has no command',
        'errorString joins every error with line numbers'
    );
    ok( !defined $sneck->{parsed_config}, 'parsed config not kept when invalid' );

    my $ret = $sneck->run;
    is( $ret->{error}, 1, 'run returns the error' );
    ok( !defined $ret->{data}{time}, 'run does not run checks for invalid config' );
}

#
# warnings do not make the config invalid
#
{
    my $cfg   = write_config("chk|/bin/date +%Y%m%d\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good},             1, 'good is true with only warnings' );
    is( $sneck->{to_return}{error}, 0, 'no error with only warnings' );
}

#
# env lines are applied to %ENV only when the config is valid
#
{
    delete $ENV{SNECK_TEST_VAR};
    my $cfg   = write_config("env SNECK_TEST_VAR=hello_world\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good},       1,             'good is true for env line' );
    is( $ENV{SNECK_TEST_VAR}, 'hello_world', 'env line sets %ENV variable' );

    delete $ENV{SNECK_TEST_BAD_VAR};
    $cfg   = write_config("env SNECK_TEST_BAD_VAR=should_not_be_set\nthis is not valid\n");
    $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 0, 'good is false for invalid config with env line' );
    ok( !exists $ENV{SNECK_TEST_BAD_VAR}, 'env line not applied when config invalid' );
}

#
# include option includes raw config in return
#
{
    my $content = "FOO=bar\n";
    my $cfg     = write_config($content);
    my $sneck   = Monitoring::Sneck->new( { config => $cfg, include => 1 } );
    is( $sneck->{good},                    1,        'good true with include option' );
    is( $sneck->{to_return}{data}{config}, $content, 'raw config included in return data' );

    $content = "this is not valid\n";
    $cfg     = write_config($content);
    $sneck   = Monitoring::Sneck->new( { config => $cfg, include => 1 } );
    is( $sneck->{to_return}{data}{config}, $content, 'raw config included even when invalid' );
}

#
# include=0 does not include raw config
#
{
    my $cfg   = write_config("FOO=bar\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg, include => 0 } );
    ok( !defined $sneck->{to_return}{data}{config}, 'raw config not included when include=0' );
}

#
# debug option stored
#
{
    my $cfg   = write_config("FOO=bar\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg, debug => 1 } );
    is( $sneck->{debug}, 1, 'debug option stored' );
    $sneck = Monitoring::Sneck->new( { config => '/nonexistent/path/sneck.conf', debug => 1 } );
    is( $sneck->{debug}, 1, 'debug option stored even when config can not be read' );
}

#
# default config path
#
{
    my $sneck = Monitoring::Sneck->new();
    is( $sneck->{config}, '/usr/local/etc/sneck.conf', 'default config path used with no args' );
    $sneck = Monitoring::Sneck->new( {} );
    is( $sneck->{config}, '/usr/local/etc/sneck.conf', 'default config path used with empty hash' );
}

done_testing();
