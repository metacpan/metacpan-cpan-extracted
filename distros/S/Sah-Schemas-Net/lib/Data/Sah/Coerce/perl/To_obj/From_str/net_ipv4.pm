package Data::Sah::Coerce::perl::To_obj::From_str::net_ipv4;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-03'; # DATE
our $DIST = 'Sah-Schemas-Net'; # DIST
our $VERSION = '0.011'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Coerce IPv4 address object from string',
        might_fail => 1,
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
        "do { my \$ip = NetAddr::IP->new($dt); if (!\$ip) { ['Invalid IP address syntax'] } ",
        "elsif (\$ip->bits != 32) { ['Not an IPv4 address (probably IPv6)'] } ",
        "elsif (\$ip->masklen != 32) { ['Not a single IPv4 address (an IP range)'] } ",
        "else { [undef, \$ip] } ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Coerce IPv4 address object from string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_obj::From_str::net_ipv4 - Coerce IPv4 address object from string

=head1 VERSION

This document describes version 0.011 of Data::Sah::Coerce::perl::To_obj::From_str::net_ipv4 (from Perl distribution Sah-Schemas-Net), released on 2022-05-03.

=head1 SYNOPSIS

To use in a Sah schema:

 ["obj",{"x.perl.coerce_rules"=>["From_str::net_ipv4"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Net>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Net>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Net>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
