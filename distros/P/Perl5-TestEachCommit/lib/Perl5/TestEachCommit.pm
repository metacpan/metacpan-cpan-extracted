package Perl5::TestEachCommit;
use 5.014;
use warnings;
our $VERSION = '0.05';
$VERSION = eval $VERSION;
use Carp;
use Data::Dump ( qw| dd pp| );
use File::Spec::Functions;

=encoding utf8

=head1 NAME

Perl5::TestEachCommit - Test each commit in a pull request to Perl core

=head1 SYNOPSIS

    use Perl5::TestEachCommit;

    $self = Perl5::TestEachCommit->new();

    $self->prepare_repository();
    $self->display_plan();
    $self->get_commits();
    $self->display_commits();
    $self->examine_all_commits();
    $self->get_results();
    $self->display_results();

=head1 DESCRIPTION

This library is intended for use by people working to maintain the
L<Perl core distribution|https://github.com/Perl/perl5>.

Commits to C<blead>, the main development branch in the Perl repository, are
most often done by pull requests.  Most such p.r.s consist of a single commit,
but commits of forty or eighty are not unknown.  A continuous integration
system (CI) ensures that each p.r. is configured, built and tested on
submission and on subsequent modifications.  That CI system, however, only
executes that cycle on the *final* commit in each p.r.  It cannot detect any
failure in a *non-final* commit.  This library provides a way to test each
commit in the p.r. to the same extent that the CI system tests the final
commit.

Why is this important?  Suppose that we have a pull request that consists of 5
commits.  In commit 3 the developer makes an error which causes F<make> to
fail.  The developer notices that and corrects the error in commit 4.  Commit
5 configures, builds and tests satisfactorily, so the CI system gives the p.r.
as a whole a PASS.  The committer uses that PASS as the basis for approving a
merge of the branch into C<blead>.

    Commit  Configure   Build       Test
    ------------------------------------
    1abcd       X         X           X
    2efab       X         X           X
    3cdef       X         0           -
    4dcba       X         X           X
    5fedc       X         X           X

If, for any reason (*e.g.,* bisection), some other developer in the future
needs to say F<git checkout 3cdef>, they will discover that at that commit the
build was actually broken.

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Perl5::TestEachCommit constructor.  Ensures that supplied arguments are
plausible, I<e.g.,> directories needed can be located.

=item * Arguments

    my $self = Perl5::TestEachCommit->new( { %opts } );

Single hash reference.  That hash B<must> include the following key-value
pairs:

=over 4

* C<workdir>

String holding path to a directory which is a F<git> checkout of the Perl core
distribution.  If you have previously set an environmental variable
C<SECONDARY_CHECKOUT_DIR> holding the path to such a directory, that will be
used; otherwise, path must be specified.

* C<start>

String holding SHA of the first commit in the series on which you wish
reporting.

* C<end>

String holding SHA of the last commit in the series on which you wish
reporting.

=back

In addition, that hash B<may> include the following key-value pairs:

=over 4

* C<branch>

F<git> branch which must exist and be available for C<git checkout> in the
directory specified by C<workdir>.  Defaults to C<blead>.

* C<configure_command>

String holding arguments to be passed to F<./Configure>.  Defaults to C<sh
./Configure -des -Dusedevel>.  Add < 1<Egt>/dev/null> to that string if you
don't need voluminous output to C<STDOUT>.

* C<make_test_prep_command>

String holding arguments to be passed to F<make test_prep>.  Defaults to
C<make test_prep>.  Add < 1<Egt>/dev/null> to that string if you don't need
voluminous output to C<STDOUT>.

* C<make_test_harness_command>

String holding arguments to be passed to F<make test_harness>.  Defaults to
C<make test_harness>.  Add < 1<Egt>/dev/null> to that string if you don't need
voluminous output to C<STDOUT>.

* C<skip_test_harness>

True/false value.  Defaults to false.  If true, when proceeding through a
series of commits in a branch or pull request, the C<make test_harness> stage
will be skipped on the assumption that any significant failures are going to
appear in the first two stages.

* C<verbose>

True/false value.  Defaults to false.  If true, prints to C<STDOUT> a summary of
switches in use and commits being tested.

=back

=item * Return Value

Perl5::TestEachCommit object (blessed hash reference).

=back

=cut

sub new {
    my ($class, $params) = @_;
    my $args = {};

    for my $k (keys %{$params}) { $args->{$k} = $params->{$k}; }
    my %data;
    croak "Must supply SHA of first commit to be studied to 'start'"
        unless $args->{start};
    croak "Must supply SHA of last commit to be studied to 'end'"
        unless $args->{end};
    $data{start} = delete $args->{start};
    $data{end} = delete $args->{end};

    # workdir: First see if it has been assigned and exists
    # later: see whether it is a git checkout (and of perl)
    $args->{workdir} ||= ($ENV{SECONDARY_CHECKOUT_DIR} || '');
    -d $args->{workdir} or croak "Unable to locate workdir";

    $data{workdir} = delete $args->{workdir};

    $data{branch} = $args->{branch} ? delete $args->{branch} : 'blead';
    $data{configure_command} = $args->{configure_command}
        ? delete $args->{configure_command}
        : 'sh ./Configure -des -Dusedevel';
    $data{make_test_prep_command} = $args->{make_test_prep_command}
        ? delete $args->{make_test_prep_command}
        : 'make test_prep';
    $data{make_test_harness_command} = $args->{make_test_harness_command}
        ? delete $args->{make_test_harness_command}
        : 'make test_harness';

    $data{skip_test_harness} = defined $args->{skip_test_harness}
        ? delete $args->{skip_test_harness}
        : '';
    $data{verbose} = defined $args->{verbose}
        ? delete $args->{verbose}
        : '';

    # Double-check that every parameter ultimately gets into the object with
    # some assignment.
    map { ! exists $data{$_} ?  $data{$_} = $args->{$_} : '' } keys %{$args};
    return bless \%data, $class;
}

=head2 C<prepare_repository()>

=over 4

=item * Purpose

Prepare the C<workdir> directory for F<git> operations, I<e.g.,> terminates
any bisection in process, cleans the directory, fetches from origing, checks
out blead, then checks out any non-blead branch indicated in the C<branch>
argument to C<new()>.

=item * Arguments

None.

    my $rv = $self->prepare_repostory();

=item * Return Value

Returns true value upon success.

=back

=cut

sub prepare_repository {
    my $self = shift;

    chdir $self->{workdir} or croak "Unable to change to $self->{workdir}";

    my $grv = system(qq|
        git bisect reset && \
        git clean -dfxq && \
        git remote prune origin && \
        git fetch origin && \
        git checkout blead && \
        git rebase origin/blead
    |) and croak "Unable to prepare $self->{workdir} for git activity";

    if ($self->{branch} ne 'blead') {
        system(qq|git checkout $self->{branch}|)
            and croak "Unable to checkout branch '$self->{branch}'";
    }
    return 1;
}

=head2 C<display_plan()>

=over 4

=item * Purpose

Display most important configuration choices.

=item * Arguments

    $self->display_plan();

=item * Return Value

Implicitly returns true value upon success.

=item * Comment

The output will look like this:

    branch:                    blead
    configure_command:         sh ./Configure -des -Dusedevel 1>/dev/null
    make_test_prep_command:    make test_prep 1>/dev/null
    make_test_harness_command: make_test_harness 1>/dev/null

=back

=cut

sub display_plan {
    my $self = shift;
    say "branch:                    $self->{branch}";
    say "configure_command:         $self->{configure_command}";
    say "make_test_prep_command:    $self->{make_test_prep_command}";
    if ($self->{skip_test_harness}) {
        say "Skipping 'make test_harness'";
    }
    else {
        say "make_test_harness_command: $self->{make_test_harness_command}";
    }
    return 1;
}

=head2 C<get_commits()>

=over 4

=item * Purpose

Get a list of SHAs of all commits being tested.

=item * Arguments

    my $lines = $self->get_commits();

=item * Return Value

Reference to an array holding list of all commits being tested.

=back

=cut

sub get_commits {
    my $self = shift;
    my $origin_commit = $self->{start} . '^';
    my $end_commit = $self->{end};
    my @commits = `git rev-list --reverse ${origin_commit}..${end_commit}`;
    chomp @commits;
    return \@commits;
}

=head2 C<display_commits()>

=over 4

=item * Purpose

Display a list of SHAs of all commits being tested.

=item * Arguments

    $self->display_commits();

=item * Return Value

Implicitly returns true value upon success.

=item * Comment

The output will look like this:

    c9cd2e0cf4ad570adf68114c001a827190cb2ee9
    79b32d926ef5961b4946ebe761a7058cb235f797
    0dfa8ac113680e6acdef0751168ab231b9bf842c

=back

=cut

sub display_commits {
    my $self = shift;
    say $_ for @{$self->get_commits()};
    return 1;
}


=head2 C<examine_all_commits()>

=over 4

=item * Purpose

Iterate over all commits in the selected range, configuring, building and --
assuming we have not elected to C<skip_test_harness> -- testing each commit.

=item * Arguments

    $self->examine_all_commits();

=item * Return Value

For possible future chaining, returns the Perl5::TestEachCommit object, which
now includes the results of the examination of each commit in the selected
range.

=back

=cut

sub examine_all_commits {
    my $self = shift;
    $self->{results} = [];
    for my $c (@{ $self->get_commits }) {
        $self->examine_one_commit($c);
    }
    return $self;
}

=head2 C<get_results()>

=over 4

=item * Purpose

Get a list of the SHA and score for each commit.

=item * Arguments

    my $results_ref = $self->get_results();

=item * Return Value

Reference to an array holding a hashref for each commit.  Each such hashref
has two elements: C<commit> and C<score>.  (See C<examine_one_commit>.)

=back

=cut

sub get_results {
    my $self = shift;
    return $self->{results}; # aref
}

=head2 C<display_results()>

=over 4

=item * Purpose

Pretty-print to C<STDOUT> the results obtained via C<get_results()>.

=item * Arguments

    $self->display_results();

=item * Return Value

Implicitly returns a true value upon success.

=item * Comment

The output will look like this:

                    commit                    score
   ------------------------------------------------
   c9cd2e0cf4ad570adf68114c001a827190cb2ee9 |   2
   79b32d926ef5961b4946ebe761a7058cb235f797 |   1
   0dfa8ac113680e6acdef0751168ab231b9bf842c |   2

=back

=cut

sub display_results {
    my $self = shift;
    say ' ' x 17, 'commit', ' ' x 17, ' ' x 3, 'score';
    say '-' x 48;
    for my $el (@{$self->{results}}) {
        say $el->{commit}, ' |   ', $el->{score};
    }
    return 1;
}

=head2 C<examine_one_commit()>

=over 4

=item * Purpose

Configure, build and test one commit in the selected range.

=item * Arguments

    my $score_ref = $self->examine_one_commit($this_SHA);

=item * Return Value

Returns the Perl5::TestEachCommit object, how holding a list of results.

=over 4

=item * C<commit>: the commit's SHA.

=item * C<score>: A numeral between 0 and 3 indicating how many stages the
commit completed successfully:

=over 4

=item 0 Unable to configure.

=item 1 Completed configuration only.

=item 2 Completed configuration and build only.

=item 3 Completed all of configuration, build and testing.

=back

=back

=item * Comment

Called internally within C<examine_all_commits()>.

=back

=cut

sub examine_one_commit {
    my ($self, $c) = @_;
    chdir $self->{workdir} or croak "Unable to change to $self->{workdir}";
    # So that ./Configure, make test_prep and make_test_harness all behave
    # as they typically do in a git checkout.
    local $ENV{PERL_CORE} = 1;

    my $rv = system(qq|git clean -dfxq|) and croak "Unable to git-clean";
    $rv = system(qq|git checkout $c|) and croak "Unable to git-checkout $c";
    undef $rv;
    my $commit_score = 0;

    say STDERR "Configuring $c" if $self->{verbose};
    $rv = system($self->{configure_command});
    if ($rv) {
        carp "Unable to configure at $c";
        push @{$self->{results}}, { commit => $c, score => $commit_score };
        return;
    }
    else {
        $commit_score++;

        say STDERR "Building $c" if $self->{verbose};
        $rv = system($self->{make_test_prep_command});
        if ($rv) {
            carp "Unable to make_test_prep at $c";
            push @{$self->{results}}, { commit => $c, score => $commit_score };
            return;
        }
        else {
            $commit_score++;

            if ($self->{skip_test_harness}) {
                say STDERR "Skipping 'make test_harness'" if $self->{verbose};
            }
            else {
                say STDERR "Testing $c" if $self->{verbose};
                $rv = system($self->{make_test_harness_command});
                if ($rv) {
                    carp "Unable to make_test_harness at $c";
                }
                else {
                    $commit_score++;
                }
            }
            push @{$self->{results}}, { commit => $c, score => $commit_score };
        }
    }
}

=head2 C<cleanup_repository()>

=over 4

=item * Purpose

Clean up the repository in the directory designated by C<workdir>.

=item * Arguments

    $self->cleanup_respository();

=item * Return Value

Implicitly returns a true value upon success.

=item * Comment

Performs a F<git clean> and F<git checkout blead> but does not do any fetching
from origin or updating of C<blead>.

=back

=cut

sub cleanup_repository {
    my $self = shift;

    chdir $self->{workdir} or croak "Unable to change to $self->{workdir}";

    my $grv = system(qq|
        git bisect reset && \
        git clean -dfxq && \
        git checkout blead
    |) and croak "Unable to clean $self->{workdir} after git activity";

    return 1;
}

=head1 BUGS

None reported so far.

=head1 SUPPORT

Contact the author.

=head1 AUTHOR

    James E Keenan
    CPAN ID: JKEENAN
    jkeenan@cpan.org
    https://thenceforward.net/perl/modules/Perl5-TestEachCommit

=head1 COPYRIGHT

Copyright 2025 James E Keenan

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
# The preceding line will help the module return a true value

