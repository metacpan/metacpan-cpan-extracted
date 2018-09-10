package Regexp::Pattern::Twitter;

our $DATE = '2018-09-10'; # DATE
our $VERSION = '0.003'; # VERSION

our %RE = (
    username => {
        pat => qr/[0-9A-Za-z_]{1,15}/,
        examples => [
            {str=>'perlancar', matches=>1},
            {str=>'a234567890123456', gen_args=>{-anchor=>1}, matches=>0, summary=>'Too long'},
            {str=>'perl ancar', gen_args=>{-anchor=>1}, matches=>0, summary=>'Contains whitespace'},
        ],
    },
);

1;
# ABSTRACT: Regexp patterns related to Twitter

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Twitter - Regexp patterns related to Twitter

=head1 VERSION

This document describes version 0.003 of Regexp::Pattern::Twitter (from Perl distribution Regexp-Pattern-Twitter), released on 2018-09-10.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Twitter::username");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * username

Examples:

 "perlancar" =~ re("Twitter::username");  # matches

 # Too long
 "a234567890123456" =~ re("Twitter::username", {-anchor=>1});  # doesn't match

 # Contains whitespace
 "perl ancar" =~ re("Twitter::username", {-anchor=>1});  # doesn't match

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Twitter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Twitter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Twitter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schemas::Twitter>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
