=head1 NAME

Pangloss::Segment::Decline::NoSelectedConcept - decline unless selected concept

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::NoSelectedConcept->new )

=cut

package Pangloss::Segment::Decline::NoSelectedConcept;

use base qw( OpenFrame::WebApp::Segment::Decline );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub should_decline {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    return $request->arguments()->{selected_concept} ? 0 : 1;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<OpenFrame::WebApp::Segment::Decline>.

Declines if the request does not contain a 'selected_concept' argument.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>

=cut
