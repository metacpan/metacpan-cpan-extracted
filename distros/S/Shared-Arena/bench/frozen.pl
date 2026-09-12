#!/usr/bin/perl
# What the Frozen tenant is worth against the alternative it replaces:
# a serialized structure in a map, rebuilt on every read.
#
#     perl -Mblib bench/frozen.pl

use strict;
use warnings;
use blib;
use Shared::Arena;
use Storable qw(freeze thaw);
use Time::HiRes qw(time);

my $N = shift || 200_000;

sub bench {
    my ($name, $code) = @_;
    $code->();
    my $t = time;
    $code->();
    printf "  %-34s %8.0f ns/op\n", $name, (time() - $t) / $N * 1e9;
}

for my $keys (10, 200, 2000) {
    my $data = { map { ("key$_" => { n => $_, label => "value $_" }) } 1 .. $keys };
    my $arena = Shared::Arena->create(size => 96 << 20);

    my $conf = $arena->frozen("c$keys", size => 1 << 20);
    $conf->publish($data);

    my $packed = freeze($data);
    my $map = $arena->map("m$keys", slots => 4, slot_size => 1 << 20);
    $map->store('blob', $packed);

    printf "\n%d keys (frozen block %d bytes, storable %d bytes)\n",
        $keys, do { my %s = $conf->stats; $s{bytes} }, length $packed;

    bench('storable: one field',
          sub { my $v; $v = thaw($map->fetch('blob'))->{key1}{n} for 1 .. $N });
    bench('frozen:   one field',
          sub { my $v; $v = $conf->view->get('key1.n') for 1 .. $N });
    bench('frozen:   one field, view held',
          sub { my $view = $conf->view;
                my $v; $v = $view->get('key1.n') for 1 .. $N });
    bench('frozen:   one field, no view',
          sub { my $v; $v = $conf->get('key1.n') for 1 .. $N });

}

print "\n";
