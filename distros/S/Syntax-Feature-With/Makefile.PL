use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		 => 'Syntax::Feature::With',
	ABSTRACT_FROM => 'lib/Syntax/Feature/With.pm',
	VERSION_FROM => 'lib/Syntax/Feature/With.pm',
	AUTHOR	   => 'Nigel Horne (njh@nigelhorne.com)',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM	=> {
		'Carp' => 0,
		'Exporter' => 0,
		'PadWalker' => 0,
	}, CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Syntax-Feature-With-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Syntax::Feature::With',
			repository => {
				repository => 'https://github.com/nigelhorne/Syntax-Feature-With',
				type => 'git',
				url => 'git://github.com/nigelhorne/Syntax-Feature-With.git',
				web => 'https://github.com/nigelhorne/Syntax-Feature-With',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Syntax-Feature-With',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Syntax-Feature-With',
				# web => 'https://github.com/nigelhorne/Syntax-Feature-With/issues',
				# url => 'https://github.com/nigelhorne/Syntax-Feature-With/issues',
				mailto => 'bug-Syntax-Feature-With@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
