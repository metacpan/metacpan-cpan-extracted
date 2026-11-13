package Review::Helper::CLI::Fill;
use v5.36;

our $VERSION = '0.001';

use Review::Helper::DB;
use Review::Helper::VCS;
use Review::Helper::Sheet;
use Review::Helper::Util qw/json_decode/;

use Getopt::Yath;

sub run($class, $settings, @args) {
    die "Usage: review-helper fill FILE SHEET\n" unless @args == 2;
    my ($file, $sheet_file) = @args;

    my $fh;
    if ($sheet_file eq '-') {
        $fh = \*STDIN;
    }
    else {
        open($fh, '<', $sheet_file) or die "Cannot open '$sheet_file': $!\n";
    }
    binmode($fh);
    my $raw = join('' => <$fh>);

    my $data;
    eval { $data = json_decode($raw); 1 } or die "'$sheet_file' is not valid JSON: $@";

    my $sheet  = Review::Helper::Sheet->new(repo => Review::Helper::VCS->detect($file), db => Review::Helper::DB->open($file));
    my $result = $sheet->fill($data);
    print "filled $result->{filled}, remaining $result->{remaining}\n";
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Fill - The review-helper fill subcommand.

=head1 DESCRIPTION

    review-helper fill FILE SHEET

Validates a filled sheet and imports it into the review in one transaction.
C<SHEET> is a file, or C<-> for standard input. Prints
C<filled N, remaining M>: the items written and the required items still
empty. A rejected sheet writes nothing; each problem is printed on its own
line on standard error, and the exit code is non-zero. Takes no options.

=head1 SYNOPSIS

    Review::Helper::CLI->run(fill => $file, $sheet_file);

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Fill->run($settings, $file, $sheet_file)

Fill the review in C<$file> from C<$sheet_file>. Dies unless exactly two
arguments are given, or when the sheet is not valid JSON or is rejected.

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
