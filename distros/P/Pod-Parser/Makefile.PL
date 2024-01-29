# Makefile.PL -- Makefile template for PodParser.
#
# This file is part of "PodParser". PodParser is free software;
# you can redistribute it and/or modify it under the same terms
# as Perl itself.

BEGIN {
    require 5.005;
    if(!eval { require File::Spec; 1; } || $@) {
        warn "Warning: prerequisite File::Spec 0.82 not found.\n".
             "It is required to run this $0\n";
        exit 0;
    }
    my $FSversion = $File::Spec::VERSION || 0;
    if($FSversion < 0.82) {
        warn "Warning: prerequisite File::Spec 0.82 not found. We have $FSversion.\n".
             "It is required to run this $0\n";
        exit 0;
    }
}

use ExtUtils::MakeMaker;

$DISTNAME  = "Pod-Parser";    ## The "product" name for this distribution
$DISTMOD   = 'Pod::Parser';  ## The "title" module of this distribution
@MODULES   = ( $DISTMOD,     ## Other modules in this distribution
               qw( Pod::InputObjects
                   Pod::PlainText
                   Pod::Select
                 )
             );

## The executable scripts to be installed
@SCRIPTS   = qw( podselect
               );
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
    VERSION      => '1.67',
    INSTALLDIRS  => ($] >= 5.006 ? 'perl' : 'site'),
    PL_FILES     => { map { (script("$_.PL") => script($_)) } @SCRIPTS },
    EXE_FILES    => [ @EXE_FILES ],
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    clean        => { FILES => "@EXE_FILES" },
    macro        => { TARFLAGS => "--format=ustar -c -v -f" },
    test         => { TESTS => "@TESTPODS" },
    PREREQ_PM    => \%prereq,
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (ABSTRACT   => 'Modules for parsing/translating POD format documents',
        AUTHOR     => 'Brad Appleton <bradapp@enteract.com>, Marek Rouchal <marekr@cpan.org>' ) : ()),
);

