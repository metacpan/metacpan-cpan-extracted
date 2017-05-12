use strict;
use warnings;

use Net::FreeIPA::Request;

use Test::More;

my $r;

=new init

=cut

$r = Net::FreeIPA::Request->new('c');
isa_ok($r, 'Net::FreeIPA::Request', 'a Net::FreeIPA::Request instance created');

$r = mkrequest('c');
isa_ok($r, 'Net::FreeIPA::Request', 'a Net::FreeIPA::Request instance created using mkrequest');

is($r->{command}, 'c', 'command set');
is_deeply($r->{args}, [], 'empty array ref as args by default');
is_deeply($r->{opts}, {}, 'empty hash ref as opts by default');
is_deeply($r->{rpc}, {}, 'empty hash ref as rpc by default');
is_deeply($r->{post}, {}, 'empty hash ref as post by default');
ok(! defined($r->{error}), 'No error attribute set by default');
ok(! defined($r->{id}), 'No id attribute set by default');
ok(! $r->is_error(), 'is_error false');
ok($r, 'overloaded boolean = true if no error via is_error');
ok(! defined($r->post_data()), "post_data returns undef with no id set");

$r = mkrequest('d', args => [qw(1 2)], opts => {a => 3, b => 4}, error => 'message', rpc => {woo => 'hoo'}, post => {awe => 'some'}, id => 123);
is($r->{command}, 'd', 'command set 2');
is_deeply($r->{args}, [qw(1 2)], 'array ref as args');
is_deeply($r->{opts}, {a => 3, b => 4}, 'hash ref as opts');
is_deeply($r->{rpc}, {woo => 'hoo'}, 'hash ref as rpc');
is_deeply($r->{post}, {awe => 'some'}, 'hash ref as post');
is($r->{error}, 'message', 'error attribute set');
is($r->{id}, 123, 'id attribute set');
ok($r->is_error(), 'is_error true');
ok(! $r, 'overloaded boolean = false on error via is_error');
is_deeply($r->post_data(), {
    method => 'd',
    params => [[qw(1 2)], {a=>3,b=>4}],
    id => 123,
}, "post_data returns RPC POST hashref");

done_testing();
