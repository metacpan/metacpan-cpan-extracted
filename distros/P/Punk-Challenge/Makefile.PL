use 5.010;
use strict;
use warnings;
use Config;                 # $Config{cc}, for the getentropy probe below
use ExtUtils::MakeMaker;

# Mainly XS, on purpose. A rule runs ahead of routing on every request under
# its prefix, and a cleared request is a cookie parse, one HMAC and a
# constant-time compare: the one place in an application where a Perl frame
# per request is paid by everybody. The SHA-256 and HMAC are bundled, as
# Punk bundles its own for sessions, so nothing links and nothing is
# fetched. The solving is done by the browser, never by this process.
#
# No ExtUtils::Depends. Punk installs pk_abi.h, an observer table with no
# install_kw and no route, so this distribution reaches Punk through its
# ordinary Perl surface by method dispatch (the Punk-Feed shape) and has no
# C header to consume.

# getentropy(2), for `punk challenge key`. Probed through the LINK, not
# compile-only: a compile probe passes on boxes whose libc headers declare
# what the linker cannot deliver (FreeBSD before 12), and the built .so
# then fails to load. Without it, /dev/urandom.
my $DEFINE = '';
{
    my $dir = "pchal_probe_$$";
    if (mkdir $dir) {
        for my $try ( [ 'sys/random.h', ' -DPCHAL_GETENTROPY_SYS_RANDOM' ],
                      [ 'unistd.h',     ''                               ] ) {
            my ($header, $extra) = @$try;
            my $src = "$dir/probe.c";
            open my $fh, '>', $src or next;
            print $fh "#include <$header>\n"
                    . "int main(void) { unsigned char b[16]; "
                    . "return getentropy(b, sizeof b); }\n";
            close $fh;
            my $cc = $Config{cc} || 'cc';
            if (system("$cc $src -o $dir/probe >/dev/null 2>&1") == 0) {
                $DEFINE .= ' -DPCHAL_HAVE_GETENTROPY' . $extra;
                print "Found getentropy (linked, not just compiled).\n";
                last;
            }
        }
        unlink "$dir/probe.c", "$dir/probe";
        rmdir $dir;
    }
    print "No getentropy; using /dev/urandom.\n" unless $DEFINE =~ /GETENTROPY/;
}

# MakeMaker tracks nothing under include/ or xs/, so an edit there would not
# rebuild without these.
my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', glob('include/pchal/*.h');

my %WriteMakefileArgs = (
    NAME             => 'Punk::Challenge',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Punk/Challenge.pm',
    ABSTRACT_FROM    => 'lib/Punk/Challenge.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More'   => '0',
        'Digest::SHA'  => '0',   # the oracle for the bundled SHA-256 and HMAC
        'MIME::Base64' => '0',   # the oracle for base64url
    },
    PREREQ_PM => {
        # The current release, not a measured minimum: nothing has
        # established where the set of methods this plugin uses starts.
        'Punk'     => '0.45',
        'XSLoader' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            license => ['http://www.opensource.org/licenses/artistic-license-2.0'],
        },
    },
    INC    => '-Iinclude',
    DEFINE => $DEFINE,
    XS     => { 'Challenge.xs' => 'Challenge.c' },
    OBJECT => 'Challenge$(OBJ_EXT)',
    depend => {
        'Challenge.c'         => $xs_deps,
        'Challenge$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Punk-Challenge-* Challenge.c Challenge.o Challenge.bs' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}
delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };
delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
