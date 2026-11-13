package Review::Helper::CLI::Build;
use v5.36;

our $VERSION = '0.001';

use Cwd qw/getcwd/;

use Review::Helper::Builder;
use Review::Helper::VCS;

use Getopt::Yath;

option_group {group => 'build', category => 'Build Options'} => sub {
    option base   => (type => 'Scalar', description => 'The commit the work starts from; the review covers base..head. Required unless --squash.');
    option head   => (type => 'Scalar', description => 'The last commit to review. Default: HEAD.');
    option squash => (type => 'Bool',   description => 'Review base..head as one combined change. Default base: the empty revision, the whole codebase.');
    option path   => (type => 'List',   description => 'Limit the review to files matching this path spec of the VCS (a git pathspec). Repeatable.');
    option title  => (type => 'Scalar', description => 'A short name for the change.');
    option source => (type => 'Scalar', description => 'URL of the pull or merge request under review.');
    option file   => (type => 'Scalar', description => 'Where to write the review file. Default: inside the git directory.');
};

my $USAGE = "Usage: review-helper build [--base REV] [--head REV] [--squash] [--path SPEC]... [--title TEXT] [--source URL] [--file PATH]\n" . "--base is required unless --squash.\n";

sub run($class, $settings, @args) {
    my $opts = $settings->build;
    die $USAGE if @args || !(defined($opts->base) || $opts->squash);

    my $builder = Review::Helper::Builder->new(repo => Review::Helper::VCS->detect(getcwd()));
    print $builder->build((map { ($_ => $opts->$_) } qw/base head squash title source file/), paths => $opts->path), "\n";
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Build - The review-helper build subcommand.

=head1 DESCRIPTION

    review-helper build [--base REV] [--head REV] [--squash] [--path SPEC]...
        [--title TEXT] [--source URL] [--file PATH]

Builds a review of C<base..head> in the current repository, with its first
iteration pinned and registered, and prints the review file path. A
C<--file> in the worktree is not checked against git; keep it out of your
commits, for example by ignoring it.

C<--squash> reviews the range as one combined change instead of commit by
commit; C<--base> then defaults to the empty revision, so the review covers
the whole codebase at the head. Each C<--path> is a path spec of the VCS (for
git, a pathspec); with any, only matching files are reviewed.

=head1 SYNOPSIS

    Review::Helper::CLI->run(build => '--base', 'main');

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Build->run($settings)

Build the review described by the C<build> option group of C<$settings>.
Dies without C<--base> unless C<--squash>, or with positional arguments.

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
