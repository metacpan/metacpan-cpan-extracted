BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Digest::SHA256;
$loaded = 1;
print "ok 1\n";

$context = Digest::SHA256::new(256);

print $context->hexhash("abc") eq "ba7816bf 8f01cfea 414140de 5dae2223 b00361a3 96177a9c b410ff61 f20015ad" ? "" : "not ", "ok 2\n";
$context->reset();
print $context->hexhash("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") eq "248d6a61 d20638b8 e5c02693 0c3e6039 a33ce459 64ff2167 f6ecedd4 19db06c1" ? "" : "not ", "ok 3\n";

$context = Digest::SHA256::new(384);

print $context->hexhash("abc") eq "cb00753f45a35e8b b5a03d699ac65007 272c32ab0eded163 1a8b605a43ff5bed 8086072ba1e7cc23 58baeca134c825a7" ? "" : "not ", "ok 4\n";
$context->reset();
print $context->hexhash("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu") eq "09330c33f71147e8 3d192fc782cd1b47 53111b173b3b05d2 2fa08086e3b0f712 fcc7c71a557e2db9 66c3e9fa91746039" ? "" : "not ", "ok 5\n";

$context = Digest::SHA256::new(512);

print $context->hexhash("abc") eq "ddaf35a193617aba cc417349ae204131 12e6fa4e89a97ea2 0a9eeee64b55d39a 2192992a274fc1a8 36ba3c23a3feebbd 454d4423643ce80e 2a9ac94fa54ca49f" ? "" : "not ", "ok 6\n";
$context->reset();
print $context->hexhash("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu") eq "8e959b75dae313da 8cf4f72814fc143f 8f7779c6eb9f7fa1 7299aeadb6889018 501d289e4900f7e4 331b99dec4b5433a c7d329eeb6dd2654 5e96e55b874be909" ? "" : "not ", "ok 7\n";
