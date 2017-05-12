use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use lib File::Spec->rel2abs('lib');
use File::Path;
use Test::Module::Build::Pluggable;

subtest 'Module::Build::Pluggable::Base#requries' => sub {
    my $test = Test::Module::Build::Pluggable->new();

    $test->write_plugin('Module::Build::Pluggable::Requires', <<'...');
package Module::Build::Pluggable::Requires;
use strict;
use warnings;
use utf8;
use parent qw/Module::Build::Pluggable::Base/;

sub HOOK_configure {
    my $self = shift;
    $self->requires('Devel::PPPort' => 3.18);
}

1;
...

    $test->write_file('Build.PL', <<'...');
use strict;
use Module::Build::Pluggable (
    'Requires',
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
    my $meta = $test->read_file('MYMETA.yml');
    like($meta, qr/Devel::PPPort/, 'requires Devel::PPPort');
    note $meta;
};

done_testing;

