#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/RDQL/Parser.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/05/2004
# Revision:	$Id: Parser.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::RDQL::Parser;

use strict;
use warnings;

use ODO::Exception;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use Parse::RecDescent;

use base qw/ODO/;

=head1 NAME

ODO::Query::RDQL::Parser

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERNALS

=over

=item $PARSER

=cut

our $PARSER = undef;

#        $::RD_ERRORS     =1; # unless undefined, report fatal errors
#        $::RD_WARN       =1; # unless undefined, also report non-fatal problems
#        $::RD_HINT       =1; # if defined, also suggestion remedies
#        $::RD_TRACE      =1; # if defined, also trace parsers' behaviour

=item $RDQL_GRAMMAR

=cut

our $RDQL_GRAMMAR = q(

# $::QNames is the QName array list. 
# It is processed during the Query object construction phase to fully qualify the
# QName Resource nodes with the appropriate URI
{
	use ODO::Node;
	use ODO::Statement;
	use ODO::Query::Simple;
	use ODO::Query::Constraint;
	
	use ODO::Query::RDQL;
}

QueryStart: { $::QNames = [ ]; $::Query = ODO::Query::RDQL->new(); } Query	

Query: SelectClause SourceClause(?) StatementPatternClause ConstraintClause(?) PrefixesClause(?) /^\Z/
	{
		# Collapse the nested arrays
		# This probably could be done in the parse itself
		my $constraints = [];

		while(   UNIVERSAL::isa($item[4]->[0], 'ARRAY')
		      && @{ $item[4]->[0] }) {
			
			my $c = shift @{ $item[4]->[0] };
			
			unless(ref $c eq 'ARRAY') {
				push @{ $constraints }, $c;
				next;
			}

			foreach my $innerc (@{ $c }) {
				push @{ $item[4]->[0] }, $innerc;
			}
		}
		
		$::Query->constraints($constraints);

		$return = {
			source=> $item[2],
			query=> $::Query,
			qnames=> $::QNames,
		};
	}


SelectClause: /select/i Variable(s /,/) 
	{
		$::Query->{'result_vars'}->{'#variables'} = $item[2];
		
		1;
	}
	    | /select/i '*' 
	{ 
		push @{ $::Query->{'result_vars'}->{'#variables'} }, $ODO::Node::ANY;
		
		1;	
	}

Variable: /(^[?](\w|[-.])+)/ 
	{ 
		$return = $item{'__PATTERN1__'};
		chomp($return);
		$return =~ s/^[?]//;
		$return = ODO::Node::Variable->new($return);
		
		1; 
	}

SourceClause:  SourceFrom SourceSelector(s /,/)

SourceFrom: /(source|from)/i { $return = lc($item{'__PATTERN1__'}); 1; }

SourceSelector: QName

StatementPatternClause: /where/i StatementPattern(s /,/) { $return = $item[2]; 1; }

StatementPattern: '(' VarOrURI ',' VarOrURI ',' VarOrConst ')' 
	{ 
		push @{ $::Query->{'statement_patterns'}->{'#patterns'} }, ODO::Query::Simple->new( $item[2], $item[4], $item[6]);
		
		1;
	}

VarOrURI: Variable 
	| URI 
	
VarOrConst: 
	  Variable
	| Const 

ConstraintClause:

PrefixesClause: /using/i PrefixDecl(s? /,/) { $return = $item[2]; 1; }

PrefixDecl: idchars /for/i '<' URIChars '>' 
	{
		$::Query->{'prefixes'}->{$item[1]} = $item[4];
		
		1;
	}

Const:    URI
	| NumericLiteral 	{ $return = ODO::Node::Literal->new($item[1]); 1; }
	| TextLiteral 		{ $return = ODO::Node::Literal->new($item[1]); 1; }
	| BooleanLiteral 	{ $return = ODO::Node::Literal->new($item[1]); 1; }
	| NullLiteral 		{ $return = ODO::Node::Literal->new($item[1]); 1; }

URI:      '<' URIChars '>' { $return = $item[2]; }
	{
		$return = ODO::Node::Resource->new($item[2]);
		
		1;
	}
	| QName
	{
		$return = ODO::Node::Resource->new($item[1]);

		push @{ $::QNames }, $return;
		
		1;
	}

QName: NSPrefix ':' LocalPart { $return = $item[1] . ':' . $item[3];  }

NSPrefix: idchars { $return = $item[1]; }

LocalPart: /[^ \t<>(),.;'"+=]+/ { $return = $item{'__PATTERN1__'}; }

NumericLiteral:
	  /([0-9]+)/ { $return = $item{'__PATTERN1__'}; chomp($return); }
	| /(([0-9])*'.'([0-9])+('e'('+'|'-')?([0-9])+)?)/ { $return = $item{'__PATTERN1__'}; chomp($return); 1; }

NullLiteral: /null/i { $return = 'null'; 1; }

TextLiteral: /"/ idchars /"/ { $return = $item[1]; 1; }
	| /'/ idchars /'/ { $return = $item[1]; 1; }

BooleanLiteral: /true|false/i { $return = lc($item{'__PATTERN1__'}); 1; }

idchars: /(([a-zA-Z0-9]|[\-_\.])+)/ { $return = $item{'__PATTERN1__'}; chomp($return); 1; }

URIChars: /([A-Za-z0-9]|[:.\-_\/#])+/ { $return = $item{'__PATTERN1__'}; chomp($return); 1; }

);


=item $CONSTRAINTS

=cut

our $CONSTRAINTS = q(

<autotree>

{
	# Used with rules that follow the RuleName: Operation TailRuleName
	$::TailStub = sub {

		my @item = @{ $_[0] };
		my %item = %{ $_[1] };

		if($item[2] eq 'Tail' . $item[0]) {
			return $item[1];
		}
		else {
			if(UNIVERSAL::isa($item[2], 'ODO::Query::Constraint')) {
				$item[2]->left($item[1]);
				return $item[2];
			}
			else {
				
				# FIXME: This is an error condition
				return bless \%item, $item[0];
			}
		}	
	};
	
	# This occurs only during unary actions with an operator
	$::UnaryAction = sub {
		my @item = @{ $_[0] };
#		my %item = %{ $_[1] }; # Not needed but preserved

		return ODO::Query::Constraint->new(operation=> $item[1], is_unary=> 1, left=> $item[2]);
	};
	
	# Evaluated in the TailRuleName productions
	$::MakeTailConstraint = sub {
		my @item = @{ $_[0] };
#		my %item = %{ $_[1] }; # Not needed but preserved

		return ODO::Query::Constraint->new(operation=> $item[1], right=> $item[2]);
	};
}

ConstraintClause: /and/i ExpressionList
	{ $return = $item[2]; }

ExpressionList: ConditionalOrExpression TailExpressionList
	{
		$return = [ $item[1] ];
		
		push @{ $return }, $item[2]
			if(ref $item[2]);
	}

TailExpressionList: ',' ExpressionList
	{ $return = $item[2]; }
	| # Empty

ConditionalOrExpression: ConditionalAndExpression TailConditionalOrExpression
	{ $return = $::TailStub->(\@item, \%item); }
	
TailConditionalOrExpression:
	'||' ConditionalOrExpression
	{ $return = $::MakeTailConstraint->(\@item, \%item); }
	| # Empty

ConditionalAndExpression: StringEqualityExpression TailConditionalAndExpression
	{ $return = $::TailStub->(\@item, \%item); }

TailConditionalAndExpression:
	'&&' ConditionalAndExpression
	{ $return = $::MakeTailConstraint->(\@item, \%item); }
	| # Empty

StringEqualityExpression: InclusiveOrExpression TailStringEqualityExpression
	{ $return = $::TailStub->(\@item, \%item); }

TailStringEqualityExpression:
	/eq|ne/ StringEqualityExpression
	{ $return = $::MakeTailConstraint->(\@item, \%item); }
	| # Empty

InclusiveOrExpression: ExclusiveOrExpression TailInclusiveOrExpression
	{ $return = $::TailStub->(\@item, \%item); }
 
TailInclusiveOrExpression:
	/[|]/ InclusiveOrExpression
	{ $return = $::MakeTailConstraint->(\@item, \%item); }
	| # Empty

ExclusiveOrExpression: AndExpression TailExclusiveOrExpression
	{ $return = $::TailStub->(\@item, \%item); }

TailExclusiveOrExpression:
	/[\^]/ ExclusiveOrExpression
	{ $return = $::MakeTailConstraint->(\@item, \%item); }
	| # Empty
	
AndExpression: EqualityExpression TailAndExpression
	{ $return = $::TailStub->(\@item, \%item); }

TailAndExpression:
	/[&]/ AndExpression
	{ $return = $::MakeTailConstraint->(\@item, \%item); }
	| # Empty

EqualityExpression: 
	RelationalExpression /==|!=/ RelationalExpression
	{
		$return = ODO::Query::Constraint->new(operation=> $item[2], left=> $item[1], right=> $item[3]);
	}
	| RelationalExpression
	{ $return = $item[1]; }

RelationalExpression:
	ShiftExpression /<|>|<=|>=/ ShiftExpression
	{
		$return = ODO::Query::Constraint->new(operation=> $item[2], left=> $item[1], right=> $item[3]);
	}
	| ShiftExpression
	{ $return = $item[1]; }

ShiftExpression: AdditiveExpression TailShiftExpression
	{ $return = $::TailStub->(\@item, \%item); }

TailShiftExpression:
	/<<|>>>|>>/ ShiftExpression
	{ $return = $::MakeTailConstraint->(\@item, \%item); }
	| # Empty

AdditiveExpression: MultiplicativeExpression TailAdditiveExpression
	{ $return = $::TailStub->(\@item, \%item); }

TailAdditiveExpression:
	/[+-]/ AdditiveExpression
	{ $return = $::MakeTailConstraint->(\@item, \%item); }
	| # Empty

MultiplicativeExpression: UnaryExpression TailMultiplicativeExpression
	{ $return = $::TailStub->(\@item, \%item); }

TailMultiplicativeExpression: 
	/[*\/%]/ MultiplicativeExpression
	{ $return = $::MakeTailConstraint->(\@item, \%item); }
	| # Empty

UnaryExpression: 
	UnaryExpressionNotPlusMinus
	{ $return = $item[1]; }
	| /[+-]/ UnaryExpression
	{ $return = $::UnaryAction->(\@item, \%item); }

UnaryExpressionNotPlusMinus: 
	/[~!]/ UnaryExpression
	{ $return = $::UnaryAction->(\@item, \%item); }
	| PrimaryExpression
	{ $return = $item[1]; }
			
PrimaryExpression: 
	Variable
	{
		$return = $item[1];
	}
	| Const
	{
		$return = $item[1];
		
		$return = ODO::Node::Literal->new($item[1])
			unless(UNIVERSAL::isa($item[1], 'ODO::Node'));
	}	
	| '(' ConditionalOrExpression ')'  
	{ # Formerly just Expression
		$return = $item[2]; 
	} 
	| FunctionCall

FunctionCall: idchars '(' ArgList ')'

ArgList: VarOrConst(s /,/) { $return = $item[1]; }

PatternLiteral: idchars { $return = $item[1]; }

);


=back

# TODO: Fix URIChars so that it is a URI regexp
=head1 METHODS

=over

=item parse( $rdql )

=cut

sub parse {
	my ($self, $rdql) = @_;

	chomp($rdql);

	unless(UNIVERSAL::isa($PARSER, 'Parse::RecDescent')) {
		$PARSER = Parse::RecDescent->new($RDQL_GRAMMAR);
		$PARSER->Replace($CONSTRAINTS);
	}

	return $self->build_query_object($PARSER->QueryStart($rdql));
}


=item build_query_object( $parse_tree )

=cut

sub build_query_object {
	my ($self, $parse_tree) = @_;
	
	my $query = $parse_tree->{'query'};
	
	# Resolve all Resource nodes that contain QNames to fully qualified
	# URIs
	while(   UNIVERSAL::isa($parse_tree->{'qnames'}, 'ARRAY' )
	      && @{ $parse_tree->{'qnames'} } ) {
	
		my $qname = shift @{ $parse_tree->{'qnames'} };
		next 
			unless(UNIVERSAL::isa($qname, 'ODO::Node::Resource'));

		# If applicable, exploit the fact that this is a reference to
		# the ODO::Node::Resource object and reset the uri
		# to the appropriate value
		if($qname->uri() =~ /(\w+)[:](\w+)/) {
			my $uri_frag = $query->{'prefixes'}->{$1};
			$qname->uri($uri_frag . $2)
				if($uri_frag && $1 && $2); # FIXME: Figure out why this is necessary
		}
	}
	
	return $query;
}


=item print_rule_info( $rule_info, $indent, $parent, [ $fh ] )

=cut

sub print_rule_info {
	my ($self, $rule_info, $indent, $parent, $fh) = @_;
	
	$fh = \*STDERR
		unless(defined $fh);
	
	my $space = ' ' x $indent;
	foreach my $key (sort(keys(%{ $rule_info }))) {
		print $fh $space, $rule_info->{$key}, "\n"
			if($key eq '__RULE__');
		
		my $tail_name = 'Tail';
		$tail_name .= $rule_info->{'__RULE__'}
			if(exists($rule_info->{'__RULE__'}));
		
		print $fh $space, "CONSTRAINT: $tail_name\n"
			if(   exists($rule_info->{$tail_name}) 
			   && UNIVERSAL::isa($rule_info->{$tail_name}, 'HASH') );
		
		print $fh $space, $rule_info->{$key}->value(), "\n"
			if(UNIVERSAL::isa($rule_info->{$key}, 'ODO::Node'));
		
		if(UNIVERSAL::isa($rule_info->{$key}, 'HASH')) {
			$self->print_rule_info($rule_info->{$key}, $indent + 2, $rule_info, $fh);
		}
		else {
		
		}
	}
}


=back

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
