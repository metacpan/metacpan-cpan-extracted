# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POE-Event-Message.t'

#########################

use Test::More tests => 5;

BEGIN { use_ok('POE::Event::Message') };           # 01

my $msg = new POE::Event::Message;
ok( defined $msg, "Instantiation okay" );          # 02

$msg->body( "Just testing" );
my $body = $msg->body();
is ( $body, "Just testing", "Body is okay" );      # 03

my $mid = $msg->id();
my $reply = new POE::Event::Message( $msg );

my $rid = $reply->id();
my $r2id = $reply->r2id();
isnt ( $rid, $mid, "Reply ID is NOT orig ID" );    # 05
is ($mid, $r2id, "Reply-to ID is orig msg ID" );   # 04

# TOOD: lots more... see Header.t too.
#########################
