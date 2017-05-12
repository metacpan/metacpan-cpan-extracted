use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Slackware::Slackget',
    license             => 'perl',
    dist_author         => 'Arnaud DUPUIS <a.dupuis@infinityperl.org>',
    dist_version_from   => 'lib/Slackware/Slackget.pm',
    build_requires => {
        'Test::More' => '0.70',
        'XML::Simple' => '2.18',
        'File::Copy' => 0,
        'perl' => '>= 5.8.5',
	'Net::FTP' => '>= 2.75',
	'LWP::Simple' => '>= 1.41',
	'Time::HiRes' => '>= 1.66',
	'HTTP::Status' => '>= 1.28',
	'HTTP::Request' => '>= 1.40',
	'File::Copy' => '>= 2.08',
	'Data::Dumper' => '>= 2.121_02',
	'Proc::Daemon' => 0,
	'Getopt::Long' => 0,
	'XML::Parser' => 0,
	'POE::Component::Logger' => '1.0',
	'POE' => '0.9999',
    },
    add_to_cleanup      => [ 'Slackware-Slackget-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
