=head1 NAME

Pangloss::Segment::Decline::NoSelectedTerm - decline unless selected term

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::NoSelectedTerm->new )

=cut

package Pangloss::Segment::Decline::NoSelectedTerm;

use base qw( OpenFrame::WebApp::Segment::Decline );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub should_decline {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    return $request->arguments()->{selected_term} ? 0 : 1;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<OpenFrame::WebApp::Segment::Decline>.

Declines if the request does not contain a 'selected_term' argument.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>

=cut
