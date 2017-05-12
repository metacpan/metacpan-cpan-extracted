package Simple::SAX::Serializer;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = 0.05;

use Abstract::Meta::Class ':all';
use base 'XML::SAX::Base';
use Carp 'confess';
use Simple::SAX::Serializer::Parser;
use XML::SAX;

BEGIN {
    eval {
        require XML::LibXML;
    };
    $XML::SAX::ParserPackage = "XML::LibXML::SAX" unless $@;
}

=head1 NAME

Simple::SAX::Serializer - Simple XML serializer

=head1 DESCRIPTION

Represents xml serializer class,

=head1 SYNOPSIS

    use Simple::SAX::Serializer;
    my $xml = Simple::SAX::Serializer;

    $xml->handler('root/child', sub {
        my ($self, $element, $parent) = @_;
        my $attributes = $element->attributes;
        my $result = $parent->children_array_result;
        push @$result,Child->new(%$attributes);
    });

    $xml->handler('root', sub {
        my ($self, $element) = @_;
          $element->validate_attributes(['dummy'], {attr2 => 'default_value'});
          Root->new(%{$element->attributes}, children => $element->children_result);
    });

    my $xml_content = "<?xml version="1.0"?><root dummy="1"><child id="1" ><child id="2" ></root>";

    $xml->parse_string($xml_content);
    # or $xml->parse_file ...

=cut

=head2 ATTRIBUTES

=over

=item handlers

=cut

has '%.handlers' => (item_accessor => 'handler');

=back

=head2 METHODS

=over


=item parse_string

Runs the parser and returns result, xml as string 

=cut

sub parse_string {
    my $self = shift;
    $self->parse('string', @_);
}


=item parse_file

Runs the parser and returns result, xml as file

=cut

sub parse_file {
    my $self = shift;
    $self->parse('file', @_);
}


=item parse

Runs the parser and returns result

=cut

sub parse {
    my ($self, $input_type, $xml, $args) = @_;
    my $parse_method = "parse_$input_type";
    my $handler = Simple::SAX::Serializer::Parser->new;
    $handler->{parser} = $self;
    my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
    if($input_type eq 'file') {
        die "file $xml doesn't exists" unless -e $xml;
    }
    $handler->{root_args} = $args;
    $parser->$parse_method($xml);
    $handler->{result};
}


=item find_handlder

Finds handler for current element.
It start matching from root/element/searched_element
and if not find that it try to resolve by
element/searched_element
and eventually searched_element
If handler is not found then generates an error.

=cut

sub find_handlder {
    my ($self, $elements) = @_;
    my @path = element_path($elements);
    my $handlers = $self->handlers;
    my $handler;
    for (my $i = 0; $i <= $#path; $i++) {
        my $path = join '/', @path[$i .. $#path ];
        $handler = $handlers->{$path};
        last if $handler;
    }
 
    
    $handler = $handlers->{'*'}
        unless $handler;

    confess "missing handler for " . join('/', @path)
      unless $handler;
    $handler;
}


=item element_path

Takes array reference of the elements data structures, return list of element name.

=cut

sub element_path {
    my ($elemets) = @_;
    map { $_->[0] } @$elemets;
}


1;

__END__

=back

=head1 COPYRIGHT AND LICENSE

The Simple::SAX::Serializer module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 SEE ALSO

L<Simple::SAX::Serializer::Parser>
L<XML::LibXML::SAX>

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

See also 

=cut