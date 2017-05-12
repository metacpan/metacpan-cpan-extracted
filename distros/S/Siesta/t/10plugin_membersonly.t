#!perl -w
# $Id: 10plugin_membersonly.t,v 1.15 2003/03/26 07:16:42 muttley Exp $
use strict;
use Test::More tests => 7;
use lib qw(t/lib);
use Siesta::Test;

use Siesta::List;
use Siesta::Plugin::MembersOnly;

my %message;

package Test::Message;
use base 'Siesta::Message';
sub reply { shift; %message = @_ }

package main;

my $list   = Siesta::List->load('dealers');
my $plugin = Siesta::Plugin::MembersOnly->new( queue => 'test',
                                               list => $list );
my $mail   = Test::Message->new(<<'MAIL');
From: dante@quick-stop

yoohoo
MAIL

my $list_id   = $list->name;
my $mail_from = $mail->from;

$plugin->pref('approve', 1);

ok( $plugin->process($mail), "deferred dante" );

like( $message{'body'}, qr{$list_id has a deferred message from $mail_from}, "said why" );

for (Siesta::Deferred->retrieve_all) {
    $_->delete;
}

$plugin->pref('approve', 0);
ok( $plugin->process($mail), "rejected dante" );
like( $message{'body'}, qr{$list_id MembersOnly dropped a message from $mail_from}, "said why" );



$mail->from_raw('jack.black@holywood');
ok( $plugin->process($mail), "jack.black isn't even on the system" );


$plugin->pref('allowed_posters','dante@quick-stop jack.black@holywood');
ok( !$plugin->process($mail), "accepted jack.black as an allowed user" );


$mail->from_raw('jay@front-of.quick-stop');

ok( !$plugin->process($mail), "accepted jay" );
