use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'OpenOffice::Wordlist',
    license             => 'perl',
    dist_author         => 'Johan Vromans <jv@cpan.org>',
    dist_version_from   => 'lib/OpenOffice/Wordlist.pm',
    build_requires => {
        'Test::More' => 0,
	'File::Compare' => 0,
    },
    add_to_cleanup      => [ 'OpenOffice-Wordlist-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
