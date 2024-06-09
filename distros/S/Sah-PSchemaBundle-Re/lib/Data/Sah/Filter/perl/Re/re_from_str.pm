package Data::Sah::Filter::perl::Re::re_from_str;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-30'; # DATE
our $DIST = 'Sah-PSchemaBundle-Re'; # DIST
our $VERSION = '0.003'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Convert string to regex using Regexp::From::String\'s str_to_re()',
        args => {
            always_quote => {
                summary => 'Passed to Regexp::From::String\'s str_to_re()',
                schema => 'bool*',
            },
            case_insensitive => {
                summary => 'Passed to Regexp::From::String\'s str_to_re()',
                schema => 'bool*',
            },
            anchored => {
                summary => 'Passed to Regexp::From::String\'s str_to_re()',
                schema => 'bool*',
            },
        },
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    my $gen_args = $fargs{args} // {};

    my $res = {};
    $res->{modules}{'Regexp::From::String'} = 0.003;
    $res->{expr_filter} = join(
        "",
        "Regexp::From::String::str_to_re({", (
            "always_quote=>",($gen_args->{always_quote} ? 1:0),
            ", case_insensitive=>",($gen_args->{case_insensitive} ? 1:0),
            ", anchored=>",($gen_args->{anchored} ? 1:0),
        ), "}, $dt)",
    );

    $res;
}

1;
# ABSTRACT: Convert string to regex using Regexp::From::String's str_to_re()

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Re::re_from_str - Convert string to regex using Regexp::From::String's str_to_re()

=head1 VERSION

This document describes version 0.003 of Data::Sah::Filter::perl::Re::re_from_str (from Perl distribution Sah-PSchemaBundle-Re), released on 2024-05-30.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-PSchemaBundle-Re>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-PSchemaBundle-Re>.

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

This software is copyright (c) 2024, 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-PSchemaBundle-Re>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
