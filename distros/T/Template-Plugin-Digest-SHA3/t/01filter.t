#!/usr/bin/perl -w
use strict;

use Digest::SHA3;
use Template::Test;

$Template::Test::DEBUG = 0;

if($Digest::SHA3::VERSION > 0.22) {
    print STDERR "# These test only apply to Digest::SHA3 v0.22 or lower\n";
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
adfb49649e8bb5a356c12cd3eb9fb328f6d57a340326362e6dc654aa85606fb6


# text | sha3_hex
--test--
[% USE Digest.SHA3 -%]
[% 'xyzzy' | sha3_hex %]
[% text = 'xyzzy'; text.sha3_hex %]
--expect--
fcf1eb3041aa2eefd41cda62428456933e23e77d2b6307e5a4e8904ab4243457
fcf1eb3041aa2eefd41cda62428456933e23e77d2b6307e5a4e8904ab4243457

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
rftJZJ6LtaNWwSzT65+zKPbVejQDJjYubcZUqoVgb7Y


# text | sha3_base64
--test--
[% USE Digest.SHA3 -%]
[% 'xyzzy' | sha3_base64 %]
--expect--
/PHrMEGqLu/UHNpiQoRWkz4j530rYwflpOiQSrQkNFc

--test--
[% USE Digest.SHA3 -%]
[% text = 'xyzzy'; text.sha3_base64 %]
--expect--
/PHrMEGqLu/UHNpiQoRWkz4j530rYwflpOiQSrQkNFc


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
b076952da24a90f6f0d50b232ee3cd1745381166cf202ce017cd5cf2673b8504


# Test the sha3 filter and vmethod
--test--
[% USE Digest.SHA3 -%]
[% checksum1 = 'xyzzy' | sha3; checksum1.sha3_hex %]
[% text1 = 'xyzzy'; text1.sha3 | sha3_hex %]
[% text2 = 'xyzzy'; text2.sha3.sha3_hex %]
--expect--
572375b3aa0d912e8215ee89f33c93e3bc44f869136721f7cf10e7dfb8d72652
572375b3aa0d912e8215ee89f33c93e3bc44f869136721f7cf10e7dfb8d72652
572375b3aa0d912e8215ee89f33c93e3bc44f869136721f7cf10e7dfb8d72652


--test--
[% USE Digest.SHA3(512) -%]
[% text = 'xyzzy'; text.sha3_base64 %]
--expect--
Kaa7QBGIgMH0/bhbN82am54HSOqQ7m+GLcivZI5HAIy27kiQJJ1anOqAZyKwKHQ6CXfHM3Z9zpiuD2c/9dth2Q

--test--
[% USE Digest.SHA3(384) -%]
[% text = 'xyzzy'; text.sha3_base64 %]
--expect--
dZrynfP1M+FXRS1uJ8jbsFwhZyipIpUnSThk2+UsdwQjF99IcGZEqjmssmKpxW+2

--test--
[% USE Digest.SHA3(224) -%]
[% text = 'xyzzy'; text.sha3_base64 %]
--expect--
MQqCVouyT1RERo3OKurC6OTYkHpdySyPHaYs7Q

