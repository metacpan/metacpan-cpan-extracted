
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	NAME => 'OOPS',
	DISTNAME => 'OOPS',
	VERSION_FROM => 'lib/OOPS.pm',
	($] >= 5.005 
		?	
			(
				ABSTRACT	=> 'Store any object in a RDBMS',
				AUTHOR		=> 'David Muir Sharnoff <cpan@dave.sharnoff.org>',
				META_MERGE     => {
					resources  => {
						repository => 'http://github.com/muir/OOPS',
					},
				},
			) 
		: ()
	),
	dist   => {COMPRESS=>'gzip', SUFFIX=>'gz'},
	PREREQ_PM => {
		'DBI' => 1.40,
		'Digest::MD5' => 0,
		'Scalar::Util' => 0,
		'Filter::Util::Call' => 0,
	},
	BUILD_REQUIRES => {
		'diagnostics'	=> 0,
		'Test::Deep'	=> 0,
	},
);

package MY;

sub postamble {
    <<'END_OF_POSTAMBLE';

pm_to_blib: README

README: lib/OOPS.pod
	pod2text lib/OOPS.pod >README

test-all:; env OOPS_SLOWTEST=yes $(MAKE) test

test-tran:; env OOPS_SLOWTEST=yes $(MAKE) TEST_FILES=t/tran*.t test

test-basic:; env OOPS_SLOWTEST=yes $(MAKE) TEST_FILES="t/auto_init.t t/misc2.t t/tran1.t t/zzz-drop.t" test

END_OF_POSTAMBLE
}
