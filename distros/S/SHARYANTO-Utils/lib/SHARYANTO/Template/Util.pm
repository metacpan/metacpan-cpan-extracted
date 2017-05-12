package SHARYANTO::Template::Util;

use 5.010;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(process_tt_recursive);

use File::Find;
use File::Slurp::Tiny 'read_file', 'write_file';
use Template::Tiny;

our $VERSION = '0.77'; # VERSION

# recursively find *.tt and process them. can optionally delete the *.tt files
# after processing.
sub process_tt_recursive {
    my ($dir, $vars, $opts) = @_;
    $opts //= {};
    my $tt = Template::Tiny->new;
    find sub {
        return unless -f;
        return unless /\.tt$/;
        my $newname = $_; $newname =~ s/\.tt$//;
        my $input = read_file($_);
        my $output;
        #$log->debug("Processing template $File::Find::dir/$_ -> $newname ...");
        $tt->process(\$input, $vars, \$output);
        write_file($newname, $output);
        #$log->debug("Removing $File::Find::dir/$_ ...");
        if ($opts->{delete}) { unlink($_) }
    }, $dir;
}

1;
# ABSTRACT: Recursively process .tt files

__END__

=pod

=encoding UTF-8

=head1 NAME

SHARYANTO::Template::Util - Recursively process .tt files

=head1 VERSION

This document describes version 0.77 of SHARYANTO::Template::Util (from Perl distribution SHARYANTO-Utils), released on 2015-09-04.

=head1 FUNCTIONS

=head2 process_tt_recursive($dir, $vars, $opts)

=head1 SEE ALSO

L<SHARYANTO>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SHARYANTO-Utils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SHARYANTO-Utils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SHARYANTO-Utils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
