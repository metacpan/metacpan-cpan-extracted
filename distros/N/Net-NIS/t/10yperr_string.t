# -*- perl -*-
#
# verify the error string names returned by yperr_string()
#
# NOTE: This uses an unpublished interface to Net::NIS
#
use Test;

my $loaded = 0;

use strict;
use vars qw(@msgs);

# Make sure we get English error messages, no matter the current locale
use POSIX qw(locale_h);
setlocale(LC_ALL, 'C');

BEGIN {
  # These regular expressions have been tested under:
  #
  #       Solaris (2.5.1, 2.6, 8) (both SPARC and x86)
  #       Linux   (RH 5.0, 7.0, Debian Woody) (yp-tools 2.4)
  #       FreeBSD 4.2
  #
  # If you encounter a system on which they don't work, please let
  # me know <esm@pobox.com>, and include the platform name and full
  # output of 'make test TEST_VERBOSE=1'
  @msgs =
    (
     '',
     '\barg.* bad',
     'RPC failure',
     'Can\'t bind to( a)? server .* domain',
     'No such map in server\'s domain',
     'No such key in map',
     '(Internal )?(YP|NIS) .*error',
     'Local resource allocation failure',
     'No more records in map database',
    );
  plan tests => (2 * scalar @msgs) + 2;
}

END   { $loaded or print "not ok 1\n" }

use Net::NIS;

$loaded = 1;

for (my $i=0; $i < @msgs; $i++) {
  eval '$yperr = $i';
  ok $@, "", "Setting \$yperr = $i";
  ok "$yperr", "/(?i)$msgs[$i]/", "yperr_string ($i)";
}

# Now try for "out of range"
foreach my $badval (-1, scalar @Net::NIS::YPERRS) {
  eval '$yperr = $badval';
  ok $@, '/^Value out of range at \(eval/', "Setting \$yperr = $badval";
}
