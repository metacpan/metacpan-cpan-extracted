package Review::Helper::CLI::Note;
use v5.36;

our $VERSION = '0.001';

use Cwd qw/getcwd/;

use Review::Helper::Journal;
use Review::Helper::VCS;

use Getopt::Yath;

option_group {group => 'note', category => 'Note Options'} => sub {
    option flag     => (type => 'Scalar', description => 'Make it a flag: yellow, a reviewer may object; red, probably an unsolved problem. Without it the note is a journal entry.');
    option kind     => (type => 'Scalar', description => 'deviation, assumption, self-review, test-revealed, note or other (the default).');
    option path     => (type => 'Scalar', description => 'Repository-relative path of the file the note is about.');
    option unit     => (type => 'Scalar', description => 'Sub, method or function the note is about.');
    option snippet  => (type => 'Scalar', description => 'A short distinctive excerpt of the code the note is about.');
    option sentence => (type => 'Scalar', description => 'One sentence, shown on hover.');
    option detail   => (type => 'Scalar', description => 'The full story, shown when the flag is clicked.');
};

sub run($class, $settings, @args) {
    die "Unexpected arguments: @args\n" if @args;

    my $repo = Review::Helper::VCS->detect(getcwd());
    my $id   = Review::Helper::Journal->new(repo => $repo)->add($settings->note->all);
    print "$id\n";

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Note - The review-helper note subcommand.

=head1 DESCRIPTION

    review-helper note [--flag yellow|red] [--kind K] --path P [--unit U] \
        [--snippet S] --sentence T [--detail D]

Appends a note to the current worktree's journal and prints its id. Needs no
review file. With C<--flag> (C<yellow> or C<red>) the note becomes a flag of
that color, placed by the agent on the lines it concerns; without it, a
journal entry, which the next build or iteration of a review takes as it is.
C<--path> and C<--sentence> are required; C<--kind> defaults to C<other>.
The journal validates every value.

=head1 SYNOPSIS

    Review::Helper::CLI->run(note => @args);

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Note->run($settings, @args)

Record the note described by the C<note> option group of C<$settings>. Dies
when positional arguments are given or a field is invalid.

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
