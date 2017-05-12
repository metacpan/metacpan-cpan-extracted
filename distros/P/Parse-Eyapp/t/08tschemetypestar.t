#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Test::More tests=>2;
use_ok qw( Parse::Eyapp );
our %s; # symbol table

my $ts = q{
  %token FLOAT INTEGER 
  %token NAME

  %metatree

  %%
  Dl:  D <* ';'> 
  ;

  D : $T { $L->{t} = $T->{t} } $L 
  ;

  T : FLOAT    { $lhs->{t} = "FLOAT" } 
    | INTEGER  { $lhs->{t} = "INTEGER" } 
  ;

  L : $NAME                                { $NAME->{t} = $lhs->{t}; $::s{$NAME->{attr}} = $NAME } 
    | $NAME { $NAME->{t} = $lhs->{t}; $L->{t} = $lhs->{t} } ',' $L { $::s{$NAME->{attr}} = $NAME } 
  ;
  %%
};

sub Error { die "Error sintáctico\n"; }

sub make_scanner { # hagamos una clausura con la entrada
  my $input = shift;

  return sub {

    { # Con el redo del final hacemos un bucle "infinito"
      if ($input =~ m|\G\s*INTEGER\b|igc) {
        return ('INTEGER', 'INTEGER');
      } 
      elsif ($input =~ m|\G\s*FLOAT\b|igc) {
        return ('FLOAT', 'FLOAT');
      } 
      elsif ($input =~ m|\G\s*([a-z_]\w*)\b|igc) {
        return ('NAME', $1);
      } 
      elsif ($input =~ m/\G\s*([,;])/gc) {
        return ($1, $1);
      }
      elsif ($input =~ m/\G\s*(.)/gc) {
        die "Caracter invalido: $1\n";
      }
      else {
        return ('', undef); # end of file
      }
      redo;
    }
  }
}

Parse::Eyapp->new_grammar(input=>$ts, classname=>'Types',); # outputfile=>'Types.pm'); 
my $parser = Types->new();                 # Create the parser
my $scanner = make_scanner("float x,y;\ninteger a,b\n");

  # build translation scheme ...
  my $t = $parser->YYParse( yylex => $scanner, yyerror => \&Error) 
or die "Syntax Error analyzing input";

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy  = 1;
#print Dumper($t);
$t->translation_scheme;

#print Dumper($t);

# test symbol table
my $expected_symbol_table = {
  'y' => bless( {
    'children' => [],
    'attr' => 'y',
    'token' => 'NAME',
    't' => 'FLOAT'
  }, 'TERMINAL' ),
  'a' => bless( {
    'children' => [],
    'attr' => 'a',
    'token' => 'NAME',
    't' => 'INTEGER'
  }, 'TERMINAL' ),
  'b' => bless( {
    'children' => [],
    'attr' => 'b',
    'token' => 'NAME',
    't' => 'INTEGER'
  }, 'TERMINAL' ),
  'x' => bless( {
    'children' => [],
    'attr' => 'x',
    'token' => 'NAME',
    't' => 'FLOAT'
  }, 'TERMINAL' )
};

print Dumper(\%s);

is_deeply(\%s, $expected_symbol_table, "translation scheme. outputfile option");
