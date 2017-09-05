use v5.24;
use Test::More;
use Data::Dumper;
use lib 't/lib';
use Carp;
use TestPW;

for my $test (qw<simple circular circular-noerr>) {
    my $input = weaver_input("t/$test");

    my $weaver = Pod::Weaver->new_from_config( { root => "t/$test", } );

    test_basic( $test, $weaver, $input );
}

done_testing;
