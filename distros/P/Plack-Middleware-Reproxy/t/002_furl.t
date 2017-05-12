use strict;
use lib "t";
use t::ReproxyTest;
use Test::More;
# XXX too lazy to add Test::Requires in my deps
if ( ! eval { require Furl } || $@ ) {
    plan skip_all => "This test requires Furl";
}
    

run_reproxy_tests reproxy_class => 'Reproxy::Furl';

done_testing;
