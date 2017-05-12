use strict;
#use warnings;

package RDF::Notation3::XML;

require 5.005_62;
use RDF::Notation3;
use RDF::Notation3::Template::TXML;

############################################################

@RDF::Notation3::XML::ISA = 
  qw(RDF::Notation3::Template::TXML RDF::Notation3);


sub parse_file {
    my ($self, $path) = @_;
    $self->_do_error(1, '') unless @_ > 1;

    $self->{xml} = [];
    $self->{count} = 0;

    $self->doStartDocument;
    $self->SUPER::parse_file($path);
    $self->doEndDocument;
    return $self->{count};
}


sub parse_string {
    my ($self, $str) = @_;
    $self->_do_error(3, '') unless @_ > 1;

    $self->{xml} = [];
    $self->{count} = 0;

    $self->doStartDocument;
    $self->SUPER::parse_string($str);
    $self->doEndDocument;
    return $self->{count};
}


sub get_arrayref {
    my $self = shift;
    return $self->{xml};
}


sub get_array {
    my $self = shift;
    my $xml = $self->{xml};
    return @$xml;
}


sub get_string {
    my $self = shift;
    my $xml = $self->{xml};
    return join "\n", @$xml, '';
}


sub doStartDocument {
    my $self = shift;
    $self->{level} = 0;
    push @{$self->{xml}}, 
      "<?xml version=\"1.0\" encoding=\"utf-8\"?>";

    my @attr = (['xmlns:rdf','http://www.w3.org/1999/02/22-rdf-syntax-ns#']);
    $self->doStartElement('rdf:RDF', \@attr);
}


sub doEndDocument {
    my $self = shift;
    $self->doEndElement('rdf:RDF');
}


sub doStartElement {
    my ($self, $tag, $attr) = @_;
    my $element = '  ' x $self->{level}++ 
      . "<$tag "
	. join(' ', map {qq/$_->[0]="$_->[1]"/} @$attr)
	  . ">";
    $element =~ s/ >$/>/;
    push @{$self->{xml}}, $element;
}


sub doEndElement {
    my ($self, $tag) = @_;
    push @{$self->{xml}},
      '  ' x --$self->{level} 
	. "</$tag>";
}


sub doElement {
    my ($self, $tag, $attr, $value) = @_;
    my $element = '  ' x $self->{level} 
      . "<$tag "  
	  . join(' ', map {qq/$_->[0]="$_->[1]"/} @$attr) 
	    . '>';
    $element =~ s/ >$/>/;
    if ($value) {
	$element .= $value;
	$element .= "</$tag>";
    } else {
	$element =~ s/>$/\/>/;	
    }
    push @{$self->{xml}}, $element;
}


1;


__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::XML - RDF/N3 to RDF/XML convertor

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3.

=cut
