package Template::Plugin::GD::Image;

use strict;
use warnings;
use base 'Template::Plugin';
use GD;

our $VERSION = sprintf("%d.%02d", q$Revision: 1.56 $ =~ /(\d+)\.(\d+)/);

sub new {
    my $class   = shift;
    my $context = shift;
    return GD::Image->new(@_);
}

1;

__END__

=head1 NAME

Template::Plugin::GD::Image - Interface to GD Graphics Library

=head1 SYNOPSIS

    [% USE im = GD.Image(width, height) %]

=head1 EXAMPLES

    [% FILTER null;
        USE gdc = GD.Constants;
        USE im  = GD.Image(200,100);
        black = im.colorAllocate(0  ,0,  0);
        red   = im.colorAllocate(255,0,  0);
        r = im.string(gdc.gdLargeFont, 10, 10, "Large Red Text", red);
        im.png | stdout(1);
       END;
    -%]

    [% FILTER null;
        USE im = GD.Image(100,100);
        # allocate some colors
        black = im.colorAllocate(0,   0, 0);
        red   = im.colorAllocate(255,0,  0);
        blue  = im.colorAllocate(0,  0,  255);
        # Draw a blue oval
        im.arc(50,50,95,75,0,360,blue);
        # And fill it with red
        im.fill(50,50,red);
        # Output binary image in PNG format
        im.png | stdout(1);
       END;
    -%]

    [% FILTER null;
        USE im   = GD.Image(100,100);
        USE c    = GD.Constants;
        USE poly = GD.Polygon;

        # allocate some colors
        white = im.colorAllocate(255,255,255);
        black = im.colorAllocate(0,  0,  0);
        red   = im.colorAllocate(255,0,  0);
        blue  = im.colorAllocate(0,  0,255);
        green = im.colorAllocate(0,  255,0);

        # make the background transparent and interlaced
        im.transparent(white);
        im.interlaced('true');

        # Put a black frame around the picture
        im.rectangle(0,0,99,99,black);

        # Draw a blue oval
        im.arc(50,50,95,75,0,360,blue);

        # And fill it with red
        im.fill(50,50,red);

        # Draw a blue triangle
        poly.addPt(50,0);
        poly.addPt(99,99);
        poly.addPt(0,99);
        im.filledPolygon(poly, blue);

        # Output binary image in PNG format
        im.png | stdout(1);
       END;
    -%]

=head1 DESCRIPTION

The GD.Image plugin provides an interface to GD.pm's GD::Image class.
The GD::Image class is the main interface to GD.pm.

It is very important that no extraneous template output appear before
or after the image.  Since some methods return values that would
otherwise appear in the output, it is recommended that GD.Image code
be wrapped in a null filter.  The methods that produce the final
output (eg, png, jpeg, gd etc) can then explicitly make their output
appear by using the stdout filter, with a non-zero argument to force
binary mode (required for non-modern operating systems).

See L<GD> for a complete description of the GD library and all the
methods that can be called via the GD.Image plugin.  See
L<Template::Plugin::GD::Constants> for a plugin that allows you access
to GD.pm's constants.

=head1 AUTHOR

Thomas Boutell wrote the GD graphics library.

Lincoln D. Stein wrote the Perl GD modules that interface to it.

Craig Barratt E<lt>craig@arraycomm.comE<gt> wrote the original GD
plugins for the Template Toolkit (2001).

Andy Wardley E<lt>abw@cpan.orgE<gt> extracted them from the TT core
into a separate distribution for TT version 2.15.

=head1 COPYRIGHT

Copyright (C) 2001 Craig Barratt E<lt>craig@arraycomm.comE<gt>, 
2006 Andy Wardley E<lt>abw@cpan.orgE<gt>.

The GD.pm interface is copyright 1995-2000, Lincoln D. Stein.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::GD>, L<GD>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
