use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::postamble {
    my (undef,%h) = @_;
    require Data::Dumper;
    #print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    return "BENCHMARK_FILES=$h{BENCHMARK_FILES}\n"
	. <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

bench :: $(BENCHMARK_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^

bench2 :: $(BENCHMARK_FILES)
	$(TEST_D) xt && $(MAKE) test TEST_FILES='$(BENCHMARK_FILES)'
POSTAMBLE
}

#	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(BENCHMARK_FILES)
#	prove --blib --verbose $^

WriteMakefile(
   INSTALL_BASE      => "$ENV{HOME}/usr",
    NAME	     => 'Statistics::Running::Tiny',
    AUTHOR	   => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Statistics/Running/Tiny.pm',
    ABSTRACT_FROM    => 'lib/Statistics/Running/Tiny.pm',
    LICENSE	  => 'artistic_2',
    PL_FILES	 => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
	'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
	'Test::More' => '0',
    },
    BUILD_REQUIRES => {
	'Test::More' => '0',
	'Test::Harness' => '0',
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Statistics-Running-Tiny-*' },
    postamble => { BENCHMARK_FILES => 'xt/benchmarks/*.b' }
);
