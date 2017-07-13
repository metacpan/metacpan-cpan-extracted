package Setup::File::Dir;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.23'; # VERSION

use Setup::File;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(setup_dir);

# now moved to Setup::File

sub setup_dir {
    [501, "Moved to Setup::File"];
}

1;
# ABSTRACT: Setup directory (existence, mode, permission)

__END__

=pod

=encoding UTF-8

=head1 NAME

Setup::File::Dir - Setup directory (existence, mode, permission)

=head1 VERSION

This document describes version 0.23 of Setup::File::Dir (from Perl distribution Setup-File), released on 2017-07-10.

=for Pod::Coverage ^(setup_dir)$

=head1

Moved to

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Setup-File>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Setup-File>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Setup-File>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Setup>

L<Setup::File>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
