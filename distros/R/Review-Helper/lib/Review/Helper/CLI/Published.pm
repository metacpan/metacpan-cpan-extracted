package Review::Helper::CLI::Published;
use v5.36;

our $VERSION = '0.001';

use Review::Helper::DB;

use Getopt::Yath;

sub run($class, $settings, @args) {
    die "Usage: review-helper published FILE ID\n" unless @args == 2;
    my ($file, $id) = @args;
    die "Feedback ID must be a positive integer, got '$id'\n" unless $id =~ m/^[1-9][0-9]*$/;

    Review::Helper::DB->open($file)->set_published($id);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Published - The review-helper published subcommand.

=head1 DESCRIPTION

    review-helper published FILE ID

Records that feedback item C<ID> was posted to the pull or merge request, by
setting its C<published> time to now. Marking an item again updates the
time. Prints nothing. Takes no options.

=head1 SYNOPSIS

    Review::Helper::CLI->run(published => $file, $id);

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Published->run($settings, $file, $id)

Mark feedback item C<$id> in C<$file> as published. Dies unless exactly a file
and an id are given, when the id is not a positive integer, or when no such
feedback item exists.

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
