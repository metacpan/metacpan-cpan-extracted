#
# Module Parse::Eyapp::Output
#
# This module is based on Francois Desarmenien Parse::Yapp distribution
# (c) Parse::Yapp Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (c) Parse::Eyapp Copyright 2006-2008 Casiano Rodriguez-Leon, all rights reserved.
#

package Parse::Eyapp::Output;
use strict;

our @ISA=qw ( Parse::Eyapp::Lalr );

require 5.004;

use Parse::Eyapp::Base qw(compute_lines);
use Parse::Eyapp::Lalr;
use Parse::Eyapp::Driver;
use Parse::Eyapp::Node; # required to have access to $Parse::Eyapp::Node::FILENAME
use File::Basename;
#use Data::Dumper;
use List::Util qw(first);


use Carp;

# Remove tokens that not appear in the right hand side
# of any production
# Check if not quote tokens aren't defined
sub deleteNotUsedTokens {
  my ($self, $term, $termDef) = @_;
  
  my $rules = $self->{GRAMMAR}{RULES};
  my @usedSymbols = map { @{$_->[1]} } @$rules;
  my %usedSymbols;
  @usedSymbols{@usedSymbols} = ();

  for (@{$self->{GRAMMAR}{DUMMY}}) {
    delete $usedSymbols{$_};
    delete $termDef->{$_};
  }

  for my $token (keys %$term) {
    delete $term->{$token} unless exists $usedSymbols{$token};
  }

  # Emit a warning if exists a non '' token in %usedSymbols that is not in %termdef
  if ($self->{GRAMMAR}{STRICT} && %$termDef) {
    my @undefined = grep { ! exists $termDef->{$_} } grep { m{^[^']} } keys %$term;
    if (@undefined) {
      @undefined = map { "Warning: may be you forgot to define token '$_'?: %token $_ = /someRegExp/" } @undefined;

      local $" = "\n";
      warn "@undefined\n";
    }
  }
}

# builds a trivial lexer
sub makeLexer {
  my $self = shift;

  my $WHITES = 'm{\G(\s+)}gc and $self->tokenline($1 =~ tr{\n}{})';
  my $w = $self->{GRAMMAR}{WHITES}[0];
  if (defined $w)  {
    # if CODE then literally
    if ($self->{GRAMMAR}{WHITES}[2] eq 'CODE') {
      $WHITES = $w;
    }
    else {
      $w =~ s{^/}{/\\G};
      $WHITES = $w.'gc and $self->tokenline($1 =~ tr{\n}{})';
    }
  }

  my $INCREMENTAL = defined($self->{GRAMMAR}{INCREMENTAL}) ? _incrementalLexerText() : '';

  my %term = %{$self->{GRAMMAR}{TERM}};
  delete $term{"\c@"};
  delete $term{'error'};

  my %termdef = %{$self->{GRAMMAR}{TERMDEF}}; 

  $self->deleteNotUsedTokens(\%term, \%termdef);


  # remove from %term the tokens that were explictly defined
  my @index = grep { !(exists $termdef{$_}) } keys %term;
  %term = map { ($_, $term{$_}) } @index;

  my @term = map { s/'$//; s/^'//; $_ } keys %term;

  @term = sort { length($b) <=> length($a) } @term;
  @term = map { quotemeta } @term;

  # Keep escape characters as \n \r, etc.
  @term = map { s/\\\\(.)/\\$1/g; $_ } @term;

  my $TERM = '';
  if (@term) {
    $TERM = join '|', @term;
    $TERM = "\\G($TERM)";
  }
 
  # Translate defined tokens
  # sort by line number
  my @termdef = sort { $termdef{$a}->[1] <=> $termdef{$b}->[1] } keys %termdef;

  my $DEFINEDTOKENS = '';
  for my $t (@termdef) {
    if ($termdef{$t}[2] eq 'REGEXP') {
      my $reg = $termdef{$t}[0];
      $reg =~ s{^/}{/\\G}; # add \G at the begining of the regexp
      $DEFINEDTOKENS .= << "EORT";
      ${reg}gc and return ('$t', \$1);
EORT
    }
    elsif ($termdef{$t}[2] eq 'CONTEXTUAL_REGEXP') {
      my $reg = $termdef{$t}[0];
      $reg =~ s{^/}{/\\G}; # add \G at the begining of the regexp
      $DEFINEDTOKENS .= << "EORT";
      \$self->expects('$t') and ${reg}gc and return ('$t', \$1);
EORT
    }
    elsif ($termdef{$t}[2] eq 'CONTEXTUAL_REGEXP_MATCH') {
      my $reg = $termdef{$t}[0];
      my $parser = $termdef{$t}[3][0];
      $reg =~ s{^/}{/\\G}; # add \G at the begining of the regexp
      $DEFINEDTOKENS .= << "EORT";
      \$pos = pos();
      if (${reg}gc) { 
        if (\$self->expects('$t')) {   
           my \$oldselfpos = \$self->{POS};
           \$self->{POS} = pos();   
           if (\$self->YYPreParse('$parser')) {
             \$self->{POS} = \$oldselfpos;
             return ('$t', \$1); 
           }
           else {
             \$self->{POS} = \$oldselfpos;
           }
        }
      }
      pos(\$_) = \$pos;
EORT
    }
    elsif ($termdef{$t}[2] eq 'CONTEXTUAL_REGEXP_NOMATCH') {
      my $reg = $termdef{$t}[0];
      my $parser = $termdef{$t}[3][0];
      $reg =~ s{^/}{/\\G}; # add \G at the begining of the regexp
      # factorize, factorize!!!! ohh!!!!
      $DEFINEDTOKENS .= << "EORT";
      \$pos = pos();
      if (${reg}gc) { 
        if (\$self->expects('$t')) {   
           my \$oldselfpos = \$self->{POS};
           \$self->{POS} = pos();   
           if (!\$self->YYPreParse('$parser')) {
             \$self->{POS} = \$oldselfpos;
             return ('$t', \$1); 
           }
           else {
             \$self->{POS} = \$oldselfpos;
           }
        }
      }
      pos(\$_) = \$pos;
EORT
    }
    elsif ($termdef{$t}[2] eq 'LITERAL') { # %token without regexp or code definition
      my $reg = $termdef{$t}[0];
      $reg =~ s{^'?}{};   # $reg =~ s{^'?}{/\\G(};
      $reg =~ s{'?$}{};   # $reg =~ s{'?$}{)/}; 
      $reg = quotemeta($reg);
      $DEFINEDTOKENS .= << "EORT";
      /\\G(${reg})/gc and return (\$1, \$1);
EORT
    }
    elsif ($termdef{$t}[2] eq 'CODE') { # token definition is code
      $DEFINEDTOKENS .= "$termdef{$t}[0]\n";
    }
  }

  my $frame = _lexerFrame();
  $frame =~ s/<<INCREMENTAL>>/$INCREMENTAL/;
  $frame =~ s/<<WHITES>>/$WHITES/;

  if (@term) {
    $frame =~ s/<<TERM>>/m{$TERM}gc and return (\$1, \$1);/ 
  }
  else {
    $frame =~ s/<<TERM>>//
  }

  $frame =~ s/<<DEFINEDTOKENS>>/$DEFINEDTOKENS/;

  return $frame;
}

sub _incrementalLexerText {

  return << 'ENDOFINCREMENTAL';
if ($self->YYEndOfInput) {
          print $a if defined($a = $self->YYPrompt);
          my $file = $self->YYInputFile;
          $_ = <$file>;
          return ('', undef) unless $_;
        }
ENDOFINCREMENTAL
}

sub _lexerFrame {
  return << 'EOLEXER';
# Default lexical analyzer
our $LEX = sub {
    my $self = shift;
    my $pos;

    for (${$self->input}) {
      <<INCREMENTAL>>

      <<WHITES>>;

      <<TERM>>

<<DEFINEDTOKENS>>

      return ('', undef) if ($_ eq '') || (defined(pos($_)) && (pos($_) >= length($_)));
      /\G\s*(\S+)/;
      my $near = substr($1,0,10); 

      return($near, $near);

     # die( "Error inside the lexical analyzer near '". $near
     #     ."'. Line: ".$self->line()
     #     .". File: '".$self->YYFilename()."'. No match found.\n");
    }
  }
;
EOLEXER
}

####################################################################
# Returns    : The string '{\n file contents }\n'  with pre and post comments
# Parameters : a file name
sub _CopyModule {
  my ($module, $function, $file) = @_;

  open(DRV,$file) or  die "BUG: could not open $file";
  my $text = join('',<DRV>);
  close(DRV);

  my $label = $module;
  $label =~ s/::/_/g;
  return << "EOCODE";
  # Loading $module
  BEGIN {
    unless ($module->can('$function')) {
      eval << 'MODULE_$label'
$text
MODULE_$label
    }; # Unless $module was loaded
  } ########### End of BEGIN { load $file }

EOCODE
}

## This sub gives support to the "%tree alias" directive
## Builds the text for the named accessors to the children
sub make_accessors {
  my $accessors = shift; # hash reference: like left => 0

  my $text = '{';
  for (keys(%$accessors)) {
    $text .= "\n      '$_' => $accessors->{$_},";
  }
  return "$text\n   }";
}

# Compute line numbers for the outputfile. Need for debugging
our $pattern = '################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################';

sub Output {
  my($self)=shift;

  $self->Options(@_);

  my ($GRAMMAR, $TERMS, $FILENAME, $PACKAGES, $LABELS); # Cas
  my($package)=$self->Option('classname');

  my $modulino = $self->Option('modulino'); # prompt or undef 

  if (defined($modulino)) {
    $modulino = <<"MODULINO";
unless (caller) {
  exit !__PACKAGE__->main('$modulino');
}
MODULINO
  }
  else {
    $modulino = '';
  }

  my $lexerisdefined = $self->Option('lexerisdefined') || $self->{GRAMMAR}{LEXERISDEFINED}; 
  my $defaultLexer = $lexerisdefined ? q{} : $self->makeLexer();

  my($head,$states,$rules,$tail,$driver, $bypass, $accessors, $buildingtree, $prefix, $conflict_handlers, $state_conflict);
  my($version)=$Parse::Eyapp::Driver::VERSION;
  my($datapos);
  my $makenodeclasses = '';
  $driver='';

      defined($package)
  or $package='Parse::Eyapp::Default'; # may be the caller package?

  $head= $self->Head();
  $rules=$self->RulesTable();
  $states=$self->DfaTable();
  $tail= $self->Tail();

  my $prompt = $self->Prompt();

  # In case the file ends with documentation and without a 
  # =cut
  #
  $tail = $tail."\n\n=for None\n\n=cut\n\n" unless $tail =~ /\n\n=cut\n/;
  #local $Data::Dumper::Purity = 1;

  ($GRAMMAR, $PACKAGES, $LABELS) = $self->Rules();
  $bypass = $self->Bypass;
  $prefix = $self->Prefix;

  $conflict_handlers = $self->conflictHandlers;
  $state_conflict = $self->stateConflict;

  $buildingtree = $self->Buildingtree;
  $accessors = $self->Accessors;
  my $accessors_hash = make_accessors($accessors);
  $TERMS = $self->Terms();

  # Thanks Tom! previous double-quote use produced errors in windows
  $FILENAME = q{'}.$self->Option('inputfile').q{'};

  if ($self->Option('standalone')) {
    # Copy Driver, Node and YATW
    
    $driver .=_CopyModule('Parse::Eyapp::Driver','YYParse', $Parse::Eyapp::Driver::FILENAME);
    $driver .= _CopyModule('Parse::Eyapp::Node', 'm', $Parse::Eyapp::Node::FILENAME);

    # Remove the line use Parse::Eyapp::YATW
    $driver =~ s/\n\s*use Parse::Eyapp::YATW;\n//g;
    $driver .= _CopyModule('Parse::Eyapp::YATW', 'm', $Parse::Eyapp::YATW::FILENAME);

    $makenodeclasses = '$self->make_node_classes('.$PACKAGES.');';
  }
  else {
    $driver = make_header_for_driver_pm();
    $makenodeclasses = '$self->make_node_classes('.$PACKAGES.');';
  }

  my($text)=$self->Option('template') || Driver_pm();

  $text=~s/<<(\$.+)>>/$1/gee;

  $text;
}

sub make_header_for_driver_pm {
  return q{
BEGIN {
  # This strange way to load the modules is to guarantee compatibility when
  # using several standalone and non-standalone Eyapp parsers

  require Parse::Eyapp::Driver unless Parse::Eyapp::Driver->can('YYParse');
  require Parse::Eyapp::Node unless Parse::Eyapp::Node->can('hnew'); 
}
  }; 
}

sub Driver_pm {
  return <<'EOT';
########################################################################################
#
#    This file was generated using Parse::Eyapp version <<$version>>.
#
# (c) Parse::Yapp Copyright 1998-2001 Francois Desarmenien.
# (c) Parse::Eyapp Copyright 2006-2008 Casiano Rodriguez-Leon. Universidad de La Laguna.
#        Don't edit this file, use source file <<$FILENAME>> instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
########################################################################################
package <<$package>>;
use strict;

push @<<$package>>::ISA, 'Parse::Eyapp::Driver';

<<$prompt>>

<<$driver>>

sub unexpendedInput { defined($_) ? substr($_, (defined(pos $_) ? pos $_ : 0)) : '' }

<<$head>>

<<$defaultLexer>>

################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################

my $warnmessage =<< "EOFWARN";
Warning!: Did you changed the \@<<$package>>::ISA variable inside the header section of the eyapp program?
EOFWARN

sub new {
  my($class)=shift;
  ref($class) and $class=ref($class);

  warn $warnmessage unless __PACKAGE__->isa('Parse::Eyapp::Driver'); 
  my($self)=$class->SUPER::new( 
    yyversion => '<<$version>>',
    yyGRAMMAR  =>
<<$GRAMMAR>>,
    yyLABELS  =>
<<$LABELS>>,
    yyTERMS  =>
<<$TERMS>>,
    yyFILENAME  => <<$FILENAME>>,
    yystates =>
<<$states>>,
    yyrules  =>
<<$rules>>,
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
    yybypass       => <<$bypass>>,
    yybuildingtree => <<$buildingtree>>,
    yyprefix       => '<<$prefix>>',
    yyaccessors    => <<$accessors_hash>>,
    yyconflicthandlers => <<$conflict_handlers>>,
    yystateconflict => <<$state_conflict>>,
    @_,
  );
  bless($self,$class);

  <<$makenodeclasses>>
  $self;
}

<<$tail>>
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################

<<$modulino>>

1;
EOT
}

####################################################################
# Usage      :   
#   my $warnings = Parse::Eyapp->new_grammar(
#                                 input=>$translationscheme,
#                                 classname=>'main',
#                                 firstline => 6,
#                                 outputfile => 'main.pm'
#                  );
#  die "$warnings\nSolve Ambiguities. See file main.output\n"  if $warnings;
#
# Returns    : string reporting about the ambiguities and conflicts or ''
# Throws     : croaks if invalid arguments, if the grammar has errors, if can not open
#              files or if the semantic actions have errors
#             
# Parameters : 
my %_new_grammar = (
  input => undef,     
  classname => undef,
  firstline => undef,
  linenumbers => undef,
  outputfile => undef,
);
my $validkeys = do { local $" = ", "; my @validkeys = keys(%_new_grammar); "@validkeys" };

sub new_grammar {
  my $class = shift;

  croak "Error in new_grammar: Use named arguments" if (@_ %2);
  my %arg = @_;
  if (defined($a = first { !exists($_new_grammar{$_}) } keys(%arg))) {
    croak("Parse::Eyapp::Output::new_grammar Error!: unknown argument $a. Valid arguments are: $validkeys")
  }
  
  my $grammar = $arg{input} or croak "Error in new_grammar: Specify a input grammar";

  my $name = $arg{classname} or croak 'Error in  new_grammar: Please provide a name for the grammar';

  my ($package, $filename, $line) = caller;

  $line = $arg{firstline} if defined($arg{firstline}) and ($arg{firstline} =~ /\d+/);

  my $linenumbers = $arg{linenumbers};
  $linenumbers = 1 unless defined($linenumbers);

  croak "Bad grammar." 
    unless my $p = Parse::Eyapp->new(
          input => $grammar, 
          inputfile => $filename, 
          firstline => $line,
          linenumbers => $linenumbers,
    ); 

  my $text = $p->Output(classname => $name) or croak "Can't generate parser.";

  my $outputfile = $arg{outputfile};
  croak "Error in new_grammar: Invalid option for parameter linenumber" unless $linenumbers =~ m{[01]};

  if (defined($outputfile)) {
    my($base,$path,$sfx)=fileparse($outputfile,'\..*$');
    $p->outputtables($path, $base);
    my($outfile)="$path$base.pm";
      open(my $OUT,">$outfile")
    or die "Cannot open $outfile for writing.\n";

    compute_lines(\$text, $outfile, $pattern);
    print $OUT $text; #$p->Output(classname  => $name, linenumbers => $linenumbers);
    close $OUT;
  }

  my $x = eval $text;
  $@ and die "Error while compiling your parser: $@\n";
  return $p;
}

1;

__END__

