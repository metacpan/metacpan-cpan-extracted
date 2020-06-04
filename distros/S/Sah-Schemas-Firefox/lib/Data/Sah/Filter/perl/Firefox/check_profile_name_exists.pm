package Data::Sah::Filter::perl::Firefox::check_profile_name_exists;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-04'; # DATE
our $DIST = 'Sah-Schemas-Firefox'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 1,
        summary => 'Check that profile name exists in local Firefox installation',
        might_fail => 1,
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};
    $res->{modules}{"Firefox::Util::Profile"} //= 0;
    $res->{expr_filter} = join(
        "",
        "do { ",
        "  my \$tmp = $dt; ",
        "  my \$dir = Firefox::Util::Profile::get_firefox_profile_dir(\$tmp); ",
        "  if (!defined \$dir) { [\"No such Firefox profile\", \$tmp] } else { [undef, \$tmp] } ",
        "}",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Firefox::check_profile_name_exists

=head1 VERSION

This document describes version 0.002 of Data::Sah::Filter::perl::Firefox::check_profile_name_exists (from Perl distribution Sah-Schemas-Firefox), released on 2020-06-04.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Firefox>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Firefox>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Firefox>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
