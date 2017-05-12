use ExtUtils::MakeMaker;

unless (eval { require Test::More; 1 }) {
	print STDERR "*** Test::More is not installed, you will not be able to run the tests\n";
}
unless ($] >= 5.006001) {
	print STDERR "*** This Perl version ($]) is not supported\n";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'	 => 'Set::Object',
  'VERSION_FROM' => 'lib/Set/Object.pm',
  'AUTHOR'    => 'Jean-Louis Leroy and Sam Vilain',
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
      recommends => {
	# deps of t/misc/more_leaks.t
	'Test::LeakTrace' => 0,
	'Moose'           => 0,
      },
      resources => {
	license     => 'http://dev.perl.org/licenses/',
	repository  => 'git://github.com/rurban/Set-Object.git',
      }
    }) : ()
  ),
  test => { TESTS => join(' ', glob('t/*/*.t')) },
);
