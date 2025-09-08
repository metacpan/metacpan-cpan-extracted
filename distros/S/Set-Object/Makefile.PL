use ExtUtils::MakeMaker;

unless (eval { require Test::More; 1 }) {
	print STDERR "*** Test::More is not installed, you will not be able to run the tests\n";
}
unless ($] >= 5.008) {
	print STDERR "*** This Perl version ($]) is not supported\n";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'	 => 'Set::Object',
  'VERSION_FROM' => 'lib/Set/Object.pm',
  'AUTHOR'    => 'Jean-Louis Leroy, Sam Vilain and Reini Urban',
  'LICENSE'   => 'Artistic_2',
  'ABSTRACT'  => "Unordered collections (sets) of Perl Objects",
  'PREREQ_PM' => {
    'Scalar::Util'    => 0,
    'Test::More'      => 0,
  },
  "SIGN" => 1,
  ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
   ('META_MERGE'  =>
    {
      "meta-spec" => { version => 2 },
      dynamic_config => 0,
      resources => {
        repository => {
          type => 'git',
          url => 'git://github.com/rurban/Set-Object.git',
          web => 'https://github.com/rurban/Set-Object',
        },
        license => [ 'http://dev.perl.org/licenses/' ],
      },
      prereqs => {
        develop => {
          requires => {
            # deps of t/misc/more_leaks.t
            'Test::LeakTrace' => 0,
            'Moose'           => 0,
          },
        },
      },
    }) : ()
  ),
  test => { TESTS => join(' ', glob('t/*/*.t')) },
);

package MY;
#use Config;

sub depend {
  "
release-test : dist
	if test \"\$(shell git rev-parse --abbrev-ref HEAD)\" != \"master\" || \\
           test \"\$(shell git status --porcelain)\" != \"\" ; then \\
          echo 'You are not on a clean master branch, aborting.'; \\
          exit 1 ; \\
	fi
	echo git tag \$(VERSION)
	echo cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	echo git push
	echo git push --tags

release : dist
	if test \"\$(shell git rev-parse --abbrev-ref HEAD)\" != \"master\" || \\
           test \"\$(shell git status --porcelain)\" != \"\" ; then \\
          echo 'You are not on a clean master branch, aborting.'; \\
          exit 1; \\
	fi
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags

test_cover :: pure_all
	\$(RM_RF) cover_db
	\$(PERLRUNINST) -S cover -test
test_coveralls :: pure_all
	\$(PERLRUNINST) -S cover -test -report coveralls

gcov : \$(BASEEXT).c.gcov \$(BASEEXT).gcov cover_db/\$(BASEEXT)-xs.html

\$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov : \$(BASEEXT).xs
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -fprofile-arcs -ftest-coverage\" LDDLFLAGS=\"\$(LDDLFLAGS) -fprofile-arcs -ftest-coverage\"
	gcov \$(BASEEXT).c \$(BASEEXT).xs

cover_db/\$(BASEEXT)-xs.html : \$(BASEEXT).xs.gcov
	PERL5OPT=-MDevel::Cover make test
	-$^X -S gcov2perl \$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov
	$^X -S cover

gprof :
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -pg\" LDDLFLAGS=\"\$(LDDLFLAGS) -pg\"
"
}
