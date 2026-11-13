package Review::Helper::CLI::List;
use v5.36;

our $VERSION = '0.001';

use Cwd qw/getcwd/;

use Review::Helper::Registry;
use Review::Helper::VCS;

use Getopt::Yath;

sub run($class, $settings, @args) {
    die "Usage: review-helper list\n" if @args;

    my $reviews = Review::Helper::Registry->new(repo => Review::Helper::VCS->detect(getcwd()))->reviews;
    print "$_\t$reviews->{$_}{state}\t$reviews->{$_}{path}\n" for sort keys %$reviews;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::List - The review-helper list subcommand.

=head1 DESCRIPTION

    review-helper list

Prints the reviews registered in the current repository, one per line: id,
state and path, separated by tabs. Takes no options.

=head1 SYNOPSIS

    Review::Helper::CLI->run('list');

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::List->run($settings)

Print the registered reviews. Dies when arguments are given.

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
