# perl syntax check for pod files

use strict;
use warnings;
use Test::More;
use Pod::Checker;
use File::Find;

my @pods;
push @pods, map { "doc/$_.pod" } qw(
    ciscoospf2yaml
    ospf2dot
    ospfd2yaml
    gated2yaml
    ospfconvert
    ospfview
    ospfview.cgi
);
push @pods, map { local $_ = $_; s,::,/,g; "lib/$_.pm" } qw(
    OSPF::LSDB
    OSPF::LSDB::Cisco
    OSPF::LSDB::View
    OSPF::LSDB::View6
    OSPF::LSDB::YAML
    OSPF::LSDB::gated
    OSPF::LSDB::ospfd
    OSPF::LSDB::ospf6d
);

plan tests => 3 * @pods;

foreach (@pods) {
    my $checker = Pod::Checker->new(-warnings => 1);
    $checker->parse_from_file($_, \*STDERR);
    my $err = $checker->num_errors();
    is($err, 0, "$_ error") or diag("Found $err POD errors in $_");
    my $warn = $checker->num_warnings();
    is($warn, 0, "$_ warning") or diag("Found $warn POD warnings in $_");
}

my %files = map { $_ => 1 } @pods;
sub wanted {
    /\.(pod|pm)$/ && -f or return;
    ok($files{$File::Find::name}, "$File::Find::name file")
	or diag("Pod file $File::Find::name not in doc or lib list");
}
find(\&wanted, "doc", "lib");
