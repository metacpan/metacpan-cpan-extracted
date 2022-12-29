use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

my @package = qw(threads.pd threads PDL::Parallel::threads);
my %hash = pdlpp_stdargs(\@package);
$hash{PM}{'SIMD.pm'} = '$(INST_LIBDIR)/threads/SIMD.pm';

WriteMakefile(
	%hash,
	LICENSE  => 'perl',
	MIN_PERL_VERSION => '5.14.0',
	CONFIGURE_REQUIRES => {
		PDL             => '2.058', # trans_parent
		'ExtUtils::MakeMaker' => '7.14',
	},
	PREREQ_PM => {
		'PDL'             => '2.058',
		'threads::shared' => '1.21',   # shared_clone
	},
	TEST_REQUIRES => {
		'Test::Warn' => 0,
		'Test::Exception' => 0,
	},
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources => {
			repository => {
				web => 'http://github.com/PDLPorters/PDL-Parallel-threads',
				url => 'git://github.com/PDLPorters/PDL-Parallel-threads.git',
				type => 'git',
			},
			bugtracker => {
				web => 'http://github.com/PDLPorters/PDL-Parallel-threads/issues',
			},
		},
		no_index => {
			file => ['README.pod'],
			directory => [qw(examples t)],
		},
	},
);

sub MY::postamble {
  pdlpp_postamble(\@package);
}
