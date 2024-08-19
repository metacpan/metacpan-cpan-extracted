package Ryu::Exception;

use strict;
use warnings;

our $VERSION = '4.000'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

=head1 NAME

Ryu::Exception - support for L<Future>-style failure information

=head1 SYNOPSIS

 use Ryu::Exception;
 my $exception = Ryu::Exception->new(
  type    => 'http',
  message => '404 response'
  details => [ $response, $request ]
 );
 Future->fail($exception->failure);

=head1 DESCRIPTION

Generic exceptions interface, implements the 3-part failure codes as described in L<Future>.

=cut

use Future;
use Scalar::Util;

=head2 new

Instantiate from named parameters.

=cut

sub new { bless { @_[1..$#_] }, $_[0] }

=head2 throw

Throws this exception.

 $exception->throw;

=cut

sub throw { die shift }

=head2 type

Returns the type, which should be a string such as C<http>.

=cut

sub type { shift->{type} }

=head2 message

Returns the message, which is a freeform string.

=cut

sub message { shift->{message} }

=head2 details

Returns the list of details, the specifics of which are specific to the type.

=cut

sub details { @{ shift->{details} || [] } }

=head2 fail

Fails the given L<Future> with this exception.

=cut

sub fail {
    my ($self, $f) = @_;
    die "expects a Future" unless Scalar::Util::blessed($f) && $f->isa('Future');
    $self->as_future->on_ready($f);
    $f;
}

=head2 as_future

Returns a failed L<Future> containing the message, type and details from
this exception.

=cut

sub as_future {
    my ($self) = @_;
    return Future->fail($self->message, $self->type, $self->details);
}

=head2 from_future

Extracts failure information from a L<Future> and instantiates accordingly.

=cut

sub from_future {
    my ($class, $f) = @_;
    die "expects a Future" unless Scalar::Util::blessed($f) && $f->isa('Future');
    die "Future is not ready" unless $f->is_ready;
    my ($msg, $type, @details) = $f->failure or die "Future is not failed?";
    $class->new(
        message => $msg,
        type    => $type,
        details => \@details
    )
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2024. Licensed under the same terms as Perl itself.

