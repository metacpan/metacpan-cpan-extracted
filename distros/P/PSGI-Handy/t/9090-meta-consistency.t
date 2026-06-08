######################################################################
# 9090-meta-consistency.t - cross-check the distribution metadata.
#
# Verifies that Makefile.PL, META.yml and META.json agree on the dist
# name, version and abstract; that the two META files declare the same
# prerequisite modules and the same provides set; that every shipped
# lib/*.pm is advertised in provides; and that every non-core module
# actually used by lib/ is declared as a prerequisite
# (prereq_matches_use). These are the checks a reviewer runs by hand
# before a CPAN upload; this file makes them automatic.
#
# Portable: drop into any distribution's t/. It uses no non-core
# modules, so it runs unchanged on Perl 5.005_03 and later. META.json is
# read with lightweight pattern matching (no JSON parser, which 5.005_03
# lacks); this is sufficient for the well-formed META that toolchains
# emit.
#
# ina closure-array pattern: one assertion per closure; the plan count is
# derived from scalar(@tests) and never hard-coded.
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();

my $ROOT = "$FindBin::Bin/..";

# --- minimal TAP helpers --------------------------------------------
my $count = 0;
sub ok {
    my ($cond, $label) = @_;
    $count++;
    print(($cond ? "ok" : "not ok") . " $count - " . (defined $label ? $label : '') . "\n");
    return $cond;
}

sub slurp {
    my ($path) = @_;
    local *FH;
    open(FH, "< $path") or return undef;
    binmode FH;
    local $/;
    my $data = <FH>;
    close(FH);
    return $data;
}

# Modules shipped with Perl (pragmas + core) that never need to be
# declared as prerequisites. Conservative: anything outside this set and
# outside the distribution itself must appear in the prereqs.
my %CORE = map { $_ => 1 } qw(
    strict warnings vars subs constant lib integer overload base fields
    attributes utf8 re bytes
    Carp Exporter Symbol Cwd Config DynaLoader AutoLoader SelfLoader
    Fcntl Errno POSIX Socket Benchmark
    File::Spec File::Basename File::Path File::Copy File::Find File::Glob
    FindBin Getopt::Long Getopt::Std
    IO IO::Handle IO::File IO::Seekable IO::Socket IO::Select
    Sys::Hostname Time::Local Data::Dumper
    Test Test::Harness ExtUtils::MakeMaker ExtUtils::Manifest
    Tie::Hash Tie::Array Tie::Scalar Tie::RefHash
);

# --- MANIFEST, lib modules, main module -----------------------------
my $manifest = slurp("$ROOT/MANIFEST");
$manifest = '' unless defined $manifest;
my @manifest;
my $ml;
for $ml (split /\n/, $manifest) {
    $ml =~ s/\r$//;
    $ml =~ s/\s+.*$//;               # strip optional comment after the path
    push @manifest, $ml if $ml =~ /\S/;
}
my @lib_pm = grep { m{^lib/.+\.pm$} } @manifest;

# package name for a lib path:  lib/Foo/Bar.pm -> Foo::Bar
sub path_to_pkg {
    my ($p) = @_;
    $p =~ s{^lib/}{};
    $p =~ s{\.pm$}{};
    $p =~ s{/}{::}g;
    return $p;
}
my %indist;
my $lp;
for $lp (@lib_pm) { $indist{ path_to_pkg($lp) } = 1; }

# main module = MANIFEST line 1 (ina convention)
my $main_pm = $lib_pm[0];
my $main_ver_pm = '';
if (defined $main_pm) {
    my $src = slurp("$ROOT/$main_pm");
    $src = '' unless defined $src;
    $main_ver_pm = $1 if $src =~ /\$VERSION\s*=\s*['"]([0-9._]+)['"]/;
}

# --- read the three metadata files ----------------------------------
my $mk   = slurp("$ROOT/Makefile.PL");
my $yml  = slurp("$ROOT/META.yml");
my $json = slurp("$ROOT/META.json");

# --- Makefile.PL fields ---------------------------------------------
sub mk_field {
    my ($src, $key) = @_;
    return '' unless defined $src;
    return $1 if $src =~ /\b\Q$key\E\b['"]?\s*=>\s*q\{([^}]*)\}/;
    return $1 if $src =~ /\b\Q$key\E\b['"]?\s*=>\s*'([^']*)'/;
    return $1 if $src =~ /\b\Q$key\E\b['"]?\s*=>\s*"([^"]*)"/;
    return '';
}
my $mk_name = mk_field($mk, 'NAME');
my $mk_ver  = mk_field($mk, 'VERSION');

# normalise a module/dist name to dash form: Foo::Bar -> Foo-Bar
sub dashed {
    my ($n) = @_;
    $n = '' unless defined $n;
    $n =~ s/::/-/g;
    return $n;
}

# --- META.yml fields ------------------------------------------------
sub yml_scalar {
    my ($src, $key) = @_;
    return '' unless defined $src;
    return $1 if $src =~ /^\Q$key\E:[ \t]*(.+?)[ \t]*$/m;
    return '';
}
my $yml_name = yml_scalar($yml, 'name');
my $yml_ver  = yml_scalar($yml, 'version');
my $yml_abs  = yml_scalar($yml, 'abstract');

# module names under requires/build_requires/configure_requires/
# recommends/suggests in a block-style META.yml
sub yml_prereq_modules {
    my ($src) = @_;
    my %mod;
    return { %mod } unless defined $src;
    my $in = 0;
    my $line;
    for $line (split /\n/, $src) {
        $line =~ s/\r$//;
        if ($line =~ /^(?:requires|build_requires|configure_requires|recommends|suggests):[ \t]*$/) {
            $in = 1;
            next;
        }
        next unless $in;
        if ($line =~ /^[ \t]+([A-Za-z_][\w]*(?:::[\w]+)*):[ \t]*\S/) {
            $mod{$1} = 1;
        }
        elsif ($line =~ /^\S/) {
            $in = 0;
        }
    }
    return { %mod };
}
my $yml_pre = yml_prereq_modules($yml);

sub yml_provides {
    my ($src) = @_;
    my %p;
    return { %p } unless defined $src;
    my $in = 0;
    my $line;
    for $line (split /\n/, $src) {
        $line =~ s/\r$//;
        if ($line =~ /^provides:[ \t]*$/) { $in = 1; next; }
        next unless $in;
        if ($line =~ /^  ([A-Za-z_][\w]*(?:::[\w]+)*):[ \t]*$/) {
            $p{$1} = 1;
        }
        elsif ($line =~ /^\S/) {
            $in = 0;
        }
    }
    return { %p };
}
my $yml_prov = yml_provides($yml);

# --- META.json fields (lightweight, no JSON parser) -----------------
sub json_scalar {
    my ($src, $key) = @_;
    return '' unless defined $src;
    return $1 if $src =~ /"\Q$key\E"[ \t]*:[ \t]*"([^"]*)"/;
    return '';
}
my $json_name = json_scalar($json, 'name');
my $json_ver  = json_scalar($json, 'version');
my $json_abs  = json_scalar($json, 'abstract');

# text region from the key "$from" up to the key "$to" (or end)
sub json_region {
    my ($src, $from, $to) = @_;
    return '' unless defined $src;
    my $i = index($src, '"' . $from . '"');
    return '' if $i < 0;
    my $j = index($src, '"' . $to . '"', $i + 1);
    $j = length($src) if $j < 0;
    return substr($src, $i, $j - $i);
}

# prereq modules = string-valued keys inside the prereqs region
sub json_prereq_modules {
    my ($src) = @_;
    my %mod;
    my $region = json_region($src, 'prereqs', 'provides');
    while ($region =~ /"([A-Za-z_][\w]*(?:::[\w]+)*)"[ \t]*:[ \t]*"/g) {
        $mod{$1} = 1;
    }
    return { %mod };
}
my $json_pre = json_prereq_modules($json);

# provides modules = object-valued keys inside the provides region
sub json_provides {
    my ($src) = @_;
    my %p;
    return { %p } unless defined $src;
    my $i = index($src, '"provides"');
    return { %p } if $i < 0;
    my $region = substr($src, $i);
    while ($region =~ /"([A-Za-z_][\w]*(?:::[\w]+)*)"[ \t]*:[ \t]*\{/g) {
        $p{$1} = 1;
    }
    delete $p{'provides'};           # drop the wrapper key itself
    return { %p };
}
my $json_prov = json_provides($json);

# --- set helpers ----------------------------------------------------
sub keys_sorted {
    my ($h) = @_;
    return join(',', sort keys %$h);
}
sub set_equal {
    my ($a, $b) = @_;
    return (keys_sorted($a) eq keys_sorted($b)) ? 1 : 0;
}

# modules used (use/require) in a piece of code, POD/trailer stripped
sub used_modules {
    my ($src) = @_;
    my %u;
    return { %u } unless defined $src;
    $src =~ s/\n__END__\b.*\z//s;
    my $line;
    for $line (split /\n/, $src) {
        next if $line =~ /^[ \t]*#/;
        if ($line =~ /^[ \t]*(?:use|require)[ \t]+([A-Za-z_][\w]*(?:::[\w]+)*)/) {
            $u{$1} = 1;
        }
    }
    return { %u };
}

# --- build the assertions -------------------------------------------
my @tests;

if (!defined $yml && !defined $json) {
    push @tests, sub { ok(1, 'no META.yml or META.json present (skipped)'); };
}
else {
    push @tests, sub { ok(defined($yml)  && length($yml),  'META.yml present and non-empty'); };
    push @tests, sub { ok(defined($json) && length($json), 'META.json present and non-empty'); };

    # name agreement (Makefile NAME is :: form; META names are dash form)
    push @tests, sub {
        my $a = dashed($mk_name);
        my $good = ($a ne '' && $a eq $yml_name && $a eq $json_name) ? 1 : 0;
        ok($good, "dist name agrees (Makefile=$a yml=$yml_name json=$json_name)");
    };

    # version agreement across all four sources
    push @tests, sub {
        my $good = ($mk_ver ne ''
                    && $mk_ver eq $yml_ver
                    && $mk_ver eq $json_ver
                    && ($main_ver_pm eq '' || $main_ver_pm eq $mk_ver)) ? 1 : 0;
        ok($good, "version agrees (Makefile=$mk_ver yml=$yml_ver json=$json_ver pm=$main_ver_pm)");
    };

    # abstract agreement between the two META files
    push @tests, sub {
        ok($yml_abs ne '' && $yml_abs eq $json_abs,
           'abstract agrees between META.yml and META.json');
    };

    # prereq module set parity (catches a module declared in one file only)
    push @tests, sub {
        my $good = set_equal($yml_pre, $json_pre);
        ok($good, 'prereq module set agrees between META.yml and META.json'
                  . ($good ? '' : ' (yml=[' . keys_sorted($yml_pre)
                               . '] json=[' . keys_sorted($json_pre) . '])'));
    };

    # provides parity between the two META files
    push @tests, sub {
        my $good = set_equal($yml_prov, $json_prov);
        ok($good, 'provides set agrees between META.yml and META.json'
                  . ($good ? '' : ' (yml=[' . keys_sorted($yml_prov)
                               . '] json=[' . keys_sorted($json_prov) . '])'));
    };

    # every lib/*.pm is advertised in provides
    my $pm;
    for $pm (@lib_pm) {
        my $pkg = path_to_pkg($pm);
        push @tests, sub {
            ok($json_prov->{$pkg}, "provides lists $pkg ($pm)");
        };
    }

    # prereq_matches_use: lib modules must declare their non-core deps
    for $pm (@lib_pm) {
        push @tests, sub {
            my $src  = slurp("$ROOT/$pm");
            my $used = used_modules($src);
            my @miss;
            my $m;
            for $m (sort keys %$used) {
                next if $CORE{$m};
                next if $indist{$m};
                next if $json_pre->{$m};
                push @miss, $m;
            }
            ok(!@miss, "prereq_matches_use: $pm"
                       . (@miss ? ' (undeclared: ' . join(', ', @miss) . ')' : ''));
        };
    }
}

print "1.." . scalar(@tests) . "\n";
my $t;
for $t (@tests) {
    $t->();
}
