#!perl -w
# $Id: $
use strict;
use Test::More tests => 6;
use lib qw(t/lib);
use Siesta::Test;

use Sys::Hostname;

use Siesta::List;
use Siesta::Plugin::MessageFooter;

my %message;

my $list   = Siesta::List->load('dealers');
my $plugin = Siesta::Plugin::MessageFooter->new( queue => 'test',
                                                 list => $list );

my $list_id   = $list->name;
my $hostname  = hostname();


my $message = new_mail();
$plugin->pref("footer","List footer for [% real_name %]");
ok( !$plugin->process($message), "processed mail" );
like( $message->body(), qr{List footer for $list_id}, "added list name" );

$message = new_mail();
$plugin->pref("footer","[% host_name %]");
ok( !$plugin->process($message));
like( $message->body(), qr{$hostname}, "added host name" );


$message = new_mail();
$plugin->pref("host_name","a random host name ");
ok( !$plugin->process($message));
like( $message->body(), qr{a random host name}, "overrode host name" );



sub new_mail { 
return Siesta::Message->new(<<'MAIL');
From: dante@quick-stop

yoohoo
MAIL
}
