# DESCRIPTION

This module helps to create Heading Styles in [OpenOffice::OODoc](https://metacpan.org/pod/OpenOffice%3A%3AOODoc) documents.
Instead of blindly creating new styles at will, one can call
`establishHeadingStyle` that will honour any exisiting style, but will create
a new one if needed.

# METHODS

## establishHeadingStyle

returns an OpenOffice::OODoc Heading Style Element for a given level

    my $level = 2;
    my $style_definition = {
        paragraph   => { top    => '0.1390in', bottom => '0.0835in' },
        text        => { size   =>     '115%', weight =>     'bold' },
    };
    my $heading_style = $oodoc_style
        ->establishHeadingStyle( $level, $style_definition );

If the style was not already present in the 'Styles' part of the document, it
will be created and added into the document.

The style-definition is an optional argument. If not provided, it will use what
is found in `HEADING_DEFINITIONS` package HashRef. That is pre-populated with
the defaults from Libre Office.

See below.

A newly created heading style inherrits from the `Heading` style and will apply
font settings like Libre Office does: relative `font-size`, `font-weight` and
`font-style` and more.

CAVEAT: `$level` will be treated turned into integer values. This means that if
it does not start with a number will be treated as "Heading 0" styles and
decimals will be truncated. See `int`

## createHeadingStyle

Creates a new Heading Style in the 'styles' part for a given level. It accepts
an optional style-definition HashRef like the above.

# MORE...

## Heading Style Definitions

This module does some convenience mapping between params and that what
[OpenOffice::OODoc](https://metacpan.org/pod/OpenOffice%3A%3AOODoc) internally uses in their xml. A heading style for this
module look like the following hash structure:

    paragraph => {
        top        => '9.9999in',
        bottom     => '9.9999mm',
    },
    text      => {
        size       => 'huge',
        weight     => 'super-heavy',
        style      => 'strike-through',
        family     => 'fantasy',
        name       => 'Noteworthy',
        font_style => 'Condensed',
    },

- top

    the marging at the top of the heading, for example:'0.1665in'.

- bottom

    the margin at the bottom of the heading, for example '0.0835in'.

- size

    the relative size of the 'parent Heading' style, like: '130%'.

- weight

    the font weight of the heading style, for example 'bold'.

- style

    the font styling for the heading, like 'italics'.

- name

    the name of the font to use, note that not all fonts are portable

- family

    the main family it is part of, like 'sans' and 'serif'

    item font\_style

    the font it's own style name, like 'narow'. 'light', or 'heavy'

## $$HEADING\_DEFINITIONS

This variable should hold a HashRef to a list of Heading Style Definitions. The
keys should be `Heading 1` through `Heading 6` when dealing with HTML tags. In
Libre Office, there are 10 diferent styles.

You can set this HashRef so `createHeadingStyle` has defaults to pick from if
not provided when calling that method.
