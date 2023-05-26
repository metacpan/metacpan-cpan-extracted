package Net::RDAP::Link;
use URI;
use MIME::Type;
use strict;

=pod

=head1 NAME

L<Net::RDAP::Link> - a module representing an RDAP link.

=head1 DESCRIPTION

Links are used throughout RDAP; the following objects may contain zero
or more links:

=over

=item * objects (see L<Net::RDAP::Object>)

=item * remarks (see L<Net::RDAP::Remark>)

=item * notices (see L<Net::RDAP::Notice>)

=item * events (see L<Net::RDAP::Event>)

=back

In all cases, the modules representing these types of object inherit
from L<Net::RDAP::Base> and therefore provide a C<links()> method
which will return a (potentially empty) array of L<Net::RDAP::Link>
objects.

=cut

sub new {
    my ($package, $args) = @_;
    my %self = %{$args};
    return bless(\%self, $package);
}

=pod

=head1 METHODS

=head2 Value

    $value = $link->value;

Returns the "value" of the link. This corresponds to the text
content of the C<E<lt>aE<gt>> element if the link if it were
represented in HTML.

=cut

sub value { $_[0]->{'value'} }

=pod

=head2 Relationship

    $rel = $link->rel;

Returns the "relationship" attribute. The possible values are defined by
an IANA registry; see:

=over

=item * L<https://www.iana.org/assignments/link-relations/link-relations.xhtml>

=back

=cut

sub rel { $_[0]->{'rel'} }

=pod

=head2 URL

    $url = $link->href;

Returns a L<URI> object corresponding to the target of the link.

=cut

sub href { URI->new($_[0]->{'href'}) }

=pod

=head2 Language

    @languages = $link->hreflang;

Returns a (potentially empty) array containing the ISO-639-2 codes
which describe the language that the target is available in.

=cut

sub hreflang { $_[0]->{'hreflang'} ? @{$_[0]->{'hreflang'}} : undef }

=pod

=head2 Title

    $title = $link->title;

Returns the "title" attribute of the link. This corresponds to the
mousover tooltip content of the C<E<lt>aE<gt>> element if the link if
it were represented in HTML.

=cut

sub title { $_[0]->{'title'} }

=pod

=head2 Media

    $media = $link->media;

Returns the "media" attribute of the link. This corresponds to the
media/device the target resource is optimized for.

=cut

sub media { $_[0]->{'media'} }

=pod

=head2 Media Type

    $type = $link->type;

Returns a L<MIME::Type> object corresponding to the media type of the
target resource.

=cut

sub type { $_[0]->{'type'} ? MIME::Type->new('type' => $_[0]->{'type'}) : undef }

=pod

=head1 COPYRIGHT

Copyright CentralNic Ltd. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
