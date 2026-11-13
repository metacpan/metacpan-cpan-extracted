package Review::Helper::CLI::Prune;
use v5.36;

our $VERSION = '0.001';

use Cwd qw/getcwd/;

use Review::Helper::Registry;
use Review::Helper::VCS;

use Getopt::Yath;

option_group {group => 'prune', category => 'Prune Options'} => sub {
    option dry_run => (type => 'Bool', description => 'Print the refs that would be removed and change nothing.');
};

sub run($class, $settings, @args) {
    die "Usage: review-helper prune [--dry-run]\n" if @args;

    my $registry = Review::Helper::Registry->new(repo => Review::Helper::VCS->detect(getcwd()));
    print "$_\n" for @{$registry->prune(dry_run => $settings->prune->dry_run)};

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Prune - The review-helper prune subcommand.

=head1 DESCRIPTION

    review-helper prune [--dry-run]

Deletes the pinned refs of reviews that are closed or whose file is gone, and
drops them from the registry. Prints each ref removed. With C<--dry-run>,
prints what would be removed and changes nothing. Takes no ref or path
arguments and never deletes review files.

=head1 SYNOPSIS

    Review::Helper::CLI->run(prune => '--dry-run');

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Prune->run($settings)

Prune the current repository's reviews. Dies when arguments are given.

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
