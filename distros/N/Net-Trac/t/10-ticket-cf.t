use warnings; 
use strict;

use Test::More;
use File::Spec;
unless (`which trac-admin`) { plan skip_all => 'You need trac installed to run the tests'; }
plan tests => 11;

use_ok('Net::Trac::Connection');
use_ok('Net::Trac::Ticket');
Net::Trac::Ticket->add_custom_props( 'foo', 'bar' );
require 't/setup_trac.pl';

my $tr = Net::Trac::TestHarness->new();
my $cf_conf = <<EOF;
[ticket-custom]

foo = text
bar = text
EOF

ok($tr->start_test_server($cf_conf), "The server started!");

my $trac = Net::Trac::Connection->new(
    url      => $tr->url,
    user     => 'hiro',
    password => 'yatta'
);

isa_ok( $trac, "Net::Trac::Connection" );
is($trac->url, $tr->url);
my $ticket = Net::Trac::Ticket->new( connection => $trac);
ok(
    $ticket->create(
        summary => 'test cf fields',
        foo     => 'foo_foo',
        bar     => 'bar_bar',
    )
);

can_ok($ticket, 'load');
ok($ticket->load(1));
ok($ticket->history, "The ticket has some history");
is($ticket->foo, 'foo_foo', "The ticket has cf foo");
is($ticket->bar, 'bar_bar', "The ticket has cf bar");

