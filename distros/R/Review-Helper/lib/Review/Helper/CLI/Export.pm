package Review::Helper::CLI::Export;
use v5.36;

our $VERSION = '0.001';

use File::Basename qw/dirname/;
use File::Path qw/make_path/;

use Review::Helper::DB;
use Review::Helper::Export;

use Getopt::Yath;

option_group {group => 'export', category => 'Export Options'} => sub {
    option out => (type => 'Scalar', description => 'Write the export to this file instead of standard output.');
};

sub run($class, $settings, @args) {
    die "Usage: review-helper export FILE [--out PATH]\n" unless @args == 1;
    my ($file) = @args;

    my $exporter = Review::Helper::Export->new(db => Review::Helper::DB->open($file));
    my $text     = $exporter->encode($exporter->export);

    my $out = $settings->export->out;
    unless (defined $out) {
        print $text;
        return;
    }

    make_path(dirname($out));
    open(my $fh, '>', $out) or die "Cannot write '$out': $!\n";
    print $fh $text;
    close($fh) or die "Cannot write '$out': $!\n";
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Export - The review-helper export subcommand.

=head1 DESCRIPTION

    review-helper export FILE [--out PATH]

Prints the review as shareable JSON: everything but its feedback and
requests. C<--out> writes it to C<PATH> instead, creating missing
directories; the convention is F<.review-helper/NAME.json> on the branch
under review.

=head1 SYNOPSIS

    Review::Helper::CLI->run(export => $file, '--out', '.review-helper/add-caching.json');

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Export->run($settings, $file)

Export the review in C<$file>. Dies unless exactly one file is given.

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
