package Pod::Weaver::Section::PERLANCAR::Contributing;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-10'; # DATE
our $DIST = 'Pod-Weaver-PluginBundle-Author-PERLANCAR'; # DIST
our $VERSION = '0.292'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

sub weave_section {
    my ($self, $document, $input) = @_;

    my $text = <<'_';

To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

_
    $self->add_text_to_section($document, $text, 'CONTRIBUTING');
}

no Moose;
1;
# ABSTRACT: Add a CONTRIBUTING section for PERLANCAR distributions

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::PERLANCAR::Contributing - Add a CONTRIBUTING section for PERLANCAR distributions

=head1 VERSION

This document describes version 0.292 of Pod::Weaver::Section::PERLANCAR::Contributing (from Perl distribution Pod-Weaver-PluginBundle-Author-PERLANCAR), released on 2021-08-10.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [PERLANCAR::Contributing]

=head1 DESCRIPTION

=for Pod::Coverage weave_section

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-PluginBundle-Author-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-PluginBundle-Author-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-PluginBundle-Author-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016, 2015, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
