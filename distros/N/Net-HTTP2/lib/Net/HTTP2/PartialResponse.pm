package Net::HTTP2::PartialResponse;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::HTTP2::PartialResponse - Partial HTTP/2 Response

=head1 DESCRIPTION

This class represents a partial (i.e., in-progress) HTTP/2 response.
It extends L<Net::HTTP2::Response> with a control to cancel the
request.

=cut

#----------------------------------------------------------------------

use parent 'Net::HTTP2::Response';

my %CANCEL_SR;

#----------------------------------------------------------------------

=head1 METHODS

=cut

# Not called publicly.
sub new {
    my ($class, $sr) = splice @_, 0, 2;
    my $self = $class->SUPER::new(@_);
    $CANCEL_SR{ $self } = $sr;
    return $self;
}

=head2 I<OBJ>->cancel()

Call this to cancel the in-progress request that I<OBJ> represents.

=cut

sub cancel {
    ${ $CANCEL_SR{$_[0]} } = 1;
}

sub DESTROY {
    delete $CANCEL_SR{ $_[0] };
}

1;
