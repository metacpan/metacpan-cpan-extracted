# $Id: Lexer.pm,v 1.10 2013/07/27 00:34:39 Paulo Exp $

package Parse::FSM::Lexer;

#------------------------------------------------------------------------------

=head1 NAME

Parse::FSM::Lexer - Companion Lexer for the Parse::FSM parser

=cut

#------------------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use File::Spec;
use Data::Dump 'dump';
use Parse::FSM::Error;

our $VERSION = '1.13';

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use Parse::FSM::Lexer;
  $lex = Parse::FSM::Lexer->new;
  $lex = Parse::FSM::Lexer->new(@files);
  
  $lex->add_path(@dirs); @dirs = $lex->path;
  $full_path = $lex->path_search($file);

  $lex->from_file($filename);
  $lex->from_list(@input); 
  $lex->from_list(sub {});
  
  $lex->get_token;
  
  $lex->error($message); 
  $lex->warning($message); 
  $lex->file; 
  $lex->line_nr;
  
  # in a nearby piece of code
  use MyParser; # isa Parse::FSM::Driver;
  my $parser = MyParser->new;
  $parser->input(sub {$lex->get_token});
  eval {$parser->parse}; $@ and $lex->error($@);

=head1 DESCRIPTION

This module implements a generic tokenizer that can be used by
L<Parse::FSM|Parse::FSM> parsers, and can also be used standalone 
independently of the parser. 

It supports recursive file includes and takes track of current file name
and line number. It keeps the path of search directories to search for
input files.

The C<get_token> method can be called by the C<input> method of the parser
to retrieves the next input token to parse.

The module can be used directly if the supplied tokenizer is enough for the
application, but usually a derived class has to be written implementing a 
custom version of the  C<tokenizer> method.

=head1 METHODS - SETUP

=head2 new

Creates a new object. If an argument list is given, calls C<from_file>
for each of the file starting from the last, so that the files are 
read in the given order.

=cut

#------------------------------------------------------------------------------
use constant INPUT 			=> 0;	# input stream, code ref
use constant FILE			=> 1;	# name of the input file, undef for list
use constant LINE_NR		=> 2;	# current input line number
use constant LINE_INC 		=> 3;	# increment to next line number
use constant SAW_NL 		=> 4;	# true if saw a newline before
									# used to increment LINE_INC on next token
use constant TEXT 			=> 5;	# line text being lexed

use constant STACK 			=> 6;	# stack of previous contexts for recursive
									# includes, saves
									# [input, file, line_nr, line_inc, saw_nl, 
									#		 text, pos(text)]
use constant PATH			=> 7;	# path of search directories

# only limited accessors
use Class::XSAccessor::Array {
	accessors => {
		file		=> FILE, 
		line_nr		=> LINE_NR,
		line_inc	=> LINE_INC,
	}
};

#------------------------------------------------------------------------------
sub new {
	my($class, @files) = @_;
	my $self = bless [], $class;
	$self->[STACK] = [];
	$self->[PATH]  = [];
	$self->from_file($_) for reverse @files;
	return $self;
}

#------------------------------------------------------------------------------
# push context for include file
sub _push_context {
	my($self) = @_;
	push @{$self->[STACK]},
		 [ @{$self}[ 0 .. STACK - 1 ], pos($self->[TEXT]) ];
	return;
}

#------------------------------------------------------------------------------
# pop context
sub _pop_context {
	my($self) = @_;
	( @{$self}[ 0 .. STACK - 1 ], pos($self->[TEXT]) )
		= @{ pop(@{$self->[STACK]}) || [] };
	return;
}

#------------------------------------------------------------------------------

=head1 METHODS - SEARCH PATH FOR FILES

=head2 path

Returns the list of directories to search in sequence for source files.

=cut

#------------------------------------------------------------------------------
sub path { @{$_[0][PATH]} } ## no critic
#------------------------------------------------------------------------------

=head2 add_path

Adds the given directories to the path searched for include files.

=cut

#------------------------------------------------------------------------------
sub add_path {
	my($self, @dirs) = @_;
	push @{$self->[PATH]}, @dirs;
}
#------------------------------------------------------------------------------

=head2 path_search

Searches for the given file name in the C<path> created by C<add_path>, returns 
the first full path name where the file can be found.

Returns the given input file name unchanged if:

=over 4

=item *

the file is found in the current directory; or 

=item *

the file is not found in any of the C<path> directories.

=back

=cut

#------------------------------------------------------------------------------
sub path_search {
	my($self, $file) = @_;
	
	return $file if -f $file;	# found
	
	for my $dir (@{$self->[PATH]}) {
		my $full_path = File::Spec->catfile($dir, $file);
		return $full_path if -f $full_path;
	}
	
	return $file;				# not found
}
#------------------------------------------------------------------------------

=head1 METHODS - INPUT STREAM

=head2 from_file

Saves the current input context, searches for the given input file name 
in the C<path>, opens the file and sets-up the object to read
each line in sequence. At the end of the 
file input resumes to the place where it was when C<from_file> was called.

Dies if the input file cannot be read, or if a file is
included recursively, to avoid an infinite include loop.

=cut

#------------------------------------------------------------------------------
sub from_file {
	my($self, $file) = @_;
	
	# search include path
	$file = $self->path_search($file);
	
	# check for include loop
	if (grep {($_->[FILE] // "") eq $file} @{$self->[STACK]}) {
		$self->error("#include loop");
	}
	
	# open the file
	open(my $fh, "<", $file) 
		or $self->error("unable to open input file '$file'");
		
	# create a new iterator to read file lines
	my $input = sub {
		$fh or return;
		my $line = <$fh>;
		if (defined $line) {
			$line .= "\n" unless $line =~ /\n\z/;	# add \n if missing
			return $line;
		}
		$fh = undef;		# free handle when file ends
		return;
	};
	$self->from_list($input);
	$self->[FILE] = $file;
	
	return;
}
#------------------------------------------------------------------------------

=head2 from_list

Saves the current input context and sets-up the object to read each element 
of the passed input list. Each element either a text string 
or a code reference of an iterator that returns text strings. 
The iterator returns C<undef> at the end of input.

=cut

#------------------------------------------------------------------------------
# input from text string (if scalar) or iterator (if CODE ref)
sub from_list {
	my($self, @input) = @_;
	
	# save previous context
	$self->_push_context if defined $self->[INPUT];
	
	# iterator
	my $input = sub {
		while (1) {
			@input or return;				# end of input
			for ($input[0]) {
				if (! ref $_) {
					return shift @input;	# scalar -> return it
				}
				else {						# has to be a CODE ref
					my $element = $_->();
					if (defined $element) {	# iterator returned something
						return $element;	
					}
					else {					# end of iterator
						shift @input;		# continue loop
					}
				}
			}
		}
	};
	
	# initialize
	@{$self}[ INPUT,  FILE,  LINE_NR, LINE_INC, SAW_NL, TEXT  ] 
		  = ( $input, undef, 0,       1,        1,      undef );
	
	return;
}
#------------------------------------------------------------------------------

=head1 METHODS - INPUT

=head2 get_token

Retrieves the next token from the input as an array reference containing
token type and token value. 

Returns C<undef> on end of input.

=head2 tokenizer

Method responsible to match the next token from the given input string.

This method can be overridden by a child class in order to implement a different
set of tokens to be retrieved from the input.

It is implemented with features from the Perl 5.010 regex engine:

=over 4

=item *

one big regex with C</\G.../gc> to match from where the
last match ended; the string to match is passed as a scalar reference, so that
the position of last match  C<pos()> is preserved;

=item *

one sequence of C<(?:...|...)> alternations for each token to be matched;

=item *

using C<(?E<gt>...)> for each token to make sure there is no
backtracking;

=item *

using capturing parentheses and embedded code evaluation 
C<(?{ [TYPE =E<gt> $^N] })> to return the token value
from the regex match;

=item *

using C<$^R> as the value of the matched token; 

As the regex engine is not
reentrant, any operation that may call another regex match 
(e.g. recursive file include) cannot be done inside 
the C<(?{ ... })> code block, and is done after the regex match by checking the 
C<$^R> for special tokens.

=item *

using C<undef> as the return of C<$^R> to ignore a token, e.g. white space.

=back

The default tokenizer recognizes and returns the following token types:

=over 4

=item [STR => $value]

Perl-like single or double quoted string, C<$value> contains the string 
without the quotes and with any backslash escapes resolved. 

The string cannot span multiple input lines.

=item [NUM => $value]

Perl-like integer in decimal, hexadecimal, octal or binary notation, 
C<$value> contains decimal value of the integer.

=item [NAME => $name]

Perl-like identifier name, i.e. word starting with a letter or underscore and 
followed by letters, underscores or digits.

=item [$token => $token]

All other characters except white space are returned in the form 
C<[$token=E<gt>$token]>, where C<$token> is a single character or one 
of the following composed tokens: << >> == != >= <=

=item white space

All white space is ignored, i.e. the tokenizer returns C<undef>.

=item [INCLUDE => $file]

Returned when a C<#include> statement is recognized, causes the lexer to
recursively include the file at the current input stream location.

=item [INPUT_POS => $file, $line_nr, $line_inc]

Returned when a C<#line> statement is recognized, causes the lexer to
set the current input location to the given C<$file>, C<$line_nr> and 
C<$line_inc>. 

=item [ERROR => $message]

Causes the lexer to call C<error> with the given error message, can be 
used when the input cannot be tokenized.

=back

=cut

#------------------------------------------------------------------------------
# get the next line from input, set TEXT, return true
# accumulate lines ending in \\, to allow lexer to handle continuation lines
sub _readline {
	my($self) = @_;
	
	while (1) {
		my $input = $self->[INPUT] or return;		# no input, return false
		if ( defined( $self->[TEXT] = $input->() ) ) {
			while ( $self->[TEXT] =~ /\\\Z/ ) {
				my $next_line = $input->();
				last unless defined $next_line;
				$self->[TEXT] .= $next_line;
			}
			pos($self->[TEXT]) = 0;
			last;
		}
		else {
			$self->_pop_context;					# pop and continue
		}
	}
	return 1;
}

#------------------------------------------------------------------------------
# get next token as [TYPE => VALUE], undef on end of input
sub get_token {
	my($self) = @_;

	LINE:
	while (1) {
		# read line
		if (! defined $self->[TEXT]) {
			$self->_readline or return;			# end of input
		}
		
		# return tokens
		while ( (my $start_pos = pos($self->[TEXT]))
				< length($self->[TEXT])
			  ) {	
			# increment line number if last token included newlines
			# need to retest after each token
			if ($self->[SAW_NL]) {
				$self->[LINE_NR] += $self->[SAW_NL] * $self->[LINE_INC];
				undef $self->[SAW_NL];
			}
		
			# read next token
			my $token = $self->tokenizer(\($self->[TEXT]));
			
			# check for newlines
			my $end_pos = pos($self->[TEXT]);
			$self->[SAW_NL] += 
				substr($self->[TEXT], $start_pos, $end_pos - $start_pos) 
					=~ tr/\n/\n/;
			
			# check for special tokens
			next unless defined $token;
			
			my $method = $self->can( $token->[0] );
			if ($method) {
				my $new_token = $self->$method($token);
				return $new_token if defined $new_token;
				next LINE unless defined $self->[TEXT];	# if context changed
			}
			else {
				return $token;
			}
		}
		# end of line
		undef $self->[TEXT];
	}
}

#------------------------------------------------------------------------------
# special handlers: return $token to return changed token; return undef to continue loop
# changeable by subclass
sub INCLUDE {
	my($self, $token) = @_;
	
	$self->from_file($token->[1]);
	
	return;
}

sub INPUT_POS {
	my($self, $token) = @_;
	
	@{$self}[ SAW_NL, FILE, LINE_NR, LINE_INC ] =
			( undef,  @{$token}[1 .. $#$token] );
	
	return;
}

sub ERROR {
	my($self, $token) = @_;
	
	$self->error($token->[1]);
	
	return;
}
	
#------------------------------------------------------------------------------
# get next token as [TYPE => VALUE] from the given string reference
# return undef to ignore a token
sub tokenizer {
	my($self, $rtext) = @_;
	our $LINE_NR; local $LINE_NR;
	
	$$rtext =~ m{\G
		(?:
			# #include
			(?> ^ (?&SP)* \# include (?&SP)*
				(?:	\' ( [^\'\n]+ ) \' 	(?{ [INCLUDE => $^N] }) 
				|	\" ( [^\"\n]+ ) \" 	(?{ [INCLUDE => $^N] }) 
				|	 < ( [^>\n]+  )  > 	(?{ [INCLUDE => $^N] }) 
				|	   ( \S+      )		(?{ [INCLUDE => $^N] }) 
				|						(?{ [ERROR => 
											 "#include expects a file name"] })
				)
				.* \n?					# eat newline
			)
		
			# #line
		|	(?> ^ (?&SP)* \# line (?&SP)+ 
					(\d+) (?&SP)+ 		(?{ $LINE_NR = $^N })
					\"? ([^\"\n]+) \"?	(?{ [INPUT_POS => $^N, $LINE_NR, 1] })
				.* \n?					# eat newline
			)
			
			# other #-lines - ignore
		|	(?> ^ (?&SP)* \# .* \n?		(?{ undef }) 
			)
		
			# white space
		|	(?> \s+						(?{ undef }) 
			)
			
			# string
		|	(?>	( \" (?: \\. | [^\\\"] )* \" )
										(?{ [STR => eval($^N)] })
			)
		|	(?>	( \' (?: \\. | [^\\\'] )* \' )
										(?{ [STR => eval($^N)] })
			)
			
			# number
		|	(?> 0x ( [0-9a-f]+ ) \b 	(?{ [NUM => hex($^N)] }) 
			)
		|	(?> 0b ( [01]+ ) \b			(?{ [NUM => oct("0b".$^N)] }) 
			)
		|	(?> 0 ( [0-7]+ ) \b			(?{ [NUM => oct("0".$^N)] }) 
			)
		|	(?> ( \d+ ) \b 				(?{ [NUM => 0+$^N] }) 
			)
		
			# name
		|	(?> ( [a-z_]\w* )			(?{ [NAME => $^N] }) 
			)
			
			# symbols
		|	(?> ( << | >> | == | != | >= | <= | . )
										(?{ [$^N, $^N] }) 
			)
		)
		
		(?(DEFINE)
			# horizontal blanks
			(?<SP>	[\t\f\r ] )
		)
	}gcxmi or die 'not reached';
	return $^R;
}

#------------------------------------------------------------------------------
# implemented by XSAccessor above

=head1 METHODS - INPUT LOCATION AND ERRORS

=head2 file

Returns the current input file, C<undef> if reading from a list.

=head2 line_nr

Returns the current input line number, starting at 1.

=head2 line_inc

Increment of line number on each new-line found, usually 1.

=head2 error

Dies with the given error message, indicating the place in the input source file
where the error occurred.

=cut

#------------------------------------------------------------------------------
sub error { 
	my($self, $message) = @_;
	Parse::FSM::Error::error( $self->_error_msg($message), 
							  $self->[FILE], $self->[LINE_NR] );
}
#------------------------------------------------------------------------------

=head2 warning

Warns with the given error message, indicating the place in the input source file
where the warning occurred.

=cut

#------------------------------------------------------------------------------
sub warning { 
	my($self, $message) = @_;
	Parse::FSM::Error::warning( $self->_error_msg($message), 
							    $self->[FILE], $self->[LINE_NR] );
}

#------------------------------------------------------------------------------
# error message for error() and warning()
sub _error_msg { 
	my($self, $message) = @_;
	
	defined($message) and $message =~ s/\s+\z//;

	my $near;
	if (defined($self->[TEXT]) && defined(pos($self->[TEXT]))) {
		my $code = substr($self->[TEXT], pos($self->[TEXT]), 20);
		$code =~ s/\n.*//s;
		if ($code ne "") {
			$near = "near ".dump($code);
		}
	}

	return join(" ", grep {defined} $message, $near);
}
#------------------------------------------------------------------------------

=head1 AUTHOR, BUGS, FEEDBACK, LICENSE, COPYRIGHT

See L<Parse::FSM|Parse::FSM>

=cut

#------------------------------------------------------------------------------

1;
