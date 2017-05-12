package Template::Plugin::Colour;

use Template::Colour::Class
    debug     => 0,
    base      => 'Template::Plugin Template::Colour',
    constants => 'HASH';

our $VERSION = 2.10;


sub new {
    my ($class, $context, @args) = @_;;
    my $params = (@args && ref $args[-1] eq HASH) ? $args[-1] : { };
    my $space;

    # first argument can be 'rgb' or 'hsv' to indicate argument(s) type
    if ($space = $params->{ rgb } || $params->{ RGB }) {
        return $class->RGB($space);
    }
    elsif ($space = $params->{ hsv } || $params->{ HSV }) {
        return $class->HSV($space);
    }
    else {
        # RGB by default
        return $class->RGB(@args);
    }
}


1;

__END__

=head1 NAME

Template::Plugin::Colour - Template plugin for colour manipulation

=head1 SYNOPSIS

    # long or short hex triplets, with or without '#'
    [% USE Colour('abc')     %]    
    [% USE Colour('#abc')    %]   
    [% USE Colour('ff0000')  %] 
    [% USE Colour('#ff0000') %]

    # decimal r, g, b values
    [% USE Colour(255, 128, 0) %]

    # named parameters
    [% USE Colour( red=255, green=128, blue=0 ) %]

    # explicit colour space
    [% USE Colour( rgb = [255, 128, 10] ) %] 
    [% USE Colour( hsv = [120, 180, 20] ) %] 

    # alternately, call Colour methods
    [% USE Colour;

       # create RGB colours
       red    = Colour.RGB('#c00');
       green  = Colour.RGB('#0c0');
       blue   = Colour.RGB('#00c');

       # create HSV colours
       orange = Colour.HSV(30, 255, 255);
    %]

=head1 DESCRIPTION

This Template Toolkit plugin module allows you to define and 
manipulate colours using the RGB (red, green, blue) and HSV
(hue, saturation, value) colour spaces.

It delegates to the L<Template::Plugin::Colour::RGB> and
L<Template::Plugin::Colour::HSV> modules to do all the hard work.

As a convenience to our American friends and other international users
who spell 'C<Colour>' as 'C<Color>', all the 'C<Colour>' plugin modules have
'C<Color>' equivalents.  So you can write either:

    [% USE Colour %]

or:

    [% USE Color %]

The same is true of the other plugins as well (Color.RGB, Color.HSV).

=head1 METHODS

=head2 new(@args)

Creates a new colour object.  The first argument can denote the
intended colour space: 'rgb' or 'hsv' (either upper or lower case
is accepted).

    [% USE Colour( rgb = [100, 150, 200] ) %]
    [% USE Colour( hsv = [120, 140, 160] ) %]

If the colour space argument isn't specified then it defaults to RGB.

    [% USE Colour( 100, 150, 200 ) %]   # RGB colour

The new() method delegates to RGB() or HSV() depending on the colour
space.

=head2 RGB(@args)

Create a new colour object using the RGB colour space.  See
Template::Plugin::Colour::RGB.

=head2 HSV(@args)

Create a new colour object using the HSV colour space.  See
Template::Plugin::Colour::HSV.

=head1 COLOUR SPACE CONVERSION ALGORITHMS

The algorithms used to covert between the RGB and HSV colour spaces
are based on the the C Code in "Computer Graphics -- Principles and
Practice,", Foley et al, 1996, p. 592-593.

Due to a limitation in the particular implementation chosen (to use
integers rather than floating point numbers to represent RGB and HSV
components), the conversion between colour spaces is not totally
symmetrical.  That is, if you convert a colour from RGB to HSV and
then back again, you may not get back exactly the same colour you
started with.

=head1 EXAMPLES

=head2 What Colour is Orange?

Everyone needs to know what colour orange is in RGB and HSV.

I find the easiest way to remember is that its Hue is 30 degrees,
with full Saturation and Value.  

    [% USE Colour;
       orange = Colour.HSV(30, 255, 255);
    %]

Use the 'rgb' method to convert it to RGB, and 'html' to display it
as an HTML formatted hex string.

    <p style="color: [% orange.rgb.html %]">
       I like orange!
    </p>

As it happens, orange is pretty easy to remember in RGB, too.  It's
#ff7f00 which is full red (ff), half green (7f) and no blue (00).  It
just goes to reinforce the widely held belief that orange really is
one of the best colours ever.  Whoever invented it should probably get
an award of some kind, or maybe even a pony.

=head2 How Do I Make a Nice Colour Scheme?

Let's start with orange, shall we?

    [% USE Colour;
       orange = Colour.HSV(30, 255, 255)
    %]

Now copy it twice to create a lighter (more white) version by reducing
the saturation, and a darker version (more black) by reducing the value.

    [% lighter = orange.copy( saturation = 127 );
       darker  = orange.copy( value = 127 );
    %]

Now you can convert them to RGB for display in your HTML page.

    [% orange.html  %]  => #ff7f00
    [% lighter.html %]  => #ffbf80 
    [% darker.html  %]  => #7f3f00

If you want a strongly contrasting colour, then shift the hue 180 degrees
around the colour wheel.  In this case, going from 30 to 210 to give a 
nice shade of blue.

    [% contrast = orange.copy( hue = 210 ).html %]  => #007fff

=head2 How Much More Black Could This Be?

How much more black could this be?

    [% black = Colour.RGB %]        # defaults to 0, 0, 0

The answer is none. None more black.

=head1 VERSION

This is version 0.04 of the Template::Plugin::Colour module set.

=head1 AUTHOR

Andy Wardley E<lt>abw@cpan.orgE<gt>, L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 2006-2012 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Written using algorithms from "Computer Graphics -- Principles and Practice", 
Foley et al, 1996, p. 592-593.

=head1 SEE ALSO

L<Template::Plugin::Colour::RGB>, L<Template::Plugin::Colour::HSV>,
L<Template::Plugin>
