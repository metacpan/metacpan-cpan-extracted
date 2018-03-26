package Regexp::Common::json;

our $DATE = '2018-03-25'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Regexp::Common 'pattern';
use Regexp::Pattern::JSON;

my $re = \%Regexp::Pattern::JSON::RE;

for my $patname (sort keys %$re) {
    pattern(
        name => ['json', $patname],
        create => $re->{$patname}{pat},
    );
}

1;
# ABSTRACT: Regexp patterns to match JSON

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Common::json - Regexp patterns to match JSON

=head1 VERSION

This document describes version 0.001 of Regexp::Common::json (from Perl distribution Regexp-Common-json), released on 2018-03-25.

=head1 SYNOPSIS

 use Regexp::Common qw/json/;

 say "match" if $str =~ /\A$RE{json}{number}\z/;

=head1 PATTERNS

=head2 number

=head2 string

=head2 array

=head2 object

=head2 value

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Common-json>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Common-json>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Common-json>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern::JSON>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
