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
    [ 'DBIx::Loop'      => '../DBIx-Loop/include'       ],  # dbil_abi.h
);

my $INC = '-Iinclude';
{
    my $dep;
    if (eval { $dep = ExtUtils::Depends->new('Punk::OpenTelemetry',
                          map { $_->[0] } @PROVIDERS); 1 } && $dep) {
        my %v = $dep->get_makefile_vars;
        # A SIBLING CHECKOUT COMES FIRST, ahead of whatever is installed.
        #
        # Punk's own Makefile.PL has done this for the same reason: otherwise
        # a development tree compiles against the last INSTALLED header while
        # declaring a dependency on something newer, and the two never meet.
        # PREREQ_PM checks a .pm's $VERSION and the C comes from that dist's
        # Install/ directory, so this can require Punk 0.50 for current_of,
        # build against 0.49's pk_abi.h, and fail on a struct member the
        # version it asked for does have. The failure names the member, not
        # the stale header, which is a long way from the cause.
        #
        # With no sibling directories present this adds no paths at all.
        my @sib = grep { -d $_->[1] } @PROVIDERS;
        $INC .= join '', map { " -I$_->[1]" } @sib if @sib;
        $INC .= ' ' . $v{INC} if $v{INC};
    }
    else {
        my @missing = grep { !-d $_->[1] } @PROVIDERS;
        die "Punk::OpenTelemetry needs " . join(', ', map { $_->[0] } @missing)
          . " installed, or present as sibling directories.\n" if @missing;
        $INC .= join '', map { " -I$_->[1]" } @PROVIDERS;
    }
}

# PROVIDER SIDE, and until 0.08 there was not one.
#
# This distribution owns the OTLP field numbers, and Punk::Observe reads them
# rather than keeping a second copy: two sources of truth for a field number
# is the one thing that must not happen across a wire format. The client
# writing field 9 and the server reading field 9 as something else produces
# plausible wrong data, silently, with no error anywhere.
#
# But asking ExtUtils::Depends for those numbers only works if this dist
# ANSWERS, and it never did: it used ExtUtils::Depends purely as a consumer,
# installed no headers, and wrote no Install/Files.pm. So every consumer fell
# through to the sibling-checkout branch, and anyone building from a released
# tarball outside the source tree was told the dependency was "neither
# installed nor findable" while holding a correctly installed copy of it.
#
# ONLY otel_proto.h IS PUBLISHED. The rest of include/ is this dist's own
# working surface, and installing it would make every one of those headers a
# compatibility commitment - the append-only rule applies to what is
# published, not to what exists.
#
# A SEPARATE OBJECT FROM THE CONSUMER ONE ABOVE, and that is the whole point
# rather than tidiness. ExtUtils::Depends records its dependency list into the
# file it writes, so publishing through the object that names Fetch, Punk,
# Hyperman and File::Raw::JSON would declare all four - and their transitive
# closure, which here came to fourteen distributions - as things a consumer
# must also have installed. Reading a field number would then require the
# whole client stack.
#
# otel_proto.h includes nothing and needs nothing. What is published says so.
my $provider = ExtUtils::Depends->new('Punk::OpenTelemetry');
$provider->install('include/otel_proto.h');
mkdir 'Install' unless -d 'Install';
$provider->save_config('Install/Files.pm');

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
}

# clock_gettime, for span timestamps and durations. Two questions, both put
# to the LINKER (see the getentropy note above): does clock_gettime link at
# all, and does it need -lrt to do so. glibc before 2.17 keeps it in librt,
# so a plain probe fails there and the built .so loads with "undefined
# symbol: clock_gettime" (CPAN Testers, Debian wheezy, 0.04 on 5.20-5.24),
# while macOS and the BSDs have no librt at all - so -lrt is added only when
# it is what makes the probe link. Without clock_gettime the wall clock comes
# from gettimeofday; without CLOCK_MONOTONIC a duration is two wall-clock
# reads clamped at zero (see otel_clock.h).
my $LIBS = '';
{
    my $dir = "otel_clk_$$";
    my $cc  = $Config{cc} || 'cc';
    my $try = sub {
        my ($clock, $libs) = @_;
        my $src = "$dir/probe.c";
        open my $fh, '>', $src or return 0;
        print $fh "#include <time.h>\n"
            . "int main(void){struct timespec t;"
            . "return clock_gettime($clock,&t);}\n";
        close $fh;
        my $ok = system("$cc $src -o $dir/probe $libs >/dev/null 2>&1") == 0;
        unlink $src, "$dir/probe";
        return $ok;
    };
    if (mkdir $dir) {
        my $libs;
        for my $l ('', '-lrt') {
            if ($try->('CLOCK_REALTIME', $l)) { $libs = $l; last }
        }
        if (defined $libs) {
            push @DEFINE, '-DOTEL_HAVE_CLOCK_GETTIME';
            push @DEFINE, '-DOTEL_HAVE_CLOCK_MONOTONIC'
                if $try->('CLOCK_MONOTONIC', $libs);
            if (length $libs) {
                $LIBS = $libs;
                print "clock_gettime needs $libs (old glibc): linking it.\n";
            }
        }
        else {
            print "No clock_gettime; using gettimeofday.\n";
        }
        rmdir $dir;
    }
}
print "DEFINE:   @DEFINE\n" if @DEFINE;
print "LIBS:     $LIBS\n"   if length $LIBS;

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

# As a provider, get_makefile_vars returns a PM map - otel_proto.h and
# Files.pm - and naming PM ourselves would REPLACE it. Merged rather than
# either one winning: dropping theirs installs no header, dropping ours
# installs no modules.
my %dep_vars = $provider->get_makefile_vars;
@PM{ keys %{ $dep_vars{PM} || {} } } = values %{ $dep_vars{PM} || {} };
delete $dep_vars{PM};
# The INC above is already the full answer, including the sibling case that
# ExtUtils::Depends knows nothing about.
delete $dep_vars{INC};

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
        # 0.34 for pk_abi v4. The BUILD needs it whatever the runtime does:
        # the vendored header is where the on_log_ctx slot is declared, and a
        # 0.20 header will not compile the call. The runtime still checks
        # abi_version, so a process that loaded an older Punk degrades rather
        # than misbehaves.
        'Punk'                => '0.50',   # pk_abi v5: current_of
        'Hyperman'            => '0.26',   # provides hm_abi.h (v4 worker start)
        # dbil_abi.h, for the DBIx::Loop statement observer. A BUILD
        # requirement because otel_consume.h includes the header, even though
        # the table is resolved at runtime and a process without DBIx::Loop
        # simply has nothing of that kind to instrument. Punk already requires
        # it, so this costs nothing and is declared rather than inherited.
        'DBIx::Loop'          => '0.07',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'File::Raw::JSON' => '0.06',   # OTLP/JSON encoding
        'Fetch'           => '0.15',   # the OTLP/HTTP client; h2 trailers for gRPC
        'Punk'            => '0.50',   # pk_abi v5: a child span can find its parent
        'Hyperman'        => '0.26',   # hm_abi: the post-fork worker hook
        'DBIx::Loop'      => '0.07',   # dbil_abi v2: the statement observer
    },
    INC    => $INC,
    (length $LIBS ? (LIBS => [$LIBS]) : ()),
    macro  => { TARFLAGS => "--format=ustar -c -v -f" },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'Punk-OpenTelemetry-* Install/Files.pm' },
    # MakeMaker maps OpenTelemetry.xs -> .c and does not rescan the INCLUDE:
    # fragments or the C headers, so force a regenerate when either changes.
    depend => {
        'OpenTelemetry.c' => join(' ', glob('xs/*.xs')),
        'OpenTelemetry.o' => join(' ', glob('include/*.h')),
    },
    %dep_vars,
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
