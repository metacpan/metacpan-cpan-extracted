package Data::Sah::Filter::perl::Unix::try_convert_unix_group_to_gid;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-29'; # DATE
our $DIST = 'Sah-Schemas-Unix'; # DIST
our $VERSION = '0.018'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 1,
        summary => 'Try to convert Unix groupname into GID, leave as-is when cannot convert',
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; if (\$tmp !~ /\\A[0-9]+\\z/) { my \@gr = getgrnam(\$tmp); \@gr ? \$gr[2] : \$tmp } else { \$tmp } }",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Unix::try_convert_unix_group_to_gid

=head1 VERSION

This document describes version 0.018 of Data::Sah::Filter::perl::Unix::try_convert_unix_group_to_gid (from Perl distribution Sah-Schemas-Unix), released on 2021-07-29.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Unix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::Filter::perl::Unix::convert_unix_group_to_gid> which dies when
failing to convert. Most of the time you'd want this rule.

L<Data::Sah::Filter::perl::Unix::try_convert_unix_user_to_uid>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
