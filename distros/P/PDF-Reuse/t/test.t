
use Test;
BEGIN { plan tests => 8  };

ok(sub { eval { require Carp;}; });

ok(sub { eval { require Compress::Zlib;}; });

ok(sub { eval { require Digest::MD5;}; });

ok(sub { eval { require Exporter;}; });

ok(sub { eval { require Data::Dumper;}; });

use PDF::Reuse;
ok(6);

print "\n\nIf you have ok for everything this far, PDF::Reuse can be used\n";
print "Will test the optional requirements for True Type Fonts and UTF8 characters\n\n\n";

ok ( sub { eval { require Text::PDF::TTFont0;}; } );

ok ( sub { eval { require Font::TTF;}; } );

