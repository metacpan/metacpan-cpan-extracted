package Regexp::Pattern::YouTube;

our $DATE = '2018-09-10'; # DATE
our $VERSION = '0.003'; # VERSION

our %RE = (
    video_id => {
        pat => qr/[A-Za-z0-9_-]{11}/,
        examples => [
            {str=>'aNAtbYSxzuA', gen_args=>{-anchor=>1}, matches=>1},
            {str=>'aNAtbYSxzuA-', gen_args=>{-anchor=>1}, matches=>0, summary=>'Incorrect length'},
            {str=>'aNAtb+SxzuA', gen_args=>{-anchor=>1}, matches=>0, summary=>'Contains invalid character'},
        ],
    },
);

1;
# ABSTRACT: Regexp patterns related to YouTube

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::YouTube - Regexp patterns related to YouTube

=head1 VERSION

This document describes version 0.003 of Regexp::Pattern::YouTube (from Perl distribution Regexp-Pattern-YouTube), released on 2018-09-10.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("YouTube::video_id");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * video_id

Examples:

 "aNAtbYSxzuA" =~ re("YouTube::video_id", {-anchor=>1});  # matches

 # Incorrect length
 "aNAtbYSxzuA-" =~ re("YouTube::video_id", {-anchor=>1});  # doesn't match

 # Contains invalid character
 "aNAtb+SxzuA" =~ re("YouTube::video_id", {-anchor=>1});  # doesn't match

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-YouTube>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-YouTube>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-YouTube>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
