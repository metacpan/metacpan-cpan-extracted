use Test::More tests => 36;

our $orig_ok = \&Test::Carp::_ok;

my @function_list = qw(
    does_carp               does_cluck 
    does_croak              does_confess 
    does_carp_that_matches  does_cluck_that_matches
    does_croak_that_matches does_confess_that_matches    
);

require Test::Carp;
diag( "Testing Test::Carp $Test::Carp::VERSION" );

no strict 'refs';
for my $func (@function_list) {
    ok(!defined &{"main::$func" }, "$func() not imported");
}

Test::Carp->import;

for my $func (@function_list) {
    ok(defined &{"main::$func" }, "$func() imported");
}

my $fake_ok = sub {};
Test::Carp->import($fake_ok);
ok(\&Test::Carp::_ok eq $fake_ok, 'set ok() via import (i.e. use()) - is new');
ok(\&Test::Carp::_ok ne $orig_ok, 'set ok() via import (i.e. use()) - not orig');

package X;

require Test::Carp;

no strict 'refs';
for my $func (@function_list) {
    Test::More::ok(!defined &{"X::$func" }, "$func() not imported");
}

Test::Carp->import;

for my $func (@function_list) {
    Test::More::ok(defined &{"X::$func" }, "$func() imported");
}
{
    my $fake_ok = sub {};
    Test::Carp->import($fake_ok);
    Test::More::ok(\&Test::Carp::_ok eq $fake_ok, 'set ok() via import (i.e. use()) - is new');
    Test::More::ok(\&Test::Carp::_ok ne $main::orig_ok, 'set ok() via import (i.e. use()) - not orig');
}
package main;
