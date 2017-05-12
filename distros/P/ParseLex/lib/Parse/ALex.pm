# Copyright (c) Philippe Verdret, 1995-1999

# Architecture:
#           Parse::ALex - Abstract Lexer
#                |
#           +----------+
#           |          |
#           |     Parse::Tokenizer
#           |        |     |
#        LexEvent   Lex  CLex  ...       - Concrete lexers

require 5.004;
use integer;
use strict qw(vars);
use strict qw(refs);
use strict qw(subs);

package Parse::ALex;
$Parse::ALex::VERSION = '2.21';
use Parse::Trace;
@Parse::ALex::ISA = qw(Parse::Trace); 

use Parse::Token;	
use Parse::Template;

				# Default values
my $trace = 0;			# if true enable the trace mode
my $hold = 0;			# if true enable data saving
my $skip = '[ \t]+';		# strings to skip
my $DEFAULT_STREAM = \*STDIN;	# Input Filehandle 
my $eoi = 0;			# 1 if end of imput 

# define constant, use a pseudo-hash???
my %_map;			# Define a mapping between element names and numbers
my @attributes = qw(STREAM FROM_STRING LEXER_SUB BUFFER PENDING_TOKEN 
		    LINE RECORD_LENGTH OFFSET POS
		    EOI SKIP HOLD HOLD_TEXT 
		    NAME IN_PKG
		    TEMPLATE
		    LEXER_STRING_SUB LEXER_STREAM_SUB LEXER_CLOSURE_ENV
		    LEXER_STRING_CODE LEXER_STREAM_CODE LEXER_CODE
		    STATE_MACHINE_CODE STATES STACK_STATES EXCLUSIVE_COND INCLUSIVE_COND
		    TRACE  
		    TOKEN_LIST);
my($STREAM, $FROM_STRING, $LEXER_SUB, $BUFFER, $PENDING_TOKEN, 
   $LINE, $RECORD_LENGTH, $OFFSET, $POS,
   $EOI, $SKIP, $HOLD, $HOLD_TEXT, 
   $NAME, $IN_PKG,
   $TEMPLATE, 
   $LEXER_STRING_SUB, $LEXER_STREAM_SUB, $LEXER_CLOSURE_ENV,
   $LEXER_STRING_CODE, $LEXER_STREAM_CODE, $LEXER_CODE,
   $STATE_MACHINE_CODE, $STATES, $STACK_STATES, $EXCLUSIVE_COND, $INCLUSIVE_COND,
   $TRACE, 
   $TOKEN_LIST
) = @_map{@attributes} = (0..$#attributes);

#sub EOI () { 9 }		# trial

sub _map { 
  shift;
  if (@_) {
    wantarray ? @_map{@_} : $_map{$_[0]};
  } else {
    @attributes;
  }
}

my $somevar = '';		
				# Create and instanciate a prototypical instance
my $lexer = __PACKAGE__->clone;	
sub prototype { $lexer or [] }

my $TOKEN_CLASS = 'Parse::Token'; # Root class for the token objects
sub tokenClass { 
  if (defined $_[1]) {
    no strict qw/refs/;
    ${"$TOKEN_CLASS" . "::PENDING_TOKEN"} = $PENDING_TOKEN; 
    $TOKEN_CLASS = $_[1];
  } else {
    $_[1] 
  }
}
my $DEFAULT_TOKEN = $TOKEN_CLASS->new('DEFAULT', '.*'); # default token
$lexer->tokenClass($TOKEN_CLASS);

$lexer->[$STREAM] = $DEFAULT_STREAM;
$lexer->[$FROM_STRING] = 0;	# 1 for a string
$lexer->[$BUFFER] = \$somevar;		# string to tokenize
$lexer->[$PENDING_TOKEN] = $DEFAULT_TOKEN;
$lexer->[$LINE] = \$somevar;	# number of the current record
$lexer->[$RECORD_LENGTH] = \$somevar;	# length of the current record
$lexer->[$OFFSET] = \$somevar;		# offset from the beginning of the analysed stream
$lexer->[$POS] = \$somevar;		# position in the current record
$lexer->[$EOI] = $eoi;
$lexer->[$SKIP] = $skip;	# a pattern to skip
$lexer->[$HOLD] = $hold;	# save or not what is consumed
$lexer->[$HOLD_TEXT] = '';	# saved string
$lexer->[$TEMPLATE] = new Parse::Template; # code template

				# lexer code: [HEADER, BODY, FOOTER]
$lexer->[$LEXER_STREAM_CODE] = [];	# cached subroutine definition
$lexer->[$LEXER_STRING_CODE] = [];	# cached subroutine definition
$lexer->[$LEXER_CODE] = [];		# definition of the current lexer
$lexer->[$LEXER_CLOSURE_ENV] = [];	# environnement of the lexer closure
$lexer->[$LEXER_SUB] = my $DEFAULT_LEXER_SUB = sub {
  $_[0]->genLex;		# lexer autogeneration
  &{$_[0]->[$LEXER_SUB]};	# lexer execution
};
$lexer->[$LEXER_STREAM_SUB] = sub {};	# cache for the stream lexer
$lexer->[$LEXER_STRING_SUB] = sub {};	# cache for the string lexer

				# State machine
$lexer->[$EXCLUSIVE_COND] = {};	# exclusive conditions
$lexer->[$INCLUSIVE_COND] = {};	# inclusive conditions
$lexer->[$STATE_MACHINE_CODE] = ''; # definition of the state machine
$lexer->[$STATES] = { 'INITIAL' => \$somevar };	# state machine
$lexer->[$STACK_STATES] = [];	# stack of states, not used
$lexer->[$TRACE] = $trace;
$lexer->[$TOKEN_LIST] = [];	# Token instances

sub reset {			# reset all lexer's state values
  my $self = shift;
  ${$self->[$LINE]} = 0;
  ${$self->[$RECORD_LENGTH]} = 0;
  ${$self->[$OFFSET]} = 0;
  ${$self->[$POS]} = 0;
  ${$self->[$BUFFER]} = ''; 
  $self->[$HOLD_TEXT] = '';
  $self->[$EOI] = 0; 
  $self->state('INITIAL');	# initialize the state machine
  if ($self->[$PENDING_TOKEN]) { 
    $self->[$PENDING_TOKEN]->setText();
    $self->[$PENDING_TOKEN] = 0;
  }
  $self;
}

sub eoi { 
  my $self = shift;
  $self->[$EOI];
} 
sub token {			# always return a Token object
  my $self = shift;
  $self->[$PENDING_TOKEN] or $DEFAULT_TOKEN 
} 
*getToken = \&token;
sub setToken {			# force the token
  my $self = shift;
  $self->[$PENDING_TOKEN] = $_[0];
}
sub setBuffer {			# not documented
  my $self = shift;
  ${$self->[$BUFFER]} = $_[0];
} 
sub getBuffer {			# not documented
  my $self = shift;
  ${$self->[$BUFFER]}; 
} 
sub buffer { 
  my $self = shift;
  if (defined $_[0]) {
    ${$self->[$BUFFER]} = $_[0] 
  } else {
    ${$self->[$BUFFER]};
  }
} 
sub flush {
  my $self = shift;
  my $tmp = $self->[$HOLD_TEXT];
  $self->[$HOLD_TEXT] = '';
  $tmp;
}
# returns or sets the number of the current record
sub line {	
  my $self = shift;
  if (@_) {
    ${$self->[$LINE]} = shift;
  } else {
    ${$self->[$LINE]};
  }
}
# return the length of the current record
# not documented
sub length {	
  my $self = shift;
  if (@_) {
    ${$self->[$RECORD_LENGTH]} = $_[0];
  } else {
    ${$self->[$RECORD_LENGTH]};
  }
}
# return the end position of last token from the stream beginning
sub offset {			
  my $self = shift;
  ${$self->[$OFFSET]};
}
# return the end position of the last token 
# in the current record
sub pos {		
  my $self = shift;
  if (defined $_[0]) {
    ${$self->[$POS]} = $_[0] 
  } else {
    ${$self->[$POS]};
  }
}
sub name {		      
  my $self = shift;
  if (defined $_[0]) {
    $self->[$NAME] = $_[0] 
  } else {
    $self->[$NAME];
  }
}
# not documented
sub inpkg {		
  my $self = shift;
#  if (ref $self) {
    if (defined $_[0]) {
      $self->[$IN_PKG] = $_[0] 
    } else {
      $self->[$IN_PKG];
    }
#  } else {
#    if (defined $_[0]) {
#      $inpkg = $_[0] 
#    } else {
#      $inpkg;
#    }
#  }
}
use constant TRACE_GEN => 0;
sub tokenList {
  my $self = shift;
  if ($^W and @{$self->[$TOKEN_LIST]} == 0) {
    require Carp;
    Carp::carp("no token defined");
  }
  @{$self->[$TOKEN_LIST]}; 
}
####
# Purpose: define the data input
# Parameters: possibilities
# 1. filehandle (\*FH, *FH or IO::File instance)
# 2. list of strings
# 3. <none> 
# Returns:  1. returns the lexer
#           2. returns the lexer
#           3. returns the lexer's filehandle if defined
#              or undef if not 
sub from {
  my $self = shift;
  my $debug = 0;
  
  # check for stream : check only ref($fh) insteaf of fileno()
  # Filehandles connected to memory objects via new features of
  # "open" may return undefined even though they are open.)
  my $fd = $_[0];
  
  print STDERR "arg: $fd\n" if $debug;
  if (ref($fd)) {		# From STREAM
    $self->[$STREAM] = $fd;
    print STDERR "From stream\n" if $debug;

    if (@{$self->[$LEXER_STREAM_CODE]}) { # Code already exists
      if ($self->[$FROM_STRING]) { # if STREAM definition isn't the current
		print STDERR "code already exists\n" if $debug;
		$self->[$LEXER_SUB] = $self->[$LEXER_STREAM_SUB];
		$self->_switchClosureEnv();
		$self->[$FROM_STRING] = 0;
      }
    } 
	else {			# code doesn't exist
      print STDERR "Analyze STREAM - code generation\n" if $debug;
      $self->[$FROM_STRING] = 0;
      #$self->[$LEXER_SUB] = $DEFAULT_LEXER_SUB;      # 
      $self->genLex;		# lexer generation
    }

    $self->reset;
    $self;
  } 
  elsif (defined $_[0]) {	# From STRING
    print STDERR "From string\n" if $debug;
    if (@{$self->[$LEXER_STRING_CODE]}) { # code already exists
      unless ($self->[$FROM_STRING]) {
		print STDERR "code already exists\n" if $debug;
		$self->[$LEXER_SUB] = $self->[$LEXER_STRING_SUB];
		$self->_switchClosureEnv();
		$self->[$FROM_STRING] = 1;
      }
    } 
	else {			# code doesn't exist
      print STDERR "Analyze STRING - code generation\n" if $debug;
      $self->[$FROM_STRING] = 1;
      # autogeneration doesn't work, 
      # cause the generation delete the buffer
      #$self->[$LEXER_SUB] = $DEFAULT_LEXER_SUB;      # 
      $self->genLex;		# lexer generation
    }

    $self->reset;
    my $buffer = join($", @_); # Data from a list
    ${$self->[$BUFFER]} = $buffer;
    ${$self->[$RECORD_LENGTH]} = CORE::length($buffer);
    $self;
  } 
  elsif ($self->[$STREAM]) {
    $self->[$STREAM];
  } 
  else {
    undef;
  }
}


sub readline {
  my $fh = $_[0]->[$STREAM];
  my $record = '';
  if (not defined($record = <$fh>)) {
    $_[0]->[$EOI] = 1;
  } else {
    ${$_[0]->[$LINE]}++;
  }
  $record;
}

sub isFromString { $_[0]->[$FROM_STRING] }
sub isTrace { $_[0]->[$TRACE] }

# could be improved
# Purpose: Toggle the trace mode
# todo: regenerate the lexer if needed
sub trace { 
  my $self = shift;
  my $class = ref($self);
  if ($class) {			# Object method
    if ($self->[$TRACE]) {
      $self->[$TRACE] = 0;
      print STDERR qq!trace OFF for a "$class" object\n!;
    } else {
      $self->[$TRACE] = 1;
      print STDERR qq!trace ON for a "$class" object\n!;
    }
  } else {			# Class method
    $self->prototype()->[$TRACE] = not $self->prototype->[$TRACE];
    $self->SUPER::trace(@_);
  }
}
sub isHold { $_[0]->[$HOLD] }
# hold(EXPR)
# hold
# Purpose: Toggle method, hold or not consumed strings
# Arguments: nothing or EXPR true/false
# Returns: value of the hold attribute

sub hold {			
  my $self = shift;
  if (ref $self) {		# Instance method
      $self->[$HOLD] = not $self->[$HOLD];

      # delete the code already generated
      @{$lexer->[$LEXER_STREAM_CODE]} = ();
      @{$lexer->[$LEXER_STRING_CODE]} = ();
      @{$lexer->[$LEXER_CODE]} = ();		
      $lexer->[$LEXER_SUB] = $DEFAULT_LEXER_SUB;

  } else {			# Class method
    $self->prototype()->[$HOLD] = not $self->prototype()->[$HOLD];
  }
}

# skip(EXPR)
# skip
# Purpose: return or set the value of the regexp used for consuming
#          inter-token strings. 
# Arguments: with EXPR change the regexp and regenerate the
#            lexical analyzer 
# Returns: see Purpose
sub skip {			
  my $self = shift;

  my $debug = 0;
  if (ref $self) {		# Instance method
    if (defined($_[0]) and $_[0] ne $self->[$SKIP]) {
      print STDERR "skip value: '$_[0]'\n" if $debug;
      $self->[$SKIP] = $_[0];

      # delete the code already generated
      @{$self->[$LEXER_STREAM_CODE]} = (); # or $self->[$LEXER_STREAM_CODE] = []
      @{$self->[$LEXER_STRING_CODE]} = ();
      @{$self->[$LEXER_CODE]} = ();		
      $self->[$LEXER_SUB] = $DEFAULT_LEXER_SUB;

    } else {
      $self->[$SKIP];
    }
  } else {			# Used as a Class method
    print STDERR "skip value: '$_[0]'\n" if $debug;

    defined $_[0] ?
      $self->prototype()->[$SKIP] = $_[0] : $self->prototype()->[$SKIP];
  }
}
sub defineTokens {
  my $self = shift;
  my @token = $TOKEN_CLASS->factory(@_);
  my $token;
  foreach $token (@token) {	
    $token->lexer($self);	# Attach each token to its lexer
    $token->inpkg($self->inpkg); # Define the package in which the token is defined
    $token->exportTo();		# export in the calling package
  }
  print STDERR @token + 0,  " tokens\n"  if TRACE_GEN;
  $self->[$TOKEN_LIST] = [@token];
}
# From => STRING|FILEHANDLE, Tokens => [], Skip => RE
sub configure {
  my $self = shift;
  my ($key, $value);
  while (@_ >= 2) {
    ($key, $value) = (shift, shift);
    if ($key =~ /^[Ff]rom$/) {
      $self->from($value);
    } elsif ($key =~ /^[Ss]kip$/) {
      $self->skip($value);
    } elsif ($key =~ /^[Tt]okens$/) {
      unless (ref $value eq 'ARRAY') {
	require Carp;
	Carp::croak "'Tokens' must be associated to an ARRAY reference";
      }
      $self->defineTokens($value);
    } else {
      last;
    }
  }
  $self;
}
# not documented
# Purpose: returns :
# - a copy of the prototypical lexer if used as a class method
# - a copy of the message receiver if used as an instance method
# naive implementation
sub clone {
  my $receiver = shift;
  my $class;
  if ($class = ref $receiver) {	# Instance method: clone the current instance
    bless [@{$receiver}], $class; 
  } else {			# Class method: clone the class prototype
    bless [@{$receiver->prototype}], $receiver; 
  }
}
# Purpose: create the lexical analyzer
# Arguments: list of tokens or token specifications
# Returns: a lex object
sub new {
  my $receiver = shift;
  my $class = (ref $receiver or $receiver);

  if ($class eq __PACKAGE__) {
    require Carp;
    Carp::croak "can't create an instance of '$class' abstract class"
  }

  my $self = $receiver->clone;
  $self->reset;
  $self->[$IN_PKG] = caller; 

  if (@_) {			
    $self->defineTokens(@_);
  }
  $self;
}

# sub lexerType {
#   my $self = shift;
#   if ($self->isa('Parse::Lex')) {
#     return 'Parse::Lex';
#   } elsif ($self->isa('Parse::CLex')) {
#     return 'Parse::CLex';
#   } else {
#     return ref $self || $self;
#   }
# }

# Put or fetch a template object
sub template {
  my $self = shift;
  if (defined $_[0]) {
    $self->[$TEMPLATE] = $_[0];
  } else {
    $self->[$TEMPLATE];
  }
}
sub getTemplate {
  my $self = shift;
  my $part = shift;
  $self->[$TEMPLATE]->{$part};
}
sub setTemplate {
  my $self = shift;
  my $part = shift;
  $self->[$TEMPLATE]->{$part} = shift;
}

# redefine this!!! don't copy, just reference
# the LEXER_STRING_CODE!!!
# and don't regenerate if code already exists
sub genCode {
  my $self = shift;
  print STDERR "genCode()\n" if TRACE_GEN;
  $self->genHeader();
  $self->genBody($self->tokenList); 
  $self->genFooter();
  if ($self->[$FROM_STRING]) {	# cache the already generated code
    $self->[$LEXER_STRING_CODE] = [@{$self->[$LEXER_CODE]}]; 
    $self->[$LEXER_STRING_SUB] = $self->[$LEXER_SUB];
  } else {
    $self->[$LEXER_STREAM_CODE] = [@{$self->[$LEXER_CODE]}]; 
    $self->[$LEXER_STREAM_SUB] = $self->[$LEXER_SUB];
  }
}
# Remark: not documented
sub genHeader {
  my $self = shift;
  my $template = $self->template;
  print STDERR "genHeader()\n" if TRACE_GEN;
				# build the template env
  $template->env(
		 'SKIP' => $self->[$SKIP],
		 'IS_HOLD' => $self->[$HOLD],
		 'HOLD_TEXT' => $HOLD_TEXT,
		 'EOI' => $EOI,	# array index
		 'TRACE' => $TRACE,
		 'IS_TRACE' => $self->[$TRACE],
		 'PENDING_TOKEN' => $PENDING_TOKEN, # array index
		); 

  if ($self->[$FROM_STRING]) {
    $self->[$LEXER_CODE]->[0] = $self->template->eval('HEADER_STRING_PART');
  } else {
    $self->[$LEXER_CODE]->[0] = $self->template->eval('HEADER_STREAM_PART');
  }
}
# Purpose: create the lexical analyzer
# Arguments: list of tokens
# Returns: a Lex object
# Remark: not documented
sub genBody {
  my $self = shift;
  print STDERR "genBody()\n"  if TRACE_GEN;

  my $token;
  my $body = '';
  my $debug = 0;
  print STDERR @_ + 0,  " tokens\n"  if TRACE_GEN;
  while (@_) {			# list of Token instances
    $body .= shift->genCode();
  }
  $self->[$LEXER_CODE]->[1] = $body;
}
# Remark: not documented
sub genFooter {
  my $self = shift;
  print STDERR "genFooter()\n" if TRACE_GEN;
  $self->[$LEXER_CODE]->[2] = $self->template->eval('FOOTER_PART');
}

# Purpose: Returns code of the current lexer
# Arguments: nothing
# Returns: code of the lexical analyzer
# Remark: not documented, doesn't return the state machine definition
sub getCode { 
  my $self = shift;
  my @code = @{$self->[$LEXER_CODE]};
  unless (@code) {
    $self->genCode;
    @code = @{$self->[$LEXER_CODE]}
  } 
  join '', @code;
}

# Not documented
# Purpose: set/get environnement of the lexer closure
# Arguments: see definition
# Returns: references to some internal object fields
# todo: test type and number of arguments
sub _closureEnv {
  my $self = shift;
  if (@_) {
    ($self->[$BUFFER], 
     $self->[$RECORD_LENGTH],
     $self->[$LINE], 
     $self->[$POS], 
     $self->[$OFFSET],
     $self->[$STATES],
    ) = @_;
  } else {
    ($self->[$BUFFER], 
     $self->[$RECORD_LENGTH],
     $self->[$LINE], 
     $self->[$POS], 
     $self->[$OFFSET],
     $self->[$STATES],
    )
  }
}
sub _saveClosureEnv {
  my $self = shift;
  @{$self->[$LEXER_CLOSURE_ENV]} = $self->_closureEnv();
}
sub _switchClosureEnv {
  my $self = shift;
  my @tmp = $self->_closureEnv();
  $self->_closureEnv(@{$self->[$LEXER_CLOSURE_ENV]});
  @{$self->[$LEXER_CLOSURE_ENV]} = @tmp;
}

# Purpose: Generate the lexical analyzer
# Arguments: 
# A Returns: the anonymous subroutine implementing the lexical analyzer
# Remark: not documented
sub genLex {
  my $self = shift;
  # optimization: unless @{$self->[$LEXER_CODE]};	
  # or delegate this behavior to getCode() ? 
  $self->genCode; 

  print STDERR "Lexer generation...\n"  if TRACE_GEN;

				# Closure environnement
  my $LEX_BUFFER = '';		# buffer to analyze
  my $LEX_LENGTH = 0;		# buffer length

#  my $LEX_BUFFER = ${$self->[$BUFFER]};	# buffer to analyze
#  my $LEX_LENGTH = ${$self->[$RECORD_LENGTH]}; # buffer length

  my $LEX_RECORD = 0;		# current record number
  my $LEX_POS = 0;		# current position in buffer
  my $LEX_OFFSET = 0;		# offset from the beginning
  my $LEX_TOKEN = '';		# token instance
  my %LEX_STATE = ();		# states

  $self->_saveClosureEnv();
  $self->_closureEnv(\(
		    $LEX_BUFFER,	
		    $LEX_LENGTH,	
		    $LEX_RECORD,		
		    $LEX_POS,	
		    $LEX_OFFSET,
		    %LEX_STATE,
		   ));		

  my $LEX_FHR = \$self->[$STREAM];
  my $stateMachine = $self->genStateMachine();
  my $analyzer = $self->getCode();
  eval qq!$stateMachine; \$self->[$LEXER_SUB] = sub $analyzer!;

  my $debug = 0;
  if ($@ or $debug) {	# can be useful ;-)
    my $line = 0;
    $stateMachine =~ s/^/sprintf("%3d ", $line++)/meg; # line numbers
    $analyzer =~ s/^/sprintf("%3d ", $line++)/meg;
    print STDERR "$stateMachine$analyzer\n";
    print STDERR "$@\n";
    die "\n" if $@;
  }
  $self->[$LEXER_SUB];
}

# Purpose: returns the lexical analyzer routine
# Arguments: nothing
# Returns: the anonymous sub implementing the lexical analyzer
sub getSub {
  my $self = shift;
  if (ref($self->[$LEXER_SUB]) eq 'CODE') {
    $self->[$LEXER_SUB];
  } else {
    $self->genLex();
  }
}
				# 
				# The State Machine
				# 
#package Parse::State;
sub inclusive {
  my $self = shift;
  if (ref $self) {		# instance method
    if (@_)  {
      $self->[$INCLUSIVE_COND]  = {@_};
    } else {
      $self->[$INCLUSIVE_COND];
    }
  } else {			# class method
    $self->prototype->inclusive(map { $_ => 1 } @_);
  }
}
sub exclusive {
  my $self = shift;
  if (ref $self) {		# instance method
    if (@_) {
      $self->[$EXCLUSIVE_COND]  = {@_};
    } else {
      $self->[$EXCLUSIVE_COND];
    }
  } else {			# class method
    $self->prototype->exclusive(map { $_ => 1 } @_);
  }
}
use constant GEN_CONDITION => 0;
sub genCondition {
  my $self = shift;
  my $specif = shift;
  return '' if $specif =~ /^ALL:/; # special condition

  my %exclusion = %{$self->exclusive};
  my %inclusion = %{$self->inclusive};
  return '' unless $specif or keys %exclusion;

  my $condition;
  my @condition;
  my $cond_group;
  my $cond_item;
  my @cond_group;
  if ($specif =~ /^(.+):/g) {	# Ex. A:B:C: or A,C: 
    my ($prefix) = ($1);
    foreach $cond_group (split /:/, $prefix) {
      foreach $cond_item (@cond_group = split /,/, $cond_group) {
	unless ($cond_item eq 'INITIAL' or 
		defined $exclusion{$cond_item} or 
		defined $inclusion{$cond_item}) {
	  require Carp;
	  Carp::croak "'$cond_item' condition not defined";
	}
	delete $exclusion{$cond_item};
	delete $inclusion{$cond_item};
      }
      push @condition, "(" . join(" or ", map { "\$$_" } @cond_group) . ")";
    }
    if (@condition == 1) {
      $condition = shift @condition;
    } else {
      $condition = "(" . join(" and ", @condition) . ")";
    }
  }
  my @tmp = ();
  if (@tmp = map { "\$$_" } keys(%exclusion)) {
    if ($condition) {
      $condition = "not (" . join(" or ", @tmp) . ") and $condition";
    } else {
      $condition = "not (" . join(" or ", @tmp) . ")";
    }
  } 
  print STDERR "genCondition(): $specif -> $condition\n" if GEN_CONDITION;
  $condition ne '' ? "$condition and" : '';
}
sub genStateMachine { 
  my $self = shift;
  my $somevar;

  my $stateDeclaration = 'my $INITIAL = 1;' .
    "\n" .
      q!$LEX_STATE{'INITIAL'} = \\$INITIAL;! . "\n";
  my $stateName = '';
  foreach $stateName (keys (%{$self->exclusive}), keys(%{$self->inclusive})) {
    $stateDeclaration .=
      q!my $! . "$stateName" . q! = 0; ! . 
	q!$LEX_STATE{'! . "$stateName" . q!'} = \\$! . "$stateName" . q!;!  . "\n";
  }
  $self->setStateMachine($stateDeclaration);
}
# not documented
sub setStateMachine {
  my $self = shift;
  $self->[$STATE_MACHINE_CODE] = shift;
}
# not documented
sub getStateMachine {
  my $self = shift;
  $self->[$STATE_MACHINE_CODE];
}
# not documented
sub getState {
  my $self = shift;
  my $state = shift;
  ${$self->[$STATES]->{$state}};
}
# not documented
sub setState {
  my $self = shift;
  my $state = shift;
  ${$self->[$STATES]->{$state}} = shift;
}
sub state {			# get/set state
  my $self = shift;
  my $state = shift;
  if (@_)  {
    ${$self->[$STATES]->{$state}} = shift;
  } else {
    ${$self->[$STATES]->{$state}};
  }
}
sub start {
  my $self = shift;
  my $state = shift;
  if ($state eq 'INITIAL') {
    $self->_restart() 
  } else {
    if (exists $self->[$EXCLUSIVE_COND]->{$state}) {
      $self->_restart;
    }
    ${$self->[$STATES]->{$state}} = 1;
  }
}
sub _restart {
  my $self = shift;
  my $state = shift;
  my $hashref = $self->[$STATES];
  foreach $state (keys %$hashref) {
    ${$hashref->{$state}} = 0;
  }
  ${$hashref->{'INITIAL'}} = 1;
}
sub end {
  my $self = shift;
  my $state = shift;
  ${$self->[$STATES]->{$state}} = 0;
}
#sub pushState {}
#sub popState {}
#sub topState {}

package Parse::Tokenizer;
@Parse::Tokenizer::ISA = qw/Parse::ALex/;

sub next { &{$_[0]->[$LEXER_SUB]} }
				# 
				# next() wrappers
				# 
# Purpose: Analyze all data in one call
# Arguments: string or stream to analyze
# Returns: self
# Todo: generate a specific lexer sub
sub parse {
  my $self = shift;
  unless (defined $_[0]) {
    require Carp;
    Carp::carp "no data to analyze";
  }
  $self->from($_[0]);
  my $next = $self->[$LEXER_SUB];
  &{$next}($self) until $self->[$EOI]; 
  # or:
  #  local *next = $self->[$SUB];
  #  &next($self) until $self->[$EOI]; 
  $self;
}
# Purpose: Analyze data in one call
# Arguments: string or stream to analyze
# Returns: list of token name and token text
# Todo: generate a specific lexer sub
sub analyze {
  my $self = shift;
  unless (defined $_[0]) {
    require Carp;
    Carp::carp "no data to analyze";
  }
  $self->from($_[0]);
  my $next = $self->[$LEXER_SUB]; 
  my $token = &{$next}($self);
  my @token = ($token->name, $token->text);
  until ($self->[$EOI]) {
    $token = &{$next}($self);
    push (@token, $token->name, $token->text);
  }
  @token;
}
# Remark: not documented
# Purpose: put the next token in a scalar reference
# Arguments: a scalar reference
# Returns: 1 if token isn't equal to the EOI token
sub nextis {			
  my $self = shift;
  unless (@_ == 1) {
    require Carp;
    Carp::croak "bad argument number";
  }
  if (ref $_[0]) {
    my $token = &{$self->[$LEXER_SUB]}($self);
    ${$_[0]} = $token;
    $token == $Parse::Token::EOI ? return 0 : return 1;
  } else {
    require Carp;
    Carp::croak "bad argument $_[0]";
  }
}
# Purpose: execute an action on each token
# Arguments: an anonymous sub to call on each token
# Returns: undef
sub every {			
  my $self = shift;
  my $do_on = shift;
  my $ref = ref($do_on);
  if (not $ref or $ref ne 'CODE') { 
    require Carp;
    Carp::croak "argument of the 'every' method must be an anonymous routine";
  }
  my $token = &{$self->[$LEXER_SUB]}($self);
  while (not $self->[$EOI]) {
    &{$do_on}($token);
    $token = &{$self->[$LEXER_SUB]}($self);
  }
  $self;
}
__PACKAGE__

__END__

=head1 NAME

C<Parse::ALex> - Generator of lexical analyzers - abstract class

=head1 SYNOPSIS

See the C<Parse::Lex> documentation.

=head1 DESCRIPTION

This is an abstract class used by C<Parse::Lex> and C<Parse::CLex>.

=head1 AUTHOR

Philippe Verdret.

=head1 COPYRIGHT

Copyright (c) 1999 Philippe Verdret. All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
