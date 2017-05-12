# perl syntax check for all library modules

use strict;
use warnings;
use Test::More;
use File::Find;

my @libs = qw(
    OSPF::LSDB
    OSPF::LSDB::Cisco
    OSPF::LSDB::View
    OSPF::LSDB::View6
    OSPF::LSDB::YAML
    OSPF::LSDB::gated
    OSPF::LSDB::ospfd
    OSPF::LSDB::ospf6d
);

plan tests => 2 * @libs;

foreach (@libs) {
    use_ok($_);
}

my %files = map { local $_ = $_; s,::,/,g; "lib/$_.pm" => 1 } @libs;
sub wanted {
    /\.pm$/ && -f or return;
    ok($files{$File::Find::name}, "$File::Find::name file")
	or diag("Module file $File::Find::name not in lib list");
}
find(\&wanted, "lib");
