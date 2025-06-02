package PDFio::Architect::File;

use 5.006;
use strict;
use warnings;

use PDFio::Architect::Page;
use PDFio::Architect::Font;
use PDFio::Architect::Rect;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load("PDFio::Architect::File", $VERSION);

1;
