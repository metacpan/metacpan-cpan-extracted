package Template::Plugin::Colour::HSV;

use Template::Colour::Class
    base    => 'Template::Colour::HSV Template::Plugin';

our $VERSION = 2.10;

sub new {
    my $class   = shift;
    my $context = shift;
    $class->SUPER::new(@_);
}


1;

__END__

=head1 NAME

Template::Plugin::Colour::HSV - Template plugin for HSV colours

=head1 SYNOPSIS

    [% USE col = Colour.HSV(50, 255, 128) %]

    [% col.hue %]                          # 50
    [% col.sat %] / [% col.saturation %]   # 255
    [% col.val %] / [% col.value %]        # 128

=head1 DESCRIPTION

This Template Toolkit plugin module creates an object that represents
a colour in the HSV (hue, saturation, value) colour space.

You can create an HSV colour object by accessing the plugin directly:

    [% USE col = Colour.HSV(50, 255, 128) %]

Or via the Template::Plugin::Colour plugin, specifying the 'HSV' 
colour space in either upper or lower case.

    [% USE col = Colour( hsv = [50, 255, 128] ) %]
    [% USE col = Colour( HSV = [50, 255, 128] ) %]

The final option is to load the Colour plugin and then call the 
HSV method whenever you need a new colour.

    [% USE Colour;
       red   = Colour.HSV(0, 255, 204);
       green = Colour.HSV(120, 255, 204);
       blue  = Colour.HSV(240, 255, 204);
    %]

You can also access the plugin using the 'Color' name instead of
'Colour' (note the spelling difference).

    [% USE col = Color.HSV(50, 255, 128) %]
    [% USE col = Color( hsv = [50, 255, 128] ) %]
    [% USE Color;
       red   = Color.HSV(0, 255, 204);
       green = Color.HSV(120, 255, 204);
       blue  = Color.HSV(240, 255, 204);
    %]

=head1 METHODS

=head2 new(@args)

Create a new HSV colour.  This method is invoked when you C<USE> the 
plugin from within a template.

    [% USE Colour.HSV(50, 255, 128) %]

The colour is specified as three decimal values (or a reference to a
list of three values) representing the hue (0-359 degrees), saturation
(0-255) and value (0-255) components.

    [% USE Colour.HSV(50, 255, 128) %]
    [% USE Colour.HSV([50, 255, 128]) %]

Alternately you can use named parameters

    [% USE Colour.HSV( hue=50, saturation=255, value=128) %]
    [% USE Colour.HSV({ hue=50, saturation=255, value=128 }) %]

You can also create a Colour by calling the HSV method of the 
Colour plugin.  It looks very similar to the above, but you only
need the one USE directive.

    [% USE Colour;
       orange  = Colour.HSV(30, 255, 255);
       lighter = Colour.HSV(30, 127, 255);
       darker  = Colour.HSV(20, 255, 127);
    %]

=head2 copy(@args)

Copy an existing colour.  

    [% orange  = Colour.HSV(30, 255, 255);
       lighter = orange.copy.saturation(127);
    %]

You can specify one or more of the 'hue', 'saturation' (or 'sat') or
'value' (or 'val') parameters to modify the new colour created.

    [% orange  = Colour.HSV('#ff7f00');
       lighter = orange.copy( saturation = 127 );
       darker  = orange.copy( value = 127 );
    %]

=head2 hue($h)

Get or set the hue of the colour.  The value is decimal and
clipped to the range 0-359.

    [% col.hue(300) %]
    [% col.hue %]           # 300

=head2 saturation($s)

Get or set the saturation of the colour.  The value is decimal and
clipped to the range 0..255

    [% col.saturation(255) %]
    [% col.saturation %]         # 255

Lazy people and bad typists will be pleased to know that sat() is
provided as an alias for saturation().

=head2 value($v)

Get or set the value component of the colour.  The value is decimal
and clipped to the range 0..255

    [% col.value(255) %]
    [% col.value %]          # 255

Lazy people and bad typists will be pleased to know that val() is
provided as an alias for value().  But to be honest, if you find it
difficult typing those extra two characters for the greater good of
increased clarity then you should be ashamed of yourself!

=head2 rgb($r,$g,$b)

Convert the HSV colour to one in the RGB (red, green, blue) colour
space, by creating a new Template::Plugin::Colour::RGB object.  If
arguments are provided then these are passed to the RGB constructor
for red, green, and blue parameters.  Otherwise they are computed from
the current HSV colour.

    [% USE hsv = Colour.HSV(210, 170, 48) %]

    [% rgb = hsv.rgb %]
    [% rgb.red       %]    # 16
    [% rgb.green     %]    # 32
    [% rgb.blue      %]    # 48

See Template::Plugin::Colour::RGB for further information.

=head1 AUTHOR

Andy Wardley E<lt>abw@cpan.orgE<gt>, L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 2006-2012 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Colour>, L<Template::Plugin::Colour::RGB>,
L<Template::Plugin>


