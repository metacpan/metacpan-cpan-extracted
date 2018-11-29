package Perl::Examples::Module::One;

our $DATE = '2018-11-29'; # DATE
our $VERSION = '0.094'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(fisbus);

sub fisbus {
    my $arg = shift;
    if ($arg % 2 == 0) {
        return $arg + 1;
    } elsif ($arg % 5 == 0) {
        return $arg - 5;
    } else {
        return $arg - 1;
    }
}

1;
# ABSTRACT: Example module one

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Examples::Module::One - Example module one

=head1 VERSION

This document describes version 0.094 of Perl::Examples::Module::One (from Perl distribution Perl-Examples), released on 2018-11-29.

=head1 SYNOPSIS

 use Perl::Examples::Module::One qw(fisbus);

 print fisbus(3); # 2
 print fisbus(4); # 4
 print fisbus(5); # 0
 print fisbus(6); # 7

=head1 DESCRIPTION

This is an example module with the following features:

=over

=item * C<$VERSION>

=item * Some code

=item * Synopsis

=item * Documentation on function

=back

=head1 FUNCTION

=head2 fisbus

Usage:

 fisbus($num) => $new_num

Accept a number then return another number. If input number is even, return
number plus one. If input number is divisible by five, return number minus five.
Otherwise, return input number minus one.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perl-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perl-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
