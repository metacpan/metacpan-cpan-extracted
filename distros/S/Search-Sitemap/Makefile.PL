use inc::Module::Install;

name 'Search-Sitemap';
license 'perl';
all_from 'lib/Search/Sitemap.pm';
requires $_ for qw(
    Moose LWP::UserAgent XML::Twig IO::File Carp POSIX IO::Zlib Class::Trigger
    HTML::Entities Module::Find Moose::Util::TypeConstraints MooseX::Types
    MooseX::Types::Moose MooseX::ClassAttribute namespace::clean
    MooseX::Types::URI DateTime
);

test_requires $_ for qw(
    Test::Most Test::Mock::LWP::UserAgent ok
);

extra_tests;
WriteAll;
