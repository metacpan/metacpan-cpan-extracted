# $Id: Build.PL,v 1.7 2006/10/23 11:52:32 asc Exp $
# -*-cperl-*

use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Net::Delicious',
    # dist_author
    # dist_abstract
    dist_version_from => 'lib/Net/Delicious.pm',
    license           => 'perl',
    requires => {
        'LWP::UserAgent' => '',
        'HTTP::Request'  => '',
        'YAML'           => '0.35',
        'URI'            => '',
        'Log::Dispatch'  => '2',
        'XML::Simple'    => '2',
        'Time::HiRes'    => '1.65',
        'FileHandle'     => '2',
        'IO::AtomicFile' => '2.1',
        'File::Spec'     => '0.8',
        'Date::Parse'    => '2.27',
        'Config::Simple' => '2',
        'Crypt::SSLeay'  => '0',
    },
    build_requires => {
        'Test::Simple'   => '0.47',
    },
    create_readme      => 1,
);

$build->create_build_script();
