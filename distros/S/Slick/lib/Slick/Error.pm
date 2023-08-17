package Slick::Error;

use 5.036;

use Moo;
use Scalar::Util qw(blessed);

has error => (
    is       => 'ro',
    required => 1
);

has error_type => (
    is       => 'ro',
    required => 1
);

around new => sub {
    return $_[2]
      if blessed( $_[2] ) && ( blessed( $_[2] ) eq 'Slick::Error' );

    return bless {
        error_type => blessed( $_[2] ) // 'SCALAR',
        error      => $_[2]
      },
      $_[1];
};

sub to_hash {
    my $self = shift;
    return { error => $self->error, error_type => $self->error_type };
}

1;

=encoding utf8

=head1 NAME

Slick::Error

=head1 SYNOPSIS

A Moo wrapper for errors in L<Slick>.

=head1 API

=head2 error

Returns the actual error that was used to construct this object.

=head2 error_type

Returns the type of the error, C<SCALAR>, or a blessed type.

=head2 to_hash

Converts the error to a hash.

=head1 See also

=over 2

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
