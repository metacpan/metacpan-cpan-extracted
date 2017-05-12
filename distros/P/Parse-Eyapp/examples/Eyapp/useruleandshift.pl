#!/usr/bin/perl -w
use strict;
use Rule5;
use Parse::Eyapp::Base qw(insert_function);
use Shift;

=head1 SYNOPSIS

Compile the grammar and tree transformations first:

     $ eyapp Rule5
     $ treereg Shift

Then execute it with:

     $ ./useruleandshift.pl

Try inputs: 

     a = b * 8
     d = c * 16

=cut

sub SHIFTLEFT::info { $_[0]{shift} }
insert_function('TERMINAL::info', \&TERMINAL::attr);

my $parser = new Rule5();
$parser->YYPrompt('Arithmetic expression: ');
$parser->slurp_file('', "\n");
my $t = $parser->Run;
unless ($parser->YYNberr) {
  print "***********\n",$t->str,"\n";
  $t->s(@Shift::all);
  print "***********\n",$t->str,"\n";
}
