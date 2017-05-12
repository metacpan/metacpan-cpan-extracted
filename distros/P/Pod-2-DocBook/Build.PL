use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::2::DocBook',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Pod/2/DocBook.pm',
    requires => {
        'Digest::MD5'      => 0,
        'Pod::Parser'      => 0,
        'Pod::ParseLink'   => 0,
        'Text::ParseWords' => 0,
        'Text::Wrap'       => 0,
        'List::MoreUtils'  => 0,
        'CPAN::Version'    => 0,
    },
    build_requires => {
        'Test::More'  => 0,
        'XML::LibXML' => 0,
    },
    script_files => [
        'pod2docbook',
    ],
    
    add_to_cleanup      => [ 'Pod-2-DocBook-*', 't/*.out' ],
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    sign                => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/pod-2-docbook.git',
            bugtracker =>
            'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-2-DocBook',
        },
        keywords => [ qw/ pod docbook / ],
    },
);

$builder->create_build_script();
