package Net::RDAP::ID;
use base qw(Net::RDAP::Base);
use strict;

=head1 NAME

L<Net::RDAP::ID> - a module representing a public identifier in an RDAP
response.

=head1 DESCRIPTION

RDAP objects may have zero or more "public identifiers", which map a
public identifier to an object class.

Any object which inherits from L<Net::RDAP::Object> will have an
C<ids()> method which will return an array of zero or more
L<Net::RDAP::ID> objects.

=head1 METHODS

=head2 ID Type

    $type = $id->type;

Returns a string containing the type of public identifier.

=cut

sub type { $_[0]->{'type'} }

=pod

=head2 Identifier

    $identifier = $id->identifier;

Returns a string containing a public identifier of the type denoted by
the C<type>.

=cut

sub identifier { $_[0]->{'identifier'} }

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
