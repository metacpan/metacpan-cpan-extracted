#!perl -w
use strict;
use Test::More tests => 6;
use lib qw(t/lib);
use Siesta::Test;
use Siesta::Message;

my $msg = Siesta::Message->new( \*DATA );
isa_ok( $msg, 'Siesta::Message' );
is( ( $msg->to )[0], 'dealers', "->to" );
is( $msg->from, 'Jay@front_of.quick_stop', "->from" );

$msg->reply( body => 'foo' );

my $sent = $Siesta::Send::Test::sent[-1];
is( $sent->from, 'dealers', "reply" );
is( ( $sent->to )[0], 'Jay@front_of.quick_stop' );
is( $sent->body, "foo" );

__DATA__
From: Jay <Jay@front_of.quick_stop>
To: <dealers>

bar
