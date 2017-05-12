#!/usr/bin/perl
#Copyright 2010 Arthur S Goldstein
use Test::More tests => 50;
BEGIN { use_ok('Parse::Stallion') };

my %numbers_added = (
  start_rule => O(qr/\d+/,A(qr/\d+/,qr/\+/,'start_rule',
   E(sub { 
#print STDERR "params are".join("..",@_)."\n";
#use Data::Dumper;print STDERR Dumper(\@_)."\n";
     return $_[0]->{''}->[0] + $_[0]->{start_rule}; })))
);

our $step_count;
my $numbers_added_parser = new Parse::Stallion(\%numbers_added,
);

my $added;

$added = $numbers_added_parser->parse_and_evaluate('5+4',
 {match_maximum => 1 , match_length => 0});

is ($added, 9, 'Add test');

$added = $numbers_added_parser->parse_and_evaluate('5+4',
 {match_maximum => 0, match_length => 0 });

is ($added, 5, 'No match maximum');

$added = $numbers_added_parser->parse_and_evaluate('5+4x',
 {match_maximum => 1, match_length => 0 });

is ($added, 9, 'Match Maximum Add test');

my %ll_grammar = (
  start_rule => O(qr/ll/,qr/lll/,qr/l/,
   E(sub {
#  use Data::Dumper;print STDERR Dumper(\@_)." to sr\n";
    return 'X'.$_[0]->{''}.'Y'; }))
);

my $ll_parser = new Parse::Stallion(\%ll_grammar,);

my $ll_out;

$ll_out = $ll_parser->parse_and_evaluate('llll',
 {match_length => 0});

is ($ll_out, 'XllY', 'LL_L_LLL grammar');

$ll_out = $ll_parser->parse_and_evaluate('llll',
 {match_maximum => 1, match_length => 0});

is ($ll_out, 'XlllY', 'L_LLL_LL match maximum grammar');

my $f = 'llll';

$ll_parser->parse_and_evaluate($f,
 {match_maximum => 1, substitute => 1, match_length => 0});

is ($f, 'XlllYl', 'Substitute ll');

my $h = 'kjwerllllerewr';

$ll_parser->parse_and_evaluate($h,
 {match_maximum => 1, substitute => 1, match_start => 0
  , match_length => 0});

is ($h, 'kjwerXlllYlerewr', 'Begin later substitute ll');

my $jh = 'kjwerllllerllllewllllr';

$ll_parser->parse_and_evaluate($jh,
 {match_maximum => 1, substitute => 1, match_start => 0,
  match_length => 0,
  find_all => 1});

is ($jh, 'kjwerXlllYXlYerXlllYXlYewXlllYXlYr', 'Multiple max contiguous substitutes');

$jh = 'kjwerllllerllllewllllr';
$ll_parser->parse_and_evaluate($jh,
 {match_maximum => 0, substitute => 1, match_start => 0,
  match_length => 0,
  find_all => 1});


is ($jh, 'kjwerXllYXllYerXllYXllYewXllYXllYr', 'Multiple non contiguous substitutes');

$jh = 'kjwerllllerllllewllllr';
$ll_parser->parse_and_evaluate($jh,
 {match_minimum => 1, substitute => 1, match_start => 0,
  match_length => 0,
  find_all => 1});


is ($jh, 'kjwerXlYXlYXlYXlYerXlYXlYXlYXlYewXlYXlYXlYXlYr', 'Multiple min non contiguous substitutes');

$h = 'kjwerllllerewr';
is (pos $h, undef, 'before global test');
$ll_parser->parse_and_evaluate($h,
 {match_maximum => 1, substitute => 1, match_start => 0,
  match_length => 0,
  global => 1});
is (pos $h, 10, 'after global test');

$h = 'kjwerllllerewr';
$ll_parser->parse_and_evaluate($h,
 {match_maximum => 1, match_start => 0,
  match_length => 0,
  global => 1});
is (pos $h, 8, 'after second global test part one');

$ll_parser->parse_and_evaluate($h,
 {match_maximum => 1, match_start => 0,
  match_length => 0,
  global => 1});
is (pos $h, 9, 'after global test part two');

$ll_parser->parse_and_evaluate($h,
 {match_maximum => 1, match_start => 0,
  match_length => 0,
  global => 1});
is (pos $h, undef, 'after global test part three');

is($ll_parser->search($h,
{parse_trace_routine=>\&the_ptr, global => 1,
 match_length => 0},
), 1, 'search match');

is($step_count, 22, 'step count');
$ll_parser->search_and_substitute($h,{parse_trace_routine=>\&the_ptr,
 match_length => 0});
is($step_count, 2, 'step count 2');

is ($h, 'kjwerllXllYerewr', 'sub after a search');

my $hh = 'sdkfjoiuwer';

sub the_ptr {
  $step_count = ${$_[0]->{__steps_ref}};
  #print STDERR "sc is $step_count\n";
  #print STDERR "Moving Forward: ".${$_[0]->{__moving_forward_ref}}." ";
  #print STDERR "Position: ".${$_[0]->{__current_position_ref}}." ";
  #print STDERR "CN name: ".${$_[0]->{__current_node_name_ref}}."\n";
}


is($ll_parser->search($hh), '', 'search not match');

$ll_parser->search_and_substitute($h,{parse_trace_routine=>\&the_ptr});

$h = 'kjwerllllerewr';

$ll_parser->search_and_substitute($h,{parse_trace_routine=>\&the_ptr});

is ($h, 'kjwerXllYllerewr', 'search and sub after reset');

my %match_empty_grammar = (
  start_rule => O(qr//, qr/ll/,qr/lll/,qr/l/,
   E(sub {
#  use Data::Dumper;print STDERR Dumper(\@_)." to sr\n";
    return 'X'.$_[0]->{''}.'Y'; }))
);

my $match_empty_parser = new Parse::Stallion(\%match_empty_grammar,
 {match_length => 0}
);

$h = 'fj';

my @fa = $match_empty_parser->parse_and_evaluate($h,
 {find_all => 1, match_maximum => 1, substitute => 0,
  match_start => 0,
  global => 1}
);
is_deeply(\@fa, ['XY','XY','XY'], 'find all match on empty');



#print STDERR "mepos h is \n";
#print STDERR pos $h;
#print STDERR "\n";

#$h =~ /x*/g;
#print STDERR "xpos h is \n";
#print STDERR pos $h;
#print STDERR "\n";
#while ($h =~ /x*/g) {
  #$i++;
  #if ($i==10) {exit};
  #print STDERR "i is $i\n";
#}

  my $result;

  my $plus_times_parser = new Parse::Stallion({
    start => A('term',M(A(qr/\+/,'term')),
         E(sub {my $i = 0; $i += $_ for @{$_[0]->{term}}; return $i;})),
    term => A('expression',M(A(qr/\*/,'expression')),
         E(sub {my $i = 1; $i *= $_ for @{$_[0]->{expression}}; return $i;})),
    expression => O(A(qr/\(/,'start',qr/\)/, E(sub {return $_[0]->{start}})),
     L(qr/\d+/,E(sub {return $_[0]}))),
   },
    {start_rule => 'start'});

  $result = $plus_times_parser->parse_and_evaluate('(3+5*2)*2+4*3');
  is ($result, 38, 'ptp');
  #$result should contain 38

  $result = $plus_times_parser->parse_and_evaluate('example:(3+5*2)*2+4*3');
  #$result should be undef
  is ($result, undef, 'ptp example:');

  $result = $plus_times_parser->parse_and_evaluate('example:(3+5*2)*2+4*3',
   {match_start => 0});
  #$result should contain 38
  is ($result, 38, 'ptp example: with not at start');

  $result = $plus_times_parser->parse_and_evaluate('(3+5*2)*2+4*3',
   {match_length => 0});
  #$result should contain 13
  is ($result, 38, 'ptp example: with not match whole');

  $result = $plus_times_parser->parse_and_evaluate('(3+5*2)*2+4*3ttt',
   {match_length => 0});
  #$result should contain 38
  is ($result, 38, 'ptp example: with not match whole string');

  $result = $plus_times_parser->parse_and_evaluate('(3+5*2)*2+4*3',
   {match_minimum => 1});
  #$result should contain 13
  is ($result, 13, 'ptp example: with not match whole string');

  my $string_with_numbers = '7*8 is greater than 4+3+4 greater than 2*5';
  $plus_times_parser->search_and_substitute($string_with_numbers);
  #$string_with_numbers should be '56 is greater than 4+3+4 greater than 2*5';
  is ($string_with_numbers, '56 is greater than 4+3+4 greater than 2*5',
   'no global math search and sub');
  
  $string_with_numbers = '7*8 is greater than 4+3+4 greater than 2*5';
  $plus_times_parser->search_and_substitute($string_with_numbers,
   {global=>1});
  #$string_with_numbers should be '56 is greater than 11 greater than 10';
  is ($string_with_numbers, '56 is greater than 11 greater than 10',
   'global math search and sub');

  my $choice_parser = new Parse::Stallion({
    start => O(qr'bc', qr'abcdef', qr'abcd', qr'abcde', qr'abc', qr'de')});

  $result = $choice_parser->parse_and_evaluate('abcd');
  #result should be "abcd"
  is ($result, 'abcd', 'first choice');

  $result = $choice_parser->parse_and_evaluate('abcdex');
  is ($result, undef, 'second choice');
  #result should be undef

  $result = $choice_parser->parse_and_evaluate('abcdex', {match_minimum => 1});
  is ($result, 'abc', 'third choice');
  #result should be "abc"

  $result = $choice_parser->parse_and_evaluate('abcdex', {match_maximum => 1});
  is ($result, 'abcde', 'fourth choice');
  #result should be "abcde"

  $result = $choice_parser->parse_and_evaluate('abcdex', {match_minimum => 1,
   match_start => 0});
  is ($result, 'abc', 'fifth choice');
  #result should be "abc"

  my @result = $choice_parser->parse_and_evaluate('abcdex', {match_minimum => 1,
    global => 1});
  is_deeply (\@result, ['abc', 'de'], 'sixth choice');
  #@result should contain ("abc", "de")

  $result = $choice_parser->parse_and_evaluate('tabcdex', {match_minimum => 1});
  is ($result, undef, 'seventh choice');
  #result should be undef

  $result = $choice_parser->parse_and_evaluate('tabcdex', {match_maximum => 1});
  is ($result, undef, 'eighth choice');
  #result should be undef

  $result = $choice_parser->parse_and_evaluate('tabcdex', {match_minimum => 1,
    match_start => 0});
  is ($result, "abc", 'ninth choice');
  #result should be "abc"

  $result = $choice_parser->parse_and_evaluate('tabcdex', {match_maximum => 1,
   match_start => 0});
  is ($result, "abcde", 'tenth choice');
  #result should be "abcde"

  my $p_and_e_string = 'abcdex';
  my $result_1 = $choice_parser->parse_and_evaluate($p_and_e_string,
   {match_minimum => 1, global => 1});
  my $result_2 = $choice_parser->parse_and_evaluate($p_and_e_string,
   {match_minimum => 1, global => 1});
  #$result_1 should contain "abc", $result_2 should contain "de"
  is ($result_1, 'abc', 'result one global');
  is ($result_2, 'de', 'result two global');

  my $search_parser = new Parse::Stallion(
    {start => A(qr/b+/, qr/c+/, E(sub{return 'x'}))}
  );

  my $search_result;
  $search_result = $search_parser->search('abd');
  is ($search_result, '', 'search on search result');
  #search_result is false (0)

  my $pinfo = {};
  $search_parser->search('abd',{parse_info=>$pinfo});
  is_deeply ($pinfo->{tree}, {}, 'tree after false search');
  #use Data::Dumper; print STDERR "ftree is ".Dumper($pinfo->{tree})."\n";
  #use Data::Dumper; print STDERR "pinfo is ".Dumper($pinfo)."\n";

  my $npinfo = {};
  my $search_resultj = $search_parser->parse_and_evaluate('',
   {parse_info=>$npinfo});
  is_deeply ($npinfo->{tree}, {}, 'tree after empty search');
  #use Data::Dumper; print STDERR "nftree is ".Dumper($npinfo->{tree})."\n";
  #use Data::Dumper; print STDERR "npinfo is ".Dumper($npinfo)."\n";



  $search_result = $search_parser->search('abcd');
  #search_result is true (1)
  is ($search_result, 1, 'search on valid search result');
  my $search_string = 'abcd';
  $search_result = $search_parser->search_and_substitute($search_string);
  #$search_result is true (1), $search_string contains 'axd'
  is ($search_result, 1, 'search on substitute search result');
  is ($search_string, 'axd', 'substitute search result');
  my $s_search_string = 'abcweurbclksdfwebcoiwerubcjwoeriubcd';
  $search_result = $search_parser->search_and_substitute($s_search_string,
   {global=>1});
  is ($search_result, 5, 's_search on substitute search result');


print "\nAll done\n";
