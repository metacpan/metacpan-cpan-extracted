=head1 NAME

Pangloss::Segment::Decline::NoPager - decline unless there's a search results
pager in the store

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::NoPager->new )

=cut

package Pangloss::Segment::Decline::NoPager;

use base qw( OpenFrame::WebApp::Segment::Decline );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.1 $ '))[2];

sub should_decline {
    my $self = shift;
    $self->store->get('Pangloss::Search::Results::Pager') ? 0 : 1;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Declines if there is no L<Pangloss::Search::Results::Pager> object in the store.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<OpenFrame::WebApp::Segment::Decline>

=cut
