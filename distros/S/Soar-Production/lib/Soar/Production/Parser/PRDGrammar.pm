#
# This file is part of Soar-Production
#
# This software is copyright (c) 2012 by Nathan Glenn.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Soar::Production::Parser::PRDGrammar;
# ABSTRACT: Parse::RecDescent grammar for Soar productions

use strict;
use warnings;

our $VERSION = '0.03'; # VERSION

#this grammar will return a parse tree of a production
our $GRAMMAR = <<'EOGRAMMAR';
	<nocheck>
	parse:
		<skip: qr{(?xs:
          (?: \s+						# Whitespace
          |   (?:;\s*)?\# [^\n]* \n?	# End of line comment
          )
		)*}> production /\Z/
		{
			$item[2]
		}
	#future work: can be sp or tp (normal or template production)
	production: /sp/ "{" beginning LHS "-->" RHS "}"
		{
			my %return;
			@return{ keys %{$item[3]}} = values %{$item[3]};
			$return{LHS} = $item{LHS};
			$return{RHS} = $item{RHS}->{rhsActions};
			\%return;
		}
	beginning: prodname documentation(?) flag(s?)
		{
			{name => $item[1], doc => $item[2] ? $item[2][0] : undef, flags => $item[3]}
		}
	prodname: /[\dA-Za-z][\dA-Za-z\$%&*=><?_\/\@:-]*/

	#documentation can span many lines
	documentation: '"' <commit> /[^"]*/ms '"'
		{
			$item[3]
		}
	flag: ':' <commit> /o-support|i-support|chunk|default|interrupt|template/
	LHS: cond(s)
		{
			{ conditions		=> $item[1] }
		}
	condType: "state" | "impasse"
	cond:
		positiveCond
		{
			{ negative => 'no', condition => $item{positiveCond} }
		}
		| negativeCond
		{
			{ negative => 'yes', condition => $item{negativeCond} }
		}
	negativeCond: "-" positiveCond
	positiveCond: condsForOneId
		{
			$item{condsForOneId};
		}
		| "{" <commit> cond(s) "}"
		{
			{ 'conjunction' => $item[3] }
		}
	condsForOneId: "(" <commit> condType(?) idTest(?) attrValueTests(s?) ")"
		#only a state_imp_cond can be missing an idTest or attrValueTests
		<reject: do {
			not defined $item[3] and (
				not defined $item[4] or $#{$item[5]} == -1
			)
		} >
		{
			{
				condType 	=> ($#{$item[3]} != -1 ? $item[3][0] : undef),
				idTest 		=> ($#{$item[4]} != -1 ? $item[4][0]->{test} : undef),
				attrValueTests =>	$item[5],
			}
		}
	idTest: test
		{
			{ test => $item{test} }
		}
	attrValueTests: /-?/ attTest valueTest(s?)
		{
			{
				negative 	=> ($item[1] ? 'yes' : 'no'),
				attrs 		=> $item[2],
				values		=> $item[3],
			}
		}
	attTest: "^" <commit> test(s /\./)
	valueTest: test /\+?/
		{
			{
				test 	=> $item{test},
				'+'		=> ($item[2] ? 'yes' : 'no'),
			}
		}
		| condsForOneId /\+?/
		{
			{
				conds	=> $item{condsForOneId},
				'+'		=> ($item[2] ? 'yes' : 'no'),
			}
		}
	test:
		conjunctiveTest
		{
			{ conjunctiveTest => $item{conjunctiveTest} }
		}
		| simpleTest
		{
			{ simpleTest => $item{simpleTest} }
		}
	conjunctiveTest: "\{" <commit> simpleTest(s) "\}"
		{
			$item[3]
		}
	simpleTest:
		disjunctionTest
		{
			{ disjunctionTest => $item{disjunctionTest} }
		}
		| relationalTest
		{
			{ relationTest => $item{relationalTest} }
		}
		| singleTest
		{
			$item{singleTest}
		}
	disjunctionTest: /<<(?=\s)/ <commit> constant(s) />>/ #don't have to worry about look for whitespace on second one; if no space is there, the parser will think it's a string and fail.
	{
		$item[3]
	}
	relationalTest: relation singleTest #note that I removed a (?) from relation, and added singleTest to simpleTest
		{
			{ relation => ($item{relation} || undef), test => $item{singleTest} }
		}
	# /<(?=\s)/ ensures we don't match the beginning of a variable
	relation:  "<=>" | "<>" | "<=" | ">=" | ">" | /<(?=\s)/ | "="

	singleTest:
		variable
		{
			$item{variable}
		}
		| constant
		{
			$item{constant}
		}

	#change skip so we can't have
	variable: /<[A-Za-z0-9\$%&*+\/:=?_<>-]+(?<!>)>/
		{
			$item[1] =~ s/^<(.*)>$/$1/;
			{variable => $item[1] }
		}

	RHS: rhsAction(s?)
		{
			{ rhsActions => $item[1] }
		}

	rhsAction:
		funcCall
		{
			{ funcCall => $item{funcCall} }
		}
		| "(" variable attrValueMake(s) ")"
		{
			{ variable => $item{variable}->{variable}, attrValueMake => $item[3] }
		}

	funcCall: "(" funcName <commit> rhsValue(s?) ")"
		{
			{ function => $item{funcName}, args => $item[4] }
		}
	funcName: "+" | "-" | "*" | "/" | symConstant
	rhsValue: variable | constant | "(crlf)" | funcCall
	attrValueMake: <leftop: attr "." variableOrSymConstant> valueMake(s)
		{
			{ attr => $item[1], valueMake => $item[2] }
		}
	attr: "^" <commit> variableOrSymConstant
	variableOrSymConstant: variable | symConstant
	valueMake: rhsValue preferenceSpecifier(s?)
		{
			#add an acceptable preference if no preference is specified
			my $preferences = $item[2];
			if($#$preferences == -1){
				$preferences = [{
                                  'value' => '+',
                                  'type' => 'unary'
                                }];
			}
			{ rhsValue => $item{rhsValue},  preferences => $preferences }
		}

	preferenceSpecifier:
		unaryOrBinaryPreference rhsValue comma(?)
		{
			{ type => 'binary', value => $item{unaryOrBinaryPreference}, compareTo => $item{rhsValue} }
		}
		| unaryPreference comma(?)
		{
			{ type => 'unary', value => $item{unaryPreference} };
		}

	comma: ","

	unaryPreference: "+" | "-" | "!" | "~" | "@" | unaryOrBinaryPreference

	#negative lookahead necessary to prevent matching <xx> as two specifiers and a constant
	unaryOrBinaryPreference: ">" | ...!variable  "<" | "=" | "&"

	#put float and int first, since symConstant can technically match the same values.
	constant:
		floatConstant
		{
			{ constant => $item{floatConstant}, type => 'float' }
		}
		| intConstant
		{
			{ constant => $item{intConstant}, type => 'int' }
		}
		| symConstant
		{
			{ constant => $item{symConstant}, type => 'sym' }
		}
	symConstant: string { $item{string} } | quoted { $item{quoted} }
	string: /[A-Za-z0-9\$%&*+\/:=?_><-]+/
		<reject: do{ $item[1] =~ /^<.*>$/} > #reject if we've actually found a variable
		<reject: do{
			$item[1] =~ /^ [+!~><=-]+ $/x and
			$item[1] !~ /^ (?: >< | [<>]{3,}) $/x

			}
		> #reject if the name contains only preference characters
		<defer: {
			# "<x" or "x>" look like typos. Could have missed a pointy brace.
			if( $item[1] =~ /^<.*|.*>$/ ){
				use Carp;
				carp "Suspicious string constant: \"$item[1]\". Did you mean to use a variable or disjunction?";
			}
		}>
		{
			# "<x" or "x>" look like typos. Could have missed a pointy brace. Convert to quoted like Soar does.
			if( $item[1] =~ /^<.*|.*>$/ ){
				$return = { type => 'quoted', value => $item[1] };
			}else{
				$return = { type => 'string', value => $item[1] };
			}
		}
	#TODO: note that in Soar, || is ignored and treated like <any>.
	quoted: /\|(?:\\[|]|[^|])*\|/
		{
			#remove leading and trailing vertical bar
			$item[1] =~ s{^\|}{};
			$item[1] =~ s{\|$}{};

			#unescape other vertical bars
			$item[1] =~ s{\\\|}{|}g;

			{ type => 'quoted', value => $item[1] }
		}
	intConstant: /-?[0-9]+/
	floatConstant:
		scientific { $item{scientific} }
		| normal { $item{normal} }

	#strangely enough, the section after the period is optional; '1.' is legal.
	normal: /^[-+]?[0-9]*\.[0-9]*/
	scientific: /[+-]?[0-9]\.[0-9]+[eE][-+]?[0-9]+/
EOGRAMMAR

1;

__END__

=pod

=head1 NAME

Soar::Production::Parser::PRDGrammar - Parse::RecDescent grammar for Soar productions

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Soar::Production::Parser::PRDGrammar;
  use Parse::RecDescent;

  my $some_text = 'Soar productions here';

  my $parser = Parse::RecDescent->new($Soar::Production::Parser::PRDGrammar::GRAMMAR);
  $parser->parse($some_text);

=head1 DESCRIPTION

This module holds one global string: a C<Parse::RecDescent>
grammar for parsing Soar productions. It is not really intended for public consumption,
but for use by modules L<Soar::Production> distribution.

=head1 NAME

Soar::Production::Parser::PRDGrammar - C<Parse::RecDescent> grammar for parsing Soar productions.

=head1 BNF Grammar from the Soar Manual

The following is a description of a grammar describing Soar productions, from the Soar manual.
Note also that a /(;\s*)?\#/ (pound sign optionally preceded by semi-colon and white space) indicates an end-of-line comment.
Soar does not have multi-line comments.

=head2 Grammar of Soar productions

A grammar for Soar productions is:

	<soar-production> ::= sp "{" <production-name> [<documentation>] [<flags>]
	<condition-side> --> <action-side> "}"
	<documentation> ::= """ [<string>] """
	<flags> ::= ":" (o-support | i-support | chunk | default)

=head3 Grammar for Condition Side

I have modified the grammar below from the original to account for the fact that an instance of <state-imp-cond> is not required to start the LHS, and may actually occur anywhere inside of it.

	Below is a grammar for the condition sides of productions:
	<condition-side> ::= <cond>+
	<cond> ::= <positive_cond> | "-" <positive_cond>
	<positive_cond> ::= <state-imp-cond> | <conds_for_one_id> | "{" <cond>+ "}"
	<state-imp-cond> ::= "(" (state | impasse) [<id_test>] <attr_value_tests>+ ")"
	<conds_for_one_id> ::= "(" [(state|impasse)] <id_test> <attr_value_tests>+ ")"
	<id_test> ::= <test>
	<attr_value_tests> ::= ["-"] "^" <attr_test> ("." <attr_test>)* <value_test>*
	<attr_test> ::= <test>
	<value_test> ::= <test> ["+"] | <conds_for_one_id> ["+"]
	<test> ::= <conjunctive_test> | <simple_test>
	<conjunctive_test> ::= "{" <simple_test>+ "}"
	<simple_test> ::= <disjunction_test> | <relational_test>
	<disjunction_test> ::= "<<" <constant>+ ">>"
	<relational_test> ::= [<relation>] <single_test>
	<relation> ::= "<>" | "<" | ">" | "<=" | ">=" | "=" | "<=>"
	<single_test> ::= <variable> | <constant>
	<variable> ::= "<" <sym_constant> ">"
	<constant> ::= <sym_constant> | <int_constant> | <float_constant>

=head4 Notes on the Condition Side

In an <id_test>, only a <variable> may be used in a <single_test>.

=head3 Grammar for Action Side

Below is a grammar for the action sides of productions:

	<rhs> ::= <rhs_action>*
	<rhs_action> ::= "(" <variable> <attr_value_make>+ ")" | <func_call>
	<func_call> ::= "(" <func_name> <rhs_value>* ")"
	<func_name> ::= <sym_constant> | "+" | "-" | "*" | "/"
	<rhs_value> ::= <constant> | <func_call> | <variable>
	<attr_value_make> ::= "^" <variable_or_sym_constant> ("." <variable_or_sym_constant>)* <value_make>+
	<variable_or_sym_constant> ::= <variable> | <sym_constant>
	<value_make> ::= <rhs_value> <preference_specifier>*
	<preference-specifier> ::= <unary-preference> [","]
		| <unary-or-binary-preference> [","]
		| <unary-or-binary-preference> <rhs_value> [","]
	<unary-pref> ::= "+" | "-" | "!" | "~" | "@"
	<unary-or-binary-pref> ::= ">" | "=" | "<" | "&"

=head1 CAVEATS

This grammar does not check for the semantic correctness of a production. For example, the following parses just fine:

	sp {foo
		(state)
	-->
		(<s> ^foo <a>)
	}
Whereas the real Soar parser gives us an error, saying that <lt>s<gt> is not connected to the LHS in any way.

=head1 BUGS

In Soar, numbers cannot be used to name
a working memory element unless they are quoted; this is a
L<known bug|https://code.google.com/p/soar/issues/detail?id=135>.
This grammar does not implement that specific bug/feature,
and thus the following is accepted, even though Soar would
reject it:

	sp {bad-numbers
		(state <s> ^string.2.string)
	-->
	}

=head1 SEE ALSO

The documentation for Soar is located at L<https://code.google.com/p/soar/>

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nathan Glenn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
