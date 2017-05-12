use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Religion::Bible::Regex::Lexer',
    license             => 'perl',
    dist_author         => 'Daniel Holmlund <holmlund.dev@gmail.com>',
    dist_version_from   => 'lib/Religion/Bible/Regex/Lexer.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Religion-Bible-Regex-Lexer-*' ],
);

$builder->create_build_script();
