#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

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
    is( $sneck->{good}, 0, 'good is false when config file missing' );
    is( $sneck->{to_return}{error}, 1, 'error flag set when config file missing' );
    like(
        $sneck->{to_return}{errorString},
        qr/Failed to read/,
        'errorString mentions read failure'
    );
}

#
# new() with valid minimal config (only comments and blank lines)
#
{
    my $cfg = write_config("# just a comment\n\n# another comment\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 1, 'good is true for comment-only config' );
    is( $sneck->{to_return}{error}, 0, 'no error for comment-only config' );
}

#
# Variable parsing
#
{
    my $cfg = write_config("FOO=bar\nBAZ=qux\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 1, 'good is true for variable config' );
    is( $sneck->{vars}{FOO}, 'bar', 'variable FOO parsed correctly' );
    is( $sneck->{vars}{BAZ}, 'qux', 'variable BAZ parsed correctly' );
}

#
# Variable with = in value
#
{
    my $cfg = write_config("CONNSTR=host=localhost port=5432\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 1, 'good is true for variable with = in value' );
    is( $sneck->{vars}{CONNSTR}, 'host=localhost port=5432', 'variable value with = preserved' );
}

#
# Redefined variable → error
#
{
    my $cfg = write_config("FOO=first\nFOO=second\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 0, 'good is false when variable redefined' );
    is( $sneck->{to_return}{error}, 1, 'error set when variable redefined' );
    like( $sneck->{to_return}{errorString}, qr/redefined/, 'errorString mentions redefined' );
}

#
# Check definition parsed
#
{
    my $cfg = write_config("mycheck|/bin/true\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 1, 'good is true when check defined' );
    is( $sneck->{checks}{mycheck}, '/bin/true', 'check command stored correctly' );
}

#
# Redefined check → error
#
{
    my $cfg = write_config("mycheck|/bin/true\nmycheck|/bin/false\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 0, 'good is false when check redefined' );
    is( $sneck->{to_return}{error}, 1, 'error set when check redefined' );
}

#
# Unknown line → error
#
{
    my $cfg = write_config("this is not valid\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 0, 'good is false for unknown line' );
    is( $sneck->{to_return}{error}, 1, 'error set for unknown line' );
    like( $sneck->{to_return}{errorString}, qr/not a understood line/, 'errorString mentions unrecognized line' );
}

#
# Debug check (% prefix) parsed into checks hash
#
{
    my $cfg = write_config("%dbgcheck|/bin/true\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 1, 'good is true when debug check defined' );
    ok( defined $sneck->{checks}{'%dbgcheck'}, 'debug check stored with % prefix' );
}

#
# env line sets %ENV
#
{
    my $cfg = write_config("env SNECK_TEST_VAR=hello_world\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg } );
    is( $sneck->{good}, 1, 'good is true for env line' );
    is( $ENV{SNECK_TEST_VAR}, 'hello_world', 'env line sets %ENV variable' );
}

#
# include option includes raw config in return
#
{
    my $content = "FOO=bar\n";
    my $cfg     = write_config($content);
    my $sneck   = Monitoring::Sneck->new( { config => $cfg, include => 1 } );
    is( $sneck->{good}, 1, 'good true with include option' );
    is( $sneck->{to_return}{data}{config}, $content, 'raw config included in return data' );
}

#
# include=0 does not include raw config
#
{
    my $cfg   = write_config("FOO=bar\n");
    my $sneck = Monitoring::Sneck->new( { config => $cfg, include => 0 } );
    ok( !defined $sneck->{to_return}{data}{config}, 'raw config not included when include=0' );
}

done_testing();
