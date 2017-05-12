package ShiftJIS::CP932::MapUTF;

require 5.006;

use strict;
use vars qw($VERSION $PACKAGE @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

$VERSION = '1.03';
$PACKAGE = 'ShiftJIS::CP932::MapUTF'; # __PACKAGE__

@EXPORT = qw(
    cp932_to_unicode  unicode_to_cp932
    cp932_to_utf8     utf8_to_cp932
    cp932_to_utf16le  utf16le_to_cp932
    cp932_to_utf16be  utf16be_to_cp932
);

%EXPORT_TAGS = (
    'unicode'  => [ 'cp932_to_unicode', 'unicode_to_cp932' ],
    'utf8'     => [ 'cp932_to_utf8',    'utf8_to_cp932'    ],
    'utf16'    => [                     'utf16_to_cp932'   ],
    'utf16le'  => [ 'cp932_to_utf16le', 'utf16le_to_cp932' ],
    'utf16be'  => [ 'cp932_to_utf16be', 'utf16be_to_cp932' ],
    'utf32'    => [                     'utf32_to_cp932'   ],
    'utf32le'  => [ 'cp932_to_utf32le', 'utf32le_to_cp932' ],
    'utf32be'  => [ 'cp932_to_utf32be', 'utf32be_to_cp932' ],
);

@EXPORT_OK = map @$_, values %EXPORT_TAGS;
$EXPORT_TAGS{all}  = [ @EXPORT_OK ];

bootstrap ShiftJIS::CP932::MapUTF $VERSION;

1;
__END__

