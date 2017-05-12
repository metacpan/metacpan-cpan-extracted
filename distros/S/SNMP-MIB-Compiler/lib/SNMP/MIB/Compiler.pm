# -*- Mode: Perl -*-

##########################################################################
# MIB Compiler supporting SMI(v1) and SMIv2
#
# Author: Fabien Tassin <fta@oleane.net>
# Copyright 1998, 1999 Fabien Tassin <fta@oleane.net>
##########################################################################
# See Also :
#   Rec. X.208: Specification of Abstract Syntax Notation (ASN.1)
#   RFC 1155:   Structure and Identification of Management Information
#               for TCP/IP-based Internets
#   RFC 1158:   Management Information Base for network management of
#               TCP/IP-based internets: MIB-II
#   RFC 1212:   Concise MIB definitions
#   RFC 1215:   Convention for defining traps for use with the SNMP
#   RFC 1902:   Structure of Management Information for Version 2 of the
#               Simple Network Management Protocol (SNMPv2)
#   RFC 1903:   Textual Conventions for Version 2 of the Simple Network
#               Management Protocol (SNMPv2)
#   RFC 1904:   Conformance Statements for Version 2 of the Simple Network
#               Management Protocol (SNMPv2)
##########################################################################
# ABSOLUTELY NO WARRANTY WITH THIS PACKAGE. USE IT AT YOUR OWN RISKS.
##########################################################################

# TODO:
# - resolve constants (e.g. 'max-bindings' in SNMPv2-PDU)
# - check a value against a syntax
# - extend the API
# - more test scripts

package SNMP::MIB::Compiler;

use strict;
use vars qw(@ISA @EXPORT $VERSION $DEBUG);
use Exporter;
use Carp;
use Data::Dumper;
use FileHandle;

@ISA     = qw(Exporter);
@EXPORT  = ();
$VERSION = 0.06;
$DEBUG   = 1; # no longer used

######################################################################
# ASN1 items. (See Rec. X.208 §8)

# Type references (§8.2)
my $ITEM_TYPEREFERENCE_PAT = '[A-Z](\-?[A-Za-z0-9])*';

# Reserved character sequences (See Table 3/X.208)
# and Additional keyword items (See §A.2.9)
my @RESERVED_CHAR_SEQ = ('BOOLEAN', 'INTEGER', 'BIT', 'STRING', 'OCTET',
 			 'NULL', 'SEQUENCE', 'OF', 'SET', 'IMPLICIT', 'CHOICE',
 			 'ANY', 'EXTERNAL', 'OBJECT', 'IDENTIFIER', 'OPTIONAL',
 			 'DEFAULT', 'COMPONENTS', 'UNIVERSAL', 'APPLICATION',
 			 'PRIVATE', 'TRUE', 'FALSE', 'BEGIN', 'END',
 			 'DEFINITIONS', 'EXPLICIT', 'ENUMERATED', 'EXPORTS',
 			 'IMPORTS', 'REAL', 'INCLUDES', 'MIN', 'MAX', 'SIZE',
 			 'FROM', 'WITH', 'COMPONENT', 'PRESENT', 'ABSENT',
 			 'DEFINED', 'BY', 'PLUS-INFINITY', 'MINUS-INFINITY',
 			 'TAGS',
                         'MACRO', 'TYPE', 'NOTATION', 'VALUE', # Macro keywords
);

# my $ITEM_TYPEREFERENCE = '(?!' .
#   (join '(?!\-?[A-Za-z0-9])|', @RESERVED_CHAR_SEQ) .
#   '(?!\-?[A-Za-z0-9]))' . $ITEM_TYPEREFERENCE_PAT;

my $ITEM_TYPEREFERENCE =
  '(?!(?:' . (join '|', @RESERVED_CHAR_SEQ) . ')(?!\-?[A-Za-z0-9]))' .
  $ITEM_TYPEREFERENCE_PAT;

# Identifiers (§8.3)
my $ITEM_IDENTIFIER  = '\b[a-z](?:\-?[A-Za-z0-9])*\b';
my $ITEM_IDENTIFIER2 = '\b[a-z](?:[\-_]?[A-Za-z0-9])*\b'; # w/allow_underscore

# Number item (§8.8)
my $ITEM_NUMBER = '\b(?:0|[1-9][0-9]*)\b';

# Binary string item (§8.9) (bstring)
my $ITEM_BINARYSTRING = '\'[01]*\'B';

# Hexadecimal string item (§8.10) (hstring)
my $ITEM_HEXADECIMALSTRING = '\'[A-F0-9]*\'H';

# Single character items (§8.13)
my $ITEM_SINGLECHARACTER = '[\{\}\<,\.\(\)\[\]\-;]';

sub MIBERROR()  { 0 };
sub MIBWARN()   { 1 };
sub MIBNOTICE() { 2 };

######################################################################
# Tokens

my $TOKEN = &create_tokens();

my $BSTRING          = &add_token ($TOKEN, 'BSTRING');
my $HSTRING          = &add_token ($TOKEN, 'HSTRING');
my $CSTRING          = &add_token ($TOKEN, 'CSTRING');
my $ASSIGNMENT       = &add_token ($TOKEN, 'ASSIGNMENT');
my $NUMBER           = &add_token ($TOKEN, 'NUMBER');
my $IDENTIFIER       = &add_token ($TOKEN, 'IDENTIFIER');
my $TYPEMODREFERENCE = &add_token ($TOKEN, 'TYPEMODREFERENCE');
my $EMPTY            = &add_token ($TOKEN, 'EMPTY');
my $BOOLEAN          = &add_token ($TOKEN, 'BOOLEAN');
my $INTEGER          = &add_token ($TOKEN, 'INTEGER');
my $BIT              = &add_token ($TOKEN, 'BIT');
my $STRING           = &add_token ($TOKEN, 'STRING');
my $OCTET            = &add_token ($TOKEN, 'OCTET');
my $NULL             = &add_token ($TOKEN, 'NULL');
my $SEQUENCE         = &add_token ($TOKEN, 'SEQUENCE');
my $OF               = &add_token ($TOKEN, 'OF');
my $SET              = &add_token ($TOKEN, 'SET');
my $IMPLICIT         = &add_token ($TOKEN, 'IMPLICIT');
my $CHOICE           = &add_token ($TOKEN, 'CHOICE');
my $ANY              = &add_token ($TOKEN, 'ANY');
my $EXTERNAL         = &add_token ($TOKEN, 'EXTERNAL');
my $OBJECT           = &add_token ($TOKEN, 'OBJECT');
my $OPTIONAL         = &add_token ($TOKEN, 'OPTIONAL');
my $DEFAULT          = &add_token ($TOKEN, 'DEFAULT');
my $COMPONENTS       = &add_token ($TOKEN, 'COMPONENTS');
my $UNIVERSAL        = &add_token ($TOKEN, 'UNIVERSAL');
my $APPLICATION      = &add_token ($TOKEN, 'APPLICATION');
my $PRIVATE          = &add_token ($TOKEN, 'PRIVATE');
my $TRUE             = &add_token ($TOKEN, 'TRUE');
my $FALSE            = &add_token ($TOKEN, 'FALSE');
my $BEGIN            = &add_token ($TOKEN, 'BEGIN');
my $END              = &add_token ($TOKEN, 'END');
my $DEFINITIONS      = &add_token ($TOKEN, 'DEFINITIONS');
my $EXPLICIT         = &add_token ($TOKEN, 'EXPLICIT');
my $ENUMERATED       = &add_token ($TOKEN, 'ENUMERATED');
my $EXPORTS          = &add_token ($TOKEN, 'EXPORTS');
my $IMPORTS          = &add_token ($TOKEN, 'IMPORTS');
my $REAL             = &add_token ($TOKEN, 'REAL');
my $INCLUDES         = &add_token ($TOKEN, 'INCLUDES');
my $MIN              = &add_token ($TOKEN, 'MIN');
my $MAX              = &add_token ($TOKEN, 'MAX');
my $SIZE             = &add_token ($TOKEN, 'SIZE');
my $FROM             = &add_token ($TOKEN, 'FROM');
my $WITH             = &add_token ($TOKEN, 'WITH');
my $COMPONENT        = &add_token ($TOKEN, 'COMPONENT');
my $PRESENT          = &add_token ($TOKEN, 'PRESENT');
my $ABSENT           = &add_token ($TOKEN, 'ABSENT');
my $DEFINED          = &add_token ($TOKEN, 'DEFINED');
my $BY               = &add_token ($TOKEN, 'BY');
my $PLUSINFINITY     = &add_token ($TOKEN, 'PLUSINFINITY');
my $MINUSINFINITY    = &add_token ($TOKEN, 'MINUSINFINITY');
my $TAGS             = &add_token ($TOKEN, 'TAGS');
my $MACRO            = &add_token ($TOKEN, 'MACRO');
my $TYPE             = &add_token ($TOKEN, 'TYPE');
my $NOTATION         = &add_token ($TOKEN, 'NOTATION');
my $VALUE            = &add_token ($TOKEN, 'VALUE');
my $MACROTYPE        = &add_token ($TOKEN, 'MACROTYPE');
my $MACROVALUE       = &add_token ($TOKEN, 'MACROVALUE');

my $keywords = {
                'BOOLEAN'     => $BOOLEAN,
                'INTEGER'     => $INTEGER,
                'BIT'         => $BIT,
                'STRING'      => $STRING,
                'OCTET'       => $OCTET,
                'NULL'        => $NULL,
                'SEQUENCE'    => $SEQUENCE,
                'OF'          => $OF,
                'SET'         => $SET,
                'IMPLICIT'    => $IMPLICIT,
                'CHOICE'      => $CHOICE,
                'ANY'         => $ANY,
                'EXTERNAL'    => $EXTERNAL,
                'OBJECT'      => $OBJECT,
                'IDENTIFIER'  => $IDENTIFIER,
                'OPTIONAL'    => $OPTIONAL,
                'DEFAULT'     => $DEFAULT,
                'COMPONENTS'  => $COMPONENTS,
                'UNIVERSAL'   => $UNIVERSAL,
                'APPLICATION' => $APPLICATION,
                'PRIVATE'     => $PRIVATE,
                'TRUE'        => $TRUE,
                'FALSE'       => $FALSE,
                'BEGIN'       => $BEGIN,
                'END'         => $END,
                'DEFINITIONS' => $DEFINITIONS,
                'EXPLICIT'    => $EXPLICIT,
                'ENUMERATED'  => $ENUMERATED,
                'EXPORTS'     => $EXPORTS,
                'IMPORTS'     => $IMPORTS,
                'REAL'        => $REAL,
                'INCLUDES'    => $INCLUDES,
                'MIN'         => $MIN,
                'MAX'         => $MAX,
                'SIZE'        => $SIZE,
                'FROM'        => $FROM,
                'WITH'        => $WITH,
                'COMPONENT'   => $COMPONENT,
                'PRESENT'     => $PRESENT,
                'ABSENT'      => $ABSENT,
                'DEFINED'     => $DEFINED,
                'BY'          => $BY,
                'TAGS'        => $TAGS,

                'MACRO'       => $MACRO,
                'TYPE'        => $TYPE,
                'NOTATION'    => $NOTATION,
                'VALUE'       => $VALUE,

                'MACROTYPE'   => $MACROTYPE,
                'MACROVALUE'  => $MACROVALUE,
};

######################################################################

# Create the standard tokens
sub create_tokens {
  my $TOKEN = [];
  my $i = -1;
  while ($i++ < 255) {
    $$TOKEN[$i] = chr $i;
  }
  $TOKEN;
}

# Add a 'specialized' token to the current list of tokens
sub add_token {
  my $TOKEN = shift;
  my $k = shift;
  push @$TOKEN, $k;
  $#$TOKEN;
}

# The 'heart' of the compiler: the parser
# returns the couple token/value or the scalar 0 if something goes wrong.
sub yylex {
  my $self = shift;

  my $s = $self->{'stream'};
  my $val;
  my $c = ' '; # initialization.
  CHAR: while ($c ne '' && $c !~ m/^[A-Za-z0-9:=,\{\}<.\(\)\[\]\'\">|]$/o) {
    # remove useless blanks and comments
    1 while ($c = $s->getc) eq ' ' || $c eq "\t" || $c eq "\n" || $c eq "\r";
    return 0 if $c eq '';
    if ($c eq '-') { # The first char of a "comment" (See §8.6)
      $c = $s->getc;
      if ($c eq '') { # a single hyphen followed by EOF
	$s->ungetc; # keep EOF for the next yylex call
	$c = '-';
	last CHAR;
      }
      if ($c eq '-') { # it is a real "comment" marker
	while (1) {
	  1 while ($c = $s->getc) ne '' && $c ne '-'
	    && $c ne "\n" && $c ne "\r";
	  return 0 if $c eq ''; # End of file.
	  if ($c eq '-') {
	    $c = $s->getc;
	    return 0 if $c eq ''; # End of file.
	    next CHAR if $c eq "\n" || $c eq "\r" ||
	      $c eq '-'; # End of comment.
	  }
	  next CHAR if $c eq "\n"; # End of comment.
	}
      }
      else { # it is NOT a comment but a single hyphen.
	$s->ungetc;
	$c = '-';
	last CHAR;
      }
    }
    else {
      last;
    }
  }
  # Here, the current char is a valid ASN.1 char, it can be a hyphen but
  # not a double hyphen (comment start).

  # Read a word and return the correspondant token.
  return 0 if $c eq '';
  if ($c =~ m/^$ITEM_SINGLECHARACTER$/o) {
    # it is a single characters
    return (ord ($c), $c);
  }
  if ($c =~ m/^[>|]/o) {
    # it is a single extension characters
    return (ord ($c), $c);
  }
  if ($c eq '\'') { # it can be a cstring or a hstring.
    $val = $c;
    # while (($c = $s->getc) ne '' && ($c =~ m/[0-9A-F]/o ||
    #   ($self->{'allow_lowcase_hstrings'} && $c =~ m/[a-f]/o))) {
    while (($c = $s->getc) ne '' && $c =~ m/[0-9A-Fa-f]/o) {
      $val .= $c;
    }
    return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
          "Unexpected EOF near \"$val\"") if $c eq '';
    if ($c eq '\'') {
      $val .= $c;
      $c = $s->getc;
      return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
          "Unexpected EOF near \"$val\"") if $c eq '';
      $val .= $c;
      # it must be 'B' or 'H'.
      $c = 'B' if $c eq 'b' && $self->{'allow_lowcase_bstrings'};
      if ($c =~ m/[hH]/o && $self->{'allow_lowcase_hstrings'}) {
	$c = 'H';
	$val = uc $val;
      }
      if ($c eq 'B' && $val =~ m/^$ITEM_BINARYSTRING$/o) {
	return ($BSTRING, $val);
      }
      if ($c eq 'H' && $val =~ m/^$ITEM_HEXADECIMALSTRING$/o) {
	return ($HSTRING, $val);
      }
      return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
          "Invalid \"$val\". See 'allow_lowcase_{b|h}strings' switches");
    }
    return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
			 "Syntax error near \"$val\"");
  }
  if ($c eq '"') { # a cstring
    $val = $c;
    while (1) {
      while (($c = $s->getc) ne '' && $c ne '"') {
	$val .= $c;
      }
      return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
			   "Unexpected EOF near \"$val\"") if $c eq '';
      $val .= $c;
      $c = $s->getc;
      if ($c eq '' || $c ne '"') {
	$s->ungetc if $c;
	return ($CSTRING, $val);
      }
      $val .= $c;
    }
  }
  if ($c eq ':') { # an assignment item
    $val = $c;
    $c = $s->getc;
    return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
			 "Unexpected EOF near \"$val\"") if $c eq '';
    if ($c ne ':') {
      $s->ungetc if $c;
    }
    else {
      $val .= $c;
      $c = $s->getc;
      return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
			   "Unexpected EOF near \"$val\"") if $c eq '';
      return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
			   "Syntax error near \"$val\"") unless $c eq '=';
      $val .= $c;
      return ($ASSIGNMENT, $val);
    }
  }
  if ($c =~ m/\d/o) { # it is a number
    $val = $c;
    while (($c = $s->getc) ne '' && $c =~ m/\d/o) {
      $val .= $c;
    }
    $s->ungetc if $c;
    return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
	"Syntax error near \"$val\"") unless $val =~ m/^$ITEM_NUMBER$/;
    return ($NUMBER, $val);
  }
  if ($c =~ m/[a-zA-Z]/o) {
    $val = $c;
    while (1) {
      while (($c = $s->getc) ne '' && ($c =~ m/[A-Za-z0-9]/o ||
			($self->{'allow_underscore'} && $c eq '_'))) {
	$val .= $c;
      }
      if ($c eq '-') {
	$c = $s->getc;
	# a hyphen shall not be the last character
	return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
			     "Syntax error near \"$val\"")
	  if $c eq '' || $c eq "\n" || $c eq "\r";
	if ($c eq '-') { # it is a comment.
	  COMM: while (1) {
	    1 while ($c = $s->getc) ne '' && $c ne '-' &&
	      $c ne "\n" && $c ne "\r";
	    last COMM if $c eq '' ||      # End of file...
	      $c eq "\n" || $c eq "\r";   # End of comment.
	    $c = $s->getc;
	    last COMM if $c eq '' ||                 # End of file...
	      $c eq "\n" || $c eq "\r" || $c eq '-'; # End of comment.
	    $s->ungetc;
	  }
	  # TypeReference or ModuleReference
	  return ($TYPEMODREFERENCE, $val)
	    if $val =~ m/^$ITEM_TYPEREFERENCE$/o;
	  # Identifier or ValueReference
	  return ($IDENTIFIER, $val) if $val =~ m/^$ITEM_IDENTIFIER$/o;
	  return ($IDENTIFIER, $val) if $val =~ m/^$ITEM_IDENTIFIER2$/o &&
	    $self->{'allow_underscore'};
	  return ($PLUSINFINITY, $val) if $val eq 'PLUS-INFINITY';
	  return ($MINUSINFINITY, $val) if $val eq 'MINUS-INFINITY';
	  return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
			       "Syntax error near \"$val\"");
	}
	$s->ungetc if $c ne '';
	$val .= "-";
      }
      if ($c !~ m/[A-Za-z0-9]/o) {
	$s->ungetc if $c;

	# Is it a known keyword ?
	return ($$keywords{$val}, $val) if defined $$keywords{$val};

	# TypeReference/ModuleReference/MacroReference/ProductionReference/
        # LocalTypeReference
	return ($TYPEMODREFERENCE, $val) if $val =~ m/^$ITEM_TYPEREFERENCE$/o;
	# Identifier/ValueReference/LocalValueReference
	return ($IDENTIFIER, $val) if $val =~ m/^$ITEM_IDENTIFIER$/o;
	return ($IDENTIFIER, $val) if $val =~ m/^$ITEM_IDENTIFIER2$/o &&
	  $self->{'allow_underscore'};
	return ($PLUSINFINITY, $val) if $val eq 'PLUS-INFINITY';
	return ($MINUSINFINITY, $val) if $val eq 'MINUS-INFINITY';
	return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
		      "'$val' unrecognized");
      }
    }
  }
  return $self->assert(MIBERROR, $self->{'filename'}, $s->{'lineno'},
           "'$c' unrecognized");
}

# Constructor
sub new {
  my $this = shift;

  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize();
  return $self;
}

# Create the MIB tree with some special nodes.
sub initialize {
  my $self = shift;

  $self->{'token_list'} = [];
  $self->{'srcpath'}    = [];

  # extension of the produced files
  $self->{'dumpext'} = ".dump";

  # '_' is not defined in the ASN.1 charset set but is sometimes found
  # in SNMP MIBs. This flag can be used to avoid parsing errors on such
  # mibs.
  $self->{'allow_underscore'} = 0;

  # 'abfc'h is invalid (must be 'ABFC'H) but is sometimes used in SNMP MIBs.
  $self->{'allow_lowcase_hstrings'} = 0;

  # '1001'b is invalid (must be '1001'B) but is sometimes used in SNMP MIBs.
  $self->{'allow_lowcase_bstrings'} = 0;

  $self->{'allow_keyword_any'} = 1;

  # Add the 3 roots of the tree.
  # These nodes cannot be specified using valid ASN.1 clauses.
  $self->{'root'}{'ccitt'}{'oid'}           = [ 0 ];
  $self->{'root'}{'iso'}{'oid'}             = [ 1 ];
  $self->{'root'}{'joint-iso-ccitt'}{'oid'} = [ 2 ];

  # debug flags
  $self->{'debug_recursive'} = 0;
  $self->{'debug_lexer'}     = 0;

  $self->{'make_dump'} = 1;
  $self->{'use_dump'}  = 1;

  $self->{'accept_smiv1'} = 1;
  $self->{'accept_smiv2'} = 1;

  # should we import dependencies ?
  $self->{'do_imports'} = 1;
}

sub assert {
  my $self  = shift;
  my $level = shift;
  my $file  = shift;
  my $line  = shift;
  my $msg   = shift;

  if (defined $level) {
    $self->{'msg'} = [] unless defined $self->{'msg'};
    my ($cpackage, $cfile, $cline) = caller;
    push @{$self->{'msg'}}, { 'level'    => $level,
			      'file'     => $file,
			      'line'     => $line,
			      'msg'      => sprintf($msg, @_),
			      'cpackage' => $cpackage,
			      'cfile'    => $cfile,
			      'cline'    => $cline,
			    };
    return $level;
  }
  else {
    if (wantarray) {
      return $level;
    }
    else {
      my $s = "";
      map {
	$s .= sprintf "Error %d: %s at %s line %d.%s\n", $$_{'level'},
	  $$_{'msg'}, $$_{'file'}, $$_{'line'},
	    $DEBUG ? sprintf " [%s %d]", $$_{'cfile'}, $$_{'cline'}: "";
      } @{$self->{'msg'}} if defined $self->{'msg'};
      return $s;
    }
  }
}

# Get the next token from the parser
sub get_token {
  my $self  = shift;
  my $needed = shift;

  my ($res, $k);
  if (@{$self->{'token_list'}}) {
    my $temp = shift @{$self->{'token_list'}};
    ($res, $k) = ($$temp[0], $$temp[1]);
    $self->{'lineno'} = $$temp[2];
  }
  else {
    ($res, $k) = $self->yylex();
    $self->{'lineno'} = $self->{'stream'}->lineno;
    return unless $res;
  }
  warn "DEBUG: token='" . ($res ? $$TOKEN[$res] : $res) . "' value='" .
    (defined $k ? $k : '<EOF>') . "'\n" if $self->{'debug_lexer'};
  return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
		       "'$needed' expected")
    if defined $needed && $res && $$TOKEN[$res] ne $needed;
  $self->{'current_token'} = $res;
  $self->{'current_value'} = $k;
  ($res, $k);
}

# Requeue the last token in the incoming queue.
# WARNING: only one token can be requeued.
sub unget_token {
  my $self = shift;

  warn "DEBUG: unshift\n" if $self->{'debug_lexer'};
  if (defined $self->{'current_token'}) {
    push @{$self->{'token_list'}}, [ $self->{'current_token'},
				     $self->{'current_value'},
				     $self->{'lineno'} ];
    $self->{'current_token'} = $self->{'current_value'} =
      $self->{'lineno'} = undef;
  }
  else {
    die "Error: can't unget more than one token. Abort.\n";
  }
}

sub create_tree {
  my $self = shift;

  for my $node (keys %{$self->{'nodes'}}) {
    my $t = $self->{'nodes'}{$node}{'oid'};
    $self->{'tree'}{$$t[$#$t - 1]}{$$t[$#$t]} = $node;
  }
}

# Compile a MIB file given its name
sub compile {
  my $self = shift;
  my $file = shift;

  croak "Error: you MUST specify a file to compile\n" unless $file;
  my $outdir = $self->repository;
  croak "Error: you MUST specify a repository\n"
    if $self->{'make_dump'} && !$outdir;
  my $filename;
  if ($file =~ m|/([^/]+)$|) {
    croak "Error: can't find $file" unless -e $file;
    $filename = $file;
    $file = $1;
  }
  else {
    my $dir = $self->{'srcpath'} ||
      croak "Error: you MUST specify a path using add_path()\n";
    my $ext = $self->extensions || [ '' ];
    my $windir;
    my $extfile;
    my @dirtmp = @$dir;
    while (my $d = shift @dirtmp) {
      map {
	my $e = $_;
	# warn "testing '$d/$file$e'\n";
	$windir = $d, $extfile = $e, last if -e "$d/$file$e";
      } @$ext;
    }
    croak "Error: can't find $file" unless $windir;
    $filename = "$windir/$file$extfile";
  }
  # push @{$self->{'filename'}}, $filename;
  $self->{'filename'} = $filename;
  # my $filename = $ {$self->{'filename'}}[$#{$self->{'filename'}}];

  if ($self->{'use_dump'} && -e "$outdir/$file$self->{'dumpext'}") {
    if (-M $filename < -M "$outdir/$file$self->{'dumpext'}") {
      $self->assert(MIBNOTICE, $self->{'filename'}, $self->{'fileno'},
		    "$outdir/$file$self->{'dumpext'} is older than " .
		    "$filename. Recompiling $filename...");
    }
    else {
      my $v;
      my $fh = new FileHandle "$outdir/$file$self->{'dumpext'}";
      if (defined $fh) {
	local $/ = undef;
	$v = eval <$fh>;
	if ($v) {
	  map { $self->{'nodes'}{$_} = $$v{'nodes'}{$_} } keys %{$$v{'nodes'}};
	  map { $self->{'types'}{$_} = $$v{'types'}{$_} } keys %{$$v{'types'}};
	  for my $node (keys %{$$v{'tree'}}) {
	    for my $son (keys %{$$v{'tree'}{$node}}) {
	      $self->{'tree'}{$node}{$son} = $$v{'tree'}{$node}{$son};
	    }
	  }
	  map { $self->{'traps'}{$_} = $$v{'traps'}{$_} } keys %{$$v{'traps'}};
	  map { push @{$self->{'macros'}}, $_ } @{$$v{'macros'}};
	}
	$fh->close;
      }
      return $self if $v;
    }
  }

  # open the MIB file
  my $fh = new FileHandle $filename;
  unless (defined $fh) {
    croak "Error: can't open $filename: $!\n";
    return;
  }
  # create a new MIB object
  my $mib = new SNMP::MIB::Compiler;
  $mib->{'filename'} = $filename;
  $mib->repository($self->repository);
  $mib->extensions($self->extensions);
  $mib->{'srcpath'} = $self->{'srcpath'};
  push @{$mib->{'msg'}}, @{$self->{'msg'}} if defined $self->{'msg'};

  $mib->{'make_dump'}  = $self->{'make_dump'};
  $mib->{'use_dump'}   = $self->{'use_dump'};
  $mib->{'do_imports'} = $self->{'do_imports'};

  $mib->{'allow_underscore'}       = $self->{'allow_underscore'};
  $mib->{'allow_lowcase_hstrings'} = $self->{'allow_lowcase_hstrings'};
  $mib->{'allow_lowcase_bstrings'} = $self->{'allow_lowcase_bstrings'};

  if ($self->{'debug_recursive'}) {
    $mib->{'debug_recursive'} = $self->{'debug_recursive'};
    $mib->{'debug_lexer'}     = $self->{'debug_lexer'};
  }
  # create a stream
  my $s = Stream->new($fh);
  $mib->{'stream'} = $s;
  # parse the MIB
  my $r = $mib->parse_Module();
  push @{$self->{'msg'}}, @{$mib->{'msg'}} if defined $mib->{'msg'};

  # destroy the stream
  delete $mib->{'stream'};
  # close the file
  $fh->close;
  return undef unless $r;

  # Create the MIB 'tree'
  $mib->create_tree();

  if ($self->{'make_dump'}) {
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse  = 1;

    my $file = $mib->{'name'};
    my $fh = new FileHandle "> $outdir/$file$self->{'dumpext'}";
    if (defined $fh) {
      print $fh "## Compiled by SNMP::MIB::Compiler version $VERSION\n" .
	        "## Source: $filename\n" .
                "## Date: " . (scalar localtime (time)) ."\n\n";
      print $fh Dumper { 'nodes'   => $mib->{'nodes'},
			 'types'   => $mib->{'types'},
		         'macros'  => $mib->{'macros'},
		         'tree'    => $mib->{'tree'},
		         'traps'   => $mib->{'traps'},
			 'version' => $VERSION,
		       };
      $fh->close;
    }
    else {
      croak "Warning: can't create dump $outdir/$file$self->{'dumpext'}" .
	": $!\n";
    }
  }
  # insert this MIB into the current object
  map { $self->{'nodes'}{$_} = $mib->{'nodes'}{$_} } keys %{$mib->{'nodes'}};
  map { $self->{'types'}{$_} = $mib->{'types'}{$_} } keys %{$mib->{'types'}};
  map { $self->{'traps'}{$_} = $mib->{'traps'}{$_} } keys %{$mib->{'traps'}};
  map { push @{$self->{'macros'}}, $_ } @{$mib->{'macros'}};

  for my $node (keys %{$mib->{'tree'}}) {
    for my $son (keys %{$self->{'tree'}{$node}}) {
      $self->{'tree'}{$node}{$son} = $mib->{'tree'}{$node}{$son};
    }
  }
  $self->create_tree();
  $self;
}

sub load {
  my $self = shift;
  my $file = shift;

  croak "Error: you MUST specify a MIB to load\n" unless $file;
  my $outdir = $self->repository;
  die "Error: you MUST specify a repository\n" unless $outdir;
  if ($self->{'use_dump'} && -e "$outdir/$file$self->{'dumpext'}") {
    my $v;
    my $fh = new FileHandle "$outdir/$file$self->{'dumpext'}";
    if (defined $fh) {
      local $/ = undef;
      $v = eval <$fh>;
      if ($v) {
	map { $self->{'nodes'}{$_} = $$v{'nodes'}{$_} } keys %{$$v{'nodes'}};
	map { $self->{'types'}{$_} = $$v{'types'}{$_} } keys %{$$v{'types'}};
	map { $self->{'traps'}{$_} = $$v{'traps'}{$_} } keys %{$$v{'traps'}};
	for my $node (keys %{$$v{'tree'}}) {
	  for my $son (keys %{$$v{'tree'}{$node}}) {
	    $self->{'tree'}{$node}{$son} = $$v{'tree'}{$node}{$son};
	  }
	}
	map { push @{$self->{'macros'}}, $_ } @{$$v{'macros'}};
      }
      $fh->close;
    }
    1;
  }
  else {
    $self->assert(MIBWARN, $self->{'filename'}, $self->{'lineno'},
	"can't find precompiled $file. Ignored\n") if $self->{'debug_lexer'};
    0;
  }
}

sub parse_Module {
  my $self = shift;
  my ($token, $mibname, $value);
  # ModuleIdentifier
  (($token, $mibname) = $self->get_token('TYPEMODREFERENCE')) || return;
  $self->{'name'} = $mibname;
  $self->get_token('DEFINITIONS') || return;
  $self->get_token('ASSIGNMENT') || return;
  $self->get_token('BEGIN') || return;
  (($token, $value) = $self->get_token()) || return;
  while ($token && $token != $END) {
    if ($token == $IMPORTS) {
      $self->{'imports'} = $self->parse_imports();
      $self->import_modules() if $self->{'do_imports'};
    }
    elsif ($token == $EXPORTS) {
      $self->{'exports'} = $self->parse_exports();
    }
    elsif ($token == $IDENTIFIER) {
      my $assign = $value;
      (($token, $value) = $self->get_token()) || return;
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			   "Syntax error") unless $token;
      if ($token == $OBJECT) { # probably an OBJECT IDENTIFIER
	$self->get_token('IDENTIFIER') || return;
	$self->get_token('ASSIGNMENT') || return;
	my $oid = $self->parse_oid();
	$self->{'nodes'}{$assign}{'oid'} = $oid;
	$self->{'nodes'}{$assign}{'type'} = 'OBJECT IDENTIFIER';
      }
      elsif ($token == $INTEGER) {
	$self->get_token('ASSIGNMENT') || return;
	(($token, $value) = $self->get_token()) || return;
	$self->{'constants'}{$assign}{'value'} = $value;
      }
      elsif ($value eq 'OBJECT-TYPE') {
	$self->{'nodes'}{$assign} = $self->parse_objecttype() || return;
	# return undef unless $self->{'nodes'}{$assign};
	$self->{'nodes'}{$assign}{'type'} = 'OBJECT-TYPE';
      }
      elsif ($value eq 'OBJECT-IDENTITY') {
	$self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	      "Syntax error at '$value'") unless $self->{'accept_smiv2'};
	$self->{'nodes'}{$assign} = $self->parse_objectidentity() || return;
	$self->{'nodes'}{$assign}{'type'} = 'OBJECT-IDENTITY';
      }
      elsif ($value eq 'MODULE-IDENTITY') {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			   "Syntax error at '$value'")
	  unless $self->{'accept_smiv2'};
	$self->{'nodes'}{$assign} = $self->parse_moduleidentity();
	$self->{'nodes'}{$assign}{'type'} = 'MODULE-IDENTITY';
      }
      elsif ($value eq 'MODULE-COMPLIANCE') {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			   "Syntax error at '$value'")
	  unless $self->{'accept_smiv2'};
	$self->{'nodes'}{$assign} = $self->parse_modulecompliance();
	$self->{'nodes'}{$assign}{'type'} = 'MODULE-COMPLIANCE';
      }
      elsif ($value eq 'OBJECT-GROUP') {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			   "Syntax error at '$value'")
	  unless $self->{'accept_smiv2'};
	$self->{'nodes'}{$assign} = $self->parse_objectgroup();
	$self->{'nodes'}{$assign}{'type'} = 'OBJECT-GROUP';
      }
      elsif ($value eq 'NOTIFICATION-GROUP') {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			   "Syntax error at '$value'")
	  unless $self->{'accept_smiv2'};
	$self->{'nodes'}{$assign} = $self->parse_notificationgroup();
	$self->{'nodes'}{$assign}{'type'} = 'NOTIFICATION-GROUP';
      }
      elsif ($value eq 'AGENT-CAPABILITIES') {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			   "Syntax error at '$value'")
	  unless $self->{'accept_smiv2'};
	$self->{'nodes'}{$assign} = $self->parse_agentcapabilities();
	$self->{'nodes'}{$assign}{'type'} = 'AGENT-CAPABILITIES';
      }
      elsif ($value eq 'TRAP-TYPE') {
	# as defined in RFC 1215
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			   "Syntax error at '$value'")
	  unless $self->{'accept_smiv1'};
	$self->{'traps'}{$assign} = $self->parse_traptype();
	$self->{'traps'}{$assign}{'type'} = 'TRAP-TYPE';
      }
      elsif ($value eq 'NOTIFICATION-TYPE') {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			   "Syntax error at '$value'")
	  unless $self->{'accept_smiv2'};
	$self->{'traps'}{$assign} = $self->parse_notificationtype();
	$self->{'traps'}{$assign}{'type'} = 'NOTIFICATION-TYPE';
      }
      else {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			   "Syntax error at '$value'");
      }
    }
    elsif ($token == $TYPEMODREFERENCE) {
      my $label = $value;
      (($token, $value) = $self->get_token()) || return;
      if ($token == $ASSIGNMENT) {
	my $type = $self->parse_type();
	# warn "Warning: type '$label' already defined"
	#   if defined $self->{'types'}{$label};
	$self->{'types'}{$label} = $type;
      }
      elsif ($token == $MACRO) {
	# Skip this beast..
	(($token, $value) = $self->get_token('ASSIGNMENT')) || return;
	while ($token && $token != $END) {
	  (($token, $value) = $self->get_token()) || return;
	}
	push @{$self->{'macros'}}, $label;
      }
      else {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "unrecognized syntax '$value' ($$TOKEN[$token])...");
      }
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "received an unknown token ($$TOKEN[$token])");
    }
    (($token, $value) = $self->get_token()) || return;
  }
  return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
		       "'END' expected") unless $token == $END;
}

# Given a type, this will return the corresponding SMI (v2 or v1) type
# or the corresponding ASN.1 type.
sub resolve_type {
  my $self = shift;
  my $type = shift;

  # a basic ASN.1 type.
  return $type if $type =~ m/^(SEQUENCE|CHOICE|INTEGER|OCTET\ STRING|
			       OBJECT\ IDENTIFIER|NULL)$/ox;
  # SMIv1 type
  return $type if $type =~ m/^(IpAddress|Counter|Gauge|TimeTicks|Opaque)$/o;
  # SMIv2 type
  return $type if $type =~ m/^(Integer32|Counter32|Gauge32|Unsigned32|
			       Counter64)$/ox;
  defined $self->{'types'}{$type} ?
    defined $self->{'types'}{$type}{'syntax'} ?
      $self->{'types'}{$type}{'syntax'}{'type'} :
	$self->{'types'}{$type}{'type'} : $type;
}

sub resolve_oid {
  my $self = shift;
  my $node = shift;

  return $node unless defined $node;                  # no node
  return $node unless defined $self->{'nodes'}{$node} &&
    scalar keys %{$self->{'nodes'}{$node}} ||
      defined $self->{'root'}{$node} &&
	scalar keys %{$self->{'root'}{$node}};        # no such node
  # copy the OID if needed
  if (defined $self->{'nodes'}{$node}{'oid'} &&
      !defined $self->{'nodes'}{$node}{'OID'}) {
    $self->{'nodes'}{$node}{'OID'} = [];
    @{$self->{'nodes'}{$node}{'OID'}} = @{$self->{'nodes'}{$node}{'oid'}};
  }
  my $list = $self->{'nodes'}{$node}{'OID'} ||
             $self->{'root'}{$node}{'oid'};
  while (defined $self->{'nodes'}{$$list[0]} ||
	 defined $self->{'root'}{$$list[0]}) {
    # copy the OID if needed
    if (defined $self->{'nodes'}{$$list[0]} &&
	defined $self->{'nodes'}{$$list[0]}{'oid'} &&
       !defined $self->{'nodes'}{$$list[0]}{'OID'}) {
      $self->{'nodes'}{$$list[0]}{'OID'} = [];
      @{$self->{'nodes'}{$$list[0]}{'OID'}} =
	@{$self->{'nodes'}{$$list[0]}{'oid'}};
    }
    my @l = @$list;
    if (defined $self->{'nodes'}{$$list[0]}) {
      my $eq = 1;
      if ($#{$self->{'nodes'}{$$list[0]}{'OID'}} ==
	  $#{$self->{'nodes'}{$$list[0]}{'oid'}}) {
	my $i = -1;
	for (@{$self->{'nodes'}{$$list[0]}{'OID'}}) {
	  $i++;
	  $eq = 0, last unless $ {$self->{'nodes'}{$$list[0]}{'OID'}}[$i]
	    eq $ {$self->{'nodes'}{$$list[0]}{'oid'}}[$i];
	}
	unless ($eq) {
	  my @a = @{$self->{'nodes'}{$$list[0]}{'oid'}};
	  my @l = @{$self->{'nodes'}{$$list[0]}{'OID'}};
	  shift @l;
	  my $last = pop @l;
	  for my $elem (@l) {
	    last unless $elem =~ m/^\d+$/o;
	    my $o = shift @a;
	    $self->{'tree'}{$o}{$elem} = $a[0];
	  }
	  $self->{'tree'}{$a[0]}{$last} = $node if scalar @a == 1;
	}
      }
    }
    splice @$list, 0, 1, defined $self->{'nodes'}{$$list[0]} &&
      scalar keys %{$self->{'nodes'}{$$list[0]}} ?
      @{$self->{'nodes'}{$$list[0]}{'OID'}} :
	@{$self->{'root'}{$$list[0]}{'oid'}};
  }
  for my $l (@$list) {
    if (defined $self->{'nodes'}{$l}) {
      # copy the OID if needed
      if (defined $self->{'nodes'}{$l} &&
	  defined $self->{'nodes'}{$l}{'oid'} &&
	 !defined $self->{'nodes'}{$l}{'OID'}) {
	$self->{'nodes'}{$l}{'OID'} = [];
	@{$self->{'nodes'}{$l}{'OID'}} = @{$self->{'nodes'}{$l}{'oid'}};
      }
      my @t = @{$self->{'nodes'}{$l}{'OID'}};
      $l = $t[$#t];
    }
    if (defined $self->{'root'}{$l}) {
      my @t = @{$self->{'root'}{$l}{'OID'}};
      $l = $t[$#t];
    }
  }
  join '.', @$list;
}

sub convert_oid {
  my $self = shift;
  my $oid = shift;

  my @l = split /\./, $oid;
  my @r;
  my $node = $l[0];
  for my $id (keys %{$self->{'root'}}) {
    last unless $l[0] =~ m/^\d+$/o;
    $node = $id, last if $l[0] == $self->{'root'}{$id}{'oid'}[0];
  }
  shift @l;
  push @r, $node;
  while (my $elem = shift @l) {
    push (@r, $elem), last unless defined $self->{'tree'}{$node}{$elem};
    push @r, $self->{'tree'}{$node}{$elem};
    $node = $self->{'tree'}{$node}{$elem};
  }
  join '.', @r, @l;
}

sub parse_one {
  my $self = shift;

  warn "DEBUG: Parsing one item...\n" if  $self->{'debug_lexer'};
  # 1
  # -1..3
  # foo
  # foo..bar
  (my ($token, $value) = $self->get_token()) || return;
  if ($value eq '-') { # a negative value ?
    (($token, $value) = $self->get_token()) || return;
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
          "\"$value\" must be an integer") unless $token == $NUMBER;
    $value = "-$value";
  }
  my $val = $value;
  (($token, $value) = $self->get_token()) || return;
  if ($value eq '.') {
    $self->get_token('.') || return; # range
    (($token, $value) = $self->get_token()) || return;
    if ($value eq '-') { # a negative value ?
      (($token, $value) = $self->get_token()) || return;
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	"\"$value\" must be an integer") unless $token == $NUMBER;
      $value = "-$value";
    }
    $val = { 'range' => { 'min' => $val, 'max' => $value } };
  }
  else {
    $self->unget_token();
  }
  $val;
}

sub parse_subtype {
  my $self = shift;

  warn "DEBUG: Parsing a sub-type...\n" if $self->{'debug_lexer'};
  (my ($token, $value) = $self->get_token()) || return;
  if ($token && $value eq '(') {
    (($token, $value) = $self->get_token()) || return;
    if ($token == $SIZE) {
      my $subtype = $self->parse_subtype();
      return unless $subtype;
      $self->get_token(')') || return;
      return { 'size' => $subtype };
    }
    else {
      $self->unget_token();
      my $list;
      while ($value ne ')') {
	my $v = $self->parse_one();
	return unless defined $v;
	push @$list, $v;
	(($token, $value) = $self->get_token()) || return;
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	  "\"$value\" must be ')' or '|'")
	  unless $value eq ')' || $value eq '|';
      }
      # return scalar @$list == 1 ? { 'value' => $$list[0] } :
      #   { 'choice' => $list };
      return scalar @$list == 1 ? $$list[0] : { 'choice' => $list };
    }
  }
  elsif ($token && $value eq '{') {
    my $list = {};
    while ($value ne '}') {
      (($token, $value) = $self->get_token()) || return;
      if ($token == $IDENTIFIER) {
	my $res = $self->parse_subtype();
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	  "must have a subtype") unless defined $res;
	$$list{$res} = $value;
      }
      else {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	  "should be an identifier");
      }
      (($token, $value) = $self->get_token()) || return;
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	  "must be a '}' or a ',' instead of '$value'")
	unless $value eq '}' || $value eq ',';
    }
    return { 'values' => $list };
  }
  else {
    $self->unget_token();
  }
}

# parse a type (SYNTAX field of an OBJECT-TYPE, TC)
sub parse_type {
  my $self = shift;

  warn "DEBUG: Parsing a type...\n" if  $self->{'debug_lexer'};
  (my ($token, $value) = $self->get_token()) || return;
  if ($token == $IMPLICIT) { # implicit types
    my $type = $self->parse_type();
    my $ref = ref $type;
    if (defined $ref && $ref eq 'HASH') {
      $$type{'implicit'} = 'true';
      return $type;
    }
    else {
      return { 'implicit' => 'true',
	       'type' => $type };
    }
  }
  elsif ($token == $INTEGER) { # integers
    my $type = "INTEGER";
    my $subtype = $self->parse_subtype(); # what if parse_subtype failed ???
    my $ref = ref $subtype;
    if (defined $ref && $ref eq 'HASH') {
      $$subtype{'type'} = $type;
      return $subtype;
    }
    else {
      if (defined $subtype) {
	return { 'values' => $subtype,
		 'type'   => $type };
      }
      else {
	return { 'type'   => $type };
      }
    }
  }
  elsif ($token == $OCTET) { # octet strings
    (($token, $value) = $self->get_token()) || return;
    if ($token == $STRING) {
      my $type = "OCTET STRING";
      my $subtype = $self->parse_subtype();
      $$subtype{'type'} = $type;
      return $subtype;
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "parse error");
    }
  }
  elsif ($token == $OBJECT) { # object types
    (($token, $value) = $self->get_token()) || return;
    if ($token == $IDENTIFIER) {
      my $type = "OBJECT IDENTIFIER";
      my $subtype = $self->parse_subtype();
      $$subtype{'type'} = $type;
      return $subtype;
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "parse error");
    }
  }
  elsif ($token == $NULL) {
    return { 'type' => "NULL" };
  }
  elsif ($token == $ANY && $self->{'allow_keyword_any'}) {
    # ANY is only valid in ASN.1.. but nor in SMI, nor SMIv2.
    # As it is used in RFC 1157, we must allow it :(
    return { 'type' => "ANY" };
  }
  elsif ($token == $CHOICE) { # choices
    # CHOICE { va ta, vb tb, vc tc }
    (($token, $value) = $self->get_token('{')) || return;
    my $list = {};
    while ($value ne '}') {
      (($token, $value) = $self->get_token()) || return;
      my $res = $self->parse_type();
      my $ref = ref $res;
      if (defined $ref && $ref eq 'HASH') {
	$$list{$value} = $res;
      }
      else {
	$$list{$value} = { 'type' => $res };
      }
      (($token, $value) = $self->get_token()) || return;
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
		       "must be a '}' or a ',' instead of '$value'")
	unless $value eq '}' || $value eq ',';
    }
    return { 'type'  => 'CHOICE',
	     'items' => $list };
  }
  elsif ($token == $SEQUENCE) { # sequence (of)
    my $list = {}; # Should we keep the order of the items (and then
                   # use an array instead of a hash) ??
    my $subtype;
    (($token, $value) = $self->get_token()) || return;
    if ($value eq '(') {
      $self->unget_token();
      $subtype = $self->parse_subtype();
      (($token, $value) = $self->get_token()) || return;
    }
    if ($token == $OF) {
      # Small hack to obtain a name for this unique (?) item
      (my ($t1, $t2) = $self->get_token()) || return;
      $self->unget_token();
      $t2 = lc $t2;

      my $res = $self->parse_type();
      my $r = { 'type'  => 'SEQUENCE' };
      $$r{'items'} = { $t2 => $res };
      if (defined $subtype) {
	map { $$r{$_} = $$subtype{$_} } keys %$subtype;
      }
      return $r;
    }
    if ($value eq '{') {
      my $list = {};
      while ($value ne '}') {
	(($token, $value) = $self->get_token()) || return;
	my $res;
	if ($token == $CHOICE) {
	  $self->unget_token();
	  $res = $self->parse_type();
	}
	else {
	  $res = $self->parse_type();
	}
	my $ref = ref $res;
	if (defined $ref && $ref eq 'HASH') {
	  $$list{$value} = $res;
	}
	else {
	  return $self->assert(MIBERROR, $self->{'filename'},
			  $self->{'lineno'}, "FATAL ERROR (please report)");
	  $$list{$value} = { 'type' => $res };
	}
	(($token, $value) = $self->get_token()) || return;
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
		       "must be a '}' or a ',' instead of '$value'")
	  unless $value eq '}' || $value eq ',';
      }
      return { 'type'  => 'SEQUENCE',
	       'items' => $list };
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "fatal error");
    }
  }
  elsif ($value eq '[') { # tagged types
    my $list = [];
    while ($value ne ']') { # read the tag
      (($token, $value) = $self->get_token()) || return;
      push @$list, $value unless $value eq ']';
    }
    my $type = $self->parse_type();
    $$type{'tag'} = $list;
    return $type;
  }
  elsif ($value eq 'TEXTUAL-CONVENTION') { # textual convention
    return $self->parse_textualconvention();
  }
  elsif ($token == $IDENTIFIER || $token == $TYPEMODREFERENCE) {
    my $type = $value;
    my $subtype = $self->parse_subtype();
    $$subtype{'type'} = $type;
    return $subtype;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
		       "Syntax error at '$value'");
  }
}

sub parse_textualconvention {
  my $self = shift;
  my $data;

  (my ($token, $value) = $self->get_token()) || return;
  if ($value eq 'DISPLAY-HINT') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'display-hint'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  if ($value eq 'STATUS') {
    (($token, $value) = $self->get_token()) || return;
    if ($value =~ m/^(current|deprecated|obsolete)$/o) {
      $$data{'status'} = $value;
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "unknown status ($value) for TEXTUAL-CONVENTION");
    }
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error in TC: 'STATUS' requiered");
  }
  if ($value eq 'DESCRIPTION') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'description'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error in TC: 'DESCRIPTION' requiered");
  }
  if ($value eq 'REFERENCE') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'reference'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  if ($value eq 'SYNTAX') {
    my $type;
    (($token, $value) = $self->get_token()) || return;
    if ($value eq 'BITS') {
      $$type{'type'} = $value;
      $self->get_token('{') || return;
      while ($value ne '}') {
	(($token, $value) = $self->get_token()) || return;
	my $identifier = $value;
	$self->get_token('(') || return;
	(($token, $value) = $self->get_token('NUMBER')) || return;
	$$type{'values'}{$value} = $identifier;
	$self->get_token(')') || return;
	# should be ',' or ')'
	(($token, $value) = $self->get_token()) || return;
      }
    }
    else {
      $self->unget_token();
      $type = $self->parse_type;
    }
    $$data{'syntax'} = $type;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error in TC: 'SYNTAX' requiered");
  }
  $data;
}

sub parse_objectidentity {
  my $self = shift;
  my $data;

  my ($token, $value);
  (($token, $value) = $self->get_token()) || return;
  if ($value eq 'STATUS') {
    (($token, $value) = $self->get_token()) || return;
    if ($value =~ m/^(current|deprecated|obsolete)$/o) {
      $$data{'status'} = $value;
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "unknown status ($value) for OBJECT-IDENTITY");
    }
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'STATUS' needed");
  }
  if ($value eq 'DESCRIPTION') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'description'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'DESCRIPTION' needed");
  }
  if ($value eq 'REFERENCE') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'reference'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	"Syntax error. '::=' needed") unless $token == $ASSIGNMENT;
  $$data{'oid'} = $self->parse_oid();
  $data;
}

# parse MODULE-IDENTITY macro (see RFC 1902)
sub parse_moduleidentity {
  my $self = shift;
  my $data;

  my ($token, $value);
  (($token, $value) = $self->get_token()) || return;
  if ($value eq 'LAST-UPDATED') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'last-updated'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'LAST-UPDATED' needed");
  }
  if ($value eq 'ORGANIZATION') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'organization'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'ORGANIZATION' needed");
  }
  if ($value eq 'CONTACT-INFO') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'contact-info'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'CONTACT-INFO' needed");
  }
  if ($value eq 'DESCRIPTION') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'description'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'DESCRIPTION' needed");
  }
  while ($value eq 'REVISION') {
    $$data{'revision'} = [] unless defined $$data{'revision'};
    (($token, $value) = $self->get_token('CSTRING')) || return;
    my $val = $value;
    (($token, $value) = $self->get_token()) || return;
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error: found '$value', need 'DESCRIPTION'")
      unless $value eq 'DESCRIPTION';
    (($token, $value) = $self->get_token('CSTRING')) || return;
    push @{$$data{'revision'}}, { 'revision'    => $val,
				  'description' => $value };
    (($token, $value) = $self->get_token()) || return;
  }
  return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	"Syntax error. '::=' needed") unless $token == $ASSIGNMENT;
  $$data{'oid'} = $self->parse_oid();
  $data;
}

# parse NOTIFICATION-TYPE macro (see RFC 1902)
sub parse_notificationtype {
  my $self = shift;
  my $data;

  my ($token, $value);
  (($token, $value) = $self->get_token()) || return;
  if ($value eq 'OBJECTS') {
    my $list = [];
    (($token, $value) = $self->get_token('{')) || return;
    while ($value ne '}') {
      (($token, $value) = $self->get_token('IDENTIFIER')) || return;
      push @$list, $value;
      # shoud be a ',' or a '}'
      (($token, $value) = $self->get_token()) || return;
    }
    $$data{'objects'} = $list;
    (($token, $value) = $self->get_token()) || return;
  }
  if ($value eq 'STATUS') {
    (($token, $value) = $self->get_token()) || return;
    if ($value =~ m/^(current|deprecated|obsolete)$/o) {
      $$data{'status'} = $value;
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "unknown status ($value) for NOTIFICATION-TYPE");
    }
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'STATUS' needed");
  }
  if ($value eq 'DESCRIPTION') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'description'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'DESCRIPTION' needed");
  }
  if ($value eq 'REFERENCE') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'reference'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	"Syntax error. '::=' needed") unless $token == $ASSIGNMENT;
  $$data{'oid'} = $self->parse_oid();
  $data;
}

# parse MODULE-COMPLIANCE macro (see RFC 1904)
sub parse_modulecompliance {
  my $self = shift;
  my $data;

  my ($token, $value);
  (($token, $value) = $self->get_token()) || return;
  my $name = 'this';
  if ($value eq 'STATUS') {
    (($token, $value) = $self->get_token()) || return;
    if ($value =~ m/^(current|deprecated|obsolete)$/o) {
      $$data{'status'} = $value;
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "unknown status ($value) for MODULE-COMPLIANCE");
    }
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'STATUS' needed");
  }
  if ($value eq 'DESCRIPTION') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'description'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'DESCRIPTION' needed");
  }
  if ($value eq 'REFERENCE') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'reference'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  while ($value eq 'MODULE') {
    $name = 'this';
    (($token, $value) = $self->get_token()) || return;
    while ($value ne 'MODULE' && $token != $ASSIGNMENT) {
      if ($value eq 'MANDATORY-GROUPS') {
	my $list = [];
	(($token, $value) = $self->get_token('{')) || return;
	while ($value ne '}') {
	  (($token, $value) = $self->get_token('IDENTIFIER')) || return;
	  push @$list, $value;
	  # shoud be a ',' or a '}'
	  (($token, $value) = $self->get_token()) || return;
	}
	$$data{'module'}{$name}{'mandatory-groups'} = $list;
      }
      elsif ($value eq 'GROUP') {
	(($token, $value) = $self->get_token('IDENTIFIER')) || return;
	my $val = $value;
	(($token, $value) = $self->get_token()) || return;
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error: found '$value', need 'DESCRIPTION'")
	  unless $value eq 'DESCRIPTION';
	(($token, $value) = $self->get_token('CSTRING')) || return;
	$$data{'module'}{$name}{'group'}{$val} = $value;
      }
      elsif ($value eq 'OBJECT') {
	(($token, $value) = $self->get_token('IDENTIFIER')) || return;
	my $val = $value;
	(($token, $value) = $self->get_token()) || return;
	if ($value eq 'SYNTAX') {
	  my $type = $self->parse_type();
	  $$data{'module'}{$name}{'object'}{$val}{'syntax'} = $type;
	  (($token, $value) = $self->get_token()) || return;
	}
	if ($value eq 'WRITE-SYNTAX') {
	  my $type = $self->parse_type();
	  $$data{'module'}{$name}{'object'}{$val}{'write-syntax'} = $type;
	  (($token, $value) = $self->get_token()) || return;
	}
	if ($value eq 'MIN-ACCESS') {
	  (($token, $value) = $self->get_token()) || return;
	  if ($value =~ m/^(read-(only|write|create)|not-accessible|
			    accessible-for-notify)$/ox) {
	    $$data{'module'}{$name}{'object'}{$val}{'min-access'} = $value;
	  }
	  else {
	    return $self->assert(MIBERROR, $self->{'filename'},
		$self->{'lineno'}, "Unknown MIN-ACCESS type ($value)");
	  }
	  (($token, $value) = $self->get_token()) || return;
	}
	if ($value eq 'DESCRIPTION') {
	  (($token, $value) = $self->get_token('CSTRING')) || return;
	  $$data{'module'}{$name}{'object'}{$val}{'description'} = $value;
	  (($token, $value) = $self->get_token()) || return;
	}
	$self->unget_token();
      }
      elsif ($token == $TYPEMODREFERENCE) {
	# Modulename
	$name = $value;
	(($token, $value) = $self->get_token()) || return;
	if ($token == $IDENTIFIER) { # ModuleIdentifier
	  $$data{'module'}{$name}{'identifier'} = $value;
	}
	else {
	  $self->unget_token();
	}
      }
      else {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error at '$value'");
      }
      (($token, $value) = $self->get_token()) || return;
    }
  }
  return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
		 "Syntax error. '::=' needed") unless $token == $ASSIGNMENT;
  $$data{'oid'} = $self->parse_oid();
  $data;
}

# parse OBJECT-GROUP macro (see RFC 1904)
sub parse_objectgroup {
  my $self = shift;
  my $data;

  my ($token, $value);
  (($token, $value)= $self->get_token()) || return;
  if ($value eq 'OBJECTS') {
    my $list = [];
    (($token, $value) = $self->get_token('{'));
    while ($value ne '}') {
      (($token, $value) = $self->get_token('IDENTIFIER')) || return;
      push @$list, $value;
      # shoud be a ',' or a '}'
      (($token, $value) = $self->get_token()) || return;
    }
    $$data{'objects'} = $list;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'OBJECTS' needed");
  }
  if ($value eq 'STATUS') {
    (($token, $value) = $self->get_token()) || return;
    if ($value =~ m/^(current|deprecated|obsolete)$/o) {
      $$data{'status'} = $value;
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "unknown status ($value) for OBJECT-GROUP");
    }
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'STATUS' needed");
  }
  if ($value eq 'DESCRIPTION') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'description'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'DESCRIPTION' needed");
  }
  if ($value eq 'REFERENCE') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'reference'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	"Syntax error. '::=' needed") unless $token == $ASSIGNMENT;
  $$data{'oid'} = $self->parse_oid();
  $data;
}

# parse NOTIFICATION-GROUP macro (see RFC 1904)
sub parse_notificationgroup {
  my $self = shift;
  my $data;

  my ($token, $value);
  (($token, $value) = $self->get_token()) || return;
  if ($value eq 'NOTIFICATIONS') {
    my $list = [];
    (($token, $value) = $self->get_token('{')) || return;
    while ($value ne '}') {
      (($token, $value) = $self->get_token('IDENTIFIER')) || return;
      push @$list, $value;
      # shoud be a ',' or a '}'
      (($token, $value) = $self->get_token()) || return;
    }
    $$data{'NOTIFICATIONS'} = $list;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'NOTIFICATIONS' needed");
  }
  if ($value eq 'STATUS') {
    (($token, $value) = $self->get_token()) || return;
    if ($value =~ m/^(current|deprecated|obsolete)$/o) {
      $$data{'status'} = $value;
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "unknown status ($value) for NOTIFICATION-GROUP");
    }
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'STATUS' needed");
  }
  if ($value eq 'DESCRIPTION') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'description'} = $value;
    (($token, $value) = $self->get_token()) || return;
    }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'DESCRIPTION' needed");
  }
  if ($value eq 'REFERENCE') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'reference'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
		 "Syntax error. '::=' needed") unless $token == $ASSIGNMENT;
  $$data{'oid'} = $self->parse_oid();
  $data;
}

sub parse_agentcapabilities {
  my $self = shift;
  my $data;

  my $name = 'this';
  my ($token, $value);
  (($token, $value) = $self->get_token());
  return unless $token;
  # "PRODUCT-RELEASE" Text
  if ($value eq 'PRODUCT-RELEASE') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'product-release'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'PRODUCT-RELEASE' needed");
  }
  # "STATUS" Status
  if ($value eq 'STATUS') {
    (($token, $value) = $self->get_token()) || return;
    if ($value =~ m/^(current|obsolete)$/o) {
      $$data{'status'} = $value;
      (($token, $value) = $self->get_token()) || return;
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
		"unknown status ($value) for AGENT-CAPABILITIES");
    }
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'STATUS' needed");
  }
  # "DESCRIPTION" Text
  if ($value eq 'DESCRIPTION') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'description'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'DESCRIPTION' needed");
  }
  # ReferPart
  if ($value eq 'REFERENCE') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'reference'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  # ModulePart
  while (defined $token && $token != $ASSIGNMENT) {
    while (defined $token && $value ne 'SUPPORTS' && $token != $ASSIGNMENT) {
      if ($value eq 'INCLUDES') {
	my $list = [];
	(($token, $value) = $self->get_token('{')) || return;
	while ($value ne '}') {
	  (($token, $value) = $self->get_token('IDENTIFIER')) || return;
	  push @$list, $value;
	  # shoud be a ',' or a '}'
	  (($token, $value) = $self->get_token()) || return;
	}
	$$data{'supports'}{$name}{'includes'} = $list;
	(($token, $value) = $self->get_token()) || return
      }
      while ($value eq 'VARIATION') {
	(($token, $value) = $self->get_token('IDENTIFIER')) || return;
	my $val = $value; # ObjectName or NotificationName
	(($token, $value) = $self->get_token()) || return;
	if ($value eq 'SYNTAX') {
	  my $type = $self->parse_type();
	  $$data{'supports'}{$name}{'variation'}{$val}{'syntax'} = $type;
	  (($token, $value) = $self->get_token()) || return;
	}
	if ($value eq 'WRITE-SYNTAX') {
	  my $type = $self->parse_type();
	  $$data{'supports'}{$name}{'variation'}{$val}{'write-syntax'} = $type;
	  (($token, $value) = $self->get_token()) || return;
	}
	if ($value eq 'ACCESS') {
	  (($token, $value) = $self->get_token()) || return;
	  if ($value =~ m/^(not-implemented|accessible-for-notify|
			    read-(only|write|create)|write-only)$/ox) {
	    $$data{'supports'}{$name}{'variation'}{$val}{'access'} = $value;
	  }
	  else {
	    return $self->assert(MIBERROR, $self->{'filename'},
		$self->{'lineno'}, "Unknown ACCESS type ($value)");
	  }
	  (($token, $value) = $self->get_token()) || return;
	}
	if ($value eq 'CREATION-REQUIRES') {
	  my $list = [];
	  (($token, $value) = $self->get_token('{')) || return;
	  while ($value ne '}') {
	    (($token, $value) = $self->get_token('IDENTIFIER')) || return;
	    push @$list, $value;
	    # shoud be a ',' or a '}'
	    (($token, $value) = $self->get_token()) || return;
	  }
	  $$data{'supports'}{$name}{'variation'}{$val}{'creation-requires'} =
	    $list;
	  (($token, $value) = $self->get_token()) || return;
	}
	if ($value eq 'DEFVAL') {
	  (($token, $value) = $self->get_token('{')) || return;
	  (($token, $value) = $self->get_token('IDENTIFIER')) || return;
	  $$data{'supports'}{$name}{'variation'}{$val}{'defval'} = $value;
	  (($token, $value) = $self->get_token('}')) || return;
	  (($token, $value) = $self->get_token()) || return;
	}
	if ($value eq 'DESCRIPTION') {
	  (($token, $value) = $self->get_token('CSTRING')) || return;
	  $$data{'supports'}{$name}{'variation'}{$val}{'description'} = $value;
	  (($token, $value) = $self->get_token()) || return;
	}
	else {
	  return $self->assert(MIBERROR, $self->{'filename'},
		     $self->{'lineno'}, "Syntax error. 'DESCRIPTION' needed");
	}
      }
    }
    if ($value eq 'SUPPORTS') {
      # Modulename
      (($token, $value) = $self->get_token()) || return;
      $name = $value;
      (($token, $value) = $self->get_token()) || return;
      if ($token == $IDENTIFIER) { # ModuleIdentifier
	$$data{'module'}{$name}{'identifier'} = $value;
      }
      else {
	$self->unget_token();
      }
    }
    (($token, $value) = $self->get_token()) || return
      unless $token == $ASSIGNMENT;
  }
  $$data{'oid'} = $self->parse_oid();
  $data;
}

# Parse TRAP-TYPE macro (see RFC 1215)
sub parse_traptype {
  my $self = shift;
  my $data;

  my ($token, $value);
  (($token, $value) = $self->get_token()) || return;
  if ($value eq 'ENTERPRISE') {
    (($token, $value) = $self->get_token('IDENTIFIER')) || return;
    $$data{'enterprise'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'ENTERPRISE' needed");
  }
  if ($value eq 'VARIABLES') {
    my $list = [];
    (($token, $value) = $self->get_token('{')) || return;
    while ($value ne '}') {
      (($token, $value) = $self->get_token('IDENTIFIER')) || return;
      push @$list, $value;
      # shoud be a ',' or a '}'
      (($token, $value) = $self->get_token()) || return;
    }
    $$data{'variables'} = $list;
    (($token, $value) = $self->get_token()) || return;
  }
  if ($value eq 'DESCRIPTION') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'description'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  if ($value eq 'REFERENCE') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'reference'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  if ($token == $ASSIGNMENT) {
    (my $value = $self->get_token('NUMBER')) || return;
    $$data{'value'} = $value;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Should be '::='instead of '$value'");
  }
  $data;
}

# parse OBJECT-TYPE macro (see RFC 1902)
sub parse_objecttype {
  my $self = shift;
  my $data;

  my ($token, $value);
  (($token, $value) = $self->get_token()) || return;
  if ($value eq 'SYNTAX') {
    my $syntax = {};
    my $type;
    (($token, $value) = $self->get_token()) || return;
    if ($self->{'accept_smiv2'} && $value eq 'BITS') {
      $$type{'type'} = $value;
      $self->get_token('{') || return;
      while ($value ne '}') {
	(($token, $value) = $self->get_token()) || return;
	my $identifier = $value;
	$self->get_token('(') || return;
	(($token, $value) = $self->get_token('NUMBER')) || return;
	$$type{'values'}{$value} = $identifier;
	$self->get_token(')') || return;
	# should be ',' or ')'
	(($token, $value) = $self->get_token()) || return;
      }
    }
    else {
      $self->unget_token();
      $type = $self->parse_type;
    }
    my $subtype = $self->parse_subtype();
    my $ref = ref $type;
    if (defined $ref && $ref eq 'HASH') {
      for my $key (keys %$type) {
	$$syntax{$key} = $$type{$key};
      }
    }
    else { # should not happen
      $$syntax{'type'} = $type;
    }
    if ($subtype) {
      for my $key (keys %$subtype) {
	$$syntax{$key} = $$subtype{$key};
      }
    }
    $$data{'syntax'} = $syntax;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "'SYNTAX' needed");
  }
  if ($self->{'accept_smiv2'} && $value eq 'UNITS') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'units'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  if ($value eq 'ACCESS' || $value eq 'MAX-ACCESS') {
    if ($value eq 'MAX-ACCESS') {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
		 "Syntax error at $value") unless $self->{'accept_smiv2'};
      (($token, $value) = $self->get_token()) || return;
      if ($value =~ m/^(read-(only|write)|not-accessible|
			accessible-for-notify|read-create)$/ox) {
	# Valid SMIv2 acces type (rfc 1902, draft-ops-smiv2-smi-01)
	$$data{'access'} = $value;
      }
      else {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Unknown acces type ($value)");
      }
    }
    else { # 'ACCESS'
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
		 "Syntax error at $value") unless $self->{'accept_smiv1'};
      (($token, $value) = $self->get_token()) || return;
      if ($value =~ m/^(read-(only|write)|write-only|not-accessible)$/o) {
	# Valid SMIv1 acces type (rfc 1155, rfc 1212)
	$$data{'access'} = $value;
      }
      else {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			     "Unknown acces type ($value)");
      }
    }
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    if ($self->{'accept_smiv1'} && !$self->{'accept_smiv2'}) {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'ACCESS' needed");
    }
    elsif (!$self->{'accept_smiv1'} && $self->{'accept_smiv2'}) {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			   "Syntax error. 'MAX-ACCESS' needed");
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'ACCESS' or 'MAX-ACCESS' needed");
    }
  }
  if ($value eq 'STATUS') {
    (($token, $value) = $self->get_token()) || return;
    if ($self->{'accept_smiv1'} &&
	$value =~ m/^(mandatory|optional|obsolete|deprecated)$/o) {
      # Valid SMIv1 status (rfc 1155)
      # add 'deprecated' (rfc 1158, rfc 1212)
      $$data{'status'} = $value;
    }
    elsif ($self->{'accept_smiv2'} &&
	   $value =~ m/^(current|obsolete|deprecated)$/o) {
      # Valid SMIv2 status (rfc 1902, draft-ops-smiv2-smi-01)
      $$data{'status'} = $value;
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Unknown status ($value)");
    }
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error. 'STATUS' needed");
  }
  if ($value eq 'DESCRIPTION') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'description'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	"Syntax error. 'STATUS' needed") unless $self->{'accept_smiv1'};
  }
  if ($value eq 'REFERENCE') {
    (($token, $value) = $self->get_token('CSTRING')) || return;
    $$data{'reference'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  if ($value eq 'INDEX') {
    my $list = [];
    (($token, $value) = $self->get_token('{')) || return;
    while ($value ne '}') {
      (($token, $value) = $self->get_token()) || return;
      my $implied = 0;
      if ($value eq 'IMPLIED') {
	$implied++;
	(($token, $value) = $self->get_token('IDENTIFIER'));
      }
      push @$list, { 'value' => $value, 'implied' => $implied };
      # shoud be a ',' or a '}'
      (($token, $value) = $self->get_token()) || return;
    }
    $$data{'index'} = $list;
    (($token, $value) = $self->get_token()) || return;
  }
  if ($value eq 'AUGMENTS' && $self->{'accept_smiv2'}) {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
	"Can't define both 'INDEX' and 'AUGMENTS'") if defined $$data{'index'};
    $self->get_token('{') || return;
    (($token, $value) = $self->get_token('IDENTIFIER')) || return;
    $$data{'augments'} = $value;
    $self->get_token('}') || return;
    (($token, $value) = $self->get_token()) || return;
  }
  if ($value eq 'DEFVAL') {
    # SMIv1: rfc 1212
    # SMIv2: rfc 1902
    $self->get_token('{') || return;
    (($token, $value) = $self->get_token()) || return;
    if ($value eq '-') {
      (($token, $value) = $self->get_token()) || return;
      $value = "-" . $value;
    }
    $self->get_token('}') || return;
    $$data{'defval'} = $value;
    (($token, $value) = $self->get_token()) || return;
  }
  if ($token == $ASSIGNMENT) {
    my $oid = $self->parse_oid();
    $$data{'oid'} = $oid;
  }
  else {
    return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "should be ::=");
  }
  $data;
}

# parse an OBJECT IDENTIFIER clause
# note: everything except the value has already been parsed.
sub parse_oid {
  my $self = shift;
  #
  # internet OBJECT IDENTIFIER ::= { iso org(3) dod(6) 1 }
  # mgmt     OBJECT IDENTIFIER ::= { internet 2 }
  #                                ^^^^^^^^^^^^^^^^^^^^^^^
  #
  my ($list, $old, $old2);
  $self->get_token('{') || return;
  my ($token, $value);
  (($token, $value) = $self->get_token()) || return;
  while (defined $token && $value ne '}') {
    if ($token == $IDENTIFIER ||
	$token == $NUMBER) {
      push @$list, $value;
      $old2 = $old;
      $old = $value;
    }
    elsif ($value eq '(') {
      if ($old2 && $old) {
	(($token, $value) = $self->get_token('NUMBER')) || return;
        $self->get_token(')') || return;
	# Add this to the tree
	$self->{'nodes'}{$old}{'oid'} = [ $old2, $value ];
      }
      else {
	# These syntaxes are incorrect:
	#  { iso(1) ...}
        #  { (1) ... }
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error");
      }
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "Syntax error");
    }
    (($token, $value) = $self->get_token()) || return;
  }
  $list;
}

# parse an IMPORTS clause.
# note: the 'IMPORTS' keyword has already been parsed.
sub parse_imports {
  my $self = shift;
  #
  # IMPORT a, b, c    FROM mib-foo
  #        d, e, f, g FROM mib-bar;
  #
  my ($list, $data);
  my $elem = 0;
  my ($token, $value);
  (($token, $value) = $self->get_token()) || return;
  while (defined $token && $value ne ';') {
    if ($token == $IDENTIFIER ||
	$token == $TYPEMODREFERENCE) {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "two values must be separated by a comma") if $elem;
      push @$list, $value;
      $elem = 1;
    }
    elsif ($value eq ',') {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "value expected. ',' found") unless $elem;
      $elem = 0;
    }
    elsif ($token == $FROM) {
      $elem = 0;
      my $oldvalue = $value;
      (($token, $value) = $self->get_token()) || return;
      if ($token == $IDENTIFIER ||
	$token == $TYPEMODREFERENCE) {
	my @l;
	@l = @{$$data{$value}} if defined $$data{$value};
	push @l, @$list;
	$$data{$value} = \@l;
	undef $list;
      }
      else {
	return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "identifier expected after '$oldvalue'");
      }

    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "syntax error while parsing IMPORTS clause");
    }
    (($token, $value) = $self->get_token()) || return;
  }
  $data;
}

# parse an EXPORTS clause.
# note: the 'EXPORTS' keyword has already been parsed.
sub parse_exports {
  my $self = shift;
  #
  # EXPORTS a, b, c;
  #
  my $list;
  my $elem = 0;
  my ($token, $value);
  (($token, $value) = $self->get_token()) || return;
  while (defined $token && $value ne ';') {
    if ($token == $IDENTIFIER ||
	$token == $TYPEMODREFERENCE) {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "two values must be separated by a comma") if $elem;
      push @$list, $value;
      $elem = 1;
    }
    elsif ($value eq ',') {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "value expected. ',' found") unless $elem;
      $elem = 0;
    }
    else {
      return $self->assert(MIBERROR, $self->{'filename'}, $self->{'lineno'},
			 "syntax error while parsing EXPORTS clause");
    }
    (($token, $value) = $self->get_token()) || return;
  }
  $list;
}

sub import_modules {
  my $self = shift;

  for my $k (keys %{$self->{'imports'}}) {
    warn "DEBUG: importing $k...\n" if $self->{'debug_lexer'};
    my $mib = new SNMP::MIB::Compiler();
    $mib->repository($self->repository);
    $mib->extensions($self->extensions);
    $mib->{'srcpath'} = $self->{'srcpath'};

    $mib->{'make_dump'}  = $self->{'make_dump'};
    $mib->{'use_dump'}   = $self->{'use_dump'};
    $mib->{'do_imports'} = $self->{'do_imports'};

    $mib->{'allow_underscore'}       = $self->{'allow_underscore'};
    $mib->{'allow_lowcase_hstrings'} = $self->{'allow_lowcase_hstrings'};
    $mib->{'allow_lowcase_bstrings'} = $self->{'allow_lowcase_bstrings'};

    if ($self->{'debug_recursive'}) {
      $mib->{'debug_recursive'} = $self->{'debug_recursive'};
      $mib->{'debug_lexer'}     = $self->{'debug_lexer'};
    }
    $mib->load($k) || $mib->compile($k);
    for my $item (@{$self->{'imports'}{$k}}) {
      warn "DEBUG: importing symbol $item from $k for $self->{'name'}...\n"
	if $self->{'debug_lexer'};
      if (defined $mib->{'nodes'}{$item}) {
	# resolve OID to break the dependencies
	my @a = split /\./, $mib->convert_oid($mib->resolve_oid($item));
	my @l = @{$mib->{'nodes'}{$item}{'OID'}};
	$a[$#a] = $l[$#l];
	@{$mib->{'nodes'}{$item}{'oid'}} = @a;
	shift @l;
	my $last = pop @l;
	for my $elem (@l) {
	  last unless $elem =~ m/^\d+$/o;
	  my $o = shift @a;
	  $self->{'tree'}{$o}{$elem} = $a[0];
	}
	$self->{'tree'}{$a[0]}{$last} = $item if scalar @a == 1;
	$self->{'nodes'}{$item} = $mib->{'nodes'}{$item};
      }
      elsif (defined $mib->{'types'}{$item}) {
	$self->{'types'}{$item} = $mib->{'types'}{$item};
      }
      else {
	my $found = 0;
	for my $macro (@{$mib->{'macros'}}) {
	  $found++, push (@{$self->{'macros'}}, $item) if $macro eq $item;
	}
	$self->assert(MIBWARN, $self->{'filename'}, $self->{'lineno'},
			 "can't find '$item' in $k") unless $found;
      }
    }
    warn "DEBUG: $k imported.\n" if $self->{'debug_lexer'};
  }
}

# Where the MIBs are stored
sub repository {
  my $self = shift;
  my $dir = shift;

  $self->{'repository'} = $dir if defined $dir;
  return $self->{'repository'};
}

# Add some paths to the list of possible MIB locations
sub add_path {
  my $self = shift;

  croak "Usage: Compiler::addpath(path1[,path2[,path3]])" if $#_ == -1;
  while (defined (my $path = shift)) {
    push @{$self->{'srcpath'}}, $path;
  }
  @{$self->{'srcpath'}};
}

# List of possible MIB filename extensions
sub extensions {
  my $self = shift;
  my $ext = shift;

  $self->{'extensions'} = $ext if defined $ext;
  return $self->{'extensions'};
}

# Add some possible MIB filename extensions
sub add_extension {
  my $self = shift;

  croak "Usage: Compiler::extension(ext1[,ext2[,ext3]])" if $#_ == -1;
  while (defined (my $ext = shift)) {
    push @{$self->{'extensions'}}, $ext;
  }
}

my $treemodes = {'read-only'             => '-r-',
		 'read-write'            => '-rw',
		 'read-create'           => 'cr-',
		 'write-only'            => '--w',
		 'not-accessible'        => '---',
		 'accessible-for-notify' => 'n--',
		 'not-implemented'       => 'i--',
		};

my $treetypes = {'SEQUENCE'          => '',
		 'CHOICE'            => '',
		 'INTEGER'           => 'Integer',
		 'OCTET STRING'      => 'String',
		 'OBJECT IDENTIFIER' => 'ObjectID',
		 'NULL'              => 'Null',
		 'IpAddress'         => 'IPAddr',
		 'Counter'           => 'Counter',
		 'Gauge'             => 'Gauge',
		 'TimeTicks'         => 'TimeTcks',
		 'Opaque'            => 'Opaque',
		 'Integer32'         => 'Int32',
		 'Counter32'         => 'Count32',
		 'Gauge32'           => 'Gauge32',
		 'Unsigned32'        => 'UInt32',
		 'Counter64'         => 'Count64',
		};

# return an ASCII driagram showing the tree under the given node
sub tree {
  my $self  = shift;
  my $node  = shift;
  my $level = shift;
  my $inc   = shift;
  my $s     = shift;

  $level = 0 unless defined $level;
  $inc   = 4 unless defined $inc;

  return $level ? $s : "$node\n" unless defined $self->{'tree'}{$node};
  unless ($level) {
    $s .= $node . "\n";
    $s .= "  |\n";
  }
  for my $n (sort { $a <=> $b } keys %{$self->{'tree'}{$node}}) {
    my $new = $self->{'tree'}{$node}{$n};
    $s .= "  ";
    $s .= " " x ($inc * $level) . "+-- ";
    my $access = "";
    $access = $$treemodes{$self->{'nodes'}{$new}{'access'}} || "???"
      if defined $self->{'nodes'}{$new}{'access'};
    $access .= " " if $access;
    my $type = "";
    $type = $self->{'nodes'}{$new}{'syntax'}{'type'} if
      defined $self->{'nodes'}{$new}{'syntax'} &&
	defined $self->{'nodes'}{$new}{'syntax'}{'type'};
    if ($type) {
      $type = $self->resolve_type($type);
      $type = sprintf "%-8.8s ", defined $$treetypes{$type} ?
	$$treetypes{$type} : $type;
      $type = "" if $type =~ m/^\s+$/o;
    }
    $s .= $access . $type . $new . '(' . $n . ")\n";
    if (defined $self->{'tree'}{$new}) {
      $s .= "  ";
      $s .= " " x ($inc * ($level + 1)) . "|\n";
      $s = $self->tree($new, $level + 1, $inc, $s);
    }
  }
  $s;
}

###########################################################################
package Stream;

use strict;
use vars qw($VERSION);

$VERSION = 1.00;

sub new {
  my $this = shift;
  my $fh = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->{'fh'} = $fh;
  $self->{'lineno'} = 1;
  $self->{'saved'} = 0;
  $self;
}

sub getc {
  my $self = shift;

  my $char;
  if ($self->{'saved'}) {
    $char = $self->{'save'};
    $self->{'saved'} = 0;
    $self->{'lineno'}++ if $char eq "\n";
  }
  elsif (defined ($char = getc $self->{'fh'})) {
    $self->{'save'} = $char;
    $self->{'lineno'}++ if $char eq "\n";
  }
  else {
    $char = '';
  }
  $char;
}

sub ungetc {
  my $self = shift;

  $self->{'saved'} = 1;
  $self->{'lineno'}-- if $self->{'save'} eq "\n";
}

sub lineno {
  my $self = shift;

  $self->{'lineno'};
}

1;

=head1 NAME

SNMP::MIB::Compiler - a MIB Compiler supporting SMIv1 and SMIv2

=head1 SYNOPSIS

    use SNMP::MIB::Compiler;

    my $mib = new SNMP::MIB::Compiler;

    # search MIBs there...
    $mib->add_path('./mibs', '/foo/bar/mibs');

    # possibly using these extensions...
    $mib->add_extension('', '.mib', '.my');

    # store the compiled MIBs there..
    $mib->repository('./out');

    # only accept SMIv2 MIBs
    $mib->{'accept_smiv1'} = 0;
    $mib->{'accept_smiv2'} = 1;

    # no debug
    $mib->{'debug_lexer'}     = 0;
    $mib->{'debug_recursive'} = 0;

    # store compiled MIBs into files
    $mib->{'make_dump'}  = 1;
    # read compiled MIBs
    $mib->{'use_dump'}   = 1;
    # follow IMPORTS clause while compiling
    $mib->{'do_imports'} = 1;

    # load a precompiled MIB
    $mib->load('SNMPv2-MIB');

    # compile a new MIB
    $mib->compile('IF-MIB');

    print $mib->resolve_oid('ifInOctets'), "\n";
    print $mib->convert_oid('1.3.6.1.2.1.31.1.1.1.10'), "\n";
    print $mib->tree('ifMIB');

=head1 DESCRIPTION

    SNMP::MIB::Compiler is a MIB compiler that fully supports
    both SMI(v1) and SMIv2. This module can be use to compile
    MIBs (recursively or not) or load already compiled MIBs for
    later use.
    Some tasks can be performed by the resulting object such as :

      - resolution of object names into object identifiers (OIDs).
        e.g. ifInOctets => 1.3.6.1.2.1.2.2.1.10

      - convertion of OIDs.
        e.g. 1.3.6.1.2.1.2.1 =>
               iso.org.dod.internet.mgmt.mib-2.interfaces.ifNumber

      - drawing MIB trees.
        e.g. ifTestTable => ifTestTable
                                |
                                +-- --- ifTestEntry(1)
                                    |
                                    +-- -rw Integer  ifTestId(1)
                                    +-- -rw Integer  ifTestStatus(2)
                                    +-- -rw ObjectID ifTestType(3)
                                    +-- -r- Integer  ifTestResult(4)
                                    +-- -r- ObjectID ifTestCode(5)
                                    +-- -rw String   ifTestOwner(6)


    The MIB to be compiled requires no modification. Everything legal
    according to SMIs is accepted, including MACRO definitions (which
    are parsed but ignored).

    This module is shipped with the basic MIBs usually needed by IMPORTS
    clauses. A lot of IETF MIBs has been successfully tested as well as
    some private ones.

=head1 Methods

=over 5

=item C<new>

C<SNMP::MIB::Compiler::new()> I<class method>

To create a new MIB, send a new() message to the SNMP::MIB::Compiler
class.  For example:

	my $mib = new SNMP::MIB::Compiler;

This will create an empty MIB ready to accept both SMIv1 and SMIv2
MIBs. A lot of attributes can be (des)activated to obtain a more
or less strict and verbose compiler.
The created object is returned.

=item C<add_path>

C<SNMP::MIB::Compiler::add_path(p1[,p2[,p3]])> I<object method>

Add one or more directories to the search path. This path is used to
locate a MIB file when the 'compile' method is invoqued.
The current list of paths is returned.

Example:

    # search MIBs in the "mibs" directory (relative
    # to cwd) and in "/foo/bar/mibs" (absolute path)
    $mib->add_path('./mibs', '/foo/bar/mibs');

=item C<add_extension>

C<SNMP::MIB::Compiler::add_extension(e1[,e2[,e3]])> I<object method>

Add one or more extensions to the extension list. These extensions are
used to locate a MIB file when the 'compile' method is invoqued. All
extensions are tested for each directory specified by the add_path()
method until one match.
The current list of extensions is returned.

Example:

    $mib->add_path('./mibs', '/foo/bar/mibs');
    $mib->add_extension('', '.mib');
    $mib->compile('FOO');

    The order is "./mibs/FOO", "./mibs/FOO.mib", "/foo/bar/mibs/FOO"
    and "/foo/bar/mibs/FOO.mib".

=item C<repository>

C<SNMP::MIB::Compiler::repository([dir])> I<object method>

If 'dir' is defined, set the directory where compiled MIBs will be
stored (using the compile() method) or loaded (using the load() method).
The repository MUST be initialized before a MIB can be compiled or loaded.
The current repository is returned.

Example:

    $mib->repository('./out');
    print "Current repository is ", $mib->repository, "\n";

=item C<compile>

C<SNMP::MIB::Compiler::compile(mib)> I<object method>

Compile a MIB given its name. All information contained in
this MIB is inserted into the current object and is stored
into a file in the repository (see the 'make_dump' attribute).
The choosen name is the same as the real MIB name (defined
in the MIB itself). If a precompiled MIB already exists in
the repository and is newer than the given file, it is used
instead of a real compilation (see the 'use_dump' attribute).
The compiler can be recursive if IMPORTS clauses are followed
(see the 'do_imports' attribute) and in that case, uncompiled
MIB names must be explict according to paths and extensions
critaeria (see add_path() and add_extensions() methods).
The current object is returned.

=item C<load>

C<SNMP::MIB::Compiler::load(mib)> I<object method>

Load a precompiled MIB given its name. All information contained in
this MIB is inserted into the current object. The file is searched in the
repository which MUST be initialized. In case of success, returns 1
else returns 0.

Example:

    $mib->load('SNMPv2-SMI');
    $mib->load('SNMPv2-MIB');

=item C<resolve_oid>

C<SNMP::MIB::Compiler::resolve_oid(node)> I<object method>

Example:

    print $mib->resolve_oid('ifInOctets'), "\n";

=item C<convert_oid>

C<SNMP::MIB::Compiler::convert_oid(oid)> I<object method>

Example:

    print $mib->convert_oid('1.3.6.1.2.1.31.1.1.1.10'), "\n";

=item C<tree>

C<SNMP::MIB::Compiler::tree(node)> I<object method>

Example:

    print $mib->tree('ifMIB');

=back

=head1 Attributes

=over 5

=item C<do_imports>

=item C<accept_smiv1>

=item C<accept_smiv2>

=item C<allow_underscore>

=item C<allow_lowcase_hstrings>

=item C<allow_lowcase_bstrings>

=item C<make_dump>

=item C<dumpext>

=item C<use_dump>

=item C<debug_lexer>

=item C<debug_recursive>

=back

=head1 BUGS

Currently, it is more a TODO list than a bug list.

- not enough documentation

- not enough methods

- not enough test scripts

- find a better name for compiled MIBs than 'dump's.. even if they are
no more than dumps.

If your MIBs can't be compiled by this module, please, double check
their syntax. If you really think that they are correct, send them
to me including their "uncommon" dependencies.

=head1 AUTHOR

Fabien Tassin (fta@oleane.net)

=head1 COPYRIGHT

Copyright 1998, 1999, Fabien Tassin. All rights reserved.
It may be used and modified freely, but I do request that
this copyright notice remain attached to the file. You may
modify this module as you wish, but if you redistribute a
modified version, please attach a note listing the modifications
you have made.

=cut
