#!/usr/bin/perl

use strict;
use File::Spec;

my %test_arg;
BEGIN {
  %test_arg = ( tests => 4 );
  unless(-t STDIN && -t STDOUT) {
    %test_arg = (skip_all => 'This test works only in interactive mode');
  }
}
use Test::More %test_arg;

use_ok('Term::Completion' => qw(Complete));

my $result = Complete("Choose 'Apple' by pressing A [TAB]: ",
                      qw(Apple Banana Cherry));

is($result, "Apple", "Simple completion: Apple");

$result = Complete("Choose 'Banana' by pressing B [TAB]: ",
                      [ qw(Apple Banana Cherry) ]);

is($result, "Banana", "Simple completion: Banana");

SKIP: {
  my $devnull = File::Spec->devnull();
  skip "no null device available",1 unless($devnull);
  open(NULL, "<$devnull") ||
    skip "cannot open null device", 1;
  my $tc = Term::Completion->new(
    in => \*NULL,
    prompt => "Input: ",
    validate => 'nonempty',
    choices => [ qw(one two three) ] );
  my $result = $tc->complete();
  is($result, '', "return empty if input is null");
}

exit 0;

