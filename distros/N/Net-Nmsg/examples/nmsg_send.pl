#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::Output;
use Net::Nmsg::Msg;

my $dest = '127.0.0.1/9430';

my %template = (
  srcip   => '127.0.0.1',
  srchost => 'localhost.localdomain',
  helo    => 'helo',
  from    => 'foo@bar.example.com',
  rcpt    => [qw(
    bar%d@baz.example.com
    baz%d@baz.example.com
  )],
);

my $count = 1;

my $o = Net::Nmsg::Output->open($dest);
my $m = Net::Nmsg::Msg::base::email->new;

for my $i (0 .. $count-1) {
  $m->set_type($template{type});
  $m->set_helo($template{helo});
  $m->set_srchost($template{srchost});
  $m->set_srcip($template{srcip});
  $m->set_from($template{from});
  for my $r (@{$template{rcpt}}) {
    $m->add_rcpt(sprintf($r, $i));
  }
  $o->write($m);
}
