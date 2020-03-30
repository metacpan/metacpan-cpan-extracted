use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
#   INSTALL_BASE	 => "$ENV{HOME}/usr",
	NAME		 => 'Statistics::Covid',
	AUTHOR		 => q{Andreas Hadjiprocopis <bliako@cpan.org> / <andreashad2@gmail.com>},
	VERSION_FROM	 => 'lib/Statistics/Covid.pm',
	ABSTRACT_FROM	=> 'lib/Statistics/Covid.pm',
	LICENSE		 => 'artistic_2',
	EXE_FILES		=> [qw|
	script/statistics-covid-fetch-data-and-store.pl
	script/db-search-and-make-new-db.pl
	|],
	PL_FILES		 => {},
	MIN_PERL_VERSION => '5.006',
	CONFIGURE_REQUIRES => {
	'ExtUtils::MakeMaker' => '0',
	},
	BUILD_REQUIRES => {
	'Test::More' => '0',
	'Test::Harness' => '0',
	},
	PREREQ_PM => {
	# Supported databases, make sure any DB supported is also
	# declared in the dependencies as follows:
	'DBI' => '1.60',
	'DBD::SQLite' => '1.60',
	#'DBD::mysql' => '4.0',
	#'DBD::Pg' => '3.10.0',
	'DBIx::Class' => '0.08',

	# in order to fix Can't deploy without a ddl_dir or SQL::Translator >= 0.11018 
	'SQL::Translator' => '0.11019',

	'Math::Symbolic' => '0.6',
	'Algorithm::CurveFit' => '1.0',

	'Chart::Clicker' => '0',
	'DateTime' => '0',
	'DateTime::Format::Strptime' => '0',
	'Getopt::Long' => '0',
	'File::Basename' => '0',
	'File::Find' => '0',
	'File::Copy' => '0',
	'File::Path' => '0',
	'File::Temp' => '0',
	'File::Spec' => '0',
	'LWP::UserAgent' => '0',
	'HTTP::CookieJar::LWP' => '0',
	'JSON::Parse' => '0',
	'Storable' => '0',
	'Data::Dump' => '0',
	'Try::Tiny' => '0',
	'Getopt::Long' => '0',
	},

	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Statistics-Covid-UK-*' },
	postamble => {
		BENCHMARK_FILES => 'xt/benchmarks/*.b',
		NETWORK_TEST_FILES => 'xt/network/*.n',
		DATABASE_FILES => 'xt/database/*.d',
	}
);

sub MY::postamble {
	my (undef,%h) = @_;
	require Data::Dumper;
	#print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
	# This goes to the Makefile, it sets the files for the targets following it
	return
	"BENCHMARK_FILES=$h{BENCHMARK_FILES}\n" # the files
	. <<'POSTAMBLE' # and the target
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

bench :: $(BENCHMARK_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^

bench2 :: $(BENCHMARK_FILES)
	$(TEST_D) xt && $(MAKE) test TEST_FILES='$(BENCHMARK_FILES)'
POSTAMBLE
	# here goes another target:
	. "NETWORK_TEST_FILES=$h{NETWORK_TEST_FILES}\n" # the files
	. <<'POSTAMBLE' # and the target follows
network :: $(NETWORK_TEST_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^

network2 :: $(NETWORK_TEST_FILES)
	$(TEST_D) xt && $(MAKE) test TEST_FILES='$(NETWORK_TEST_FILES)'
POSTAMBLE

	# here goes another target:
	. "DATABASE_FILES=$h{DATABASE_FILES}\n" # the files
	. <<'POSTAMBLE' # and the target follows
database :: $(DATABASE_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^

database2 :: $(DATABASE_FILES)
	$(TEST_D) xt && $(MAKE) test TEST_FILES='$(DATABASE_FILES)'
POSTAMBLE
}
