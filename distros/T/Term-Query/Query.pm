# Term::Query.pm				-*- perl -*-
#
#    Copyright (C) 1995  Alan K. Stebbens <aks@hub.ucsb.edu>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# $Id: Query.pm,v 1.1.1.1 1996/08/09 21:39:25 stebbens Exp $
# Author: Alan K. Stebbens <aks@hub.ucsb.edu>
#
#
# query 	-- generalized query routine
#
# query_table 	-- perform multiple queries (given an array of info)
#
# query_table_set_defaults
#		-- set all named variable's to their default values.
#
# query_table_process
#		-- process a table of queries
#
# Note: This module uses the Array::PrintCols module (by the same author).

package Term::Query;

require 5.001;

use Exporter; 

@ISA = (Exporter);
@EXPORT_OK = qw( query 
		 query_table 
		 query_table_set_defaults
		 query_table_process 
	       );

use Carp;
use Array::PrintCols;

###############
#
# $result = query($prompt, $flags, [optional fields])
#
# Ask a question, prompting with $prompt (unless STDIN is not tty).
# Validate the answer based on $flags below.
#
#
# The following flags indicate the type or attribute of the value
#  r   - an answer is required
#  Y   - the question requires a "yes" or "no", defaulting to "yes"
#  N   - the question requires a "yes" or "no", defaulting to "no"
#  i   - the input is an integer
#  n   - the input is a number (possibly a real number)
#  H   - do *not* treat '?' as a request for help (note, this disables
#        any help, unless implemented in the "after" subroutine).
#
# The following flags indicate that the next argument is:
#  a   - a subroutine which is invoked *After* the input is read, but 
#	 prior to doing any other checks; if it returns false, the input
#        is rejected.
#  b   - a subroutine which is invoked *Before* the input is read, which
#        generally prepares for the input; if it returns false, then no
#        input is accepted; if it returns undef, an EOF is assumed.
#  d   - the next argument is a Default input, used if the actual input
#  	 is the empty string.
#  h   - the next argument is a Help string to print in response to "?"
#  I   - the next argument is the input "method" ref: if it is a scalar 
#	 value, then no read is performed and this value is used as if 
#	 it has been entered by the user; if it is a CODE ref, then the 
#	 sub is invoked to obtain its return value as the input.
#  J   - same as I, except that if the initial value returned by the
#        next argument reference is unacceptable for any reason, 
#	 solicit a new, proper value from STDIN.  (Mnemonic: "jump" into
#	 query with an initial value).
#  k   - the next argument is a table reference of allowable keywords
#	 (mnemonic: check a Keywword list).
#  K   - the next argument is a table reference of disallowed keywords
#	 (mnemonic: check against a Keyword list).
#  m   - the next argument is a Match pattern (regexp)
#  l   - the next argument is a maximum Length value
#  V   - the next argument is a variable name or *reference* to receive 
#        the value; if it is a name (a string) and unqualified, it is
#	 qualified at the package level outside of Query.pm.
#
# The ordering of the arguments must match the ordering of their
# corresponding flags.
# 
# The ordering of the flags is also important -- it determines the order in
# which the various checks are made.  For example, if the flags are
# given in this order: 'alm', then the $after sub is invoked first, then the
# length check is made, then the $match test is made.
#
# Of course, the 'b' flag (and the corresponding $before sub) is always
# invoked before doing any input.
#
# Returns undef on EOF.
# Otherwise, the result is the input.

%query_flags = (
	'a', sub { $after = shift(@_);
		   &add_check("after"); },

	'b', sub { $before = shift(@_); },

	'd', sub { $default = shift(@_);
		   &add_check(qw(default	null)); },

	'h', sub { $help = shift(@_);
		   &add_check(qw(help		null)); },

	'H', sub { $nohelp++; 
		  $check_done{"help"}++;},	# don't do any help

	'i', sub { $integer++;
		   &add_check(qw(int		null strip default help)); },

	'I', sub { $inref = shift(@_); 
		   $inref_flag++; },

	'J', sub { $inref = shift(@_); 
		   $inref_flag++; 
		   $inref_once++; },

	'k', sub { $keys = shift(@_);
		   ref($keys) eq 'ARRAY' or 
		       (croak "query: The k flag needs an array reference argument.\n");
		   &add_check(qw(key		null strip default help)); },

	'K', sub { $notkeys = shift(@_);
		   ref($notkeys) eq 'ARRAY' or 
		       (croak "query: The K flag needs an array reference argument.\n");
		   &add_check(qw(nonkey		null strip default help)); },

	'l', sub { $maxlen = shift(@_);
		   &add_check(qw(maxlen		null default help)); },

	'm', sub { $match = shift(@_);
		   &add_check(qw(match		null default help)); },

	'n', sub { $number++;
		   &add_check(qw(num		null strip default help)); },

	'N', sub { $no++;
		   &add_check(qw(yesno		null strip default help)); },

	'r', sub { $required++;
		   &add_check(qw(req		null default help)); },

	's', sub { $strip++;
		   &add_check(qw(strip		null default help)); },

	'V', sub { $variable = shift(@_); 
		   ref($variable) eq 'SCALAR' or 
		   (ref($variable) eq '' && 
		    $variable =~ /^((\w+)?(::|'))?\w+$/) or
		       (croak "query: The V flag needs a variable name or reference.\n"); },

	'Y', sub { $yes++;
		   &add_check(qw(yesno		null strip default help)); },

	);

$need_arg_codes = 'abdhIkKlmV';		# list of codes which need an argument

# This is an array of check "codes", and corresponding anonymous subs
# which, when invoked, should return one of the values (undef, '', 1)
# indicating how to proceed with the input.
#
# The sub "add_check", when invoked as part of the flag parsing (see
# above), causes the codes below to be inserted into the @checks array,
# which is then processed for each input.

%check_code = (	
	'after',	\&check_after,
	'default',	\&check_default,
	'help',		\&check_help,
	'int',		\&check_integer,
	'key',		\&check_keys,
	'maxlen',	\&check_length,
	'match',	\&check_match,
	'nonkey',	\&check_nonkeys,
	'num',		\&check_number,
	'req',		\&check_required,
	'strip',	\&strip_input,
	'yesno',	\&check_yesorno,
	'null',		\&check_null,
       );

# This variable controls how the keyword matching is done.

$Case_sensitive = '';	

$Force_Interactive = '';		# set to force interactive behaviour

##################################################################################
#
# 	&query($prompt, $flags, @optional_args)
#
# Returns
#
#   undef	EOF on input
#   <anything else as the result>
#

sub query {
  local( $prompt ) = shift;
  local( $flags ) = shift;		# there may be other arguments
  local( $help, $required, $default, $match, $maxlen, $keys, $notkeys );
  local( $yes, $no, $integer, $number, $strip, $after, $before, $inref );
  local( $inref_once, $inref_flag, $variable );
  local( $c, $ev, $input );
  local( @flags ) = split(//,$flags);
  local( @checks, $check, $result );
  local( %check_done );		# make sure this gets reset

  foreach $c ( @flags ) {
    $ev = $query_flags{$c} or 
    	(croak "query: Unknown query flag '$c'\n");
    &$ev;			# set a flag, or get the next argument
  }

  &add_check(qw( help null default ));	# these checks are done
					# by default (unless disabled)

  # setup a default, depending on type
  $default = $yes ? 'yes' : 'no' if $yes or $no;

  $help .= "\n" if $help && substr($help,-1) ne "\n";

  Query:while (1) {
    if (length($before)) {
	&$before or last;	# check $before sub first
    }
    if ($inref_flag) {		# do we have a reference?
	$input = &deref($inref);
	$inref_flag = '' if $inref_once;	# kill flag if "once"
    } else {
	if (-t STDIN or $Force_Interactive) {	# interactive?
	    print $prompt;
	    print " " unless substr($prompt, -1) eq ' ';
	    if ($default ne '') {
		my($def) = &deref($default);
		print "[$def] ";
	    }
	}
	$input = <STDIN>;
	print "\n" if !-t STDIN and $Force_Interactive;
    }

    # Now process all the check expressions.  If any return undef, then
    # return from this routine with undef.  If a null or zero return is 
    # made, then reject the input.  Otherwise, it passes.

    foreach $check ( @checks ) {
      $result = &$check;		# process the check
      return undef unless defined($result);	# was the result undef?

      # Perform the next test if this one was okay
      next if $result;

      # If $inref_flag is set (I flag), don't loop
      return undef 	if $inref_flag; 

      # don't try looping on non-interactive input
      return undef unless -t STDIN or $Force_Interactive;	

      print "Please try again, or enter \"?\" for help.\n";
      next Query;		# do another query
    }
    last Query;			# all tests passed
  }
  &define_var($variable, $input); # assign a variable (maybe)
  return $input;		# return with input
}

#############################
#
#	&deref ($possible_ref)
#
# If the $possible_ref is a reference, dereference it
# correctly.

sub deref {
    my($ref) = shift;
    my($type) = ref($ref);
    return $ref 	if $type eq '';		# not a reference
    return $$ref 	if $type eq 'SCALAR';	# a scalar 
    return &$ref 	if $type eq 'CODE';	# a subroutine
    return @$ref	if $type eq 'ARRAY';	# an array
    return %$ref	if $type eq 'HASH';	# a hashed array
    return &deref($$ref) if $type eq 'REF';	# recursive reference
    $ref;					# whatever..
}


#############################
#
#	&add_check($code, @precedes)
#
# Add the check code for $code, after ensuring that all codes
# in @precedes have already been done.
#
# In other words, if a particular check should be done *after* 
# some other test, place the other check code(s) as one of the 
# elements in the @precedes array.
#
# Add_check ensures that no check is scheduled twice.

sub add_check {
  local($code,@precedes) = @_;
  return if $check_done{$code};	# don't make the same check twice
  local($c);			# ensure predecessors are done first
  foreach $c (@precedes) {	# see if others are done
    &add_check($c) unless $check_done{$c};
  }
  push(@checks,$check_code{$code});
  $check_done{$code}++;
}

#################################
#
# These are the "check" routines.
#
# They are all called without arguments, and have full access to the
# variables of the &query routine.

# They all should check $input and return either:
#
#  undef	-return from query with undef
#  ''		-fail the input, and force another query
#  1		-input is okay, do the next check


#	&check_after
#
#	If $after is a CODE ref, invoke it to 
#	allow the sub to validate the input.

sub check_after {
  return 1 unless length($after);	# default is okay
  &$after(\$input);			# invoke the sub
}

#	&check_default
#
#	If $default is a CODE ref, invoke it to
#	get the default value, otherwise just use
#	the value as is.

sub check_default {
    $input = &deref($default) if !length($input);
    1;
}

#
#	&check_keys
#

sub check_keys {
  local( @exact );
  if ($Case_sensitive) {
    @exact = grep($input eq $_, @$keys);
  } else {
    @exact = grep(/^\Q$input\E$/i, @$keys);
  }
  if ($#exact == 0) {
    $input = $exact[0];	# it matches -- return the keyword
    return 1;		# yea!
  }
  local( @matches );
  if ($Case_sensitive) {
    @matches = grep(/^\Q$input\E/, @$keys);
  } else {
    @matches = grep(/^\Q$input\E/i, @$keys);
  }
  if ($#matches == 0) {	# exactly one match?
    $input = $matches[0];
    return 1;		# return success
  }
  if ($#matches > 0) {	# ambiguous?
    print "The input \"$input\" is ambiguous; it matches the following:\n";
    print_cols \@matches;
  } else {
    print "The input \"$input\" fails to match any of the allowed keywords:\n";
    print_cols $keys;
  }
  '';			# fail the input
}

#
#	&check_nonkeys
#

sub check_nonkeys {
  local( @matches );
  if ($Case_sensitive) {
    @matches = grep($_ eq $input, @$notkeys);	
  } else {
    @matches  = grep(/^\Q$input\E$/i, @$notkeys);	
  }
  @matches || return 1;		# no matches -- it's okay
  printf("The input \"%s\" matches a disallowed keyword \"%s\".\n", 
	 $input, $matches[0]);
  return '';
}

#
#	&check_number
#

sub check_number {
  if ($input !~ /^(\d+(\.\d*)?|\.\d+)(e\d+)?$/i) {
    print "Please enter a number, real or integer.\n";
    return '';
  }
  $input = 0.0 + $input;	# convert to numeric
  1;				# and it's okay
}

#
#	&check_integer
#

sub check_integer {
  if ($input !~ /^(\d+|0x[0-9a-f]+)$/i) {
    print "Please enter an integer number.\n";
    return '';
  }
  $input = 0 + $input;	# conver to integer
  1;
}

#
#	&check_yesorno
#

sub check_yesorno {
  if ($input !~ /^(y(es?)?|no?)$/i) {
    print "Please answer with \"yes\" or \"no\".\n";
    return '';
  }
  # Coerce input to 'yes' or 'no' 
  # Fixed by markw@temple.dev.wholesale.nbnz.co.nz (Mark Wright)
  $input = $input =~ /^y(es?)?$/i ? 'yes' : 'no';
}

#
#	&check_match
#

sub check_match {
  return 1 if $match eq '' or $input =~ m/$match/;
  printf "\"%s\" fails to match \"%s\"\n", $input, $match;
  '';			# fail the input
}

#
#	&check_length
#

sub check_length {
  return 1 if $maxlen <= 0 or length($input) <= $maxlen;
  printf "Input is %d characters too long; cannot exceed %d characters.\n",
	 (length($input) - $maxlen), $maxlen;
  '';			# fail the input
}

#
#	&check_required
#
sub check_required {
  return 1 if length($input);
  print "Input is required.\n";
  '';			# fail the input
}

#
#	&check_null
#

sub check_null {
  return undef unless length($input);	# a null input is an EOF
  chomp($input);			# trim trailing newline
  1;					# always succeed
}

#
#	&strip_input

sub strip_input {
  $input =~ s/^\s+//;
  $input =~ s/\s+$//;
  $input =~ s/\s+/ /g;		# squeeze blanks
  1;				# always ok
}

#
#	&check_help
#
# Check for help trigger '?'

sub check_help {
  $input =~ /^\s*\?\s*$/ || return 1;	# if not '?', its okay
  print ($help || "You are being asked \"$prompt\"\n");
  print "Input is required.\n" if $required;
  printf "The input should be %s.\n",($integer ? 'an integer' : 'a number') 
    if $integer || $number;
  print "The input should be either \"yes\" or \"no\".\n" if $yes || $no;
  if ($default) {
    my($def) = &deref($default);
    print "If you enter nothing, the default answer will be \"$def\".\n";
  } else {
    print "There is no default input.\n";
  }
  printf "The input cannot exceed %d characters in length.\n", $maxlen
    if $maxlen;
  printf "The input must match the pattern \"%s\".\n",$match if $match;
  if (@$keys) {
    print "The input must match one of the following keywords:\n";
    print_cols $keys, 0, 0, 1;
    print "The keyword matching is case-sensitive.\n" if $Case_sensitive;
  }
  if (@$notkeys) {
    print "The input cannot match one of the following keywords:\n";
    print_cols $notkeys, 0, 0, 1;
    print "The keyword matching is case-sensitive.\n" if $Case_sensitive;
  }
  print "\n";
  '';				# cause another query
}


###############
#
# query_table_process \@array, \&flagsub, \&querysub.
#
# Given an array suitable for query_table, run through the table and
# perform &querysub on each query definition, invoking &flagsub on each
# flag character.
#
# The local variables available to the subs are:
#   $table	- the array reference
#   $flags	- all the flags
#   $flag	- the current flag being processed (&flagsub only)
#   $arg	- the argument for the current flag, if appropriate.
#   $prompt	- the prompt for the current query
#
# When the &querysub is invoked, if it returns UNDEF, then the query
# table processing stops immediately, with an UNDEF return.

sub query_table_process {
  local( $table ) = shift;		# the query table
  local( $flagsub ) = shift;		# sub to perform on each flag
  local( $querysub ) = shift;		# sub to perform for each query
  local( $x, $prompt, $flags, $query_args, $argx, $flag, $_, $arg);

  ref($table) eq 'ARRAY' or
    (croak "query_table_process: Need an array reference argument.\n");
  (ref($flagsub) eq 'CODE' or $flagsub eq '') and
  (ref($querysub) eq 'CODE' or $querysub eq '') or
    (croak "query_table_process: Need a code reference argument.\n");

  for ($x = 0; $x <= $#$table; $x += 3) {
    $prompt     = $table->[$x];		# get the prompt
    $flags      = $table->[$x+1];	# get the flags
    $query_args = $table->[$x+2];	# get the arguments (if any)
    $argx	= 0;			# initialize arg index
    foreach $flag ( split(//, $flags) ) {
      $query_flags{$flag} or
	(croak "query_table_set_defaults: Unknown query flag: '$flag'\n");
      $arg = '';			# set arg to null by default
      if (index($need_arg_codes, $flag) >= 0) {
	$arg = $query_args->[$argx++];	# get the next arg
      }
      &$flagsub if $flagsub ne '';	# run the flag sub
    }
    if ($querysub ne '') {		# is there a querysub?
      &$querysub or return undef;	# run the query
    }
  }
  1;
}

###############
#
# $ok = query_table \@array;
#
# $ok == undef if EOF returned
#     == 1 if all queries completed ok
#     == 0 if not.
#
# Run multiple queries given "query" entries in the @array.
#
# The array is organized like this:
#
#  @array = ( prompt1, flags1, [ arglist1, ... ],
#	      prompt2, flags2, [ arglist2, ... ],
#		...
#	      promptN, flagsN, [ arglistN, ...] )
#
# Note: the query table is a N x 3 array, with the 3rd column being
# itself arrays of varying lengths, depending upon the corresponding
# flags. 
#
# Of course, this routine is more useful if the flags contain the 'V'
# flag, and the arglist has a correspoinding variable name.
#

sub query_table {
  local( $table ) = shift;
  local( @args );

  query_table_process $table, 	# process the query table
    sub {			# flagsub
      push(@args, $arg) if index($need_arg_codes, $flag) >= 0;
    },
    sub {			# querysub
      defined(query $prompt, $flags, @args) or return undef;
      @args = ();		# reset the args array
      1;
    };
  1;
}

###############
#
# query_table_set_defaults \@array;
#
# Given an array suitable for query_table, run through the table and
# initialize any variables mentioned with the provided defaults, if any.
#
# This routine is suitable for preinitializing variables using the
# same query table as would be used to query for their values.
#

sub query_table_set_defaults {
  local( $table ) = shift;		# the query table
  local( $var, $def );

  query_table_process $table, 
    sub {				# flag sub
      $var = $arg if $flag eq 'V';	# look for the variable arg
      $def = $arg if $flag eq 'd';	# look for the default arg
    }, 
    sub { &define_var($var, $def); };	# define a variable (maybe)
  1;
}

#######################
#
# define_var $var, $ref
#
# Define $var outside of this package.
#
# $var can be a reference to a variable, or it can be a string name.
# If it is the latter and not already qualified, it will be
# qualified at the package level outside of the Query.pm module.
#

sub define_var {
  my( $var ) = shift;			# the variable name
  my( $ref ) = shift;			# the value to define
  return 1 unless length($var);		# don't work with nulls
  if (!(ref($var) or $var =~ /::/)) { 	# variable already qualified?
    my( $pkg, $file ) = (caller)[0,1];	# get caller info
    my( $i );
    # Walk the stack until we get the first level outside of Query.pm
    for ($i = 1; $file =~ /Query\.pm/; $i++) {
      ($pkg, $file) = (caller $i)[0,1];
    }
    $pkg = 'main' unless $pkg ne '';	# default package
    $var = "${pkg}::${var}";		# qualify the variable's scope
  }
  $$var = &deref($ref);			# assign a deref'ed value
  1;					# always return good stuff
}

1;

__END__


=head1 NAME

B<Term::Query> - Table-driven query routine.

=head1 SYNOPSIS

=over 17

=item C<use B<Term::Query>>

C<qw( B<query> B<query_table> B<query_table_set_defaults> B<query_table_process> );>

=back

C<$result = B<query> $I<prompt>, $I<flags>, [ $I<optional_args> ];>

C<$I<ok> = B<query_table> \@I<array>;>

C<B<query_table_set_defaults> \@I<array>;>

C<$I<ok> = B<query_table_process> \@I<array>, \&flagsub, \&querysub;>

=head1 DESCRIPTION

=head2 B<query>

The B<query> subroutine fulfills the need for a generalized
question-response subroutine, with programmatic defaulting, validation,
condition and error checking.

Given I<$prompt> and I<$flags>, and possibly additional arguments,
depending upon the characters in I<$flags>, B<query> issues a prompt to
STDOUT and solicits input from STDIN.  The input is validated against a
set of test criteria as configured by the characters in I<$flags>; if
any of the tests fail, an error message is noted, and the query is
reattempted.

When STDIN is not a tty (not interactive), prompts are not issued, and
errors cause a return rather than attempting to obtain more input.
This non-interactive behaviour can be disabled by setting the variable
C<$Foce_Interactive> as below:

    $Term::Query::Force_Interactive = 1;

When C<$Force_Interactive> is a non-null, non-zero value, B<query>
will issue prompts, error messages, and ask for additional input
even when the input is not interactive.

=head2 B<query_table>

The B<query_table> subroutine performs multiple queries, by invoking
B<query>, setting associated variables with the results of each query.
Prompts, flags, and other arguments for each query are given in an
array, called a I<query table>, which is passed to the B<query_table>
subroutine by reference.

=head2 B<query_table_set_defaults>

The B<query_table_set_defaults> subroutine causes any variables named in
the given I<query table> array to be assigned their corresponding
default values, if any.  This is a non-interactive subroutine.

=head2 B<query_table_process>

A general interface to processing a I<query table> is available with the
B<query_table_process> subroutine.  It accepts a I<query table> array,
and two subroutine references, a I<&flagsub> and a I<&querysub>.  The
I<&flagsub> is invoked on each each I<flag> character given in the
I<$flags> argument of the I<query table> (see below).  The I<&querysub>
is invoked for each query in the I<query table>.

The B<query_table> and B<query_table_set_defaults> subroutines both use
B<query_table_process> to perform their functions.

=head2 I<Query Table>

The format of the I<query table> array passed to B<query_table>,
B<query_table_set_defaults>, and B<query_table_process> subroutines is:

 @array = ( $prompt1, $flags1, [ $arglist1, ... ],
            $prompt2, $flags2, [ $arglist2, ... ],
	    ...
	    $promptN, $flagsN, [ $arglistN, ... ] );

In English, there are three items per query: a I<prompt> string, a
I<flags> string, and an array of arguments.  Note that the syntax used
above uses C<[ ... ]> to denote a Perl 5 anonymous array, not an
optional set of arguments.  Of course, if there are no arguments for a
particular query, the corresponding anonymous array can be the null
string or zero.

The query table design is such that a query table can be created with a
set of variables, their defaults, value constraints, and help strings,
and it can be used to both initialize the variables' values and to
interactively set their new values.  The B<query_table_set_defaults>
subroutine performs the former, while B<query_table> does the latter.

=head2 Flag Characters

With typical usage, given I<$prompt> and I<$flags>, B<query> prints
I<$prompt> and then waits for input from the user.  The handling of the
response depends upon the flag characters given in the I<$flags> string.

The flag characters indicate the type of input, how to process it,
acceptable values, etc.  Some flags simply indicate the type or
processing of the input, and do not require additional arguments.  Other
flags require that subsequent arguments to the B<query> subroutine be
given.  The arguments must be given in the same order as their
corresponding flag characters.

The ordering of the flags in the I<$flags> argument is important -- it
determines the ordering of the tests.  For example, if both the B<a> and
B<m> flags are given as C<"am">, then this indicates that an I<after>
subroutine call should be performed first, followed by a regular
expression I<match> test.

All tests are applied in the order given in the I<$flags> until a
particular test fails.  When a test fails, an error message is generated
and the input is reattempted, except in the case of the B<I> flag.

=head2 Flag Characters Without Arguments

=over 5

=item B<i>

The input must be an integer.

=item B<n>

The input must be a number, real or integer.

=item B<Y>

The input is a C<"yes"> or C<"no">, with a default answer of C<"yes">.

=item B<N>

The input is a C<"yes"> or C<"no">, with a default answer of C<"no">.

=item B<r>

Some input is I<required>; an empty response will be refused.  This
option is only meaningful when there is no default input (see the B<d>
flag character below).

=item B<s>

Strip and squeeze the input.  Leading and trailing blanks are
eliminated, and embedded whitespace is "squeezed" to single blank
characters.  This flag is implied by the B<k> and B<K> flags.

=item B<H> 

Do not treat input of B<?> as a request for help.  This disables
automatic help, unless implemented with the I<after> (B<a> flag)
subroutine.

=back

=head2 Flag Characters With Arguments

The following flag characters indicate the presence of an argument to
B<query>.  The arguments must occur in the same order as their
corresponding flag characters.  For example, if both the B<V> and B<h>
flags are given as C<"Vh">, then the first argument must be the
variable name, and the next the help string, in that order.

=over 5

=item B<a> I<\&after>

The next argument is the I<after> subroutine, to be invoked after the
input has been solicited.  This feature provides for an "open ended"
input validation, completely at the control of the user of the Query
module.    The I<after> subroutine is invoked in this manner:

  &$after( \$input );

If the I<after> sub returns an C<undef>, then query processing stops
with an immediate C<undef> return value.

If the I<after> sub returns a null or zero value, then the input is
rejected and resolicted.  No error messages are displayed except the
"Please try again." message.

Since the I<after> sub has the reference to the I<$input> variable, it
is free to change the value of input indirectly; ie:

  $$input = $some_new_value;

=item B<b> I<\&before>

The next argument is the I<before> subroutine, to be invoked before any
input is attempted.    If the I<before> sub returns a non-null, non-zero
value, the current query will be attempted.  If a null or zero value is
returned, the current query will be abandoned, with a null return.

This feature, used in a I<query table>, allows for selective queries to
be programmed by using I<before> subs on the optional queries.  For
example, using the following anonymous sub as the B<b> flag argument:

  sub { $> == 0; }

will cause the corresponding query to only be issued for the C<root>
user. 

The ordering of the B<b> flag in the I<$flags> argument is unimportant,
since, by definition, this test is always performed before attempting
any input.

=item B<d> I<$default>

The next argument is the I<default> input.  This string is used
instead of an empty response from the user.  The default value
can be a scalar value, a reference to a scalar value, or a
reference to a subroutine, which will be invoked for its result
only if a default value is needed (no input is given).

=item B<h> I<$help_string>

The next argument is the I<help string>, which is printed in
response to an input of "B<?>".  In order to enter a B<?> as
actual text, it must be prefixed with a backslash: "\".

=item B<k> I<\@array>

The next argument is a reference to an array of allowable keywords.  The
input is matched against the array elements in a case-insensitive
manner, with unambiguous abbreviations allowed.  This flag implies the
B<s> flag.

The matching can be made case-sensitive by setting the following
variable prior to the invocation of B<query>:

  $Query::Case_sensitive = 1;

By default, this variable is null.

=item B<K> I<\@array>

The next argument is a reference to an array of disallowed keywords In
this case, for the input to be unacceptable, it must match exactly,
case-insensitive, one of the array elements.  This flag implies the B<s>
flag.

The B<k> option is useful for soliciting new, unique keywords to a
growing list.  Adding new fields to a database, for example.

The matching can be made case-sensitive by setting the
C<$Query::Case_sensitive> variable (see above).

=item B<l> I<$maxlen>

The next argument specifies the maximum length of the input.

=item B<m> I<$regular_expression>

The next argument specifies a regular expression pattern against which
the input will be matched.

=item B<I> I<$reference>

The next argument is the input: either a simple scalar value, or a
I<reference> to a value, such as a C<SCALAR> variable reference (eg:
C<\$somevar>), or a C<CODE> reference (eg: C<sub {..}>).  In any case,
the resulting value is used as input instead of reading from STDIN.

If the input returned by the reference does not match other constraints,
additional input is not attempted.  An error message is noted, and an
C<undef> return is taken.

This option is handy for applications which have already acquired the
input, and wish to use the validation features of C<query>.

It is also useful to embed a query definition in a I<query table> which
does not actually perform a query, but instead does a variable
assignment dynamically, using the B<I> reference value.

=item B<J> I<$reference>

The next argument is the input I<reference>, as with the B<I> flag,
except that if the input fails any of the constraints, additional input
is solicited from the input.  In other words, the B<J> flag sets a
I<one-time> only input reference.  Think of it as I<jumping> into the
query loop with an initial input.

=item B<V> I<variable_name_or_ref>

The next argument is the variable name or reference to receive the
validated input as its value.  This option, and its corresponding
variable name, would normally be present on all entries used with
B<query_table> in order to retain to the values resulting from each
query.

The value can either be a string representing the variable name, or
a reference to a variable, eg: C<\$some_var>.

=back

=head2 Details

The query processing proceeds basically in the same order as defined by
the I<flags> argument, with some exceptions.  For example, the I<before>
subroutine is always performed prior to input.

There are implicit precedences in the ordering of some of the I<flag>
tests.  Generally, flags have their corresponding tests performed in
the same order as the given flags.  Some flag tests, however, require
that other flags' tests be performed beforehand in order to be
effective.  For example, when given the B<k> flag and an B<s> flag,
stripping the input would only be effective if the strip were done on
the input before testing the input against the keyword table.  In other
words, the B<s> flag has precedence over the B<k> flag.  If the user
supplies the I<flags> string as C<"ks">, the effective ordering would
still be C<"sk">.

The table below indicates the precedences of the flag tests:

  Given Flag       Flags With Higher Precedence
  ==========       ================================
  i (int)          s (strip), d (default), h (help)
  k (key)          s (strip), d (default), h (help)
  K (nonkey)       s (strip), d (default), h (help)
  l (maxlen)                  d (default), h (help)
  m (match)                   d (default), h (help)
  n (numeric)      s (strip), d (default), h (help)
  N (no)           s (strip), d (default), h (help)
  r (required)                d (default), h (help)
  s (strip)                   d (default), h (help)
  Y (yes)          s (strip), d (default), h (help)

Except for the implied precedence indicated in the table above, the
ordering of the flag tests proceeds in the same order as given
in the I<flags> argument.

Excepting the precedences above, query processing proceeds generally as
described below.

=over 5

=item *

If the B<b> flag was given, the "before" subroutine is invoked as a
"pre-input" test.  If the sub returns a 0, empty string, or undef, the 
query is abandoned.  Otherwise, processing continues.

=item *

If the B<I> or B<J> flags were given, then input is obtained, without
prompting, from the associated reference.  If the reference type is
C<CODE>, then it is invoked and the resulting return value is used as
the input.  Otherwise the reference is evaluated in a scalar context and
used as the input.  The B<J> flag test is only done once, on the first
entry into the input loop.

=item *

In the absence either the B<I> or B<J> flags, C<query> will issue the
given prompt and obtain input from STDIN.  If an EOF occurs, an C<undef>
value will result.

=item *

The input is examined for "null" input (that is, the empty string), and
processing quits in this case.  Since most input is obtained from
STDIN, a null input indicates an end-of-file (EOF).  If the input is
not null, a terminating newline is removed, and the input testing
continues.  At this point, an empty input string does not indicate an
EOF.

=item *

If the B<s>, B<k>, or B<K> flags were given, the input is trimmed of
leading and trailing blanks, and all whitespace is "squeezed" to single
blanks.

=item *

If the input is an empty response, and there is a I<default> input (B<d>
flag), use it instead.

=item *

Unless the B<H> flag is given, if the input is the character "B<?>"
with nothing else, then print some helpful information.  If the user had
supplied a I<help string>, it is printed, otherwise the message:

You are being asked "I<$prompt>"

is displayed.  Also, some information about the expected response,
according to any given flag characters, is displayed.  Finally, the user
is returned to the prompt, and given another opportunity to enter a
response.

=item *

If input is I<required> (indicated by the B<r> flag), and if the input
is empty, produce an error message, and query again.

=item *

If there was a B<a> flag, the corresponding I<after> subroutine is
invoked with the input reference as its argument.  If the subroutine
returns a non-null, non-zero value, the input succeeds, otherwise it
fails.  It is up to the I<after> subroutine to display any appropriate
error messages.

=item *

If the query was flagged B<Y> or B<N>, match the input against the
pattern:

    /^(y(es?)?|no?)$/i

If the match fails, print an error message, and query again.  When the
match succeeds, replace the input with the complete word C<"yes"> or
C<"no">;

=item *

If an integer response is required (B<i> flagged), check for integer
input.  If not, print an error, and query again.  A successful integer
input is returned.

=item *

If a numeric response is required (B<n> flagged), check for proper
numeric input (either integer or real format).  Errors produce a
warning, and another query.

=item *

If the query was given a I<keyword> table (flagged with B<k>), the input
is matched against the allowable keyword list.  If an exact match is
found, the keyword is returned as the input.  Failing an exact match, an
abbreviation search is performed against the keywords.  If a single
match is found, it is returned as the input.  If no match is found, an
error message is produced, and the user is returned to the query to try
again.  Otherwise, the input was ambiguous, an error noted showing the
matches, and the user is queried again.

The matching is case-insensitive or not, according to the value of the
variable C<$Query::Case_sensitive>, which is nil, by default.  The
variable may be set by the user to change the matching from
case-insensitive to case-sensitive.

=item *

If the query was given an unacceptable keyword list (flagged with B<K>),
the input is compared against the unacceptable keywords.  If it matches
any keywords exactly, an error is noted, and the query is performed
again.

The matching is case-insensitive by default.  Set the variable
C<$Query::Case_sensitive> to a non-null, non-zero value to make the
keyword matching case-sensitive.

=item *

If the query was B<m> flagged with a Perl regular expression pattern,
then the input is matched against the pattern.  Failures are noted with
an error message, and the query reattempted.

=item *

If the query was B<l> flagged with a maximum input length, the length of
the input is checked against the maximum.  A length violation is noted
with an error message and the user is queried again.

=item *

If the query has a variable defined with the B<V> flag, the variable is
assigned the input string.  This is always done last, after and only if 
all tests are successful.  

If the variable is a string name and not qualified with a package name
(ie:  C<$foo::variable>), then the variable is qualified at the level
outside of the Query.pm module.

=item *

Finally, having passed whatever conditions were flagged, the input is
returned to the user.  

=back

=head1 EXAMPLE

The following are typical usage samples:

=over 5

=item *

To perform a simple "yes" or "no" query, with "no" as the default
answer:

 $ans = &query("Do you wish to quit? (yn)",'N');

=item *

An equivalent alternative is:

    query "Do you wish to quit? (yn)", 'NV', \$ans;

=item *

To perform the same query, with some supplied helpful information:

 $ans = &query("Do you wish to quit? (yn)",'Nh',<<'EOF');
 You are being asked if you wish to quit.  If you answer "yes",
 then all changes will be lost.  An answer of "no", will allow
 you to return to continue making changes.
 EOF

=item *

To solicit an integer input:

 $mode = &query("Please enter the file mode:",'idh','644',<<'EOF');
 Please enter the 3 digit numeric file mode; if you are unsure
 of how the file mode is used, please see the man page for "chmod".
 EOF

=item *

To solicit one of several keywords:

 @keys = split(' ','SGI DEC IBM Sun HP Apple');
 $vendor = &query('Please enter a vendor:','rkd',\@keys,'SGI');

=item *

To solicit a new, unique keyword to be used as a database field
name, with a regexp pattern to check it against:

 @fields = split(' ','Index Vendor Title'); # existing fields
 $newfield = &query('New field name:','rKm',\@fields,'^\w+$');

=back

=head1 ENVIRONMENT

=over 5

=item B<COLUMNS>

This variable is used to control the width of output when listing the keyword
arrays.  If not defined, 80 is used by default.

=back

=head1 DEPENDENCIES

=over 5

=item B<Carp.pm>

Used to produce usage error messages.

=item B<Array::PrintCols::print_cols>

Used to produce displays of the keyword arrays.

=back

=head1 FILES

None.

=head1 AUTHOR

Copyright (C) 1995  Alan K. Stebbens <aks@hub.ucsb.edu>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 DIAGNOSTICS

=over 5

=item 
Input is required.

Issued when an empty response is given, and there is no default input.

=item 
Please answer with 'yes' or 'no', or enter '?' for help.

Issued for B<Y> or B<N> flagged queries, and the input is not
reconizeable.

=item 
Please enter an integer number.

Printed when non-integer input is given for B<i> flagged queries.

=item 
Please enter a number, real or integer.

Printed when non-numeric input is given for B<n> flagged queries.

=item 
The input 'I<$input>' is ambiguous; it matches the following:

Issued in response to B<k> flagged queries with input which matches more
than one of the allowed keywords.

=item 
The input 'I<$input>' fails to match any of the allowed keywords:

Printed when input to a B<k> flagged query does not match any of the
keywords.

=item 
The input '%s' matches a disallowed keyword '%s'.

Printed when the input matches one of the unacceptable keywords given on
a B<K> flagged query.

=item 
'%s' fails to match '%s'

This results from input failing to match the regular expression given on
a B<m> flagged query.

=item 
Input is %d characters too long; cannot exceed %d characters.

The length of the input exceeded the maximum length given with the B<l>
flag argument.

=item 
Please try again, or enter '?' for help.

=item 
query: The k flag needs an array reference.

The next argument in the argument list to B<query> wasn't an array
reference.

=item 
query: The K flag needs an array reference.

The next argument in the argumentlist to B<query> wasn't an array
reference.

=head1 BUGS
