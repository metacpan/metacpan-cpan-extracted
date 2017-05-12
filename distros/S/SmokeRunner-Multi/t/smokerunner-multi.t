use strict;
use warnings;

use File::Spec;
use Test::More;

BEGIN
{
    eval "use Test::Command";
    plan skip_all => 'These tests require Test::Command'
        if $@;
}

plan tests => 9;

use File::Which qw( which );

use lib 't/lib';
use SmokeRunner::Multi::Test;


test_setup();
write_four_sets();

$ENV{PERL5LIB} = join ':', @INC;
my @script = ( $^X, File::Spec->catfile( 'script', 'smokerunner-multi' ) );

HELP:
{
    my $cmd = Test::Command->new( cmd => [ @script, 'help' ] );
    exit_is_num( $cmd, 0,
                 'help command exits with 0' );
    stdout_like( $cmd, qr/accepts the following commands/,
                 'help stdout output contains expected text' );
    stderr_is_eq( $cmd, '',
                  'help stderr output is empty' );
}

LIST:
{
    my $cmd = Test::Command->new( cmd => [ @script, 'list' ] );
    exit_is_num( $cmd, 0,
                 'list command exits with 0' );
    stdout_like( $cmd, qr/set1\s+\|\s+\|\s+never/,
                 'list stdout output contains expected text' );
    stderr_is_eq( $cmd, '',
                  'list stderr output is empty' );
}

LIST:
{
 SKIP:
    {
        skip 'These tests require that prove be in the PATH.', 3
            unless which('prove');

        my $cmd = Test::Command->new( cmd => [ @script, 'run' ] );
        exit_is_num( $cmd, 0,
                     'run command exits with 0' );
        stdout_is_eq( $cmd, '',
                      'run stdout output is empty' );
        stderr_is_eq( $cmd, '',
                      'run stderr output is empty' );
    }
}
