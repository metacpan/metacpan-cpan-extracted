package Regexp::IPv4;

our $DATE = '2016-10-18'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw($IPv4_re);

my $dig_re = '(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})';
our $IPv4_re = "(?:$dig_re(?:\\.$dig_re){3})";
$IPv4_re = qr/$IPv4_re/;

1;
# ABSTRACT: Regular expression for IPv4 addresses

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::IPv4 - Regular expression for IPv4 addresses

=head1 VERSION

This document describes version 0.003 of Regexp::IPv4 (from Perl distribution Regexp-IPv4), released on 2016-10-18.

=head1 SYNOPSIS

 use Regexp::IPv4 qw($IPv4_re);

 $address =~ /^$IPv4_re$/ and print "IPv4 address\n";

=head1 DESCRIPTION

The regex only recognizes the quad-dotted notation of four decimal integers,
ranging from 0 to 255 each. Other notations like 32-bit hexadecimal number (e.g.
0xFF0000) or shortened dotted notation (e.g. 255.0.0) are not recognized.

If you do not use anchor, beware of cases like:

 "255.255.255.256" =~ /($IPv4_re)/; # true & capture "255.255.255.25"

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-IPv4>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-IPv4>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-IPv4>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::IPv6>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
