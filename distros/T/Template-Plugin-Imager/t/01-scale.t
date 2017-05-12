use strict;
use warnings;

use Template::Test;
test_expect( \*DATA );

unlink( 't/scaledimage.jpg' );

__DATA__

-- test --
[% 
    FILTER null;
        USE im = Imager();
        im.read( 'file', 't/testimage.jpg' );
        im.convert( 'preset', 'noalpha' );
        thumb_im = im.scale( 'xpixels', 32 );
        thumb_im.write( 'file', 't/scaledimage.jpg' );
        im.read( 'file', 't/scaledimage.jpg' );
    END;
    im.getwidth();
-%]
-- expect --
32

