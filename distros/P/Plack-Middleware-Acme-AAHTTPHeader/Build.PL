use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Plack-Middleware-Acme-AAHTTPHeader',
    module_name         => 'Plack::Middleware::Acme::AAHTTPHeader',
    license             => 'artistic_2',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/Acme/AAHTTPHeader.pm',
    add_to_cleanup      => [ 'Plack-Middleware-Acme-AAHTTPHeader-*' ],
    no_index => {
        directory => [ 't', 'xt', 'inc' ],
    },
    meta_merge     => {
        resources => {
            repository  => 'http://github.com/bayashi/Plack-Middleware-Acme-AAHTTPHeader',
            bugtracker  => 'http://github.com/bayashi/Plack-Middleware-Acme-AAHTTPHeader/issues',
        }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1, # https://metacpan.org/pod/Software::License
);

$builder->create_build_script();
