use Test::More;
use strict; use warnings FATAL => 'all';

use POEx::ZMQ::FFI;

# find_soname
my $soname = POEx::ZMQ::FFI->find_soname;
ok $soname, 'find_soname';
note "libzmq found at $soname";

# get_version
my $vers = POEx::ZMQ::FFI->get_version;
ok $vers->major >= 3, 'version->major ok';
ok $vers->minor >= 0, 'version->minor ok';
ok $vers->patch >= 0, 'version->patch ok';
cmp_ok $vers->string, 'eq',
  join('.', $vers->major, $vers->minor, $vers->patch),
  'version->string ok';

note "libzmq version is ".$vers->string;

my $vers_so_str = POEx::ZMQ::FFI->get_version($soname)->string;
cmp_ok $vers_so_str, 'eq', $vers->string,
  'passing soname to get_version seems ok';

eval {; POEx::ZMQ::FFI->get_version('hopefullynosuchlibexistsever') };
like $@, qr/(?:shared|not.found)/i, 'passing bad soname to get_version dies';

# zpack
# FIXME

# zunpack
# FIXME

done_testing
