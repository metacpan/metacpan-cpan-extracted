#!/usr/bin/perl

use strict;
my %test_arg;
my %TESTS;
BEGIN {
%TESTS = (
  '001 basic test' => {
    prompt => 'Path: ',
    'IN' => "li\t\t\t.\t\r",
    'OUT' => "Path: lib/Term/\aCompletion.pm\r\n",
    'RESULT' => "lib/Term/Completion.pm"
  },
  '002 wipe until separator' => {
    prompt => 'Path: ',
    'IN' => "t\t\t\cw\r",
    'OUT' => "Path: t/\a0\ch \ch\ch \ch\r\n",
    'RESULT' => "t"
  },
);

  %test_arg = ( tests => 1 + 3 * keys(%TESTS) );
  eval { require IO::String; };
  if($@) {
    %test_arg = (skip_all => 'IO::String is required for testing Term::Completion');
  }
}
use Test::More %test_arg;

use_ok('Term::Completion::Path');

foreach my $test (sort keys %TESTS) {
  my %arg = %{$TESTS{$test}};
  my $in = delete($arg{IN}) . "END\n";
  my $in_fh = IO::String->new($in);
  my $out = '';
  my $out_fh = IO::String->new($out);
  my $expected_out = delete($arg{OUT});
  my $expected_result = delete($arg{RESULT});

  my $result = Term::Completion::Path->new(
        in => $in_fh,
        out => $out_fh,
	columns => 80, rows => 24,
	sep => '/',
        %arg
  )->complete();

  is($result, $expected_result, "$test: complete() returned correct value");
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
