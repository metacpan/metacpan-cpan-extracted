use strict;
use warnings;

use Test::DependentModules qw( test_module );
use Test::More;

plan skip_all => 'Make $ENV{TDM_HACK_TESTS} true to run this test'
    unless $ENV{TDM_HACK_TESTS};

for my $mod ( 'Exception::Class', 'CPAN::Test::Dummy::Perl5::Build::Fails' ) {
    test_module($mod);
}

done_testing();
