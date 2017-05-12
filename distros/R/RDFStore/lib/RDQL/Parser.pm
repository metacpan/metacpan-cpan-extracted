# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * Changes:
# *     version 0.1
# *		- first hacked version: pure perl RDQL/SquishQL top-down LL(1) parser with some extesnions:
# *                  * LIKE operator in AND clause
# *                  * free-text triple matching like (?x, ?y, %"whatever"%)
# *     version 0.2
# *    		- added SELECT DISTINCT 
# *    		- added SPARQL PREFIX support and default/built-in prefixes
# *    		- added # and // style comments
# *    		- added SPARQL QNAME like support
# *		- added ?prefix:var QName support to vars
# *		- added SPARQL CONSTRUCT support
# *		- added SPARQL $var support
# *		- added getQueryType() method
# *		- added SPARQL DESCRIBE support
# *		- fixed bug in Literal() when matching floating point numbers
# *		- updated constraints and removed AND keyword to be SPARQL compatible
# *		- added not standard RDQL/SPARQL DELETE support
# *		- added default SPARQL PREFIX op: <http://www.w3.org/2001/sw/DataAccess/operations> and PREFIX fn: <http://www.w3.org/2004/07/xpath-functions>
# *		- updated and simplified constraints productions to reflect latest SPARQL spec
# *		- constraints are now stacked into a RPN
# *		- added full SPARQL graph-patterns and grouping
# *		- added SPARQL FROM NAMED support
# *		- added SPARQL LIMIT support
# *		- added SPARQL OFFSET support
# *		- added SPARQL ORDER BY support
# *

package RDQL::Parser;
{

use vars qw ( $VERSION );
use strict;
use Carp;

$VERSION = '0.2';

sub parse ($$);
sub MatchAndEat ($$);
sub error ($$);
sub Select ($);
sub Construct ($);
sub Describe ($);
#sub Ask ($);
sub OrderBy ($);
sub Limit ($);
sub Offset ($);
sub Delete ($);
sub From ($);
sub FromNamed ($);
sub GraphPattern ($);
sub GraphAndPattern ($);
sub PatternElement ($);
sub GroupGraphPattern ($);
sub SourceGraphPattern ($);
sub OptionalGraphPattern ($);
sub Var ($);
sub URIOrQName ($);
sub Literal ($);
sub TriplePattern ($);
sub VarOrURIOrQName ($);
sub VarOrURIOrQNameOrLiteral ($);
sub Constraint ($);
sub Prefixes ($);
sub PrefixDecl ($);
sub ConditionalOrExpression ($);
sub ConditionalAndExpression ($);
sub StringEqualityExpression ($);
sub PatternLiteral ($);
sub EqualityExpression ($);
sub RelationalExpression ($);
sub AdditiveExpression ($);
sub MultiplicativeExpression ($);
sub UnaryExpression ($);
sub UnaryExpressionNotPlusMinus ($);
sub PrimaryExpression ($);
sub FunctionCall ($);
sub ArgList ($);

# some useful default prefixes
%RDQL::Parser::default_prefixes= (
	'http://www.w3.org/1999/02/22-rdf-syntax-ns#' => 'rdf',
	'http://www.w3.org/2000/01/rdf-schema#' => 'rdfs',
	'http://purl.org/rss/1.0/' => 'rss',
	'http://www.daml.org/2001/03/daml+oil#' => 'daml',
	'http://purl.org/dc/elements/1.1/' => 'dc',
	'http://purl.org/dc/terms/' => 'dcq',
	'http://xmlns.com/foaf/0.1/' => 'foaf',
	'http://www.w3.org/2001/XMLSchema#' => 'xsd',
	'http://www.w3.org/2002/07/owl#' => 'owl',
	# these two are SPARQL special - perhaps should not mix up with other namespaces? avoid to aoverride them?
	'http://www.w3.org/2001/sw/DataAccess/operations' => 'op',
	'http://www.w3.org/2004/07/xpath-functions' => 'fn'
	);

sub new {
	my $self = {
		prefixes		=>	{},
		sources			=>	[],
		from_named		=>	[],
		resultVars		=>	[],
		constructPatterns	=>	[],
		describes		=>	[],
		graphPatterns		=>	[],
		order_by		=>	[]
		};

	map {
		$self->{'prefixes'}->{ $RDQL::Parser::default_prefixes{ $_ } } = $_ ;
	} keys %RDQL::Parser::default_prefixes;

	bless $self, shift;
	};

sub MatchAndEat ($$) {
	my($class,$lit)=@_;

	# eat single line comments
	while( $class->{'query_string'} =~ s/^\s*(#|\/\/).*// ) {};

	# eat multi-line comments
	if( $class->{'query_string'} =~ s/^\s*\/\*// ) {
		while( $class->{'query_string'} !~ s/^\s*\*\/// ) {
			$class->{'query_string'} =~ s/^\s*(.)\s*//;
			};
		};

	return $class->{'query_string'} =~ s/^\s*\Q$lit\E\s*//i;
};

sub error($$) {
	my($class,$msg)=@_;
	croak "error: $msg: ".$class->{'query_string'}."\n";
};

sub parse($$) {
	my($class,$query) = @_;

	$class->{'query_string'} = $query;

	$class->{'context'}=[];
	$class->{'graph_patterns_pointer'} = []; #to check undeflow???
	
	while( MatchAndEat $class,'prefix' ) {
		PrefixDecl $class;
		};

	if( MatchAndEat $class,'select' ) {
		$class->{'queryType'} = 'SELECT';
		Select $class;
	} elsif( MatchAndEat $class,'construct' ) {
		$class->{'queryType'} = 'CONSTRUCT';
		Construct $class;
	} elsif( MatchAndEat $class,'describe' ) {
		$class->{'queryType'} = 'DESCRIBE';
		Describe $class;
	} elsif( MatchAndEat $class,'ask' ) {
		$class->{'queryType'} = 'ASK';
		#Ask $class;
	} elsif( MatchAndEat $class,'delete' ) {
		$class->{'queryType'} = 'DELETE';
		Delete $class;
	} else {
		error $class,'Expecting SELECT, CONSTRUCT, DESCRIBE, ASK or DELETE token'
			if($class->{'query_string'} ne '');
		};

	while( MatchAndEat $class,'prefix' ) {
		PrefixDecl $class;
		};

	while(	MatchAndEat $class,'source' or
		MatchAndEat $class,'from' ) {
		if( MatchAndEat $class,'named' ) {
			FromNamed $class;
		} else {
			From $class;
			};
		};

	GraphPattern $class
		if( MatchAndEat $class,'where');

	while(	MatchAndEat $class,'order' and
		MatchAndEat $class,'by' ) {
		OrderBy $class;
		};

	Limit $class
		if(MatchAndEat $class,'limit');

	Offset $class
		if(MatchAndEat $class,'offset');

	# eat this up anyway to keep legacy RDQL queries working...
        Prefixes $class
		if(MatchAndEat $class,'using');

	$class->{'query_string'} =~ s/^\s*//;
	$class->{'query_string'} =~ s/\s*$//;

	error $class,'illegal input'
		if($class->{'query_string'} ne '');

	delete($class->{'query_string'});
	delete($class->{'context'});
	delete($class->{'graph_patterns_pointer'});

	#use Data::Dumper;
	#print STDERR Dumper($class);

	return $class;
	};

sub Select($) {
	my($class) = @_;

	$class->{'distinct'} = ( MatchAndEat $class,'distinct' ) ? 1 : 0;
	push @{ $class->{'context'} }, 'select';
	if( MatchAndEat $class,'*') {
		push @{$class->{resultVars}},'*';
	} elsif( Var $class ) {
		do {
			MatchAndEat $class,',';
			} while ( Var $class );
	};
	pop @{ $class->{'context'} };
};

sub OrderBy($) {
	my($class) = @_;

	push @{ $class->{'context'} }, 'order by';

	if( MatchAndEat $class,'asc' ) {
		ConditionalOrExpression $class;

		push @{ $class->{'order_by'} }, 'ASC';
	} elsif( MatchAndEat $class,'desc' ) {
		ConditionalOrExpression $class;

		push @{ $class->{'order_by'} }, 'DESC';
	} else {
		if ( Var $class ) {
		} elsif ( FunctionCall $class ) {
		} else {
			ConditionalOrExpression $class;
			};

		push @{ $class->{'order_by'} }, 'ASC';
		};

	pop @{ $class->{'context'} };
};

sub Limit($) {
	my($class) = @_;

	push @{ $class->{'context'} }, 'limit';

	error $class,"limit requires an integer value"
		unless( Literal $class );

	error $class,"limit is invalid"
		unless(	$class->{'limit'} >= 0 );

	pop @{ $class->{'context'} };
};

sub Offset($) {
	my($class) = @_;

	push @{ $class->{'context'} }, 'offset';

	error $class,"offset requires an integer value"
		unless( Literal $class );

	error $class,"offset is invalid"
		unless(	$class->{'offset'} >= 0 );

	pop @{ $class->{'context'} };
};

sub Construct($) {
	my($class) = @_;

	$class->{'distinct'} = 0; #useless? see DBD::RDFStore driver
	push @{ $class->{'context'} }, 'construct';
	if( MatchAndEat $class,'*') {
		push @{$class->{constructPatterns}},'*';
	} elsif( TriplePattern $class ) {
	} else {
		if( MatchAndEat $class,'{' ) {
			# we do not deal with nested Groups yet...
			while ( TriplePattern $class ) {
                		MatchAndEat $class,',';
                		};

			error $class,"missing right brace"
				unless( MatchAndEat $class,'}' );
		} else {
			error $class,"missing left brace";
			};
		};
	pop @{ $class->{'context'} };
	};

sub Describe($) {
	my($class) = @_;

	$class->{'distinct'} = 0; #useless? see DBD::RDFStore driver
	push @{ $class->{'context'} }, 'describe';
	if( MatchAndEat $class,'*') {
		push @{$class->{describes}},'*';
	} elsif( VarOrURIOrQName $class ) {
		do {
			MatchAndEat $class,',';
			} while ( VarOrURIOrQName $class );
		};
	pop @{ $class->{'context'} };
	};

sub Delete($) {
	my($class) = @_;

	$class->{'distinct'} = 0;
	push @{$class->{resultVars}},'*'
		if( MatchAndEat $class,'*');
	};

sub Var($) {
	my($class) = @_;

	if($class->{'query_string'} =~ s/^\s*[\?\$]([a-zA-Z0-9_\.:]+)\s*//) {
		my $var = '?'.$1; # we force ?var style anyway
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'select' ) {
			push @{$class->{resultVars}}, $var
				unless(grep /^\Q$var\E$/,@{$class->{resultVars}});
			};
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'describe' ) {
			push @{$class->{describes}},$var
				unless(grep /^\Q$var\E$/,@{$class->{describes}});
			};
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'triples' ) {
			push @{$class->{triple_pattern}}, $var;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'constraints' ) {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, $var;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
			push @{ $class->{'order_by'} }, $var;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'named_graph' ) {
			$class->{'graph_name'} = $var;
		};

		return 1;
	};
	return 0;
};

sub FromNamed($) {
	my($class) = @_;

	push @{ $class->{'context'} }, 'from_named';
	if( URIOrQName $class ) {
		do {
                        MatchAndEat $class,',';
                        } while ( URIOrQName $class );
	} else {
		error $class, "malformed URI or QName";
	};
	pop @{ $class->{'context'} };
	};

sub From($) {
	my($class) = @_;

	push @{ $class->{'context'} }, 'source';
	if( URIOrQName $class ) {
		do {
                        MatchAndEat $class,',';
                        } while ( URIOrQName $class );
	} else {
		error $class, "malformed URI or QName";
	};
	pop @{ $class->{'context'} };
	};

sub URIOrQName($) {
	my($class) = @_;

	# the following covers also RDFStore/RDQL extensions for simple OR <URI1 , URI2 , URI3 ....>, 
	# <pp:ff , pp1:ff> and <"string a" , "literal b" .... "literal n">
	#if($class->{'query_string'} =~ s/^\s*((\<[^>]*\>)|([a-zA-Z0-9\-_$\.]+:[a-zA-Z0-9\-_$\.]+)|([a-zA-Z0-9\-_$\.]+:))\s*//) {
	if($class->{'query_string'} =~ s/^\s*(\<[^>]*\>)\s*//) { #not yet the above - but we are NOT RDQL compliant then - no QNames (need to fix all the DBD driver too then)
		# in the old RDQL syntax we do not deal with prefixes here yet but directly in the DBD::RDFStore driver code instead
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'triples' ) {
			push @{$class->{triple_pattern}}, $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'from_named' ) {
			push @{$class->{from_named}}, $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'source' ) {
			push @{$class->{sources}}, $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'constraints' ) {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
			push @{ $class->{'order_by'} }, $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'named_graph' ) {
			$class->{'graph_name'} = $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'describe' ) {
			push @{$class->{describes}},$1
				unless(grep /^\Q$1\E$/,@{$class->{describes}});
			};
		return 1;
	} elsif($class->{'query_string'} =~ s/^\s*([a-zA-Z0-9\-_$\.]+)?:([a-zA-Z0-9\-_$\.]+)\s*//) {
		# I am lazy, and do not want to fix DBD::RDFStore driver code too...
		my $qn;
		if($1) {
			# look up for a prefix if there
			if( exists $class->{'prefixes'}->{$1} ) {
				$qn = '<'. $class->{'prefixes'}->{$1} .$2.'>';
			} else {
				# otherwise should say unbound prefix in new SPARQL with pre-PREFIX syntax
				error $class,"Unbound prefix $1 ";
				};
		} else {
			# try to use default one
			$qn = '<'.( ( exists $class->{'prefixes'}->{'#default'} ) ? $class->{'prefixes'}->{'#default'} : $1 ).$2.'>';
			};
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'triples' ) {
			push @{$class->{triple_pattern}}, $qn;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'from_named' ) {
			push @{$class->{from_named}}, $qn;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'source' ) {
			push @{$class->{sources}}, $qn;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'constraints' ) {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, $qn;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
			push @{ $class->{'order_by'} }, $qn;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'named_graph' ) {
			$class->{'graph_name'} = $qn;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'describe' ) {
			push @{$class->{describes}},$qn
				unless(grep /^\Q$qn\E$/,@{$class->{describes}});
			};
		return 1;
		};
	return 0;
};

sub Literal($) {
	my($class) = @_;

	if(	($class->{'query_string'} =~ s/^\s*(([0-9]+\.[0-9]*([eE][+-]?[0-9]+)?[fFdD]?)|(\.[0-9]+([eE][+-]?[0-9]+)?[fFdD]?)|([0-9]+[eE][+-]?[0-9]+[fFdD]?)|([0-9]+([eE][+-]?[0-9]+)?[fFdD]))\s*//) or
		#($class->{'query_string'} =~ s/^\s*(%?\'((([^\'\\\n\r])|(\\([ntbrf\\'\"])|([0-7][0-7?)|([0-3][0-7][0-7]))))\'%?)\s*//) or
		($class->{'query_string'} =~ s/^\s*(%?[\"\']((([^\"\'\\\n\r])|(\\([ntbrf\\'\"])|([0-7][0-7?)|([0-3][0-7][0-7])))*)[\"\'](\@([a-z0-9]+(-[a-z0-9]+)?))?%?)\s*//) or
		($class->{'query_string'} =~ s/^\s*([0-9]+)\s*//) or
		($class->{'query_string'} =~ s/^\s*(0[xX]([0-9",a-f,A-F])+)\s*//) or
		#($class->{'query_string'} =~ s/^\s*(0[0-7]*)\s*//) or
		($class->{'query_string'} =~ s/^\s*(true|false)\s*//) or
		($class->{'query_string'} =~ s/^\s*(null)\s*//) ) {
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'triples' ) {
			push @{$class->{triple_pattern}}, $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'constraints' ) {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
			push @{ $class->{'order_by'} }, $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'named_graph' ) {
			$class->{'graph_name'} = $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'limit' ) {
			$class->{'limit'} = $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'offset' ) {
			$class->{'offset'} = $1;
		};
		return 1;
	};
	return 0;
};

sub GraphPattern($) {
	my($class) = @_;

	GraphAndPattern $class;
	while( MatchAndEat $class,'UNION' ) { # we might have an issue with UNION and AND 'expression' constraints if no braces - to be checked
		GraphAndPattern $class;

		push @{$class->{'graphPatterns'}}, 'UNION';
		};
	};

sub GraphAndPattern($) {
	my($class) = @_;

	# shall we check if previous on stack is an empty block, and use that one instead? Or how can we evaluate empty blocks?
	push @{$class->{'graphPatterns'}}, {
		'triplePatterns' =>	[],
		'constraints'	 =>	[],
		'optional'	 => 	( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'optional' ) ? 1 : 0
		};
	push @{ $class->{'graph_patterns_pointer'} }, $#{$class->{'graphPatterns'}};

        while( PatternElement $class ) {
		MatchAndEat $class,',';
		};

	pop @{ $class->{'graph_patterns_pointer'} };
	};

sub PatternElement($) {
	my($class) = @_;

	if( TriplePattern $class ) {
	} elsif( GroupGraphPattern $class ) {
	} elsif( SourceGraphPattern $class ) {
	} elsif( OptionalGraphPattern $class ) {
	} elsif( MatchAndEat $class,'and' ) {
		Constraint $class;

		$class->{'graphPatterns'}->[$#{$class->{'graphPatterns'}}]->{'constraints_optional'} = ( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'optional' ) ? 1 : 0;
	} else {
		return 0;
		};
	return 1;
	};

sub GroupGraphPattern($) {
	my($class) = @_;

	if( MatchAndEat $class,'{' ) {
		GraphPattern $class;

		error $class,"missing right brace"
			unless( MatchAndEat $class,'}' );

		push @{$class->{'graphPatterns'}}, 'AND';

		return 1;
	} else {
		return 0;
		};
	};

# SOURCE is just a modifier how to process a triple-pattern
sub SourceGraphPattern($) {
	my($class) = @_;

	if( MatchAndEat $class,'graph' ) {
		push @{ $class->{'context'} }, 'named_graph';

		# need to add GRAPH * - what does it really mean in the triple-pattern?
		error $class,"malformed GRAPH clause"
			unless( VarOrURIOrQName $class ); #context

		PatternElement $class;

		delete($class->{'graph_name'});

		pop @{ $class->{'context'} };

		return 1;
	} else {
		return 0;
		};
	};

# optionals are just a modifier how to process triple-patterns or blocks (triple-patterns+constraints)
# NOTE: for triple-patterns we allocate the 1st element of the array to flag (0/1) whether or not it is OPTIONAL
sub OptionalGraphPattern($) {
	my($class) = @_;

	if( MatchAndEat $class,'optional' ) {
		push @{ $class->{'context'} }, 'optional';

		PatternElement $class;

		pop @{ $class->{'context'} };

		return 1;
	} else {
		return 0;
		};
	};

sub TriplePattern($) {
	my($class) = @_;

	if( MatchAndEat $class,'(' ) {
		$class->{triple_pattern}=[ ( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'optional' ) ? 1 : 0 ];

		push @{ $class->{'context'} }, 'triples';

		error $class,"malformed subject variable, URI or QName"
			unless VarOrURIOrQName $class; #subject

		MatchAndEat $class,',';
		error $class,"malformed predicate variable, URI or QName"
			unless VarOrURIOrQName $class; #predicate

		MatchAndEat $class,',';
		error $class,"malformed object variable, URI, QName or literal"
			unless VarOrURIOrQNameOrLiteral $class; #object

		MatchAndEat $class,',';
		unless( VarOrURIOrQNameOrLiteral $class ) { #context
			push @{$class->{triple_pattern}}, $class->{'graph_name'}
				if( exists $class->{'graph_name'} );
			};

		error $class,"missing right round bracket"
			unless( MatchAndEat $class,')' );

		if(	( ( $#{ $class->{'context'} } - 1 ) >= 0 ) and
			$class->{'context'}->[ $#{ $class->{'context'} } - 1 ] eq 'construct' and
			$class->{constructPatterns}->[0] ne '*' ) {
			push @{$class->{constructPatterns}}, $class->{triple_pattern};
		} else {
			push @{$class->{'graphPatterns'}->[ $class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}] ]->{triplePatterns}}, $class->{triple_pattern};
			};

		delete($class->{triple_pattern});

		pop @{ $class->{'context'} };

		return 1;
	} else {
		return 0;
		};
	};

sub VarOrURIOrQName($) {
	my($class) = @_;

	return ( Var $class or URIOrQName $class );
};

sub VarOrURIOrQNameOrLiteral($) {
	my($class) = @_;

	return ( Var $class or URIOrQName $class or Literal $class );
};

sub Prefixes($) {
	my($class) = @_;

	while( PrefixDecl $class ) {
		MatchAndEat $class,',';
		};
};

sub PrefixDecl($) {
	my($class) = @_;
	if($class->{'query_string'} =~ s/^\s*(\w[\w\d]*)?:\s+\<([A-Za-z][^>]*)\>\s*//i) {
		return 0
			if( $1 eq 'fn' or $1 eq 'op'); #ignore overrride of special ones??
		$class->{prefixes}->{ ($1) ? $1 : '#default' }=$2;
		return 1;
	} elsif($class->{'query_string'} =~ s/^\s*(\w[\w\d]*)\s+FOR\s+\<([A-Za-z][^>]*)\>\s*//i) {
		return 0
			if(	( $1 eq 'fn' and $2 ne $class->{prefixes}->{'fn'} ) or
				( $1 eq 'op' and $2 ne $class->{prefixes}->{'op'} ) ); #ignore overrride of special ones??
		$class->{prefixes}->{$1}=$2;
		return 1;
		};
	return 0;
	};

sub Constraint($) {
	my($class) = @_;

	push @{ $class->{'context'} }, 'constraints';

	ConditionalOrExpression $class;
	while(  MatchAndEat $class,',' or
                MatchAndEat $class,'and') {
                ConditionalOrExpression $class;
        	};

	pop @{ $class->{'context'} };
	};

# we skip ConditionalXorExpression...
sub ConditionalOrExpression($) {
	my($class) = @_;

	ConditionalAndExpression $class;
	while( MatchAndEat $class,'||' ) {
		ConditionalAndExpression $class;
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
			push @{ $class->{'order_by'} }, '||';
		} else {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '||';
			};
	};
};

sub ConditionalAndExpression($) {
	my($class) = @_;

	StringEqualityExpression $class;
	while( MatchAndEat $class,'&&' ) {
		StringEqualityExpression $class;
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                        push @{ $class->{'order_by'} }, '&&';
                } else {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '&&';
                        };
	};
};

sub StringEqualityExpression($) {
	my($class) = @_;

	EqualityExpression $class;
	my $true=1;
	while( $true ) {
		if( MatchAndEat $class,'eq' ) {
			EqualityExpression $class;
			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                        	push @{ $class->{'order_by'} }, 'eq';
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, 'eq';
                        	};
		} elsif( MatchAndEat $class,'ne' ) {
			EqualityExpression $class;
			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                        	push @{ $class->{'order_by'} }, 'ne';
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, 'ne';
                        	};
		} elsif(	( MatchAndEat $class,'=~' ) ||
				( MatchAndEat $class,'LIKE' ) ) { # pattern is like [m]/pattern/[i][m][s][x]
			PatternLiteral $class; # should some pattern literal
			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                        	push @{ $class->{'order_by'} }, '=~';
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '=~';
                        	};
		} elsif( MatchAndEat $class,'!~' ) {
			PatternLiteral $class; # should some pattern literal
			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                        	push @{ $class->{'order_by'} }, '!~';
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '!~';
                        	};
		} else {
			$true=0;
		};
	};
};

sub PatternLiteral($) {
	my($class) = @_;

	if( $class->{'query_string'} =~ s/([m]?\/(.*)\/[i]?[m]?[s]?[x]?)// ) {
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'constraints' ) {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, $1;
		} elsif( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                       	push @{ $class->{'order_by'} }, $1;
                        };
		};
	};

sub EqualityExpression($) {
	my($class) = @_;

	RelationalExpression $class;
	my $true=1;
	while( $true ) {
		if( MatchAndEat $class,'==' ) {
			RelationalExpression $class;
			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                       		push @{ $class->{'order_by'} }, '==';
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '==';
                        	};
		} elsif( MatchAndEat $class,'!=' ) {
			RelationalExpression $class;
			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                       		push @{ $class->{'order_by'} }, '!=';
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '!=';
                        	};
		} else {
			$true=0;
		};
	};
};

sub RelationalExpression($) {
	my($class) = @_;

	AdditiveExpression $class;
	if( MatchAndEat $class,'>=' or MatchAndEat $class,'>=' ) {
		AdditiveExpression $class;
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                	push @{ $class->{'order_by'} }, '>=';
                } else {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '>=';
                       	};
	} elsif( MatchAndEat $class,'<=' or MatchAndEat $class,'<=' ) {
		AdditiveExpression $class;
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                	push @{ $class->{'order_by'} }, '<=';
                } else {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '<=';
                       	};
	} elsif( MatchAndEat $class,'<' ) {
		AdditiveExpression $class;
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                	push @{ $class->{'order_by'} }, '<';
                } else {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '<';
                       	};
	} elsif( MatchAndEat $class,'>' ) {
		AdditiveExpression $class;
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                	push @{ $class->{'order_by'} }, '>';
                } else {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '>';
                       	};
	};
};

sub AdditiveExpression($) {
	my($class) = @_;

	MultiplicativeExpression $class;
	my $true=1;
	while( $true ) {
		if( MatchAndEat $class,'+' ) {
			MultiplicativeExpression $class;
			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                		push @{ $class->{'order_by'} }, '+';
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '+';
                       		};
		} elsif( MatchAndEat $class,'-' ) {
			MultiplicativeExpression $class;
			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                		push @{ $class->{'order_by'} }, '-';
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '-';
                       		};
		} else {
			$true=0;
		};
	};
};

sub MultiplicativeExpression($) {
	my($class) = @_;

	UnaryExpression $class;
	my $true=1;
	while( $true ) {
		if( MatchAndEat $class,'*' ) {
			UnaryExpression $class;
			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                		push @{ $class->{'order_by'} }, '*';
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '*';
                       		};
		} elsif( MatchAndEat $class,'/' ) {
			UnaryExpression $class;
			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                		push @{ $class->{'order_by'} }, '/';
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '/';
                       		};
		} elsif( MatchAndEat $class,'%' ) {
			UnaryExpression $class;
			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                		push @{ $class->{'order_by'} }, '%';
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '%';
                       		};
		} else {
			$true=0;
		};
	};
};

sub UnaryExpression($) {
	my($class) = @_;

	UnaryExpressionNotPlusMinus $class;
};

sub UnaryExpressionNotPlusMinus($) {
	my($class) = @_;

	if( MatchAndEat $class,'~' ) {
		UnaryExpression $class;
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                	push @{ $class->{'order_by'} }, '~';
                } else {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '~';
                       	};
	} elsif ( MatchAndEat $class,'!' ) {
		UnaryExpression $class;
		if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                	push @{ $class->{'order_by'} }, '!';
                } else {
			push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, '!';
                       	};
	} else {
		PrimaryExpression $class;
	};
};

sub PrimaryExpression($) {
	my($class) = @_;

	if( MatchAndEat $class,'(' ) {

		ConditionalOrExpression $class;

		error $class,"missing right round bracket"
			unless( MatchAndEat $class,')' );

	} else {
		unless(	Var $class or URIOrQName $class or Literal $class ) {
			FunctionCall $class;
		};
	};
};

sub FunctionCall($) {
	my($class) = @_;

	if(	( MatchAndEat $class,'&' ) &&
		($class->{'query_string'} =~ s/^\s*([a-zA-Z0-9\-_$\.]+)?:([a-zA-Z0-9\-_$\.]+)\s*//) ) {
		#	if( $1 ne 'fn' and $1 ne 'op' );

		# look up for a prefix if there
		# NOTE: otherwise should say unbound prefix in new SPARQL with pre-PREFIX syntax
		my $qn;
		if( exists $class->{'prefixes'}->{ ($1) ? $1 : '#default' } ) {
			$qn = $class->{'prefixes'}->{ ($1) ? $1 : '#default' } . $2 ;
		} else {
			error $class,"Unsupported function call $1:$2";
			};

		if( MatchAndEat $class,'(' ) {

			ArgList $class;

			error $class,"missing right round bracket"
				unless( MatchAndEat $class,')' );

			if( $class->{'context'}->[ $#{ $class->{'context'} } ] eq 'order by' ) {
                		push @{ $class->{'order_by'} }, ( '&', $qn );
                	} else {
				push @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }, ( '&', $qn );
                       		};
			};

		return 1;
	} else {
		return 0;
                };
	};

sub ArgList($) {
	my($class) = @_;

	if( Var $class or URIOrQName $class or Literal $class ) {
		my $true=1;
		while( $true ) {
			if( MatchAndEat $class,',' ) {

				unless( Var $class or URIOrQName $class or Literal $class ) {
					$true=0;

				};
			} else {
				$true=0;
			};
		};
	};
};

# see SPARQL spec http://www.w3.org/TR/rdf-sparql-query/ - generally it can be SELECT, CONSTRUCT, DESCRIBE or ASK
sub getQueryType {
	my($class) = @_;

	return $class->{'queryType'};
	};

sub serialize {
	my($class, $fh, $syntax) = @_;

	if(	(! $syntax ) ||
                ( $syntax =~ m/N-Triples/i) ) {
		# not yet supported ?
                return
			if($#{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{constraints} }>=0);
		foreach my $tp ( @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{triplePatterns} } ) {
			return
				if( ($#{$tp}==3) || #Quads not there yet
			            (     ($tp->[2] =~ m/^%/) && #my free-text extensions
                                          ($tp->[2] =~ m/%$/) ) );
			};

		# convert
		my @nt;
		foreach my $tp ( @{ $class->{'graphPatterns'}->[$class->{'graph_patterns_pointer'}->[$#{$class->{'graph_patterns_pointer'}}]]->{triplePatterns} } ) {
			my @tp;
			map {
				my $ff = $class->{'query_string'};
				$ff =~ s/^[\?\$](.+)$/_:$1/;
				$ff =~ s/[\$:]/-/g;
				if(	($ff =~ m/^<(([^\:]+)\:{1,2}([^>]+))>$/) &&
					(defined $2) &&
					(exists $class->{prefixes}->{$2}) ) {
					push @tp, '<'.$class->{prefixes}->{$2}.$3.'>';
				} else {
					push @tp, $ff;
					};
			} @{$tp};
			push @tp, '.';
			push @nt, join(' ',@tp);
			};
		if($fh) {
			print $fh join("\n",@nt);
			return 1;
		} else {
			return join("\n",@nt);
			};
        } else {
                croak "Unknown serialization syntax '$syntax'";
                };
	};

sub DESTROY {
	my($class) = @_;

};

1;
};

__END__

=head1 NAME

RDQL::Parser - A simple top-down LL(1) RDQL and SPARQL parser

=head1 SYNOPSIS

	use RDQL::Parser;
	my $parser = RDQL::Parser->new();
	my $query = <<QUERY;

	PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
	PREFIX rss: <http://purl.org/rss/1.0/>
        SELECT
           ?title ?link
        FROM
           <http://xmlhack.com/rss10.php>
        WHERE
	   (?item, rdf:type <rss:item>)
	   (?item, rss:title, ?title)
	   (?item, rss:link ?link)

        QUERY;

        $parser->parse($query); #parse the query

	# I.e.
	$parser = bless( {
                 'distinct' => 0,
                 'constructPatterns' => [],
                 'prefixes' => {
                                 'fn' => 'http://www.w3.org/2004/07/xpath-functions',
                                 'op' => 'http://www.w3.org/2001/sw/DataAccess/operations',
                                 'owl' => 'http://www.w3.org/2002/07/owl#',
                                 'dcq' => 'http://purl.org/dc/terms/',
                                 'dc' => 'http://purl.org/dc/elements/1.1/',
                                 'foaf' => 'http://xmlns.com/foaf/0.1/',
                                 'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
                                 'rss' => 'http://purl.org/rss/1.0/',
                                 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
                                 'xsd' => 'http://www.w3.org/2001/XMLSchema#',
                                 'daml' => 'http://www.daml.org/2001/03/daml+oil#'
                               },
                 'graphPatterns' => [
                                      {
                                        'constraints' => [],
                                        'optional' => 0,
                                        'triplePatterns' => [
                                                              [
                                                                0,
                                                                '?item',
                                                                '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>',
                                                                '<rss:item>'
                                                              ],
                                                              [
                                                                0,
                                                                '?item',
                                                                '<http://purl.org/rss/1.0/title>',
                                                                '?title'
                                                              ],
                                                              [
                                                                0,
                                                                '?item',
                                                                '<http://purl.org/rss/1.0/link>',
                                                                '?link'
                                                              ]
                                                            ]
                                      }
                                    ],
                 'sources' => [
                                '<http://xmlhack.com/rss10.php>'
                              ],
                 'describes' => [],
                 'queryType' => 'SELECT',
                 'resultVars' => [
                                   '?title',
                                   '?link'
                                 ],
               }, 'RDQL::Parser' );

	$parser->serialize(*STDOUT, 'N-Triples'); #print on STDOUT the RDQL query as N-Triples if possible (or an error)

=head1 DESCRIPTION

 RDQL::Parser - A simple top-down LL(1) RDQL and SPARQL parser - see http://www.w3.org/TR/rdf-sparql-query/ and http://www.w3.org/Submission/2004/SUBM-RDQL-20040109/

=head1 CONSTRUCTORS

=item $parser = new RDQL::Parser;

=head1 METHODS

=item parse( PARSER, QUERY )

 If use Data::Dumper(3) to actually dumpo out the content of the PARSER variable after invoching the parse() method it lokks like:

 $VAR1 = bless( {
                 'distinct' => 0,
                 'constructPatterns' => [],
                 'prefixes' => {
                                 'fn' => 'http://www.w3.org/2004/07/xpath-functions',
                                 'op' => 'http://www.w3.org/2001/sw/DataAccess/operations',
                                 'owl' => 'http://www.w3.org/2002/07/owl#',
                                 'dcq' => 'http://purl.org/dc/terms/',
                                 'dc' => 'http://purl.org/dc/elements/1.1/',
                                 'foaf' => 'http://xmlns.com/foaf/0.1/',
                                 'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
                                 'rss' => 'http://purl.org/rss/1.0/',
                                 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
                                 'xsd' => 'http://www.w3.org/2001/XMLSchema#',
                                 'daml' => 'http://www.daml.org/2001/03/daml+oil#'
                               },
                 'graphPatterns' => [
                                      {
                                        'constraints' => [],
                                        'optional' => 0,
                                        'triplePatterns' => [
                                                              [
                                                                0,
                                                                '?item',
                                                                '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>',
                                                                '<rss:item>'
                                                              ],
                                                              [
                                                                0,
                                                                '?item',
                                                                '<http://purl.org/rss/1.0/title>',
                                                                '?title'
                                                              ],
                                                              [
                                                                0,
                                                                '?item',
                                                                '<http://purl.org/rss/1.0/link>',
                                                                '?link'
                                                              ]
                                                            ]
                                      }
                                    ],
                 'sources' => [
                                '<http://xmlhack.com/rss10.php>'
                              ],
                 'describes' => [],
                 'queryType' => 'SELECT',
                 'resultVars' => [
                                   '?title',
                                   '?link'
                                 ],
               }, 'RDQL::Parser' );

=head1 NOTES

	The RDQL implementation is actually an extension of the original RDQL spec (http://www.w3.org/Submission/2004/SUBM-RDQL-20040109/)
	to allow more SQL-like Data Manipulation Language (DML) features like DELETE and INSERT - which is much more close to the original rdfdb
	query language which SquishQL/RDQL are inspired to (see http://www.guha.com/rdfdb).
	
	As well as the SPARQL one....?

=head1 SEE ALSO

DBD::RDFStore(3)

http://www.w3.org/TR/rdf-sparql-query/
http://www.w3.org/Submission/2004/SUBM-RDQL-20040109/
http://ilrt.org/discovery/2002/04/query/
http://www.hpl.hp.com/semweb/doc/tutorial/RDQL/
http://rdfstore.sourceforge.net/documentation/papers/HPL-2002-110.pdf

=head1 FAQ

=item I<What's the difference between RDQL and SquishQL?>

=item None :-) The former is a bit of an extension of the original SquishQL proposal defining a proper BNF to the query language; the only practical difference is that triple patterns in the WHERE clause are expressed in a different order s,p,o for RDQL while SquishQL uses '(p s o)' without commas. In addition the URIs are expressed with angle brackets on RDQL while SquishQL do not. For more about differences between the two languages see http://rdfstore.sourceforge.net/documentation/papers/HPL-2002-110.pdf

=item I<Is RDQL::Parser compliant to RDQL BNF?>

=item Yes

=item I<Is RDQL::Parser compliant to SquishQL syntax ?>

=item Not yet :)

=item I<What are RDQL::Parser extensions to RDQL BNF?>

=item RDQL::Parser leverage on RDFStore(3) to run proper free-text UTF-8 queries over literals; the two main extensions are

=item * LIKE operator in AND clause

=item * free-text triple matching like (?x, ?y, %"whatever"%)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
	Andy Seaborne <andy_seaborne@hp.com> is the original author of RDQL
	Libby Miller <libby.miller@bristol.ac.uk> is the original author of SquishQL
