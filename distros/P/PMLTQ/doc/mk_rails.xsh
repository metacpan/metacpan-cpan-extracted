#!/usr/bin/env xsh2
# -*- mode: cperl; coding: utf-8; -*-

for my $f in ($ARGV) {
  open $f;
  for (//mediaobject[textobject[@role='syntax_diagram']]) {
    my $id = string(@id);
    echo $id;
    echo string(textobject) | ./mk_rail.sh ${id};
  }
}
