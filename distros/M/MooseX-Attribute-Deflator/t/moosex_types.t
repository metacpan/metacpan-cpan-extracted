use Test::More;
use warnings;
use strict;
use lib qw(t/lib);

package Test;

use Moose;
use JSON;

use Types q(:all);

has hashref => ( is => 'rw', isa => MyHashRef, traits => ['Deflator'] );
has die => ( is => 'rw', isa => Die, traits => ['Deflator'] );

package main;

my $obj = Test->new( hashref => { foo => 'bar' }, die => { foo => 'bar' } );

is_deeply( $obj->meta->get_attribute('hashref')->get_value($obj), { foo => 'bar' } );

is( $obj->meta->get_attribute('hashref')->deflate($obj), '{"foo":"bar"}' );

eval { $obj->meta->get_attribute('die')->deflate($obj) };
like($@, qr/failed to deflate/i, 'throws error ok');

done_testing;