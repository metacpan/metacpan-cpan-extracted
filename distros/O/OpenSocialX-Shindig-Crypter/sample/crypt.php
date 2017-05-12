<?php

$str = 'o=1&v=3&p=5';
$encrypted = mcrypt_cbc(MCRYPT_RIJNDAEL_128, 'length16length16', $str, MCRYPT_ENCRYPT, '1234567890abcdef');
$decrypted = mcrypt_cbc(MCRYPT_RIJNDAEL_128, 'length16length16', $encrypted, MCRYPT_DECRYPT, '1234567890abcdef');
echo "encrypted: ".base64_encode($encrypted)."\n"; 
echo "decrypted: ".$decrypted."\n"; 

$blabla = hash_hmac('sha1', $encrypted, 'hmackey', 1);
echo "hmac: " . base64_encode($blabla) . "\n";
echo "total: " . base64_encode($encrypted . $blabla) . "\n";
