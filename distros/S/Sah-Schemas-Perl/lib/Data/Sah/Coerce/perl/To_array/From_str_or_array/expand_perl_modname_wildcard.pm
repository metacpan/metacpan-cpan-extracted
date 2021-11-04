package Data::Sah::Coerce::perl::To_array::From_str_or_array::expand_perl_modname_wildcard;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-05'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.040'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Expand wildcard of Perl module names',
        prio => 50,
        args => {
            ns_prefix => {
                schema => 'str*',
            },
        },
    };
}

sub coerce {
    require Data::Dmp;

    my %cargs = @_;

    my $dt = $cargs{data_term};
    my $gen_args = $cargs{args};

    my $ns_prefix = $gen_args->{ns_prefix};
    if (defined $ns_prefix) {
        $ns_prefix .= "::" unless $ns_prefix =~ /::\z/;
    }

    my $res = {};
    $res->{expr_match} = "ref($dt) eq '' || ref($dt) eq 'ARRAY'";
    $res->{modules}{"PERLANCAR::Module::List"} //= "0.004002";
    $res->{modules}{"String::Wildcard::Bash"} //= "0.040";
    $res->{expr_coerce} = join(
        "",
        "do { ",
        "my \$tmp = $dt; \$tmp = [\$tmp] unless ref \$tmp eq 'ARRAY'; ",
        "my \$i = 0; ",
        "while (\$i < \@\$tmp) { ",
        "  \$tmp->[\$i] =~ s!/!::!g; ",
        "  my \$el = \$tmp->[\$i++]; ",
        "  next unless String::Wildcard::Bash::contains_wildcard(\$el); ",
        "  my \$mods = PERLANCAR::Module::List::list_modules(" . (defined($ns_prefix) ? Data::Dmp::dmp($ns_prefix) . " . " : "") . "\$el, {wildcard=>1, list_modules=>1}); ",
        "  my \@mods = sort keys \%\$mods; ",
        (defined($ns_prefix) ? "  for (\@mods) { substr(\$_, 0, ".length($ns_prefix).") = '' } " : ""),
        "  if (\@mods) { splice \@\$tmp, \$i-1, 1, \@mods; \$i += \@mods - 1 } ",
        "} ", # while
        "\$tmp ",
        "}", # do
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_array::From_str_or_array::expand_perl_modname_wildcard

=head1 VERSION

This document describes version 0.040 of Data::Sah::Coerce::perl::To_array::From_str_or_array::expand_perl_modname_wildcard (from Perl distribution Sah-Schemas-Perl), released on 2021-10-05.

=head1 DESCRIPTION

This rule can expand wildcard of Perl module names in string (or string elements
in array) into array. Example:

 "Module::P*"
 ["Foo", "Module::P*", "Bar"]

will become, respectively:

 ["Module::Patch", "Module::Path", "Module::Pluggable"]
 ["Foo", "Module::Patch", "Module::Path", "Module::Pluggable", "Bar"]

when a string does not contain wildcard pattern, or if a pattern fails to match
any module name, it will be left unchanged, e.g.:

 ["Foo", "Fizz*", "Bar"]

will become, respectively:

 ["Foo", "Fizz*", "Bar"]

Additionally, for convenience, it also replaces "/" to "::", so:

 "Module/P*"

will also become:

 ["Module::Patch", "Module::Path", "Module::Pluggable"]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 SEE ALSO

L<Data::Sah::Coerce::perl::To_str::From_str::NormalizePerlModname>

L<Data::Sah::Coerce::perl::To_array::From_str_or_array::ExpandPerlModprefixWildcard>

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
