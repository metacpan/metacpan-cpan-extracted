package Simple::SAX::Serializer::Element;

use warnings;
use strict;
use vars qw($VERSION);
use Carp 'confess';

$VERSION = 0.03;

use Abstract::Meta::Class ':all';

=head1 NAME

Simple::SAX::Serializer::Element - XML node element.

=head1 SYNOPSIS

    my $xml = Simple::SAX::Serializer->new;
    $xml->handler('dataset', sub {
             my ($self, $element, $parent) = @_;
             my $attributes = $element->attributes;
             my $children_result = $element->children_result;
             {properties => $attributes, dataset => $children_result}
         }
     );
     $xml->handler('*', sub {
         my ($self, $element, $parent) = @_;
         my $attributes = $element->attributes;
         my $children_result = $parent->children_array_result;
         my $result = $parent->children_result;
         push @$children_result, $element->name => {%$attributes};
     });
 }

=head1 DESCRIPTION

Represents xml node element.

=head2 EXPORT

None.

=head2 ATTRIBUTES

=over

=item node

Stores reference to the xml node.

=cut

has '$.node';

=back

=head2 METHODS

=over

=item attributes

Return attributes as hash ref.

=cut

sub attributes {
    my ($self) = @_;
    my $node = $self->node;
    $node->[1];
}


=item name

=cut

sub name {
    my ($self) = @_;
    my $node = $self->node;
    $node->[0];
}

=item children_result

Returns children results.

=cut

sub children_result {
    my ($self, $value) = @_;
    my $node = $self->node;
    $node->[-2] = $value if $value;
    $node->[-2];
}


=item children_array_result

Returns children result as array ref

=cut

sub children_array_result {
    my ($self, $value) = @_;
    my $node = $self->node;
    $node->[-2] = [] unless $node->[-2] ;
    $node->[-2] = $value if $value;
    $node->[-2];
}


=item children_hash_result

Returns children result as hash ref

=cut

sub children_hash_result {
    my ($self, $value) = @_;
    my $node = $self->node;
    $node->[-2] = {} unless $node->[-2] ;
    $node->[-2] = $value if $value;
    $node->[-2];
}


=item set_children_result

Sets children result

=cut

sub set_children_result {
    my ($self, $value) = @_;
    my $node = $self->node;
    $node->[-2] = $value;
    $self;
}


=item value

Return element's value. Takes optionally normalise spaces flag.

=cut

sub value {
    my ($self, $normailise_spaces) = @_;
    my $node = $self->node;
    my $result = $node->[-1];
    $result =~ s/^\s+|\s+$//sg if defined($result) && $normailise_spaces;
    $result;
}


=item validate_attributes

Validates element attributes takes, required attributes parameter as array ref,
optional attributes parameter as hash ref
    $element->validate_attributes(['name'], {type => 'text'});

=cut

sub validate_attributes {
    my ($self, $required, $optional) = @_;
    $required ||= [];
    $optional ||= {};
    my %attributes = map { $_ => 1 } @$required;
    my $attributes = $self->attributes;
    for (@$required) {
        confess "attribute $_ is required"
            unless exists $attributes->{$_};
    }
    
    for my $k (keys %$optional) {
            $attributes->{$k} = $optional->{$k}
                unless exists $attributes->{$k};
    }
    
    for my $k(keys %$attributes) {
        next if $k =~ /^_/;
        confess "unknown attributes $k on tag " . $self->name
            if (! exists($attributes{$k}) && ! exists($optional->{$k}));
    }
    
}

1;

__END__

=back

=head1 COPYRIGHT AND LICENSE

The Simple::SAX::Serializer::Element module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 SEE ALSO

L<Simple::SAX::Serializer>
L<Simple::SAX::Serializer::Parser>
L<Simple::SAX::Handler>

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

See also 

=cut
