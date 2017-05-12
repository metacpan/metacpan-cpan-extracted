package Template::Plugin::GD;

use strict;
use warnings;
use base 'Template::Plugin';
use GD;

our $VERSION = 2.66;

sub new {
    my $class   = shift;
    my $context = shift;
    bless { 
        context => $context,
    }, $class;
}

sub image {
    my $self = shift;
    return GD::Image->new(@_);
}

sub polygon {
    my $self = shift;
    return GD::Polygon->new(@_);
}

sub text {
    my $self = shift;
    $self->{ context }->plugin( 'GD.Text' => @_ );
}


1;

__END__

=head1 NAME

Template::Plugin::GD - GD plugin(s) for the Template Toolkit

=head1 SYNOPSIS

    [% USE GD;
     
       # create an image
       img = GD.image(width, height)

       # allocate some colors
       black = img.colorAllocate(0,   0,   0);
       red   = img.colorAllocate(255, 0,   0);
       blue  = img.colorAllocate(0,   0, 255);

       # draw a blue oval
       img.arc(50, 50, 95, 75, 0, 360, blue);

       # fill it with red
       img.fill(50, 50, red);

       # output binary image in PNG format
       img.png | redirect('example.png');
    %]

=head1 DESCRIPTION

The Template-GD distribution provides a number of Template Toolkit
plugin modules to interface with Lincoln Stein's GD modules.  These in
turn provide an interface to Thomas Boutell's GD graphics library.

These plugins were distributed as part of the Template Toolkit until
version 2.15 released in February 2006.  At this time they were
extracted into this separate distribution.

For general information on the Template Toolkit see the documentation
for the L<Template> module or L<http://template-toolkit.org>.  For
information on using plugins, see L<Template::Plugins> and
L<Template::Manual::Directives/"USE">.

=head1 METHODS

The GD plugin module provides a number of methods to create various
other GD objects.  But first you need to load the GD plugin.

    [% USE GD %]

Then you can call the following objects against it.

=head2 image(width, height)

Creates a new GD::Image object.

    [% image = GD.image(100, 200) %]

=head2 polygon()

Creates a new GD::Polygon object.

    [% poly = GD.polygon;
       poly.addPt(50,0);
       poly.addPt(99,99);
       poly.addPt(0,99);
       image.filledPolygon(poly, blue);
    %]

=head2 text()

Creates a new GD::Text object.

    [%  text = GD.text;
        text.set_text('Some text');
    %]

=head1 GD PLUGINS

These are the GD plugins provided in this distribution.  

=head2 Template::Plugin::GD

Front-end module to the GD plugin collection.

=head2 Template::Plugin::GD::Image

Plugin interface providing direct access to the GD::Image module.

    [% USE image = GD.Image %]

=head2 Template::Plugin::GD::Polygon

Plugin interface providing direct access to the GD::Polygon module.

    [% USE poly = GD.Polygon;
       poly.addPt(50,0);
       poly.addPt(99,99);
       poly.addPt(0,99);
       image.filledPolygon(poly, blue);
    %]

=head2 Template::Plugin::GD::Text

Plugin interface providing direct access to the GD::Text module.

    [%  USE text = GD.Text;
        text.set_text('Some text');
    %]

=head2 Template::Plugin::GD::Text::Align

Plugin interface to the GD::Text::Align module for creating aligned
text.

=head2 Template::Plugin::GD::Text::Wrap

Plugin interface to the GD::Text::Wrap module for creating wrapped
text.

=head2 Template::Plugin::GD::Graph::area

Plugin interface to the GD::Graph::area module for creating area graphics
with axes and legends.

=head2 Template::Plugin::GD::Graph::bars3d

Plugin interface to the GD::Graph::bars3d module for creating 3D bar
graphs with axes and legends.

=head2 Template::Plugin::GD::Graph::bars

Plugin interface to the GD::Graph::bars module for creating bar graphs
with axes and legends.

=head2 Template::Plugin::GD::Graph::lines3d

Plugin interface to the GD::Graph::lines3d module for creating 3D line
graphs with axes and legends.

=head2 Template::Plugin::GD::Graph::lines

Plugin interface to the GD::Graph::lines module for creating line
graphs with axes and legends.

=head2 Template::Plugin::GD::Graph::linespoints

Plugin interface to the GD::Graph::linespoints module for creating
line/point graphs with axes and legends

=head2 Template::Plugin::GD::Graph::mixed

Plugin interface to the GD::Graph::mixed module for creating mixed
graphs with axes and legends.

=head2 Template::Plugin::GD::Graph::pie3d

Plugin interface to the GD::Graph::pie3d module for creating 3D pie
charts with legends.

=head2 Template::Plugin::GD::Graph::pie

Plugin interface to the GD::Graph::pie module for creating pie
charts with legends.

=head2 Template::Plugin::GD::Graph::points

Plugin interface to the GD::Graph::points module for creating point
graphs with axes and legends 

=head2 Template::Plugin::GD::Constants

Provides access to various GD constants.

    [% USE gdc = GD.Constants;
       font = gdc.gdLargeFont
    %]

=head1 AUTHORS

Thomas Boutell wrote the GD graphics library.  Lincoln D. Stein wrote
the Perl GD modules and Martien Verbruggen wrote the GD::Text and
GD::Graph modules that interface with it.  Craig Barratt wrote the GD
plugins for the Template Toolkit.  Andy Wardley wrote the Template
Toolkit.  Larry wrote Perl.  Brian and Dennis wrote C.  Dennis and Ken
wrote Unix.  

=head1 VERSION

This is version 2.66 of the Template::Plugin::GD module set.

=head1 COPYRIGHT

Copyright (C) 2001 Craig Barratt, 2006 Andy Wardley.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>, L<Template::Plugins>, L<GD>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
