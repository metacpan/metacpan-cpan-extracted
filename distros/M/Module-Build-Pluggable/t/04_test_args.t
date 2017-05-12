use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use lib File::Spec->rel2abs('lib');
use File::Path;
use Test::Module::Build::Pluggable;

BEGIN { *describe = *context = *it = *Test::More::subtest }

describe 'Test::Module::Build::Pluggable::run_build_pl passes @ARGV' => sub {
    context 'with no args' => sub {
        my $test = setup();
        $test->run_build_pl();
        my $params = $test->read_file('ddd');
        is($params, '0', 'arguments for read_file is passed to @ARGV');
        ok(-f 'called');
        note $params;
    };
    context 'with -g option' => sub {
        my $test = setup();
        $test->run_build_pl('-g');
        my $params = $test->read_file('ddd');
        is($params, '1', 'arguments for read_file is passed to @ARGV');
        ok(-f 'called');
        note $params;
    };
};

done_testing;

sub setup {
    my $test = Test::Module::Build::Pluggable->new();

    $test->write_plugin('Module::Build::Pluggable::Extra', <<'...');
package Module::Build::Pluggable::Extra;
use strict;
use warnings;
use utf8;
use parent qw/Module::Build::Pluggable::Base/;

sub HOOK_prepare {
    my ($class, $args) = @_;

    open my $fh, '>', 'called';
    print {$fh} 1;
    close $fh;

    die "Other plugins uses -g option" if $args->{get_options}->{g};
    $args->{get_options}->{g} = { type => '!' };
}

1;
...

    $test->write_file('Build.PL', <<'...');
use strict;
use Module::Build::Pluggable (
    'Extra'
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

open my $fh, '>', 'ddd' or die $!;
print {$fh} ($builder->args('g') ? 1 : 0);
close $fh;
...

    $test->write_file('MANIFEST', join("\n", qw(MANIFEST)));

    return $test;
}
