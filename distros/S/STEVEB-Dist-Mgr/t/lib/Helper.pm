package Helper;

use warnings;
use strict;

use Carp qw(croak);
use Exporter qw(import);
use File::Copy;
use File::Path qw(rmtree);
use Test::More;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    copy_ci_files
    copy_makefile
    copy_module_files
    copy_manifest_skip
    copy_git_ignore

    unlink_ci_files
    unlink_makefile
    unlink_module_files
    unlink_manifest_skip
    unlink_git_ignore

    remove_init
    remove_unwanted
    file_scalar
    trap_warn
    verify_clean
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

ok 1;

my $orig_dir        = 't/data/orig/';
my $work_dir        = 't/data/work/';
my $unwanted_dir    = 't/data/work/unwanted/';
my $init_dir        = 't/data/work/init/';

sub copy_ci_files {
    copy "$orig_dir/github_ci_default.yml", $work_dir or die $!;
}
sub copy_makefile {
    copy "$orig_dir/Makefile.PL", $work_dir or die $!;
}
sub copy_module_files {
    for (find_module_files($orig_dir)) {
        copy $_, $work_dir or die $!;
    }
}
sub copy_manifest_skip {
    copy "$orig_dir/MANIFEST.SKIP", $work_dir or die $!;
}
sub copy_git_ignore {
    copy "$orig_dir/.gitignore", $work_dir or die $!;
}

sub unlink_ci_files {
    if (-e "$work_dir/github_ci_default.yml") {
        unlink "$work_dir/github_ci_default.yml" or die $!;
    }
    is -e "$work_dir/github_ci_default.yml", undef, "temp github actions file deleted ok";
}
sub unlink_makefile {
    if (-e "$work_dir/Makefile.PL") {
        unlink "$work_dir/Makefile.PL" or die $!;
    }
    is -e "$work_dir/Makefile.PL", undef, "temp makefile deleted ok";
}
sub unlink_module_files {
    for (find_module_files($work_dir)) {
        if (-e $_) {
            unlink $_ or die $!;
        }
        is -e $_, undef, "unlinked $_ file ok";
    }
}
sub unlink_manifest_skip {
    if (-e "$work_dir/MANIFEST.SKIP") {
        unlink "$work_dir/MANIFEST.SKIP" or die $!;
    }
    is -e "$work_dir/MANIFEST.SKIP", undef, "temp MANIFEST.SKIP deleted ok";
}
sub unlink_git_ignore {
    if (-e "$work_dir/.gitignore") {
        unlink "$work_dir/.gitignore" or die $!;
    }
    is -e "$work_dir/.gitignore", undef, "temp .gitignore deleted ok";
}

sub file_scalar {
    my ($fname) = @_;
    my $contents;

    {
        local $/;
        open my $fh, '<', $fname or die $!;
        $contents = <$fh>;
    }
    return $contents;
}
sub find_module_files {
    my ($dir) = @_;

    croak("find_module_files() needs \$dir param") if ! defined $dir;

    return File::Find::Rule->file()
        ->name('*.pm')
        ->in($dir);
}
sub trap_warn {
    # enable/disable sinking our own internal warnings to prevent
    # cluttered test output

    my ($bool) = shift;

    croak("trap() needs a bool param") if ! defined $bool;

    if ($bool) {
        $SIG{__WARN__} = sub {
            my $w = shift;

            if ($w =~ /valid version/ || $w =~ /VERSION definition/) {
                return;
            }
            else {
                warn $w;
            }
        }
    }
    else {
        $SIG{__WARN__} = sub { warn shift; }
    }
}

sub remove_init {
    if (-e $init_dir) {
        is rmtree("$work_dir/init") >= 1, 1, "removed init dir structure ok";
    }
    is -e $init_dir, undef, "init dir removed ok";
}
sub remove_unwanted {
    if (-e $unwanted_dir) {
        is rmtree("$work_dir/unwanted") >= 1, 1, "removed unwanted dir structure ok";
    }
    is -e $unwanted_dir, undef, "unwanted dir removed ok";
}

sub verify_clean {
    is(scalar(find_module_files($work_dir)), 0, "all work module files unlinked ok");
}

1;