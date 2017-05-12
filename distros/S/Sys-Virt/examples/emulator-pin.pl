#!/usr/bin/perl

use Sys::Virt;


my $uri = shift @ARGV;

my $c = Sys::Virt->new(uri => $uri);


my $d = $c->get_domain_by_name("vm1");

unless ($d->is_active()) {
    $d->create;
}



my $mask = $d->get_emulator_pin_info;

@bits = split(//, unpack("b*", $mask));
print join(":", @bits), "\n";

if ($bits[0] == '1' && $bits[1] == '1') {
    @bits[0] = 0;
    my $newmask = '';
    for(my $i = 0 ; $i <= $#bits ; $i++) {
	vec($newmask, $i, 1) = $bits[$i];
    }
    @bits = split(//, unpack("b*", $newmask));
    print join(":", @bits), "\n";
    $d->pin_emulator($newmask);

    $newermask = $d->get_emulator_pin_info;
    @bits = split(//, unpack("b*", $newermask));
    print join(":", @bits), "\n";

    $d->pin_emulator($mask);

    $newermask = $d->get_emulator_pin_info;
    @bits = split(//, unpack("b*", $newermask));
    print join(":", @bits), "\n";

}
