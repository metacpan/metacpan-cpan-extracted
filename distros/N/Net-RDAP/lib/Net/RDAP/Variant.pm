package Net::RDAP::Variant;
use Net::RDAP::VariantName;
use strict;

=pod

=head1 NAME

L<Net::RDAP::Variant> - a module representing one or more variants of a domain
name.

=head1 DESCRIPTION

Internationalized Domain Names (IDNs) may (depending on the script and/or
language they are written in) have variant names. For example, a name written in
Simplified Chinese may have a variant in Traditional Chinese, and vice versa.

The C<variants()> property of L<Net::RDAP::Domain> objects may return an array
of L<Net::RDAP::Variant> objects representing such variant names.

=cut

sub new {
    my ($package, $ref) = @_;
    return bless($ref, $package);
};

=pod

=head1 METHODS

    @relation = $variant->relation;

Returns an array of strings describing the relationship between the variants.
This array B<SHOULD> only contain values that are present in the IANA registry
(see L<Net::RDAP::Values>).

=cut

sub relation { @{ $_[0]->{'relation'} || [] } }

=pod

    $table = $variant->idnTable;

Returns a string that represents the Internationalized Domain Name (IDN) table
that has been registered in the
L<IANA Repository of IDN Practices|https://www.iana.org/domains/idn-tables>.

=cut

sub idnTable { $_[0]->{'idnTable'} }

=pod

    @names = $variant->variantNames;

Returns an array of L<Net::RDAP::VariantName> objects.

=cut

sub variantNames { map { Net::RDAP::VariantName->new($_) } @{ $_[0]->{'variantNames'} || [] } }

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
