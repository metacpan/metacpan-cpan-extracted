package Net::RDAP::JCard;
use Net::RDAP::JCard::Node;
use strict;

=head1 NAME

L<Net::RDAP::JCard> - an object representing an RDAP jCard object.

=head1 SYNOPSIS

    #
    # get an object by calling the vcardArray() method on a Net::RDAP::Object::Entity
    #
    my $vcardArray = $entity->vcardArray;

    my $name = ($vcardArray->nodes('fn'))[0];

    say $name->value;

=head1 DESCRIPTION

This module provides a representation of jCard objects, as described in
L<RFC 7095|https://www.rfc-editor.org/rfc/rfc7095.html>. Historically, the only
way to access the contents of the C<vcardArray> property of L<Net::RDAP::Object::Entity>
objects was to call the C<vcard()> method and get a L<vCard> object back, but
the conversion was lossy. This module provides a lossless ergonomic interface as
an alternative to L<vCard>.

=head1 CONSTRUCTOR

    $vcardArray = Net::RDAP::JCard->new($ref);

You probably don't need to instantiate these objects yourself, but if you do,
you just need to pass an arrayref of nodes.

=cut

sub new {
    my ($package, $arrayref) = @_;

    my $self = {
        nodes => [map { Net::RDAP::JCard::Node->new($_) } @{$arrayref}],
    };
    
    return bless($self, $package);
}

=pod

=head1 METHODS

    @nodes = $vcardArray->nodes;

    @nodes = $vcardArray->nodes($type);

Returns an array of L<Net::RDAP::JCard::Node> objects, optionally filtered
to just those that have the C<$type> type.

=cut

sub nodes {
    my ($self, $type) = @_;
    return grep { !$type || $type eq $_->type } @{$self->{nodes}};
}

sub TO_JSON { shift->{nodes} }

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
