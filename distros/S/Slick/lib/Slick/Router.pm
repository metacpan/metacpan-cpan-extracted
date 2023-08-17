package Slick::Router;

use 5.036;

use Moo;
use Slick::Methods qw(METHODS);
use Slick::Events  qw(EVENTS);

with 'Slick::EventHandler';
with 'Slick::RouteManager';

1;

=encoding utf8

=head1 NAME

Slick::RouteMap

=head1 SYNOPSIS

L<Slick::Router> is a L<Slick::EventHandler> and a L<Slick::RouteManager>.

It is the primary object for defining routes, outside of the main L<Slick> instance. If you want to spread
routing logic out across multiple files, you'll want to export a L<Slick::Router> from each module you
want to contain routing logic.

=head1 Example

    my $router = Slick::Router->new(base => '/foo'); # All routes will start with /foo
    
    my $slick = Slick->new;

    $router->get('/bob' => sub { my ($app, $context) = @_; $context->json({hello => 'world'}); });

    # You may also add events that will be dispatched between global and route level events as well.
    $router->on(before_dispatch => sub { my ($app, $context) = @_; return 1; });

    $slick->register($router); # Register router with your Slick application

=head1 API

See L<Slick::EventHandler> and L<Slick::RouteManager>.

=head1 See also

=over 2

=item * L<Slick>

=item * L<Slick::RouteManager>

=item * L<Slick::Context>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::DatabaseExecutor::MySQL>

=item * L<Slick::DatabaseExecutor::Pg>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=back

=cut
