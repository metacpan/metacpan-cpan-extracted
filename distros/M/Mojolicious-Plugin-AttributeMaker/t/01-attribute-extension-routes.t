#!perl
use Test::More;
use Test::Mojo;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
our $t;

use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
$t = Test::Mojo->new('TestApp');

my $urls = Mojolicious::Plugin::AttributeMaker::config()->{urls};
foreach ( @{ $t->app->routes->children } ) {
    $t->get_ok( $_->to_string )->status_is(200)->content_like(qr/$urls->{$_->to_string}->{attr}/i);
}
done_testing();

