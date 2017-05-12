use Module::Build;

die "OS unsupported\n" unless win32;

my $builder = Module::Build->new(
	module_name         => 'Perl::Dist::Padre',
	license             => 'perl',
	dist_author         => 'Curtis Jewell <csjewell@cpan.org>',
	dist_version_from   => 'lib/Perl/Dist/Padre.pm',
	create_makefile_pl  => 'small',
	create_license      => 1,
	create_readme       => 1,
# Will do this soon, but I have to get a key first.
#	sign                => 1,
	configure_requires => {
		'Module::Build'             => '0.36',
	},
	requires => {
		'perl'                      => '5.010001',
		'Perl::Dist::Strawberry'    => '2.02',
		'Perl::Dist::WiX'           => '1.102002',
		'URI::file'                 => '4.20', # From URI 1.36 or better.
		'parent'                    => '0.221',
	},
	build_requires => {
		'Test::More'                => '0.86',
		'LWP::Online'               => '1.07',
		'Test::Perl::Dist'          => '0.202',
	},
	meta_merge     => {
		resources => {
			homepage    => 'http://padre.perlide.org/',
			repository  => 'https://svn.perlide.org/padre/trunk/Perl-Dist-Padre',
			IRC         => 'irc://irc.perl.org/#padre',
			WebIRC      => 'http://widget.mibbit.com/?server=irc.perl.org&channel=%23padre',
			bugtracker  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Padre',
		},
	},
	share_dir => {
		dist => 'share',
	},
);

$builder->create_build_script();
