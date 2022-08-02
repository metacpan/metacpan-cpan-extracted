package Data::Sah::Filter::perl::Str::maybe_convert_to_re;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-09'; # DATE
our $DIST = 'Sah-Schemas-Str'; # DIST
our $VERSION = '0.008'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Convert string to regex if delimited by /.../ or qr(...)',
        might_fail => 1,
        args => {
            # XXX delimiter
            # XXX allowed modifiers
        },
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    my $gen_args = $fargs{args} // {};

    my $res = {};
    $res->{expr_filter} = join(
        "",
        "do {",
        "    my \$tmp = $dt; ",
        "    if (\$tmp =~ m!\\A(?:/.*/|qr\\(.*\\))(?:[ims]*)\\z!s) { my \$re = eval(substr(\$tmp, 0, 2) eq 'qr' ? \$tmp : \"qr\$tmp\"); if (\$@) { [\"Invalid regex: \$@\", \$tmp] } else { [undef, \$re] } } ",
        "    else { [undef, \$tmp] } ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Convert string to regex if string is delimited by /.../ or qr(...)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::maybe_convert_to_re - Convert string to regex if string is delimited by /.../ or qr(...)

=head1 VERSION

This document describes version 0.008 of Data::Sah::Filter::perl::Str::maybe_convert_to_re (from Perl distribution Sah-Schemas-Str), released on 2022-06-09.

=head1 DESCRIPTION

Currently for the C<qr(...)> form, unlike in normal Perl, only parentheses C<(>
and C<)> are allowed as the delimiter.

Currently regex modifiers C<i>, C<m>, and C<s> are allowed at the end.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Str>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
