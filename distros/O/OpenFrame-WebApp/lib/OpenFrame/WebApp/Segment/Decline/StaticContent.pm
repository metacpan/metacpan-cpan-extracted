=head1 NAME

OpenFrame::WebApp::Segment::Decline::StaticContent - decline if request uri is for static content.

=head1 SYNOPSIS

  $pipe->add_segment( OpenFrame::WebApp::Segment::StaticContent->new )

=cut

package OpenFrame::WebApp::Segment::Decline::StaticContent;

use MIME::Types;

use base qw( OpenFrame::WebApp::Segment::Decline );

our $VERSION = (split(/ /, '$Revision: 1.1 $'))[1];

sub should_decline {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $uri     = $request->uri || return;
    my $mtype   = MIME::Types->new->mimeTypeOf( $uri ) || return;

    return 1 if ($mtype->subType eq 'css');
    return 1 if ($mtype->mediaType eq 'image');

    return 0;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Inherits from L<OpenFrame::WebApp::Segment::Decline>.

Declines if the request uri looks like it's for static content (currently a
mime type of image/css).

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<MIME::Types>,
L<OpenFrame::WebApp::Segment::Decline>

=cut
