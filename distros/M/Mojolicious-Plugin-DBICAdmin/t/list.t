use v5.14;
use Mojo::Base qw{-strict};
use lib 't/lib';
use TestApp::Schema;

my $schema = TestApp::Schema->connect( 'dbi:SQLite:dbname=:memory:', '', '' );
$schema->deploy();
$schema->populate(
    A => [
        [qw/id col1 col2/],        [qw/1   "ahello" "abc"/],
        [qw/2   "ahello" "abcd"/], [qw/3   "hello2" "abcd"/],
    ]
);

$schema->populate(
    B => [
        [qw/id col1 col2/], [qw/1   2 "abc"/],
        [qw/1   3 "abc"/],  [qw/2   3 "abcd"/],
    ]
);

use Mojolicious::Lite;
plugin 'DBICAdmin';
app->attr( schema => sub { $schema } );

use Test::More tests => 15;
use Test::Mojo;

my $t = Test::Mojo->new;

$t->get_ok('/admin/dbic')->status_is(200)->content_like(qr/Welcome !/s, "index ok");
$t->get_ok('/admin/dbic/info')->status_is(200)->element_exists('a[href=/admin/dbic/info/A]', "info list ok");
$t->get_ok('/admin/dbic/list')->status_is(200)->content_like(qr!a +href=\S+/admin/dbic/search/A!s, "list ok");
$t->get_ok('/admin/dbic/search')->status_is(200)->content_like(qr!a +href=\S+/admin/dbic/search/A!s, "list ok");
$t->get_ok('/admin/dbic/search/A')->status_is(200)->element_exists('html body div table tr td', "list ok");





