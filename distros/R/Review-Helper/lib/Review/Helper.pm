package Review::Helper;
use v5.36;

our $VERSION = '0.001';

use constant STANDARD_VERSION => 1;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper - Web app for reviewing changes written by AI agents.

=head1 EARLY VERSION

This is a very early version. Some key features are still to come, and it is
not ready for daily use. Expect changes between releases, including to the
commands, the review page and the review file format; a review built with
one release may not open in the next.

=head1 DESCRIPTION

Review::Helper helps a human review code an AI agent wrote. When the agent
finishes a change (a commit, a branch, a pull request) it builds a B<review
file> describing the change and fills in explanations: what, why and how for
the whole change and for each commit, file and sub. The human opens the
review in a local web app, reads the change top-down, leaves feedback, and
exports it back to the agent, which acts on it and adds a new B<iteration>.

While writing code, the agent records B<notes> about wrong assumptions,
deviations from a plan, and anything else the reviewer should see. Those that
need the reviewer's judgment become flags beside the lines they concern:
yellow when a reviewer may object, red when something is probably still
wrong. The rest are listed in the iteration's journal.

The other primary use is B<project review>: reviewing a whole codebase, or
one area of it, as it finally lands. With no notes recorded, the agent
deduces points of interest from the commit history, docs, tests, and issues,
and builds one combined review of the final code with a guided tour, rather
than going commit by commit. A large codebase can be split into several
reviews by path. This also serves for learning a codebase.

The review file is a SQLite database kept inside the repository under review,
by default in the worktree's git directory, so it never dirties a working
tree. It stores only review data. Diffs and file contents are read live from
git, and each iteration's head commit is pinned under
C<refs/review-helper/> so rebases and garbage collection do not remove it.

Everything is driven by the C<review-helper> command. Agents never edit the
review file or the refs directly; they use its subcommands.

One goal of this project is a standard format for AI-assisted code review: a
sharable review file plus the tools and agent skills around it. The format,
specified in F<standards/FORMAT.md> of the share directory (see
L<Review::Helper::Manual/"THE REVIEW FILE FORMAT">), is documented and
language-neutral, so other review tools, skills and processes can be built on
the same file and extend it, with this distribution as one starting point.

=head1 SYNOPSIS

Record a note while working:

    review-helper note --flag yellow --kind deviation --path lib/Foo.pm \
        --unit bar --sentence 'Skips expiry when TTL is zero.'

List the reviews of the current repository, close one, and clean up:

    review-helper list
    review-helper close .git/review-helper/my-change.sqlite
    review-helper prune --dry-run
    review-helper prune

Report the standard this implementation follows:

    review-helper version

=head1 PUBLIC METHODS

=over 4

=item $version = Review::Helper->STANDARD_VERSION

The version of the Review::Helper standard this distribution implements: the
review file format, the commands the agent skills rely on, and the HTTP API
the review page uses. C<review-helper version> prints it, and the page's
review data carries it.

=back

=head1 SOURCE

The source code repository for Review-Helper can be found at
L<https://github.com/exodist/Review-Helper>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
