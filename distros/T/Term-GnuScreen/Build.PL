use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Term::GnuScreen',
    license           => 'perl',
    dist_author       => 'Mario Domgoergen <dom@math.uni-bonn.de>',
    dist_version_from => 'lib/Term/GnuScreen.pm',
    requires          => {
        'Moo'               => 0,
        'File::Temp'        => 0,
        autodie             => 0,
        'File::Which'       => 0,
        'IO::CaptureOutput' => 0,
	'IPC::System::Simple' => 0,
    },
    build_requires     => { 'Test::More' => 0, },
    add_to_cleanup     => ['Term-GnuScreen-*'],
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    meta_merge         => {
        resources => { repository => 'http://github.com/mdom/term-gnuscreen', },
    }
);

$builder->create_build_script();
