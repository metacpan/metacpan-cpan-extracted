use strict;
use warnings;
use Config;                 # $Config{cc}, for the probes below
use Cwd qw(abs_path);
use ExtUtils::MakeMaker;

my @PROVIDERS = (
    [ 'Punk::OpenTelemetry' => 'Punk-OpenTelemetry/include' ],  # otel_proto.h
);

my @GZ = grep { -f } (glob('root/static/*.js'), glob('root/static/*.css'));

my $NEEDED = 'otel_proto.h';

sub inc_dirs { my @d; push @d, $1 while $_[0] =~ /-I(\S+)/g; return @d }
sub has_header { my ($inc) = @_; -f "$_/$NEEDED" && return 1 for inc_dirs($inc); 0 }

my $INC = '-Iinclude';
{
    my @from_depends;
    my $dep;
    if (eval { require ExtUtils::Depends;
               $dep = ExtUtils::Depends->new('Punk::Observe',
                          map { $_->[0] } @PROVIDERS); 1 } && $dep) {
        my %v = $dep->get_makefile_vars;
        @from_depends = ($v{INC}) if $v{INC};
    }

    my $candidate = join ' ', $INC, @from_depends;
    if (has_header($candidate)) {
        $INC = $candidate;
        print "$NEEDED: from the installed Punk::OpenTelemetry.\n";
    }
}

my @DEFINE;
my $LIBS = '';

sub probe {
    my ($tag, $src, $libs) = @_;
    my $dir = "po_probe_$$";
    my $ok  = 0;
    if (mkdir $dir) {
        my $c = "$dir/probe.c";
        if (open my $fh, '>', $c) {
            print $fh $src;
            close $fh;
            my $cc  = $Config{cc} || 'cc';
            my $exe = "$dir/probe";
            # -Fe for MSVC, -o everywhere else: cl ignores -o and writes
            # probe.exe wherever it feels like, which a later unlink misses.
            my $out = $cc =~ /\bcl(?:\.exe)?\b/i ? "-Fe$exe" : "-o $exe";
            $ok = system("$cc $c $out $libs >" . File::Spec->devnull
                         . " 2>&1") == 0;
            unlink $c, $exe, "$dir/probe.obj", "$dir/probe.exe";
        }
        rmdir $dir;
    }
    return $ok;
}

require File::Spec;

{
    my $mk = sub {
        my ($clock) = @_;
        "#include <time.h>\n"
      . "int main(void){struct timespec t;return clock_gettime($clock,&t);}\n";
    };
    my $libs;
    for my $l ('', '-lrt') {
        if (probe('clock', $mk->('CLOCK_REALTIME'), $l)) { $libs = $l; last }
    }
    if (defined $libs) {
        push @DEFINE, '-DPO_HAVE_CLOCK_GETTIME';
        push @DEFINE, '-DPO_HAVE_CLOCK_MONOTONIC'
            if probe('mono', $mk->('CLOCK_MONOTONIC'), $libs);
        if (length $libs) {
            $LIBS = $libs;
            print "clock_gettime needs $libs (glibc < 2.17): linking it.\n";
        }
    }
    else {
        print "No clock_gettime; wall clock from gettimeofday.\n";
        print "  Durations will be wall-clock differences, which step.\n";
    }
}

push @DEFINE, '-DPO_HAVE_ATOMICS'
    if probe('atomics',
             "#include <stdint.h>\n"
           . "int main(void){uint64_t v=0;\n"
           . "__atomic_add_fetch(&v,1,__ATOMIC_SEQ_CST);\n"
           . "return (int)__atomic_load_n(&v,__ATOMIC_SEQ_CST)-1;}\n", '');

push @DEFINE, '-DPO_HAVE_CRC32C_X86'
    if probe('crc_x86',
             "#include <nmmintrin.h>\n#include <stdint.h>\n"
           . "int main(void){return (int)_mm_crc32_u64(0,1);}\n", '');

push @DEFINE, '-DPO_HAVE_CRC32C_ARM'
    if probe('crc_arm',
             "#include <arm_acle.h>\n#include <stdint.h>\n"
           . "int main(void){return (int)__crc32cd(0,1);}\n", '');

{
    my $src = "#include <zlib.h>\n"
            . "int main(void){z_stream s;s.zalloc=0;s.zfree=0;s.opaque=0;\n"
            . "return deflateInit2(&s,6,Z_DEFLATED,-15,8,Z_DEFAULT_STRATEGY)"
            . "==Z_OK?0:1;}\n";
    if (probe('zlib', $src, '-lz')) {
        push @DEFINE, '-DPO_HAVE_ZLIB';
        $LIBS = length $LIBS ? "$LIBS -lz" : '-lz';
    }
    else {
        print "No zlib: log blocks will be STORED uncompressed.\n";
    }
}

# The live tail's ring is Shared::Arena's, driven through its C ABI, so the
# header is sa_abi.h and the table is resolved at boot. A sibling checkout
# comes first, ahead of an installed copy, as everywhere in this workspace;
# Shared::Arena is REQUIRED (one code path, as Hyperman decided), so a build
# that finds neither stops here rather than shipping a tail that cannot
# cross workers.
{
    my $sa;
    my @sib = grep { -d } ('../Shared-Arena/include');
    my $inst = eval { require ExtUtils::Depends;
                      my $d = ExtUtils::Depends->new('Punk::Observe', 'Shared::Arena');
                      my %v = $d->get_makefile_vars;
                      $v{INC} } || '';
    for my $d (@sib, inc_dirs($inst)) {
        next unless -f "$d/sa_abi.h";
        $sa = $d;
        last;
    }
    die "Punk::Observe needs Shared::Arena 0.11 installed, or present as the "
      . "sibling ../Shared-Arena: its sa_abi.h is the live tail's ring.\n"
        unless $sa;
    $INC .= " -I$sa";
    push @DEFINE, '-DPO_HAVE_BUS';
    print "sa_abi.h: from $sa - the tail crosses workers.\n";
}

print "DEFINE:   @DEFINE\n" if @DEFINE;
print "LIBS:     $LIBS\n"   if length $LIBS;

my %PM;
{
    my @todo = ('lib');
    while (my $dir = shift @todo) {
        opendir my $dh, $dir or next;
        for my $e (sort readdir $dh) {
            next if $e eq '.' || $e eq '..';
            my $p = "$dir/$e";
            if    (-d $p)                 { push @todo, $p }
            elsif ($e =~ /\.(?:pm|pod)\z/) {
                (my $to = $p) =~ s{\Alib/}{\$(INST_LIB)/};
                $PM{$p} = $to;
            }
        }
    }
}

{
    my @todo = ('root');
    while (my $dir = shift @todo) {
        opendir my $dh, $dir or next;
        for my $e (sort readdir $dh) {
            next if $e eq '.' || $e eq '..';
            my $p = "$dir/$e";
            if (-d $p) { push @todo, $p; next }
            next if $p =~ /\.gz\z/;        # added below, existing or not
            (my $to = $p) =~ s{\Aroot/}{\$(INST_LIB)/Punk/Observe/root/};
            $PM{$p} = $to;
        }
    }
    for my $src (@GZ) {
        (my $to = "$src.gz") =~ s{\Aroot/}{\$(INST_LIB)/Punk/Observe/root/};
        $PM{"$src.gz"} = $to;
    }
}

# THE CHANGE SCRIPTS ARE THE SCHEMA, so they have to be installed with it.
#
# sqitch/ shipped in the tarball and was copied nowhere, which is the same
# bug root/ had: a checkout finds it at the top of the distribution and an
# installed copy has no DDL at all - so a host that installed this could not
# create the configuration store it needs.
#
# $(INST_LIB)/Punk/Observe/sqitch is where Backend::_project_dir looks first.
{
    my @todo = ('sqitch');
    while (my $dir = shift @todo) {
        opendir my $dh, $dir or next;
        for my $e (sort readdir $dh) {
            next if $e eq '.' || $e eq '..';
            my $p = "$dir/$e";
            if (-d $p) { push @todo, $p; next }
            (my $to = $p) =~ s{\Asqitch/}{\$(INST_LIB)/Punk/Observe/sqitch/};
            $PM{$p} = $to;
        }
    }
}

my %WriteMakefileArgs = (
    NAME             => 'Punk::Observe',
    PM               => \%PM,
    DEFINE           => join(' ', @DEFINE),
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Punk/Observe.pm',
    ABSTRACT_FROM    => 'lib/Punk/Observe.pm',
    LICENSE          => 'artistic_2',
    # Not Module::Starter's 5.008003, which is a lie for any modern XS dist.
    # This is the oldest perl the suite is actually run on.
    MIN_PERL_VERSION => '5.010000',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'   => '0',
        'ExtUtils::Depends'     => '0.404',
        'Punk::OpenTelemetry'   => '0.08',
    },
    TEST_REQUIRES    => { 'Test::More' => '0', 'IO::Compress::Gzip' => '0' },
    PREREQ_PM        => {
        'Punk::OpenTelemetry' => '0.08',   # otel_proto.h at build, decode at test
        'File::Raw::JSON'     => '0.06',   # the OTLP/JSON parse
        'IO::Uncompress::Gunzip' => '0',   # gzip request bodies
        'Hyperman' => '0.36',              # the server the tail runs under
        'Shared::Arena' => '0.11',         # the ring the tail crosses workers on
        # THE SCHEDULER FOR THE PERIODIC WORK. Compaction, retention, alert
        # evaluation and health polling are four cron tasks under one leader
        # lease, so they inherit election, restart, backoff and the admin UI
        # rather than reinventing four things. A host that would rather run
        # bin/punk-observe-health from system cron can - the binary exists for
        # exactly that - but the scheduled path is the supported one.
        'Punk::Queue' => '0.04',
        # The configuration store: dashboards, alert rules, check targets.
        # SQLite is the default because a self-hosted single node should not
        # have to stand up a server for a few dozen rows; DBD::Pg is NOT a
        # prerequisite and is loaded only by a dbi:Pg: dsn.
        'DBI'         => '1.614',   # AutoInactiveDestroy
        'DBD::SQLite' => '1.60',    # 3.8+ for partial indexes
        # The dashboard chunk cache. Optional in effect - every path
        # through it falls back to the plain query - but a dashboard
        # without it re-scans a settled day on every refresh.
        'Punk::Cache' => '0.34',
    },
    EXE_FILES        => [ 'bin/punk-observe-health',
                          'bin/punk-observe-retain',
                          'bin/punk-observe-warm' ],
    INC              => $INC,
    (length $LIBS ? (LIBS => [$LIBS]) : ()),
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Punk-Observe-* po_probe_*' },
    depend => {
        'Observe.c' => join(' ', glob('xs/*.xs')),
        'Observe.o' => join(' ', glob('include/punk_observe/*.h')),
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

# The precompressed siblings, as rules, so make's own dependency check is what
# decides whether one is stale. pm_to_blib is made to wait on them because it
# is the step that copies them into blib, and a copy that runs first copies
# either nothing or the previous contents.
sub MY::postamble {
    return '' unless @GZ;
    my @rules;
    for my $src (@GZ) {
        push @rules, "$src.gz : $src tools/gzip-asset.pl\n"
                   . "\t\$(PERLRUN) tools/gzip-asset.pl $src $src.gz\n";
    }
    return join("\n", "PO_GZ = " . join(' ', map { "$_.gz" } @GZ), '',
                      'pm_to_blib : $(PO_GZ)', '', @rules);
}

WriteMakefile(%WriteMakefileArgs);
