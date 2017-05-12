#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Parser/NTriples.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/01/2006
# Revision:	$Id: NTriples.pm,v 1.2 2009-11-25 17:54:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Parser::NTriples;

use strict;
use warnings;

use ODO::Exception;

use ODO::Node;
use ODO::Statement;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use base qw/ODO::Parser/;

__PACKAGE__->mk_accessors(qw/base_uri statements/);

=head1 NAME

ODO::Parser::NTriples - Parser for statements serialized in NTriples format.

=head1 SYNOPSIS

 use ODO::Parser::NTriples;
 
 my $statements = ODO::Parser::NTriples->parse_file('some/path/to/data.ntriples');
 
 my $rdf = ' ... ntriples format here ... ';
 my $other_statements = ODO::Parser::NTriples->parse(\$rdf);

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=over

=item parse( $rdf, [ base_uri=> $base_uri ] )

=cut

sub parse {
	my ( $self, $rdf, %parameters ) = @_;
	
	$self = ODO::Parser::NTriples->new(%parameters)
		unless(ref $self);
	
	$rdf = $self->_split_text($rdf)
		unless(UNIVERSAL::isa($rdf, 'ARRAY'));
	
	foreach my $line (@{ $rdf }) {
		my $statement = $self->_make_statement($line);
		
		next 
			unless($statement);
		
		$self->add_statement($statement);
	}
	
	return $self->statements();
}


=item parse_file( $filename, [ base_uri=> $base_uri ] )

=cut

sub parse_file {
	my ($self, $filename, %parameters) = @_;
	
	$self = ODO::Parser::NTriples->new(%parameters)
		unless(ref $self);
	
	throw ODO::Exception::File::Missing(error=> "Could not locate file: $filename")
		unless(-e $filename);
	
	open(RDF_FILE, $filename);
	foreach my $line (<RDF_FILE>) {
		
		$line =~ s/\n|\r$//;
		my $statement = $self->_make_statement($line);
		
		next
			unless($statement);
	
		$self->add_statement($statement);
	}
	close(RDF_FILE);
	
	return $self->statements();
}



sub init {
	my ($self, $config) = @_;
	$self->base_uri( $config->{'base_uri'} );
	$self->statements( [] );
	return $self;
}


sub _split_text {
	shift;
	
	my $rdf_text = shift;
	my @statements = split(/\r\n|\n|\r/, $rdf_text);
	
	return \@statements;
}

sub _make_statement {
	my ($self, $line) = @_;

	return undef
		unless($line && $line !~ /^#/ && $line !~ /^[\ \t]+$/);

	throw ODO::Exception::Parameter::Invalid(error=> "Line does not end with a '.': '$line'")
		unless($line =~ m/.*[\ \t]+\.[\ \t]*$/);
	
	my ($s, $p, $o ) = split(/[\ \t]+/, $line);
	
	throw ODO::Exception::Parameter::Invalid(error=> 'Could not split line in to components of a statement')
		unless($s && $p && $o);
	
	$s = $self->make_node($s);
	$p = $self->make_node($p);
	$o = $self->make_node($o);
	
	throw ODO::Exception::Parameter::Invalid(error=> "Could not create ODO::Node's for the raw text")
		unless(    UNIVERSAL::isa($s, 'ODO::Node')
				&& UNIVERSAL::isa($p, 'ODO::Node')
				&& UNIVERSAL::isa($o, 'ODO::Node')
			);

	my $t = ODO::Statement->new('s'=> $s, 'p'=> $p, 'o'=> $o);
	
	throw ODO::Exception::Parameters::Invalid("Could not create statement for: $s, $p, $o")
		unless(UNIVERSAL::isa($t, 'ODO::Statement'));

	return $t;	
}

sub add_statement {
	my ($self, $statement) = @_;
	push @{ $self->statements() }, $statement;
}

sub make_node {
	my ($self, $node) = @_;
	
	if($node =~ /^_:(\w+|\d+)/) {
		return ODO::Node::Blank->new($1);
	}
	elsif($node =~ /^<(.*)>$/) {
		return ODO::Node::Resource->new($1);
	}
	else {
		return $self->make_literal($node);
	}
}


sub make_literal {
	my ($self, $raw) = @_;	
	my $literal = ODO::Node::Literal->new();

	my $value;
	my $datatype;
	my $language;
	
	if( ( ( $value, $datatype ) = split('^^', $raw)) ) {
		if($value =~ /"(.*)"/) {
			$value = $1;
		}
		
		$literal->datatype($datatype)
			if($datatype);
	}
	elsif( ( ( $value, $language ) = split('@', $raw)) ) {
		if($value =~ /"(.*)"/) {
			$value = $1;
		}
		
		$literal->language($language)
			if($language);
	}
	else {
		if($raw=~ /^\w*"(.*)"\w*$/) {
			$value = $1;
		}
		else {
			return undef;
		}
	}

	$literal->value($value);
	
	return $literal;
}


=back

=head1 COPYRIGHT

Copyright (c) 2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
