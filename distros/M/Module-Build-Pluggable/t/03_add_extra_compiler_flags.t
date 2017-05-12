use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use lib File::Spec->rel2abs('lib');
use File::Path;
use Test::Module::Build::Pluggable;

subtest 'Module::Build::Pluggable::Base#add_extra_compiler_flags' => sub {
    my $test = Test::Module::Build::Pluggable->new(
        cleanup => $ENV{DEBUG} ? 0 : 1,
    );

    $test->write_plugin('Module::Build::Pluggable::Extra', <<'...');
package Module::Build::Pluggable::Extra;
use strict;
use warnings;
use utf8;
use parent qw/Module::Build::Pluggable::Base/;

sub HOOK_configure {
    my $self = shift;
    $self->add_extra_compiler_flags('-Wall');
}

1;
...

    $test->write_file('Build.PL', <<'...');
use strict;
use Module::Build::Pluggable (
    'Extra',
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

    $test->write_file('MANIFEST', join("\n", qw(MANIFEST)));
    $test->run_build_pl();
    my $params = $test->read_file('_build/build_params');
    like($params, qr/-Wall/, 'added extra compiler flags');
    note $params;
};

done_testing;

