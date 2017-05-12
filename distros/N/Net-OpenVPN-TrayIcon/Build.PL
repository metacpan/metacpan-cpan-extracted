use 5.006;
use strict;
use warnings;
use Module::Build;
use lib 'lib';
use Net::OpenVPN::TrayIcon::Version;
use Getopt::Long qw(:config pass_through);

my @script_files = grep { -f and ! -d } glob 'script/*';
my $v = Net::OpenVPN::TrayIcon::Version->new;

my $install = 0;
my $dist    = 0;

GetOptions(
    'install' => \$install,
    'dist'    => \$dist,
);

my $build = Module::Build->new(
    module_name         => 'Net::OpenVPN::TrayIcon',
    dist_abstract       => 'An OpenVPN tray icon.',
    license             => 'perl',
    dist_author         => q{Mugen Kenichi <mugen.kenichi@uninets.eu>},
    dist_version_from   => 'lib/Net/OpenVPN/TrayIcon/Version.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.010,
    },
    add_to_cleanup      => [ 'Net-OpenVPN-TrayIcon-*' ],
    create_makefile_pl => 'traditional',

    configure_requires => {
        'Module::Build' => 0.38
    },
    requires       => {
        'POSIX'             => 0,
        'Time::HiRes'       => 0,
        'Data::Section'     => 0,
        'Moo'               => 0,
        'MIME::Base64'      => 0,
        'Gtk2'              => 0,
        'Gtk2::TrayIcon'    => 0,
        'Proc::Daemon'      => 0,
    },
    provides => {
        'Net::OpenVPN::TrayIcon'          => 0,
        'Net::OpenVPN::TrayIcon::Version' => 0,
    },
    script_files => [@script_files],
    add_to_cleanup => [ 'Net-OpenVPN-TrayIcon-* *.bak *.old Build MYMETA.* _build Makefile.PL' ],
    meta_add       => {
        no_index => {
            directory => ['t'],
        },
        release_status => 'testing',
        version        => $v->get,
    },
    meta_merge => {
        provides => {
            'Net::OpenVPN::TrayIcon' => {
                file => 'lib/Net/OpenVPN/TrayIcon.pm',
                version => $v->get,
            },
            'Net::OpenVPN::TrayIcon::Version' => {
                file => 'lib/Net/OpenVPN/TrayIcon/Version.pm',
                version => $v->get,
            },
        },
    },
);

if ($dist) {
    $build->dispatch('build');
    $build->dispatch('test');
    $build->dispatch('distmeta');
    $build->dispatch('dist');
}

if ($install) {
    $build->dispatch('build');
    $build->dispatch('test', verbose => 1);
    $build->dispatch('install');
}

$build->create_build_script();
