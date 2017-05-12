require 5.004;
use strict qw(vars);
use strict qw(refs);
use strict qw(subs);

package Parse::Token;		# or perhaps: Parse::AToken
$Parse::Token::VERSION = '2.21';
use Parse::Trace;
@Parse::Token::ISA = qw(Parse::Trace);

use vars qw($AUTOLOAD $trace $PENDING_TOKEN $EOI);
$trace = 0;

# other possibilities: pseudo-hash, constants (see The Perl Journal Spring 99)
my %_map;
my @attributes = qw(STATUS TEXT NAME CONDITION 
		    REGEXP SUB DECORATION LEXER HANDLER READ_MORE_RE EXPRESSION
		    TEMPLATE TRACE IN_PKG);
my($STATUS, $TEXT, $NAME, $CONDITION, 
   $REGEXP, $ACTION, $DECORATION, $LEXER, $HANDLER, $READ_MORE_RE, $EXPRESSION,
   $CODE, $TRACE, $IN_PKG) = @_map{@attributes} = (0..$#attributes);
sub _map { 
  shift;
  if (@_) {
    wantarray ? @_map{@_} : $_map{$_[0]}
  } else {
    @attributes;
  }
}

$EOI = Parse::Token->new('EOI');

#  new()
# Purpose: token constructor
# Arguments: see definition
# Returns: Return a token object
sub new {
  my $receiver = shift;
  my $class = (ref $receiver or $receiver);
  my $self = bless [], $class;

  my $debug = 0;
  print STDERR "@_\n" if $debug;
  print STDERR "@{$_[1]}\n" if $debug and ref $_[1];

				# initialize...
  $self->[$STATUS] = 0;		# object status
  $self->[$TEXT] = '';		# recognized text
  (
   $self->[$CONDITION], 	# associated conditions		
   $self->[$NAME],		# symbolic name
   $self->[$REGEXP],
   $self->[$ACTION],
   $self->[$EXPRESSION],
   $self->[$READ_MORE_RE],
   $self->[$HANDLER],
   $self->[$LEXER],
  ) = (
       $self->_parseName($_[0]), # condition + name 
       $_[1],			# regexp, can be an array reference
       $_[2],			# associated sub
       $_[3],			# expression (Token::Action)
       $_[4],			# read more data if $_[4] =~ $LEX_BUFFER
       $_[5],			# name of the event handler
       $_[6],			# lexer instance
      );
  $self->[$IN_PKG] = '';	# defined in this package
  $self->[$DECORATION] = {};	# token decoration
  $self->[$CODE] = '';		# generated code
  $self->[$TRACE] = $trace;	# trace
  $self;
}
# Purpose: export a token object in the caller's package or 
#          in the package returned by inpkg()
# Arguments: 
# Returns: the token object 
sub exportTo {
  my $self = shift;
  my $inpkg = $self->inpkg;
  unless (defined $inpkg) {
    $inpkg = caller;		# (caller(0))[0];	
    $self->inpkg($inpkg);
  }
  my $name = $self->name;
  no strict 'refs';	
  if ($^W and defined ${"$inpkg" . "::" . "$name"}) {
    require Carp;
    Carp::carp "the '${inpkg}::$name' token is already defined";
  }
  ${"$inpkg" . "::" . "$name"} = $self;
  $self;
}

# Purpose: create a list of token objects
# Arguments: a list of token specification or token objects
# Returns: list of token objects
sub factory { 
  my $self = shift;

  unless (defined($_[0])) {
    require Carp;
    Carp::croak "argument of the factory() method must be a list of token specifications";
  }
  my $sub;
  my $ref;
  my @token;			# returned list of tokens 
  my $token;
  my $arg;
  my $token_class = '';
  my $debug = 0;
  if (ref $_[0] eq 'ARRAY') {	# [Type => Segmented, Name => Xxxx, Etc.]
    my @args = @{$_[0]};
    my @specif = ();
    my $next_type = '';
    while (@args) {
      $arg = shift @args;
      if (ref $arg and $arg->isa(__PACKAGE__)) { 
	push @token, $arg;
      } elsif ($arg =~ /^[Tt]ype$/) {
	if (@specif) {
	  $token_class = $next_type;
	  unless ($token_class->isa(__PACKAGE__)) {
	    eval { require $token_class };
	    if ($@) {
	      require Carp;
	      Carp::croak "$@"; # "unable to access to the $token_class class";
	    }
	  }
	  print STDERR "$token_class - @specif\n" if $debug;
	  push @token, $token_class->new(@specif);
	  @specif = ();
	}
	$next_type = __PACKAGE__ . '::' . shift(@args);
      } else {
	push @specif, $arg;
      }
    }
    if (@specif) {
      $token_class = $next_type; # todo: load if not defined;
      print STDERR "$token_class - @specif\n" if $debug;
      push @token, $token_class->new(@specif);
      @specif = ();
    }
  } else {
    while (@_) {
      $arg = shift;
				# it's already an instance
      if (ref $arg and $arg->isa(__PACKAGE__)) { # isa()
	push @token, $arg;
      } else {			# parse the specification
	my($name, $regexp) = ($arg, shift);
	if (@_) {
	  $ref = ref($_[0]);
	  if ($ref and $ref eq 'CODE') { # if next arg is a sub reference
	    $sub = shift;
	  } else {
	    $sub = undef;
	  }
	} else {
	  $sub = undef;
	}
	unless (ref($regexp) eq 'ARRAY') {
	  $token_class = __PACKAGE__ . '::Simple';
	} else {
	  $token_class = __PACKAGE__ . '::Segmented';
	}
	push @token, $token_class->new(Name => $name, Regex => $regexp, Sub => $sub);
      }
    }
  }
  @token;
}
sub _parseName {
  my $self = shift;
  my $name = shift;
  my $condition = '';
  if ($name =~ /^(.+:)(.+)/) { # Ex. A:B:C:SYMBOL, A,C:SYMBOL
    ($condition, $name) = ($1, $2);
  }
  ($condition, $name);
}
sub code {
  my $self = shift;
  if (defined $_[0]) {
    $self->[$CODE] = $_[0];
  } else {
    $self->[$CODE];
  }
}
sub getCode {
  my $self = shift;
  my $part = shift;
  $self->[$CODE];
}
sub setCode {
  my $self = shift;
  $self->[$CODE] = shift;
}
sub condition {
  my $self = shift;
  if (@_) {
    $self->[$CONDITION] = shift;
  } else {
    $self->[$CONDITION];
  }
}
sub expression {
  my $self = shift;
  if (@_) {
    $self->[$EXPRESSION] = shift;
  } else {
    $self->[$EXPRESSION];
  }
}
sub readmore {
  my $self = shift;
  if (@_) {
    $self->[$READ_MORE_RE] = shift;
  } else {
    $self->[$READ_MORE_RE];
  }
}
sub AUTOLOAD {			# is this useful or dangerous? ;-)
  my $self = shift;
  return unless ref($self);
  return if $AUTOLOAD =~ /\bDESTROY$/;
  my $name = $AUTOLOAD;
  $name =~ s/.*://;
  my $value = shift;
  if (defined $value) { 
    ${$self->[$DECORATION]}{$name} = $value;
  } else {
    ${$self->[$DECORATION]}{$name};
  }
}
# set(ATTRIBUTE, VALUE)
# Purpose: set an attribute value
sub set {  ${$_[0]->[$DECORATION]}{$_[1]} = $_[2];}
# get(ATT)
# Purpose: return an attribute value
sub get {  ${$_[0]->[$DECORATION]}{$_[1]};}

sub inpkg {			# not documented
  my $self = shift;
  if (defined $_[0]) {
    $self->[$IN_PKG] = $_[0] 
  } else {
    $self->[$IN_PKG];
  }
}
# status()
# Purpose: Indicate is the last token search has succeeded or not
# Arguments:
# Returns:
sub status { 
  defined($_[1]) ? 
    $_[0]->[$STATUS] = $_[1] : 
      $_[0]->[$STATUS];
} 
# setText()
# Purpose: Return the symbolic name of the object
# Arguments:
# Returns: see purpose
# Extension: save $1, $2... in a list
sub setText    { $_[0]->[$TEXT] = $_[1] } # set token string

# getText()
# Purpose:
# Arguments:
# Returns:
sub getText    { $_[0]->[$TEXT] }	# get token string 

sub text { 
  defined($_[1]) ? 
    $_[0]->[$TEXT] = $_[1] : 
      $_[0]->[$TEXT];
} 

sub name { $_[0]->[$NAME] }	# name of the token
*type = \&name;			# synonym of the name() method

sub regexp { $_[0]->[$REGEXP] }	# regexp

sub handler { $_[0]->[$HANDLER] } # name of an event handler

# action()
# Purpose:
# Arguments:
# Returns:
sub action { $_[0]->[$ACTION] } # anonymous function

# lexer(EXP)
# lexer
# Purpose: Defines or returns the associated lexer
# Arguments:
# Returns:
sub lexer {		
  if (defined $_[1]) {
    $_[0]->[$LEXER] = $_[1];
  } else {
    $_[0]->[$LEXER];
  }
}	

sub getRegisteredLexerType {
  my $self = shift;
  my $type = shift;
  my $class = ref $self || $self;
  no strict 'refs';
  foreach (@{"${class}::REGISTERED_LEXER_TYPE"}) {
    return $_ if $type->isa("Parse::$_");
  }
  require Carp;
  Carp::croak "no template defined for the '$class' token in the '$type' lexer";
}
# not documented
sub do { 
  my $self = shift;
  &{(shift)}($self, @_)
}

# next()
# Purpose: Return the string token if token is the pending token
# Arguments: no argument
# Returns: a token string if token is found, else undef
# Remark: $PENDING_TOKEN  is set by the Parse::ALex class
sub next {			# return the token string 
  my $self = shift;
  my $lexer = $self->[$LEXER];
  my $pendingToken = $lexer->[$PENDING_TOKEN];
  if ($pendingToken == $EOI) {
    $self->[$STATUS] = $self == $EOI ? 1 : 0;
    return undef;		
  }
  $lexer->next() unless $pendingToken;
  if ($self == $lexer->[$PENDING_TOKEN]) {
    $lexer->[$PENDING_TOKEN] = 0; # now no pending token
    my $text = $self->[$TEXT];
    $self->[$TEXT] = '';
    $self->[$STATUS] = 1;
    $text;			# return token string
  } else {
    $self->[$STATUS] = 0;
    undef;
  }
}
# isnext()
# Purpose: Return the status of the token object, and the recognized string
# Arguments: scalar reference
# Returns: 
#  1. the object status
#  2. the recognized string is put in the scalar reference
sub isnext {
  my $self = shift;
  my $lexer = $self->[$LEXER];
  my $pendingToken = $lexer->[$PENDING_TOKEN];
  if ($pendingToken == $EOI) {
    ${$_[0]} = undef;
    return $self->[$STATUS] = $self == $EOI ? 1 : 0;
  }
  $lexer->next() unless $pendingToken;
  if ($self == $lexer->[$PENDING_TOKEN]) {
    $lexer->[$PENDING_TOKEN] = 0; # now no pending token
    ${$_[0]} = $self->[$TEXT];
    $self->[$TEXT] = '';
    $self->[$STATUS] = 1;
    1;
  } else {
    $self->[$STATUS] = 0;
    ${$_[0]} = undef;
    0;
  }
}

package Parse::Token::Action;	
use Parse::Template;
@Parse::Token::Action::ISA = qw(Parse::Token Parse::Trace);

use vars qw(%TEMPLATE $template);
%TEMPLATE = 
(EXPRESSION_PART => q!
 %%$CONDITION%%
 %%$EXPRESSION%%
 !
);
$template = new Parse::Template(%TEMPLATE);
sub new {
  my $receiver = shift;
  my ($name, $expression) = $receiver->_parse(@_);
  my $token = $receiver->SUPER::new($name, '', '', $expression);
  $token;
}
sub _parse {
  my $self = shift;
  unless (@_ >= 2) {
    require  Carp;
    Carp::croak "bad argument number (@_)";
  }
  my ($key, $value);
  my ($name, $expression);
  my $escape = '';
  while (@_ >= 2) {
    ($key, $value) = (shift, shift);
    if ($key =~ /^[Nn]ame$/) {
      $name = $value;
    } elsif ($key =~ /^[Ee]xpr$/) {
      $expression = $value;
    } else {
      require  Carp;
      Carp::croak "'$key' is an invalid attribute for a ", __PACKAGE__, "'s instance";
    }
  }
  ($name, $expression);
}
sub genCode {
  my $self = shift;

  my $lexer = $self->lexer;
  my $tokenid = $lexer->inpkg() . '::' . $self->name();
  my $condition = $lexer->genCondition($self->condition);
  my $expression = $self->expression;

  $template->env(
		 CONDITION => $condition,
		 EXPRESSION => $expression,
		); 
  my $code = $template->eval('EXPRESSION_PART');
  $self->code($code);
  $code;
}

package Parse::Token::Simple;
use Parse::Trace;
use Parse::Template;
@Parse::Token::Simple::ISA = qw(Parse::Token Parse::Trace);

sub new {
  my $receiver = shift;
  my $token = $receiver->SUPER::new($receiver->_parse(@_));
  $token;
}
sub _parse {
  my $self = shift;
  unless (@_ >= 2) {
    require  Carp;
    Carp::croak "bad argument number (@_)";
  }
  my ($name, $regex, $action, $expression, $readif, $handler) =
    ('', '', '', '', '', '');
  my ($key, $value, $escape);
  while (@_ >= 2) {
    ($key, $value) = (shift, shift);
    if ($key =~ /^[Nn]ame$/) {
      $name = $value;
    } elsif ($key =~ /^(?:[Rr]egexp?|[Rr]e)$/) {
      $regex = $value;
    #} elsif ($key =~ /^[Rr]ead[Ii]f$/) { # regexp for continuation
    } elsif ($key =~ /^[Rr]eadMore$/) { # regexp for continuation
      $readif = $value == 1 ? "\$" : '';
    } elsif ($key =~ /^[Ss]ub$/) {
      $action = $value;
    } elsif ($key =~ /^[Hh]andler$/) {
      $handler = $value;
    } else {
      require  Carp;
      Carp::croak "'$key' is an invalid attribute for a ", __PACKAGE__, "'s instance";
    }
  }
  ($name, $regex, $action, $expression, $readif, $handler);
}

use vars qw(%TEMPLATE @REGISTERED_LEXER_TYPE $template);
@REGISTERED_LEXER_TYPE = qw(Lex CLex LexEvent);
%TEMPLATE = ();
####################################### Parse::Token::Simple - Parse::Lex class
$TEMPLATE{'LEX_HEADER_PART'} = q!
   %%$CONDITION%%
   $LEX_BUFFER =~ /\G(?:%%$REGEXP%%)/cg and do {
     %%$READ_MORE_RE ne '' ? LEX_READ_MORE_DATA_PART() : LEX_SET_TOKEN_PART()%%
     %%$WITH_TRACE ? LEX_TRACE_PART() : '' %%
     %%$WITH_SUB ? LEX_FOOTER_WITH_SUB_PART() : LEX_FOOTER_PART() %%
!;
$TEMPLATE{'LEX_READ_MORE_DATA_PART'} = q!
  my $pos = pos($LEX_BUFFER);
  my $line;
  $textLength = $pos - $LEX_POS;
  $pos = pos($LEX_BUFFER);
  while ($LEX_BUFFER =~ /\G(?:%%$READ_MORE_RE%%)/cg) {
     $line = <$LEX_FH>;	
     if (defined $line) {
       $LEX_BUFFER .= $line;
       pos($LEX_BUFFER) = $pos;
       if ($LEX_BUFFER =~ /\G(?:%%$REGEXP%%)/cg) {
	 $pos = pos($LEX_BUFFER);
       } else {
	 last;
       }
     }
  }
  $textLength = pos($LEX_BUFFER) - $LEX_POS;
  $content = substr($LEX_BUFFER, $LEX_POS, $textLength); # $&
  $LEX_LENGTH = CORE::length($LEX_BUFFER); 
  $LEX_OFFSET += $textLength;
  $LEX_POS += $textLength;
!;
$TEMPLATE{'LEX_SET_TOKEN_PART'} = q!
     $textLength = pos($LEX_BUFFER) - $LEX_POS;
     $content = substr($LEX_BUFFER, $LEX_POS, $textLength); # $&
     $LEX_OFFSET += $textLength;
     $LEX_POS += $textLength;
!;
$TEMPLATE{'LEX_TRACE_PART'} = q!
     if ($self->[%%$TRACE%%]) {
       my $tmp = '%%$REGEXP%%';
       my $trace = "Token read (" . $%%$TOKEN_ID%%->name . ", $tmp): $content"; 
       $self->context($trace);
     }
!;
$TEMPLATE{'LEX_FOOTER_WITH_SUB_PART'} = q!
    $%%$TOKEN_ID%%->setText($content);
    $self->[%%$PENDING_TOKEN%%] = $LEX_TOKEN = $%%$TOKEN_ID%%;
    $content = &{$%%$TOKEN_ID%%->action}($LEX_TOKEN, $content);
    ($LEX_TOKEN = $self->getToken)->setText($content);
    #print STDERR $LEX_TOKEN->name, " ", $self->[%%$PENDING_TOKEN%%]->name, " $content\n";
    %%$WITH_TRACE ? LEX_FOOTER_WITH_SUB_TRACE_PART() : ''%%
    last CASE;
  };
!;
$TEMPLATE{'LEX_FOOTER_WITH_SUB_TRACE_PART'} = q!
    if ($self->[%%$PENDING_TOKEN%%] ne $LEX_TOKEN) {
     if ($self->[%%$TRACE%%]) { # Trace
	    $self->context("Token type has changed - " .
			   "Type: " . $LEX_TOKEN->name .
			   " - Content: $content\n");
	  }
	}
!;
$TEMPLATE{'LEX_FOOTER_PART'} = q!
    $%%$TOKEN_ID%%->setText($content);
    $LEX_TOKEN = $%%$TOKEN_ID%%;
    last CASE;
   };
!;
####################################### Parse::Token::Simple - Parse::LexEvent class
$TEMPLATE{'LEXEVENT_HEADER_PART'} = q!
   %%$CONDITION%%
   $LEX_BUFFER =~ /\G(?:%%$REGEXP%%)/cg and do {
     %%$READ_MORE_RE ne '' ? LEX_READ_MORE_DATA_PART() : LEXEVENT_SET_TOKEN_PART()%%
     %%$WITH_TRACE ? LEXEVENT_TRACE_PART() : '' %%
     %%$TOKEN_HANDLER%%($%%$TOKEN_ID%%, $content);
    redo PARSE;
  };
!;
$TEMPLATE{'LEX_READ_MORE_DATA_PART'} = q!
  my $pos = pos($LEX_BUFFER);
  my $line;
  $textLength = $pos - $LEX_POS;
  $pos = pos($LEX_BUFFER);
  while ($LEX_BUFFER =~ /\G(?:%%$READ_MORE_RE%%)/cg) {
     $line = <$LEX_FH>;	
     if (defined $line) {
         $LEX_BUFFER .= $line;
         pos($LEX_BUFFER) = $pos;
	 if ($LEX_BUFFER =~ /\G(?:%%$REGEXP%%)/cg) {
	   $pos = pos($LEX_BUFFER);
	 } else {
	   last;
	 }
     }
  }
  $textLength = pos($LEX_BUFFER) - $LEX_POS;
  $content = substr($LEX_BUFFER, $LEX_POS, $textLength); # $&
  $LEX_LENGTH = CORE::length($LEX_BUFFER); 
  $LEX_OFFSET += $textLength;
  $LEX_POS += $textLength;
!;
$TEMPLATE{'LEXEVENT_SET_TOKEN_PART'} = q!
     $textLength = pos($LEX_BUFFER) - $LEX_POS;
     $content = substr($LEX_BUFFER, $LEX_POS, $textLength); # $&
     $LEX_OFFSET += $textLength;
     $LEX_POS += $textLength;
!;
$TEMPLATE{'LEXEVENT_TRACE_PART'} = q!
     if ($self->[%%$TRACE%%]) {
       my $tmp = '%%$REGEXP%%';
       my $trace = "Token read (" . $%%$TOKEN_ID%%->name . ", $tmp): $content"; 
       $self->context($trace);
     }
!;
####################################### Parse::Token::Simple - Parse::CLex class
$TEMPLATE{'CLEX_HEADER_PART'} = q!
   %%$CONDITION%%
   $LEX_BUFFER =~ s/^(?:%%$REGEXP%%)// and do {
     $content = $&;
     $textLength = CORE::length($content);
     $LEX_OFFSET += $textLength;
     $LEX_POS += $textLength;
     %%$WITH_TRACE ? CLEX_TRACE_PART() : '' %%
     %%$WITH_SUB ? CLEX_FOOTER_WITH_SUB_PART() : CLEX_FOOTER_PART() %%
!;
$TEMPLATE{'CLEX_TRACE_PART'} = q!
     if ($self->[%%$TRACE%%]) {
       my $tmp = '%%$REGEXP%%';
       my $trace = "Token read (" . $%%$TOKEN_ID%%->name . ", $tmp): $content"; 
       $self->context($trace);
     }
!;

$TEMPLATE{'CLEX_FOOTER_WITH_SUB_PART'} = q!
     $%%$TOKEN_ID%%->setText($content);
     $self->[%%$PENDING_TOKEN%%] = $LEX_TOKEN = $%%$TOKEN_ID%%;
     $content = &{$%%$TOKEN_ID%%->action}($LEX_TOKEN, $content);
     ($LEX_TOKEN = $self->getToken)->setText($content);
     %%$WITH_TRACE ? CLEX_FOOTER_WITH_SUB_TRACE_PART() : ''%%
     last CASE;
  };
!;
$TEMPLATE{'CLEX_FOOTER_WITH_SUB_TRACE_PART'} = q!
        if ($self->[%%$PENDING_TOKEN%%] ne $LEX_TOKEN) {
	  if ($self->isTrace) {
	    $self->context("token type has changed - " .
			   "Type: " . $LEX_TOKEN->name .
			   " - Content: $content\n");
	  }
	}
!;
$TEMPLATE{'CLEX_FOOTER_PART'} = q!
     $%%$TOKEN_ID%%->setText($content);
     $LEX_TOKEN = $%%$TOKEN_ID%%;
     last CASE;
   };
!;
$template = new Parse::Template(%TEMPLATE);
sub genCode {
  my $self = shift;

  my $lexer = $self->lexer;
  my($TRACE, $EOI, $HOLD_TEXT,  $PENDING_TOKEN) =
    $lexer->_map('TRACE', 'EOI', 'HOLD_TEXT', 'PENDING_TOKEN');

  my $tokenid = $lexer->inpkg() . '::' . $self->name();
  my $condition = $lexer->genCondition($self->condition);
  my $with_sub = $self->action ? 1 : 0;
  my $readmore =   $lexer->isFromString ? '' : $self->readmore;
  my $handler = $self->handler || $tokenid;
  $handler = $handler =~ /::/ ? $handler : $lexer->inpkg . '::' . $handler;

  $template->env(
		 CONDITION => $condition,
		 TOKEN_ID=> $tokenid,
		 TOKEN_HANDLER => $handler,
		 SKIP => $lexer->skip,
		 'IS_HOLD' => $lexer->isHold,
		 'WITH_TRACE' => $lexer->isTrace,
		 READ_MORE_RE => $readmore,
		 'WITH_SUB' => $with_sub,
		 'HOLD_TEXT' => $HOLD_TEXT,
		 'EOI' => $EOI,
		 'TRACE' => $TRACE,
		 'PENDING_TOKEN' => $PENDING_TOKEN,
		); 

  my $ppregexp = $template->ppregexp($self->regexp);
  my $debug = 0;
  if ($debug) {
    print STDERR "REGEXP[$tokenid]->\t\t$ppregexp\n";
  }
  $template->env('REGEXP' => $ppregexp);
  # find the template code defined for this lexer type
  my $lexer_type = __PACKAGE__->getRegisteredLexerType(ref $lexer);
  my $code = $template->eval("\U$lexer_type" . '_HEADER_PART');
  $self->code($code);
  $code;
}

package Parse::Token::Segmented; 
use Parse::Trace;
@Parse::Token::Segmented::ISA = qw(Parse::Token Parse::Trace);
sub new {
  my $receiver = shift;
  #my ($name, $regex, $action) = $receiver->_parse(@_);
  my $token = $receiver->SUPER::new($receiver->_parse(@_));
  $token;
}
sub _parse {
  my $self = shift;
  unless (@_ >= 2) {
    require  Carp;
    Carp::croak "bad argument number (@_)";
  }
  my ($name, $regex, $action, $expression, $readif, $handler) = 
    ('', '', '', '', '', '');
  my ($key, $value, $escape) = ('', '', '');
  while (@_ >= 2) {
    ($key, $value) = (shift, shift);
    if ($key =~ /^[Nn]ame$/) {
      $name = $value;
    } elsif ($key =~ /^(?:[Rr]egexp?|[Rr]e)$/) {
      $regex = $value;
    } elsif ($key =~ /^[Ss]ub$/) {
      $action = $value;
    } elsif ($key =~ /^[Hh]andler$/) {
      $handler = $value;
    } else {
      require  Carp;
      Carp::croak "'$key' is an invalid attribute for a ", __PACKAGE__, "'s instance";
    }
  }
  ($name, $regex, $action, $expression, $readif, $handler);
}

use vars qw(%TEMPLATE @REGISTERED_LEXER_TYPE);
@REGISTERED_LEXER_TYPE = qw(Lex CLex LexEvent);
%TEMPLATE = ();
####################################### Parse::Token::Segmented - Parse::Lex class
$TEMPLATE{'LEX_HEADER_PART'} = q!
  %%$FROM_STRING ? LEX_HEADER_STRING_PART() : LEX_HEADER_STREAM_PART() %%
!;

$TEMPLATE{'LEX_HEADER_STRING_PART'} = q!
   %%$CONDITION%%
   $LEX_BUFFER =~ /\G(?:%%$REGEXP%%)/cg and do {
     $textLength = pos($LEX_BUFFER) - $LEX_POS; # length $&
     $content = substr($LEX_BUFFER, $LEX_POS, $textLength); # $&
     $LEX_OFFSET += $textLength;
     $LEX_POS += $textLength;
     %%$WITH_TRACE ? LEX_TOKEN_TRACE_PART() : '' %%
     %%$WITH_SUB ? LEX_FOOTER_WITH_SUB_PART() : LEX_FOOTER_PART() %%
!;
$TEMPLATE{'LEX_HEADER_STREAM_PART'} = q@
    %%$CONDITION%%
    $LEX_BUFFER =~ /\G(?:%%"$REGEXP_START"%%)/cg and do {
      my $before_pos = $LEX_POS;
      my $start_pos = pos($LEX_BUFFER);
      my $tmp = substr($LEX_BUFFER, $start_pos); 
      my $line_read = 0;
      # don't use \G 
      #print STDERR "before: $LEX_POS - initpos: $start_pos - tmp: $tmp\n";
      unless ($tmp =~ /^(?:%%"$REGEXP_MIDDLE$REGEXP_END"%%)/g) {
	my $line = '';
	do {
	  while (1) {
	    $line = <$LEX_FH>;
	    $line_read = 1;
	    unless (defined($line)) { # 
	      $self->[%%$EOI%%] = 1;
	      $LEX_TOKEN = $Parse::Token::EOI;
	      require Carp;
	      Carp::croak "unable to find end of the '", $%%$TOKEN_ID%%->name, "' token";
	    }
	    $LEX_RECORD++;
	    $tmp .= $line;
	    last if $line =~ /%%$REGEXP_END%%/;
	  }
	} until ($tmp =~ /^(?:%%"$REGEXP_MIDDLE$REGEXP_END"%%)/g); # don't forget /g
      }
      $LEX_POS = $start_pos + pos($tmp);
      $LEX_OFFSET += $LEX_POS;
      if ($line_read) {
	$LEX_BUFFER = substr($LEX_BUFFER, 0, $start_pos) . $tmp;
	$LEX_LENGTH = CORE::length($LEX_BUFFER); 
      } 
      $content = substr($LEX_BUFFER, $before_pos, $LEX_POS - $before_pos);
      pos($LEX_BUFFER) = $LEX_POS;
      #print STDERR "LEX_BUFFER: $LEX_BUFFER\n";
      #print STDERR "pos: $before_pos - length: ", $LEX_POS -$before_pos, " - content->$content<-\n";
      %%$WITH_TRACE ? LEX_TOKEN_TRACE_PART() : '' %%
      %%$WITH_SUB ? LEX_FOOTER_WITH_SUB_PART() : LEX_FOOTER_PART() %%
@;
$TEMPLATE{'LEX_TOKEN_TRACE_PART'} = q!
     if ($self->[%%$TRACE%%]) { # Trace
       my $tmp = '%%$REGEXP%%';
       my $trace = "Token read (" . $%%$TOKEN_ID%%->name . ", $tmp): $content"; 
        $self->context($trace);
     }
!;
$TEMPLATE{'LEX_FOOTER_WITH_SUB_PART'} = q!
    $%%$TOKEN_ID%%->setText($content);
    $self->[%%$PENDING_TOKEN%%] = $LEX_TOKEN = $%%$TOKEN_ID%%;
    $content = &{$%%$TOKEN_ID%%->action}($LEX_TOKEN, $content);
    ($LEX_TOKEN = $self->getToken)->setText($content);
     %%$WITH_TRACE ? LEX_FOOTER_WITH_SUB_TRACE_PART() : ''%%
    last CASE;
  };
!;
$TEMPLATE{'LEX_FOOTER_WITH_SUB_TRACE_PART'} = q!
    if ($self->[%%$PENDING_TOKEN%%] ne $LEX_TOKEN) {
     if ($self->[%%$TRACE%%]) { # Trace
	    $self->context("Token type has changed - " .
			   "Type: " . $LEX_TOKEN->name .
			   " - Content: $content\n");
	  }
	}
!;
$TEMPLATE{'LEX_FOOTER_PART'} = q!
    $%%$TOKEN_ID%%->setText($content);
    $LEX_TOKEN = $%%$TOKEN_ID%%;
    last CASE;
   };
!;
####################################### Parse::Token::Segmented - Parse::LexEvent class
$TEMPLATE{'LEXEVENT_HEADER_PART'} = q!
  %%$FROM_STRING ? LEXEVENT_HEADER_STRING_PART() : LEXEVENT_HEADER_STREAM_PART() %%
!;

$TEMPLATE{'LEXEVENT_HEADER_STRING_PART'} = q!
   %%$CONDITION%%
   $LEX_BUFFER =~ /\G(?:%%$REGEXP%%)/cg and do {
     $textLength = pos($LEX_BUFFER) - $LEX_POS;
     $content = substr($LEX_BUFFER, $LEX_POS, $textLength); # $&
     $LEX_OFFSET += $textLength;
     $LEX_POS += $textLength;
     %%$WITH_TRACE ? LEXEVENT_TRACE_PART() : '' %%
     %%$TOKEN_HANDLER%%($%%$TOKEN_ID%%, $content);
    redo PARSE;
  };
!;
$TEMPLATE{'LEXEVENT_HEADER_STREAM_PART'} = q@
    %%$CONDITION%%
    $LEX_BUFFER =~ /\G(?:%%"$REGEXP_START"%%)/cg and do {
      my $before_pos = $LEX_POS;
      my $start_pos = pos($LEX_BUFFER);
      my $tmp = substr($LEX_BUFFER, $start_pos); 
      my $line_read = 0;
      # don't use \G 
      #print STDERR "before: $LEX_POS - initpos: $start_pos - tmp: $tmp\n";
      unless ($tmp =~ /^(?:%%"$REGEXP_MIDDLE$REGEXP_END"%%)/g) {
	my $line = '';
	do {
	  while (1) {
	    $line = <$LEX_FH>;
	    $line_read = 1;
	    unless (defined($line)) { # 
	      $self->[%%$EOI%%] = 1;
	      $LEX_TOKEN = $Parse::Token::EOI;
	      require Carp;
	      Carp::croak "unable to find end of the '", $%%$TOKEN_ID%%->name, "' token";
	    }
	    $LEX_RECORD++;
	    $tmp .= $line;
	    last if $line =~ /%%$REGEXP_END%%/;
	  }
	} until ($tmp =~ /^(?:%%"$REGEXP_MIDDLE$REGEXP_END"%%)/g); # don't forget /g
      }
      $LEX_POS = $start_pos + pos($tmp);
      $LEX_OFFSET += $LEX_POS;
      if ($line_read) {
         $LEX_BUFFER = substr($LEX_BUFFER, 0, $start_pos) . $tmp;
         $LEX_LENGTH = CORE::length($LEX_BUFFER); 
      } 
      $content = substr($LEX_BUFFER, $before_pos, $LEX_POS - $before_pos);
      pos($LEX_BUFFER) = $LEX_POS;
      #print STDERR "LEX_BUFFER: $LEX_BUFFER\n";
      #print STDERR "pos: $before_pos - length: ", $LEX_POS -$before_pos, " - content->$content<-\n";
      %%$WITH_TRACE ? LEXEVENT_TRACE_PART() : '' %%
      %%$TOKEN_HANDLER%%($%%$TOKEN_ID%%, $content);
     redo PARSE;
   };
@;
$TEMPLATE{'LEXEVENT_TRACE_PART'} = q!
     if ($self->[%%$TRACE%%]) {
       my $tmp = '%%$REGEXP%%';
       my $trace = "Token read (" . $%%$TOKEN_ID%%->name . ", $tmp): $content"; 
       $self->context($trace);
     }
!;
####################################### Parse::Token::Segmented - Parse::CLex class
$TEMPLATE{'CLEX_HEADER_PART'} = q!
  %%$FROM_STRING ? CLEX_HEADER_STRING_PART() : CLEX_HEADER_STREAM_PART() %%
!;
$TEMPLATE{'CLEX_HEADER_STRING_PART'} = q!
   %%$CONDITION%%
   $LEX_BUFFER =~ s/^(?:%%$REGEXP%%)// and do {
     $content = $&;
     $textLength = CORE::length($content);
     $LEX_OFFSET += $textLength;
     $LEX_POS += $textLength;
     %%$WITH_TRACE ? CLEX_TOKEN_TRACE_PART() : '' %%
     %%$WITH_SUB ? CLEX_FOOTER_WITH_SUB_PART() : CLEX_FOOTER_PART() %%
!;
$TEMPLATE{'CLEX_HEADER_STREAM_PART'} = q!
    %%$CONDITION%%
    $LEX_BUFFER =~ s/^(?:%%$REGEXP_START%%)// and do {
      my $string = $LEX_BUFFER;
      $content = $&;
      my $length = CORE::length($content) + CORE::length($LEX_BUFFER);
     do {
       until ($string =~ /%%$REGEXP_END%%/) {
	 $string = <$LEX_FH>;
	 unless (defined($string)) { # 
           $self->[%%$EOI%%] = 1;
           $LEX_TOKEN = $Parse::Token::EOI;
	   require Carp;
	   Carp::croak "unable to find end of the '", $%%$TOKEN_ID%%->name, "' token";
	 }
	 $length = CORE::length($string);
	 $LEX_RECORD++;
	 $LEX_BUFFER .= $string;
       }
       $string = '';
     } until ($LEX_BUFFER =~ s/^(?:%%"$REGEXP_MIDDLE$REGEXP_END"%%)//);
     $content .= $&;
     $textLength = CORE::length($content);
     $LEX_OFFSET += $textLength;
     $LEX_POS += $length - CORE::length($LEX_BUFFER);	
     %%$WITH_TRACE ? CLEX_TOKEN_TRACE_PART() : '' %%
     %%$WITH_SUB ? CLEX_FOOTER_WITH_SUB_PART() : CLEX_FOOTER_PART() %%
!;
$TEMPLATE{'CLEX_TOKEN_TRACE_PART'} = q!
     if ($self->[%%$TRACE%%]) { # Trace
       my $tmp = '%%$REGEXP%%';
       my $trace = "Token read (" . $%%$TOKEN_ID%%->name . ", $tmp): $content"; 
        $self->context($trace);
     }
!;
$TEMPLATE{'CLEX_FOOTER_WITH_SUB_PART'} = q!
     $%%$TOKEN_ID%%->setText($content);
     $self->[%%$PENDING_TOKEN%%] = $LEX_TOKEN = $%%$TOKEN_ID%%;
     $content = &{$%%$TOKEN_ID%%->action}($LEX_TOKEN, $content);
     ($LEX_TOKEN = $self->getToken)->setText($content);
     %%$WITH_TRACE ? CLEX_FOOTER_WITH_SUB_TRACE_PART() : ''%%
     last CASE;
  };
!;
$TEMPLATE{'CLEX_FOOTER_WITH_SUB_TRACE_PART'} = q!
        if ($self->[%%$PENDING_TOKEN%%] ne $LEX_TOKEN) {
	  if ($self->isTrace) {
	    $self->context("token type has changed - " .
			   "Type: " . $LEX_TOKEN->name .
			   " - Content: $content\n");
	  }
	}
!;
$TEMPLATE{'CLEX_FOOTER_PART'} = q!
     $%%$TOKEN_ID%%->setText($content);
     $LEX_TOKEN = $%%$TOKEN_ID%%;
     last CASE;
   };
!;
my $template = new Parse::Template(%TEMPLATE);
sub genCode {
  my $self = shift;
  my $debug = 0;

  my $lexer = $self->lexer;
  my $tokenid = $lexer->inpkg() . '::' . $self->name();
  my $condition = $lexer->genCondition($self->condition);
  my $handler = $self->handler || $tokenid;
  $handler = $handler =~ /::/ ? $handler : $lexer->inpkg . '::' . $handler;

  my($TRACE, $EOI, $HOLD_TEXT,  $PENDING_TOKEN) =
    $lexer->_map('TRACE', 'EOI', 'HOLD_TEXT', 'PENDING_TOKEN');

  my $with_sub = $self->action ? 1 : 0;
  $template->env(
		 'CONDITION' => $condition,
		 'TOKEN_ID' => $tokenid,
		 TOKEN_HANDLER => $handler,
		 'SKIP' => $lexer->skip,
		 'FROM_STRING' => $lexer->isFromString,
		 'IS_HOLD' => $lexer->isHold,
		 'WITH_TRACE' => $lexer->isTrace,
		 'WITH_SUB' => $with_sub,
		 'HOLD_TEXT' => $HOLD_TEXT,
		 'EOI' => $EOI,
		 'TRACE' => $TRACE,
		 'PENDING_TOKEN' => $PENDING_TOKEN,
		); 

  my $ppregexp;
  my $tmpregexp;
  my $regexp = $self->regexp;
  print STDERR "REGEXP[$tokenid]->\t\t@{$self->[$REGEXP]}\n" if $debug;

  if ($#{$regexp} >= 3) {
    require Carp;
    Carp::carp join  " " , "Warning!", $#{$regexp} + 1, 
    "arguments in token definition";
  }
  $ppregexp = $tmpregexp = $template->ppregexp(${$regexp}[0]);
  $template->env('REGEXP_START' => $ppregexp);

  $ppregexp = ${$regexp}[1] ? $template->ppregexp(${$regexp}[1]) : '(?:.*?)';
  $tmpregexp .= $ppregexp;
  $template->env('REGEXP_MIDDLE' => $ppregexp);

  $ppregexp = $template->ppregexp(${$regexp}[2] or ${$regexp}[0]);
  $template->env('REGEXP_END' => $ppregexp);
  $ppregexp = "$tmpregexp$ppregexp";

  if ($debug) {
    print STDERR "REGEXP[$tokenid]->\t\t$ppregexp\n";
  }
  $template->env('REGEXP' => $ppregexp);

  # find the template code defined for this lexer type
  my $lexer_type = __PACKAGE__->getRegisteredLexerType(ref $lexer);
  my $code = $template->eval("\U$lexer_type" . '_HEADER_PART');
  $self->code($code);
  $code;
}

package Parse::Token::Delimited;
use Parse::Trace;
@Parse::Token::Delimited::ISA = qw(Parse::Token::Segmented Parse::Trace);

# Examples:
# [qw(/[*] (?s:.*?) [*]/)]
# [qw(<!-- (?s:.*?) -->)]
# [qw(<[?] (?s:.*?) [?]>)]

sub _parse {
  my $self = shift;
  unless (@_ >= 2) {
    require  Carp;
    Carp::croak "bad argument number (@_)";
  }
  my ($name, $regex, $action, $expression, $readif, $handler) = 
    ('', '', '', '', '', '');
  my ($key, $value, $start, $end, $escape) = ('', '');
  while (@_ >= 2) {	
    ($key, $value) = (shift, shift);
    if ($key =~ /^[Nn]ame$/) {
      $name = $value;
    } elsif ($key =~ /^[Ss]tart$/) {
      $start = $value;
      $end = $value unless defined $end;
    } elsif ($key =~ /^[Ee]nd$/) {
      $end = $value;
      $start = $value unless defined $start;
    } elsif ($key =~ /^[Ss]ub$/) {
      $action = $value;
    } elsif ($key =~ /^[Hh]andler$/) {
      $handler = $value;
    } else {
      require  Carp;
      Carp::croak "'$key' is an invalid attribute for a ", __PACKAGE__, "'s instance";
    }
  }
  unless (defined $start) {
    require Carp;
    Carp::croak "'Start' regex not defined";
  }
  unless (defined $end) {
    require Carp;
    Carp::croak "'End' regex not defined";
  }
  $regex = $self->_buildRegexp($start, $end);
  ($name, $regex, $action, $expression, $readif, $handler);
}
sub _buildRegexp {
  my $self = shift;
  my ($start, $end) = @_;
  my $content;
  $content = q!(?s:.*?)!;
  #print STDERR "[$start, $content, $end]\n";
  [$start, $content, $end];
}

package Parse::Token::Quoted;
use Parse::Trace;
@Parse::Token::Quoted::ISA = qw(Parse::Token::Segmented Parse::Trace);

sub _parse {
  my $self = shift;
  unless (@_ >= 2) {
    require  Carp;
    Carp::croak "bad argument number (@_)";
  }

  my ($name, $regex, $action, $expression, $readif, $handler) = 
    ('', '', '', '', '', '');
  my ($key, $value, $start, $end, $escape) = ('', '');
  while (@_ >= 2) {	
    ($key, $value) = (shift, shift);
    if ($key =~ /^[Nn]ame$/) {
      $name = $value;
    } elsif ($key =~ /^[Qq]uote$/) {
      $start = $value unless defined $start;
      $end = $value unless defined $end;
    } elsif ($key =~ /^[Ss]tart$/) {
      $start = $value;
      $end = $value unless defined $end;
    } elsif ($key =~ /^[Ee]nd$/) {
      $end = $value;
      $start = $value unless defined $start;
    } elsif ($key =~ /^[Ee]scape$/) {
      $escape = $value;
    } elsif ($key =~ /^[Ss]ub$/) {
      $action = $value;
    } elsif ($key =~ /^[Hh]andler$/) {
      $handler = $value;
    } else {
      require  Carp;
      Carp::croak "'$key' is an invalid attribute for a ", __PACKAGE__, "'s instance";
    }
  }
  unless (defined $start) {
    require Carp;
    Carp::croak "'Start' char not defined";
  }
  unless (defined $end) {
    require Carp;
    Carp::croak "'end' char not defined";
  }
  $regex = $self->_buildRegexp($start, $end, $escape);
  ($name, $regex, $action, $expression, $readif, $handler);
}
# Examples:
# [qw(" [^"]+(?:""[^"]*)* ")]
# [qw(" [^\\"]+(?:\\.[^\\"]*)* ")]
sub _buildRegexp {
  my $self = shift;
  my ($start, $end, $escape) = @_;
  my $content;
  $start = quotemeta $start;
  $end = quotemeta $end;
  if (defined $escape and $escape ne '') {
    $escape = quotemeta $escape;
    $content = qq![^$end$escape]*(?:$escape.! . qq![^$end$escape]*)*!;
  } else {
    $content = qq![^$end]*(?:$end$end! . qq![^$end]*)*!;
  } 
  #print STDERR "[$start, $content, $end]\n";
  [$start, $content, $end];
}

package Parse::Token::Nested;
use Parse::Trace;
@Parse::Token::Nested::ISA = qw(Parse::Trace);

# Examples:
# (+ (* 3 4) 4)
# 
sub new {
  die "Sorry! Not yet implemented";
}

1;
__END__

=head1 NAME

C<Parse::Token> - Definition of tokens used by C<Parse::Lex>

=head1 SYNOPSIS

        require 5.005;

        use Parse::Lex;
        @token = qw(
            ADDOP    [-+]
            INTEGER  [1-9][0-9]*
           );

        $lexer = Parse::Lex->new(@token);
        $lexer->from(\*DATA);

        $content = $INTEGER->next;
        if ($INTEGER->status) {
          print "$content\n";
        }
        $content = $ADDOP->next;
        if ($ADDOP->status) {
          print "$content\n";
        }
        if ($INTEGER->isnext(\$content)) {
          print "$content\n";
        }
        __END__
        1+2

=head1 DESCRIPTION

The C<Parse::Token> class and its derived classes permit defining the
tokens used by C<Parse::Lex> or C<Parse::LexEvent>.

The creation of tokens can be done by means of the C<new()> or
C<factory()> methods.  The C<Lex::new()> method of the C<Parse::Lex>
package indirectly creates instances of the tokens to be recognized.

The C<next()> or C<isnext()> methods of the C<Parse::Token> package
permit interfacing the lexical analyzer with a syntactic analyzer
of recursive descent type.  For interfacing with C<byacc>, see the
C<Parse::YYLex> package.

C<Parse::Token> is included indirectly by means of C<use Parse::Lex> or
C<use Parse::LexEvent>.

=head1 Methods

=over 4

=item action

Returns the anonymous subroutine defined within the C<Parse::Token> object.

=item factory LIST

=item factory ARRAY_REF

The C<factory(LIST)> method creates a list of tokens from a list
of specifications, which include for each token: a name, a
regular expression, and possibly an anonymous subroutine.
The list can also include objects of class C<Parse::Token>
or of a class derived from it.

The C<factory(ARRAY_REF)> method permits creating tokens from
specifications of type attribute-value:

        Parse::Token->factory([Type => 'Simple', 
                               Name => 'EXAMPLE', 
                               Regex => '.+']);

C<Type> indicates the type of each token to be created
(the package prefix is not indicated).

C<factory()> creates a series of tokens but does not import these
tokens into the calling package.

You could for example write:

        %keywords = 
          qw (
              PROC  undef
              FUNC  undef
              RETURN undef
              IF    undef
              ELSE  undef
              WHILE undef
              PRINT undef
              READ  undef
             );
        @tokens = Parse::Token->factory(%keywords);

and install these tokens in a symbol table in the following manner:

        foreach $name (keys %keywords) {
	  ${$name} = pop @tokens;
          $symbol{"\L$name"} = [${$name}, ''];
        }

C<${$name}> is the token instance.

During the lexical analysis phase, you can use the tokens in the
following manner:

        qw(IDENT [a-zA-Z][a-zA-Z0-9_]*),  sub {
           $symbol{$_[1]} = [] unless defined $symbol{$_[1]};
           my $type = $symbol{$_[1]}[0];
           $lexer->setToken((not defined $type) ? $VAR : $type);
           $_[1];  # THE TOKEN TEXT
         }

This permits indicating that any symbol of unknown type is a variable.

In this example we have used C<$_[1]> which corresponds to the text
recognized by the regular expression.  This text associated with the
token must be returned by the anonymous subroutine.

=item get EXPR

C<get> obtains the value of the attribute named by the result of
evaluating EXPR.  You can also use the name of the attribute as a method name.

=item getText

Returns the character string that was recognized by means of this
C<Parse::Token> object.

Same as the text() method.

=item isnext EXPR

=item isnext

Returns the status of the token. The consumed string is put into
EXPR if it is a reference to a scalar.

=item name

Returns the name of the token.

=item next

Activate searching for the lexeme defined by the regular expression
contained in the object. If this lexeme is recognized on the character
stream to analyze, C<next> returns the string found and sets the
status of the object to true.

=item new SYMBOL_NAME, REGEXP, SUB

=item new SYMBOL_NAME, REGEXP

Creates an object of type C<Parse::Token::Simple> or
C<Parse::Token::Segmented>. The arguments of the C<new()> method are,
respectively: a symbolic name, a regular expression, and possibly
an anonymous subroutine.  The subclasses of C<Parse::Token> permit
specifying tokens by means of a list of attribute-values.

REGEXP is either a simple regular expression, or a reference to an
array containing from one to three regular expressions.  In the
first case, the instance belongs to the C<Parse::Token::Simple>
class.  In the second case, the instance belongs to the
C<Parse::Token::Segmented> class.  The tokens of this type permit
recognizing structures of type character string delimited by
quotation marks, comments in a C program, etc.  The regular
expressions are used to recognize:

1. The beginning of the lexeme,

2. The "body" of the lexeme; if this second expression is missing,
C<Parse::Lex> uses "(?:.*?)",

3. the end of the lexeme; if this last expression is missing then the
first one is used. (Note! The end of the lexeme cannot span
several lines).

Example:

          qw(STRING), [qw(" (?:[^"\\\\]+|\\\\(?:.|\n))* ")],

These regular expressions can recognize multi-line strings
delimited by quotation marks, where the backslash is used to quote the
quotation marks appearing within the string. Notice the quadrupling of
the backslash.

Here is a variation of the previous example which uses the C<s>
option to include newline in the characters recognized by "C<.>":

          qw(STRING), [qw(" (?s:[^"\\\\]+|\\\\.)* ")],

(Note: it is possible to write regular expressions which are
more efficient in terms of execution time, but this is not our
objective with this example.  See I<Mastering Regular Expressions>.)

The anonymous subroutine is called when the lexeme is recognized by the
lexical analyzer. This subroutine takes two arguments: C<$_[0]> contains
the token instance, and C<$_[1]> contains the string recognized
by the regular expression. The scalar returned by the anonymous
subroutine defines the character string memorized in the token instance.

In the anonymous subroutine you can use the positional variables
C<$1>, C<$2>, etc. which correspond to the groups of parentheses
in the regular expression.

=item regexp

Returns the regular expression of the C<Token> object.

=item set LIST

Allows marking a token with a list of attribute-value
pairs.

An attribute name can be used as a method name.

=item setText EXPR

The value of C<EXPR> defines the character string associated with the
lexeme.

Same as the C<text(EXPR)> method.

=item status EXPR

=item status

Indicates if the last search of the lexeme succeeded or failed.
C<status EXPR> overrides the existing value and sets it to the value of EXPR.

=item text EXPR

=item text

C<text()> returns the character string recognized by means of the
token. The value of C<EXPR> sets the character string
associated with the lexeme.

=item trace OUTPUT 

=item trace 

Class method which activates/deactivates a trace of the lexical
analysis.

C<OUTPUT> can be a file name or a reference to a filehandle to which
the trace will be directed.

=back

=head1 Subclasses of Parse::Token

Subclasses of the C<Parse::Token> class are being defined.
They permit recognizing specific structures such as,
for example, strings within double-quotes, C comments, etc.
Here are the subclasses which I am working on:

C<Parse::Token::Simple> : tokens of this class are defined
by means of a single regular expression.

C<Parse::Token::Segmented> : tokens of this class are defined
by means of three regular expressions.  Reading of new data
is done automatically.

C<Parse::Token::Delimited> : permits recognizing, for example,
C language comments.

C<Parse::Token::Quoted> : permits recognizing, for example,
character strings within quotation marks.

C<Parse::Token::Nested> : permits recognizing nested structures
such as parenthesized expressions.  NOT DEFINED.

These classes are recently created and no doubt contain some bugs.

=head2 Parse::Token::Action 

Tokens of the C<Parse::Token::Action> class permit inserting arbitrary
Perl expressions within a lexical analyzer.  An expression can be used
for instance to print out internal variables of the analyzer:

=over 

=item *

C<$LEX_BUFFER> : contents of the buffer to be analyzed

=item *

C<$LEX_LENGTH> : length of the character string being analyzed

=item *

C<$LEX_RECORD> : number of the record being analyzed

=item *

C<$LEX_OFFSET> : number of characters already consumed since the start
of the analysis.

=item *

C<$LEX_POS> : position reached by the analysis as a number of characters
since the start of the buffer.

=back

The class constructor accepts the following attributes:

=over 

=item *

C<Name> : the name of the token

=item * 

C<Expr> : a Perl expression

=back

Example :

        $ACTION = new Parse::Token::Action(
                                      Name => 'ACTION',
                                      Expr => q!print "LEX_POS: $LEX_POS\n" .
                                      "LEX_BUFFER: $LEX_BUFFER\n" .
                                      "LEX_LENGTH: $LEX_LENGTH\n" .
                                      "LEX_RECORD: $LEX_RECORD\n" .
                                      "LEX_OFFSET: $LEX_OFFSET\n" 
                                      ;!,
                                     );

=head2 Parse::Token::Simple

The class constructor accepts the following attributes:

=over

=item * 

C<Handler> : the value indicates the name of a function to call during
an analysis performed by an analyzer of class C<Parse::LexEvent>.

=item * 

C<Name> : the associated value is the name of the token.

=item * 

C<Regex> : the associated value is a regular expression
corresponding to the pattern to be recognized.

=item * 

C<ReadMore> : if the associated value is 1, the recognition of the token
continues after reading a new record.  The strings recognized are
concatenated.  This attribute only has effect during analysis of a
character stream.

=item * 

C<Sub> : the associated value must be an anonymous subroutine to be
executed after the token is recognized.  This function is only used
with analyzers of class C<Parse::Lex> or C<Parse::CLex>.

=back

Example.
      new Parse::Token::Simple(Name => 'remainder', 
                               Regex => '[^/\'\"]+', 
                               ReadMore => 1);

=head2 Parse::Token::Segmented

The definition of these tokens includes three regular expressions.
During analysis of a data stream, new data is read as long as the
end of the token has not been reached.

The class constructor accepts the following attributes:

=over

=item * 

C<Handler> : the value indicates the name of a function to call during
analysis performed by an analyzer of class C<Parse::LexEvent>.

=item * 

C<Name> : the associated value is the name of the token.

=item * 

C<Regex> : the associated value must be a reference to an array that
contains three regular expressions.

=item * 

C<Sub> : the associated value must be an anonymous subroutine to be
executed after the token is recognized.  This function is only used
with analyzers of class C<Parse::Lex> or C<Parse::CLex>.

=back

=head2 Parse::Token::Quoted

C<Parse::Token::Quoted> is a subclass of
C<Parse::Token::Segmented>.  It permits recognizing character
strings within double quotes or single quotes.

Examples.

      ---------------------------------------------------------
       Start    End            Escaping
      ---------------------------------------------------------
        '        '              ''
        "        "              ""
        "        "              \
      ---------------------------------------------------------

The class constructor accepts the following attributes:

=over

=item * 

C<End> : The associated value is a regular expression permitting
recognizing the end of the token.

=item * 

C<Escape> : The associated value indicates the character used to escape
the delimiter.  By default, a double occurrence of the terminating
character escapes that character.

=item * 

C<Handler> : the value indicates the name of a function to be called
during an analysis performed by an analyzer of class C<Parse::LexEvent>.

=item * 

C<Name> : the associated value is the name of the token.

=item * 

C<Start> : the associated value is a regular expression permitting
recognizing the start of the token.

=item * 

C<Sub> : the associated value must be an anonymous subroutine to be
executed after the token is recognized.  This function is only used
with analyzers of class C<Parse::Lex> or C<Parse::CLex>.

=back

Example.
      new Parse::Token::Quoted(Name => 'squotes', 
                               Handler => 'string',
                               Escape => '\\',
                               Quote => qq!\'!, 
                              );

=head2 Parse::Token::Delimited

C<Parse::Token::Delimited> is a subclass of
C<Parse::Token::Segmented>.  It permits, for example, recognizing C
language comments.

Examples.

      ---------------------------------------------------------
        Start   End     Constraint
                        on the contents
      ---------------------------------------------------------
        /*       */                         C Comment
        <!--     -->      No '--'           XML Comment
        <!--     -->                        SGML Comment
        <?       ?>                         Processing instruction
                                            in SGML/XML
      ---------------------------------------------------------

The class constructor accepts the following attributes:

=over 4

=item * 

C<End> : The associated value is a regular expression permitting
recognizing the end of the token.

=item * 

C<Handler> : the value indicates the name of a function to be called
during an analysis performed by an analyzer of class C<Parse::LexEvent>.

=item * 

C<Name> : the associated value is the name of the token.

=item * 

C<Start> : the associated value is a regular expression permitting
recognizing the start of the token.

=item * 

C<Sub> : the associated value must be an anonymous subroutine to be
executed after the token is recognized.  This function is only used
with analyzers of class C<Parse::Lex> or C<Parse::CLex>.

=back

Example.
      new Parse::Token::Delimited(Name => 'comment',
                                  Start => '/[*]', 
                                  End => '[*]/'
                                 );

=head2 Parse::Token::Nested - Not defined

Examples.

      ----------------------------------------------------------
        Start   End
      ----------------------------------------------------------
        (        )                      Symbolic Expressions
        {        }                      Rich Text Format Groups
      ----------------------------------------------------------


=head1 BUGS

The implementation of subclasses of tokens is not complete for
analyzers of the C<Parse::CLex> class.  I am not too keen to do
it, since an implementation for classes C<Parse::Lex> and
C<Parse::LexEvent> seems quite sufficient.

=head1 AUTHOR

Philippe Verdret. Documentation translated to English by Vladimir
Alexiev and Ocrat.

=head1 ACKNOWLEDGMENTS

Version 2.0 owes much to suggestions made by Vladimir Alexiev.
Ocrat has significantly contributed to improving this documentation.
Thanks also to the numerous persons who have made comments or sometimes
sent bug fixes.

=head1 REFERENCES

Friedl, J.E.F. Mastering Regular Expressions. O'Reilly & Associates
1996.

Mason, T. & Brown, D. - Lex & Yacc. O'Reilly & Associates, Inc. 1990.

=head1 COPYRIGHT

Copyright (c) 1995-1999 Philippe Verdret. All rights reserved. This
module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
