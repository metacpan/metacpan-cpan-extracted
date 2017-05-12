#
# Copyright (c) 2007 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Parser/N3.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  01/05/2007
# Revision:	$Id: N3.pm,v 1.2 2009-11-25 17:54:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Parser::N3;

use strict;
use warnings;

use ODO::Exception;

use ODO::Node;
use ODO::Statement;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use Parse::RecDescent;

use base qw/ODO::Parser/;

__PACKAGE__->mk_accessors(qw/base_uri statements/);

our $PARSER = undef;

#        $::RD_ERRORS     =1; # unless undefined, report fatal errors
#        $::RD_WARN       =1; # unless undefined, also report non-fatal problems
#        $::RD_HINT       =1; # if defined, also suggestion remedies
#        $::RD_TRACE      =1; # if defined, also trace parsers' behaviour

our $GRAMMAR = q(

<autotree>

{
	use Data::Dumper;
	use ODO::Node;
	use ODO::Statement;
	
	my $prefix;
	my $frag;

	my $subject;
	my $predicate;

	my $predicate_list;
	my $object_list;
}

start_parse:{ $::Prefixes = {}; $::Statements = [] } document { $return = { prefixes=> $::Prefixes, 'statements'=> $::Statements }; }

barename: /([a-zA-Z_][a-zA-Z0-9_]*)/ { $return = $item{'__PATTERN1__'}; }

declaration: '@prefix' prefix explicituri { $::Prefixes->{ $item[2] } = $item[3]; } 

document: statements_optional

dtlang: '@' langcode { $return = [$item[2], undef]; }
	| '^^' symbol    { $return = [undef, $item[2]]; }
	| { $return = []; } # void 

explicituri: /<([^>]*)>/ { $return = $item{'__PATTERN1__'}; ($return) = $return =~ m/<(.*)>/; }

existential: explicituri { $return = $item[1]; }

formulacontent: statementlist

langcode: /([a-z]+(-[a-z0-9]+)*)/ { $return = $item{'__PATTERN1__'}; }

literal: string dtlang { $return = ODO::Node::Literal->new($item[1], @{ $item[2] }); }

node: literal { $return = $item[1]; }
	| numericliteral { $return = $item[1]; }
	| symbol { $return = $item[1]; }
	| variable { $return = $item[1]; }
	| '(' pathlist ')' { $return = $item[2]; }
	| '@this'
	| '[' propertylist ']' { $return = $item[2]; }
	| '{' formulacontent '}' { $return = $item[2]; }

numericliteral: /([-+]?[0-9]+(\.[0-9]+)?(e[-+]?[0-9]+)?)/ { $return = $item{'__PATTERN1__'}; }

object: path { $return = $item[1]; }

objecttail: ',' object objecttail { $return = [ $item[2], @{ $item[3] } ]; }
	| { $return = []; } # void

path: node pathtail { $return = [ $item[1], @{ $item[2] } ]; }

pathlist: path pathlist
	| # void

pathtail: '!' path
	| '^' path
	| { $return = []; } # void

prefix: /([a-zA-Z_][a-zA-Z0-9_]*)?:/ { $return = $item{'__PATTERN1__'}; chomp($return); chop($return); }

propertylist: verb object objecttail propertylisttail
	{
		$return = [
			[ $item[1], ($item[2], @{ $item[3] }) ],
			@{ $item[4] }
		];
	}
	| { $return = []; } # void

propertylisttail: ';' propertylist { $return = $item[2]; }
	| { $return = []; } # void

qname: /(([a-zA-Z_][a-zA-Z0-9_]*)?:)?[a-zA-Z_][a-zA-Z0-9_]*/ 
	{
		($prefix, $frag) = $item{'__PATTERN1__'} =~ m/^([a-zA-Z_][a-zA-Z0-9_]*):([a-zA-Z_][a-zA-Z0-9_]*)$/;
		$return = { prefix=> $prefix, frag=> $frag }
	}

simpleStatement: subject propertylist
	{
		$subject = $item[1]->[0];
		
		# Format is predicate = arr[0], object_list = arr[1...N]
		foreach my $property_group (@{ $item[2] }) {
			
			$predicate = $property_group->[0]->[0];
			shift @{ $property_group };
			
			foreach my $object (@{ $property_group }) {
				push @{ $::Statements }, ODO::Statement->new($subject, $predicate, $object->[0]);
			}
		}
	}

statement: declaration
	| simpleStatement
	| existential
	| universal

statementlist: statement statementtail
	| # void

statements_optional: statement '.' statements_optional
	| # void

statementtail: '.' statementlist
	| # void

string: /("""[^"\\\\]*(?:(?:\\.|"(?!""))[^"\\\\]*)*""")|("[^"\\\\]*(?:\\.[^"\\\\]*)*")/ { $return = $item{'__PATTERN1__'}; $return =~ s/^"//g; chomp($return); chop($return); 1; }

subject: path { $return = $item[1]; }

symbol: explicituri { $return = ODO::Node::Resource->new($item[1]); }
	| qname { $return = ODO::Node::Resource->new($::Prefixes->{ $item[1]->{'prefix'} } . $item[1]->{'frag'}); }

universal: variable { $return = $item[1]; }

variable: /(\?[a-zA-Z_][a-zA-Z0-9_]*)/ { $return = $item{'__PATTERN1__'}; }

verb: path { $return = $item[1] }
	| '@'
	| '@has' path
	| '@is' path '@of'
	| '='
	| '<='
	| '>='
	
);

=head1 NAME

ODO::Parser::N3 - Parser for statements serialized in Notation3 format.

=head1 SYNOPSIS

 use ODO::Parser::N3;
 
 my $statements = ODO::Parser::N3->parse_file('some/path/to/data.n3');
 
 my $rdf = ' ... n3 format here ... ';
 my $other_statements = ODO::Parser::N3->parse(\$rdf);

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=over

=item parse( $rdf, [ base_uri=> $base_uri ] )

=cut

sub parse {
	my ( $self, $rdf, %parameters ) = @_;
	
	$self = ODO::Parser::N3->new(%parameters)
		unless(ref $self);

	my $parse_results = $PARSER->start_parse($rdf);
	return $parse_results->{'statements'};
}


=item parse_file( $filename, [ base_uri=> $base_uri ] )

=cut

sub parse_file {
	my ($self, $filename, %parameters) = @_;
	
	$self = ODO::Parser::N3->new(%parameters)
		unless(ref $self);
	
	throw ODO::Exception::File::Missing(error=> "Could not locate file: $filename")
		unless(-e $filename);

	local $/ = undef;	
	open(RDF_FILE, $filename);
	my $rdf = <RDF_FILE>;
	close(RDF_FILE);
	
	return $self->parse($rdf, %parameters);
}



sub init {
	my ($self, $config) = @_;
	$self->base_uri( $config->{'base_uri'} );
	$self->statements( [] );

	unless(UNIVERSAL::isa($PARSER, 'Parse::RecDescent')) {
		$PARSER = Parse::RecDescent->new($GRAMMAR);
	}

	return $self;
}


=back

=head1 COPYRIGHT

Copyright (c) 2007 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
