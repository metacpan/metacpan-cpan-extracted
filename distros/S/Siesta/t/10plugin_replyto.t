#!perl -w
use strict;
use Test::More tests => 5;
use lib 't/lib';
use Siesta::Test;

use Siesta::Message;
use Siesta::Plugin::ReplyTo;

my $POST_ADDRESS = 'foo@bar.com';

use Data::Dumper;
my $mail = Siesta::Message->new();
my $list = Siesta::List->create({
    name => 'replyto_test',
    post_address => $POST_ADDRESS
   });
my $plugin = Siesta::Plugin::ReplyTo->new( list => $list, queue => 'test' );

$plugin->pref( 'munge', 1 );
is( $mail->header("Reply-To"), '', "blank" );
ok( !$plugin->process($mail) );
is( $mail->header("Reply-To"), "$POST_ADDRESS", "munged once" );
ok( !$plugin->process($mail) );
is( $mail->header("Reply-To"), "$POST_ADDRESS", "munged again" );

$list->delete;
