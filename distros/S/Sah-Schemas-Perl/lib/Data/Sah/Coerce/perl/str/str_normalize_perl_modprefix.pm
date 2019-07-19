package Data::Sah::Coerce::perl::str::str_normalize_perl_modprefix;

our $DATE = '2019-07-05'; # DATE
our $VERSION = '0.020'; # VERSION

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

    $res->{expr_match} = "!ref($dt)";
    $res->{expr_coerce} = join(
        "",
        "do { my \$tmp = $dt; \$tmp =~ s!::?|/|\\.|-!::!g; \$tmp .= '::' if \$tmp =~ /\\A\\w+(::\\w+)*\\z/; \$tmp }",
    );

    $res;
}

1;
# ABSTRACT: Coerce perl::modprefix from str

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::str::str_normalize_perl_modprefix - Coerce perl::modprefix from str

=head1 VERSION

This document describes version 0.020 of Data::Sah::Coerce::perl::str::str_normalize_perl_modprefix (from Perl distribution Sah-Schemas-Perl), released on 2019-07-05.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
