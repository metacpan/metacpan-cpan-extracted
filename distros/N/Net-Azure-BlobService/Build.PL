#!perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_license => 1,
    create_readme  => 1,
    dist_abstract  => 'Interface to Azure Blob Service',
    dist_author    => 'Leon Brocard <acme@astray.com>',
    license        => 'perl',
    meta_merge     => {
        resources => {
            homepage => 'http://search.cpan.org/dist/Net-Azure-BlobService/',
        },
    },
    'meta-spec' => {
        version => '2',
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    module_name    => 'Net::Azure::BlobService',
    needs_compiler => 1,
    requires       => {
        'Digest::MD5'    => 0,
        'Digest::SHA'    => 0,
        'LWP::UserAgent' => 0,
        'MIME::Base64'   => 0,
        'Moose'          => 0,

    },
    sign => 1,
);
$build->create_build_script;
