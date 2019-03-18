package Data::Sah::Coerce::perl::any::validate_dirhandle;

our $DATE = '2019-03-17'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        might_fail => 1,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{modules}{'Scalar::Util'} //= 0;
    $res->{expr_match} = '1';
    $res->{expr_coerce} = join(
        '',
        "ref($dt) eq 'GLOB' || (Scalar::Util::blessed($dt) && ($dt)\->isa('IO::Dir')) ? [undef, $dt] : ['Not a dirhandle']",
    );
    $res;
}

1;
# ABSTRACT: Validate dirhandle

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::any::validate_dirhandle - Validate dirhandle

=head1 VERSION

This document describes version 0.001 of Data::Sah::Coerce::perl::any::validate_dirhandle (from Perl distribution Sah-Schemas-FileHandle), released on 2019-03-17.

=head1 DESCRIPTION

This rule checks that data is a glob or an object that isa L<IO::Dir>.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-FileHandle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Filehandle>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-FileHandle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
