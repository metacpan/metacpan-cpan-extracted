package Sah::Schema::date::tz_offset;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-27'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.008'; # VERSION

BEGIN {

    # taken from Wikipedia page: https://en.wikipedia.org/wiki/UTC%2B14:00 on Feb 27, 2020
our @TZ_STRING_OFFSETS = qw(
    -12:00 -11:00 -10:30 -10:00 -09:30 -09:00 -08:30 -08:00 -07:00
    -06:00 -05:00 -04:30 -04:00 -03:30 -03:00 -02:30 -02:00 -01:00 -00:44 -00:25:21
    -00:00 +00:00 +00:20 +00:30 +01:00 +01:24 +01:30 +02:00 +02:30 +03:00 +03:30 +04:00 +04:30 +04:51 +05:00 +05:30 +05:40 +05:45
    +06:00 +06:30 +07:00 +07:20 +07:30 +08:00 +08:30 +08:45 +09:00 +09:30 +09:45 +10:00 +10:30 +11:00 +11:30
    +12:00 +12:45 +13:00 +13:45 +14:00
);

our @TZ_INT_OFFSETS;
for (@TZ_STRING_OFFSETS) {
    /^([+-])(\d\d):(\d\d)(?::(\d\d))?$/
        or die "Unrecognized tz offset string: $_";
    push @TZ_INT_OFFSETS, ($1 eq '-' ? -1:1) * ($2*3600 + $3*60 + ($4 ? $4 : 0));
}

#use DD; dd \@TZ_INT_OFFSETS;

} # BEGIN

our $schema = [int => {
    summary => 'Timezone offset in seconds from UTC',
    in => \@TZ_INT_OFFSETS,
    description => <<'_',

Only timezone offsets that are known to exist are allowed. For example, 1 second
(+00:00:01) is not allowed. See `date::tz_offset_lax` for a more relaxed
validation.

A coercion from these form of string is provided:

    UTC

    UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21
    -14 or +12, -1400 or +12:00

A coercion from timezone name is also provided.

_
    'x.perl.coerce_rules' => ['From_str::tz_offset_strings'],
    'x.completion' => sub {
        require Complete::TZ;
        require Complete::Util;

        my %args = @_;

        Complete::Util::combine_answers(
            Complete::TZ::complete_tz_offset(word => $args{word}),
            Complete::TZ::complete_tz_name(word => $args{word}),
        );
    },
}, {}];

1;

# ABSTRACT: Timezone offset in seconds from UTC

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::tz_offset - Timezone offset in seconds from UTC

=head1 VERSION

This document describes version 0.008 of Sah::Schema::date::tz_offset (from Perl distribution Sah-Schemas-Date), released on 2020-02-27.

=head1 DESCRIPTION

Only timezone offsets that are known to exist are allowed. For example, 1 second
(+00:00:01) is not allowed. See C<date::tz_offset_lax> for a more relaxed
validation.

A coercion from these form of string is provided:

 UTC
 
 UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21
 -14 or +12, -1400 or +12:00

A coercion from timezone name is also provided.

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

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
