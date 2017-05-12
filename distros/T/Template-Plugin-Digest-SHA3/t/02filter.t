#!/usr/bin/perl -w
use strict;

use Digest::SHA3;
use Template::Test;

$Template::Test::DEBUG = 0;

if($Digest::SHA3::VERSION < 0.24) {
    print STDERR "# These test only apply to Digest::SHA3 v0.24 or higher\n";
    ok(1);
} else {
    test_expect(\*DATA);
}

__END__

# testing sha3_hex filter with a block
--test--
[% USE Digest.SHA3; FILTER sha3_hex -%]
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed sed metus et lectus commodo porta. Integer tortor. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nullam pretium enim at lorem. Aenean sit amet justo at odio dictum suscipit. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Nam lectus. In mattis hendrerit leo. Phasellus nec dolor. Quisque mi neque, porttitor a, bibendum ac, ullamcorper a, dolor. Mauris a augue cursus nulla rutrum aliquet. Nam lectus. Morbi nec massa sit amet urna volutpat imperdiet. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

Cras fringilla turpis sed orci. Aliquam pulvinar magna ac turpis. Duis viverra, tortor pulvinar consequat accumsan, leo elit ultrices neque, non vestibulum sem nisl in ipsum. Fusce pharetra luctus mi. Donec ornare enim nec nisl. Etiam ullamcorper bibendum elit. Nunc malesuada lorem in elit. Maecenas mi ipsum, semper quis, tristique nec, tempor vitae, ligula. In non urna. Vestibulum mollis varius nibh. Fusce sodales. Fusce feugiat libero. Nunc nec tortor. Integer sapien. Integer convallis nonummy enim. Curabitur est. Etiam tincidunt, velit id dapibus lobortis, arcu lectus aliquam turpis, id fringilla odio odio nec libero. Donec faucibus, dolor vel dapibus eleifend, neque nulla tristique risus, eleifend molestie justo metus sed est. Nunc vel dolor quis urna malesuada consectetuer. Mauris a risus in tortor laoreet blandit.

Donec pharetra, nibh nec mollis tristique, lorem turpis viverra elit, in sollicitudin augue orci eget turpis. In nisi nisi, malesuada vel, ornare sed, fringilla sit amet, urna. Duis facilisis. Integer vitae neque. Aenean eu mauris id est ullamcorper tristique. Duis velit enim, condimentum ut, bibendum facilisis, bibendum eu, nibh. Pellentesque sed enim ac lectus tincidunt mollis. Etiam at nulla. Aliquam in nibh in lorem malesuada molestie. Nullam nunc risus, convallis eu, tristique eu, luctus ac, enim. 
[%
    END;
 -%]
--expect--
cdac72f7172b58c004968dd48db7ab670f33a304736d370fbde446c21094e532


# text | sha3_hex
--test--
[% USE Digest.SHA3 -%]
[% 'xyzzy' | sha3_hex %]
[% text = 'xyzzy'; text.sha3_hex %]
--expect--
f78850e7536b52d75ddb0c6a660cd9a97692c0c7f8f1aa5e62f449d5d55f6171
f78850e7536b52d75ddb0c6a660cd9a97692c0c7f8f1aa5e62f449d5d55f6171

# FILTER sha3_base64; ...
--test--
[% USE Digest.SHA3; FILTER sha3_base64 -%]
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed sed metus et lectus commodo porta. Integer tortor. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nullam pretium enim at lorem. Aenean sit amet justo at odio dictum suscipit. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Nam lectus. In mattis hendrerit leo. Phasellus nec dolor. Quisque mi neque, porttitor a, bibendum ac, ullamcorper a, dolor. Mauris a augue cursus nulla rutrum aliquet. Nam lectus. Morbi nec massa sit amet urna volutpat imperdiet. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

Cras fringilla turpis sed orci. Aliquam pulvinar magna ac turpis. Duis viverra, tortor pulvinar consequat accumsan, leo elit ultrices neque, non vestibulum sem nisl in ipsum. Fusce pharetra luctus mi. Donec ornare enim nec nisl. Etiam ullamcorper bibendum elit. Nunc malesuada lorem in elit. Maecenas mi ipsum, semper quis, tristique nec, tempor vitae, ligula. In non urna. Vestibulum mollis varius nibh. Fusce sodales. Fusce feugiat libero. Nunc nec tortor. Integer sapien. Integer convallis nonummy enim. Curabitur est. Etiam tincidunt, velit id dapibus lobortis, arcu lectus aliquam turpis, id fringilla odio odio nec libero. Donec faucibus, dolor vel dapibus eleifend, neque nulla tristique risus, eleifend molestie justo metus sed est. Nunc vel dolor quis urna malesuada consectetuer. Mauris a risus in tortor laoreet blandit.

Donec pharetra, nibh nec mollis tristique, lorem turpis viverra elit, in sollicitudin augue orci eget turpis. In nisi nisi, malesuada vel, ornare sed, fringilla sit amet, urna. Duis facilisis. Integer vitae neque. Aenean eu mauris id est ullamcorper tristique. Duis velit enim, condimentum ut, bibendum facilisis, bibendum eu, nibh. Pellentesque sed enim ac lectus tincidunt mollis. Etiam at nulla. Aliquam in nibh in lorem malesuada molestie. Nullam nunc risus, convallis eu, tristique eu, luctus ac, enim. 
[%
    END;
 -%]
--expect--
zaxy9xcrWMAElo3UjberZw8zowRzbTcPveRGwhCU5TI


# text | sha3_base64
--test--
[% USE Digest.SHA3 -%]
[% 'xyzzy' | sha3_base64 %]
--expect--
94hQ51NrUtdd2wxqZgzZqXaSwMf48apeYvRJ1dVfYXE

--test--
[% USE Digest.SHA3 -%]
[% text = 'xyzzy'; text.sha3_base64 %]
--expect--
94hQ51NrUtdd2wxqZgzZqXaSwMf48apeYvRJ1dVfYXE


# Test the sha3 filter
--test--
[% USE Digest.SHA3; USE Dumper; checksum = FILTER sha3 -%]
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed sed metus et lectus commodo porta. Integer tortor. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nullam pretium enim at lorem. Aenean sit amet justo at odio dictum suscipit. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Nam lectus. In mattis hendrerit leo. Phasellus nec dolor. Quisque mi neque, porttitor a, bibendum ac, ullamcorper a, dolor. Mauris a augue cursus nulla rutrum aliquet. Nam lectus. Morbi nec massa sit amet urna volutpat imperdiet. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

Cras fringilla turpis sed orci. Aliquam pulvinar magna ac turpis. Duis viverra, tortor pulvinar consequat accumsan, leo elit ultrices neque, non vestibulum sem nisl in ipsum. Fusce pharetra luctus mi. Donec ornare enim nec nisl. Etiam ullamcorper bibendum elit. Nunc malesuada lorem in elit. Maecenas mi ipsum, semper quis, tristique nec, tempor vitae, ligula. In non urna. Vestibulum mollis varius nibh. Fusce sodales. Fusce feugiat libero. Nunc nec tortor. Integer sapien. Integer convallis nonummy enim. Curabitur est. Etiam tincidunt, velit id dapibus lobortis, arcu lectus aliquam turpis, id fringilla odio odio nec libero. Donec faucibus, dolor vel dapibus eleifend, neque nulla tristique risus, eleifend molestie justo metus sed est. Nunc vel dolor quis urna malesuada consectetuer. Mauris a risus in tortor laoreet blandit.

Donec pharetra, nibh nec mollis tristique, lorem turpis viverra elit, in sollicitudin augue orci eget turpis. In nisi nisi, malesuada vel, ornare sed, fringilla sit amet, urna. Duis facilisis. Integer vitae neque. Aenean eu mauris id est ullamcorper tristique. Duis velit enim, condimentum ut, bibendum facilisis, bibendum eu, nibh. Pellentesque sed enim ac lectus tincidunt mollis. Etiam at nulla. Aliquam in nibh in lorem malesuada molestie. Nullam nunc risus, convallis eu, tristique eu, luctus ac, enim. 
[%
    END;
    checksum.sha3_hex;
 -%]
--expect--
de518bb2fb4c73b49db51ff855db239b6ba549c0a378a02462945a1e8640aa7d


# Test the sha3 filter and vmethod
--test--
[% USE Digest.SHA3 -%]
[% checksum1 = 'xyzzy' | sha3; checksum1.sha3_hex %]
[% text1 = 'xyzzy'; text1.sha3 | sha3_hex %]
[% text2 = 'xyzzy'; text2.sha3.sha3_hex %]
--expect--
c4de5f86f3a98183dae72a2dc252d2c58f7f4836331479ee46bcaf538b68bdca
c4de5f86f3a98183dae72a2dc252d2c58f7f4836331479ee46bcaf538b68bdca
c4de5f86f3a98183dae72a2dc252d2c58f7f4836331479ee46bcaf538b68bdca


--test--
[% USE Digest.SHA3(512) -%]
[% text = 'xyzzy'; text.sha3_base64 %]
--expect--
2sB6I8oJmE1gFBvkwZTrUOPu4H1FUjCn+8S6GsMd8NCs/psu+W8AN6zrL4B1E7YDKYz+ywLhK+kalIG38RixPA

--test--
[% USE Digest.SHA3(384) -%]
[% text = 'xyzzy'; text.sha3_base64 %]
--expect--
YK0GWATaZf09g/fvspYPqm/qtaiqf+KjaNj5uMEQCjQpuXWPjqQbeBINL5H/A0Lo

--test--
[% USE Digest.SHA3(224) -%]
[% text = 'xyzzy'; text.sha3_base64 %]
--expect--
d3VZq2pcaKssfvcBvvvdyV3bMJn+DV6E+kbZFA

