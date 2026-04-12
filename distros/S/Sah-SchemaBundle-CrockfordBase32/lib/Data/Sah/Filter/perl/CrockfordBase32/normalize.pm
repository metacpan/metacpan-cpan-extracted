package Data::Sah::Filter::perl::CrockfordBase32::normalize;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-01-28'; # DATE
our $DIST = 'Sah-SchemaBundle-CrockfordBase32'; # DIST
our $VERSION = '0.001'; # VERSION

sub meta {
    +{
        v => 1,
        summary => "Normalize Crockford's Base 32 encoding digits",
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; ",
        "if (ref \$tmp) { \$tmp } ",
        "else { ", (
            "\$tmp =~ tr/iIlLoO/111100/; ",
            "\$tmp; "),
        "} }",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::CrockfordBase32::normalize

=head1 VERSION

This document describes version 0.001 of Data::Sah::Filter::perl::CrockfordBase32::normalize (from Perl distribution Sah-SchemaBundle-CrockfordBase32), released on 2026-01-28.

=head1 DESCRIPTION

This prefilter rule can normalize strings in the form of:

 Foo:Bar
 Foo-Bar
 Foo/Bar.pm
 Foo/Bar
 Foo.Bar

into:

 Foo::Bar

This rule can also handle version after module name, e.g.:

 Foo::Bar@1.23

as well as optional import arguments like perl's C<-M>:

 Foo::Bar=arg1,arg2
 Foo::Bar@1.23=arg1,arg2

For convenience with bash completion (because C<=> is by default a word-breaking
character in bash, while C<,> is not) you can use C<,> instead of C<=> and it
will be normalized to C<=>.

 Foo::Bar,arg1,arg2           # will become Foo::Bar=arg1,arg2
 Foo::Bar@1.23,arg1,arg2      # will become Foo::Bar@1.23=arg1,arg2

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-CrockfordBase32>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-CrockfordBase32>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-CrockfordBase32>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
