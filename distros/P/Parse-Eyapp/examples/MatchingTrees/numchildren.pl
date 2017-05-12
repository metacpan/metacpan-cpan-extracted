#!/usr/bin/env perl 
use warnings;
use strict;
use Rule6;
use Parse::Eyapp::Treeregexp;

sub TERMINAL::info { $_[0]{attr} }

my $input = shift || '0*2';
my $severity = shift || 0;

my $parser = Rule6->new();
$parser->input(\$input);
my $t = $parser->YYParse();

exit(1) if $parser->YYNberr > 0;

my $transform = Parse::Eyapp::Treeregexp->new( 
  STRING => q{
    zero_times_whatever: TIMES(NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }
  },
  SEVERITY => $severity,
)->generate;

# The package special variable @all now contains the whole set of transformations
$t->s(our @all);

print qq{Tree after applying '0*x => 0' transformation:\n}.$t->str,"\n";

=head1 SYNOPSIS

Compile C<Rule6.yp> first:

             eyapp Rule6

Run it like this:

      $ ./numchildren.pl 'a=0*8'
      Tree after applying '0*x => 0' transformation:
      ASSIGN(TERMINAL[a],NUM(TERMINAL[0]))

