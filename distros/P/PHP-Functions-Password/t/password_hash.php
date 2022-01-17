<?php
mb_internal_encoding('UTF-8');
ini_set('default_charset', mb_internal_encoding());

$password = "\01234567";
$hash = password_hash($password, PASSWORD_BCRYPT);
print "Hash of password starting with null byte: $hash\n";
$other_password = "\0blabla";
if (password_verify($other_password, $hash)) {
	print "WARNING: do not use passwords with NULL bytes!\n";
}
else {
	print "It's safe to use passwords with NULL bytes.\n";
}
