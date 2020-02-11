package Data::Sah::Filter::perl::Unix::convert_uid_to_unix_user;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-11'; # DATE
our $DIST = 'Sah-Schemas-Unix'; # DIST
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 1,
        summary => 'Convert UID into Unix username, fail when username does not exist',
        might_fail => 1,
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; if (\$tmp =~ /\\A[0-9]+\\z/) { my \@pw = getpwuid(\$tmp); return [\"UID \$tmp has no associated username\", \$tmp] unless \@pw; return [undef, \$pw[0]] } [undef, \$tmp] }",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Unix::convert_uid_to_unix_user

=head1 VERSION

This document describes version 0.010 of Data::Sah::Filter::perl::Unix::convert_uid_to_unix_user (from Perl distribution Sah-Schemas-Unix), released on 2020-02-11.

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

L<Data::Sah::Filter::perl::Unix::try_convert_uid_to_unix_user> which leaves UID
as-is when associated username cannot be found.

L<Data::Sah::Filter::perl::Unix::convert_gid_to_unix_group>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
