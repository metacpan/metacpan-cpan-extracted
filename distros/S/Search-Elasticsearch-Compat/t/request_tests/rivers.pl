#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

no warnings 'redefine';

### RIVER ###
ok $es->create_river( type => 'dummy', river => 'foo' )->{ok}, 'Create river';
wait_for_es(2);
is $es->get_river( river => 'foo' )->{_type}, 'foo', 'Get river';
is $es->river_status( river => 'foo' )->{_id}, '_status', 'River status';
ok $es->delete_river( river => 'foo' )->{ok}, 'Delete river';

missing($_) for qw(get_river river_status);

$es->delete_index( index => '_river' );

#===================================
sub missing {
#===================================
    my $action = shift;
    throws_ok { $es->$action( river => 'foobar' ) } qr/Missing/,
        " - $action missing";
    ok !$es->$action( river => 'foobar', ignore_missing => 1 ),
        " - $action ignore_missing";
}

1
