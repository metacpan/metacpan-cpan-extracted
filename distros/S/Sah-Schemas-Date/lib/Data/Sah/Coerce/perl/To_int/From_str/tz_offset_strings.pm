package Data::Sah::Coerce::perl::To_int::From_str::tz_offset_strings;

# AUTHOR
our $DATE = '2021-08-04'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.017'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Convert timezone offset strings like UTC-500, UTC, or UTC+12:30 to number of offset seconds from UTC',
        might_fail => 1,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    #                                #1=label      #2=sgn #3=hour           #4=min       #5=sec
    $res->{expr_match} = "$dt =~ /\\A(UTC|GMT)?(?: ([+-]) (\\d\\d?)(?: (?::?(\\d\\d)(?:: (\\d\\d) )?)?)?)?\\z/x";
    $res->{expr_coerce} = join(
        "",
        "do { ",

        "!\$1 && !\$2 ? ['Cannot be empty', $dt] : [undef, \$2 ? ((\$2 eq '-' ? -1:1)*(\$3*3600 + (\$4 ? \$4*60:0) + (\$5 ? \$5:0))) : 0]",

        "}", # do
    );

    $res;
}

1;
# ABSTRACT: Convert timezone offset strings like UTC-500, UTC, or UTC+12:30 to number of offset seconds from UTC

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_int::From_str::tz_offset_strings - Convert timezone offset strings like UTC-500, UTC, or UTC+12:30 to number of offset seconds from UTC

=head1 VERSION

This document describes version 0.017 of Data::Sah::Coerce::perl::To_int::From_str::tz_offset_strings (from Perl distribution Sah-Schemas-Date), released on 2021-08-04.

=head1 SYNOPSIS

To use in a Sah schema:

 ["int",{"x.perl.coerce_rules"=>["From_str::tz_offset_strings"]}]

=head1 DESCRIPTION

This rule coerces time zone offsets like:

 UTC
 UTC+7
 UTC+700
 UTC-0700
 UTC+07:00

respectively to number of offset seconds from UTC:

 0
 25200
 25200
 -25200
 25200

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
