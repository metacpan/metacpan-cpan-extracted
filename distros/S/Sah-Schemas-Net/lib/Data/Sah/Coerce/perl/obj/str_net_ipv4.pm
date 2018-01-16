package Data::Sah::Coerce::perl::obj::str_net_ipv4;

our $DATE = '2018-01-14'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 2,
        enable_by_default => 0,
        might_die => 1,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{modules}{'NetAddr::IP'} //= 0;
    $res->{expr_match} = "!ref($dt)";
    $res->{expr_coerce} = join(
        "",
        "do { my \$ip = NetAddr::IP->new($dt) or die 'Invalid IP address syntax';",
        " \$ip->bits == 32 or die 'Not an IPv4 address (probably IPv6)';",
        " \$ip->masklen == 32 or die 'Not a single IPv4 address (an IP range)';",
        " \$ip }",
    );

    $res;
}

1;
# ABSTRACT: Coerce IPv4 address object from string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::obj::str_net_ipv4 - Coerce IPv4 address object from string

=head1 VERSION

This document describes version 0.002 of Data::Sah::Coerce::perl::obj::str_net_ipv4 (from Perl distribution Sah-Schemas-Net), released on 2018-01-14.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Net>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Net>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Net>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
