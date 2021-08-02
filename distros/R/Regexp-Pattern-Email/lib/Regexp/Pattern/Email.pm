package Regexp::Pattern::Email;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-01'; # DATE
our $DIST = 'Regexp-Pattern-Email'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our %RE = (
    email_address => {
        summary => 'Email address (RFC 2822)',
        description => <<'_',

Currently uses pattern produced by <pm:Email::Address>.

_
        pat => qr((?:(?^:(?:(?^:(?>(?^:(?^:(?>(?^:(?>(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|\.|\s*"(?^:(?^:[^\\"])|(?^:\\(?^:[^\x0A\x0D])))+"\s*))+))|(?>(?^:(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*"(?^:(?^:[^\\"])|(?^:\\(?^:[^\x0A\x0D])))*"(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))+))?)(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*<(?^:(?^:(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*"(?^:(?^:[^\\"])|(?^:\\(?^:[^\x0A\x0D])))*"(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))\@(?^:(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*\[(?:\s*(?^:(?^:[^\[\]\\])|(?^:\\(?^:[^\x0A\x0D]))))*\s*\](?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))))>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))|(?^:(?^:(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*"(?^:(?^:[^\\"])|(?^:\\(?^:[^\x0A\x0D])))*"(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))\@(?^:(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^:(?>(?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*\[(?:\s*(?^:(?^:[^\[\]\\])|(?^:\\(?^:[^\x0A\x0D]))))*\s*\](?^:(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))))(?>(?^:(?>\s*\((?:\s*(?^:(?^:(?>[^()\\]+))|(?^:\\(?^:[^\x0A\x0D]))|))*\s*\)\s*))*)))),
        examples => [
            {str=>'', anchor=>1, matches=>0, summary=>'Empty'},

            {str=>'foo@example.com', anchor=>1, matches=>1},
            {str=>'foo@example!.com', anchor=>1, matches=>1, summary=>'Not strict enough for most cases'},
            {str=>'foo@exam ple.com', anchor=>1, matches=>0, summary=>'Contains whitespace'},
        ],
    },
);

1;
# ABSTRACT: Regexp patterns related to email

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Email - Regexp patterns related to email

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::Email (from Perl distribution Regexp-Pattern-Email), released on 2021-08-01.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Email::email_address");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 REGEXP PATTERNS

=over

=item * email_address

Email address (RFC 2822).

Currently uses pattern produced by L<Email::Address>.


Examples:

Empty.

 "" =~ re("Email::email_address");  # DOESN'T MATCH

Example #2.

 "foo\@example.com" =~ re("Email::email_address");  # matches

Not strict enough for most cases.

 "foo\@example!.com" =~ re("Email::email_address");  # matches

Contains whitespace.

 "foo\@exam ple.com" =~ re("Email::email_address");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Email>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Email>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Email>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Email::Address>, L<Regexp::Common::Email::Address>

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
