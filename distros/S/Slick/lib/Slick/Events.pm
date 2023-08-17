package Slick::Events;

use 5.036;

use Exporter qw(import);

our @EXPORT_OK = qw(BEFORE_DISPATCH AFTER_DISPATCH EVENTS);

sub BEFORE_DISPATCH { return 'before_dispatch'; }
sub AFTER_DISPATCH  { return 'after_dispatch'; }
sub EVENTS          { return [ BEFORE_DISPATCH(), AFTER_DISPATCH() ]; }

1;

=encoding utf8

=head1 NAME

Slick::Events

=head1 SYNOPSIS

An export module that contains all of the events that L<Slick::EventHandler> objects rely on.

=head1 API

=head2 BEFORE_DISPATCH

Returns C<"before_dispatch">.

=head2 AFTER_DISPATCH

Returns C<"after_dispatch">.

=head2 EVENTS

Returns an C<ArrayRef> of all of the events available.

=head1 See also

=over2

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
