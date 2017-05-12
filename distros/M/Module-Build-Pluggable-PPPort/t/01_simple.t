use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'File::Temp';
use Test::Module::Build::Pluggable;

use File::Spec;
use lib File::Spec->rel2abs('lib');
my $test = Test::Module::Build::Pluggable->new();

$test->write_file('Build.PL', <<'...');
use strict;
use Module::Build::Pluggable (
    'PPPort'
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
...

$test->run_build_pl();
$test->run_build_script();

ok(-f 'ppport.h', 'Created ppport.h');

undef $test;

done_testing;

