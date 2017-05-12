# Module makefile for Object::InsideOut (using ExtUtils::MakeMaker)

require 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;


# Check for Scalar::Util::weaken()
eval { require Scalar::Util; };
if (! $@ &&
    ! Scalar::Util->can('weaken') &&
    $Scalar::Util::VERSION ge '1.20')
{
    die <<_NO_WEAKEN_;
You must reinstall Scalar::Util in order to install Object::InsideOut
because the currently installed Scalar::Util is a 'pure perl' version
that is missing the 'weaken()' function.
_NO_WEAKEN_
}


# Check for Want module
eval { require Want; };
if ($@) {
    print(<<_WANT_);

Checking prerequisites...
 * Optional prerequisite Want is not installed

ERRORS/WARNINGS FOUND IN PREREQUISITES.  You may wish to install the versions
of the modules indicated above before proceeding with this installation

_WANT_
} elsif ($Want::VERSION < 0.21) {
    print(<<_WANT_);

Checking prerequisites...
 * Want ($Want::VERSION) is installed, but we prefer to have 0.21 or later

ERRORS/WARNINGS FOUND IN PREREQUISITES.  You may wish to install the versions
of the modules indicated above before proceeding with this installation

_WANT_
}


# Check for MRMA
eval { require Math::Random::MT::Auto; };
if ($@) {
    print(<<_MRMA_);

Checking prerequisites...
 * Optional prerequisite Math::Random::MT::Auto is not installed

ERRORS/WARNINGS FOUND IN PREREQUISITES.  You may wish to install the versions
of the modules indicated above before proceeding with this installation

_MRMA_
} elsif ($Math::Random::MT::Auto::VERSION < 6.18) {
    print(<<_MRMA_);

Checking prerequisites...
 * Math::Random::MT::Auto ($Math::Random::MT::Auto::VERSION) is installed, but we prefer to have 6.18 or later

ERRORS/WARNINGS FOUND IN PREREQUISITES.  You may wish to install the versions
of the modules indicated above before proceeding with this installation

_MRMA_
}


# Construct make file
WriteMakefile(
    'NAME'          => 'Object::InsideOut',
    'AUTHOR'        => 'Jerry D. Hedden <jdhedden AT cpan DOT org>',
    'VERSION_FROM'  => 'lib/Object/InsideOut.pm',
    'ABSTRACT_FROM' => 'lib/Object/InsideOut.pod',
    'PREREQ_PM'     => { 'strict'           => 0,
                         'warnings'         => 0,
                         'attributes'       => 0,
                         'overload'         => 0,
                         'Config'           => 0,
                         'B'                => 0,
                         'Data::Dumper'     => 2.131,
                         'Scalar::Util'     => 1.23,
                         'Exception::Class' => 1.32,
                         'Test::More'       => 0.98,
                       },
    ((ExtUtils::MakeMaker->VERSION() lt '6.25')
                              ? ('PL_FILES' => { })    : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30')
                              ? ('LICENSE'  => 'perl') : ()),
);


package MY;

# Add to metafile target
sub metafile
{
    my $inherited = shift->SUPER::metafile_target(@_);
    $inherited .= <<'_MOREMETA_';
	$(NOECHO) $(ECHO) 'recommends:' >>$(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) '  Math::Random::MT::Auto: 6.18' >>$(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) '  Want: 0.21' >>$(DISTVNAME)/META.yml
_MOREMETA_

    return $inherited;
}

# Additional 'make' targets
sub postamble
{
    return <<'_EXTRAS_';
fixfiles:
	@dos2unix `cat MANIFEST`
	@$(CHMOD) 644 `cat MANIFEST`

yapi:
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', '\''$(PM_FILTER)'\'')' -- \
	  examples/YAPI.pm blib/lib/Term/YAPI.pm
	$(NOECHO) $(TOUCH) pm_to_blib
_EXTRAS_
}

# EOF
