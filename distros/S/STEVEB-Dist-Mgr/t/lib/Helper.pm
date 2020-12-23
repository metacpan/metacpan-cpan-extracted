package Helper;

use warnings;
use strict;

use Carp qw(croak);
use Exporter qw(import);
use File::Copy;
use Test::More;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    copy_makefile
    unlink_makefile
    copy_module_files
    unlink_module_files
    file_scalar
    trap_warn
    verify_clean
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

ok 1;

my $orig_dir = 't/data/orig';
my $work_dir = 't/data/work';

sub copy_makefile {
    copy "$orig_dir/Makefile.PL", $work_dir or die $!;
}
sub copy_module_files {
    for (find_module_files($orig_dir)) {
        copy $_, $work_dir or die $!;
    }
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
sub verify_clean {
    is(scalar(find_module_files($work_dir)), 0, "all work module files unlinked ok");
}

1;