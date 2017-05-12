package Template::Plugin::Colour::RGB;

use Template::Colour::Class
    base    => 'Template::Colour::RGB Template::Plugin';

our $VERSION = 2.10;

sub new {
    my $class   = shift;
    my $context = shift;
    $class->SUPER::new(@_);
}

1;

__END__

=head1 NAME

Template::Plugin::Colour - Template plugin for colour manipulation

=head1 SYNOPSIS

    # long or short hex triplets, with or without '#'
    [% USE col = Colour.RGB('abc')     %]    
    [% USE col = Colour.RGB('#abc')    %]   
    [% USE col = Colour.RGB('ff0000')  %] 
    [% USE col = Colour.RGB('#ff0000') %]

    # decimal r, g, b values
    [% USE col = Colour.RGB(255, 128, 0) %]

    # named parameters
    [% USE col = Colour.RGB(red = 255, green = 128, blue = 0) %]

=head1 DESCRIPTION

This Template Toolkit plugin module allows you to represent and
manipulate colours using the RGB (red, green, blue) colour space.

You can create an RGB colour object by accessing the plugin directly:

    [% USE col = Colour.RGB('#112233') %]

Or via the Template::Plugin::Colour plugin.  

    [% USE col = Colour('#112233') %]

The default colour space is RGB so there's no need to specify it, but
you can if you like:

    [% USE col = Colour( rgb = '#112233' ) %]

The final option is to load the Colour plugin and then call the 
RGB method whenever you need a new colour.

    [% USE Colour;
       red   = Colour.RGB('#c00');
       green = Colour.RGB('#0c0');
       blue  = Colour.RGB('#00c');
    %]

You can also access the plugin using the 'Color' name instead of
'Colour' (note the spelling difference).

    [% USE col = Color.RGB('#112233') %]
    [% USE col = Color('#112233') %]
    [% USE Color;
       red   = Color.RGB('#c00');
       green = Color.RGB('#0c0');
       blue  = Color.RGB('#00c');
    %]

=head1 METHODS

=head2 new(@args)

Create a new RGB colour.  This method is invoked when you C<USE> the 
plugin from within a template.

    [% USE col = Colour.RGB('#ffccdd') %]

The colour can be specified as a short (3 digit) or long (6 digit)
hexadecimal number, with or without the leading '#'.  A list or
reference to a list of decimal red, green and blue values can also be
provided:

    [% USE col = Colour.RGB(100, 200, 300) %]
    [% USE col = Colour.RGB([100, 200, 300]) %]

Alternately, you can use a list or reference to a hash array of named
parameters:

    [% USE col = Colour.RGB( red=100, green=200, blue=250 ) %]
    [% USE col = Colour.RGB({ red=100, green=200, blue=250 }) %]

You can also create a Colour by calling the RGB method of the 
Colour plugin.  It looks very similar to the above, but you only
need the one USE directive.

    [% USE Colour;
       red   = Colour.RGB('#ff0000');
       green = Colour.RGB('#00ff00');
       blue  = Colour.RGB('#0000ff');
    %]

=head2 copy(@args)

Copy an existing colour.  

    [% orange = Colour.RGB('#ff7f00');
       redder = orange.copy.green(32);
    %]

You can specify one or more of the 'red', 'green' or 'blue' 
parameters to modify the new colour created.

    [% orange = Colour.RGB('#ff7f00');
       redder = orange.copy(green=32);
    %]

=head2 rgb($r,$g,$b)

Method to set all of the red, green and blue components in one go.
Any of the supported argument formats can be used.

    [% col.rgb('#ff1020') %]
    [% col.rgb(255, 16, 32) %]
    [% col.rgb(red=255, green=16, blue=32) %]

When called without any arguments it simply returns itself, a blessed
reference to a list of red, green and blue components.  This is
effectively a no-op, but can be useful to ensure that you have a colour
defined in a particular colour space.

For example, say we have two colours, one of which is defined in the
RGB colour space, the other in HSV (Hue, Saturation, Value - see
L<Template::Plugin::Colour::HSV>).

    [% red    = Colour.RGB('#C00');
       orange = Colour.HSV(30, 255, 255);
    %]

If we iterate over these colours in a FOREACH loop then we can't be 
sure if the colour we're looking at is defined in the RGB or HSV colour
space.  By calling the 'rgb' method against it we can convert any
HSV colours to RGB, and leave those that are already RGB as they are.

    [% FOREACH col IN [red, orange] %]
       <span style="background-color: [% col.rgb.html %]">
        Sample Colour: [% col.rgb.html %]
       </span>
    [% END %]

=head2 red($r)

Get or set the red component of the colour.  The value is decimal and
clipped to the range 0..255

    [% col.red(255) %]
    [% col.red %]           # 255

=head2 green($g)

Get or set the green component of the colour.  The value is decimal and
clipped to the range 0..255

    [% col.green(255) %]
    [% col.green %]         # 255

=head2 blue($b)

Get or set the blue component of the colour.  The value is decimal and
clipped to the range 0..255

    [% col.blue(255) %]
    [% col.blue %]          # 255

=head2 grey($g)

Get or set the greyscale value of the colour.  When called with an
argument, it sets each of the red, green and blue components to that
value.

    [% col.grey(128) %]
    [% col.red   %]         # 128
    [% col.green %]         # 128
    [% col.blue  %]         # 128

When called without an argument, it returns the greyscale value for
the current RGB colour.  Because our eyes do not perceive the
different red, green and blue components with equal intensity (green
is the dominant colour in defining the perception of brightness,
whereas blue contributes very little), the value returned is one 
based on the following formula which is widely accepted to give
the most accurate value:

    (red * 0.222) + (green * 0.707) + (blue * 0.071)

=head2 hex($x)

Get or set the value using hexadecimal notation.  When called with an 
argument, it sets the red, green and blue components according to the 
value.  This can be specified in short (3 digit) or long (6 digit) form,
with or without a leading '#'.

    [% col.hex('369')     %]
    [% col.hex('#369')    %]
    [% col.hex('336699')  %]
    [% col.hex('#336699') %]

When called without any arguments, it returns the current value as
a 6 digit hexadecimal string without the leading '#'.

    [% col.hex %]               # 336699

Any alphabetical characters ('a'-'f') are output in lower case.

    [% col.hex('#AABBCC') %]
    [% col.hex %]               # aabbcc

Use the HEX() method if you want them output in upper case.

=head2 HEX($x)

Wrapper around the hex() method which returns the hex string
converted to upper case.

    [% col.hex('#aabbcc') %]
    [% col.hex %]               # AABBCC

=head2 html($h)

Wrapper around the hex() method which prefixes the returned value
with a '#', suitable for using directly as an HTML or CSS colour.

    [% col.hex('#aabbcc') %]
    [% col.html %]              # #aabbcc

=head2 HTML($h)

Same as the html() method, but returning the colour in upper case,
as per HEX().

    [% col.hex('#aabbcc') %]
    [% col.html %]              # #AABBCC

=head2 hsv($h,$s,$v)

Convert the RGB colour to one in the HSV (hue, saturation, value)
colour space, by creating a new Template::Plugin::Colour::HSV object.
If arguments are provided then these are passed to the HSV constructor
for hue, saturation and value parameters.  Otherwise they are computed
from the current RGB colour.

    [% USE rgb = Colour('#102030') %]

    [% hsv = rgb.hsv  %]
    [% hsv.hue        %]    # 210  
    [% hsv.saturation %]    # 170
    [% hsv.value      %]    #  48

See Template::Plugin::Colour::HSV for further information.

=head1 AUTHOR

Andy Wardley E<lt>abw@cpan.orgE<gt>, L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 2006-2012 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Colour>, L<Template::Plugin::Colour::HSV>,
L<Template::Plugin>


