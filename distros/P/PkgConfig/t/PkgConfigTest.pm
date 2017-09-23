#!perl
package PkgConfigTest;
use strict;
use warnings;
use Config;
use Test::More;
use File::Basename;
use Data::Dumper;
use File::Spec;
use File::Basename qw(fileparse);
use Config;
use Cwd qw( cwd chdir );
use FindBin ();
use Exporter;
our @ISA = qw( Exporter );

$ENV{PKG_CONFIG_NO_OS_CUSTOMIZATION} = 1;

our @EXPORT = qw(
    expect_flags run_common $RV $S);

my @PC_PATHS = qw(data/usr/lib/pkgconfig data/usr/share/pkgconfig
                data/usr/local/lib/pkgconfig data/usr/local/share/pkgconfig);
                


my $TARBALL = File::Spec->catfile($FindBin::Bin, 'pc_files.tar.gz');
my $LOCK    = File::Spec->catfile($FindBin::Bin, 'pc_files.lock');
@PC_PATHS = map { $FindBin::Bin . "/$_" } @PC_PATHS;
@PC_PATHS = map {
    my @components = split(/\//, $_);
    $_ = File::Spec->catfile(@components);
    $_;
} @PC_PATHS;
    
note Dumper(\@PC_PATHS);

$ENV{PKG_CONFIG_PATH} = join($Config{path_sep}, @PC_PATHS);

our $RV;
our $S;

my $SCRIPT = "$FindBin::Bin/../script/ppkg-config";

# Work around git on windows' lamentable lack of symbolic
# link support
$SCRIPT = $FindBin::Bin . "/../lib/PkgConfig.pm"
    if $^O eq 'MSWin32' && -d '.git';

sub run_common {
    my @args = @_;
    (my $ret = qx($^X $SCRIPT --env-only @args))
        =~ s/(?:^\s+)|($?:\s+$)//g;
    $RV = $?;
    $S = $ret;
}

sub expect_flags {
    my ($flags,$msg) = @_;
    like($S, qr/\Q$flags\E/, $msg);
}

sub run_exists_test {
    my ($flist,$pmfile) = @_;
    note "$pmfile: Will perform --exist tests";
    foreach my $fname (@$flist) {
        next unless -f $fname;
        my ($base) = fileparse($fname, ".pc");
        run_common("$base");
        ok($RV == 0, "Package $base exists");
    }
}

sub _single_flags_test {
    my $fname = shift;
    return unless -f $fname;
    my ($base) = fileparse($fname, ".pc");
    run_common("--libs --cflags $base --define-variable=prefix=blah");
    ok($RV == 0, "Got OK for --libs and --cflags");
    if($S =~ /-(?:L|I)/) {
        if($S !~ /blah/) {
            
            #these files define $prefix, but don't actually use them for
            #flags:
            if($base =~ /^(?:glu?|libconfig)$/) {
                note "Skipping gl pcfiles which define but do not use 'prefix'";
                return;
            }
            
            #Check the file, see if it at all has a '$prefix'
            open my $fh, "<", $fname;
            if(!defined $fh) {
                note "$fname: $!";
                return;
            }
            
            my @lines = <$fh>;
            if(grep /\$\{prefix\}/, @lines) {
                ok(0, "Expected substituted prefix for $base");
            } else {
                note "File $fname has no \${prefix} directive";
            }
            return;
        }
        ok($S =~ /blah/, "Found modified prefix for $base");
    }
}

sub run_flags_test {
    my ($flist,$pmfile) = @_;
    note "$pmfile: Will perform --prefix, --cflags, and --libs tests";
    foreach my $fname (@$flist) {
        _single_flags_test($fname);
    }
}

1;
