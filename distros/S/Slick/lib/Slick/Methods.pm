package Slick::Methods;

use 5.036;

use Exporter qw(import);

our @EXPORT_OK = qw(METHODS);

sub METHODS {
    return [qw(get post put patch delete head options)];
}

1;

=encoding utf8

=head1 NAME

Slick::Methods

=head1 SYNOPSIS

An export module that contains all of the methods that L<Slick::Route> objects rely on.

=head1 API

=head2 METHODS

Returns an C<ArrayRef> of all of the methods available.

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
