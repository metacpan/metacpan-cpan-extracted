package Net::RDAP::JCard::Node;
use strict;

=pod

=head1 NAME

L<Net::RDAP::JCard::Node> - an object representing a node in a L<Net::RDAP::JCard>
object.

=head1 SYNOPSIS

    #
    # get a node by calling the nodes() method on a Net::RDAP::JCard object
    #
    $node = ($vcardArray->nodes('tel'))[0];

    say $node->param('type');
    say $node->value;

=head1 DESCRIPTION

The data in a jCard (L<RFC 7095|https://www.rfc-editor.org/rfc/rfc7095.html>)
object is stored in a set of nodes, which this module represents.

Nodes have exactly four elements, specifically:

=over

=item 1. the node I<type>, such as C<fn> (full name) or C<email> (email address);

=item 2. I<parameters>, which are represented as a hashref;

=item 3. a I<value type>, such as C<text> or C<URI>;

=item 4. the node I<value>, which can be a string or arrayref.

=back

L<Net::RDAP::JCard::Node> provides an ergonomic way to access these
elements.

=head1 CONSTRUCTOR

    $node = Net::RDAP::JCard::Node->new($ref);

You probably don't need to instantiate these objects yourself, but if you do,
you just need to pass an arrayref.

=cut

sub new {
    my ($package, $arrayref) = @_;

    my $self = {
        type        => $arrayref->[0],
        params      => $arrayref->[1],
        value_type  => $arrayref->[2],
        value       => $arrayref->[3],
    };
    
    return bless($self, $package);
}

=pod

=head1 METHODS

    $type = $node->type;

Returns a string containing the node type.

    $params = $node->params;

Returns a hashref containing the node parameters.

    $param = $node->param($name);

Returns the value of the C<$name> parameter or C<undef>.

    $value_type = $node->value_type;

Returns a string containing the node value's type. See the L<vCard Value Data
Types|https://www.iana.org/assignments/vcard-elements/vcard-elements.xhtml#value-data-types>
IANA registry for a list of possible values.

    $value = $node->value;

Returns the node value.

=cut

sub type        { $_[0]->{type} }
sub params      { $_[0]->{params} }
sub param       { $_[0]->params->{$_[1]} }
sub value_type  { $_[0]->{value_type} }
sub value       { $_[0]->{value} }

sub TO_JSON {
    my $self = shift;

    return [
        $self->type,
        $self->params,
        $self->value_type,
        $self->value,
    ];
}

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
