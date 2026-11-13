package Review::Helper::CLI::Skills;
use v5.36;

our $VERSION = '0.001';

use File::Spec;
use Review::Helper::Util qw/share_dir/;

use Getopt::Yath;

sub run($class, $settings, @args) {
    die "Usage: review-helper skills path\n" unless @args == 1 && $args[0] eq 'path';

    print File::Spec->catdir(share_dir(), 'skills'), "\n";

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Skills - The C<review-helper skills> subcommand.

=head1 DESCRIPTION

    review-helper skills path

Prints the directory holding the agent skills that ship with Review::Helper,
one subdirectory per skill. Agents load a skill from a symlink to its
subdirectory. Takes no options.

=head1 SYNOPSIS

    Review::Helper::CLI->run(skills => 'path');

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Skills->run($settings, 'path')

Print the shipped skills directory. Dies on any other arguments.

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
