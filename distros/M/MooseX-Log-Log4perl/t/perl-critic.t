use strict;
use warnings;
use File::Spec;
use Test::More;

if ( not($ENV{TEST_AUTHOR} || $ENV{TEST_CRITIC}) ) {
    my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $@ ) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
diag("Data: $rcfile" . -f $rcfile);
Test::Perl::Critic->import( -profile => $rcfile, -verbose => 6 );
all_critic_ok();
