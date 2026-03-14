use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Term::ReadLine::Repl',
    license            => 'perl',
    dist_author        => 'John R. <johnlradford23@gmail.com>',
    requires => {
        'perl'             => '5.010',
        'Data::Dumper'     => 0,
        'JSON'             => 0,
        'Term::ANSIColor'  => 0,
        'Term::ReadLine'   => 0,
        'Carp'             => 0,
    },
    build_requires => {
        'Module::Build'   => 0,
        'Test::Exception' => 0,
    },
);

$build->create_build_script();
