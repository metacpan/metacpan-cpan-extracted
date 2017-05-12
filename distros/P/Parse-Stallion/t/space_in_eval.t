#!/usr/bin/perl
#Copyright 2007-8 Arthur S Goldstein
use Test::More tests => 4;
BEGIN { use_ok('Parse::Stallion') };
use Time::Local;
#use Data::Dumper;

my %rule;
$rule{start_rule} =
  A('white_space_word', 'end_of_string',
  E(sub {
    my $param = shift;
#use Data::Dumper;print STDERR "param in to start rule is ".Dumper($param)."\n";
    if ($param->{white_space_word} =~ /\s/) {
      return "found white space";
    }
    else {
      return "no white space";
    }
  })
);
$rule{white_space_word} =
  L(qr/\s+\w+\s+/
);
$rule{end_of_string} =
  L(qr/\z/
);
my ($result_1, $result_2);

my $after_parser = new Parse::Stallion(
  \%rule,
  {start_rule => 'start_rule',
});

$result_1 = $after_parser->parse_and_evaluate(' jj ');



my $during_parser = new Parse::Stallion(
  \%rule,
  {do_evaluation_in_parsing => 1,
  start_rule => 'start_rule',
});

#print STDERR "getting result 2\n";

$result_2 = $during_parser->parse_and_evaluate(' jj ');

#print STDERR "result 1 is $result_1 and r2 is $result_2\n";
is ($result_1, $result_2, "with spaces match");



my $ks_after_parser = new Parse::Stallion(
  \%rule,
  {keep_white_space => 0,
  start_rule => 'start_rule',
});

$result_1 = $ks_after_parser->parse_and_evaluate(' jj ');

my $ks_during_parser = new Parse::Stallion(
  \%rule,
  {do_evaluation_in_parsing => 1,
  keep_white_space => 0,
  start_rule => 'start_rule',
});

$result_2 = $ks_during_parser->parse_and_evaluate(' jj ');

is ($result_1, $result_2, "with forced keep white spaces match");


my $kws_after_parser = new Parse::Stallion(
  \%rule,
  {keep_white_space => 1,
  start_rule => 'start_rule',
});

$result_1 = $kws_after_parser->parse_and_evaluate(' jj ');

my $kws_during_parser = new Parse::Stallion(
  \%rule,
  {do_evaluation_in_parsing => 1,
  keep_white_space => 1,
  start_rule => 'start_rule',
});

$result_2 = $kws_during_parser->parse_and_evaluate(' jj ');

is ($result_1, $result_2, "with forced not to keep white spaces match");

