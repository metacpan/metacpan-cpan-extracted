#!/usr/bin/env perl
use strict;
use warnings;
use Ordeal::Model;
my $model = Ordeal::Model->new(PlainFile => [base_directory => 'xmpl']);

$|++;
my $prompt = 'expression> ';
print {*STDOUT} $prompt;
while (defined(my $expression = <>)) {
   my $shuffle = $model->evaluate($expression);
   my @cards = $shuffle->draw;
   my $n_cards = @cards;
   my $n_cards_length = length $n_cards;
   my $format = "%${n_cards_length}d. %s\n";
   for my $index (0 .. $#cards) {
      printf {*STDOUT} $format, $index + 1, $cards[$index]->name;
   }
   print {*STDOUT} "\n$prompt";
}
