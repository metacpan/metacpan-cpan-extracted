use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use lib File::Spec->rel2abs('lib');
use File::Path;
use Test::Module::Build::Pluggable;

# Module::Build::Pluggable should not add "+My::Own::Plugin" to (build|configure)_requires.

my $test = Test::Module::Build::Pluggable->new();
$test->write_plugin('My::Own::Plugin', <<'...');
package My::Own::Plugin;
use strict;
use warnings;
use utf8;
use parent qw/Module::Build::Pluggable::Base/;

sub HOOK_configure {
    my $self = shift;
    warn "CONFIGURE";
    $self->requires('Devel::PPPort' => 3.18);
}

1;
...

$test->write_plugin('Module::Build::Pluggable::Requires', <<'...');
package Module::Build::Pluggable::Requires;
use strict;
use warnings;
use utf8;
use parent qw/Module::Build::Pluggable::Base/;

sub HOOK_configure {
    my $self = shift;
    $self->requires('HTML::FillInForm' => 3.18);
}

1;
...

    $test->write_file('Build.PL', <<'...');
use strict;
use Module::Build::Pluggable (
    '+My::Own::Plugin',
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
unlike($meta, qr/My::Own::Plugin/, 'Do not requires My::Own::Plugin. Since it was required with + prefix.');
like($meta, qr/Devel::PPPort/, 'requires Devel::PPPort(This means the plugin module module is works well.)');
like($meta, qr/HTML::FillInForm/, 'requires HTML::FillInForm(This means the plugin module module is works well.)');
like($meta, qr/Module::Build::Pluggable::Requires/, 'require plugin if it does not have + prefix');
note $meta;

done_testing;
