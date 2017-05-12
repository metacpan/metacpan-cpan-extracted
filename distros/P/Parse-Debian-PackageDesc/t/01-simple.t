use strict;
use warnings;

use Test::More tests => 20;

use Encode;
use utf8;

BEGIN { use FindBin qw($Bin); use lib $Bin; };
BEGIN { use_ok( 'Parse::Debian::PackageDesc' ) };

my $broken_package = undef;
eval {
    local $SIG{__WARN__} = sub { };
    $broken_package = Parse::Debian::PackageDesc->new();
};
ok(!defined $broken_package, 'Missing package path');


$broken_package = undef;
eval { $broken_package = Parse::Debian::PackageDesc->new("random_name.changes"); };
ok(!defined $broken_package, 'Invalid package path');


my $package = Parse::Debian::PackageDesc->new('t/files/ack_1.66-1_i386.changes');
isa_ok($package, 'Parse::Debian::PackageDesc');

is($package->path, "t/files/ack_1.66-1_i386.changes");
is($package->name, "ack");
is($package->source, "ack");
is($package->version, "1.66-1");
is($package->upstream_version, "1.66");
is($package->debian_revision, "1");
is($package->distribution, "unstable");
is_deeply([$package->architecture], [ qw(source i386) ]);
is($package->urgency, "low");
is($package->maintainer, 'Esteban Manchado Velázquez <estebanm@estebanm-desktop>');
ok(Encode::is_utf8($package->maintainer),
   "The maintainer name should be correctly decoded");
is($package->date, "Tue, 18 Sep 2007 17:07:42 +0200");
is($package->changes, <<EOF);
 ack (1.66-1) unstable; urgency=low
 .
   * Initial Release.
EOF
is_deeply([ $package->files ], [ qw(ack_1.66-1.dsc ack_1.66.orig.tar.gz ack_1.66-1.diff.gz ack_1.66-1_i386.deb) ]);
is_deeply([ $package->binary_package_files ], [ qw(ack_1.66-1_i386.deb) ]);

my $binnmu_package = Parse::Debian::PackageDesc->new('t/files/libparse-debian-packagedesc-perl_0.12-1+b3_i386.changes');
is($binnmu_package->source, "libparse-debian-packagedesc-perl");

__END__

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
