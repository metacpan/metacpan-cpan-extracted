=head1 NAME

Pangloss::Segment::Decline::NoSelectedSearch - decline unless request contains a search.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::NoSelectedSearch->new )

=cut

package Pangloss::Segment::Decline::NoSelectedSearch;

use base qw( OpenFrame::WebApp::Segment::Decline );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub should_decline {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $path    = $request->uri ? $request->uri->path : '';
    my $args    = $request->arguments;

    return 0 if ($args->{search});
    return 0 if ($path =~ /^\/search\.html$/i);

    return 1;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Inherits from C<OpenFrame::WebApp::Segment::Decline>.

Declines if the request uri matches '/search.html' or the request has a
'search' argument.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<OpenFrame::WebApp::Segment::Decline>

=cut
