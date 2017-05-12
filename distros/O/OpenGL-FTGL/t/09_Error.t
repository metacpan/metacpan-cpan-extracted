use Test;
BEGIN { plan tests => 192 };
use strict;
use warnings;
use OpenGL ':all';
use OpenGL::FTGL ':all';

my $i = 0;

while ( <DATA> ) {
  chomp;
  ok( $_ eq OpenGL::FTGL::_ErrorMsg($i) );
  $i++;
  }
  

__END__
no error
cannot open resource
unknown file format
broken file
invalid FreeType version
module version is too low
invalid argument
unimplemented feature
broken table
broken offset within table
array allocation size too large
missing module
unknown error
unknown error
unknown error
unknown error
invalid glyph index
invalid character code
unsupported glyph image format
cannot render this glyph format
invalid outline
invalid composite glyph
too many hints
invalid pixel size
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
invalid object handle
invalid library handle
invalid module handle
invalid face handle
invalid size handle
invalid glyph slot handle
invalid charmap handle
invalid cache manager handle
invalid stream handle
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
too many modules
too many extensions
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
out of memory
unlisted object
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
cannot open stream
invalid stream seek
invalid stream skip
invalid stream read
invalid stream operation
invalid frame operation
nested frame access
invalid frame read
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
raster uninitialized
raster corrupted
raster overflow
negative height while rastering
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
too many registered caches
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
invalid opcode
too few arguments
stack overflow
code overflow
bad argument
division by zero
invalid reference
found debug opcode
found ENDF opcode in execution stream
nested DEFS
invalid code range
execution context too long
too many function definitions
too many instruction definitions
SFNT font table missing
horizontal header (hhea) table missing
locations (loca) table missing
name table missing
character map (cmap) table missing
horizontal metrics (hmtx) table missing
PostScript (post) table missing
invalid horizontal metrics
invalid character map (cmap) format
invalid ppem value
invalid vertical metrics
could not find context
invalid PostScript (post) table format
invalid PostScript (post) table
unknown error
unknown error
unknown error
unknown error
opcode syntax error
argument stack underflow
ignore
no Unicode glyph name found
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
unknown error
`STARTFONT' field missing
`FONT' field missing
`SIZE' field missing
`FONTBOUNDINGBOX' field missing
`CHARS' field missing
`STARTCHAR' field missing
`ENCODING' field missing
`BBX' field missing
`BBX' too big
Font header corrupted or missing fields
Font glyphs corrupted or missing fields
unknown error
unknown error
unknown error
unknown error
unknown error
