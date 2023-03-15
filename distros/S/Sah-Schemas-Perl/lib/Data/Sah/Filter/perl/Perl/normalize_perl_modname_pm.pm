package Data::Sah::Filter::perl::Perl::normalize_perl_modname_pm;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.048'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Normalize perl module name to Foo/Bar.pm form',
        might_fail => 1,
        examples => [
            {value=>"Foo:Bar", valid=>1, filtered_value=>"Foo/Bar.pm"},
            {value=>"Foo::Bar,arg1,arg2", valid=>1, filtered_value=>"Foo/Bar.pm=arg1,arg2"},
        ],
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; ",
        "if (ref \$tmp) { [\"Must be a string and not a reference\", \$tmp] } ",
        "else { ", (
            "my \$argssuffix = ''; \$argssuffix = \$1 if \$tmp =~ s/([=,].*)\\z//; \$argssuffix =~ s/\\A,/=/; ",    # extract args suffix (=arg1,arg2) first. we allow % in addition to =
            "my \$versuffix = ''; \$versuffix = \$1 if \$tmp =~ s/(\@[0-9][0-9A-Za-z]*(\\.[0-9A-Za-z_]+)*)\\z//; ", # extract version suffix part first
            "\$tmp = \$1 if \$tmp =~ m!\\A(\\w+(?:/\\w+)*)\.pm\\z!; ",
            "\$tmp =~ s!::?|/|\\.|-!::!g; ",
            "\$tmp =~ s!::!/!g; ",
            "[undef, \"\$tmp.pm\" . \$versuffix . \$argssuffix]; "),
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

Data::Sah::Filter::perl::Perl::normalize_perl_modname_pm

=head1 VERSION

This document describes version 0.048 of Data::Sah::Filter::perl::Perl::normalize_perl_modname_pm (from Perl distribution Sah-Schemas-Perl), released on 2023-01-19.

=head1 DESCRIPTION

This prefilter rule can normalize strings in the form of:

 Foo:Bar
 Foo-Bar
 Foo/Bar.pm
 Foo/Bar
 Foo.Bar

into:

 Foo/Bar.pm

This rule can also handle version after module name, e.g.:

 Foo/Bar.pm@1.23

as well as optional import arguments like perl's C<-M>:

 Foo/Bar.pm=arg1,arg2
 Foo/Bar.pm@1.23=arg1,arg2

For convenience with bash completion (because C<=> is by default a word-breaking
character in bash, while C<,> is not) you can use C<,> instead of C<=> and it
will be normalized to C<=>.

 Foo/Bar.pm,arg1,arg2           # will become Foo/Bar.pm=arg1,arg2
 Foo/Bar.pm@1.23,arg1,arg2      # will become Foo/Bar.pm@1.23=arg1,arg2

=for Pod::Coverage ^(meta|filter)$

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
