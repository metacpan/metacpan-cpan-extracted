use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

# Switch::Declare builds against the core perl C API only (the keyword-plugin
# and lexer/parser interfaces). The few post-5.14 symbols it touches
# (pad_findmy_pvn, the OUR pad-name resolution) are shimmed in Declare.xs back
# to 5.14 via the stable Perl_pad_findmy / PAD_COMPNAME_* APIs.
#
# The `case PATTERN -> [..]` destructuring bind reuses Destructure::Declare's
# compile-time engine (destructure.h), pulled in via ExtUtils::Depends. The
# header is all static code, so we compile our own copy - there are no shared
# runtime C symbols to link. When developing in-tree (Destructure::Declare not
# yet installed) we fall back to a sibling working copy.

my $pkg;
eval { $pkg = ExtUtils::Depends->new('Switch::Declare', 'Destructure::Declare') };
if (!$pkg) {
    die "Cannot find the Destructure::Declare dependency (need 0.01+).\n"
      . "Install Destructure::Declare or place it as a sibling directory.\n"
        unless -d '../Destructure-Declare/include';
    $pkg = ExtUtils::Depends->new('Switch::Declare');
    $pkg->set_inc('-I. -I../Destructure-Declare/include');
}
else {
    # The dependency already supplies the path to the published destructure.h;
    # just add our own dir for ppport.h.
    $pkg->set_inc('-I.');
}
my %dep_vars = $pkg->get_makefile_vars;

my %WriteMakefileArgs = (
    NAME             => 'Switch::Declare',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Switch/Declare.pm',
    ABSTRACT_FROM    => 'lib/Switch/Declare.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.014',
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'   => '0',
        'ExtUtils::Depends'     => '0.404',
        'Destructure::Declare'  => '0.01',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Switch-Declare-*' },
    %dep_vars,   # INC pointing at Destructure::Declare's published destructure.h
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
