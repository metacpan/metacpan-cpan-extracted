#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/Simple/Parser.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/29/2006
# Revision:	$Id: Parser.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::Simple::Parser;

use strict;
use warnings;

use base qw/ODO/;

use ODO::Exception;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use Parse::RecDescent;

our $PARSER = undef;

=head1 NAME

ODO::Ontology::Query::Simple::Parser

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERNALS

=over 

=item $GRAMMAR

=cut

our $GRAMMAR=q(

{
	use ODO::Node;
	use ODO::Statement;
	use ODO::Query::Simple;
}

StatementPatternClause: StatementPattern(s /,/) { $return = $item[1]; }

StatementPattern: '(' VarOrURI ',' VarOrURI ',' VarOrConst ')' 
	{ 
		$return = ODO::Query::Simple->new(s=> $item[2], p=> $item[4], o=> $item[6]);
	}
	
Variable: /(^[?](\w|[-.])+)/ 
	{ 
		$return = $item{'__PATTERN1__'};
		chomp($return);
		$return =~ s/^[?]//;
		$return = ODO::Node::Variable->new($return);
	}

VarOrURI: Variable 
	| URI 
	
VarOrConst: 
	  Variable
	| Const 

Const:    URI
	| NumericLiteral { $return = ODO::Node::Literal->new($item[1]); }
	| TextLiteral { $return = ODO::Node::Literal->new($item[1]); }
	| BooleanLiteral { $return = ODO::Node::Literal->new($item[1]); }
	| NullLiteral { $return = ODO::Node::Literal->new($item[1]); }

URI:      '<' URIChars '>' { $return = $item[2]; }
	{
		$return = ODO::Node::Resource->new($item[2]);
	}
	| QName
	{
		$return = ODO::Node::Resource->new($item[1]);

		push @{ $::QNames }, $return;
	}

QName: NSPrefix ':' LocalPart { $return = $item[1] . ':' . $item[3];  }

NSPrefix: idchars { $return = $item[1]; }

LocalPart: /[^ \t<>(),.;'"+=]+/ { $return = $item{'__PATTERN1__'}; }

NumericLiteral: 
	  /([0-9]+)/ { $return = $item{'__PATTERN1__'}; chomp($return); }
	| /(([0-9])*'.'([0-9])+('e'('+'|'-')?([0-9])+)?)/ { $return = $item{'__PATTERN1__'}; chomp($return); 1; }

NullLiteral: /null/i { $return = 'null'; }

TextLiteral: /"/ idchars /"/ { $return = $item[1]; }
	| /'/ idchars /'/ { $return = $item[1]; }

BooleanLiteral: /true|false/i { $return = lc($item{'__PATTERN1__'}); }

idchars: /(([a-zA-Z0-9]|[\-_\.])+)/ { $return = $item{'__PATTERN1__'}; chomp($return); }

URIChars: /([A-Za-z0-9]|[:.\-_\/#])+/ { $return = $item{'__PATTERN1__'}; chomp($return); }

);

=head1 METHODS

=over

=item parse( $query_string )

=cut

sub parse {
	my ($self, $query_string) = @_;
	
	chomp($query_string);

	$PARSER = new Parse::RecDescent($GRAMMAR)
		unless(UNIVERSAL::isa($PARSER, 'Parse::RecDescent'));

	return $PARSER->StatementPatternClause($query_string);
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
