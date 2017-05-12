#!/usr/bin/perl -w
use strict;

use Template::Test;

$Template::Test::DEBUG = 0;

test_expect(\*DATA);

__END__

# testing sha2_hex filter with a block
--test--
[% USE Digest.SHA2; FILTER sha2_hex -%]
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed sed metus et lectus commodo porta. Integer tortor. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nullam pretium enim at lorem. Aenean sit amet justo at odio dictum suscipit. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Nam lectus. In mattis hendrerit leo. Phasellus nec dolor. Quisque mi neque, porttitor a, bibendum ac, ullamcorper a, dolor. Mauris a augue cursus nulla rutrum aliquet. Nam lectus. Morbi nec massa sit amet urna volutpat imperdiet. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

Cras fringilla turpis sed orci. Aliquam pulvinar magna ac turpis. Duis viverra, tortor pulvinar consequat accumsan, leo elit ultrices neque, non vestibulum sem nisl in ipsum. Fusce pharetra luctus mi. Donec ornare enim nec nisl. Etiam ullamcorper bibendum elit. Nunc malesuada lorem in elit. Maecenas mi ipsum, semper quis, tristique nec, tempor vitae, ligula. In non urna. Vestibulum mollis varius nibh. Fusce sodales. Fusce feugiat libero. Nunc nec tortor. Integer sapien. Integer convallis nonummy enim. Curabitur est. Etiam tincidunt, velit id dapibus lobortis, arcu lectus aliquam turpis, id fringilla odio odio nec libero. Donec faucibus, dolor vel dapibus eleifend, neque nulla tristique risus, eleifend molestie justo metus sed est. Nunc vel dolor quis urna malesuada consectetuer. Mauris a risus in tortor laoreet blandit.

Donec pharetra, nibh nec mollis tristique, lorem turpis viverra elit, in sollicitudin augue orci eget turpis. In nisi nisi, malesuada vel, ornare sed, fringilla sit amet, urna. Duis facilisis. Integer vitae neque. Aenean eu mauris id est ullamcorper tristique. Duis velit enim, condimentum ut, bibendum facilisis, bibendum eu, nibh. Pellentesque sed enim ac lectus tincidunt mollis. Etiam at nulla. Aliquam in nibh in lorem malesuada molestie. Nullam nunc risus, convallis eu, tristique eu, luctus ac, enim. 
[%
    END;
 -%]
--expect--
ca9d59c8f9aa865c799bcd30afa6c2643c18bc5545b2dd6d9143a4a50b5cb42a


# text | sha2_hex
--test--
[% USE Digest.SHA2 -%]
[% 'xyzzy' | sha2_hex %]
[% text = 'xyzzy'; text.sha2_hex %]
--expect--
184858a00fd7971f810848266ebcecee5e8b69972c5ffaed622f5ee078671aed
184858a00fd7971f810848266ebcecee5e8b69972c5ffaed622f5ee078671aed

# FILTER sha2_base64; ...
--test--
[% USE Digest.SHA2; FILTER sha2_base64 -%]
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed sed metus et lectus commodo porta. Integer tortor. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nullam pretium enim at lorem. Aenean sit amet justo at odio dictum suscipit. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Nam lectus. In mattis hendrerit leo. Phasellus nec dolor. Quisque mi neque, porttitor a, bibendum ac, ullamcorper a, dolor. Mauris a augue cursus nulla rutrum aliquet. Nam lectus. Morbi nec massa sit amet urna volutpat imperdiet. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

Cras fringilla turpis sed orci. Aliquam pulvinar magna ac turpis. Duis viverra, tortor pulvinar consequat accumsan, leo elit ultrices neque, non vestibulum sem nisl in ipsum. Fusce pharetra luctus mi. Donec ornare enim nec nisl. Etiam ullamcorper bibendum elit. Nunc malesuada lorem in elit. Maecenas mi ipsum, semper quis, tristique nec, tempor vitae, ligula. In non urna. Vestibulum mollis varius nibh. Fusce sodales. Fusce feugiat libero. Nunc nec tortor. Integer sapien. Integer convallis nonummy enim. Curabitur est. Etiam tincidunt, velit id dapibus lobortis, arcu lectus aliquam turpis, id fringilla odio odio nec libero. Donec faucibus, dolor vel dapibus eleifend, neque nulla tristique risus, eleifend molestie justo metus sed est. Nunc vel dolor quis urna malesuada consectetuer. Mauris a risus in tortor laoreet blandit.

Donec pharetra, nibh nec mollis tristique, lorem turpis viverra elit, in sollicitudin augue orci eget turpis. In nisi nisi, malesuada vel, ornare sed, fringilla sit amet, urna. Duis facilisis. Integer vitae neque. Aenean eu mauris id est ullamcorper tristique. Duis velit enim, condimentum ut, bibendum facilisis, bibendum eu, nibh. Pellentesque sed enim ac lectus tincidunt mollis. Etiam at nulla. Aliquam in nibh in lorem malesuada molestie. Nullam nunc risus, convallis eu, tristique eu, luctus ac, enim. 
[%
    END;
 -%]
--expect--
yp1ZyPmqhlx5m80wr6bCZDwYvFVFst1tkUOkpQtctCo


# text | sha2_base64
--test--
[% USE Digest.SHA2 -%]
[% 'xyzzy' | sha2_base64 %]
--expect--
GEhYoA/Xlx+BCEgmbrzs7l6LaZcsX/rtYi9e4HhnGu0

--test--
[% USE Digest.SHA2 -%]
[% text = 'xyzzy'; text.sha2_base64 %]
--expect--
GEhYoA/Xlx+BCEgmbrzs7l6LaZcsX/rtYi9e4HhnGu0


# Test the sha2 filter
--test--
[% USE Digest.SHA2; USE Dumper; checksum = FILTER sha2 -%]
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed sed metus et lectus commodo porta. Integer tortor. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nullam pretium enim at lorem. Aenean sit amet justo at odio dictum suscipit. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Nam lectus. In mattis hendrerit leo. Phasellus nec dolor. Quisque mi neque, porttitor a, bibendum ac, ullamcorper a, dolor. Mauris a augue cursus nulla rutrum aliquet. Nam lectus. Morbi nec massa sit amet urna volutpat imperdiet. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

Cras fringilla turpis sed orci. Aliquam pulvinar magna ac turpis. Duis viverra, tortor pulvinar consequat accumsan, leo elit ultrices neque, non vestibulum sem nisl in ipsum. Fusce pharetra luctus mi. Donec ornare enim nec nisl. Etiam ullamcorper bibendum elit. Nunc malesuada lorem in elit. Maecenas mi ipsum, semper quis, tristique nec, tempor vitae, ligula. In non urna. Vestibulum mollis varius nibh. Fusce sodales. Fusce feugiat libero. Nunc nec tortor. Integer sapien. Integer convallis nonummy enim. Curabitur est. Etiam tincidunt, velit id dapibus lobortis, arcu lectus aliquam turpis, id fringilla odio odio nec libero. Donec faucibus, dolor vel dapibus eleifend, neque nulla tristique risus, eleifend molestie justo metus sed est. Nunc vel dolor quis urna malesuada consectetuer. Mauris a risus in tortor laoreet blandit.

Donec pharetra, nibh nec mollis tristique, lorem turpis viverra elit, in sollicitudin augue orci eget turpis. In nisi nisi, malesuada vel, ornare sed, fringilla sit amet, urna. Duis facilisis. Integer vitae neque. Aenean eu mauris id est ullamcorper tristique. Duis velit enim, condimentum ut, bibendum facilisis, bibendum eu, nibh. Pellentesque sed enim ac lectus tincidunt mollis. Etiam at nulla. Aliquam in nibh in lorem malesuada molestie. Nullam nunc risus, convallis eu, tristique eu, luctus ac, enim. 
[%
    END;
    checksum.sha2_hex;
 -%]
--expect--
fae6e96e8e5d7810d8f298ba8867a067de2ff58767feb3f0d953b7e86ffd9e3b


# Test the sha2 filter and vmethod
--test--
[% USE Digest.SHA2 -%]
[% checksum1 = 'xyzzy' | sha2; checksum1.sha2_hex %]
[% text1 = 'xyzzy'; text1.sha2 | sha2_hex %]
[% text2 = 'xyzzy'; text2.sha2.sha2_hex %]
--expect--
35e017ffbad99f60b074c09793812c3c8d405b38e04a5aa4d73ae912b502a7f3
35e017ffbad99f60b074c09793812c3c8d405b38e04a5aa4d73ae912b502a7f3
35e017ffbad99f60b074c09793812c3c8d405b38e04a5aa4d73ae912b502a7f3

--test--
[% USE Digest.SHA2(512) -%]
[% text = 'xyzzy'; text.sha2_base64 %]
--expect--
RqvigyGDkuVtTN+tbuNoyDWVM5vQm01Dsg+JtCwV+0qKZOIgptAC+vsJIwIw2zhVtBi/4Hk2ecmnCG4FmVGVzg


--test--
[% USE Digest.SHA2(384) -%]
[% text = 'xyzzy'; text.sha2_base64 %]
--expect--
jYx+ebDy7wCvsXunB+JgYssqWT7AiHWXXL4MgiHjLipggiTvOFQIPZ5jj5W+3BjH

