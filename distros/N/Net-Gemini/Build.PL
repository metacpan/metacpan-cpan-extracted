#!perl
# the actual perl version requirement may be higher due to other modules
use 5.8.0;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

# there is also Devel::CheckOS but the use-devel-assertos script seems a
# bit too complicated every time I look at it. so...
if ( $^O =~ /MSWin32/ ) {
    print "no automated install on Windows due to test failures.\n";
    exit 0;
}

my $builder = Module::Build->new(
    module_name        => 'Net::Gemini',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jmates@thrig.me>},
    dist_version_from  => 'lib/Net/Gemini.pm',
    release_status     => 'stable',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'Data::Dumper'          => '0',
        'IO::Socket::IP'        => '0',
        'IO::Socket::SSL'       => '0',
        'Parse::MIME'           => '0',
        'Test2::Tools::Command' => '0.11',
        'Test2::V0'             => '0.000060',
        'perl'                  => '5.8.0',
    },
    # NOTE several of these are for gmitool so are not really required
    requires => {
        'Carp'             => '0',
        'Cpanel::JSON::XS' => '0',
        'Digest::SHA'      => '0',
        'File::Path'       => '0',
        'File::Slurper'    => '0',
        'File::Spec'       => '0',
        'IO::Socket::IP'   => '0',
        'IO::Socket::SSL'  => '0',
        'Net::SSLeay'      => '0',
        'Parse::MIME'      => '0',
        'URI'              => '0',
        'perl'             => '5.8.0',
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
    meta_merge => {
        resources => { repository => 'https://thrig.me/src/Net-Gemini.git' }
    },
);

$builder->create_build_script();
