package Progress::Any::Output::Null;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.219'; # VERSION

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub update {
    1;
}

1;
# ABSTRACT: Null output

__END__

=pod

=encoding UTF-8

=head1 NAME

Progress::Any::Output::Null - Null output

=head1 VERSION

This document describes version 0.219 of Progress::Any::Output::Null (from Perl distribution Progress-Any), released on 2020-08-15.

=for Pod::Coverage ^(new|update)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Progress-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Progress-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Progress-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
