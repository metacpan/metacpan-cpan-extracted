package Task::Digest;

use strict;
use warnings;

our $VERSION = '0.07';
$VERSION = eval $VERSION;


1;

__END__

=head1 NAME

Task::Digest - Task to install all available cryptographic message digests

=head1 DESCRIPTION

This distribution contains no actual code; it simply exists to provide
a list of dependencies to assist in quickly installing all available
cryptographic message digests.

=head1 MODULES

=over

=item * L<Crypt::RIPEMD160>

=item * L<CryptX>

=item * L<Digest::BLAKE>

=item * L<Digest::BLAKE2>

=item * L<Digest::BMW>

=item * L<Digest::CubeHash::XS>

=item * L<Digest::ECHO>

=item * L<Digest::EdonR>

=item * L<Digest::Fugue>

=item * L<Digest::GOST>

=item * L<Digest::Groestl>

=item * L<Digest::Hamsi>

=item * L<Digest::JH>

=item * L<Digest::Keccak>

=item * L<Digest::Luffa>

=item * L<Digest::MD2>

=item * L<Digest::MD4>

=item * L<Digest::MD5>

=item * L<Digest::MD6>

=item * L<Digest::Perl::MD4>

=item * L<Digest::Perl::MD5>

=item * L<Digest::SHA>

=item * L<Digest::SHA1>

=item * L<Digest::SHA::PurePerl>

=item * L<Digest::SHA3>

=item * L<Digest::Shabal>

=item * L<Digest::SHAvite3>

=item * L<Digest::SIMD>

=item * L<Digest::Skein>

=item * L<Digest::Whirlpool>

=back

=head1 BENCHMARKS

This distribution contains a benchmarking script which compares the available
message digest algorithms. These are the results on a MacBook 2.6GHz Core i5
(64-bit) with Perl 5.26.0:, using a message size of 1KB:

    edonr_512         793688/s   775 MB/s
    edonr_384         789138/s   771 MB/s
    bmw_384           472615/s   462 MB/s
    bmw_512           472332/s   461 MB/s
    edonr_256         454210/s   444 MB/s
    edonr_224         449757/s   439 MB/s
    md4               436906/s   427 MB/s
    blake2b           432785/s   423 MB/s
    blake2s           362172/s   354 MB/s
    md5               341672/s   334 MB/s
    shabal_384        329098/s   321 MB/s
    blake_512         322947/s   315 MB/s
    blake_384         321554/s   314 MB/s
    shabal_224        309131/s   302 MB/s
    shabal_512        307199/s   300 MB/s
    shabal_256        300623/s   294 MB/s
    bmw_256           267963/s   262 MB/s
    bmw_224           265481/s   259 MB/s
    skein_1024        219428/s   214 MB/s
    blake_224         202867/s   198 MB/s
    blake_256         202867/s   198 MB/s
    keccak_256        182044/s   178 MB/s
    sha1_sha_1        182044/s   178 MB/s
    keccak_224        179293/s   175 MB/s
    sha_sha_1         170666/s   167 MB/s
    skein_512         151837/s   148 MB/s
    keccak_384        146161/s   143 MB/s
    md6_224           128478/s   125 MB/s
    md6_256           123675/s   121 MB/s
    shavite3_256      122530/s   120 MB/s
    shavite3_224      121406/s   119 MB/s
    skein_256         118153/s   115 MB/s
    ripemd_160        115071/s   112 MB/s
    sha_224           104981/s   103 MB/s
    sha3_384          102400/s   100 MB/s
    keccak_512        102399/s   100 MB/s
    sha_384           102399/s   100 MB/s
    luffa_256         100486/s    98 MB/s
    md6_384            99556/s    97 MB/s
    luffa_224          99211/s    97 MB/s
    sha3_224           98642/s    96 MB/s
    sha_512            96515/s    94 MB/s
    sha_256            96376/s    94 MB/s
    fugue_224          89321/s    87 MB/s
    fugue_256          88494/s    86 MB/s
    cryptx_md4         85333/s    83 MB/s
    sha3_256           84620/s    83 MB/s
    md6_512            83510/s    82 MB/s
    simd_256           77491/s    76 MB/s
    cryptx_md5         76799/s    75 MB/s
    luffa_384          76119/s    74 MB/s
    simd_224           74472/s    73 MB/s
    cryptx_tiger192    73277/s    72 MB/s
    cryptx_ripemd256   73080/s    71 MB/s
    shavite3_384       71739/s    70 MB/s
    shavite3_512       71087/s    69 MB/s
    cryptx_sha512_224  70447/s    69 MB/s
    cryptx_sha512      70447/s    69 MB/s
    cryptx_sha384      69818/s    68 MB/s
    echo_224           68593/s    67 MB/s
    groestl_256        68593/s    67 MB/s
    cryptx_sha512_256  68593/s    67 MB/s
    cryptx_ripemd128   68266/s    67 MB/s
    cryptx_sha1        68218/s    67 MB/s
    echo_256           67622/s    66 MB/s
    groestl_224        67622/s    66 MB/s
    simd_512           63883/s    62 MB/s
    cryptx_ripemd320   63621/s    62 MB/s
    simd_384           61837/s    60 MB/s
    fugue_384          61265/s    60 MB/s
    cryptx_ripemd160   60703/s    59 MB/s
    whirlpool          58554/s    57 MB/s
    luffa_512          58513/s    57 MB/s
    jh_256             57420/s    56 MB/s
    sha3_512           56889/s    56 MB/s
    cubehash_256       56888/s    56 MB/s
    jh_224             56888/s    56 MB/s
    cubehash_512       56776/s    55 MB/s
    cubehash_224       56367/s    55 MB/s
    jh_384             56366/s    55 MB/s
    jh_512             56366/s    55 MB/s
    cubehash_384       56366/s    55 MB/s
    cryptx_sha224      53894/s    53 MB/s
    cryptx_sha256      53593/s    52 MB/s
    hamsi_224          47733/s    47 MB/s
    hamsi_256          46849/s    46 MB/s
    fugue_512          44823/s    44 MB/s
    groestl_512        44021/s    43 MB/s
    groestl_384        43840/s    43 MB/s
    gost               43050/s    42 MB/s
    cryptx_whirlpool   41155/s    40 MB/s
    cryptx_sha3_256    37236/s    36 MB/s
    echo_512           36885/s    36 MB/s
    echo_384           36202/s    35 MB/s
    cryptx_sha3_224    35870/s    35 MB/s
    cryptx_chaes       33083/s    32 MB/s
    cryptx_sha3_384    31716/s    31 MB/s
    cryptx_sha3_512    23866/s    23 MB/s
    hamsi_512          19166/s    19 MB/s
    hamsi_384          18618/s    18 MB/s
    md2                 6762/s     7 MB/s
    cryptx_md2          6508/s     6 MB/s
    perl_sha_1           424/s  0.41 MB/s
    perl_sha_256         359/s  0.35 MB/s
    perl_sha_224         352/s  0.34 MB/s
    perl_md4             256/s  0.25 MB/s
    perl_md5             254/s  0.25 MB/s
    perl_sha_384         221/s  0.22 MB/s
    perl_sha_512         212/s  0.21 MB/s

=head1 SEE ALSO

L<Digest>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Task-Digest>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Digest

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/task-digest>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Digest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Digest>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Task-Digest>

=item * Search CPAN

L<http://search.cpan.org/dist/Task-Digest/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2017 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
