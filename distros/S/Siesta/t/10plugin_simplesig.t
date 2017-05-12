#!perl -w
# $Id: 10plugin_simplesig.t,v 1.10 2003/03/26 07:16:42 muttley Exp $
use strict;
use Test::More tests => 2;
use lib qw(t/lib);
use Siesta::Test;
use Siesta::Plugin::SimpleSig;
use Siesta::Message;

my $mail = Siesta::Message->new(<<'END');
From: richardc
To: foo

Clerks, 1994.  http://us.imdb.com/Quotes?0109445

-- 
Woman with daughter: Excuse me, do you sell videos?
Randal Graves: Yeah, what're you looking for?
Woman with daughter: Happy Scrappy Hero Pup.
Randal Graves: Okay, hang on, I'm on the phone with the distribution house now, lemme make sure we got it. What was it called again?
Woman with daughter: Happy Scrappy Hero Pup.
Daughter: Happy Scrappy...
Woman with Daughter: She loves it.
Randal Graves: Obviously. Yeah, hello, this is RST Video, customer number 4352, I need to place an order. Okay, I need one each of the following tapes: "Whispers in the Wind", "To Each His Own", "Put It Where It Doesn't Belong", "My Pipes Need Cleaning", "All Tit-Fucking Volume 8", "I Need Your Cock", "Ass-Worshipping Rim-Jobbers", "My Cunt Needs Shafts", "Cum Clean", "Cum-Gargling Naked Sluts", "Cum Buns III", "Cumming in Socks", "Cum On Eileen", "Huge Black Cocks and Pearly White Cum", "Men Alone II: the KY Connection", "Pink Pussy Lips", and, uh, oh yeah, "All Holes Filled with Hard Cock". Uh-huh...yeah...Oh, wait, and, what was that called again?
END


my $reply;
my $list = Siesta::List->create({
    name => 'simplesig',
    owner => Siesta::Member->create({ email => 'Daddy' }),
   });

my $plugin = Siesta::Plugin::SimpleSig->new(list => $list, queue => 'test' );

ok( $plugin->process($mail), "reject super-long sig" );
like( $Siesta::Send::Test::sent[-1]->body, 
     qr{Daddy has set this list to have a maximum .sig},
      "explain why" );
