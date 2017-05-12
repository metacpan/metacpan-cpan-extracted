#!/usr/bin/perl

use strict;
my %test_arg;
my %TESTS;
BEGIN {
%TESTS = (
  '001 basic test' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    'IN' => "A\tB\t\r",
    'OUT' => "Fruit: Apple Banana \r\n",
    'RESULT' => [ qw(Apple Banana) ]
  },
  '002 wipe till delimiter' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    'IN' => "\cwC\tRaspberry\cw D\t\r",
    'OUT' => "Fruit: Cherry Raspberry\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch Duriam \r\n",
    'RESULT' => [ qw(Cherry Duriam) ]
  },
  '003 multi validation' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    validate => 'fromchoices',
    'IN' => "A\tB\tEgg\r\cw\r",
    'OUT' => "Fruit: Apple Banana Egg\r\nERROR: You must choose one item from the list!\r\nFruit: Apple Banana Egg\ch \ch\ch \ch\ch \ch\ch \ch\r\n",
    'RESULT' => [ qw(Apple Banana) ]
  },
  '004 show choices' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    'IN' => "A\tB\cd\t\r",
    'OUT' => "Fruit: Apple B\r\nBanana \r\nFruit: Apple Banana \r\n",
    'RESULT' => [ qw(Apple Banana) ]
  },
);

  %test_arg = ( tests => 1 + 3 * keys(%TESTS) );
  eval { require IO::String; };
  if($@) {
    %test_arg = (skip_all => 'IO::String is required for testing Term::Completion');
  }
}
use Test::More %test_arg;

use_ok('Term::Completion::Multi');

foreach my $test (sort keys %TESTS) {
  my %arg = %{$TESTS{$test}};
  my $in = delete($arg{IN}) . "END\n";
  my $in_fh = IO::String->new($in);
  my $out = '';
  my $out_fh = IO::String->new($out);
  my $expected_out = delete($arg{OUT});
  my $expected_result = delete($arg{RESULT});

  my @result = Term::Completion::Multi->new(
        in => $in_fh,
        out => $out_fh,
	columns => 80,
	rows => 24,
        %arg
  )->complete();

  is_deeply(\@result, $expected_result, "$test: complete() returned correct list");
  is($out, $expected_out, "$test: correct data sent to terminal");
  $out =~ s#\t#\\t#g;
  $out =~ s#\r#\\r#g;
  $out =~ s#\n#\\n#g;
  $out =~ s#\a#\\a#g;
  $out =~ s#\ch#\\ch#g;
  $out =~ s#([\x00-\x1f])#sprintf("%%%02x",ord($1))#ge;
  #diag("out = '$out'\n");
  my $in_rest = <$in_fh>;
  is($in_rest, "END\n", "$test: input stream correctly used up");
} # loop tests

exit 0;
