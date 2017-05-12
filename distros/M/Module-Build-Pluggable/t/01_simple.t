use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use lib File::Spec->rel2abs('t/lib/');
use File::Path;
use t::Util;

BEGIN {
rmtree 't/tmp/';
mkpath 't/tmp/';

chdir 't/tmp/';

spew('MANIFEST', '');
}

use Module::Build::Pluggable (
    'T1',
);

my $builder = Module::Build::Pluggable->new(
    dist_name => 'Eg',
    dist_version => 0.01,
    dist_abstract => 'test',
    dynamic_config => 0,
    module_name => 'Eg',
    requires => {},
    provides => {},
    author => 1,
    dist_author => 'test',
);
$builder->create_build_script();
is($Module::Build::Pluggable::T1::CONFIGURE_CALLED, 1);

# I think here need to fork to refresh, but i'm lazy.
ok(-f 'Build');
do 'Build';
is($Module::Build::Pluggable::T1::BUILD_CALLED, 1);

done_testing;

