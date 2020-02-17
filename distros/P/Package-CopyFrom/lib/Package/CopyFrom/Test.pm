package Package::CopyFrom::Test;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-16'; # DATE
our $DIST = 'Package-CopyFrom'; # DIST
our $VERSION = '0.003'; # VERSION

our $SCALAR1 = "test1";
our $SCALAR2 = "test2";
our @ARRAY1  = ("elem1", "elem2");
our @ARRAY2  = ("elem3", "elem4");
our %HASH1   = (key1=>1, key2=>[2]);
our %HASH2   = (key3=>3, key4=>4);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(func1);
our %EXPORT_TAGS = (
    T1 => [qw/func1 func2/],
    T2 => [qw/func2 func3/],
);

sub func1 { return "from test 1: $_[0]" }
sub func2 { return "from test 2: $_[0]" }
sub func3 { return "from test 3: $_[0]" }

1;

# ABSTRACT: A dummy module for testing

__END__

=pod

=encoding UTF-8

=head1 NAME

Package::CopyFrom::Test - A dummy module for testing

=head1 VERSION

This document describes version 0.003 of Package::CopyFrom::Test (from Perl distribution Package-CopyFrom), released on 2020-02-16.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Package-CopyFrom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Package-CopyFrom>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Package-CopyFrom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
