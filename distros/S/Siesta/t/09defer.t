#!perl -w
use strict;
use Test::More tests => 22;
use lib qw(t/lib);
use Siesta::Test;
use Siesta;
use Siesta::Deferred;

my $user = Siesta::Member->find_or_create({ email => 'test@foo' });
my $message = Siesta::Message->new(\*DATA);
ok( $message, "made a message from DATA" );

is( $message->subject, "yoohoo", "  on which the subject is correct" );

my @deferred = Siesta::Deferred->retrieve_all;
is( scalar @deferred, 0, "we have no deferred messages" );

my $id = $message->defer(
    why => 'the hell of it',
    who => $user,
   )->id;
ok( $id, "deferred a message $id" );

@deferred = Siesta::Deferred->retrieve_all;
is( scalar @deferred, 1, "we have 1 deferred message" );

my $def = shift @deferred;

is( $def->message->subject, "yoohoo", "deferred message has correct subject" );
is( $def->why, "the hell of it", "deferred message has correct deferred reason" );
is( $def->id, $id, "id matches" );

$def = Siesta::Deferred->retrieve($id);
ok( $def, "fetch via id" );

$message->subject("woobly");
my $other = $message->defer(
    why => 'to check that ids work',
    who => Siesta::Member->find_or_create({ email => 'test@foo' }),
   )->id;

ok( $other, "deferred a second mail" );
@deferred = Siesta::Deferred->retrieve_all;
is( scalar @deferred, 2 );
isnt( $id, $other, "two different ids" );

my $two = Siesta::Deferred->retrieve($other);
is( $two->why, 'to check that ids work' );

# kill it
$def->delete;

@deferred = Siesta::Deferred->retrieve_all;
is( scalar @deferred, 1, "deleted one" );

$two->delete;

@deferred = Siesta::Deferred->retrieve_all;
is( scalar @deferred, 0, "we have 0 deferred messages again" );


## start and defer

my $list = Siesta::List->find_or_create({
    name         => 'defer',
    owner        => $user,
    post_address => 'spangly',
   });

$list->add_member( $user );

$list->set_plugins(post => qw( ReplyTo Send ));
$message->plugins([ $list->plugins ]);

$message->plugins->[0]->pref( 'munge', 1 );

my $handle = $message->defer(who => $user, why => 'test');
ok( $handle, "froze something with somewhere to go" );

@deferred = Siesta::Deferred->retrieve_all;
is( scalar @deferred, 1, "we have 1 deferred message" );

$handle->resume;

@deferred = Siesta::Deferred->retrieve_all;
is( scalar @deferred, 0, "not deferred now" );

is( $Siesta::Send::Test::sent[-1]->header('reply-to'), 'spangly',
    "resumed message ran the right stages" );

# check cascading delete on $user
$handle = $message->defer(who => $user, why => 'test');
ok( $handle, "froze something with somewhere to go" );

@deferred = Siesta::Deferred->retrieve_all;
is( scalar @deferred, 1, "we have 1 deferred message" );

$user->delete;

@deferred = Siesta::Deferred->retrieve_all;
is( scalar @deferred, 0, "cascading delete" );



__DATA__
From: jay@front-of.quick-stop
To: dealers@front-of.quick-stop
Subject: yoohoo

All you motherfuckers are gonna pay, You are the ones who are the
ball-lickers.  We're gonna fuck your mothers while you watch and cry
like little bitches.  Once we get to Hollywood and find those Miramax
fucks who are making that movie, we're gonna make 'em eat our shit,
then shit out our shit, then eat their shit which is made up of our
shit that we made 'em eat.  Then you're all fucking next.

Love, Jay and Silent Bob.
