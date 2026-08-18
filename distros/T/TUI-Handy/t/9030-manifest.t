use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/9030-manifest.t - MANIFEST integrity:
#   * MANIFEST exists and its first line is the primary module.
#   * every source file on disk (lib/*.pm, t/*.t, t/lib/*.pm, eg/*.pl) is
#     listed in MANIFEST.
# The pmake-generated files (Makefile.PL, META.*, LICENSE, CONTRIBUTING,
# SECURITY.md) are created at 'pmake dist' time, so their presence on disk
# is not required here.
#
# This is the distribution's own, stricter form of INA_CPAN_Check check_A,
# so t/9000-ina-cpan-check.t does not call check_A as well.

use lib 't/lib';
use INA_CPAN_Check;

sub read_manifest {
    local *FH;
    open(FH, "<MANIFEST") or return ();
    my @f;
    while (<FH>) {
        chomp;
        s/\r\z//;         # a MANIFEST written on Windows, read on Unix
        s/\s+#.*$//;
        s/^\s+//; s/\s+$//;
        next if $_ eq '';
        push @f, $_;
    }
    close FH;
    return @f;
}

# Directory separators are normalised to '/' so that the comparison against
# MANIFEST (which always uses '/') holds on Windows as well.
sub find_sources {
    my @src;
    _walk('lib', \@src, qr/\.pm$/) if -d 'lib';
    _walk('t',   \@src, qr/\.(?:t|pm)$/) if -d 't';
    _walk('eg',  \@src, qr/\.pl$/) if -d 'eg';
    for my $p (@src) {
        $p =~ s{\\}{/}g;
    }
    return @src;
}

sub _walk {
    my ($dir, $acc, $re) = @_;
    local *D;
    opendir(D, $dir) or return;
    my @e = sort readdir(D);
    closedir(D);
    for my $e (@e) {
        next if $e eq '.' || $e eq '..';
        my $p = "$dir/$e";
        if (-d $p) {
            _walk($p, $acc, $re);
        }
        elsif ($p =~ $re) {
            push @$acc, $p;
        }
    }
}

my @manifest = read_manifest();
my %in_manifest;
for my $f (@manifest) {
    $in_manifest{$f} = 1;
}

my @sources = find_sources();

my @tests = (
    sub { ok(scalar(@manifest) > 0, 'MANIFEST is readable and non-empty') },
    sub { ok(defined($manifest[0]) && $manifest[0] eq 'lib/TUI/Handy.pm',
             'first MANIFEST line is lib/TUI/Handy.pm') },
    sub { ok($in_manifest{'MANIFEST'}, 'MANIFEST lists itself') },
    sub { ok($in_manifest{'README'},   'MANIFEST lists README') },
    sub { ok($in_manifest{'Changes'},  'MANIFEST lists Changes') },
    sub { ok($in_manifest{'pmake.bat'}, 'MANIFEST lists pmake.bat') },
    sub { ok($in_manifest{'t/lib/INA_CPAN_Check.pm'},
             'MANIFEST lists t/lib/INA_CPAN_Check.pm') },
);

for my $file (@sources) {
    my $f = $file;
    push @tests, sub {
        ok($in_manifest{$f}, "source $f is listed in MANIFEST");
    };
}

plan_tests(scalar(@tests));
for my $x (@tests) {
    $x->();
}
