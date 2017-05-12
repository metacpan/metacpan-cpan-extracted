#!/usr/bin/perl
# xxx: I'd really like to make this more friendly to install....

use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;
use Cwd qw(cwd);
use File::Spec;

my @pkgs = qw/moz ff mff ice xulunstable xul/;

my %pkg_to_try = (
    moz         => {
        pkgcfg => 'mozilla-xpcom',
        reqver => 1.7,
    },
    ff          => {
        pkgcfg => 'firefox-xpcom',
        reqver => 1.0,
    },
    mff         => {
        pkgcfg => 'mozilla-firefox-xpcom',
        reqver => 1.0,
    },
    ice         => {
        pkgcfg => 'xulrunner-xpcom',
        reqver => 1.7,
    },
    xulunstable => {
        pkgcfg => 'libxul-unstable',
        reqver => 1.9,
    },
    xul         => {
        pkgcfg => 'libxul',
        reqver => 1.9,
    },
);

our %build_reqs = (
    'perl-ExtUtils-Depends'   => '0.205',
    'perl-ExtUtils-PkgConfig' => '1.07',
    (
        map { ( $pkg_to_try{$_}{pkgcfg} => $pkg_to_try{$_}{reqver} ) } @pkgs
    ),
);

unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
           . "1") {
    warn "$@\n";
    WriteMakefile(
        PREREQ_FATAL => 1,
        PREREQ_PM    => {
            'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
            'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
        },
    );
    exit 1; # not reached
}

my %pkgcfg = ExtUtils::PkgConfig->find(
    map { $_ . ' >= ' . $build_reqs{$_} } map { $pkg_to_try{$_}{pkgcfg} } @pkgs
);

my ($pkg) = $pkgcfg{pkg} =~ /^(\S+) /;

mkdir 'build', 0777;

ExtUtils::PkgConfig->write_version_macros (
    "build/mozilladom2perl-version.h",
    $pkg => 'MOZ_DOM',
);

my $incdir = `pkg-config --variable=includedir $pkg`;
my $libdir = `pkg-config --variable=libdir $pkg`;
chomp($incdir, $libdir);

my $pkgconf_variable = 'libdir';
unless ($libdir) {
    $libdir = `pkg-config --variable=sdkdir $pkg`;
    chomp($libdir);

    $pkgconf_variable = 'sdkdir';
}

ExtUtils::MakeMaker::prompt(<<MSG);


IMPORTANT NOTES:

1) Due to the broken way that firefox/xulrunner libraries
are set up (at least in Ubuntu), you might need to configure
your LD_LIBRARY_PATH to include the directory where
libxul.so (or whatever) is located.

This script found a library in '$libdir'
and will set the LD_LIBRARY_PATH to temporarily include that
so the tests will (hopefully) pass. You may need to set
that yourself somehow, for example by adding an entry
to /etc/ld.so.conf or /etc/ld.so.conf.d/ or by doing

    export LD_LIBRARY_PATH="$libdir/lib:\$LD_LIBRARY_PATH"

in your ~/.bashrc file. (You might also try using something like
\$(pkg-config --variable=$pkgconf_variable $pkg)/lib to be more general,
but this varies depending on the distribution....)

2) You might have to install a "-dev" package, so that libraries
and header files are available.


Good luck!  (please hit Enter now)


MSG

{
    package MY;
    sub test {
        "\nLD_LIBRARY_PATH=$libdir/lib:$ENV{LD_LIBRARY_PATH}\n"
          . shift->SUPER::test(@_)
    }
}

my $mozdom = ExtUtils::Depends->new('Mozilla::DOM');

# -I/usr/include/mozilla -I/usr/include/mozilla/xpcom
# -I/usr/include/mozilla/string -I/usr/include/mozilla/nspr
$mozdom->set_inc($pkgcfg{cflags}, '-I.', '-I./build',
                 "-I$incdir", "-I$incdir/dom", "-I$incdir/webbrwsr",
                 "-I$incdir/content", "-I$incdir/docshell");

# -L/usr/lib/mozilla -lxpcom -lplds4 -lplc4 -lnspr4 -ldl -lc -lpthread
$mozdom->set_libs($pkgcfg{libs});

$mozdom->add_xs(<xs/*.xs>);
# XXX: should move DOM.pm into lib/Mozilla/ then use PMLIBDIRS in WriteMakefile instead
$mozdom->add_pm(
    'DOM.pm' => '$(INST_LIBDIR)/DOM.pm',
    map {   # .pod and .pm files in lib/Mozilla/DOM/
        my $inst = $_;
        $inst =~ s{lib/Mozilla}{};
        $_ => "\$(INST_LIBDIR)$inst";
    } glob('lib/Mozilla/DOM/*.{pod,pm}'),
);
$mozdom->add_typemaps(map {File::Spec->catfile(cwd(), $_)} ('mozilladom.typemap'));

$mozdom->install('mozilladom2perl.h',
                 # 'build/mozilladom2perl-autogen.h',
                 'build/mozilladom2perl-version.h',
                 'doctypes');
$mozdom->save_config('build/IFiles.pm');

# xxx:
# https://developer.mozilla.org/en/Gecko_1.9_Changes_affecting_websites#intersectsNode_has_been_removed
my @defines = ();
push @defines, '-DMD_XUL'
  if $pkg eq $pkg_to_try{xul}{pkgcfg} or $pkg eq $pkg_to_try{xulunstable}{pkgcfg};

WriteMakefile(
    NAME          => 'Mozilla::DOM',
    VERSION_FROM  => 'DOM.pm',
    ABSTRACT_FROM => 'DOM.pm',
    XSPROTOARG    => '-noprototypes',
    MAN3PODS      => {},    # don't create man pages
    LD            => "LD_RUN_PATH=$libdir $Config{ld}",
    CC            => 'g++',
    XSOPT         => '-C++',
    dist => {
        # don't index examples directory on CPAN
        PREOP => 'echo -e "no_index:\n  directory:\n    - examples" >> ${DISTVNAME}/META.yml',
    },
    $mozdom->get_makefile_vars,

    (@defines ? ('DEFINE' => join(' ', @defines)) : ()),
);


package MY;

# Copied from Glib::MakeHelper
# (see NOTICE in `perldoc Glib::MakeHelper` on const_cccmd)
sub const_cccmd {
        my $inherited = shift->SUPER::const_cccmd(@_);
        return '' unless $inherited;
        use Config;
        $inherited .= ($Config{cc} eq 'cl') ? ' /Fo$@' : ' -o $@';
        return $inherited;
}

# Copied from Glib::MakeMaker `postamble_clean'
sub postamble {
'
realclean ::
	-$(RM_RF) build blib_done perl-$(DISTNAME).spec
'
}
