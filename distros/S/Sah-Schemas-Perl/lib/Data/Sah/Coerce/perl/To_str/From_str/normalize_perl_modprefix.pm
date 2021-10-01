package Data::Sah::Coerce::perl::To_str::From_str::normalize_perl_modprefix;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-29'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.039'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Coerce perl::modprefix from str',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "!ref($dt)";
    $res->{expr_coerce} = join(
        "",
        "do { my \$tmp = $dt; \$tmp =~ s!::?|/|\\.|-!::!g; \$tmp .= '::' if \$tmp =~ /\\A\\w+(::\\w+)*\\z/; \$tmp }",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_str::From_str::normalize_perl_modprefix

=head1 VERSION

This document describes version 0.039 of Data::Sah::Coerce::perl::To_str::From_str::normalize_perl_modprefix (from Perl distribution Sah-Schemas-Perl), released on 2021-09-29.

=head1 DESCRIPTION

This rule can normalize strings in the form of:

 Foo::Bar

 Foo:Bar
 Foo:Bar:

 Foo-Bar
 Foo-Bar-

 Foo/Bar
 Foo/Bar/

 Foo.Bar
 Foo.Bar.

into:

 Foo::Bar::

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

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

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
