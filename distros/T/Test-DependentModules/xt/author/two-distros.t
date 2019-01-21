use strict;
use warnings;

use Test::DependentModules qw( test_modules );
use Test::More;

plan skip_all => 'Make $ENV{TDM_HACK_TESTS} true to run this test'
    unless $ENV{TDM_HACK_TESTS};

test_modules( 'Exception::Class', 'CPAN::Test::Dummy::Perl5::Build::Fails' );

done_testing();
