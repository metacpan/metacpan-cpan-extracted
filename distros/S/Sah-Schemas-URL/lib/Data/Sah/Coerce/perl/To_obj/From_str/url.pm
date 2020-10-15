package Data::Sah::Coerce::perl::To_obj::From_str::url;

# AUTHOR
our $DATE = '2020-05-27'; # DATE
our $DIST = 'Sah-Schemas-URL'; # DIST
our $VERSION = '0.012'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce URL object (URI) from string',
        might_fail => 1,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'URI';

    my $res = {};

    $res->{modules}{'URI'} //= 0;
    $res->{expr_match} = "!ref($dt)";
    if ($coerce_to eq 'str') {
        $res->{expr_coerce} = $dt;
    } elsif ($coerce_to eq 'URI') {
        $res->{expr_coerce} = join(
            "",
            "do { my \$url = URI->new($dt); if (!\$url) { ['Invalid URL'] } else { [undef, \$url] } }",
        );
    }
    $res;
}

1;
# ABSTRACT: Coerce URL object (URI) from string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_obj::From_str::url - Coerce URL object (URI) from string

=head1 VERSION

This document describes version 0.012 of Data::Sah::Coerce::perl::To_obj::From_str::url (from Perl distribution Sah-Schemas-URL), released on 2020-05-27.

=head1 SYNOPSIS

To use in a Sah schema:

 ["obj",{"x.perl.coerce_rules"=>["From_str::url"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-URL>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-URL>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-URL>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
