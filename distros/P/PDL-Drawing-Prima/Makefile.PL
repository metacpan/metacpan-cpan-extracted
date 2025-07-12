use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use Prima::Config;
use Config;

my @package = qw(prima.pd Prima PDL::Drawing::Prima);

sub MY::postamble { pdlpp_postamble(\@package) }

my %hash = pdlpp_stdargs(\@package);
$hash{INC} .= join ' ', '', map qq{-I"$_"}, @{$Prima::Config::Config{incpaths}};
$hash{PM}{$_} = "\$(INST_LIBDIR)/Prima/$_" for glob 'pod/*.png';

# Link to Prima's dynamic library if there are any linker settings.
# (Big shout out to Dmitry, Rob, and Chris for helping me solve this!!)
$hash{LIBS}[0] .= qq{ "$Prima::Config::Config{libs}"} # for "place with space"
	if $Prima::Config::Config{libs};

WriteMakefile(
	%hash,
	LICENSE            => 'perl',
	MIN_PERL_VERSION   => '5.012', # Prima is minimum 5.12
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 0,
		PDL            => '2.037',
		Prima          => '1.74',
	},
	PREREQ_PM => {
		PDL            => '2.037',
		Prima          => '1.57',
	},
	TEST_REQUIRES => {
		'Test::More'   => '0.88',
	},
	META_MERGE => {
		"meta-spec"    => { version => 2 },
		dynamic_config => 0,
		resources      => {
			x_IRC        => 'irc://irc.perl.org/#pdl',
			repository   => {
				type => 'git',
				url  => 'git@github.com:dk/PDL-Drawing-Prima.git',
				web  => 'https://github.com/dk/PDL-Drawing-Prima',
			},
			bugtracker   => {
				web  => 'https://github.com/dk/PDL-Drawing-Prima/issues',
			},
		},
		no_index => {
			file      => ['README.md'],
			directory => [qw(examples t)],
		},
	},
);

