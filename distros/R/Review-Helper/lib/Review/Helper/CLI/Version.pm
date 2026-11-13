package Review::Helper::CLI::Version;
use v5.36;

our $VERSION = '0.001';

use Review::Helper;

use Getopt::Yath;

sub run($class, $settings, @args) {
    die "Usage: review-helper version\n" if @args;

    print 'standard ', Review::Helper->STANDARD_VERSION, "\n";
    print "implementation Review-Helper $Review::Helper::VERSION\n";

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Version - The review-helper version subcommand.

=head1 DESCRIPTION

    review-helper version

Prints two lines: C<standard> and the version of the standard this
distribution implements, then C<implementation Review-Helper> and the
distribution's version. Takes no options.

=head1 SYNOPSIS

    Review::Helper::CLI->run('version');

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Version->run($settings)

Print the versions. Dies when arguments are given.

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
