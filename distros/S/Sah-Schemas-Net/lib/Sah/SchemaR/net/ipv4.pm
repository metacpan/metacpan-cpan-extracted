package Sah::SchemaR::net::ipv4;

our $DATE = '2020-05-27'; # DATE
our $VERSION = '0.009'; # VERSION

our $rschema = ["obj",[{examples=>[{valid=>0,value=>""},{valid=>0,value=>"12.345.67.89"}],isa=>"NetAddr::IP",summary=>"IPv4 address","x.perl.coerce_rules"=>["From_str::net_ipv4"]}],["obj"]];

1;
# ABSTRACT: IPv4 address

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaR::net::ipv4 - IPv4 address

=head1 VERSION

This document describes version 0.009 of Sah::SchemaR::net::ipv4 (from Perl distribution Sah-Schemas-Net), released on 2020-05-27.

=head1 DESCRIPTION

This module is automatically generated by Dist::Zilla::Plugin::Sah::Schemas during distribution build.

A Sah::SchemaR::* module is useful if a client wants to quickly lookup the base type of a schema without having to do any extra resolving. With Sah::Schema::*, one might need to do several lookups if a schema is based on another schema, and so on. Compare for example L<Sah::Schema::poseven> vs L<Sah::SchemaR::poseven>, where in Sah::SchemaR::poseven one can immediately get that the base type is C<int>. Currently L<Perinci::Sub::Complete> uses Sah::SchemaR::* instead of Sah::Schema::* for reduced startup overhead when doing tab completion.

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

This software is copyright (c) 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
