package Regexp::Pattern::CPAN;

our $DATE = '2017-01-05'; # DATE
our $VERSION = '0.001'; # VERSION

our %RE = (
    pause_id => {
        summary => 'PAUSE author ID, or PAUSE ID for short',
        pat => qr/[a-z][a-z0-9]{1,8}/,
        description => <<'_',

I'm not sure whether PAUSE allows digit for the first letter. For safety I'm
assuming no.

_
    },
);

1;
# ABSTRACT: Regexp patterns related to CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::CPAN - Regexp patterns related to CPAN

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::CPAN (from Perl distribution Regexp-Pattern-CPAN), released on 2017-01-05.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("CPAN::pause_id");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * pause_id

PAUSE author ID, or PAUSE ID for short.

I'm not sure whether PAUSE allows digit for the first letter. For safety I'm
assuming no.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-CPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-CPAN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-CPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern::Perl>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
