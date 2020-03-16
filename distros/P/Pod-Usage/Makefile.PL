# Makefile.PL -- Makefile template for Pod-Usage
#
# This file is part of "Pod-Usage". Pod-Usage is free software;
# you can redistribute it and/or modify it under the same terms
# as Perl itself.
use 5.006;
use strict;

use ExtUtils::MakeMaker;
use File::Spec;

my $DISTNAME  = "Pod-Usage";    ## The "product" name for this distribution
my $DISTMOD   = 'Pod::Usage';  ## The "title" module of this distribution
my @MODULES   = ( $DISTMOD,     ## Other modules in this distribution
             );

## The executable scripts to be installed
my @SCRIPTS   = qw( pod2usage );
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
my @TESTPODS = ();
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
  'Pod::Text'      => 4.00, # to avoid issues with wrong test results
  'Test::More'     => 0.60,
  'Cwd'            => 0,
  'File::Basename' => 0,
  'File::Spec'     => 0.82,
  'blib'           => 0,
);

WriteMakefile(
    NAME         => $DISTMOD,
    DISTNAME     => $DISTNAME,
    VERSION      => '1.70',
    INSTALLDIRS  => ($] < 5.012 ? 'perl' : 'site'),
    PL_FILES     => { map { (script("$_.PL") => script($_)) } @SCRIPTS },
    EXE_FILES    => [ @EXE_FILES ],
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    clean        => { FILES => "@EXE_FILES" },
    test         => { TESTS => "@TESTPODS" },
    macro        => { TARFLAGS   => "--format=ustar -c -v -f", },
    PREREQ_PM    => \%prereq,
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (ABSTRACT   => 'Pod::Usage extracts POD documentation and shows usage information',
        AUTHOR     => [ 'Brad Appleton  <bradapp@enteract.com>', 'Marek Rouchal <marekr@cpan.org>' ] ) : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ?
       (LICENSE => 'perl') : ()),
);

