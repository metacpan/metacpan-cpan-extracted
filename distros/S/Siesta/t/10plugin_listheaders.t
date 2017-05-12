#!perl -w
use strict;
use Test::More tests => 5;
use lib qw(t/lib);
use Siesta::Test;
use Siesta::Message;
use Siesta::List;
use Siesta::Plugin::ListHeaders;

my $mail = Siesta::Message->new;
my $list = Siesta::List->create({
    name => 'test',
    owner => Siesta::Member->create({ email => 'foo-owner@foo.com'}),
    post_address => 'foo@foo.com',
    });

my $plugin = Siesta::Plugin::ListHeaders->new( queue => 'test',
                                               list => $list );

is( $mail->header("List-Id"), '', "No List-Id" );
ok( !$plugin->process($mail), "plugin processed" );
is( $mail->header("List-Id"), "test <foo.foo.com>", "Set List-Id" );
ok( !$plugin->process($mail) );
is( $mail->header("List-Id"), "test <foo.foo.com>" );

$list->owner->delete;
$list->delete;
