package Regexp::Pattern::DefHash;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-22'; # DATE
our $DIST = 'Regexp-Pattern-DefHash'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

my @prop_examples = (
    {str=>'p', matches=>1},
    {str=>'_', matches=>1},
    {str=>'prop', matches=>1},
    {str=>'Prop2', matches=>1},
    {str=>'prop_', matches=>1},

    {str=>'0prop', matches=>0, summary=>'Cannot start with digit'},
    {str=>'prop-erty', matches=>0, summary=>'Invalid character: dash'},
    {str=>'property ', matches=>0, summary=>'Invalid character: whitespace'},
);

my @attr_examples = (
    {str=>'.attr', matches=>1},
    {str=>'._attr', matches=>1},
    {str=>'.attr1.subattr2', matches=>1},
    {str=>'prop.attr1', matches=>1},
    {str=>'_prop._attr1', matches=>1},
    {str=>'Prop.attr1.subattr2.Subattr3', matches=>1},
    {str=>'_prop.attr1', matches=>1},

    {str=>'.0attr', matches=>0, summary=>'Cannot start with digit (1)'},
    {str=>'prop.0attr', matches=>0, summary=>'Cannot start with digit (2)'},
    {str=>'prop.attr.0subattr', matches=>0, summary=>'Cannot start with digit (3)'},
    {str=>'.attr-ibute', matches=>0, summary=>'Invalid character: dash (1)'},
    {str=>'prop-erty.attribute', matches=>0, summary=>'Invalid character: dash (2)'},
    {str=>'prop.attr-ibute', matches=>0, summary=>'Invalid character: dash (3)'},
    {str=>'property .attr', matches=>0, summary=>'Invalid character: whitespace (1)'},
    {str=>'property.attr ', matches=>0, summary=>'Invalid character: whitespace (2)'},
    {str=>'.attr ', matches=>0, summary=>'Invalid character: whitespace (3)'},

    {str=>'.', matches=>0, summary=>'Invalid syntax: dot only'},
    {str=>'..attr', matches=>0, summary=>'Invalid syntax: double dot'},
    {str=>'attr.', matches=>0, summary=>'Invalid syntax: dot without attr'},
    {str=>'attr..', matches=>0, summary=>'Invalid syntax: dot without attr (2)'},
);

my $patspec_prop_or_attr = {
    summary => 'Attribute key or property key',
    pat => qr/\A(?:([A-Za-z_][A-Za-z0-9_]*)|([A-Za-z_][A-Za-z0-9_]*)?\.([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*))\z/,
    tags => ['anchored', 'capturing'],
    description => <<'_',

All keys in defhash must match this pattern.

_
    examples => [
        @prop_examples,
        @attr_examples,

        {str=>'', matches=>0, summary=>'Empty'},
    ],
};

our %RE = (
    prop => {
        summary => 'Property key',
        pat => qr/\A[A-Za-z_][A-Za-z0-9_]*\z/,
        tags => ['anchored'],
        examples => [
            @prop_examples,

            {str=>'', matches=>0, summary=>'Empty'},

            {str=>'prop.attr', matches=>0, summary=>'Attribute, not property'},
            {str=>'.attr', matches=>0, summary=>'Attribute, not property'},
        ],
    },
    attr => {
        summary => 'Attribute key',
        pat => qr/\A([A-Za-z_][A-Za-z0-9_]*)?\.([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)\z/,
        tags => ['anchored', 'capturing'],
        examples => [
            @attr_examples,

            {str=>'', matches=>0, summary=>'Empty'},

            {str=>'p', matches=>0, summary=>'Property, not attribute'},
            {str=>'_', matches=>0, summary=>'Property, not attribute'},
        ],
    },

    attr_part => {
        summary => 'Attribute part in attribute key',
        pat => qr/\A[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*\z/,
        tags => ['anchored'],
        examples => [
            {str=>'', matches=>0, summary=>'Empty'},

            {str=>'p', matches=>1},
            {str=>'p.q', matches=>1},
            {str=>'.p', matches=>0, summary=>'Dot prefix must not be included'},
        ],
    },

    prop_or_attr => $patspec_prop_or_attr,

    key => $patspec_prop_or_attr, # alias for prop_or_attr
);

1;
# ABSTRACT: Regexp patterns related to DefHash

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::DefHash - Regexp patterns related to DefHash

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::DefHash (from Perl distribution Regexp-Pattern-DefHash), released on 2021-07-22.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("DefHash::attr");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 REGEXP PATTERNS

=over

=item * attr

Tags: anchored, capturing

Attribute key.

Examples:

Example #1.

 ".attr" =~ re("DefHash::attr");  # matches

Example #2.

 "._attr" =~ re("DefHash::attr");  # matches

Example #3.

 ".attr1.subattr2" =~ re("DefHash::attr");  # matches

Example #4.

 "prop.attr1" =~ re("DefHash::attr");  # matches

Example #5.

 "_prop._attr1" =~ re("DefHash::attr");  # matches

Example #6.

 "Prop.attr1.subattr2.Subattr3" =~ re("DefHash::attr");  # matches

Example #7.

 "_prop.attr1" =~ re("DefHash::attr");  # matches

Cannot start with digit (1).

 ".0attr" =~ re("DefHash::attr");  # DOESN'T MATCH

Cannot start with digit (2).

 "prop.0attr" =~ re("DefHash::attr");  # DOESN'T MATCH

Cannot start with digit (3).

 "prop.attr.0subattr" =~ re("DefHash::attr");  # DOESN'T MATCH

Invalid character: dash (1).

 ".attr-ibute" =~ re("DefHash::attr");  # DOESN'T MATCH

Invalid character: dash (2).

 "prop-erty.attribute" =~ re("DefHash::attr");  # DOESN'T MATCH

Invalid character: dash (3).

 "prop.attr-ibute" =~ re("DefHash::attr");  # DOESN'T MATCH

Invalid character: whitespace (1).

 "property .attr" =~ re("DefHash::attr");  # DOESN'T MATCH

Invalid character: whitespace (2).

 "property.attr " =~ re("DefHash::attr");  # DOESN'T MATCH

Invalid character: whitespace (3).

 ".attr " =~ re("DefHash::attr");  # DOESN'T MATCH

Invalid syntax: dot only.

 "." =~ re("DefHash::attr");  # DOESN'T MATCH

Invalid syntax: double dot.

 "..attr" =~ re("DefHash::attr");  # DOESN'T MATCH

Invalid syntax: dot without attr.

 "attr." =~ re("DefHash::attr");  # DOESN'T MATCH

Invalid syntax: dot without attr (2).

 "attr.." =~ re("DefHash::attr");  # DOESN'T MATCH

Empty.

 "" =~ re("DefHash::attr");  # DOESN'T MATCH

Property, not attribute.

 "p" =~ re("DefHash::attr");  # DOESN'T MATCH

Property, not attribute.

 "_" =~ re("DefHash::attr");  # DOESN'T MATCH

=item * attr_part

Tags: anchored

Attribute part in attribute key.

Examples:

Empty.

 "" =~ re("DefHash::attr_part");  # DOESN'T MATCH

Example #2.

 "p" =~ re("DefHash::attr_part");  # matches

Example #3.

 "p.q" =~ re("DefHash::attr_part");  # matches

Dot prefix must not be included.

 ".p" =~ re("DefHash::attr_part");  # DOESN'T MATCH

=item * key

Tags: anchored, capturing

Attribute key or property key.

All keys in defhash must match this pattern.


Examples:

Example #1.

 "p" =~ re("DefHash::key");  # matches

Example #2.

 "_" =~ re("DefHash::key");  # matches

Example #3.

 "prop" =~ re("DefHash::key");  # matches

Example #4.

 "Prop2" =~ re("DefHash::key");  # matches

Example #5.

 "prop_" =~ re("DefHash::key");  # matches

Cannot start with digit.

 "0prop" =~ re("DefHash::key");  # DOESN'T MATCH

Invalid character: dash.

 "prop-erty" =~ re("DefHash::key");  # DOESN'T MATCH

Invalid character: whitespace.

 "property " =~ re("DefHash::key");  # DOESN'T MATCH

Example #9.

 ".attr" =~ re("DefHash::key");  # matches

Example #10.

 "._attr" =~ re("DefHash::key");  # matches

Example #11.

 ".attr1.subattr2" =~ re("DefHash::key");  # matches

Example #12.

 "prop.attr1" =~ re("DefHash::key");  # matches

Example #13.

 "_prop._attr1" =~ re("DefHash::key");  # matches

Example #14.

 "Prop.attr1.subattr2.Subattr3" =~ re("DefHash::key");  # matches

Example #15.

 "_prop.attr1" =~ re("DefHash::key");  # matches

Cannot start with digit (1).

 ".0attr" =~ re("DefHash::key");  # DOESN'T MATCH

Cannot start with digit (2).

 "prop.0attr" =~ re("DefHash::key");  # DOESN'T MATCH

Cannot start with digit (3).

 "prop.attr.0subattr" =~ re("DefHash::key");  # DOESN'T MATCH

Invalid character: dash (1).

 ".attr-ibute" =~ re("DefHash::key");  # DOESN'T MATCH

Invalid character: dash (2).

 "prop-erty.attribute" =~ re("DefHash::key");  # DOESN'T MATCH

Invalid character: dash (3).

 "prop.attr-ibute" =~ re("DefHash::key");  # DOESN'T MATCH

Invalid character: whitespace (1).

 "property .attr" =~ re("DefHash::key");  # DOESN'T MATCH

Invalid character: whitespace (2).

 "property.attr " =~ re("DefHash::key");  # DOESN'T MATCH

Invalid character: whitespace (3).

 ".attr " =~ re("DefHash::key");  # DOESN'T MATCH

Invalid syntax: dot only.

 "." =~ re("DefHash::key");  # DOESN'T MATCH

Invalid syntax: double dot.

 "..attr" =~ re("DefHash::key");  # DOESN'T MATCH

Invalid syntax: dot without attr.

 "attr." =~ re("DefHash::key");  # DOESN'T MATCH

Invalid syntax: dot without attr (2).

 "attr.." =~ re("DefHash::key");  # DOESN'T MATCH

Empty.

 "" =~ re("DefHash::key");  # DOESN'T MATCH

=item * prop

Tags: anchored

Property key.

Examples:

Example #1.

 "p" =~ re("DefHash::prop");  # matches

Example #2.

 "_" =~ re("DefHash::prop");  # matches

Example #3.

 "prop" =~ re("DefHash::prop");  # matches

Example #4.

 "Prop2" =~ re("DefHash::prop");  # matches

Example #5.

 "prop_" =~ re("DefHash::prop");  # matches

Cannot start with digit.

 "0prop" =~ re("DefHash::prop");  # DOESN'T MATCH

Invalid character: dash.

 "prop-erty" =~ re("DefHash::prop");  # DOESN'T MATCH

Invalid character: whitespace.

 "property " =~ re("DefHash::prop");  # DOESN'T MATCH

Empty.

 "" =~ re("DefHash::prop");  # DOESN'T MATCH

Attribute, not property.

 "prop.attr" =~ re("DefHash::prop");  # DOESN'T MATCH

Attribute, not property.

 ".attr" =~ re("DefHash::prop");  # DOESN'T MATCH

=item * prop_or_attr

Tags: anchored, capturing

Attribute key or property key.

All keys in defhash must match this pattern.


Examples:

Example #1.

 "p" =~ re("DefHash::prop_or_attr");  # matches

Example #2.

 "_" =~ re("DefHash::prop_or_attr");  # matches

Example #3.

 "prop" =~ re("DefHash::prop_or_attr");  # matches

Example #4.

 "Prop2" =~ re("DefHash::prop_or_attr");  # matches

Example #5.

 "prop_" =~ re("DefHash::prop_or_attr");  # matches

Cannot start with digit.

 "0prop" =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid character: dash.

 "prop-erty" =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid character: whitespace.

 "property " =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Example #9.

 ".attr" =~ re("DefHash::prop_or_attr");  # matches

Example #10.

 "._attr" =~ re("DefHash::prop_or_attr");  # matches

Example #11.

 ".attr1.subattr2" =~ re("DefHash::prop_or_attr");  # matches

Example #12.

 "prop.attr1" =~ re("DefHash::prop_or_attr");  # matches

Example #13.

 "_prop._attr1" =~ re("DefHash::prop_or_attr");  # matches

Example #14.

 "Prop.attr1.subattr2.Subattr3" =~ re("DefHash::prop_or_attr");  # matches

Example #15.

 "_prop.attr1" =~ re("DefHash::prop_or_attr");  # matches

Cannot start with digit (1).

 ".0attr" =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Cannot start with digit (2).

 "prop.0attr" =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Cannot start with digit (3).

 "prop.attr.0subattr" =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid character: dash (1).

 ".attr-ibute" =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid character: dash (2).

 "prop-erty.attribute" =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid character: dash (3).

 "prop.attr-ibute" =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid character: whitespace (1).

 "property .attr" =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid character: whitespace (2).

 "property.attr " =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid character: whitespace (3).

 ".attr " =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid syntax: dot only.

 "." =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid syntax: double dot.

 "..attr" =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid syntax: dot without attr.

 "attr." =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Invalid syntax: dot without attr (2).

 "attr.." =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

Empty.

 "" =~ re("DefHash::prop_or_attr");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-DefHash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-DefHash>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-DefHash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DefHash> specification.

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
