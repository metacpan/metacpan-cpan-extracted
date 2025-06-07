use strict;
use warnings;
use ExtUtils::MakeMaker;

# Test for broken smokers that don't set AUTOMATED_TESTING
if(my $reporter = $ENV{'PERL_CPAN_REPORTER_CONFIG'}) {
	if($reporter =~ /smoker/i) {
		warn 'AUTOMATED_TESTING added for you' if(!defined($ENV{'AUTOMATED_TESTING'}));
		$ENV{'AUTOMATED_TESTING'} = 1;
	}
}

my $dist = {
	COMPRESS => 'gzip -9f', # Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME	 => 'Object::Configure',		# Name of the module
	VERSION_FROM => 'lib/Object/Configure.pm',	# Automatically fetch version from the module
	AUTHOR	=> 'Nigel Horne <njh@nigelhorne.com>', # Author information
	ABSTRACT_FROM	=> 'lib/Object/Configure.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM => {						# Dependencies (with versions)
		'Carp' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Config::Abstraction' => 0.25,
		'Log::Abstraction' => 0.15,
	}, TEST_REQUIRES => {
		'File::Temp' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'YAML::XS' => 0,
	}, dist => $dist,
	clean	 => {
		FILES => 'Object-Configure-*',
	}, META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Object::Configure',
			repository => {
				repository => 'https://github.com/nigelhorne/Object-Configure',
				type => 'git',
				url => 'git://github.com/nigelhorne/Object-Configure.git',
				web => 'https://github.com/nigelhorne/Object-Configure'
			}, bugtracker => {
				mailto => 'bug-Object-Configure@rt.cpan.org',
				url => 'https://github.com/nigelhorne/Object-Configure/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Object-Configure',
				web => 'https://github.com/nigelhorne/Object-Configure/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
