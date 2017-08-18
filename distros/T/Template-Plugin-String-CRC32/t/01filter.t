#!/usr/bin/perl -w
use strict;

use blib;
use Template::Test;

test_expect(\*DATA);

__END__

# testing crc32 filter with a block
--test--
[% USE String::CRC32; FILTER crc32 -%]
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed sed metus et lectus commodo porta. Integer tortor. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nullam pretium enim at lorem. Aenean sit amet justo at odio dictum suscipit. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Nam lectus. In mattis hendrerit leo. Phasellus nec dolor. Quisque mi neque, porttitor a, bibendum ac, ullamcorper a, dolor. Mauris a augue cursus nulla rutrum aliquet. Nam lectus. Morbi nec massa sit amet urna volutpat imperdiet. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

Cras fringilla turpis sed orci. Aliquam pulvinar magna ac turpis. Duis viverra, tortor pulvinar consequat accumsan, leo elit ultrices neque, non vestibulum sem nisl in ipsum. Fusce pharetra luctus mi. Donec ornare enim nec nisl. Etiam ullamcorper bibendum elit. Nunc malesuada lorem in elit. Maecenas mi ipsum, semper quis, tristique nec, tempor vitae, ligula. In non urna. Vestibulum mollis varius nibh. Fusce sodales. Fusce feugiat libero. Nunc nec tortor. Integer sapien. Integer convallis nonummy enim. Curabitur est. Etiam tincidunt, velit id dapibus lobortis, arcu lectus aliquam turpis, id fringilla odio odio nec libero. Donec faucibus, dolor vel dapibus eleifend, neque nulla tristique risus, eleifend molestie justo metus sed est. Nunc vel dolor quis urna malesuada consectetuer. Mauris a risus in tortor laoreet blandit.

Donec pharetra, nibh nec mollis tristique, lorem turpis viverra elit, in sollicitudin augue orci eget turpis. In nisi nisi, malesuada vel, ornare sed, fringilla sit amet, urna. Duis facilisis. Integer vitae neque. Aenean eu mauris id est ullamcorper tristique. Duis velit enim, condimentum ut, bibendum facilisis, bibendum eu, nibh. Pellentesque sed enim ac lectus tincidunt mollis. Etiam at nulla. Aliquam in nibh in lorem malesuada molestie. Nullam nunc risus, convallis eu, tristique eu, luctus ac, enim. 
[%
    END;
 -%]
--expect--
2970705446


# text | crc32
--test--
[% USE String::CRC32 -%]
[% 'test_string' | crc32 %]
[% text = 'test_string'; text.crc32 %]
--expect--
157791623
157791623


# Test the crc32 filter as a vmethod
--test--
[% USE String.CRC32 -%]
[% checksum1 = 'test_string' | crc32; checksum1.crc32 %]
[% text1 = 'test_string'; text1.crc32 | crc32 %]
[% text2 = 'test_string'; text2.crc32.crc32 %]
--expect--
4030060697
4030060697
4030060697
