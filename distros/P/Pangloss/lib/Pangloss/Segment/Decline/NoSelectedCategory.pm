=head1 NAME

Pangloss::Segment::Decline::NoSelectedCategory - decline unless selected category

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::NoSelectedCategory->new )

=cut

package Pangloss::Segment::Decline::NoSelectedCategory;

use base qw( OpenFrame::WebApp::Segment::Decline );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub should_decline {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    return $request->arguments()->{selected_category} ? 0 : 1;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<OpenFrame::WebApp::Segment::Decline>.

Declines if the request does not contain a 'selected_category' argument.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>

=cut
