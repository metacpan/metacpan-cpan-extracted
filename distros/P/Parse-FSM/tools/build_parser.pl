#!perl
# $Id: build_parser.pl,v 1.1 2011/04/16 20:20:46 Paulo Exp $

#------------------------------------------------------------------------------
# Create Parse::FSM::Parse to parse a yacc-like grammar
#------------------------------------------------------------------------------

use strict;
use warnings;

use Parse::FSM;
use File::Slurp;
use File::Basename;

@ARGV == 2 or die "Usage: ",basename($0)," MODULE FILE\n";
my($module, $file) = @ARGV; 

my $fsm = Parse::FSM->new;

#------------------------------------------------------------------------------
# prolog
$fsm->prolog(q{
use Data::Dump 'dump';
use Text::Balanced 'extract_quotelike', 'extract_codeblock';

my $uid = 1;

});

#------------------------------------------------------------------------------
# epilog
$fsm->epilog(q{
# access the FSM object
sub fsm { return shift->user->{fsm} }

# read the given input string
sub from {
	my($self, $line) = @_;
	
	$self->input(sub {
		for ($line) {
			/\G(?:\s+|#.*)+/gc;		# skip blanks and comments
			
			/\G([a-z]\w*)/gci and do {
				return [NAME => $1];
			};
			/\G(?=["'])/gc and do {
				my $start_pos = pos();
				my($quoted_string, $rest) = extract_quotelike($_);
				if (defined $quoted_string) {
					my $token = eval($quoted_string); ## no critic
					if (! $@) {
						pos() = length() - length($rest);
						return [TOKEN => $token];
					}
				}
				
				# could not parse quoted string, die
				$rest = substr($_, $start_pos, 100);
				die "Cannot parse quoted string at ", dump($rest), "\n";
			};
			/\G(?=[\{])/gc and do {
				my $start_pos = pos();
				my($code_block, $rest) = extract_codeblock($_);
				if (defined $code_block) {
					pos() = length() - length($rest);
					return [CODE => $code_block];
				}
				
				# could not parse quoted string, die
				$rest = substr($_, $start_pos, 100);
				die "Cannot parse code block at ", dump($rest), "\n";
			};
			/\G(%\w+)/gc and do {					# directives
				return [$1 => $1];
			};
			/\G(<\+)\s*([^>\s]+)\s*>/gc and do {	# list quantifier
				return [$1 => $2];					# ['<+' => ',']
			};
			/\G(<\w+)/gc and do {					# directive
				return [$1 => $1];					# ['<start' => '<start']
			};
			/\G(.)/gc and do {
				return [$1 => $1];
			};
			return;	# end of input
		}
	});
	return;
}

});

#------------------------------------------------------------------------------
# program : list of rules
$fsm->add_rule('program', '[prolog]?', '[statement]+', '[epilog]?', '', '{}');

# prolog
$fsm->add_rule('prolog', '[code_unbraced]', q{{
				my $code = $item[0];
				$self->fsm->prolog($code);
				return;
			}});
				
# epilog
$fsm->add_rule('epilog', '[code_unbraced]', q{{
				my $code = $item[0];
				$self->fsm->epilog($code);
				return;
			}});
				
# code section with braces removed
$fsm->add_rule('code_unbraced', '[code]', q{{
				my $code = $item[0];
				$code =~ s/\A\s*\{//;	# remove start ...
				$code =~ s/\}\s*\z//;	# ... and end braces
				return $code;
			}});

# statement : rule | directive ;
$fsm->add_rule('statement', '[rule]', '{}');
$fsm->add_rule('statement', '[directive]', '{}');

# rule : name sentence<+|> ';'
$fsm->add_rule('rule', '[name]', ':', '[sentence]<+|>', ';', q{{
				my $name = $item[0];
				my $sentences = $item[2];
				for my $sentence (@$sentences) {
					$self->fsm->add_rule($name, @$sentence);
				}
				return;
			}});

# sentence : element+ action
$fsm->add_rule('sentence', '[element]+', '[action]', q{{
				my $elements = $item[0];
				my $action   = $item[1];
				return [@$elements, $action];
			}});

# element : token | subrule | <eof> | <leftop> | <rightop>
$fsm->add_rule('element', '[token]',			'{ return $item[0] }');
$fsm->add_rule('element', '[subrule]',			'{ return $item[0] }');
$fsm->add_rule('element', '<eof', '>',			'{ return ""       }');

# <list> separated by tokens
$fsm->add_rule('element', '<list', ':', 
					'[subrule_name]', '[token]', '[subrule_name]', '>',
			q{{
				my $operand1  = $item[2];
				my $operator  = $item[3];
				my $operand2  = $item[4];
				my $name      = "_anon".($uid++);
				my $name_opt  = "_anon".($uid++);
				
				# create rule for repetion of (operator operand2)
				$self->fsm->add_rule($name_opt, 
									$operator, "[$operand2]",
									'{return [$item[0][0], $item[1]]}');
				
				# create rule for : operand1 (opt_rule)*
				$self->fsm->add_rule($name, 
									"[$operand1]", "[$name_opt]*",
									q{{
										my @ret = ($item[0]);
										for (@{$item[1]}) {
											push @ret, @$_;
										}
										return \@ret;
									}});
				
				# return rule name
				return "[$name]";
			}});

# <list> separated by rules
$fsm->add_rule('element', '<list', ':', 
					'[subrule_name]', '[subrule_name]', '[subrule_name]', '>',
			q{{
				my $operand1  = $item[2];
				my $operator  = $item[3];
				my $operand2  = $item[4];
				my $name      = "_anon".($uid++);
				my $name_opt  = "_anon".($uid++);
				
				# create rule for repetion of (operator operand2)
				$self->fsm->add_rule($name_opt, 
									"[$operator]", "[$operand2]",
									'{return [$item[0], $item[1]]}');
				
				# create rule for : operand1 (opt_rule)*
				$self->fsm->add_rule($name, 
									"[$operand1]", "[$name_opt]*",
									q{{
										my @ret = ($item[0]);
										for (@{$item[1]}) {
											push @ret, @$_;
										}
										return \@ret;
									}});
				
				# return rule name
				return "[$name]";
			}});

# subrule
$fsm->add_rule('subrule', '[subrule_name]', '[quantifier]?', q{{
				my $name  = $item[0];
				my $quant = $item[1];
				my $ret = "[$name]";
				$ret .= $quant->[0] if @$quant;
				return $ret;
			}});

# subrule name : either name or () surrounded anonymous rule
$fsm->add_rule('subrule_name', '[name]', '{ return $item[0] }');
$fsm->add_rule('subrule_name', '(', '[sentence]<+|>', ')', q{{
				my $name = "_anon".($uid++);
				my $sentences = $item[1];
				for my $sentence (@$sentences) {
					$self->fsm->add_rule($name, @$sentence);
				}
				return $name;
			}});

# quantifier
$fsm->add_rule('quantifier', '?',  '{return $item[0][1]}');
$fsm->add_rule('quantifier', '*',  '{return $item[0][1]}');
$fsm->add_rule('quantifier', '+',  '{return $item[0][1]}');
$fsm->add_rule('quantifier', '<+', '{return "<+$item[0][1]>"}');

# action
$fsm->add_rule('action', '[code]?',	q{{
				if (@{$item[0]}) {			# code block supplied
					return $item[0][0];		
				}
				else {						# default action
					return q{{
								if (@item == 1) {	# special case: one element
									return $item[0];	# drop one array level
								}
								else {
									return \@item;
								}
							}};
				}
			}});

# directive
$fsm->add_rule('directive', '<start', ':', '[name]', '>', q{{
				my $name = $item[2];
				$self->fsm->start_rule($name);
				return;
			}});

# terminals
$fsm->add_rule('name', 		'NAME', 	'{ return $item[0][1] }');
$fsm->add_rule('token',		'TOKEN',	'{ return $item[0][1] }');
$fsm->add_rule('code',		'CODE',		'{ return $item[0][1] }');

#------------------------------------------------------------------------------
# write_module
$fsm->write_module($module, $file, 'hidden_module');
