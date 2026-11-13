package TestRepo;
use v5.36;

use Exporter 'import';
our @EXPORT_OK = qw/make_repo run_git write_file commit_file pinned_refs/;

use File::Basename qw/dirname/;
use File::Path qw/make_path/;
use File::Temp qw/tempdir/;
use Cwd qw/abs_path/;

# A throwaway repository in a temp dir, isolated from user and system git config.
sub make_repo() {
    my $dir = abs_path(tempdir(CLEANUP => 1));
    run_git($dir, qw/init -q -b main/);
    run_git($dir, qw/config user.name Tester/);
    run_git($dir, qw/config user.email tester@example.com/);
    return $dir;
}

sub run_git($dir, @args) {
    local $ENV{GIT_CONFIG_NOSYSTEM} = 1;
    local $ENV{GIT_CONFIG_GLOBAL}   = '/dev/null';
    open(my $fh, '-|', 'git', '-C', $dir, @args) or die "git @args: $!";
    my $out = join('' => <$fh>);
    close($fh);
    die "git @args failed with exit " . ($? >> 8) if $?;
    return $out;
}

sub write_file($dir, $path, $content) {
    my $file = "$dir/$path";
    make_path(dirname($file));
    open(my $fh, '>', $file) or die "write $file: $!";
    print $fh $content;
    close($fh) or die "close $file: $!";
}

# Write each path => content (undef deletes), commit, and return the new sha.
sub commit_file($dir, $message, %files) {
    for my $path (sort keys %files) {
        if (defined $files{$path}) {
            write_file($dir, $path, $files{$path});
            run_git($dir, 'add', '--', $path);
        }
        else {
            run_git($dir, qw/rm -q --/, $path);
        }
    }
    run_git($dir, qw/commit -q --allow-empty -m/, $message);
    my $revision = run_git($dir, qw/rev-parse HEAD/);
    chomp($revision);
    return $revision;
}

# Every review-helper pin (git ref) in the repository at $dir.
sub pinned_refs($dir) {
    return [split /\n/ => run_git($dir, 'for-each-ref', '--format=%(refname)', 'refs/review-helper/')];
}

1;
