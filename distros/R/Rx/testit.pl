#!/usr/bin/perl
require 5.00561;

use ExtUtils::testlib;
# use Devel::Peek;
use Data::Dumper;
use Rx;

@ARGV = ('b', '', 'aab') unless @ARGV;
prompt_for(\$r, 'Regex');
prompt_for(\$o, 'Options');
prompt_for(\$t, 'Target');

print qq{"$t" =~ /$r/$o\n};

Rx::test_it($r, $o, $t);


sub prompt_for {
  my ($ref, $p) = @_;
  unless (defined($$ref = shift @ARGV)) {
    print $p, "> ";
    $$ref = <STDIN>;
    chomp $$ref;
  }
}


