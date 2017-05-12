#!perl -T

use Test::More tests => 35;

BEGIN {
    my @modules = qw(SVG::Rasterize::Regexes
                     SVG::Rasterize
                     SVG::Rasterize::Engine
                     SVG::Rasterize::Engine::PangoCairo
                     SVG::Rasterize::Specification
                     SVG::Rasterize::Specification::Use
                     SVG::Rasterize::Specification::Gradient
                     SVG::Rasterize::Specification::Shape
                     SVG::Rasterize::Specification::Description
                     SVG::Rasterize::Specification::Conditional
                     SVG::Rasterize::Specification::Clip
                     SVG::Rasterize::Specification::Mask
                     SVG::Rasterize::Specification::Text
                     SVG::Rasterize::Specification::Marker
                     SVG::Rasterize::Specification::Animation
                     SVG::Rasterize::Specification::Style
                     SVG::Rasterize::Specification::Structure
                     SVG::Rasterize::Specification::TextContent
                     SVG::Rasterize::Specification::ColorProfile
                     SVG::Rasterize::Specification::Pattern
                     SVG::Rasterize::Specification::Cursor
                     SVG::Rasterize::Specification::FilterPrimitive
                     SVG::Rasterize::Specification::Font
                     SVG::Rasterize::Specification::Script
                     SVG::Rasterize::Specification::Extensibility
                     SVG::Rasterize::Specification::Filter
                     SVG::Rasterize::Specification::View
                     SVG::Rasterize::Specification::Hyperlink
                     SVG::Rasterize::Specification::Image
                     SVG::Rasterize::Properties
                     SVG::Rasterize::Colors
                     SVG::Rasterize::State
                     SVG::Rasterize::State::Text
                     SVG::Rasterize::Exception
                     SVG::Rasterize::TextNode);

    foreach(@modules) { use_ok($_) || print "Bail out!\n" }
}

diag( "Testing SVG::Rasterize $SVG::Rasterize::VERSION, Perl $], $^X" );
