#!/usr/bin/perl -w
use strict;
use Parse::Eyapp;
use Infix;
use I2PIR;

sub TERMINAL::info { $_[0]{attr} }

sub build_dec {
  our %s;
  my $dec = "";
  if (%s) {
    my @vars = sort keys %s;
    my $last = pop @vars;
    $dec .= "$_, " for @vars;
    $dec .= $last;
  }
  return $dec;
}

sub peephole_optimization {
  $_[0] =~ s{(\$N\d+)\s*=\s*(.*\n)\s* ([a-zA-Z_]\w*)\s*=\s*\1}{$3 = $2}gx;
}

sub output_code {
  my ($trans, $dec) = @_;

  # Indent
  $$trans =~ s/^/\t/gm;

  # Output the code
print << "TRANSLATION";
.sub 'main' :main
\t.local num $$dec
$$trans
.end
TRANSLATION
}

################# main ######################
my $filename = shift;
my $parser = Infix->new(); 
$parser->slurp_file($filename);

my $t = $parser->YYParse() || exit(1);

# Machine independent optimizations
$t->s(our @algebra);  

# Address Assignment 
our $reg_assign;
$reg_assign->s($t);

# Translate to PARROT
$t->bud(our @translation);
# variable declarations
my $dec = build_dec();

peephole_optimization($t->{tr});

output_code(\$t->{tr}, \$dec);
