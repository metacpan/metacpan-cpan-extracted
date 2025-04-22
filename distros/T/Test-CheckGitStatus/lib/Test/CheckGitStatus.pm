# ABSTRACT: Check git status after every test
package Test::CheckGitStatus;
use strict;
use warnings;
use Config;

our $VERSION = 'v0.1.2'; # VERSION

my $CHECK_GIT_STATUS = $ENV{CHECK_GIT_STATUS};

# prevent subsequent perl processes to check the status
if ($ENV{HARNESS_ACTIVE} or $ENV{TEST_ACTIVE} or $ENV{TEST2_ACTIVE}) {
    $ENV{CHECK_GIT_STATUS} = 0;
}
else {
    $CHECK_GIT_STATUS = 0;
}

# Prevent forked processes to check the status
my $pid = $$;

my $cwd;

if ($CHECK_GIT_STATUS) {
    require Test::More;
    require Cwd;
    $cwd = Cwd::cwd();
}

sub check_status {
    my @lines = _get_status();
    if (@lines > 0) {
        Test::More::diag("Error: modified or untracked files\n" . join '', @lines);
        $? = 1;
    }
}

sub _check_git {
    require File::Which;
    my $git = File::Which::which('git');
    return unless $git;
    if ($Config{osname} eq 'MSWin32') {
        $git = qq{"$git"};
    }
    return $git;
}

sub _get_status {
    local $?;
    chdir $cwd;
    my $git = _check_git();
    return unless $git;
    my $cmd = qq{$git rev-parse --git-dir};
    my $out = qx{$cmd};
    return if $? != 0;
    $cmd = qq{$git status --porcelain=v1 2>&1};
    my @lines = qx{$cmd};
    die "Problem running '$git':\n" . join '', @lines if $? != 0;
    return @lines;
}

END {
    # Check $pid - don't run this in forked processes
    check_status() if $$ == $pid and $CHECK_GIT_STATUS;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::CheckGitStatus - Check git status after every test

=head1 SYNOPSIS

    CHECK_GIT_STATUS=1 prove -M Test::CheckGitStatus -l t/
    CHECK_GIT_STATUS=1 PERL5OPT="-MTest::CheckGitStatus" prove -l t/

    # or in your test:
    use Test::CheckGitStatus;

    CHECK_GIT_STATUS=1 prove t/

=head1 DESCRIPTION

This module can be used to check if your git directory has any modified or
untracked files. You can use it in your unit tests, and it will check
the status after each test file.

By default it will not run the check, as this would be annoying during
development.

=head2 USE CASE

If you have a large test suite and a lot of contributors, it can happen
that someone implements a test by adding a file in the git worktree.
They might forget to delete it at the end, or it might not be deleted
if the test exits before the deletion.

Sometimes such temp files are even hidden via C<.gitignore>. Then it
can happen that one test adds such a file, and one of the next tests
relies on its existence. And if you only run the next test, you might
not have the file from the previous test, and it fails, and you don't
know why.

I have seen all of this and wanted to have a check that ensures a clean
status after B<every> test file, not just at the end.

You can use this as a normal module in all your tests:

    use Test::CheckGitStatus;

Then you only have to activate it via C<CHECK_GIT_STATUS=1>.

You can also use it with C<prove -MTest::CheckGitStatus>.

The module runs the check in an END block and tries to make sure that
it only runs it in the END block of the actual test script, not of any new
or forked processes.
It will only run if one of the environment variables C<TEST_ACTIVE>,
C<TEST2_ACTIVE> or C<HARNESS_ACTIVE> is set. (That is to make sure
it does not run as the END block of the C<prove> app itself.)

It will modify the exit status and output any modified or untracked files.

Example output:

    1..1
    # Error: modified or untracked files
    #  M lib/Test/CheckGitStatus.pm
    # ?? LICENSE
    # ?? Makefile.PL
    # ?? t/00.compile.t
    # Looks like your test exited with 1 just after 1.
    Dubious, test returned 1 (wstat 256, 0x100)
    All 1 subtests passed

It's not very pretty and like the normal output from a failed test you are used
to.

If you still need to touch some files during tests, you can always add
them to C<.gitignore>.

=head3 ALTERNATIVE IMPLEMENTATION

An alternative could be to implement it like L<Test::Warnings>, for example,
which sneaks this in as a regular test.

This can have disadvantages as well.

For that it would have to run a bit earlier, and at that point some tests
might still have temp directories open which will be deleted in the global
destruction phase, which might happen after the status check runs.

But if you actually would want to avoid such temporary files completely,
the alternative implementation would be a better choice.

Of course it still cannot prevent any temporary files created and
removed during a test before the check. For that you might want to
try C<chmod -R a-w .> ;-)

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) SUSE LLC, Tina Müller

=cut
