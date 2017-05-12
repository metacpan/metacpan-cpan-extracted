use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name         => 'Script::NeedsRestart',
    license             => 'perl',
    requires            => {
    },
    build_requires => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'File::Temp'      => 0,
    },
    configure_requires  => { 'Module::Build' => '0.38' },
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    create_readme       => 1,
    add_to_cleanup      => [ 'Script-NeedsRestart-*' ],
    meta_merge => {
        resources => {
            repository => 'http://github.com/meon/Script-NeedsRestart',
            bugtracker => 'http://github.com/meon/Script-NeedsRestart/issues',
        },
        keywords => [ qw/ script exec watch modified / ],
    },
);
$build->create_build_script;

