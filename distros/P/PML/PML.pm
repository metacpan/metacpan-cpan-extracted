################################################################################
#
# PML.pm (PML Markup Language)
#
################################################################################
#
# Copyright (C) 1999-2000 Peter J Jones (pjones@cpan.org)
# All Rights Reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the Author nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.
#
################################################################################
#
# POD
#
################################################################################

=pod

=head1 NAME

PML (PML Markup Lanuage)

=head1 SYNOPSIS

use PML;

my $parser = new PML;

$parser->parse('/path/to/somefile');

my $output = $parser->execute;

=head1 DESCRIPTION

PML is a powerful text preprocessor. It supports such things as
variables, flow control and macros. After preprocessing a text file
it returns the result to your Perl script. The power comes from
the fact that you can even embed Perl code into the file that is
getting processed.

PML was originaly designed to seperate a Perl CGI script and the
HTML that it generates. What sets PML apart from other similar
solutions is that it is not just a web solution using mod_perl.
You can parse PML files from the command line using the supplied
pml script or from within your Perl scripts using the PML Perl
module.

If you do have mod_perl, you can use the supplied mod_pml Apache
module to parse PML files from within the Apache web server.

=head1 EXAMPLE PML FILE

	<html>
		<head>
			<title>${title}</title>
		</head>
		<body>
		@if(${title}) {
			<h1>${title}</h1>
		}
		</body>
	</html>

=head1 DOCUMENTATION

Documentation is supplied with this module, in the doc directory.

      language.html: describes the language.

   pml-modules.html: tells you how to write a PML module

pml-custom-app.html: tells you how to extend PML from
                     within your application.

=head1 USAGE

The following is an overview of the PML API

=cut
################################################################################
#
# Package Definition
#
################################################################################
package PML; {
	package PML::Token;
	use base PML;
}
################################################################################
#
# Includes
#
################################################################################
use strict;
use Carp;
use Text::Wrap;
use File::Basename;
use Cwd qw(cwd chdir);
################################################################################
#
# Constants
#
################################################################################
use constant ID							=> '$Id: PML.pm,v 1.29 2000/07/31 20:39:50 pjones Exp $';

use constant PML_V						=>  0;  # pml variables
use constant PML_LINE					=>  1;  # current line number
use constant PML_LINE_STR				=>  2;  # line string
use constant PML_TOKENS					=>  3;  # tokens array
use constant PML_TC						=>  4;  # the token counter
use constant PML_LINES					=>  5;  # list of lines
use constant PML_W						=>  6;  # warnings flag
use constant PML_PEEK					=>  7;  # peek flag
use constant PML_FILE					=>  8;  # file name element
use constant PML_MAGIC					=>  9;  # use magic flag
use constant PML_MAGIC_NEWLINE			=> 10;  # magic newline flag
use constant PML_MAGIC_TAB				=> 11;  # magic tab flag
use constant PML_COLLECTOR				=> 12;  # collect the output from a execute
use constant PML_MACROS					=> 13;  # hash of macro tokens
use constant PML_INCLUDES				=> 14;  # hash of filenames for includes
use constant PML_USE_STDERR				=> 15;  # flag; allow errors to STDERR
use constant PML_PARSE_AFTER			=> 16;  # parse after flag
use constant PML_RECURSIVE_MAX			=> 17;  # max times to allow recurse
use constant PML_RECURSIVE_COUNT		=> 18;  # current number of recurse
use constant PML_NEED_LIST				=> 19;  # list of needed modules
use constant PML_OBJ_DIR				=> 20;	# dir to store object
use constant PML_LOOP_COUNTERS			=> 21;	# are we in a loop flags
use constant PML_DIE_MESSAGE			=> 22;	# message given durring a die
use constant PML_PCALLBACKS				=> 23;	# object specific parser callbacks
use constant PML_TCALLBACKS				=> 24;	# object specific token callbacks

use constant PML_TOKEN_ID				=> 0;	# store the token id
use constant PML_TOKEN_CONTEXT			=> 1;	# the context that the token is called in
use constant PML_TOKEN_FILE_LOC			=> 2;	# arg; block; file
use constant PML_TOKEN_LABEL			=> 3;	# label name if we have one
use constant PML_TOKEN_DATA				=> 4;	# the actual token data

use constant CONTEXT_SCALAR				=> 1;	# scalar context
use constant CONTEXT_LIST				=> 2;	# list context

use constant FILE_LOC_FILE				=> 0;	# token within file scope
use constant FILE_LOC_ARG				=> 1;	# token within arg list
use constant FILE_LOC_BLOCK				=> 2;	# token within block

use constant TOKEN_IF					=> 1;	# if function token
use constant TOKEN_NOT					=> 2;	# unless function
use constant TOKEN_EVAL					=> 3;	# eval internal token
use constant TOKEN_PERL					=> 4;	# perl function token
use constant TOKEN_SET					=> 5;	# set function token
use constant TOKEN_INCLUDE				=> 6;	# include function token
use constant TOKEN_MACRO				=> 7;	# macro function token
use constant TOKEN_VARIABLE				=> 8;	# allows the expansion of a variable outside a string
use constant TOKEN_FOREACH				=> 9;	# foreach function token
use constant TOKEN_WHILE				=> 10;	# while and until loop token
use constant TOKEN_SKIP					=> 11;  # skip function
use constant TOKEN_WRAP					=> 12;	# wrap function
use constant TOKEN_RIB					=> 13;	# replace if blank function
use constant TOKEN_MAGIC_MACRO			=> 14;	# call a unknown macro
use constant TOKEN_LOOP_INT				=> 15;	# next, redo, last functions

use constant TOKEN_SET_SET				=> 1;	# set sub tokens
use constant TOKEN_SET_IF				=> 2;	# |
use constant TOKEN_SET_APPEND			=> 3;	# |
use constant TOKEN_SET_PREPEND			=> 4;	# |
use constant TOKEN_SET_CONCAT			=> 5;	# |

use constant TOKEN_START_AVAL			=> 1001;# what token id to start at for others
use constant ARG_BLOCK					=> 1;	# function with arguments and a block
use constant ARG_ONLY					=> 2;	# function with only arguments, no block
use constant BLOCK_ONLY					=> 3;	# function with only a block, no arguments

use constant G_MARKER					=> '@';
use constant G_RE_IF					=> qr/^\@(elsif|else)/o;
################################################################################
#
# Global Variables and Default Settings
#
################################################################################
use vars qw($VERSION $AUTOLOAD);
$VERSION	= '0.4.1';

my %function_arg_block = (
	'if'		=> \&parse_if,
	'unless'	=> [\&parse_if, 1],
	'macro'		=> \&parse_macro,
	'foreach'	=> \&parse_foreach,
	'while'		=> \&parse_while,
	'until'		=> [\&parse_while, 1],
	'wrap'		=> \&parse_wrap,
	'rib'		=> \&parse_rib,
);

my %function_arg_only = (
	'set'		=> [\&parse_set, TOKEN_SET_SET],
	'setif'		=> [\&parse_set, TOKEN_SET_IF],
	'append'	=> [\&parse_set, TOKEN_SET_APPEND],
	'prepend'	=> [\&parse_set, TOKEN_SET_PREPEND],
	'concat'	=> [\&parse_set, TOKEN_SET_CONCAT],
	'include'	=> \&parse_include,
	'warning'	=> \&parse_warning,
	'need'		=> \&parse_need,
	'next'		=> [\&parse_loop_int, 'next'],
	'redo'		=> [\&parse_loop_int, 'redo'],
	'last'		=> [\&parse_loop_int, 'last'],
);

my %function_block_only = (
);

my %function_block_no_parse = (
	'perl'		=> \&parse_perl,
	'skip'		=> \&parse_skip,
);

my %allow_remove_tabs = (
	'set'		=> 1,
	'setif'		=> 1,
	'append'	=> 1,
	'prepend'	=> 1,
	'concat'	=> 1,
	'include'	=> 1,
	'need'		=> 1,
	'if'		=> 1,
	'unless'	=> 1,
	'macro'		=> 1,
	'foreach'	=> 1,
	'while'		=> 1,
	'until'		=> 1,
	'rib'		=> 1,
);

my %allow_remove_newline = (
	'macro'		=> 1,
	'set'		=> 1,
	'setif'		=> 1,
	'append'	=> 1,
	'prepend'	=> 1,
	'concat'	=> 1,
	'include'	=> 1,
	'need'		=> 1,
	'if'		=> 1,
	'unless'	=> 1,
	'while'		=> 1,
	'until'		=> 1,
	'skip'		=> 1,
	'perl'		=> 1,
	'rib'		=> 1,
	'wrap'		=> 1,
);

my %loop_functions = (
	'foreach'	=> 1,
	'while'		=> 1,
	'until'		=> 1,
);

my %tokens =  (
	TOKEN_IF()			=> \&token_if,
	TOKEN_NOT()			=> \&token_not,
	TOKEN_EVAL()		=> \&token_eval,
	TOKEN_PERL()		=> \&token_perl,
	TOKEN_SET()			=> \&token_set,
	TOKEN_INCLUDE()		=> \&token_include,
	TOKEN_MACRO()		=> \&token_macro,
	TOKEN_VARIABLE()	=> \&token_variable,
	TOKEN_FOREACH()		=> \&token_foreach,
	TOKEN_WHILE()		=> \&token_while,
	TOKEN_SKIP()		=> \&token_skip,
	TOKEN_WRAP()		=> \&token_wrap,
	TOKEN_RIB()			=> \&token_rib,
	TOKEN_MAGIC_MACRO()	=> \&token_magic_macro,
	TOKEN_LOOP_INT()	=> \&token_loop_int,
);

my @invalid_functions;
my $next_token = TOKEN_START_AVAL;

my @inc = (
	'.',
	'..', 
	'../include', 
	'/usr/local/share/pml',
	'/usr/local/pml/include',
);

my $RE_NAME	= qr/(?:(?:[A-Za-z_]|\$\{)(?:\w|\$|(?<=\$)\{|\}|::|\.|-|[\[\]])*)/o;
my $RE_VAR	= qr/(?:[A-Za-z_\$](?:\w|::|\.|-|\[|\]|\{|\}|\$)*)|\./o;
my $RE_VAR_TEST = qr/([^\$]*)(?<!\\)\$(?=\{)/o;
my $RE_FUNCTION	= '^([^' . G_MARKER() . ']*)(?<!\\\\)' . G_MARKER() . "($RE_NAME)";
my $RE_LOOP_INT = qr/^(next|last|redo):(\w+)?/o;
my $RE_LABEL	= qr/([A-Z0-9]+):\s*$/o;

use vars qw($DEBUG);
$DEBUG	= 0;
################################################################################
#------------------------------------------------------------------------------#

=pod

=head2 METHOD new


	Arguments:
		1) Class or PML Object to clone
		2) Hash Reference (Optional)

	Returns:
		1) A PML Object

	Description:
		new creates a new PML Object and returns the object
		to the caller. You can optionaly pass in a hash
		refernece, where the keys are PML variables to set
		and the values are the values to set those variables
		to.

=cut

#------------------------------------------------------------------------------#
################################################################################
sub new
{
	my $ref = shift;
	my $class = ref($ref) || $ref;
	my $v = shift;
	my $self = [];
	
	# check to see if the is a PML::Token object
	if ($class eq 'PML::Token') {
		my $self = [];
		   $self->[PML_TOKEN_ID] = undef;
		   $self->[PML_TOKEN_CONTEXT] = CONTEXT_SCALAR;
		   $self->[PML_TOKEN_FILE_LOC] = FILE_LOC_FILE;
		   $self->[PML_TOKEN_DATA] = undef;
		
		_token_id($self, $v) if defined $v;
		return bless $self, $class;
	}
	
	if (not ref $ref) {
		# create new PML Object and set some variables
		$self->[PML_V] 					= {PMLVERSION => $VERSION};
		$self->[PML_W] 					= 0;
		$self->[PML_LINE] 				= 0;
		$self->[PML_LINE_STR] 			= 'on Line 1';
		$self->[PML_TOKENS] 			= [];
		$self->[PML_PEEK] 				= 0;
		$self->[PML_FILE] 				= 'input stream';
		$self->[PML_MAGIC] 				= 1;
		$self->[PML_MAGIC_NEWLINE] 		= 1;
		$self->[PML_MAGIC_TAB] 			= 0;
		$self->[PML_COLLECTOR] 			= '';
		$self->[PML_MACROS] 			= {};
		$self->[PML_INCLUDES] 			= {};
		$self->[PML_USE_STDERR] 		= 1;
		$self->[PML_PARSE_AFTER] 		= 0;
		$self->[PML_RECURSIVE_MAX] 		= 1000;
		$self->[PML_RECURSIVE_COUNT] 	= 0;
		$self->[PML_NEED_LIST] 			= [];
		$self->[PML_OBJ_DIR] 			= '/tmp';
		$self->[PML_LOOP_COUNTERS] 		= {};
		$self->[PML_DIE_MESSAGE] 		= '';
		$self->[PML_TCALLBACKS]			= {};
		$self->[PML_PCALLBACKS] 		= {
			'function_arg_block'		=> {},
			'function_arg_only'			=> {},
			'function_block_only'		=> {},
			'function_block_no_parse'	=> {},
		};

		# Set up the loop counters
		$self->[PML_LOOP_COUNTERS]{$_} = 0 foreach keys %loop_functions;
	} else { # we need to clone an existsing object
		eval {require Storable} or # make sure Storable is avaliable
			croak "can't call new as a method unless you install the Storable module";

		$self->[PML_V] 				= Storable::dclone($ref->[PML_V]);
		$self->[PML_W] 				= $ref->[PML_W];
		$self->[PML_LINE] 			= $ref->[PML_LINE];
		$self->[PML_LINE_STR] 		= $ref->[PML_LINE_STR];
		$self->[PML_TOKENS] 		= Storable::dclone($ref->[PML_TOKENS]);
		$self->[PML_PEEK] 			= $ref->[PML_PEEK];
		$self->[PML_FILE] 			= $ref->[PML_FILE];
		$self->[PML_MAGIC] 			= $ref->[PML_MAGIC];
		$self->[PML_MAGIC_NEWLINE] 	= $ref->[PML_MAGIC_NEWLINE];
		$self->[PML_MAGIC_TAB] 		= $ref->[PML_MAGIC_TAB];
		$self->[PML_COLLECTOR] 		= $ref->[PML_COLLECTOR];
		$self->[PML_MACROS] 		= Storable::dclone($ref->[PML_MACROS]);
		$self->[PML_INCLUDES] 		= Storable::dclone($ref->[PML_INCLUDES]);
		$self->[PML_USE_STDERR] 	= $ref->[PML_USE_STDERR];
		$self->[PML_PARSE_AFTER] 	= $ref->[PML_PARSE_AFTER];
		$self->[PML_RECURSIVE_MAX]	= $ref->[PML_RECURSIVE_MAX];
		$self->[PML_RECURSIVE_COUNT]= $ref->[PML_RECURSIVE_COUNT];
		$self->[PML_NEED_LIST] 		= Storable::dclone($ref->[PML_NEED_LIST]);
		$self->[PML_OBJ_DIR] 		= $ref->[PML_OBJ_DIR];
		$self->[PML_LOOP_COUNTERS] 	= Storable::dclone($ref->[PML_LOOP_COUNTERS]);
		$self->[PML_DIE_MESSAGE] 	= $ref->[PML_DIE_MESSAGE];
		$self->[PML_TCALLBACKS]		= {%{$ref->[PML_TCALLBACKS]}};
		$self->[PML_PCALLBACKS] 	= {};
		
		# clone the callback holders
		foreach my $key (keys %{$ref->[PML_PCALLBACKS]}) {
			$self->[PML_PCALLBACKS]{$key} = {%{$ref->[PML_PCALLBACKS]{$key}}};
		};
	}

	# Set some other variables if passed into this sub
	%{$self->[PML_V]} = (%{$self->[PML_V]}, %$v) if defined $v;
	
	# Bless and return this new object
	bless $self, $class;
} # <-- End new -->
################################################################################
#
# ==== ready ==== ##############################################################
#
#   Arguments:
#	1) A PML Object
#	2) A String (filename) or A reference to an array
#
#     Returns:
#	None
#
# Description:
#	Gets the PML Object ready to parse
#
################################################################################
sub ready
{
	my ($self, $x) = @_;
	
	#
	# check the arguments
	#
	croak("Usage: ready(pml_object, lines_string|lines_arrayref)")
		unless defined $self and defined $x;
	
	#
	# setup the lines array ref
	#
	if ((ref $x) eq 'ARRAY')
	{
		$self->[PML_LINES] = $x;
	}
	else
	{
		open(SOURCE, $x) || die "cannot open file \"$x\": $!\n";
		@{$self->[PML_LINES]} = <SOURCE>;
		close SOURCE;
		$self->[PML_FILE] = $x;
	}
} # <-- End ready -->
################################################################################
#------------------------------------------------------------------------------#

=pod

=head2 METHOD parse


	Arguments:
		1) PML Object
		2) Filename or a reference to an array of lines

	Returns:
		1) True if parse was successful

	Description:
		parse will parse the file or array that you give
		it. If there is an error, such as a syntax error,
		parse will throw an exception via die.  Therefore
		if you want to catch the exception you should wrap
		the call to parse in an eval block and check $@.
		If $@ is true there was and error and the error
		message can be found in $@.

=cut

#------------------------------------------------------------------------------#
################################################################################
sub parse
{
	my ($self, $x) = @_;
	my ($cwd);
	
	# check the arguments
	croak("Usage: parse(pml_object, lines_string|lines_arrayref)")
		unless defined $self and defined $x;
	
	# call ready to prep the pml object
	$self->ready($x);
		
	
	# if we were given the filename to parse then chdir
	# to where that file lives before we parse it
	$cwd = cwd;
	
	if (not ref $x) {
		my $dir = dirname $x;
		
		unless (chdir $dir) {
			print STDERR "A error occured while trying to change directroies to parse the file \"$x\": $!\n";
			die "$!\n";
		}
	}
	
	# now parse all the lines
	my ($line, @tokens);

	while (1) {
		$line = $self->next_line unless defined $line and length $line;
		defined $line or last;
		
		if ($self->[PML_PARSE_AFTER]) {
			if ($line =~ $self->[PML_PARSE_AFTER]) {
				$self->[PML_PARSE_AFTER] = 0;
			}
			
			$line = '';
			next;
		}
		
		@tokens = $self->parse_one_line(\$line);
		push(@{$self->[PML_TOKENS]}, @tokens) if @tokens;
	}
	
	foreach my $invalid_function (@invalid_functions) {
		unless (
			exists $self->[PML_MACROS]{$invalid_function->[0]} 
			and defined $self->[PML_MACROS]{$invalid_function->[0]}
		) {
			$self->error_syntax("$invalid_function->[1], the macro or function \"$invalid_function->[0]\" is not defined.");
		}
	}
	
	# now that we are done parsing we can 
	# move back to the dir where we started
	chdir $cwd;

	return 1;
} # <-- End parse -->
################################################################################
#------------------------------------------------------------------------------#

=pod

=head2 METHOD execute


	Arguments:
		1) PML Object
		2) A Hash Reference (Optional)

	Returns:
		1) The text in the file after processing it

	Description:
		execute will process the file and return the
		post-processed text.  You can optionaly pass in a
		reference to a hash, where the keys are PML variables
		to set and the values are the value to set them
		to.  This is a good way so talk to your text file.

		You can call execute as many times as you wish.
		Each call will start afresh at the top of the parsed
		file.

=cut

#------------------------------------------------------------------------------#
################################################################################
sub execute
{
	my ($self, $v) = @_;
	my ($tmp);
	
	#
	# check arguments
	#
	croak("Usage: execute(pml_object, hash_ref_optional)") unless defined $self;
	
	#
	# make sure that there are tokens
	#
	unless ($self->[PML_TOKENS])
	{
		croak("There were no tokens to process, maybe you did not call parse or maybe the file was empty");
	}
	
	#
	# Clean out the collector if we need to
	#
	undef $self->[PML_COLLECTOR];
	
	#
	# set any variables
	#
	$self->[PML_V]{$_} = $v->{$_} foreach keys %$v;
	
	#
	# set some default values
	#
	$self->[PML_TC] = 0;
	
	#
	# now walk the token list and execute tokens
	#
	while ($#{$self->[PML_TOKENS]} >= $self->[PML_TC])
	{
		$tmp = $self->tokens_execute (
			$self->[PML_TOKENS][$self->[PML_TC]]
		);

		$self->[PML_COLLECTOR] .= $tmp if defined $tmp;
		
		# check to see if it died
		if ($self->[PML_DIE_MESSAGE]) {
			# see if it is ours
			if ($self->[PML_DIE_MESSAGE] =~ /$RE_LOOP_INT/o) {
				# do stuff
				if ($1 eq 'next') {
					$self->[PML_TC]++;
					next;
				} elsif ($1 eq 'redo') {
					redo;
				} elsif ($1 eq 'last') {
					last;
				}
			} else { # it's not ours
				die $self->[PML_DIE_MESSAGE];
			}
		}
		
		$self->[PML_TC]++;
	}
	
	return $self->[PML_COLLECTOR];
} # <-- End execute -->
################################################################################
#------------------------------------------------------------------------------#

=pod

=head2 METHOD v 


	Arguments:
		1) PML Object

		-- or --
		
		2) Variable Name

		-- or --

		2) Variable Name
		3) New Value

		-- or --

		2) Hash Reference

	Returns:
		1) Depends on Arguments, see below.

	Description:
		The v method allows you to get and set PML variables.
		There are a few different ways to use v, and we
		will cover them all.

		Arguments:
			1) PML Object

		In this case, you call v with only the object, no
		arguments. This will return an array of variable
		names. This is so you can see what variables are
		defined.

		Arguments:
			1) PML Object
			2) Variable Name

		This time you give a name of a variable. The v
		method will return the current value of that
		variable, or undef if it is not set.

		Arguments:
			1) PML Object
			2) Variable Name
			3) Value

		Here, you give a variable name and the value to
		set it to. The v method will then set the give
		variable to the value you gave it. It should return
		the same value.

		Arguments:
			1) PML Object
			2) Hash Reference

		To limit method calls, you can give a hash reference
		where the keys are the variable to set and the
		values are the value to set those variables to.
		Returns 1.

=cut

#------------------------------------------------------------------------------#
################################################################################
sub v
{
	my ($self, $variable, $value) = @_;
	
	unless ($self) {
		carp "Usage: v(PML, [Variable, [Value]])";
		return undef;
	}
	
	unless ($variable) {
		return %{$self->[PML_V]};
	}

	if (ref $variable eq 'HASH') {
		foreach my $key (keys %$variable) {
			$self->[PML_V]{$key} = $variable->{$key};
		}
		return 1;
	}
	
	if (defined $value) {
		$self->[PML_V]{$variable} = $value;
	}
	
	return $self->[PML_V]{$variable};
} # <-- End v -->
################################################################################
#------------------------------------------------------------------------------#

=pod

=head2 METHOD parse_after


	Arguments:
		1) PML Object
		2) Regular Expression String or Object

	Returns:
		1) Nothing

	Description:
		Used before the call to parse, this method will
		effect when parsing will start. When you call the
		parse method, it will search for the given regex,
		when that regex matches, parsing will begin on the
		NEXT line.

=cut

#------------------------------------------------------------------------------#
################################################################################
sub parse_after
{
	my ($self, $regex) = @_;
	
	$regex = qr/$regex/ unless ref $regex eq 'Regexp';
	$self->[PML_PARSE_AFTER] = $regex;
} # <-- End parse_after -->
################################################################################
#------------------------------------------------------------------------------#

=pod

=head2 CLASS METHOD register


	Arguments:
		1) Class ie PML->register(...)
		2) A Hash, keys are described below

	Returns:
		1) An ID number to refer to your token

	Description:
		The register function is used to extend the PML
		syntax. You register a callback for a new PML
		function. When parsing the text, PML will call your
		parser-callback to assist parsing. When executing,
		PML will call your token-callback to process the
		token created by your parser-callback.

		Here is what you should pass to register:

			parse => A callback. Defaults to using the
			         builtin autoparser
			token => A callback. You must give this.
			name  => The name of the new PML function to add.
			type  => See Types below
		
		Callbacks:

			A callback is a reference to a subroutine like this:
				\&myfunc  -- or -- sub{}

			It can also be a reference to an array,
			where the first element is a reference to
			a subroutine and the remaining elements
			are passed to the subroutine as arguemnts
			after the standard arguments.

		Types:

			The types are constants in PML.pm.

            PML->ARG_ONLY   This means that your new 
                            function will only take
                            arguments, just like the 
                            builtin @set function.

            PML->BLOCK_ONLY This means that your new 
                            function only takes a block
                            just like the builtin @perl 
                            function.

            PML->ARG_BLOCK  This means that your new 
                            function takes arguments 
                            and a block, just like the 
                            builtin @if function.

=cut

#------------------------------------------------------------------------------#
################################################################################
sub register
{
	my $ref = shift;
	my $table;
	my %options = (
		parse	=> undef,
		token	=> undef,
		name	=> undef,
		type	=> ARG_ONLY,
		id		=> undef,
		
		@_,
	);
	
	unless (defined $options{token} and defined $options{name}) {
		croak "You must, at a minimum, give token sub and name arguments to PML->register";
	}
	
	foreach ('token', 'parse') {
		next unless defined $options{$_};
		unless (ref($options{$_}) eq 'CODE') {
			unless (ref($options{$_}) eq 'ARRAY' and ref($options{$_}->[0]) eq 'CODE') {
				croak "callback must be a ref to a sub or a ref to an array who's first elemnt is a ref to a sub";
			}
		}
	}
	
	if ($options{type} == ARG_BLOCK) {
		if (ref $ref) {
			$table = $ref->[PML_PCALLBACKS]{'function_arg_block'};
		} else {
			$table = \%function_arg_block;
		}
	} elsif ($options{type} == ARG_ONLY) {
		if (ref $ref) {
			$table = $ref->[PML_PCALLBACKS]{'function_arg_only'};
		} else {
			$table = \%function_arg_only;
		}
	} elsif ($options{type} == BLOCK_ONLY) {
		if (ref $ref) {
			$table = $ref->[PML_PCALLBACKS]{'function_block_only'};
		} else {
			$table = \%function_block_only;
		}
	} else {
		croak "Bad type argument to register, what is type \"$options{type}\"?";
	}
	
	$options{id} ||= $next_token++;
	if (ref $ref) { # this is a method call
		$ref->[PML_TCALLBACKS]{$options{id}} = $options{token};
	} else { # this is a class call
		$tokens{$options{id}} = $options{token};
	}
	$table->{$options{name}} = $options{parse} || [\&auto_parse, \%options];
	
	return $options{id};
} # <-- End register -->
################################################################################
#
# ==== execute_callback ==== ###################################################
#
#   Arguments:
#	1) A callback Object
#	2) All the args to send to the callback
#
#     Returns:
#	What ever the callback returns
#
# Description:
#	Calls the callback
#
################################################################################
sub execute_callback
{
	my ($callback, @args) = @_;
	
	if (ref($callback) eq 'CODE')
	{
		return $callback->(@args);
	}
	elsif (ref($callback) eq 'ARRAY' and ref($callback->[0]) eq 'CODE')
	{
		return $callback->[0]->(@args, @$callback[1 .. $#{$callback}]);
	}
	else
	{
		print STDERR 'Internal error, bad callback object ';
		print STDERR "\"ref(callback) = ";
		print STDERR scalar ref($callback);
		print STDERR "\", sorry but you found a bug. ";
		print STDERR caller, "\n";
		exit 1;
	}
} # <-- End execute_callback -->
################################################################################
#------------------------------------------------------------------------------#

=pod

=head2 METHOD warning


	Arguments:
		1) PML Object
		2) Boolean Flag (Optional)

	Returns:
		1) Current Warning Flag

	Description:
		The warning method will set the warning flag to
		the one given, if one was given. It always returns
		the current value. If the flag is true, PML will
		print warnings to STDERR.

=cut

#------------------------------------------------------------------------------#
################################################################################
sub warning
{
	my ($self, $flag) = @_;
	
	croak "Usage: warning(pml_object, [flag])" unless defined $self;
		
	$self->[PML_W] = $flag if $flag;
	return $self->[PML_W];	
} # <-- End warning -->
################################################################################
#------------------------------------------------------------------------------#

=pod

=head2 METHOD use_stderr

	Arguments:
		1) PML Object
		2) True to allow use of stderr, false to disallow

	Returns:
		1) Nothing

	Description:
		Sets the use_stderr flag for this object

=cut

#------------------------------------------------------------------------------#
################################################################################
sub use_stderr ($$)
{
	my ($self, $flag) = @_;
	$self->[PML_USE_STDERR] = $flag;
} #<-- End: use_stderr -->
################################################################################
#
# ==== tokens_execute ==== #####################################################
#
#   Arguments:
#	1) A PML Object
#	2) A reference to an array of tokens
#
#     Returns:
#	The results of the tokens
#
# Description:
#	runs through the tokens and returns the results
#
################################################################################
sub tokens_execute
{
	my ($self, @tokens) = @_;
	my ($token, @rv, $callback);
	
	# check arguments
	croak("Usage: tokens_execute(pml_object, tokens)")
		unless defined $self;
	
	# reset the die message
	$self->[PML_DIE_MESSAGE] = '';
	
	# return an empty list if there are no tokens
	return () unless @tokens;
	
	# check to see if there is only one token and
	# if that token is realy a array ref to a token
	if (@tokens == 1 and ref($tokens[0]) eq 'ARRAY') {
		@tokens = @{$tokens[0]};
	}
	
	# process the tokens
	foreach $token (@tokens) {
		# skip this token unless it is defined
		next unless defined $token;
		
		# check for an array of tokens
		if (ref $token eq 'ARRAY') {
			push @rv, scalar $self->tokens_execute(@$token);
			next;
		}
		
		# if this is not a token just add it to the result
		unless (ref $token eq 'PML::Token') {
			push @rv, $token;
			next;
		}
		
		# check to see if the token exists
		if (exists $self->[PML_TCALLBACKS]{$token->id}) {
			$callback = $self->[PML_TCALLBACKS]{$token->id};
		} elsif (exists $tokens{$token->id}) {
			$callback = $tokens{$token->id};
		} else {
			die("Hmmm... bad token id '$token->[0]', you found a bug in PML");
		}
		
		# we wrap the next line in an eval because
		# if we come across a @next, @redo or @last
		# they will call die
		eval {
			# call the token and record it's return value
			push @rv, execute_callback($callback, $self, $token);
		};
		
		# check to see if we died
		if ($@) {$self->[PML_DIE_MESSAGE]=$@; last}
	}
	
	# why in the heck am i getting
	# `Use of uninitialized value at ...'
	local ($^W)=0; #FIXME
	
	# now check the calling context
	if (wantarray) {		
		return @rv;
	} else {
		return join '', @rv;
	}
} # <-- End tokens_execute -->
################################################################################
#
# ==== parse_one_line ==== #####################################################
#
#   Arguments:
#	1) A PML Object
#	2) A line of text
#	3) A ref to an array of lines (Optional, default is $self->[PML_LINES])
#
#     Returns:
#	A List of PML_TOKENS to add to the token array
#
# Description:
#	Parses the line, getting more lines from $self->[PML_LINES] if necessary
#	then returns entries to the tokens array
#
################################################################################
sub parse_one_line
{
	my ($self, $line_ref, $lines) = @_;
	my (@tokens, $func, @arguments, @block);
	my ($token, $pre_text, $label, $callback);
	
	# check arguments
	croak("Usage: parse_one_line(pml_object, lines)") unless defined $self and defined $line_ref;
	croak("PML object is missing the lines array") if not $lines and not defined $self->[PML_LINES];
	
	# set lines to self PML_LINES if not already set
	$lines ||= $self->[PML_LINES];
	
	# now check to see if there is a call to a built-in function
	# or a call to a macro
	if ($$line_ref =~ s/$RE_FUNCTION//o) {
		# store the removed text
		$pre_text = $1; $func = $2;
		
		# is the pretext a Label?
		if ($loop_functions{$func} and $pre_text =~ s/$RE_LABEL//o) {
			$label = $1;
		}
		
		# Remove pre_text if it only contains tabs and
		# we want magic and it is allowed for this func
		if ($pre_text and $self->[PML_MAGIC]) {
			$pre_text =~ s/^\s+$//o;
		}
		
		# Put the pretext into a token so that it is not lost
		if ($pre_text) {
			$token = new PML::Token TOKEN_EVAL;
			$token->data($pre_text);
			push @tokens, $token;
		}
		
		if (
			exists $function_arg_only{$func} or 
			exists $self->[PML_PCALLBACKS]{'function_arg_only'}{$func} ){
			# these type have args with no blocks
			if (exists $self->[PML_PCALLBACKS]{'function_arg_only'}{$func}) {
				$callback = $self->[PML_PCALLBACKS]{'function_arg_only'}{$func};
			} else { #build in parser or register-class parser
				$callback = $function_arg_only{$func};
			}
			@arguments = $self->parse_arguments($line_ref, $lines);
			$token = execute_callback($callback, $self, [@arguments], undef, $line_ref, $lines);
			if ($token and $label) {$token->label($label)}
			if ($token) {push @tokens, $token};
		} elsif (
			exists $function_arg_block{$func} or
			exists $self->[PML_PCALLBACKS]{'function_arg_block'}{$func} ){
			# these functions have args and blocks
			if (exists $self->[PML_PCALLBACKS]{'function_arg_block'}{$func}) {
				$callback = $self->[PML_PCALLBACKS]{'function_arg_block'}{$func};
			} else {
				$callback = $function_arg_block{$func};
			}
			@arguments	= $self->parse_arguments($line_ref, $lines);
			@block		= $self->parse_block($line_ref, $lines);
			# call the built in and store the tokens that it returns
			$token = execute_callback($callback, $self, [@arguments], [@block], $line_ref, $lines);
			if ($token and $label) {$token->label($label)}
			if ($token) {push @tokens, $token};
		} elsif (
			exists $function_block_no_parse{$func} or 
			exists $self->[PML_PCALLBACKS]{'function_block_no_parse'}{$func} ){
			# these are fuctions that need to parse their own blocks
			# we just grab whats between the { and } and give them the rest
			if (exists $self->[PML_PCALLBACKS]{'function_block_no_parse'}{$func}) {
				$callback = $self->[PML_PCALLBACKS]{'function_block_no_parse'}{$func};
			} else {
				$callback = $function_block_no_parse{$func};
			}
			$self->magic_newline($line_ref, $lines);
			$token = execute_callback (
				$callback,
				$self, 
				$self->gut('{', '}', $line_ref, $lines, 1)
			);
			if ($token and $label) {$token->label($label)}
			if ($token) {push @tokens, $token};
		} elsif (
			exists $function_block_only{$func} or
			exists $self->[PML_PCALLBACKS]{'function_block_only'}{$func} ){
			# these are functins that only have a block
			if (exists $self->[PML_PCALLBACKS]{'function_block_only'}{$func}) {
				$callback = $self->[PML_PCALLBACKS]{'function_block_only'}{$func};
			} else {
				$callback = $function_block_only{$func};
			}
			@block = $self->parse_block($line_ref, $lines);
			$token = execute_callback($callback, $self, undef, [@block], $line_ref, $lines);
			if ($token and $label) {$token->label($label)}
			if ($token) {push @tokens, $token};
		} else {
			# these are macros or functions that are not defined
			# we need to see if the macro has a variable in it's name
			if ($func =~ /$RE_VAR_TEST/o) {
				$token = new PML::Token TOKEN_MAGIC_MACRO;
			} else { # this is just a normal macro call
				$token = new PML::Token TOKEN_MACRO;
			}
			$token->data([$func, $self->parse_arguments($line_ref, $lines)]);
			if ($token and $label) {$token->label($label)}
			if ($token) {push @tokens, $token}
			
			if ($self->peek(qr/^{/o, $line_ref, $lines)) {
				$self->error_syntax
					("there is no such function called '$func'");
			}
			unless (
				$token->id == TOKEN_MAGIC_MACRO or 
				exists $self->[PML_MACROS]{$func} ){
				push @invalid_functions, 
				[$func, $self->[PML_LINE_STR]];
			}	
		}
		
		# Check to see if we are allowed to remove the trailing
		# spaces and newline
		if ($allow_remove_newline{$func}) {
			$$line_ref =~ s/^\s*\n//o;
		}
	
	} else {
		# if there were no calls to a built-in then this
		# line will only contain variables and/or text
		# so we add the line with the EVAL token
		$token = new PML::Token TOKEN_EVAL;
		$token->data($$line_ref);
		push @tokens, $token;
		$$line_ref = ''; # we took the whole line
	}
	
	return @tokens;
} # <-- End parse_one_line -->
################################################################################
#
# ==== parse_arguments ==== ####################################################
#
#   Arguments:
#	1) A PML Object
#	2) A reference to a line to cut up
#	3) A ref to an array of lines (Optional, defaults to self->[PML_LINES]
#
#     Returns:
#	A list of tokens that make up the arguments to the function call
#
# Description:
#	Looks in the line for the arguments to the function call
#
################################################################################
sub parse_arguments
{
	my ($self, $line_ref, $lines) = @_;
	my (@tokens, $guts, @args, $x, $y, @queue);
	my ($token, $stoken);
	my $M = G_MARKER();
	
	# check arguments
	croak("Usage: parse_arguments(pml_object, line_reference)") unless defined $self and defined $line_ref;
	
	# set lines to self PML_LINES if not already set
	$lines ||= $self->[PML_LINES];
	
	# Remove any space and newlines that might apear before the arguments
	$self->magic_newline($line_ref, $lines);
		
	# check to see if the first char is an expected character
	$x = substr $$line_ref, 0, 1;
	if (not defined $x or $x ne '(') {
		$self->error_syntax("expected a '(' but found '$x' instead");
	}

	# get the guts between the '(' and the ')'
	$guts = $self->gut('(', ')', $line_ref, $lines);
	
	# return a empty list if there are no guts
	return () unless length $guts;
	
	# clean up the arg list
	$guts =~ s/\n+//ogs;
	$guts =~ s/^\s+//os;
	$guts =~ s/\s+$//os;
		
	# now break up the line
	while ($guts =~ /\S/o) {
		$x = substr($guts, 0, 1);
		
		if ($x eq '"' or $x eq "'") {
			$y = $self->gut($x, $x, \$guts, []);
			while ($y =~ /$RE_FUNCTION/o) {
				push @queue, 
					$self->parse_one_line(\$y, []);
			}
			
			if (length $y) {
				$token = new PML::Token TOKEN_EVAL;
				$token->data($y);
				push @queue, $token;
			}
		} elsif ($guts =~ s/^(\${$RE_VAR})\s*(?=,|=>|$)//o) {
			$token = new PML::Token TOKEN_VARIABLE;
			$token->data($y = $1);
			push @queue, $token;
		} elsif ($guts =~ s/^((?:\d+)(?:\.\d+)?)\s*(?=,|=>|$)//o) {
			$token = new PML::Token TOKEN_EVAL;
			$token->data($y = $1);
			push @queue, $token;
		} else {
			if ($guts =~ /^[^,]*?(?<!\\)$M/o) {
				push @queue,
					$self->parse_one_line(\$guts, []);
			} else {
				$guts =~ s/^([^,]+)//o;
				($y = $1) =~ s/\s+$//o;
				if (length $y) {
					$token = new PML::Token TOKEN_EVAL;
					$token->data($y);
					push @queue, $token;
				}
			}
		}
		
		# did we run out of arguments or should we move
		# on to the next one?
		if ($guts =~ s/^\s*(?:(?:,\s*)|(?:=>\s*)|$)//o) {
			if (@queue > 1) {
				push @tokens, [@queue];
				@queue = ();
			} else {
				push @tokens, shift @queue if @queue;
			}
		}
	}
	
	# now just make sure that the queue is empty
	if (@queue) {
		if (@queue > 1) {
			push @tokens, [@queue];
		} else {
			push @tokens, shift @queue;
		}
	}
	
	# set some token flags on all the tokens
	foreach $token (@tokens) {
		if (ref $token eq 'ARRAY') {
			foreach $stoken (@$token) {
				$stoken->file_loc(FILE_LOC_ARG);
				$stoken->context(CONTEXT_LIST);
			} next;
		}
		
		$token->file_loc(FILE_LOC_ARG);
		$token->context(CONTEXT_LIST);
	}
	
	# return the tokens that we collected
	return @tokens;
} # <-- End parse_arguments -->
################################################################################
#
# ==== parse_block ==== ########################################################
#
#   Arguments:
#	1) A PML Object
#	2) A Reference to a line
#	3) A ref to an array of lines (Optional, defaults to self->[PML_LINES])
#
#     Returns:
#	A List of tokens for the block
#
# Description:
#	tries to get the block following the function call
#
################################################################################
sub parse_block
{
	my ($self, $line_ref, $lines) = @_;
	my ($x, @tokens, $guts, $token);
	
	# check arguments
	croak("Usage: parse_block(pml_object, line_reference")
		unless defined $self and defined $line_ref;
	
	# set lines to self PML_LINES if not already set
	$lines ||= $self->[PML_LINES];
	
	# Remove any spaces or newlines
	$self->magic_newline($line_ref, $lines);
		
	# check to see if the first char is an expected character
	$x = substr $$line_ref, 0, 1;
	
	unless ($x eq '{') {
		$self->error_syntax (
			"can't find opening brace, saw '$x' instead"
		);
	}
		
	# get the guts between the '{' and the '}'
	$guts = $self->gut('{', '}', $line_ref, $lines, 1);
	$self->magic_newline_gut(\$guts);
	$self->magic_tab(\$guts);
	
	# parse the text in the block
	while (length $guts) {
		push @tokens, $self->parse_one_line(\$guts, []);
	}
	
	# set some token flags
	foreach $token (@tokens) {
		$token->context(CONTEXT_SCALAR);
		$token->file_loc(FILE_LOC_BLOCK);
	}
	
	return @tokens;
} # <-- End parse_block -->
################################################################################
#
# ==== magic_newline ==== ######################################################
#
#   Arguments:
#	1) A PML Object
#	2) A reference to a string
#	3) A reference to a array of strings (optional)
#
#     Returns:
#	None
#
# Description:
#	Removes all spaces and newlines from the front of arg 2.
#	pulls another string off arg3 if necessary
#
################################################################################
sub magic_newline
{
	my ($self, $line_ref, $lines) = @_;
	my $line_num = $self->[PML_LINE];

	return unless $self->[PML_MAGIC] and $self->[PML_MAGIC_NEWLINE];
	
	while (1)
	{
		last unless length($$line_ref) or @{$lines};
		$$line_ref = $self->next_line($lines) unless length($$line_ref);
		$$line_ref =~ s/^(\s|\n)+//og;
		last if length $$line_ref;
	}
	
	unless (length $$line_ref)
	{
		$self->warn_error("did not expect EOF, was looking for a char starting from line $line_num");
	}
} # <-- End magic_newline -->
################################################################################
#
# ==== magic_newline_gut ==== ##################################################
#
#   Arguments:
#	1) A PML Object
#	2) A reference to a string
#
#     Returns:
#	None
#
# Description:
#	Removes prefixing and trail spaces and newline
#
################################################################################
sub magic_newline_gut
{
	my ($self, $line_ref) = @_;
	
	return unless $self->[PML_MAGIC] and $self->[PML_MAGIC_NEWLINE];
	
	$$line_ref =~ s/^\s*\n//os;
	$$line_ref =~ s/\n\s*$//os;
} # <-- End magic_newline_gut -->
################################################################################
#
# ==== magic_tab ==== ##########################################################
#
#   Arguments:
#	1) A PML Object
#	2) A reference to a string
#
#     Returns:
#	None
#
# Description:
#	Removes one tab from the begining of each line
#
################################################################################
sub magic_tab
{
	my ($self, $line_ref) = @_;
	
	return unless $self->[PML_MAGIC] and $self->[PML_MAGIC_TAB];
	$$line_ref =~ s/^\t//mog;
} # <-- End magic_tab -->
################################################################################
#
# ==== gut ==== ################################################################
#
#   Arguments:
#	1) A PML Object
#	2) A starting delimiter
#	3) An ending delimiter
#	4) A ref to a string
#	5) A ref to an array to get more lines (optional)
#	6) A flag (true means don't sub gut for ('|")) (optioal)
#
#     Returns:
#	An array of lines that are in between the delimiters
#
# Description:
#	This is a replacement for the orignial gut. It will do a charater by 
#	charter look instead of using regexs
#
################################################################################
sub gut
{
	my ($self, $od, $cd, $line_ref, $lines, $sflag) = @_;
	my (@repository, @gut, $result);
	my ($got_od, $last_char, $last_real_char, $char, $count, $ds);
	my (@sub_gut, @pre_sg, @post_sg);
	my $sub_gut_regex = qr/:=:\((\d+)\):=:/;
	
	@pre_sg = (':', '=', ':', '(');
	@post_sg = (')', ':', '=', ':');
	
	$lines ||= $self->[PML_LINES];
	$last_char = $last_real_char = '';
	$ds  = 0; # do we have a double back slash condition?
	
	while (1)
	{
		unless (@repository) # fill the repository
		{
			last unless length($$line_ref) or @{$lines};
			$$line_ref = $self->next_line($lines)
				unless length $$line_ref;
			length $$line_ref or next;
			push @repository, split(//, $$line_ref);
			$$line_ref = '';
		}
		
		$char = shift @repository;
		defined $char or next;
		
		unless ($got_od)
		{
			unless ($char eq $od) {
				$self->error_syntax (
					"looking for open delimiter '$od' ".
					"but found '$char' instead, near '$char".
					join('', @repository) .
					"'"
				);
			} else {	
				$got_od = 1;
				$count++;
				next;
			}
		}
		
		if ($last_real_char ne '\\' and $char =~ /^(['"])/o and $od ne $1 and not $sflag)
		{
			my $tmp = join '', $1, @repository; undef @repository;
			push @gut, $1, @pre_sg, scalar @sub_gut, @post_sg, $1;
			push @sub_gut, $self->gut($1, $1, \$tmp, $lines);
			$$line_ref = $tmp;
			next;
		}
			
		if ($char eq $od and ($last_real_char ne '\\' or $ds))
		{
			$count++ unless $od eq $cd;
		}
		
		if ($char eq $cd and ($last_real_char ne '\\' or $ds))
		{
			$count--;
			last unless $count;
		}
		
		push @gut, $char;
		
		if ($last_real_char eq '\\' and $char eq '\\') {
			$ds = 1;
		} else {
			$ds = 0;
		}
		
		$last_real_char = $char;
		$last_char = $char unless
			$char =~ /^(\s|\n|\\)/o;
	}
	
	if ($count) {
		$self->error_syntax (
			"I can't seem to find the closing '$cd'"
		);
	}
	
	$$line_ref = join '', @repository if @repository;
	$result = join '', @gut;
	$result =~ s/$sub_gut_regex/$sub_gut[$1]/gos if @sub_gut;
	return $result;
} # <-- End gut -->
################################################################################
#
# ==== next_line ==== ##########################################################
#
#   Arguments:
#	1) PML Object
#	2) An Arrary Reference of Lines
#
#     Returns:
#	1) A line from the Array
#	-- or --
#	2) undef if no more lines
#
# Description:
#	goes through the array of lines trying to find one that we can return.
#	lines that beging with a pound signare skipped. Lines that
#	end with a backslash are joined with the line that follows it.
#
################################################################################
sub next_line
{
	my ($self, $lines) = @_;
	my ($line);
	
	# Check to make sure that we got the correct number of arguments
	$lines ||= $self->[PML_LINES] || undef;
	croak("Usage: next_line(pml_object, array_ref)") unless defined $self and defined $lines;
				
	# Now we loop pulling out lines
	while (@{$lines}) {
		# Get a fresh line to work with
		$line = shift @$lines;
		
		# update the line counter
		if ($lines == $self->[PML_LINES]) {
			$self->[PML_LINE_STR] = 'on line ' . ++$self->[PML_LINE];
			$self->[PML_LINE_STR] .= " from " . $self->[PML_FILE];
		}
		
		# reasons to check next line
		defined $line or next; # this line needs to have something on it
		$line =~ /^\s*#/o and next; # skip if line is a comment
		#length($line) or next;
		
		return $line;		
	}

	return undef;
} # <-- End next_line -->
################################################################################
#
# ==== peek ==== ###############################################################
#
#   Arguments:
#	1) PML Object
#	2) A Regular Expression that you are looking for
#	3) A ref to a string (current line)
#	4) Array Reference (Optional if $self->[PML_LINES] exists)
#
#     Returns:
#	True if that patter will be found; False otherwise
#
# Description:
#	Scans through the array of lines looking for the first charater
#	that is not space or newline and the tries to match the regular
#	expression on the remaining string.
#
################################################################################
sub peek
{
	my ($self, $regex, $line_ref, $lines) = @_;
	my ($i);
	
	if ($$line_ref =~ /(\S+)/o) {
		return $1 =~ $regex ? 1 : undef;
	}
	
	for ($i=0; $i<=$#{$lines}; $i++) {
		next unless $lines->[$i] =~ /(\S+)/o;
		return $1 =~ $regex ? 1 : undef;
	}
} # <-- End peek -->
################################################################################
#
# ==== replace_variable ==== ###################################################
#
#   Arguments:
#	1) A PML Object
#	2) The name of the variable
#
#     Returns:
#	A String
#
# Description:
#	Returns a string with the value of the varable
#
################################################################################
sub replace_variable
{
	my ($self, $vref) = @_;
	my ($index, $v, $x);
	
	# get the inside of the variable
	$v = $self->gut('{', '}', $vref, []);
	
	# does this match a variable regex?
	unless ($v =~ /^$RE_VAR/o) {
		return "\${$v}";
	}
	
	# keep from deep recursion
	$self->_in;

	# look for another variable inside this one
	while ($v =~ s/^$RE_VAR_TEST//o) {
		$x .= $1 if $1;
		$x .= $self->replace_variable(\$v);
	}
	
	# set x back to v if v did not have a variable
	$x .= $v if length $v;
	
	# no longer going to call myself!
	$self->_out;
	
	# now, check once more for allowed charaters
	($v = $x) =~ /$RE_VAR/o or return $v;
	
	
	# now look to see if this is an array index
	if ($v =~ /^(.*?)\[(\d+)\]$/o) {
		$index = $2;
		$v = $1;
		
		unless (ref($self->[PML_V]{$v}) eq 'ARRAY') {
			print STDERR "Variable $v is not an array but you used the index operator on it, the result is a blank string.\n" if $self->[PML_W];
			return '' unless wantarray; return ();
		}
		
		if (defined $self->[PML_V]{$v}[$index]) {
			return $self->[PML_V]{$v}[$index];
		} else {
			print STDERR "the index '$index' to the variable '$v' was used when it had no value\n" if $self->[PML_W];
			return '';
		}
	} elsif ($v =~ /^([^\.]+)\.([^\.]+)$/o) { # Hash index?
		$index = $2;
		$v = $1;
		
		unless (ref($self->[PML_V]{$v}) eq 'HASH') {
			print STDERR "variable '$v' is not a hash, but you used it as one. the result is a blank value\n" if $self->[PML_W];
			return '';
		}
		
		if (defined $self->[PML_V]{$v}{$index}) {
			return $self->[PML_V]{$v}{$index};
		} else {
			print STDERR "the hash key '$index' to the hash '$v' was not set, the result is a blank value\n" if $self->[PML_W];
			return '';
		}
	} elsif (ref ($self->[PML_V]{$v}) eq 'ARRAY') { # whole array?
		return @{$self->[PML_V]{$v}} if wantarray;
		return join ' ', @{$self->[PML_V]{$v}};
	} elsif (ref ($self->[PML_V]{$v}) eq 'HASH') { # whole hash?
		return values %{$self->[PML_V]{$v}} if wantarray;
		return join ' ', values %{$self->[PML_V]{$v}};
	} else { # normal variable
		if (defined $self->[PML_V]{$v}) {
			return $self->[PML_V]{$v};
		} else {
			print STDERR "the variable '$v' was used before it was set, the result is a blank value\n" if $self->[PML_W];
			return '';
		}
	}
} # <-- End replace_variable -->
################################################################################
#
# ==== rel2abs ==== ############################################################
#
#   Arguments:
#	1) A relative path to a file
#	2) Full path to a starting directory [Optional]
#
#     Returns:
#	The full path to that file based on arg2 or cwd
#
# Description:
#	Removes the ./ and ../ from the path
#
################################################################################
sub rel2abs
{
	my ($path, $base) = @_;
	my @path_parts = split(/\//, $path);
	my (@base_parts, $current_part);
	
	$base ||= cwd;
	
	@base_parts = split(/\//, $base);
	
	while ($current_part = shift @path_parts)
	{
		next if $current_part eq '.';
		pop @base_parts if $current_part eq '..';
		push @base_parts, $current_part unless $current_part eq '..';
	}
	
	return '/' . join '/', @base_parts;
} # <-- End rel2abs -->
################################################################################
#
# ==== error ==== ##############################################################
#
#   Arguments:
#	1) A PML Object
#	2) A String
#
#     Returns:
#	None
#
# Description:
#	Prints an error message and exit 1
#
################################################################################
sub error
{
	my ($self, $string) = @_;
	
	print STDERR "PML error on line $self->[PML_LINE] from $self->[PML_FILE]: $string\n";
	exit 1;
} # <-- End error -->
################################################################################
#
# ==== warn_error ==== #########################################################
#
#   Arguments:
#	1) A PML Object
#	2) A String
#
#     Returns:
#	None
#
# Description:
#	Prints an error and returns
#
################################################################################
sub warn_error
{
	my ($self, $string) = @_;
	
	print STDERR "PML error on line $self->[PML_LINE] from $self->[PML_FILE]: $string\n";
} # <-- End warn_error -->
################################################################################
#
# ==== error_syntax ==== #######################################################
#
#   Arguments:
#	1) A PML Object
#	2) An Description of the syntax error
#
#     Returns:
#	None
#
# Description:
#	Reports an error then dies
#
################################################################################
sub error_syntax
{
	my ($self, $message) = @_;
	my ($text);
	
	$text  = "PML Syntax Error " . $self->[PML_LINE_STR] . "\n";
	$text .= "$message\n";
	
	if ($self->[PML_USE_STDERR]) {
		print STDERR $text;
	}
	
	die $text;
} # <-- End error_syntax -->
################################################################################
#
# ==== _in ==== ################################################################
#
#   Arguments:
#	1) A PML Object
#
#     Returns:
#	None
#
# Description:
#	Increments the current Recurse count and check to see if we
#	went over the max.
#
################################################################################
sub _in
{
	my $self = shift;
	
	$self->[PML_RECURSIVE_COUNT]++;
	
	if ($self->[PML_RECURSIVE_COUNT] > $self->[PML_RECURSIVE_MAX]) {
		print STDERR "deep recursion detected.\n";
		print STDERR "max recursion set to " 
			. $self->[PML_RECURSIVE_MAX] . "\n";
		croak("recurse error");
	}
} # <-- End _in -->
################################################################################
#
# ==== _out ==== ###############################################################
#
#   Arguments:
#	1) PML Object
#
#     Returns:
#	None
#
# Description:
#	Lowers the recurse count
#
################################################################################
sub _out
{
	$_[0]->[PML_RECURSIVE_COUNT]--;
} # <-- End _out -->
################################################################################
#
# ==== append ==== #############################################################
#
#   Arguments:
#	1) PML Object
#	2) PML Object to append to object in arg 1
#
#     Returns:
#	None
#
# Description:
#	Appends PML Object 2 to PML Object 1, PML Object 1 takes priority
#	does not append TOKENS though
#
################################################################################
sub append
{
	my ($self, $append) = @_;
	
	%{$self->[PML_INCLUDES]} = (
		%{$self->[PML_INCLUDES]}, 
		%{$append->[PML_INCLUDES]}
	);
	
	%{$self->[PML_MACROS]} = ( 
		%{$self->[PML_MACROS]}, 
		%{$append->[PML_MACROS]}
	);
	
	%{$self->[PML_V]} = (
		%{$self->[PML_V]}, 
		%{$append->[PML_V]}
	);

	return $self;
} # <-- End append -->
################################################################################
#
# ==== _token_id ==== ##########################################################
#
#   Arguments:
#	1) PML::Token Object
#	2) New Token ID (Optional)
#
#     Returns:
#	The Current Token ID
#
# Description:
#	Sets the Token ID to the one given, if any, then returns the ID.
#
################################################################################
sub _token_id
{
	my ($token, $id) = @_;
	
	if (defined $id) {
		$token->[PML_TOKEN_ID] = $id;
	}
	
	return $token->[PML_TOKEN_ID];
} # <-- End _token_id -->
################################################################################
#
# ==== _token_context ==== #####################################################
#
#   Arguments:
#	1) PML::Token Object
#	2) New Context ID (Optional)
#
#     Returns:
#	Current Context ID
#
# Description:
#	Sets the Context ID if given, then returns the context ID
#
################################################################################
sub _token_context
{
	my ($token, $context) = @_;
	
	if (defined $context) {
		unless (
			$context == CONTEXT_SCALAR ||
			$context == CONTEXT_LIST
		) {
			carp "context not scalar or array";
			return $token->[PML_TOKEN_CONTEXT];
		}
		
		$token->[PML_TOKEN_CONTEXT] = $context;
	}
	
	return $token->[PML_TOKEN_CONTEXT] || CONTEXT_SCALAR;
} # <-- End _token_context -->
################################################################################
#
# ==== _token_file_loc ==== ####################################################
#
#   Arguments:
#	1) PML::Token Object
#	2) New File Location ID (Optional)
#
#     Returns:
#	File Location ID
#
# Description:
#	Sets the File Location ID if given, then returns the FLI
#
################################################################################
sub _token_file_loc
{
	my ($token, $fli) = @_;
	
	if (defined $fli) {
		unless (
			$fli == FILE_LOC_FILE or 
			$fli == FILE_LOC_ARG or
			$fli == FILE_LOC_BLOCK
		) { # then 
			carp "file location id is not file, arg or block";
			return $token->[PML_TOKEN_FILE_LOC];
		}
		
		$token->[PML_TOKEN_FILE_LOC] = $fli;
	}
	
	return $token->[PML_TOKEN_FILE_LOC];
} # <-- End _token_file_loc -->
################################################################################
#
# ==== _token_data ==== ########################################################
#
#   Arguments:
#	1) PML::Token Object
#	2) Data (optional)
#
#     Returns:
#	Data
#
# Description:
#	Sets the data section to whatever you give, or returns it
#
################################################################################
sub _token_data
{
	my ($token, $data) = (shift, shift);
	
	if (defined $data) {
		$token->[PML_TOKEN_DATA] = $data;
	}
	
	return $token->[PML_TOKEN_DATA];
} # <-- End _token_data -->
################################################################################
#
# ==== _token_label ==== #######################################################
#
#   Arguments:
#	1) PML::Token Object
#	2) Label (optional)
#
#     Returns:
#	The current label
#
# Description:
#	Sets the label if one is given, return the label
#
################################################################################
sub _token_label
{
	my ($token, $label) = @_;
	
	if (defined $label) {
		$token->[PML_TOKEN_LABEL] = $label;
	}
	
	return $token->[PML_TOKEN_LABEL];
} # <-- End _token_label -->
################################################################################
#
# ==== object_directory ==== ###################################################
#
#   Arguments:
#	1) A PML Variable
#	2) A directory to place objects (optional)
#
#     Returns:
#	Current directory
#
# Description:
#	Sets the object directory if given then returns the object directory
#
################################################################################
sub object_directory
{
	my ($self, $dir) = @_;
	
	if (defined $dir) {
		unless (-d $dir) {
			carp "directory '$dir' does not exists\n";
		} elsif (-w $dir) {
			carp "you don't have permission to write into '$dir'\n";
		} else {
			$self->[PML_OBJ_DIR] = $dir;
		}
	}
	
	return $self->[PML_OBJ_DIR];
} # <-- End object_directory -->
################################################################################
#
#                   B U I L T -- I N -- F U N C T I O N S
#                   ------------------------------------
#
#
#	All built in functions take the following arguments
#
#	1) A PML Object
#	2) A Reference to an array of argument tokens
#	3) A Reference to an array of block tokens
#	4) A Reference to a line (if you need to get more stuff from file)
#	5) A Reference to an array of lines, in case you need more data
#	   from the file. This argument is optional and should default
#	   to $self->[PML_LINES];
#
################################################################################
#
# ==== auto_parse ==== #########################################################
#
#   Arguments:
#	See Above, but in addition to that :
#	1) The name of the function
#	2) The Token ID of the function
#
#     Returns:
#	A Token
#
# Description:
#	Auto Parse is a parser for function that do not provide a parser for
#	themselves. It just makes a generic token, no syntax checking is done.
#
################################################################################
sub auto_parse
{
	my ($self, $a, $b, $line_ref, $lines) = @_;
	my ($options, $name, $id, $token);
	
	$options = pop @_;
	$id = $options->{id};
	$name = $options->{name};
	
	$token = new PML::Token $id;
	$token->data([$name, $a, $b]);
	
	return $token;
} # <-- End auto_parse -->
################################################################################
#
# ==== parse_if ==== ###########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	A List of tokens
#
# Description:
#	Builds tokens needed for an IF statement (function)
#	removes elsif and else statments as needed from the file
#
################################################################################
sub parse_if
{
	my ($self, $a, $b, $line_ref, $lines, $unless) = @_;
	my (@tokens, $regex, $token);
	
	# prepare the regex for speed
	$regex = G_RE_IF;
	
	# make sure we only have one condition
	if ($#{$a} > 1) {
		$self->error_syntax
			("you can only have one condition to a if function");
	} else {
		$a = $a->[0];
	}
	
	# check to see if this is a @if or @unless
	if ($unless) {
		# push a unless token
		$token = new PML::Token TOKEN_NOT;
		$token->data($a);
		push @tokens, $token, $b;
	} else {
		# add the if token
		push @tokens, $a, $b;
	}
	
	# look for else or elsif functions
	while ($self->peek($regex, $line_ref, $lines)) {
		# remove all dead space before the @ marker
		$self->magic_newline($line_ref, $lines);
		
		# remove the @ marker and either the 'else' or 'elsif'
		# leaving $1 set to 'else' or 'elsif'
		$$line_ref =~ s/$regex//o;
		
		# handle the elsif and else
		if ($1 eq 'elsif') {
			my $elsif_a = 
				[$self->parse_arguments($line_ref, $lines)];
			if (@{$elsif_a} > 1) {
				$self->error_syntax
					("you are only allowed to give one condition to elsif");
			}
			
			push @tokens, 
			     $elsif_a->[0], 
			     [$self->parse_block($line_ref, $lines)];
		} elsif ($1 eq 'else') {
			$token = new PML::Token TOKEN_EVAL;
			$token->data(1);
			push @tokens, 
			     $token,
			     [$self->parse_block($line_ref, $lines)];
			last; # nothing allowed after the else
		}
	}
	
	$token = new PML::Token TOKEN_IF;
	$token->data(\@tokens);
	return $token;
} # <-- End parse_if -->
################################################################################
#
# ==== parse_perl ==== #########################################################
#
#   Arguments:
#	1) A PML Object
#	2) The charters between the { and the } after a @perl
#
#     Returns:
#	1 Token
#
# Description:
#	Just grabs the perl code and puts it into a token.
#	This parse function is special because the arguments and block
# 	are not parsed for it. Thus $a and $b are undef
#
################################################################################
sub parse_perl
{
	my ($self, $code) = @_;
	my $token = new PML::Token TOKEN_PERL;
	
	$token->data($code);
	return $token;
} # <-- End parse_perl -->
################################################################################
#
# ==== parse_set ==== ##########################################################
#
#   Arguments:
#	See Above
#	A TOKEN_SET_* token id
#
#     Returns:
#	A Token
#
# Description:
#	Sets the variable to the give value(s)
#
################################################################################
sub parse_set
{
	my ($self, $a, $b, $line_ref, $lines, $set) = @_;
	my $token;
	
	# make sure that we were given a variable name to set
	unless (defined $a->[0]) {
		$self->error_syntax(
			"you must give a variable name to set"
		);
	}
	
	$token = new PML::Token TOKEN_SET;
	$token->data([$set, @$a]);
	return $token;
} # <-- End parse_set -->
################################################################################
#
# ==== parse_include ==== ######################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	Tokens
#
# Description:
#	Returns a include token after parsing a file and keeping it's tokens
#
################################################################################
sub parse_include
{
	my ($self, $a, $b, $line_ref, $lines) = @_;
	my @args = $self->tokens_execute($a);
	my ($found, @tokens, $token);
	
	unless (@args)
	{
		$self->error("syntax error, the include function needs a list of files to include.\n");
	}
	
	foreach my $file (@args)
	{
		$found = 0;
		
		unless ($file =~ m{^(?:\.(?:\./|/)|/)}o)
		{
			foreach my $path (@inc)
			{
				if (-e "$path/$file")
				{
					$found = 1;
					$file = "$path/$file";
					last;
				}
			}
		}
		else
		{
			if (-e $file)
			{
				$found = 1;
				$file = rel2abs($file) unless $file =~ m(^/)o;
			}
		}
		
		unless ($found)
		{
			$self->error("can't find included file \"$file\". inc contains ". join(' ', @inc). "\n");
		}
				
		my $inc_parser = new PML;
		$inc_parser->parse($file);
		
		if ($DEBUG)
		{
			print STDERR "Including file $file\n";
			print STDERR "Before including $file the macro list is:\n";
			print STDERR "\t$_\n" foreach sort keys %{$self->[PML_MACROS]};
			print STDERR "Before including $file the includes list is:\n";
			print STDERR "\t$_\n" foreach sort keys %{$self->[PML_INCLUDES]};
		}

		$self->[PML_INCLUDES]{$file} = $inc_parser->[PML_TOKENS];
		$self->append($inc_parser);
		
		if ($DEBUG)
		{
			print STDERR "After including $file the macro list is:\n";
			print STDERR "\t$_\n" foreach sort keys %{$self->[PML_MACROS]};
			print STDERR "After including $file the includes list is:\n";
			print STDERR "\t$_\n" foreach sort keys %{$self->[PML_INCLUDES]};
		}
			
		push(@tokens, $file);
	}
	
	$token = new PML::Token TOKEN_INCLUDE;
	$token->data(\@tokens);
	return $token;
} # <-- End parse_include -->
################################################################################
#
# ==== parse_macro ==== ########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	A Token
#
# Description:
#	Sets a MACRO_TOKEN
#
################################################################################
sub parse_macro
{
	my ($self, $a, $b, $line_ref, $lines) = @_;
	
	unless (defined $a->[0])
	{
		$self->error("syntax Error, you must give the name of the macro\n");
	}
	
	my $name = $self->tokens_execute(shift @$a);
	
	if (exists $self->[PML_MACROS]{$name} and $self->[PML_W])
	{
		print STDERR "Macro \"$name\" was redfined ", $self->[PML_LINE_STR], "\n";
	}
	
	$self->[PML_MACROS]{$name} = [$a, $b];
	return undef;
} # <-- End parse_macro -->
################################################################################
#
# ==== parse_warning ==== ######################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	None
#
# Description:
#	Changes the warning flag
#
################################################################################
sub parse_warning
{
	my ($self, $a, $b, $line_ref, $lines) = @_;
	
	unless (@$a == 1)
	{
		$self->error("syntax error, you must give one boolean flag to the warning function.\n");
	}
	
	$self->warning($self->tokens_execute($a->[0]) || 0);
	return undef;
} # <-- End parse_warning -->
################################################################################
#
# ==== parse_foreach ==== ######################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	A FOREACH_TOKEN
#
# Description:
#	Parses the foreach pml function
#
################################################################################
sub parse_foreach
{
	my ($self, $a, $b, $line_ref, $lines) = @_;
	my $token;
	
	unless (@$a)
	{
		$self->error("syntax error, you need to give some arguments to the foreach function.\n");
	}
	
	$token = new PML::Token TOKEN_FOREACH;
	$token->data([$a, $b]);
	return $token;
} # <-- End parse_foreach -->
################################################################################
#
# ==== parse_need ==== #########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	None
#
# Description:
#	Loads the modules that need to be loaded, if the are not alread loaded
#
################################################################################
sub parse_need
{
	my ($self, $a, $b, $line_ref, $lines) = @_;
	my @modules = $self->tokens_execute($a);
	
	foreach (@modules)
	{
		push @{$self->[PML_NEED_LIST]}, $_;
		eval "require PML::" . $_;
		
		if ($@)
		{
			$self->error("error loading module \"$_\", make sure you entered it correctly");
		}
		
		eval "PML::" . $_ . "->init(\$self)";
		
		if ($DEBUG and $@)
		{
			print STDERR "error from PML::$_->init: $@\n";
		}
	}
	
	return undef;	
} # <-- End parse_need -->
################################################################################
#
# ==== parse_while ==== ########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	Tokens
#
# Description:
#	The while and until functions
#
################################################################################
sub parse_while
{
	my ($self, $a, $b, $line_ref, $lines, $until) = @_;
	my (@tokens, $token);
	
	# check to make sure there no more then one condition
	if (@{$a} > 1) {
		error_syntax("you can only supply one condition to the while/until function");
	} else {
		$a = $a->[0];
	}
	
	# create the token, negate the condition if this is until
	if ($until) {
		$token = new PML::Token TOKEN_NOT;
		$token->data($a);
		push @tokens, $token, $b;
	} else {
		push @tokens, $a, $b;
	}
	
	$token = new PML::Token TOKEN_WHILE;
	$token->data(\@tokens);
	return $token;
} # <-- End parse_while -->
################################################################################
#
# ==== parse_skip ==== #########################################################
#
#	1) A PML Object
#	2) The charters between the { and the } after a @perl
#
#     Returns:
#	1 Token
#
# Description:
#	Keeps PML from parsing any text in the skip block
#
################################################################################
sub parse_skip
{
	my ($self, $skip) = @_;
	my $token = new PML::Token TOKEN_SKIP;
	
	$token->data($skip);
	return $token;
} # <-- End parse_skip -->
################################################################################
#
# ==== parse_wrap ==== #########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	A wrap token
#
# Description:
#	Wraps text to a certain number of chars per line
#
################################################################################
sub parse_wrap
{
	my ($self, $a, $b, $line_ref, $lines) = @_;
	my $token = new PML::Token TOKEN_WRAP;
	
	unless (@$a <= 3) {
		$self->error_syntax (
			"wrap function only takes 3 arguments"
		);
	}
	
	$token->data([$a->[0]||80, $a->[1]||'', $a->[2]||'', $b]);
	return $token;
} # <-- End parse_wrap -->
################################################################################
#
# ==== parse_rib ==== ##########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	A rib token
#
# Description:
#	Parses the rib function
#
################################################################################
sub parse_rib
{
	my ($self, $a, $b, $line_ref, $lines) = @_;
	my $token = new PML::Token TOKEN_RIB;
	
	unless (@$a == 1) {
		$self->error_syntax (
			"the rib function needs one argument"
		);
	}
	
	$token->data([$a->[0], $b]);
	return $token;
} # <-- End parse_rib -->
################################################################################
#
# ==== parse_loop_int ==== #####################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	A Token
#
# Description:
#	Creates a token for @next, @last and @redo
#
################################################################################
sub parse_loop_int
{
	my ($self, $a, $b, $line_ref, $lines, $name) = @_;
	my $token = new PML::Token TOKEN_LOOP_INT;
	
	# make sure that we are only getting one label
	if (@$a > 1) {
		$self->error_syntax("you can only give one label to $name");
	}
	
	# set the data to be the name (next,redo or last) and the label ($a)
	$token->data([$name, $a->[0] || '']);
	
	return $token;
} # <-- End parse_loop_int -->
################################################################################
#
#                   B U I L T -- I N -- T O K E N S
#                   ------------------------------------
#
#
#	All built in tokens take the following arguments
#
#	1) A PML Object
#	2) A PML::Token Object
#
################################################################################
#
# ==== token_eval ==== #########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	A String
#
# Description:
#	Replaces all variables in the string and returns it
#
################################################################################
sub token_eval
{
	my ($self, $token) = @_;
	my $string = $token->data;
	my $result = '';
	
	# check to make sure that we have a string
	return undef unless defined $string and length($string);
	
	# replace variable names with the value
	while ($string =~ s/^$RE_VAR_TEST//o) {
		$result .= $1 if $1;
		$result .= $self->replace_variable(\$string);
	}
	
	# if we found none then set the result to the string
	$result .= $string if length $string;
	
	# replace backslashed charaters with their actual ASCII codes
	$result =~ s/(?<!\\)\\(0\d+|c\w|x\w+|[nrtfbaeulULQE])/"\"\\$1\""/oeeg;
	
	# Remove some tabs if asked
	$result =~ s/[\t]+\\T//og;
	
	# remove any remaining backslashes unless we are processing
	# the arguments of a function call. If that is the case
	# we will surly get another change to remove the backslash
	# when charater is used in the block or body.
	$result =~ s/(?<!\\)\\//og unless $token->file_loc == FILE_LOC_ARG;
	
	# and return the result
	return $result;
} # <-- End token_eval -->
################################################################################
#
# ==== token_if ==== ###########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	Whatever is in the if block or elsif block or else block
#
# Description:
#	Check to see if the args are true then executes the correct tokens
#
################################################################################
sub token_if
{
	my ($self, $token) = @_;
	my (@tokens) = @{$token->data};
	my ($a, $b, $rv, $tmp);
	
	#
	# now loop trying to execute a block of PML
	#
	while(1)
	{
		#
		# check to make sure there are at least two tokens
		#
		last unless @tokens >= 2;
		
		# 
		# get the argument and block tokens from the tokens array
		#
		($a, $b, @tokens) = @tokens;
		
		#
		# check to see if this token return a true value
		#
		if ($self->tokens_execute($a))
		{
			# if we get here then we get to execute
			# the block and return what it returns
			return $self->tokens_execute($b) || undef;
			
			#foreach my $token (@$b)
			#{
			#	$tmp = $self->token_execute($token);
			#	$rv .= $tmp if defined $tmp;
			#}
			
			#return $rv;	
		}
	}
	
	#
	# if we get this far there were no succesfull tokens
	#
	return undef;
} # <-- End token_if -->
################################################################################
#
# ==== token_not ==== ##########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	The inverse of the inner token
#
# Description:
#	This token comes with one other token to execute
#	The unless token returns the inverse of executing that token
#
################################################################################
sub token_not
{
	my ($self, $token) = @_;
	return not scalar $self->tokens_execute($token->data);
} # <-- End token_not -->
################################################################################
#
# ==== token_perl ==== #########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	What ever is the last value in the perl code
#
# Description:
#	Evals the perl code and returns it
#
################################################################################
sub token_perl
{
	my ($self, $token) = @_;
	my %v = %{$self->[PML_V]};
	my $code = $token->data;
	my @rv;
	
	@rv = eval "$code";
	
	if ($@ and $self->warning) {
		print STDERR "An error occured in your perl code: $@\n";
	}
	
	%{$self->[PML_V]} = %v;
	
	local $^W=0; # bug in perl? next line causes "Use of uninitialized value at PML.pm"
	if ($token->context == CONTEXT_LIST) {
		return @rv;
	} else {
		return join '', @rv;
	}
} # <-- End token_perl -->
################################################################################
#
# ==== token_set ==== ##########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	None
#
# Description:
#	Sets the variable to the value(s) in the token(s)
#
################################################################################
sub token_set
{
	my ($self, $token) = @_;
	my ($sub_token, $v, @values) = @{$token->data};
	my ($array, $hash, $index, $ref, $i);
	
	$v = $self->tokens_execute($v);
	
	# reject the variable name if it does not match
	# the standard variable naming procedures
	if ($v !~ /^$RE_VAR/o or $v =~ /[\$\{\}]/o or $v =~ /^(\.|ARGV)$/o) {
		print STDERR "The variable name '$v' contains illeagal charaters\n";
		croak("bad variable name");
	}
	
	# execute the tokens and get the real data
	@values = $self->tokens_execute(@values);
	
	if ($v =~ /^(.*?)\[(\d+)\]$/o) {
		$array = $1; $index = $2;
		
		if (
			defined $self->[PML_V]{$array} and
			ref($self->[PML_V]{$array}) ne 'ARRAY'
		) {
			print STDERR "pml does not support complexe data structures, but you tried to set one\n";
			return undef;
		}
		
		$ref = \$self->[PML_V]{$array}[$index];
	} elsif ($v =~ /^([^\.]+)\.([^\.]+)$/o) {
		$hash = $1; $index = $2;

		if (
			defined $self->[PML_V]{$hash} and
			ref($self->[PML_V]{$hash}) ne 'HASH'
		) {
			print STDERR "pml does not support complexe data structures, but you tried to set one\n";
			return undef;
		}
		
		$ref = \$self->[PML_V]{$hash}{$index};
	} else {
		$self->[PML_V]{$v} = '' unless exists $self->[PML_V]{$v};
		$ref = \$self->[PML_V]{$v};
	}
	
	if ($sub_token == TOKEN_SET_SET) {
		if (@values > 1) {
			if ($array or $hash) {
				print STDERR "you can only assign one value to a array index or hash key\n";
				$$ref = $values[-1];
			} else {
				$self->[PML_V]{$v} = [@values];
			}
		} else {
			$$ref = $values[0];
		}
	} elsif ($sub_token == TOKEN_SET_IF) {
		return undef if defined $ref and $$ref;
		$token = new PML::Token TOKEN_SET;
		$token->data([TOKEN_SET_SET, $v, @values]);
		$self->token_set($token);
	} elsif ($sub_token == TOKEN_SET_APPEND) {		
		if (not $array and not $hash and ref $self->[PML_V]{$v} eq 'ARRAY') {
			push(@{$self->[PML_V]{$v}}, @values);
		} else {
			foreach $i (@values) {
				$i =~ s/^\s+//o;
				defined $$ref and $$ref =~ s/\s+$//o;
				$$ref .= " $i";
			}
		}
	} elsif ($sub_token == TOKEN_SET_PREPEND) {
		if (not $array and not $hash and ref $self->[PML_V]{$v} eq 'ARRAY') {
			unshift(@{$self->[PML_V]{$v}}, @values);
		} else {
			foreach $i (@values) {
				$i =~ s/\s+$//o;
				defined $$ref and $$ref =~ s/^\s+//o;
				$$ref = "$i $$ref";
			}
		}
	} elsif ($sub_token == TOKEN_SET_CONCAT) {
		if (not $array and not $hash and ref($self->[PML_V]{$v}) eq 'ARRAY') {
			push(@{$self->[PML_V]{$v}}, @values);
		} else {
			foreach $i (@values) {
				$i =~ s/^\s+//o;
				defined $$ref and $$ref =~ s/\s+$//o;
				$$ref .= "$i";
			}
		}
	} else {
		print STDERR "WOAH! Unknown Set Sub Token \"$sub_token\", you found a bug in PML.\n";
		croak "PML Internal Error";
	}
	
	return undef;
} # <-- End token_set -->
################################################################################
#
# ==== token_include ==== ######################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	None
#
# Description:
#	runs the tokens for the included file
#
################################################################################
sub token_include
{
	my ($self, $token) = @_;
	my @files = @{$token->data};
	my $file;
	my $rv = '';
	
	local $^W=0; #FIXME temp fix for Use of uninitialized value
	
	foreach $file (@files)
	{
		next unless defined $file;
		$rv .= $self->tokens_execute($_) foreach @{$self->[PML_INCLUDES]{$file}};
		print STDERR "Executed included file $file\n" if $DEBUG;
	}
	
	print STDERR "The included text to be returned is:\n$rv\n" if $DEBUG;
	return $rv || undef;
} # <-- End token_include -->
################################################################################
#
# ==== token_macro ==== ########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	What ever the macro returns
#
# Description:
#	Runs the tokens for the macro
#
################################################################################
sub token_macro
{
	my ($self, $token) = @_;
	my ($name, @args) = @{$token->data};
	my ($argument, $save_argv, $result, %save);
	
	# keep from going to deep in recursion
	$self->_in;
	
	# first make sure that the macro exists
	unless (exists $self->[PML_MACROS]{$name}) {
		print STDERR "Macro \"$name\" was not defined, possible bug in PML\n";
		croak("PML Internal Error");
	}
	
	# process the list of argument names from the macro definition
	my @arg_names = $self->tokens_execute (
		$self->[PML_MACROS]{$name}->[0]
	);
	
	# look for one name called _ALL_ and remove it
	# this is for backwards compatability before ARGV existed
	if (defined $arg_names[0] and $arg_names[0] eq '_ALL_') {
		shift @arg_names;
	}
	
	# save the values of the arguments so
	# we can restore them at the end of the 
	# macro call
	foreach $argument (@arg_names) {
		$save{$argument} = $self->[PML_V]{$argument};
	}
	
	# make sure that the macro was called with at least
	# the number of arguments as there are names
	if (not (@args >= @arg_names) and $self->[PML_W]) {
		print STDERR "Macro '$name' called with wrong number of arguments\n";
	}

	# now, place the arguments into the correct variables
	foreach $argument (@arg_names) {
		$self->[PML_V]{$argument} = $self->tokens_execute(shift @args);
	}
	
	# save the current value of ARGV incase this is a macro call
	# inside another macro call.
	$save_argv = $self->[PML_V]{'ARGV'};
	
	# all remaing arguments are put into ARGV and _ALL_
	# the _ALL_ part is for backward compatiblity and will be
	# removed someday
	if (@args) {
		$self->[PML_V]{'ARGV'} = [$self->tokens_execute(@args)];
		$self->[PML_V]{'_ALL_'} = $self->[PML_V]{'ARGV'};
	}
	
	# don't complain when we give join undef
	local $^W=0;
	
	# execute the block of the macro
	$result =  join '', $self->tokens_execute($self->[PML_MACROS]{$name}[1]);

	# restore the ARGV variable
	$self->[PML_V]{'ARGV'} = $save_argv;
	
	# restore the variables in the arguments
	foreach $argument (keys %save) {
		$self->[PML_V]{$argument} = $save{$argument};
	}
	
	# restore the rescurse count
	$self->_out;
	
	# put the result into the output stream
	return $result;
} # <-- End token_macro -->
################################################################################
#
# ==== token_variable ==== #####################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	1 or more values or undef
#
# Description:
#	tries to expand variable
#
################################################################################
sub token_variable
{
	my ($self, $token) = @_;
	my $v = $token->data;
	my @result;
	
	while ($v =~ s/^$RE_VAR_TEST//o) {
		push @result, $1 if $1;
		push @result, $self->replace_variable(\$v);
	}
	
	# set result to v if there is something in v
	push @result, $v if length $v;
	
	if ($token->context == CONTEXT_LIST) {
		return @result;
	} else {
		return join '', @result;
	}
} # <-- End token_variable -->
################################################################################
#
# ==== token_foreach ==== ######################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	The code from the block
#
# Description:
#	Executes the block tokens one time for each of the arguments,
#	setting the variable "." to the name of the argument
#
################################################################################
sub token_foreach
{
	my ($self, $token) = @_;
	my ($a, $b) = @{$token->data};
	my @args = $self->tokens_execute($a);
	my ($savedot, $savelabel, $havelabel, $rv);
	
	# protect from deep recursion
	$self->_in;
	
	# save off the old value of '.'
	$savedot = $self->[PML_V]{'.'};
	
	# if we have a label, use it along with '.'
	if ($havelabel = $token->label) {
		$savelabel = $self->[PML_V]{$havelabel};
	}
	
	# add to the count of loops
	$self->[PML_LOOP_COUNTERS]{'foreach'}++;
	
	foreach my $arg (@args) {
		$self->[PML_V]{'.'} = $arg;
		$self->[PML_V]{$havelabel} = $arg if $havelabel;
		$rv .= join('', $self->tokens_execute($b));
		# see if that last call died
		if ($self->[PML_DIE_MESSAGE]) {
			if ($self->[PML_DIE_MESSAGE] =~ /$RE_LOOP_INT/) {
				# the die was a next, last or redo
				if (not $2 or $2 eq $token->label) {
					$self->[PML_DIE_MESSAGE]='';
					if    ($1 eq 'next') {next}
					elsif ($1 eq 'redo') {redo}
					elsif ($1 eq 'last') {last}
				} else {
					die $self->[PML_DIE_MESSAGE];
				}
			} else {die $self->[PML_DIE_MESSAGE]}
		}
	}
	
	# we are out of the loop
	$self->[PML_LOOP_COUNTERS]{'foreach'}--;
	
	# restore the variable stored in havelabel
	$self->[PML_V]{$havelabel} = $savelabel if $havelabel;
	
	# restore the value of the '.'
	$self->[PML_V]{'.'} = $savedot;
	
	# stop recursion protection
	$self->_out;
	
	return $rv || undef;
} # <-- End token_foreach -->
################################################################################
#
# ==== token_while ==== ########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	A String
#
# Description:
#	Repeates the block while the condition is true
#
################################################################################
sub token_while
{
	my ($self, $token) = @_;
	my ($condition, $block) = @{$token->data};
	my $rv = '';
	
	# say that we are in a loop
	$self->[PML_LOOP_COUNTERS]{'while'}++;
	
	local $^W=0;
	while (scalar $self->tokens_execute($condition)) {
		$rv .= join '', $self->tokens_execute($block);
		if ($self->[PML_DIE_MESSAGE]) {
			if ($self->[PML_DIE_MESSAGE] =~ /$RE_LOOP_INT/) {
				# the die was a next, last or redo
				if (not $2 or $2 eq $token->label) {
					$self->[PML_DIE_MESSAGE]='';
					if    ($1 eq 'next') {next}
					elsif ($1 eq 'redo') {redo}
					elsif ($1 eq 'last') {last}
				} else {
					die $self->[PML_DIE_MESSAGE];
				}
			} else {die $self->[PML_DIE_MESSAGE]}
		}

	}
	
	# done with the loop
	$self->[PML_LOOP_COUNTERS]{'while'}--;
	
	return $rv || undef;
} # <-- End token_while -->
################################################################################
#
# ==== token_skip ==== #########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	The skip text
#
# Description:
#	just returns the text in the skip block
#
################################################################################
sub token_skip
{
	return $_[1]->data || undef;
} # <-- End token_skip -->
################################################################################
#
# ==== token_wrap ==== #########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	Text wrapped
#
# Description:
#	Wraps the text
#
################################################################################
sub token_wrap
{
	my ($self, $token) = @_;
	my ($c, $f, $s, $b) = @{$token->data};
	my ($text, $result);
	
	$c = $self->tokens_execute($c);
	$f = $self->tokens_execute($f);
	$s = $self->tokens_execute($s);
	
	$Text::Wrap::columns = $c;
	
	$text = join '', $self->tokens_execute($b);
	$text =~ s/(?<!\n)\n(?!\n)/ /go;
	
	while ($text =~ /([^\n]+)?(\n+)?/go) {
		if ($1) {
			$result .= wrap($f, $s, $1);
		}
		
		if ($2) {
			$result .= $2;
		}
	}
	
	return $result;
} # <-- End token_wrap -->
################################################################################
#
# ==== token_rib ==== ##########################################################
#
#   Arguments:
#	See Above
#
#     Returns:
#	The text in the block or the first argument
#
# Description:
#	replace if blank token executer
#
################################################################################
sub token_rib
{
	local ($^W)=0;
	my ($self, $token) = @_;
	my ($a, $b) = @{$token->data};
	my $block = join '', $self->tokens_execute($b);
	
	return $block || $self->tokens_execute($a) || undef;
} # <-- End token_rib -->
################################################################################
#
# ==== token_magic_macro ==== ##################################################
#
#   Arguments:
#	1) A PML Object
#	2) A PML::Token Object
#
#     Returns:
#	Whatever the macro call returns
#
# Description:
#	Replaces all variables in the macro name untill there are none
#	left, the calls that macro if it exists
#
################################################################################
sub token_magic_macro
{
	my ($self, $token) = @_;
	my ($eval_token, $name);
	my ($func, $a) = @{$token->data};
	
	# first build a token to eval the macro name
	$eval_token = new PML::Token TOKEN_EVAL;
	$eval_token->data($func);
	
	# now get the name of the macro
	$name = $self->tokens_execute($eval_token);
	
	# make sure there is a macro called $name
	unless (exists $self->[PML_MACROS]{$name}) {
		if ($self->warning) {
			print STDERR "you called a macro with a variable in it's name, the name resolved to '$name' but there is no macro by that name\n";
		}
		return '';
	}
	
	# if we get here we can let token_macro do the work for us
	$token->id(TOKEN_MACRO);
	$token->data([$name, $a]);
	
	return scalar $self->tokens_execute($token);
} # <-- End token_magic_macro -->
################################################################################
#
# ==== token_loop_int ==== #####################################################
#
#   Arguments:
#	1) PML Object
#	2) PML::Token
#
#     Returns:
#	Nothing
#
# Description:
#	Dies if we are in a loop
#
################################################################################
sub token_loop_int
{
	my ($self, $token) = @_;
	my ($name, $label) = @{$token->data};
	
	# if we have a label then resolve it
	$label = $self->tokens_execute($label) if $label;
	$label ||= '';
	
	# check to see if we are in a loop
	if (grep {$_>=1} values %{$self->[PML_LOOP_COUNTERS]}) {
		die "$name:$label";
	} else { # we are not in a loop so we go all the way back up to execute
		if ($self->warning) {
			print STDERR "using \@$name() outside of a loop can be messy\n";
		}; 
		die "$name:tc";
	}
	
	return undef;
} # <-- End token_loop_int -->
################################################################################
#
# ==== AUTOLOAD ==== ###########################################################
#
#   Arguments:
#	1) Args going to orig method call
#
#     Returns:
#	What ever the orig method call would return
#
# Description:
#	Helps map method calls to subs
#
################################################################################
AUTOLOAD
{	
	my ($class, $method) = ($AUTOLOAD =~ /^(.*)::(.*)$/);
	
	if ($class eq 'PML::Token') {
		if ($method eq 'id') {
			return _token_id(@_);
		} elsif ($method eq 'context') {
			return _token_context(@_);
		} elsif ($method eq 'file_loc' or $method eq 'fli') {
			return _token_file_loc(@_);
		} elsif ($method eq 'data') {
			return _token_data(@_);
		} elsif ($method eq 'label') {
			return _token_label(@_);
		} else {
			carp "unknown PML::Token method '$method'";
			return undef;
		}
	} else {
		carp "unknown PML method '$method'";
		return undef;
	}
} # <-- End AUTOLOAD -->
################################################################################
#
# ==== DESTROY ==== ############################################################
#
#   Arguments:
#	1) Object to destroy
#
#     Returns:
#	None
#
# Description:
#	Cleans up after object
#
################################################################################
DESTROY
{

} # <-- End DESTROY -->
################################################################################
#                              END-OF-MODULE                                   #
################################################################################
1;
