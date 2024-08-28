package Net::RDAP::VariantName;
use strict;
use warnings;

=pod

=head1 NAME

L<Net::RDAP::VariantName> - a module representing a variant name in an
L<Net::RDAP::Variant> object.

=head1 DESCRIPTION

See L<Net::RDAP::Variant> for more information

=head1 METHODS

=cut

sub new {
    my ($package, $ref) = @_;
    return bless($ref, $package);
};

=pod

    $name = $variant->name;

Returns a L<Net::DNS::Domain> object representing the domain name.

=cut

sub name { Net::DNS::Domain->new($_[0]->{'ldhName'}) }

=pod

    $name = $domain->unicodeName;

Returns a string containing the DNS Unicode name of the domain.

=cut

sub unicodeName { $_[0]->{'unicodeName'} }

=pod

=head1 COPYRIGHT

Copyright 2024 Gavin Brown. All rights reserved.

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
