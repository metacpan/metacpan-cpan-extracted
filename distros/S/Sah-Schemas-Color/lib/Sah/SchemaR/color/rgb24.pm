package Sah::SchemaR::color::rgb24;

our $DATE = '2021-07-19'; # DATE
our $VERSION = '0.014'; # VERSION

our $rschema = ["str",[{examples=>[{valid=>1,validated_value=>"000000",value=>"000000"},{valid=>1,validated_value=>"000000",value=>"black"},{valid=>1,validated_value=>"ffffcc",value=>"FFffcc"},{valid=>1,validated_value=>"ffffcc",value=>"#FFffcc"},{valid=>0,value=>"foo"}],match=>qr(\A[0-9A-Fa-f]{6}\z),summary=>"RGB 24-digit color, a hexdigit e.g. ffcc00","x.completion"=>["colorname"],"x.perl.coerce_rules"=>["From_str::rgb24_from_colorname_X_or_code"]}],["str"]];

1;
# ABSTRACT: RGB 24-digit color, a hexdigit e.g. ffcc00

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaR::color::rgb24 - RGB 24-digit color, a hexdigit e.g. ffcc00

=head1 VERSION

This document describes version 0.014 of Sah::SchemaR::color::rgb24 (from Perl distribution Sah-Schemas-Color), released on 2021-07-19.

=head1 DESCRIPTION

This module is automatically generated by Dist::Zilla::Plugin::Sah::Schemas during distribution build.

A Sah::SchemaR::* module is useful if a client wants to quickly lookup the base type of a schema without having to do any extra resolving. With Sah::Schema::*, one might need to do several lookups if a schema is based on another schema, and so on. Compare for example L<Sah::Schema::poseven> vs L<Sah::SchemaR::poseven>, where in Sah::SchemaR::poseven one can immediately get that the base type is C<int>. Currently L<Perinci::Sub::Complete> uses Sah::SchemaR::* instead of Sah::Schema::* for reduced startup overhead when doing tab completion.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
