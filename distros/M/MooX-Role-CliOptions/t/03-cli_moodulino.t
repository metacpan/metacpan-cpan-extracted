#!perl

use strict;
use warnings;

use Test::More;

use Capture::Tiny ':all';

use FindBin;

my $example_dir = "$FindBin::Bin/../examples";
my $script      = $example_dir . "/moodulino.pl";

# it seems that a number of test platforms don't spawn a proper child
# environment for 'system' calls like this. specifically, they fail to have
# a lib path that includes Moo even though it is specified as a requirement.
my ( $stdout, $stderr, $exit ) = capture {
    system($script );
};
plan skip_all => "spawned process can't find modules"
  if $stderr || ( $exit >> 8 > 0 );

like( $stdout, qr/caller-stack is empty/,     'caller-stack was empty' );
like( $stdout, qr/running from command line/, 'ran from command line' );

is( $stderr, '', 'no warnings are present' );

my @args = ( '--custom_opt=foo', );

( $stdout, $stderr, $exit ) = capture {
    system( $script, @args );
};
like( $stdout, qr/custom_opt/, 'custom opt set from command line' );

done_testing();
exit;

__END__
