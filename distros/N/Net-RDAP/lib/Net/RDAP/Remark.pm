package Net::RDAP::Remark;
use base qw(Net::RDAP::Base);
use strict;

=pod

=head1 NAME

L<Net::RDAP::Remark> - an RDAP remark

=head1 DESCRIPTION

This module represents a remark attached to an RDAP response.

Any object which inherits from L<Net::RDAP::Object> will have a
C<remarks()> method which will return an array of zero or more
L<Net::RDAP::Remark> objects.

=head1 METHODS

=head2 Remark Title

    $title = $remark->title;

Returns the textual description of the remark.

=cut

sub title { $_[0]->{'title'} }

=pod

=head2 Remark Type

    $type = $link->type;

Returns the "type" of the remark. The possible values are defined by
an IANA registry; see:

=over

=item * L<https://www.iana.org/assignments/rdap-json-values/rdap-json-values.xhtml>

=back

=cut

sub type { $_[0]->{'type'} }

=pod

=head2 Remark Description

    my @description = $link->description;

Returns an array containing lines of text.

=cut

sub description { $_[0]->{'description'} ? @{$_[0]->{'description'}} : () }

=pod

=head2 Remark Links

    $links = $remark->links;

Returns a (potentially empty) array of L<Net::RDAP::Link> objects.

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
