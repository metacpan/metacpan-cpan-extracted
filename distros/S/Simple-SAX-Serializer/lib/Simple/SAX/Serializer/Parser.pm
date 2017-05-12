package Simple::SAX::Serializer::Parser;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = 0.03;

use base 'XML::SAX::Base';
use Simple::SAX::Serializer::Element;

=head1 NAME

Simple::SAX::Serializer::Parser - Xml parser

=head1 DESCRIPTION

Represents xml parser.

=head1 SYNOPSIS

    use Simple::SAX::Serializer;
    my $xml = Simple::SAX::Serializer->new(file_name => 'dummy.xml')

    $xml->handler('root/child', sub {
    my ($self, $element, $parent) = @_;
    my $attributes = $element->attributes;
    my $result = $parent->children_result;
    $result = $parent->result([])
      unless $result;
    push @$result,Child->new(%$attributes);
    });

=head2 METHODS

=over

=item start_document

Handles the start of the document. Sets up state for the parse.

=cut

sub start_document {
    my ($self) = @_;
    $self->{args} = [];
    $self->{elements} = [];
}


=item start_element

Handles the start of an element.

=cut

sub start_element {
    my ($self, $element) = @_;
    my $elements = $self->{elements};
    push @{$elements}, [$element->{LocalName} =>  attributes($element), undef, ''];
    $self->{elements};
}

=item attributes

=cut

sub attributes {
    my ($element) = @_;
    my %result;
    foreach my $k (keys %{$element->{Attributes}}) {
        my $attr = $element->{Attributes}->{$k};
        my $prefix = $attr->{Prefix};
        if($prefix) {
            $result{"_${prefix}"}{$attr->{LocalName}} ||= {};
            $result{"_${prefix}"}{$attr->{LocalName}} = $attr->{Value};
            
        } else {  
            $result{$attr->{LocalName}} = $attr->{Value};
        }    
    }
    \%result;
}

=item characters

Handles text data in the document.

=cut

sub characters {
    my ($self, $data) = @_;
    my $current_element = $self->{elements}->[-1];
    $current_element->[-1] .= $data->{Data}; 
}


=item end_element

Handles a closing tag.

=cut

my $element = Simple::SAX::Serializer::Element->new;
my $parent = Simple::SAX::Serializer::Element->new;

sub end_element {
    my ($self, $sax_element) = @_;
    my $elements = $self->{elements};
    my $args = $self->{args};
    
    if (my $callback = $self->{parser}->find_handlder($elements)) {
        $element->set_node($elements->[-1]);
        $parent->set_node($elements->[-2]) if (@$elements > 1);
        my $result = $callback->(
          $self,
          $element,
          (@$elements > 1 ? $parent : ())
        );
        $self->{result} = $result if @$elements == 1;
    }
    pop @$args;
    pop @$elements;    
}


=item root_args

Returns parse parameters.
$xml->parse_string($xml_content, {root_param1 => 1, root_param2 => 2;});

=cut

sub root_args {
    my ($self) = @_;
    $self->{root_args} ||= {};
}
1;

__END__

=back

=head1 COPYRIGHT AND LICENSE

The Simple::SAX::Serializer::Parser module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 SEE ALSO

L<Simple::SAX::Serializer>

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

See also 

=cut