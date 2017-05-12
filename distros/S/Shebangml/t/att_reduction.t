#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use Shebangml::FromXML;

sub dequote {
  my @lines = @_;
  my @out;
  foreach my $l (@lines) {
    $l =~ s/^\s*//;
    next if($l =~ m/^#/);
    my ($i, $o) = split(/\s*\|\s*/, $l);
    push(@out, [
      [map({($_, 'the_' . $_)} split(/ /, $i))],
      [split(/ /, $o)],
    ])
  }
  return(@out);
}
my @exp = dequote(split(/\n/, <<'IN'));
  id | =the_id
  name | :the_name
  class | @the_class
  junk id | =the_id junk="the_junk"
  id junk | =the_id junk="the_junk"
  junk name | :the_name junk="the_junk"
  name junk | :the_name junk="the_junk"
  id junk name junk2 | =the_id :the_name junk="the_junk" junk2="the_junk2"
  id junk2 name junk | =the_id :the_name junk2="the_junk2" junk="the_junk"
  id class name | @the_class =the_id :the_name
  junk name class id | @the_class =the_id :the_name junk="the_junk"
IN

for my $r (0..$#exp) {
  my $row = $exp[$r];
  my @got = Shebangml::FromXML->_reduce_atts(@{$row->[0]});
  is_deeply(\@got, $row->[1], "row $r");
}

{
  my @got = Shebangml::FromXML->_reduce_atts(id => "oh no");
  is_deeply(\@got, ['id="oh no"']);
}

# vim:ts=2:sw=2:et:sta
