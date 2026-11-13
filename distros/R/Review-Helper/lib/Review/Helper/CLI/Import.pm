package Review::Helper::CLI::Import;
use v5.36;

our $VERSION = '0.001';

use Cwd qw/getcwd/;
use File::Basename qw/basename/;

use Review::Helper::Export;
use Review::Helper::VCS;
use Review::Helper::Util qw/json_decode/;

use Getopt::Yath;

option_group {group => 'import', category => 'Import Options'} => sub {
    option file => (type => 'Scalar', description => 'Where to write the review file. Default: inside the git directory.');
};

sub run($class, $settings, @args) {
    die "Usage: review-helper import JSON [--file PATH]\n" unless @args == 1;
    my ($json) = @args;

    my $fh;
    if ($json eq '-') {
        $fh = \*STDIN;
    }
    else {
        open($fh, '<', $json) or die "Cannot open '$json': $!\n";
    }
    binmode($fh);
    my $raw = join('' => <$fh>);

    my $export;
    eval { $export = json_decode($raw); 1 } or die "'$json' is not valid JSON: $@";

    my $name     = $json eq '-' ? undef : basename($json) =~ s/\.json\z//r;
    my $importer = Review::Helper::Export->new(repo => Review::Helper::VCS->detect(getcwd()));
    # group() because import() is Perl's module-loading hook, not a group accessor.
    my $result = $importer->restore($export, name => $name, file => $settings->group('import')->file);

    print "$result->{file}\n";
    warn "Iteration $_->{iteration}: commit $_->{head} is not in this repository; fetch it to view that iteration.\n" for @{$result->{missing}};
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Import - The review-helper import subcommand.

=head1 DESCRIPTION

    review-helper import JSON [--file PATH]

Creates a review file in the current repository from an export (C<-> reads
standard input), registers it as open, pins each iteration whose head commit
is present, and prints the file's path. The default file is named after the
JSON file, or the review's title when reading standard input. When the
review is already here, the export is merged into its file, keeping its
feedback and requests (see L<Review::Helper::Export>); a file holding
another review is never overwritten. Each iteration whose head commit is
missing is named on standard error, with the commit to fetch.

=head1 SYNOPSIS

    Review::Helper::CLI->run(import => '.review-helper/add-caching.json');

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Import->run($settings, $json)

Import the export in C<$json>. Dies unless exactly one argument is given.

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
