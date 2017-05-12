package Task::Digest;

use strict;
use warnings;

our $VERSION = '0.05';
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

=item * L<Digest::BLAKE>

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

=item * L<Digest::Shabal>

=item * L<Digest::SHAvite3>

=item * L<Digest::SIMD>

=item * L<Digest::Skein>

=item * L<Digest::Whirlpool>

=back

=head1 BENCHMARKS

This distribution contains a benchmarking script which compares the
available message digest algorithms. These are the results on a MacBook 2GHz
Core 2 Duo (64-bit) with Perl 5.12.2, using a message size of 1KB:

    edonr_384    290443/s   284 MB/s
    edonr_512    287827/s   281 MB/s
    md4          287826/s   281 MB/s
    md5          245759/s   240 MB/s
    bmw_384      215039/s   210 MB/s
    bmw_512      208776/s   204 MB/s
    edonr_224    187398/s   183 MB/s
    edonr_256    182856/s   179 MB/s
    skein_512    157466/s   154 MB/s
    blake_384    156392/s   153 MB/s
    blake_512    154983/s   151 MB/s
    skein_256    148716/s   145 MB/s
    bmw_256      131523/s   128 MB/s
    bmw_224      131522/s   128 MB/s
    blake_224    120302/s   117 MB/s
    blake_256    119300/s   117 MB/s
    sha_sha_1    112439/s   110 MB/s
    sha1_sha_1   106193/s   104 MB/s
    shabal_224    94575/s    92 MB/s
    shabal_256    92839/s    91 MB/s
    shabal_384    91167/s    89 MB/s
    skein_1024    80842/s    79 MB/s
    sha_256       73770/s    72 MB/s
    sha_512       73770/s    72 MB/s
    sha_224       71739/s    70 MB/s
    sha_384       71087/s    69 MB/s
    shabal_512    70134/s    68 MB/s
    keccak_256    60151/s    59 MB/s
    keccak_224    60151/s    59 MB/s
    luffa_256     54098/s    53 MB/s
    luffa_224     54098/s    53 MB/s
    ripemd_160    50717/s    50 MB/s
    keccak_384    49321/s    48 MB/s
    md6_224       46849/s    46 MB/s
    fugue_256     46849/s    46 MB/s
    fugue_224     46849/s    46 MB/s
    md6_256       44660/s    44 MB/s
    shavite3_224  42666/s    42 MB/s
    shavite3_256  41918/s    41 MB/s
    groestl_224   41754/s    41 MB/s
    groestl_256   41353/s    40 MB/s
    luffa_384     40573/s    40 MB/s
    echo_256      39010/s    38 MB/s
    echo_224      38641/s    38 MB/s
    md6_384       36202/s    35 MB/s
    keccak_512    34132/s    33 MB/s
    fugue_384     31210/s    30 MB/s
    luffa_512     29805/s    29 MB/s
    md6_512       29020/s    28 MB/s
    gost          28980/s    28 MB/s
    cubehash_224  27927/s    27 MB/s
    cubehash_512  27926/s    27 MB/s
    cubehash_384  27926/s    27 MB/s
    cubehash_256  27926/s    27 MB/s
    hamsi_256     24889/s    24 MB/s
    hamsi_224     24888/s    24 MB/s
    fugue_512     22998/s    22 MB/s
    echo_512      21154/s    21 MB/s
    echo_384      21154/s    21 MB/s
    simd_256      20479/s    20 MB/s
    shavite3_384  19566/s    19 MB/s
    simd_224      18601/s    18 MB/s
    shavite3_512  18101/s    18 MB/s
    groestl_384   17935/s    18 MB/s
    groestl_512   17935/s    18 MB/s
    whirlpool     16567/s    16 MB/s
    jh_384        14354/s    14 MB/s
    jh_512        14354/s    14 MB/s
    jh_256        14354/s    14 MB/s
    jh_224        14354/s    14 MB/s
    simd_512      13273/s    13 MB/s
    simd_384      12670/s    12 MB/s
    hamsi_384      7657/s     7 MB/s
    hamsi_512      7657/s     7 MB/s
    md2            5338/s     5 MB/s
    perl_sha_1      175/s  0.17 MB/s
    perl_sha_256    126/s  0.12 MB/s
    perl_sha_224    125/s  0.12 MB/s
    perl_md5         77/s  0.08 MB/s
    perl_md4         77/s  0.08 MB/s
    perl_sha_512     61/s  0.06 MB/s
    perl_sha_384     60/s  0.06 MB/s

=head1 SEE ALSO

L<Digest>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Task-Digest>.  I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

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

Copyright (C) 2010 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
