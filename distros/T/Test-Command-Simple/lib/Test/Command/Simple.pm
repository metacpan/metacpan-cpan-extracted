package Test::Command::Simple;

use warnings;
use strict;

=head1 NAME

Test::Command::Simple - Test external commands (nearly) as easily as loaded modules.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

use base 'Test::Builder::Module';
use IPC::Open3;
use IO::Select;
use Symbol qw(gensym);
use Scalar::Util qw(looks_like_number);

our @EXPORT = qw(
    run
    stdout
    stderr
    rc
    run_ok
    exit_status
    );

=head1 SYNOPSIS

    use Test::Command::Simple;

    run('echo', 'has this output'); # only tests that the command can be started, not checking rc
    is(rc,0,'Returned successfully')
    like(stdout,qr/has this output/,'Testing stdout');
    is(length stderr, 0,'No stderr');

=head1 PURPOSE

This test module is intended to simplify testing of external commands.
It does so by running the command under L<IPC::Open3>, closing the stdin
immediately, and reading everything from the command's stdout and stderr.
It then makes the output available to be tested.

It is not (yet?) as feature-rich as L<Test::Cmd>, but I think the
interface to this is much simpler.  Tests also plug directly into the
L<Test::Builder> framework, which plays nice with L<Test::More>.

As compared to L<Test::Command>, this module is simpler, relying on
the user to feed rc, stdout, and stderr to the appropriate other
tests, presumably in L<Test::More>, but not necessarily.  This makes it
possible, for example, to test line 3 of the output:

    my (undef, undef, $line) = split /\r?\n/, stdout;
    is($line, 'This is the third line', 'Test the third line');

While this is possible to do with Test::Command's stdout_like, some regex's
can get very awkward, and it becomes better to do this in multiple steps.

Also, Test::Command saves stdout and stderr to files.  That has an advantage
when you're saving a lot of text.  However, this module prefers to slurp
everything in using IPC::Open3, IO::Select, and sysread.  Most of the time,
commands being tested do not produce significant amounts of output, so there
becomes no reason to use temporary files and involve the disk at all.

=head1 EXPORTS

=head2 run

Runs the given command.  It will return when the command is done.

This will also reinitialise all of the states for stdout, stderr, and rc.
If you need to keep the values of a previous run() after a later one,
you will need to store it.  This should be mostly pretty rare.

Counts as one test: whether the IPC::Open3 call to open3 succeeded.
That is not returned in a meaningful way to the user, though.  To check
if that's the case for purposes of SKIPping, rc will be set to -1.

=cut

my ($stdout, $stderr, $rc);
sub run {
    my $opts = @_ && ref $_[0] eq 'HASH' ? shift : {};

    my @cmd = @_;

    # initialise everything each run.
    $rc = -1;
    $stdout = '';
    $stderr = '';

    my ($wtr, $rdr, $err) = map { gensym() } 1..3;
    my $pid = open3($wtr, $rdr, $err, @cmd) or do {
        return __PACKAGE__->builder->ok(0, "Can run '@cmd'");
    };
    __PACKAGE__->builder->ok(1, "Can run '@cmd'");

    my $s = IO::Select->new();

    if ($opts->{stdin})
    {
        print $wtr $opts->{stdin};
    }

    close $wtr;
    $s->add($rdr);
    $s->add($err);

    my %map = (
               fileno($rdr) => \$stdout,
               fileno($err) => \$stderr,
              );
    while ($s->count())
    {
        if (my @ready = $s->can_read())
        {
            for my $fh (@ready)
            {
                my $buffer;
                my $fileno = fileno($fh);
                my $read = sysread($fh, $buffer, 1024);
                if ($read && $map{$fileno})
                {
                    ${$map{$fileno}} .= $buffer;
                }
                else
                {
                    # done.
                    $s->remove($fh);
                    close $fh;
                }
            }
        }
        elsif (my @err = $s->has_exception())
        {
            warn "Exception on ", fileno($_) for @err;
        }
    }
    waitpid $pid, 0;
    $rc = $?;

    $rc;
}

=head2 stdout

Returns the last run's stdout

=cut

sub stdout() {
    $stdout
}

=head2 stderr

Returns the last run's stderr

=cut

sub stderr() {
    $stderr
}

=head2 rc

Returns the last run's full $?, suitable for passing to L<POSIX>'s
:sys_wait_h macros (WIFEXITED, WEXITSTATUS, etc.)

=cut

sub rc() {
    $rc
}

=head2 exit_status

Returns the exit status of the last run

=cut

sub exit_status()
{
    #WEXITSTATUS($rc);
    $rc >> 8;
}

=head2 run_ok

Shortcut for checking that the return from a command is 0.  Will
still set stdout and stderr for further testing.

If the first parameter is an integer 0-255, then that is the expected
return code instead.  Remember: $? has both a return code (0-255) and a
reason for exit embedded.  This function must make the assumption that
you want a "normal" exit only.  If any signal is given, this will treat
that as a failure.

Note that this becomes B<three> tests: one that IPC::Open3 could create
the subprocess with the command, the next is the test that the process
exited normally, and the last is the test of the rc.

=cut

sub run_ok
{
    my $wanted_rc = 0;
    if (looks_like_number($_[0]) &&
        0 <= $_[0] && $_[0] <= 255 &&
        int($_[0]) == $_[0])
    {
        $wanted_rc = shift();
    }
    run(@_);
    __PACKAGE__->builder->is_eq(rc & 0xFF, 0, "Process terminated without a signal");
    __PACKAGE__->builder->is_eq(exit_status, $wanted_rc, "Check return from '@_' is $wanted_rc");
}

=head1 AUTHOR

Darin McBride, C<< <dmcbride at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-command at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Command-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Command::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Command-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Command-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Command-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Command-Simple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Darin McBride.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Test::Command::Simple
