use 5.010;
use lib qw(inc);
use Builder;

die "OS unsupported\n" unless 'MSWin32' eq $^O;

Builder->cpan_version_test();

# These are the main requirements.

my $builder = Builder->new(
	module_name         => 'Perl::Dist::WiX',
	license             => 'perl',
	dist_author         => 'Curtis Jewell <csjewell@cpan.org>',
	dist_version_from   => 'lib/Perl/Dist/WiX.pm',
	create_license      => 1,
	create_readme       => 1,
# Will do this soon, but I have to get a key first.
#	sign                => 1,
	configure_requires => {
		'Module::Build'             => '0.36',
		'CPAN'                      => '1.9600',
		'parent'                    => '0.221',
	},
	requires => {
		'perl'                       => '5.010',
		'parent'                     => '0.221',
		'Alien::WiX'                 => '0.300000',
		'Archive::Tar'               => '1.66',
		'Archive::Zip'               => '1.26',
		'CPAN'                       => '1.9600',
		'Clone'                      => '0.31',
		'Data::Dump::Streamer'       => '2.08',
		'Data::UUID'                 => '1.149',
		'Digest::CRC'                => '0.14',
		'Devel::StackTrace'          => '1.20',
		'Exception::Class'           => '1.22',
		'File::Copy::Recursive'      => '0.38',
		'File::Find::Rule'           => '0.30',
		'File::HomeDir'              => '0.82',
		'File::List::Object'         => '0.201',
		'File::Path'                 => '2.08',
		'File::PathList'             => '1.04',
		'File::pushd'                => '1.00',
		'File::ShareDir'             => '1.02',
		'File::Spec'                 => '3.29',
		'File::Temp'                 => '0.21',
		'HTTP::Status'               => '5.817',
		'IPC::Run3'                  => '0.042',
		'IO::Capture'                => '0.05',
		'IO::Compress::Bzip2'        => '2.025',
		'IO::String'                 => '1.08',
		'List::MoreUtils'            => '0.07',
		'LWP::UserAgent'             => '5.823',
		'LWP::UserAgent::WithCache'  => '0.06',
		'LWP::Online'                => '1.07',
		'Module::Build'              => '0.38',
		'Module::CoreList'           => '2.49',
		'Moose'                      => '2.00',
		'MooseX::NonMoose'           => '0.18',
		'MooseX::Object::Pluggable'  => '0.0011',
		'MooseX::Singleton'          => '0.26',
		'MooseX::Types'              => '0.19',
		'MooseX::Types::URI'         => '0.02',
		'MooseX::Types::Path::Class' => '0.05',
		'namespace::clean'           => '0.18',
		'namespace::autoclean'       => '0.12',
		'PAR::Dist'                  => '0.42',
		'Params::Util'               => '0.35',
		'Portable::Dist'             => '0.03',
		'Probe::Perl'                => '0.01',
		'Process'                    => '0.26',
		'Readonly'                   => '1.03',
		# Template 2.21 will not install on Windows, anyway.
		'Template'                   => '2.22',
		'URI'                        => '1.35',
		'WiX3'                       => '0.010004',
		'YAML::Tiny'                 => '1.36',
		'Win32'                      => '0.35',
		'Win32::Exe'                 => '0.13',
		'Win32::File::Object'        => '0.01',
		'Win32API::File'             => '0.1001',
	},
	build_requires => {
		'Test::LongString'          => '0.11',
		'Test::More'                => '0.86',
		'Test::Output'              => '0.11',
		'Test::Perl::Dist'          => '0.300',
		'Test::Script'              => '1.03',
		'Test::UseAllModules'       => '0.09',
	},
	recommends => {
		# To speed up scalar Readonly variables.
		'Readonly::XS'              => '1.05',
		# To notify Growl for Windows.
		'Growl::GNTP'               => '0.07',
		# To extract .xz files.
		'IO::Compress::Xz'          => '2.025'
	},
	meta_add => {
		no_index => {
			directory => [qw(inc share t)],
		},
	}, 
	meta_merge => {
		resources => {
			homepage    => 'http://csjewell.comyr.com/perl/',
			bugtracker  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX',
			repository  => 'http://hg.curtisjewell.name/Perl-Dist-WiX/',
			IRC         => 'irc://irc.perl.org/#win32',
		},
	},
	share_dir => {
		dist => 'share',
		Builder->plugin_share(),
	},
	script_files => [
		'script/perldist_w'
	],
);

$builder->create_build_script();
