use strict;
use warnings;

use lib './inc';

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'String::Random',
    license             => 'perl',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    configure_requires =>
    {
        'Module::Build'  => '0.36',
    },
    build_requires =>
    {
        'Test::More'    => 0,
    },
    requires =>
    {
        'Carp'          => 0,
        'Exporter'      => 0,
        'parent'        => 0,
        'perl'          => '5.006',
        'strict'        => 0,
        'warnings'      => 0,
        'vars'          => 0,
    },
    meta_merge =>
    {
        resources =>
        {
            repository => 'http://github.com/shlomif/String-Random',
        },
        keywords =>
        [
            'generate',
            'random',
            'regex',
            'regexp',
            'regular-expression',
            'string',
        ],
    },
);

$builder->create_build_script();

# vi: set ai et:
