#!/usr/bin/perl

open GRAMMAR, $ARGV[0] or die "Error opening grammar file $grammar_file: $!\n";
{
  local $/;
  $grammar = <GRAMMAR>;
}
close GRAMMAR;

eval($grammar);

print scalar(@fragments) . "\n";

sleep 10;
