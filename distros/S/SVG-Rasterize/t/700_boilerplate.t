#!perl -T

use strict;
use warnings;
use Test::More tests => 37;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

not_in_file_ok(README =>
  "The README is used..."       => qr/The README is used/,
  "'version information here'"  => qr/to provide version information/,
);

my @modules = qw(lib/SVG/Rasterize/Regexes.pm
                 lib/SVG/Rasterize.pm
                 lib/SVG/Rasterize/Engine.pm
                 lib/SVG/Rasterize/Engine/PangoCairo.pm
                 lib/SVG/Rasterize/Specification.pm
                 lib/SVG/Rasterize/Specification/Use.pm
                 lib/SVG/Rasterize/Specification/Gradient.pm
                 lib/SVG/Rasterize/Specification/Shape.pm
                 lib/SVG/Rasterize/Specification/Description.pm
                 lib/SVG/Rasterize/Specification/Conditional.pm
                 lib/SVG/Rasterize/Specification/Clip.pm
                 lib/SVG/Rasterize/Specification/Mask.pm
                 lib/SVG/Rasterize/Specification/Text.pm
                 lib/SVG/Rasterize/Specification/Marker.pm
                 lib/SVG/Rasterize/Specification/Animation.pm
                 lib/SVG/Rasterize/Specification/Style.pm
                 lib/SVG/Rasterize/Specification/Structure.pm
                 lib/SVG/Rasterize/Specification/TextContent.pm
                 lib/SVG/Rasterize/Specification/ColorProfile.pm
                 lib/SVG/Rasterize/Specification/Pattern.pm
                 lib/SVG/Rasterize/Specification/Cursor.pm
                 lib/SVG/Rasterize/Specification/FilterPrimitive.pm
                 lib/SVG/Rasterize/Specification/Font.pm
                 lib/SVG/Rasterize/Specification/Script.pm
                 lib/SVG/Rasterize/Specification/Extensibility.pm
                 lib/SVG/Rasterize/Specification/Filter.pm
                 lib/SVG/Rasterize/Specification/View.pm
                 lib/SVG/Rasterize/Specification/Hyperlink.pm
                 lib/SVG/Rasterize/Specification/Image.pm
                 lib/SVG/Rasterize/Properties.pm
                 lib/SVG/Rasterize/Colors.pm
                 lib/SVG/Rasterize/State.pm
                 lib/SVG/Rasterize/State/Text.pm
                 lib/SVG/Rasterize/Exception.pm
                 lib/SVG/Rasterize/TextNode.pm);

foreach(@modules) { module_boilerplate_ok($_) }

not_in_file_ok(Changes =>
  "placeholder date/time"       => qr(Date/time)
);

TODO: {
  local $TODO = "Need to replace the boilerplate text";

}

