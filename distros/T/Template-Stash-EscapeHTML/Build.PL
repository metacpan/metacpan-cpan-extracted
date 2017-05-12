use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Stash::EscapeHTML',
    license             => 'perl',
    dist_author         => 'Tomohiro IKEBE <ikebe@shebang.jp>',
    dist_version_from   => 'lib/Template/Stash/EscapeHTML.pm',
    requires => {
        'Test::More' => 0,
        Template => 2.13
    },
    add_to_cleanup      => [ 'Template-Stash-EscapeHTML-*' ],
);

$builder->create_build_script();
