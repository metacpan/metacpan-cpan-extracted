# Makefile.PL -- Makefile template for Pod-Checker
#
# This file is part of "Pod-Checker". Pod-Checker is free software;
# you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use ExtUtils::MakeMaker;
use File::Spec;

$DISTNAME  = "Pod-Checker";    ## The "product" name for this distribution
$DISTMOD   = 'Pod::Checker';  ## The "title" module of this distribution
@MODULES   = ( $DISTMOD,     ## Other modules in this distribution
               qw()
             );

## The executable scripts to be installed
@SCRIPTS   = qw( podchecker );
sub script($) { File::Spec->catfile ('scripts', @_) }
my @EXE_FILES = ();
if ( $^O eq 'VMS' ) {
  @EXE_FILES = map { script "$_.com" } @SCRIPTS;
}
else {
  @EXE_FILES = map { script $_ } @SCRIPTS;
}

## The test-script to execute regression tests (note that the
## 'xtra' directory might not exist for some installations)
@TESTPODS = ();
my $testdir  = File::Spec->catfile('t', 'pod');
my $test2dir = File::Spec->catfile($testdir, 'xtra');
my @testdirs = ($testdir);
push @testdirs, $test2dir if (-d $test2dir);
@TESTPODS = map { File::Spec->catfile($_, '*.t') } @testdirs;
@TESTPODS = map { glob } @TESTPODS if $^O eq 'MSWin32';

##-----------------------------------------------------------------------
## Instructions to write the Makefile (see Ext::MakeMaker)

# needed for new pod2usage2.t
my %prereq = (
  'Pod::Simple'    => 3.40,
  'Test::More'     => 0.60,
  'Cwd'            => 0,
  'File::Basename' => 0
);
if ($] < 5.005) {
  ## Need File::Spec if this is 5.004 or earlier
  $prereq{'File::Spec'} = 0.82;
}

WriteMakefile(
    NAME         => $DISTMOD,
    DISTNAME     => $DISTNAME,
    VERSION      => '1.76',
    INSTALLDIRS  => ($] >= 5.006 ? 'perl' : 'site'),
    PL_FILES     => { map { (script("$_.PL") => script($_)) } @SCRIPTS },
    EXE_FILES    => [ @EXE_FILES ],
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    clean        => { FILES => "@EXE_FILES" },
    test         => { TESTS => "@TESTPODS" },
    macro        => { TARFLAGS   => "--format=ustar -c -v -f", },
    PREREQ_PM    => \%prereq,
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (ABSTRACT   => 'Pod::Checker verifies POD documentation contents for compliance with the POD format specifications',
        AUTHOR     => 'Marek Rouchal <marekr@cpan.org>' ) : ()),
);

