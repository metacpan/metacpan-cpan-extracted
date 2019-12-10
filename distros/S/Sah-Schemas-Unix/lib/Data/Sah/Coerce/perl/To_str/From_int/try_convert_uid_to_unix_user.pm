package Data::Sah::Coerce::perl::To_str::From_int::try_convert_uid_to_unix_user;

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
        summary => 'Try to convert UID into Unix username, leave as-is if cannot convert',
        prio => 40,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "$dt =~ /\\A[0-9]+\\z/";
    $res->{expr_coerce} = join(
        "",
        "do { my \$tmp = $dt; my \@pw = getpwuid(\$tmp); \@pw ? \$pw[0] : \$tmp }",
    );

    $res;
}

1;
# ABSTRACT: Try to convert UID into Unix username, leave as-is if cannot convert

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_str::From_int::try_convert_uid_to_unix_user - Try to convert UID into Unix username, leave as-is if cannot convert

=head1 VERSION

This document describes version 0.009 of Data::Sah::Coerce::perl::To_str::From_int::try_convert_uid_to_unix_user (from Perl distribution Sah-Schemas-Unix), released on 2019-12-09.

=head1 SYNOPSIS

To use in a Sah schema:

 ["str",{"x.perl.coerce_rules"=>["From_int::try_convert_uid_to_unix_user"]}]

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

L<Data::Sah::Coerce::perl::To_str::From_int::convert_uid_to_unix_user> which
dies when failing to convert. Most of the time you'd want this rule.

L<Data::Sah::Coerce::perl::To_str::From_int::try_convert_gid_to_unix_group>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
