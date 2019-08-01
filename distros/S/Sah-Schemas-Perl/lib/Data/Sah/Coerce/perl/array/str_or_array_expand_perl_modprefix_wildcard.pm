package Data::Sah::Coerce::perl::array::str_or_array_expand_perl_modprefix_wildcard;

our $DATE = '2019-07-26'; # DATE
our $VERSION = '0.023'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "ref($dt) eq '' || ref($dt) eq 'ARRAY'";
    $res->{modules}{"PERLANCAR::Module::List"} //= "0.004004";
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
        "  my \$mods = PERLANCAR::Module::List::list_modules(\$el, {wildcard=>1, list_modules=>1}); ",
        "  my \@mods = sort keys \%\$mods; ",
        "  if (\@mods) { splice \@\$tmp, \$i-1, 1, \@mods; \$i += \@mods - 1 } ",
        "} ", # while
        "\$tmp ",
        "}", # do
    );

    $res;
}

1;
# ABSTRACT: Expand wildcard of Perl module prefixes

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::array::str_or_array_expand_perl_modprefix_wildcard - Expand wildcard of Perl module prefixes

=head1 VERSION

This document describes version 0.023 of Data::Sah::Coerce::perl::array::str_or_array_expand_perl_modprefix_wildcard (from Perl distribution Sah-Schemas-Perl), released on 2019-07-26.

=head1 DESCRIPTION

This rule can expand wildcard of Perl module prefixes in string (or string
elements in array) into array. Example:

 "Module::C*"
 ["Foo::", "Module::C*", "Bar::"]

will become, respectively:

 ["Module::CPANTS::", "Module::CPANfile::", "Module::CheckVersion::", "Module::CoreList::"]
 ["Foo::", "Module::CPANTS::", "Module::CPANfile::", "Module::CheckVersion::", "Module::CoreList::", "Bar::"]

when a string does not contain wildcard pattern, or if a pattern fails to match
any module name, it will be left unchanged, e.g.:

 ["Foo::", "Fizz*", "Bar::"]

will become, respectively:

 ["Foo::", "Fizz*", "Bar::"]

Additionally, for convenience, it also replaces "/" to "::", so:

 "Module/C*"

will also become:

 ["Module::CPANTS::", "Module::CPANfile::", "Module::CheckVersion::", "Module::CoreList::"]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::Coerce::perl::str::str_normalize_perl_modprefix>

L<Data::Sah::Coerce::perl::array::str_or_array_expand_perl_modname_wildcard>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
