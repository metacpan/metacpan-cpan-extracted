use strict;
#use warnings;

package RDF::Notation3::SAX;

require 5.005_62;
use RDF::Notation3;
use RDF::Notation3::Template::TXML;
use XML::SAX::Base;
use IO::File;
use Carp;

############################################################

@RDF::Notation3::SAX::ISA = 
  qw(XML::SAX::Base RDF::Notation3::Template::TXML RDF::Notation3);

# --------------------------------------------------

sub _parse_bytestream {
    my ($self, $fh, $options) = @_; #FIXME: options to ai jsou zbytecne

    $self->_do_error(1, '') unless @_ > 1;
    $self->{ansuri} = '#' unless exists $self->{ansuri};
    $self->{quantif} = 1 unless exists $self->{quantif};
    $self->{count} = 0;
    $self->doStartDocument;
    eval { $self->RDF::Notation3::parse_file($fh) };
    if ($@) {
	my ($ms, $ln) = _parse_error_msg($@);
	$self->SUPER::error({
			Message => $ms, 
			Exception => $@, 
			LineNumber => $ln });
    }
    return $self->doEndDocument;
}

sub _parse_string {
    my ($self, $str, $options) = @_;

    $self->_do_error(3, '') unless @_ > 1;
    $self->{ansuri} = '#' unless exists $self->{ansuri};
    $self->{quantif} = 1 unless exists $self->{quantif};
    $self->{count} = 0;
    $self->doStartDocument;
    eval { $self->RDF::Notation3::parse_string($str) };
    if ($@) {
	my ($ms, $ln) = _parse_error_msg($@);
	$self->SUPER::error({
			Message => $ms, 
			Exception => $@, 
			LineNumber => $ln });
    }
    return $self->doEndDocument;
}

sub _parse_systemid {
    my ($self, $uri, $options) = @_;

    my $fh = IO::File->new($uri) or croak "RDF::Notation3: Can't open $uri ($!)";
    $self->_parse_bytestream($fh, $options);
    #$self->_do_error(301, '');
}

sub _parse_characterstream {
    my ($self, $fh, $options) = @_;
    $self->_do_error(302, '');
}

# --------------------------------------------------

sub doStartDocument {
    my $self = shift;
    $self->start_document({});

    $self->{context} = '<>';

    my @attr = (['xmlns:rdf','http://www.w3.org/1999/02/22-rdf-syntax-ns#']);
    $self->doStartElement('rdf:RDF', \@attr);
}


sub doEndDocument {
    my $self = shift;
    $self->doEndElement('rdf:RDF');
    return $self->end_document({});
}


sub doStartElement {
    my ($self, $tag, $attr) = @_;

    my %ahash;
    foreach (@$attr) {
	my ($prefix, $lname) = _split_qname($_->[0]);
	my $ns = $self->_set_namespace($prefix);

	$ahash{"{$ns}$_->[0]"} = {
			Name => $_->[0],
			LocalName => $lname,
			Prefix => $prefix,
			NamespaceURI => $ns,
			Value => $_->[1] };
    }
    my ($prefix, $lname) = _split_qname($tag);
    my $ns = $self->_set_namespace($prefix);

    $self->start_element({
		Name => $tag,
		LocalName => $lname,
		Prefix => $prefix,
		NamespaceURI => $ns,
		Attributes => \%ahash });
}


sub doEndElement {
    my ($self, $tag) = @_;

    my ($prefix, $lname) = _split_qname($tag);
    my $ns = $self->_set_namespace($prefix);

    $self->end_element({
		Name => $tag,
		LocalName => $lname,
		Prefix => $prefix,
		NamespaceURI => $ns } );
}


sub doElement {
    my ($self, $tag, $attr, $value) = @_;

    $self->doStartElement($tag, $attr, $tag);

    $self->characters({	Data => $value });

    $self->doEndElement($tag, $tag);
}


# ---------- utility functions ----------

sub _set_namespace {
    my ($self, $prefix) = @_;

    my $ns = $self->{ns}->{$self->{context}}->{$prefix};

    if ($prefix eq 'rdf') {
	$ns = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
	  unless $self->{ns}->{$self->{context}}->{rdf};
    } elsif ($prefix eq 'xml') {
	$ns = 'http://www.w3.org/XML/1998/namespace';
    } elsif ($prefix eq 'xmlns') {
	$ns = 'http://www.w3.org/2000/xmlns/';
    }
    $ns = '' unless $ns;

    return $ns;
}


sub _split_qname {
    my $qname = shift;

    my $prefix = '';
    my $lname = $qname;
    if ($qname =~ /^([_a-zA-Z]\w*)*:([a-zA-Z]\w*)$/) {
	$prefix = $1;
	$lname  = $2;
    } 
    return ($prefix, $lname);
}


sub _parse_error_msg {
    my $msg = shift;

    my $ms = 'RDF::Notation3 parse error';
    my $ln = 'n/a';
    $msg =~ /] line (\d+)/ and $ln = $1;

    return ($ms, $ln);
}


1;


__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::XML - RDF/N3 to RDF/XML SAX convertor

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3.

=cut
