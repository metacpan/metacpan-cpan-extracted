#!/usr/bin/perl
use Test::More tests => 2;

use Term::ExtendedColor::TTY qw(set_tty_color);
use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Deparse   = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys  = 1;


my $map = {
  0 => 'ffff00',
};

my $result = set_tty_color($map);

is(ref($result), 'HASH', 'Hashref returned');
chomp(my $esc = Dumper($result->{0}));
is($esc, '"\e]P0ffff00"', 'Color value returned');
