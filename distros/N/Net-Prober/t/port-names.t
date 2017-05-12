=pod

=head1 NAME

t/port-names.t - Net::Prober test suite

=head1 DESCRIPTION

Check that port names are resolved to numbers

=cut

use strict;
use warnings;

use Test::More tests => 6;
use Net::Prober;

is Net::Prober::port_name_to_num(undef)  => undef;
is Net::Prober::port_name_to_num(23)     => 23;
is Net::Prober::port_name_to_num("ftp")  => 21;
is Net::Prober::port_name_to_num("echo") => 7;

SKIP: {
    skip("'ssh' port can be undefined on Windows systems", 1)
        if "MSWin32" eq $^O;
    is Net::Prober::port_name_to_num("ssh") => 22;
}

SKIP: {
    skip("'http' port name apparently not defined on Solaris", 1)
        if "solaris" eq $^O;
    is Net::Prober::port_name_to_num("http") => 80;
}
