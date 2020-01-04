package Regexp::Pattern::Test::re_engine;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-04'; # DATE
our $DIST = 'Regexp-Pattern-Test-re_engine'; # DIST
our $VERSION = '0.001'; # VERSION

our %RE = (
    contains_code_construct => {
        summary => 'Regexp which contains (?{ code }) construct',
        pat => qr/(?{ my $dummy=1 })/,
        description => <<'_',

This regex should die when compiled under e.g. <pm:re::engine::PCRE2> instead of
the default Perl regex engine.

_
    },
);

1;
# ABSTRACT: Regexp patterns to test loading under re::engine::*

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Test::re_engine - Regexp patterns to test loading under re::engine::*

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::Test::re_engine (from Perl distribution Regexp-Pattern-Test-re_engine), released on 2020-01-04.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Test::re_engine::contains_code_construct");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * contains_code_construct

Regexp which contains (?{ code }) construct.

This regex should die when compiled under e.g. L<re::engine::PCRE2> instead of
the default Perl regex engine.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Test-re_engine>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Test-re_engine>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Test-re_engine>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
