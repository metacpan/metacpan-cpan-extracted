use 5.010;
use strict;
use warnings;
use Config;                 # $Config{cc}, for the getentropy probe below
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

# The providers whose C ABIs this dist calls through. Same arrangement Punk
# itself uses: ExtUtils::Depends when they are installed, sibling include
# directories when this is a checkout beside them.
my @PROVIDERS = (
    [ 'File::Raw::JSON' => '../File-Raw-JSON/include'  ],  # frj_abi.h
    [ 'Fetch'           => '../Fetch/include/fetch'    ],  # fetch_abi.h
    [ 'Punk'            => '../Punk/include'           ],  # pk_abi.h
    [ 'Hyperman'        => '../Hyperman/include/hyperman' ], # hm_abi.h
);

my $INC = '-Iinclude';
{
    my $dep;
    if (eval { $dep = ExtUtils::Depends->new('Punk::OpenTelemetry',
                          map { $_->[0] } @PROVIDERS); 1 } && $dep) {
        my %v = $dep->get_makefile_vars;
        $INC .= ' ' . $v{INC} if $v{INC};
    }
    else {
        my @missing = grep { !-d $_->[1] } @PROVIDERS;
        die "Punk::OpenTelemetry needs " . join(', ', map { $_->[0] } @missing)
          . " installed, or present as sibling directories.\n" if @missing;
        $INC .= join '', map { " -I$_->[1]" } @PROVIDERS;
    }
}

# getentropy(2), for trace and span ids - macOS 10.12+, glibc 2.25+, the BSDs.
# Declared in <sys/random.h> on macOS and <unistd.h> on glibc, so both are
# probed. Without it otel_id.h falls back to a cached /dev/urandom descriptor,
# so this is a convenience rather than a requirement.
#
# The probe must LINK, not merely compile. FreeBSD before 12 has no getentropy
# in libc and declares nothing, and its old compilers take the implicit
# declaration as a warning - so a compile-only probe false-positives and the
# built .so fails to load with "Undefined symbol getentropy". Punk learned
# this from CPAN Testers the expensive way; only the linker asks libc the real
# question, so this is the same probe rather than a fresh guess.
my @DEFINE;
{
    my $dir = "otel_probe_$$";
    if (mkdir $dir) {
        for my $try ( [ 'sys/random.h', '-DOTEL_GETENTROPY_SYS_RANDOM' ],
                      [ 'unistd.h',     ''                             ] ) {
            my ($header, $extra) = @$try;
            my $src = "$dir/probe.c";
            open my $fh, '>', $src or next;
            print $fh "#include <$header>\n"
                . "int main(void) { char b[4]; return getentropy(b, 4); }\n";
            close $fh;
            my $cc = $Config{cc} || 'cc';
            if (system("$cc $src -o $dir/probe >/dev/null 2>&1") == 0) {
                push @DEFINE, '-DOTEL_HAVE_GETENTROPY';
                push @DEFINE, $extra if length $extra;
                unlink $src, "$dir/probe";
                last;
            }
            unlink $src, "$dir/probe";
        }
        rmdir $dir;
    }
    print "DEFINE:   @DEFINE\n" if @DEFINE;
}

# CLOCK_MONOTONIC, for span durations. A span measured with two wall-clock
# reads goes backwards across an NTP step; see otel_clock.h.
{
    my $dir = "otel_clk_$$";
    if (mkdir $dir) {
        my $src = "$dir/probe.c";
        if (open my $fh, '>', $src) {
            print $fh "#include <time.h>\n"
                . "int main(void){struct timespec t;"
                . "return clock_gettime(CLOCK_MONOTONIC,&t);}\n";
            close $fh;
            my $cc = $Config{cc} || 'cc';
            push @DEFINE, '-DOTEL_HAVE_CLOCK_MONOTONIC'
                if system("$cc $src -o $dir/probe >/dev/null 2>&1") == 0;
            unlink $src, "$dir/probe";
        }
        rmdir $dir;
    }
}

# The shipped semantic-convention schema file has to be INSTALLED, and
# MakeMaker's default PM map only picks up .pm and .pod - a .yaml under lib/
# is silently left behind, so the converter works from a checkout and fails
# once installed, which is the worst order to find out.
#
# Naming PM replaces that default map entirely, so it is built by walking
# lib/ rather than typed out: a hand-written list is the documented way to
# lose a module (see Open::API's Makefile.PL, which says so from experience).
my %PM;
{
    my @todo = ('lib');
    while (my $dir = shift @todo) {
        opendir my $dh, $dir or next;
        for my $e (sort readdir $dh) {
            next if $e eq '.' || $e eq '..';
            my $p = "$dir/$e";
            if    (-d $p)                      { push @todo, $p }
            elsif ($e =~ /\.(?:pm|pod|yaml)\z/) {
                (my $to = $p) =~ s{\Alib/}{\$(INST_LIB)/};
                $PM{$p} = $to;
            }
        }
    }
}

my %WriteMakefileArgs = (
    NAME             => 'Punk::OpenTelemetry',
    PM               => \%PM,
    DEFINE           => join(' ', @DEFINE),
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Punk/OpenTelemetry.pm',
    ABSTRACT_FROM    => 'lib/Punk/OpenTelemetry.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010000',
    # Needed at CONFIGURE time, not just build time: the block above asks
    # ExtUtils::Depends for their installed headers before it can write a
    # Makefile, and PREREQ_PM is only honoured afterwards.
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw::JSON'     => '0.06',   # provides frj_abi.h
        'Fetch'               => '0.15',   # fetch_abi v2 + HTTP/2 trailers
        'Punk'                => '0.20',   # provides pk_abi.h
        'Hyperman'            => '0.26',   # provides hm_abi.h (v4 worker start)
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'File::Raw::JSON' => '0.06',   # OTLP/JSON encoding
        'Fetch'           => '0.15',   # the OTLP/HTTP client; h2 trailers for gRPC
        'Punk'            => '0.20',   # pk_abi: request/response/query observers
        'Hyperman'        => '0.26',   # hm_abi: the post-fork worker hook
    },
    INC    => $INC,
    macro  => { TARFLAGS => "--format=ustar -c -v -f" },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'Punk-OpenTelemetry-*' },
    # MakeMaker maps OpenTelemetry.xs -> .c and does not rescan the INCLUDE:
    # fragments or the C headers, so force a regenerate when either changes.
    depend => {
        'OpenTelemetry.c' => join(' ', glob('xs/*.xs')),
        'OpenTelemetry.o' => join(' ', glob('include/*.h')),
    },
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $tr = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$tr} = values %$tr;
}
delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
