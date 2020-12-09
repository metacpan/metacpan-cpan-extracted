package Regexp::Pattern::CPAN;

our $DATE = '2020-09-14'; # DATE
our $VERSION = '0.004'; # VERSION

our %RE = (
    pause_id => {
        summary => 'PAUSE author ID, or PAUSE ID for short',
        pat => qr/[A-Z][A-Z0-9]{1,8}/,
        description => <<'_',

I'm not sure whether PAUSE allows digit for the first letter. For safety I'm
assuming no.

_
        examples => [
            {str=>'PERLANCAR', matches=>1},
            {str=>'perlancar', summary=>'Only allows uppercase', matches=>0},
            {str=>'A', summary=>'too short', matches=>0},
            {str=>'PERL ANCAR', gen_args=>{-anchor=>1}, summary=>'contains whitespace', matches=>0},
            {str=>'RANDALSCHWARTZ', gen_args=>{-anchor=>1}, summary=>'too long', matches=>0},
        ],
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

This document describes version 0.004 of Regexp::Pattern::CPAN (from Perl distribution Regexp-Pattern-CPAN), released on 2020-09-14.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("CPAN::pause_id");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 REGEXP PATTERNS

=over

=item * pause_id

PAUSE author ID, or PAUSE ID for short.

I'm not sure whether PAUSE allows digit for the first letter. For safety I'm
assuming no.


Examples:

Example #1.

 "PERLANCAR" =~ re("CPAN::pause_id");  # matches

Only allows uppercase.

 "perlancar" =~ re("CPAN::pause_id");  # DOESN'T MATCH

too short.

 "A" =~ re("CPAN::pause_id");  # DOESN'T MATCH

contains whitespace.

 "PERL ANCAR" =~ re("CPAN::pause_id", {-anchor=>1});  # DOESN'T MATCH

too long.

 "RANDALSCHWARTZ" =~ re("CPAN::pause_id", {-anchor=>1});  # DOESN'T MATCH

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

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
