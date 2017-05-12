use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'ShellQuote-Any',
    module_name         => 'ShellQuote::Any',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/ShellQuote/Any.pm',
    add_to_cleanup      => [ 'ShellQuote-Any-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/ShellQuote-Any',
        bugtracker  => 'http://github.com/bayashi/ShellQuote-Any/issues',
        x_IRC       => {
            url => 'irc://chat.freenode.org/#bayadev',
            web => 'http://webchat.freenode.net/?channels=%23bayadev',
        },
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1,
);

$builder->create_build_script();
