#!/usr/bin/perl

use Proc::ProcessTable;

my $ref = Proc::ProcessTable->new;

foreach my $proc (@{$ref->table}) {
  if(@ARGV) {
    next unless grep {$_ == $proc->{pid}} @ARGV;
  }

  print "--------------------------------\n";
  foreach my $field ($ref->fields){
    print $field, ":  ", $proc->{$field}, "\n";
  }
}
