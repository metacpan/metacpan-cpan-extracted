package Data::Sah::Coerce::perl::int::int_check_uid_exists;

our $DATE = '2019-09-11'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        prio => 50,
        might_fail => 1,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "1";
    $res->{expr_coerce} = join(
        "",
        "do { my \$tmp = $dt+0; my \@tmp = getpwuid(\$tmp); if (!\@tmp) { [\"UID \$tmp is not associated with any user\"] } else { [undef, \$tmp] } }",
    );

    $res;
}

1;
# ABSTRACT: Check that UID exists (has associated username) on the system

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::int::int_check_uid_exists - Check that UID exists (has associated username) on the system

=head1 VERSION

This document describes version 0.005 of Data::Sah::Coerce::perl::int::int_check_uid_exists (from Perl distribution Sah-Schemas-Unix), released on 2019-09-11.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Unix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
