# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use Test;
BEGIN { plan tests => 24 };

use Statistics::Contingency;

ok(1);

my $all_categories = [qw(sports politics finance world)];

{
  my $e = new Statistics::Contingency(categories => $all_categories);
  ok $e;
  
  $e->add_result(['sports','finance'], ['sports']);
  ok $e->micro_recall, 1, "micro recall";
  ok $e->micro_precision, 0.5, "micro precision";
  ok $e->micro_F1, 2/3, "micro F1";
}

{
  my $e = new Statistics::Contingency(categories => $all_categories);
  $e->add_result(['sports','finance'], ['politics']);
  ok $e->micro_recall, 0, "micro recall";
  ok $e->micro_precision, 0, "micro precision";
  ok $e->micro_F1, 0, "micro F1";
}

{
  my $e = new Statistics::Contingency(categories => $all_categories);
  
  $e->add_result(['sports','finance'], ['sports']);
  ok $e->micro_recall, 1, "micro recall";
  ok $e->macro_recall, 1, "macro recall";

  $e->add_result(['sports','finance'], ['politics']);

  ok $e->micro_recall, 0.5, "micro recall";
  ok $e->micro_precision, 0.25, "micro precision";
  ok $e->micro_F1, 1/3, "micro F1";

  ok $e->macro_recall, 0.75, "macro recall";
  ok $e->macro_precision, 0.375, "macro precision";
  ok $e->macro_F1, 5/12, "macro F1";
}

{
  my $e = new Statistics::Contingency(categories => $all_categories);
  $e->add_result([], ['politics']);
  ok $e->micro_recall, 0, "micro recall";
  ok $e->micro_precision, 0, "micro precision";
  ok $e->micro_F1, 0, "micro F1";
}

{
  my $e = new Statistics::Contingency(categories => $all_categories);
  $e->add_result([], []);
  ok $e->micro_recall, 1, "micro recall";
  ok $e->micro_precision, 1, "micro precision";
  ok $e->micro_F1, 1, "micro F1";
}

{
  my $e = new Statistics::Contingency(categories => $all_categories);
  $e->add_result(['sports','finance'], ['sports']);
  print $e->stats_table;

  $e = new Statistics::Contingency(categories => $all_categories);
  $e->add_result(['sports','finance'], ['politics']);
  print $e->stats_table;
}

{
  my $e = new Statistics::Contingency(categories => $all_categories);
  $e->set_entries(2, 3, 5, 19);
  ok $e->micro_precision, 2/(2+3), "micro precision\n";
  ok $e->micro_recall,    2/(2+5), "micro recall\n";
}
