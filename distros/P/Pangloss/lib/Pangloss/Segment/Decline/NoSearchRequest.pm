=head1 NAME

Pangloss::Segment::Decline::NoSearchRequest - decline unless there's a search
request in the store

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::NoSearchRequest->new )

=cut

package Pangloss::Segment::Decline::NoSearchRequest;

use base qw( OpenFrame::WebApp::Segment::Decline );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.3 $ '))[2];

sub should_decline {
    my $self = shift;
    $self->store->get('Pangloss::Search::Request') ? 0 : 1;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Inherits from C<OpenFrame::WebApp::Segment::Decline>.

Declines if there is no C<Pangloss::Search::Request> object in the store.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<OpenFrame::WebApp::Segment::Decline>, L<Pangloss::Search::Request>

=cut
