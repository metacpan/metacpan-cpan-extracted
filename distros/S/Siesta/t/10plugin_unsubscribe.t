#!perl -w
use strict;
use Test::More tests => 4;
use lib qw(t/lib);
use Siesta::Test;
use Siesta;
use Siesta::List;
use Siesta::Plugin::UnSubscribe;

my $list = Siesta::List->create({
    name => 'escapees',
    post_address => 'escapees@escapees.com',
    owner => Siesta::Member->create({ email => 'houdini@escapees.com' }),
});
$list->add_member( 'suzanne@lab' );

my $plugin = Siesta::Plugin::UnSubscribe->new( list => $list, queue => 'test' );

my $mail = Siesta::Message->new(<<'END');
From: suzanne@lab
END

ok( $plugin->process($mail), "request handled" );
like( $Siesta::Send::Test::sent[-1]->body,
      qr/You have been/, "unsubscribed suzanne" );

$mail = Siesta::Message->new(<<'END');
From: jay@jail
END

ok( $plugin->process($mail) );
like( $Siesta::Send::Test::sent[-1]->body,
      qr/You could not be/, "unsubscribing jay failed" );

