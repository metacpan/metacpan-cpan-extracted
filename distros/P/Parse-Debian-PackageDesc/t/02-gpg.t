use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;

BEGIN { use FindBin qw($Bin); use lib $Bin; };

# Check if there's a sane "gpg" available
my $gpg_version_unused = `gpg --version`;
my $ret = $CHILD_ERROR;
if ($ret == -1) {
    plan skip_all => "No working 'gpg' installation available";
}
else {
    plan tests => 8;
}

use_ok('Parse::Debian::PackageDesc');

my $unsigned_path = 't/files/ack_1.66-1_i386.changes';
my $unsigned = Parse::Debian::PackageDesc->new($unsigned_path,
                                               gpg_homedir => 't/gnupg');
is($unsigned->name, "ack");
is($unsigned->signature_id, undef,
   "Unsigned files should get an undefined signature id");
ok(!$unsigned->correct_signature,
   "Unsigned files shouldn't get a correct signature");


my $signed_path = 't/files/libwww-scraper-yahoo360-perl_0.03-0opera1_amd64.changes';
my $signed = Parse::Debian::PackageDesc->new($signed_path,
                                             gpg_homedir => 't/gnupg');
is($signed->signature_id, "0CBC2987",
   "The signature id should be correctly determined");
ok($signed->correct_signature,
   "The signature should be correct");


my $unknown_signed_path = 't/files/signed-ack_1.66-1_i386.changes';
my $unknown_signed = Parse::Debian::PackageDesc->new($unknown_signed_path,
                                                     gpg_homedir => 't/gnupg');
is($unknown_signed->signature_id, "8BC4E29A",
   "The signature id should be correctly determined even if unknown");
ok(!$unknown_signed->correct_signature,
   "An unknown signature should be recognised as such");


__END__

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
