# $Id: FSM.pm,v 1.10 2013/07/27 00:34:39 Paulo Exp $

package Parse::FSM;

#------------------------------------------------------------------------------

=head1 NAME

Parse::FSM - Deterministic top-down parser based on a Finite State Machine

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

use Carp; our @CARP_NOT = ('Parse::FSM');
use Data::Dump 'dump';
use Text::Template 'fill_in_string';
use File::Slurp;

our $VERSION = '1.13';

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use Parse::FSM;
  $fsm = Parse::FSM->new;
  
  $fsm->prolog($text);
  $fsm->epilog($text);
  $fsm->add_rule($name, @elems, $action);
  $fsm->start_rule($name);
  
  $fsm->parse_grammar($text);

  $fsm->write_module($module);
  $fsm->write_module($module, $file);
  
  $parser = $fsm->parser; # isa Parse::FSM::Driver
  $parser->input(\&lexer);
  $result = $parser->parse;
  
  # script
  perl -MParse::FSM - Grammar.yp Parser::Module
  perl -MParse::FSM - Grammar.yp Parser::Module lib\Parser\Module.pm

=head1 DESCRIPTION

This module compiles the Finite State Machine used by the
L<Parse::FSM::Driver|Parse::FSM::Driver> parser module.

It can be used by a sequence of C<add_rule> calls, or by parsing a yacc-like
grammar in one go with C<parse_grammar>.

It can be used as a script to generate a module from a grammar file.

The result of compiling the parser can be used immediately by retrieving the 
C<parser> object, or a pre-compiled module can be written to disk by
C<write_module>. This module can then be used by the client code of the parser.

As usual in top-down parsers, left recursion is not supported 
and generates an infinite loop. This parser is deterministic and does not implement backtracking.

=head1 METHODS - SETUP

=head2 new

Creates a new object.

=cut

#------------------------------------------------------------------------------
use Class::XSAccessor {
	constructor => '_init',
	accessors => [
		'_tree',		# parse tree
						# Contains nested HASH tables with the decision tree
						# used during parsing.
						# Each node maps:
						#	token      => next node / string with action code
						#	[subrule]  => next node / string with action code
						#	[subrule]? => next node / string with action code
						#	[subrule]* => next node / string with action code
						#	__else__   => next node / string with action code
						# The first level are the rule names.

		'_state_table',	# ARRAY that maps each state ID to the corresponding
						# HASH table from tree.
						# Copied to the generated parser module.
		
		'_action',		# map func text => [ sub name, sub text ]
		
		'start_rule',	# name start rule
		'prolog',		# code to include near the beginning of the file
		'epilog',		# code to include at the end of the file
		'_names',		# keep all generated names up to now, to be able to 
						# create unique ones
	],
};

#------------------------------------------------------------------------------
sub new {
	my($class) = @_;
	return $class->_init(_tree => {}, _state_table => [], _action => {},
						 _names => {});
}

#------------------------------------------------------------------------------
# create a new unique name (for actions, sub-rules)
sub _unique_name {
	my($self, $name) = @_;
	my $id = 1;
	while (exists $self->_names->{$name.$id}) {
		$id++;
	}
	$self->_names->{$name.$id}++;
	return $name.$id;
}		

#------------------------------------------------------------------------------

=head1 METHODS - BUILD GRAMMAR

=head2 start_rule

Name of the grammar start rule. It defaults to the first rule added by C<add_rule>.

=head2 prolog, epilog

Perl code to include in the generated module near the start of the generated
module and near the end of it.

=head2 add_rule

Adds one rule to the parser. 

  $fsm->add_rule($name, @elems, $action);

C<$name> is the name of the rule, i.e. the syntactic object recognized
by the rule. 

C<@elems> is the list of elements in sequence needed to recognize this rule.
Each element can be one of:

=over 4

=item *

A string that will match with that token type from the lexer. 

The empty string is used to match the end of input and should 
be present in the grammar to force the parser 
to accept all the input;

=item *

An array reference of a list of all possible tokens to accept at this position.

=item *

A subrule name inside square brackets, optionally followed by a 
repetition character that asks the parser to recursively descend 
to match that subrule at the current input location.

The accepted forms are:

C<[term]> - recurse to the term rule;

C<[term]?> - term is optional;

C<[term]*> - accept zero or more terms;

C<[term]+> - accept one or more terms;

C<[term]E<lt>+,E<gt>> - accept one or more terms separated by commas, 
any token type can be used instead of the comma;

=back

C<$action> is the Perl text of the action executed when the rule is recognized,
i.e. all elements were found in sequence. 

It has to be enclosed in brackets C<{}>, and can use the following lexical 
variables that are declared by the generated code:

=over 4

=item *

C<$self> : object pointer;

=item *

C<@item> : values of all the tokens or rules identified in this rule. The subrule
call with repetitions return an array reference containing all the found items
in the subrule;

=back

=cut

#------------------------------------------------------------------------------
# add_rule
# Args:
#	rule name
#	list of : 	'[rule]' '[rule]*' '[rule]?' '[rule]+' '[rule]<+SEP>' 	# subrules
#				token													# tokens
#	action :	'{ CODE }'
sub add_rule {
	my($self, $rule_name, @elems) = @_;
	my $action = pop(@elems);

	@elems or croak "missing arguments";
	$rule_name =~ /^\w+$/ or croak "invalid rule name ".dump($rule_name);
	
	# check for array-ref @elem and recurse for all alternatives
	for my $i (0 .. $#elems) {
		if (ref($elems[$i])) {		# isa 'ARRAY', others cause run-time error
			for (@{$elems[$i]}) {
				$self->add_rule($rule_name, 
								@elems[0 .. $i-1], $_, @elems[$i+1 .. $#elems],
								$action);
			}
			return;
		}
	}
	
	$self->_check_start_rule($rule_name);

	# load the tree
	my $tree = $self->_tree;
	$tree = $self->_add_tree_node($tree, $rule_name);	# load rule name
	
	my $comment = "$rule_name :";
	
	while (@elems) {
		my $elem = shift @elems;
		
		# handle subrule calls with quantifiers
		# check if recursing for _add_list_rule
		if ($rule_name !~ /^_lst_/ &&
			$elem =~ /^ \[ .* \] /x) {
			$elem = $self->_add_list_rule($elem);
		}
		
		$tree->{__comment__} = $comment;		# way up to this state
		
		$comment .= " ".($elem =~ /^\[/ ? $elem : dump($elem));
		
		if (@elems) {				# not a leaf node
			croak "leaf and node at ($comment)" 
				if (exists($tree->{$elem}) && ref($tree->{$elem}) ne 'HASH');
			$tree = $self->_add_tree_node($tree, $elem);	# load token
		}
		else {						# leaf node
			croak "leaf not unique at ($comment)"
				if (exists($tree->{$elem}));
			$self->_add_tree_node($tree, $elem);			# create node
			$tree->{$elem} = $self->_add_action($action, $rule_name, $comment);
		}
	}
	
	return;
}

#------------------------------------------------------------------------------
# add a list subrule, get passed a string '[subrule]*'
sub _add_list_rule {
	my($self, $elem) = @_; 
	
	$elem =~ /^ \[ (\w+) \] ( [?*+] | <\+.*> )? $/x
		or croak "invalid subrule call $elem";
	my($subrule, $quant) = ($1, $2);
	
	return "[$subrule]" unless $quant;		# subrule without quatifier
	
	# create a list subrule, so that the result of the repetition is returned
	# as an array reference
	my $list_subrule = $self->_unique_name("_lst_".$subrule);
	
	if ($quant eq '*' || $quant eq '?') {
		$self->add_rule($list_subrule, "[$subrule]$quant", 
						 '{ return \@item }');
	}
	elsif ($quant eq '+') {					# A+ -> A A*
		$self->add_rule($list_subrule, "[$subrule]", "[$subrule]*", 
						 '{ return \@item }');
	}
	elsif ($quant =~ /^< \+ (.*) >$/x) {	# A<+;> -> A Ac* ; Ac : ';' A
		my $separator = $1;
		my $list_subrule_cont = $self->_unique_name("_lst_".$subrule);
		
		# Ac : ';' A
		$self->add_rule($list_subrule_cont, $separator, "[$subrule]",
						 '{ return $item[1] }');
						 
		# A Ac*
		$self->add_rule($list_subrule, "[$subrule]", "[$list_subrule_cont]*",
						 '{ return \@item }');
	}
	else {
		die; # not reached
	}
	
	return "[$list_subrule]";
}

#------------------------------------------------------------------------------
# add a tree node and create a new state
sub _add_tree_node {
	my($self, $tree, $elem) = @_;
	
	$tree->{$elem} ||= {};
	
	# new state?
	if (! exists $tree->{__state__}) {
		my $id = scalar(@{$self->_state_table});
		$tree->{__state__} = $id;
		$self->_state_table->[$id] = $tree;
	}
	
	return $tree->{$elem};
}

#------------------------------------------------------------------------------
# define start rule, except if starting with '_' (internal)
sub _check_start_rule {
	my($self, $rule_name) = @_;
	
	if (! defined $self->start_rule && $rule_name =~ /^[a-z]/i) {
		$self->start_rule($rule_name);	# start rule is first defined rule
	}
	
	return;
}

#------------------------------------------------------------------------------
# _add_action()
#	Create a new action or re-use an existing one. An action has to start by 
#	'{'; a new name is created and a reference to the name is 
#	returned : "\&_action_RULE"
sub _add_action {
	my($self, $action, $rule_name, $comment) = @_;
	
	# remove braces
	$action =~ s/ \A \s* \{ \s* (.*?) \s* \} \s* \z /$1/xs 
		or croak "action must be enclosed in {}";

	# reuse an existing action, if any
	(my $cannon_action = $action) =~ s/\s+//g;
	if (!$self->_action->{$cannon_action}) {
		my $action_name = $self->_unique_name("_act_".$rule_name);

		# reduce indentation
		for ($action) {
			my($lead_space) = /^(\t+)/m;
			$lead_space and s/^$lead_space/\t/gm;
		}

		$action = 
			"# $comment\n".
			"sub $action_name {".
			($action ne '' ? "\n\tmy(\$self, \@item) = \@_;\n\t" : "").
			$action.
			"\n}\n\n";

		$self->_action->{$cannon_action} = [ $action_name, $action ];
	}
	else {
		# append this comment
		$self->_action->{$cannon_action}[1] =~ s/^(sub)/# $comment\n$1/m;
	}
	
	return "\\&".$self->_action->{$cannon_action}[0];
}	

#------------------------------------------------------------------------------
# compute the FSM machine
#
# expand [rule] calls into start_set(rule) => [ rule_id, next_state ]
#	Search for all sub-rule calls, and add each of the first tokens of the subrule
#	to the call. Repeat until no more rules added, to cope with follow sets being
# 	computed after being looked up
# creates FSM loops for the constructs:
#	A -> B?
# 	A -> B*
sub _compute_fsm {
	my($self) = @_;

	# repeat until no more follow tokens added
	# Example : A B[?*] C
	my $changed;
	do {
		$changed = 0;
		
		# check all states in turn
		for my $state (@{$self->_state_table}) {
			my %state_copy = %$state;
			while (my($token, $next_state) = each %state_copy) {
				next unless my($subrule_name, $quant) = 
						$token =~ /^ \[ (.*) \] ( [?*] )? $/x;

				my $next_state_text = ref($next_state) eq 'HASH' ? 
											$next_state->{__state__} : 
											$next_state;
				
				my $subrule = $self->_tree->{$subrule_name} 
					or croak "rule $subrule_name not found";
				ref($subrule) eq 'HASH' or die;
				
				# call subrule on each of the subrule follow set
				# Example : add all 'follow(B) -> call B' to current rule
				for my $subrule_key (keys %$subrule) {
					next if $subrule_key =~ /^(__(comment|state)__|\[.*\][?*]?)$/;
					my $text = "[ ".$subrule->{__state__}.", ".
									(($quant||"") eq '*' ? 
											$state->{__state__} :	# loop on a '*'
											$next_state_text	# else, next state
									)." ]";
					if ($state->{$subrule_key}) {
						die if $state->{$subrule_key} ne $text;
					}
					else {
						$state->{$subrule_key} = $text;								
						$changed++;
					}
				}
				
				# call next rule on the next rule follow set
				# Example : add all 'follow(C) -> end' to end current rule
				if (defined($quant)) {
					if ($state->{__else__}) {
						die if $state->{__else__} ne $next_state_text;
					}
					else {
						$state->{__else__} = $next_state_text;
						$changed++;
					}
				}
			}		
		}
	} while ($changed);
	
	return;
}

#------------------------------------------------------------------------------

=head2 parse_grammar

Parses the given grammar text and adds to the parser. Example grammar follows:

  {
    # prolog
    use MyLibrary;
  }
  
  main   : (number | name)+ <eof> ;
  number : 'NUMBER' { $item[0][1] } ; # comment
  name   : 'NAME'   { $item[0][1] } ; # comment
  
  expr   : <list:    number '+' number > ;
  
  <start: main >
  
  {
    # epilog
    sub util_method {...}
  }

=over 4

=item prolog

If the text contains a code block surrounded by braces before the first rule
definition, the text is copied without the external braces to the prolog
of generated module.

=item epilog

If the text contains a code block surrounded by braces after the last rule
definition, the text is copied without the external braces to the epilog
of generated module.

=item statements

Statements are either rule definitions of directives and end with a 
semi-colon C<;>. Comments are as in Perl, from a hash C<#> sign to 
the end of the line.

=item rule

A rule defines one sentence to match in the grammar. The first rule defined
is the default start rule, i.e. the rule parsed by default on the input.
A rule name must start with a letter and contain only letters,
digits and the underscore character.

The rule definition follows after a colon and is composed of a sequence 
of tokens (quoted strings) and sub-rules, to match in sequence. The rule matches 
when all the tokens and sub-rules in the definition match in sequence.

The top level rule should end with C<E<lt>eofE<gt>> to make sure all input
is parsed.

The rule can define several alternative definitions separated by '|'.

The rule definition finishes with a semi-colon ';'.

A rule can call an anonymous sub-rule enclosed in parentheses.

=item action

The last item in the rule definition is a text delimited by {} with the code
to execute when the rule is matched. The code can use $self to refer to the 
Parser object, and @item to refer to the values of each of the tokens and 
sub-rules matched. The return value from the code defines the value of the
rule, passed to the upper level rule, or returned as the parse result.

If no action is supplied, a default action returns an array reference with 
the result of all tokens and sub-rules of the matched sentence.

=item quantifiers

Every token or sub-rule can be followed by a repetition specification: 
'?' (zero or one), '*' (zero or more), '+' (one or more), 
or '<+,>' (comma-separated list, comma can be replaced by any token).

=item directives

Directives are written with angle brackets.

=over 4

=item <eof>

Can be used in a rule instead of the empty string to represent the end of input.

=item <list: RULE TOKEN RULE >

Shortcut for creating lists of operators separated by tokens, 
returns the list of rule and token values.

=item <start: START_RULE >

Defines the start rule of the grammar. By default the first
defined rule is the start rule; use C<E<lt>start:E<gt>> to override that.

=back

=back

=cut

#------------------------------------------------------------------------------
sub parse_grammar {
	my($self, $text) = @_;

	# need to postpone load of Parse::FSM::Parser, as Parse::FSM is used by
	# the script that creates Parse::FSM::Parser
	eval 'use Parse::FSM::Parser'; $@ and die; ## no critic
	
	my $parser = Parse::FSM::Parser->new;
	$parser->user->{fsm} = $self;
	eval {
		$parser->from($text);			# setup lexer
		$parser->parse;
	};
	$@ and do { $@ =~ s/\s+\z//; croak $@; };
	
	return;
}

#------------------------------------------------------------------------------

=head1 METHODS - USE PARSER

=head2 parser

Computes the Finite State Machine to execute the parser and returns a 
L<Parse::FSM::Driver|Parse::FSM::Driver> object that implements the parser.

Useful to build the parser and execute it in the same
program, but with the run-time penalty of the time to setup the state tables.

=cut

#------------------------------------------------------------------------------
sub parser {
	my($self) = @_;
	our $name ||= 'Parser00000'; $name++;		# new module on each call
	
	my $text = $self->_module_text($name, "-");
	eval $text;		## no critic
	$@ and die $@;

	my $parser = $name->new;
	
	return $parser;
}
#------------------------------------------------------------------------------

=head2 write_module

Receives as input the module name and the output file name
and writes the parser module. 

The file name is optional; if not supplied is computed from the 
module name by replacing C<::> by C</> and appending C<.pm>, 
e.g. C<Parse/Module.pm>.

The generated code includes C<parse_XXX> functions for every rule 
C<XXX> found in the grammar, as a short-cut for calling C<parse('XXX')>.

=cut

#------------------------------------------------------------------------------
sub write_module {
	my($self, $name, $file) = @_;
	
	$name or croak "name not defined";

	# build file name from module name
	unless (defined $file) {
		$file = $name;
		$file =~ s/::/\//g;
		$file .= ".pm";
	}
	
	my $text = $self->_module_text($name, $file);
	write_file($file, {atomic => 1}, $text);

	return;
}

#------------------------------------------------------------------------------
# template code for grammmar parser
my $TEMPLATE = <<'END_TEMPLATE';
# $Id: FSM.pm,v 1.10 2013/07/27 00:34:39 Paulo Exp $
# Parser generated by Parse::FSM

package # hide from CPAN indexer
  <% $name %>;

use strict;
use warnings;

use Parse::FSM::Driver; our @ISA = ('Parse::FSM::Driver');

<% $prolog %>

<% $table %>

sub new {
	my($class, %args) = @_;
	return $class->SUPER::new(
				_state_table	=> \@state_table,
				_start_state	=> $start_state,
				%args,
	);
}

<% $epilog %>

1;
END_TEMPLATE

#------------------------------------------------------------------------------
# module text
sub _module_text {
	my($self, $name, $file) = @_;

	$name or croak "name not defined";
	$file or croak "file not defined";

	my $table = $self->_table_dump;
	
	my @template_args = (
		DELIMITERS 	=> [ '<%', '%>' ],
		HASH 		=> {
			prolog	=> $self->prolog || "",
			epilog	=> $self->epilog || "",
			name	=> $name,
			table	=> $table,
		},
	);
	return fill_in_string($TEMPLATE, @template_args);
}

#------------------------------------------------------------------------------
# dump the state table
sub _table_dump {
	my($self) = @_;

	$self->_compute_fsm;

	#print dump($self),"\n" if $ENV{DEBUG};

	my $start_state = 0;
	if (defined($self->start_rule) && exists($self->_tree->{$self->start_rule})) {
		$start_state = $self->_tree->{$self->start_rule}{__state__};
	}
	else {
		croak "start state not found";
	}
	
	my $ret = 'my $start_state = '.$start_state.";\n".
			  'my @state_table = ('."\n";
	my $width;
	for my $i (0 .. $#{$self->_state_table}) {
		$ret .= "\t# [$i] " . 
				($self->_state_table->[$i]{__comment__} || "") . 
				"\n" .
				"\t{ "; 
		$width = 2;
		
		for my $key (sort keys %{$self->_state_table->[$i]}) {
			next if $key =~ /^(__(comment|state)__|\[.*\][?*]?)$/;
			
			my $value = $self->_state_table->[$i]{$key};
			$value = $value->{__state__} if ref($value) eq 'HASH';
			
			my $key_text = ($key =~ /^\w+$/) ? $key : dump($key);
			
			my $item_text = "$key_text => $value, ";
			if (($width += length($item_text)) > 72) {
				$ret .= "\n\t  ";
				$width = 2 + length($item_text);
			}			
			$ret .= $item_text;
		}
		
		$ret .= "},\n\n";
	}
	$ret .= ");\n\n";
	
	# dump action
	for (sort {$a->[0] cmp $b->[0]} values %{$self->_action}) {
		$ret .= $_->[1];
	}
	
	# dump parse_XXX functions
	my $length = 1;
	while (my($name, $rule) = each %{$self->_tree}) {
		next unless $name =~ /^[a-z]/i;
		$length = length($name) if length($name) > $length;
	}
	while (my($name, $rule) = each %{$self->_tree}) {
		next unless $name =~ /^[a-z]/i;
		$ret .= 
			"sub parse_$name". 
			(" " x ($length - length($name))).
			" { return shift->_parse($rule->{__state__}) }\n";
	}
		
	return $ret;
}

#------------------------------------------------------------------------------

=head1 PRE-COMPILING THE GRAMMAR

The setup of the parsing tables and creating the parsing module may take up
considerable time. Therefore it is useful to separate the parser generation 
phase from the parsing phase.

=head2 precompile

A parser module can be created from a yacc-like grammar file by the 
following command. The generated file (last parameter) is optional; if not
supplied is computed from the module name by replacing C<::> by C</> and
appending C<.pm>, e.g. C<Parse/Module.pm>:

  perl -MParse::FSM - Grammar.yp Parser::Module
  perl -MParse::FSM - Grammar.yp Parser::Module lib\Parser\Module.pm

This is equivalent to the following Perl program:

  #!perl
  use Parse::FSM;
  Parse::FSM->precompile(@ARGV);

The class method C<precompile> receives as arguments the grammar file, the 
generated module name and an optional file name, and creates the parsing module.

=cut

#------------------------------------------------------------------------------
sub precompile {
	my($class, $grammar, $module, $file) = @_;

	my $self = $class->new;
	my $text = read_file($grammar);
	$self->parse_grammar($text);
	$self->write_module($module, $file);
	
	return;
}

#------------------------------------------------------------------------------
# startup code for pre-compiler
# borrowed from Parse::RecDescent
sub import {
    local *_die = sub { warn @_, "\n"; exit 1; };

    my($package, $file, $line) = caller;
    if (substr($file,0,1) eq '-' && $line == 0) {
        _die("Usage: perl -MParse::FSM - GRAMMAR MODULE::NAME [MODULE/NAME.pm]")
            unless @ARGV == 2 || @ARGV == 3;

        my($grammar, $module, $file) = @ARGV;
		eval {
			Parse::FSM->precompile($grammar, $module, $file);
		};
		$@ and _die($@);

		exit 0;
	}
	
	return;
}

#------------------------------------------------------------------------------


=head1 AUTHOR

Paulo Custodio, C<< <pscust at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Calling pre-compiler on C<import> 
borrowed from L<Parse::RecDescent|Parse::RecDescent>.

=head1 BUGS and FEEDBACK

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-FSM>.  

=head1 LICENSE and COPYRIGHT

Copyright (C) 2010-2011 Paulo Custodio.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Parse::FSM
