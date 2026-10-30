use strict;
use warnings;

use Config;
use File::Spec;
use Test::More;
use Net::IDN::Punycode ();
use Net::IDN::Punycode::PP ();

BEGIN {
  my $object = File::Spec->catfile(qw( blib arch auto Net IDN Punycode ),
    "Punycode.$Config{dlext}");
  plan skip_all => "no XS object at $object" unless -e $object;
  plan tests => 1 + 1;
}

use Test::NoWarnings;

ok(
  \&Net::IDN::Punycode::decode_punycode !=
    \&Net::IDN::Punycode::PP::decode_punycode,
  'the XS loaded rather than the pure-Perl fallback'
) or do {
  eval { require XSLoader; XSLoader::load('Net::IDN::Punycode') };
  diag($@) if $@;
};
