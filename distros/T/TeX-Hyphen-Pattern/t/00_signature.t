# $Id: 00_signature.t 102 2009-07-30 14:48:55Z roland $
# $Revision: 102 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/rhonda/trunk/TeX-Hyphen-Pattern/t/00_signature.t $
# $Date: 2009-07-30 16:48:55 +0200 (Thu, 30 Jul 2009) $

use Test::More;

if ( !$ENV{TEST_SIGNATURE} ) {
    plan skip_all =>
      "Set the environment variable TEST_SIGNATURE to enable this test.";
}
elsif ( !eval { require Module::Signature; 1 } ) {
    plan skip_all => "Next time around, consider installing Module::Signature, "
      . "so you can verify the integrity of this distribution.";
}
elsif ( !-e 'SIGNATURE' ) {
    plan skip_all => "SIGNATURE not found";
}
elsif ( -s 'SIGNATURE' == 0 ) {
    plan skip_all => "SIGNATURE file empty";
}
elsif ( !eval { require Socket; Socket::inet_aton('pgp.mit.edu') } ) {
    plan skip_all => "Cannot connect to the keyserver to check module "
      . "signature";
}
else {
    plan tests => 1 + 1;
}

my $ret = Module::Signature::verify();

SKIP: {
    skip "Module::Signature cannot verify", 1
      if $ret eq Module::Signature::CANNOT_VERIFY();
    cmp_ok $ret, '==', Module::Signature::SIGNATURE_OK(), "Valid signature";
}
