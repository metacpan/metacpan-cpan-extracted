package Data::Sah::Coerce::perl::To_str::From_int::convert_gid_to_unix_group;

# AUTHOR
our $DATE = '2019-12-09'; # DATE
our $DIST = 'Sah-Schemas-Unix'; # DIST
our $VERSION = '0.009'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Convert GID into Unix groupname, fail when groupname does not exist',
        prio => 40,
        might_fail => 1,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "$dt =~ /\\A[0-9]+\\z/";
    $res->{expr_coerce} = join(
        "",
        "do { my \$tmp = $dt; my \@gr = getgrgid(\$tmp); return [\"GID \$tmp has no associated group name\", undef] unless \@gr; [undef, \$gr[0]] }",
    );

    $res;
}

1;
# ABSTRACT: Convert GID into Unix groupname, fail when groupname does not exist

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_str::From_int::convert_gid_to_unix_group - Convert GID into Unix groupname, fail when groupname does not exist

=head1 VERSION

This document describes version 0.009 of Data::Sah::Coerce::perl::To_str::From_int::convert_gid_to_unix_group (from Perl distribution Sah-Schemas-Unix), released on 2019-12-09.

=head1 SYNOPSIS

To use in a Sah schema:

 ["str",{"x.perl.coerce_rules"=>["From_int::convert_gid_to_unix_group"]}]

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

=head1 SEE ALSO

L<Data::Sah::Coerce::perl::To_str::From_int::try_convert_gid_to_unix_group>
which leaves GID as-is when associated groupname cannot be found.

L<Data::Sah::Coerce::perl::To_str::From_int::convert_uid_to_unix_user>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
