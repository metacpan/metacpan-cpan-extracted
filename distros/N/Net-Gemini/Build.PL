#!perl
use 5.10.0;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

# there is also Devel::CheckOS but the use-devel-assertos script seems a
# bit too complicated every time I look at it. so...
if ( $^O =~ /MSWin32/ ) {
    say "no automated install on Windows due to test failures.";
    exit 0;
}

my $builder = Module::Build->new(
    module_name        => 'Net::Gemini',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Net/Gemini.pm',
    release_status     => 'stable',
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'Test2::V0' => '0.000060',
        'perl'      => '5.10.0',
    },
    requires => {
        'Carp'            => '0',
        'Encode'          => '0',
        'IO::Socket::SSL' => '1.985',    # can_ipv6
        'perl'            => '5.10.0',
    },
    sign           => 1,
    add_to_cleanup => ['Net-Gemini-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge =>
      { resources => { repository => 'https://thrig.me/src/Net-Gemini.git' } },
);

$builder->create_build_script();
