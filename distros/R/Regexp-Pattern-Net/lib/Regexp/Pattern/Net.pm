package Regexp::Pattern::Net;

our $DATE = '2019-01-14'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %RE;

$RE{ipv4} = {
    summary => 'Match an IPv4 address',
    pat => qr/(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))/, # from Regexp::Common {net}{IPv4}
    examples => [
        {str=>'1.2.3.4', matches=>1},
        {str=>'1.256.3.4', matches=>0},
    ],
};

1;
# ABSTRACT: Regexp patterns related to network

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Net - Regexp patterns related to network

=head1 VERSION

This document describes version 0.002 of Regexp::Pattern::Net (from Perl distribution Regexp-Pattern-Net), released on 2019-01-14.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Net::ipv4");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * ipv4

Match an IPv4 address.

Examples:

 "1.2.3.4" =~ re("Net::ipv4");  # matches

 "1.256.3.4" =~ re("Net::ipv4");  # doesn't match

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Net>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Net>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Net>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern>

L<Regexp::Common>, particularly L<Regexp::Common::net>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
