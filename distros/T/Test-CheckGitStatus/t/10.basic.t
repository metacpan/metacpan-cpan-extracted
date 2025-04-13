use Test::More;
use strict;
use warnings;
use FindBin '$Bin';

use File::Temp;
use Test::CheckGitStatus;

my $tmp = File::Temp->newdir("Test-CheckGitStatus-XXXX", TMPDIR => 1);
my $git = Test::CheckGitStatus::_check_git();

subtest 'git status' => sub {
    plan skip_all => 'git not installed' unless $git;
    # Don't let git use any personal settings
    local $ENV{HOME};

    my $dir = "$tmp/repo";
    mkdir $dir;
    _write_file("$dir/file1");

    my $cmd = "$git -C $dir";
    note qx{$cmd init --quiet 2>&1};
    note qx{$cmd add . 2>&1};
    note qx{$cmd config user.email 'name\@example.org'};
    note qx{$cmd config user.name 'Name'};
    note qx{$cmd commit --quiet -m "test" 2>&1};

    local $ENV{CHECK_GIT_STATUS} = 1;
    chdir $dir;
    my $out = qx{perl -wE'use Test::CheckGitStatus;' 2>&1};
    my $rc = $?;
    is $rc, 0, "clean status exit code 0";
    is $out, '', "clean status";

    _write_file("$dir/file2");
    $out = qx{perl -wE'use Test::CheckGitStatus;' 2>&1};
    $rc = $? >> 8;
    is $rc, 1, "untracked file exit code";
    like $out, qr{Error.*\?\? file2}s, "untracked file";
    unlink "$dir/file2";

    _write_file("$dir/file1", "new");
    $out = qx{perl -wE'use Test::CheckGitStatus;' 2>&1};
    $rc = $? >> 8;
    is $rc, 1, "modified file exit code";
    like $out, qr{Error.*M file1}s, "modified file";
};

sub _write_file {
    my ($file, $content) = @_;
    $content ||= 'test';
    open my $fh, ">", $_[0] or die $!;
    print $fh "$content\n";
    close $fh;
}

chdir $Bin;

done_testing;
