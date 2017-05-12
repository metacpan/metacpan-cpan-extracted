# -*- perl -*-
#
# test the Net::NIS interface when called as scalars or arrays
#
use Test;

my $loaded = 0;

use strict;

BEGIN {
  plan tests => 6;
}

END   { $loaded or print "not ok 1\n" }

use Net::NIS;

$loaded = 1;

my ($status, $value_array, $value_scalar);

eval '($status, $value_array) = Net::NIS::yp_get_default_domain()';
ok $@,      '',       'eval yp_get_default_domain [array]';
ok $status, 0+$yperr, 'status of yp_get_default_domain [array]';

eval '$value_scalar = Net::NIS::yp_get_default_domain()';
ok $@, '',     'eval yp_get_default_domain [scalar]';

ok $value_array, $value_scalar,
    'yp_get_default_domain [array,scalar] mismatch';

my @ret;
eval '@ret = Net::NIS::yp_get_default_domain()';
ok scalar @ret, 2, 'scalar return of yp_get_default_domain[array]';

eval '@ret = scalar Net::NIS::yp_get_default_domain()';
ok scalar @ret, 1, 'scalar return of yp_get_default_domain[array]';
