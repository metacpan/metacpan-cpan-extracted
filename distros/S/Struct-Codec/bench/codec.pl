#!/usr/bin/perl
# THE GATE. Struct::Codec against Storable, and against the two JSON codecs
# for scale, on the three fixtures plan_struct_codec/06 names.
#
# Timed by Benchmark, which runs each arm for a fixed amount of CPU time and
# subtracts the cost of its own empty loop, so the arms compare on work done
# rather than on an iteration count somebody guessed would be enough.
#
#     perl -Mblib bench/codec.pl [count]
#
# `count` is Benchmark's own: negative is CPU seconds per arm, positive an
# iteration count. Default -2.

use strict;
use warnings;
use blib;
use Benchmark qw(timethese cmpthese);
use Storable qw(freeze thaw);
use Struct::Codec ();

my $COUNT = shift // -2;

my $jx = eval { require JSON::XS; JSON::XS->new->utf8 };
my $fj = eval { require File::Raw::JSON; 1 };

my %fixtures = (
    small => { user_id => 12345, name => 'Ada Lovelace', roles => ['admin', 'editor'],
               exp => 1757600000, active => 1 },
    big   => { map { ("key$_" => { id => $_, name => "item $_", tags => [qw(a b c)],
                                   score => $_ * 1.5 }) } 1 .. 50 },
    objects => [ map { bless { id => $_, name => "obj $_", tags => ['x'], weight => $_ / 7 }, 'Bench::Obj' } 1 .. 100 ],
);

# One comparison: the rate table cmpthese prints, then ns per call, which is
# the unit the gate's numbers are quoted in.
sub compare {
    my ($title, $arms) = @_;
    print "\n-- $title\n";
    my $r = timethese($COUNT, $arms, 'none');
    cmpthese($r);
    for my $label (sort { $r->{$a}->cpu_p / $r->{$a}->iters
                          <=> $r->{$b}->cpu_p / $r->{$b}->iters } keys %$r) {
        printf "  %-24s %8.0f ns\n", $label,
            $r->{$label}->cpu_p / $r->{$label}->iters * 1e9;
    }
}

for my $name (qw(small big objects)) {
    my $d  = $fixtures{$name};
    my $sc = Struct::Codec::encode($d);
    my $st = freeze($d);
    # the JSON arms cannot carry a blessed value at all
    my $json_ok = $jx && $name ne 'objects';
    my $js = $json_ok ? $jx->encode($d) : '';

    my %arms = (
        'Struct::Codec' => [ sub { my $x = Struct::Codec::encode($d) },
                             sub { my $x = Struct::Codec::decode($sc) }, length $sc ],
        'Storable'      => [ sub { my $x = freeze($d) },
                             sub { my $x = thaw($st) }, length $st ],
    );
    $arms{'JSON::XS (lossy)'} = [ sub { my $x = $jx->encode($d) },
                                  sub { my $x = $jx->decode($js) }, length $js ]
        if $json_ok;
    $arms{'File::Raw::JSON (lossy)'} = [
        sub { my $x = File::Raw::JSON::file_json_encode($d) },
        sub { my $x = File::Raw::JSON::file_json_decode($js) }, length $js ]
        if $json_ok && $fj;

    print "\n==== $name\n";
    compare("$name: encode", { map { ($_ => $arms{$_}[0]) } keys %arms });
    compare("$name: decode", { map { ($_ => $arms{$_}[1]) } keys %arms });
    compare("$name: round trip", { map {
        my ($enc, $dec) = @{ $arms{$_} }[0, 1];
        ($_ => sub { $enc->(); $dec->() });
    } keys %arms });

    print "\n-- $name: encoded size\n";
    printf "  %-24s %8d bytes\n", $_, $arms{$_}[2]
        for sort { $arms{$a}[2] <=> $arms{$b}[2] } keys %arms;
}
