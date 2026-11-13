package Review::Helper::CLI::Close;
use v5.36;

our $VERSION = '0.001';

use Review::Helper::DB;
use Review::Helper::Registry;
use Review::Helper::VCS;

use Getopt::Yath;

sub run($class, $settings, @args) {
    die "Usage: review-helper close FILE\n" unless @args == 1;
    my ($file) = @args;
    my $registry = Review::Helper::Registry->new(repo => Review::Helper::VCS->detect($file));
    $registry->close_review(Review::Helper::DB->open($file), $file);
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Close - The review-helper close subcommand.

=head1 DESCRIPTION

    review-helper close FILE

Marks the review closed, in the file and in the repository's registry. A
review missing from the registry is registered as closed. Prints nothing.
Takes no options.

=head1 SYNOPSIS

    Review::Helper::CLI->run(close => $file);

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Close->run($settings, $file)

Close the review in C<$file>. Dies unless exactly one file is given.

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
