use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use nmsgtest;

use Net::Nmsg::Util qw( :field );
use Net::Nmsg::Msg;

my $tc = 0;
BEGIN {
  for my $c (MSG_CLASS->modules) {
    $tc += $c->count;
    for my $f ($c->flags) {
      $tc += keys %$f;
    }
  }
}

use Test::More tests => $tc;

my %field_type = field_types();
my %field_flag = field_flags();

for my $c (MSG_CLASS->modules) {
  my $v = $c->vendor;
  my $t = $c->type;
  my @fields = $c->fields;
  my @types  = $c->types;
  my @flags  = $c->flags;
  for my $i (0 .. $#fields) {
    my($field, $type, $flags) = ($fields[$i], $types[$i], $flags[$i]);
    ok(defined $field_type{$type}, "known type for $v:$t $field");
    for my $f (keys %$flags) {
      ok(defined $field_flag{$f},sprintf("known flag for %s:%s %s 0x%02x",
                                         $v, $t, $field,$flags->{$f}));
    }
  }
}
