#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Parse::Eyapp;
our %s; # symbol table

my $ts = q{
  %token FLOAT INTEGER NAME

  %{
  our %s; 

  my %reserved_words = ( INTEGER => 'INTEGER', FLOAT => 'FLOAT');
  my $validchars = qr{[,;]}; 
  my $ID = qr{[a-z_A_Z_]\w*};

  %}

  %lexer {
    m{\G\s+}gc;                     # skip whites
    if (m{\G($ID)}gc) {
      my $w = uc($1);                 # upper case the word
      return ($w, $w) if exists $reserved_words{$w};
      return ('NAME', $1);            # not a reserved word
    } 
    return ($1, $1) if m/\G($validchars)/gc;
  }

  %metatree

  %%
  Dl: D 
    | Dl ';' D
  ;

  D : $T { $L->{t} = $T->{t} } $L 
  ;

  T : FLOAT    { $lhs->{t} = "FLOAT" } 
    | INTEGER  { $lhs->{t} = "INTEGER" } 
  ;

  L : $NAME 
        { $NAME->{t} = $lhs->{t}; $s{$NAME->{attr}} = $NAME } 
    | $NAME { $NAME->{t} = $lhs->{t}; $L->{t} = $lhs->{t} } ',' $L 
        { $s{$NAME->{attr}} = $NAME } 
  ;
  %%
};


Parse::Eyapp->new_grammar(input=>$ts, classname=>'main', outputfile=>'Types.pm'); 
my $parser = main->new(); # Create the parser
my $input = shift || "float x,y;\ninteger a,b\n";
$parser->input(\$input);
print "Input: $input";

my $t = $parser->YYParse() or die "Syntax Error analyzing input";

$t->translation_scheme;

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Deparse = 1;
print "Tree:\n".Dumper($t);
print "Symbol table:\n".Dumper(\%s);

