<?php
# Based on example at https://www.php.net/manual/en/function.password-needs-rehash
# This proves that PHP's password_needs_rehash returns true if the cost has changed in any way (i.e. also if it has become smaller).
mb_internal_encoding('UTF-8');
ini_set('default_charset', mb_internal_encoding());

$password = 'rasmuslerdorf';

# cost is 10 here:
$hash = '$2y$10$YCFsG6elYca568hBi2pZ0.3LDL5wjgxct1N8w/oLR/jfHsiQwCqTS';

if (!password_verify($password, $hash)) {
	die("password_verify failed with given hash!\n");
}

# The cost parameter can change over time as hardware improves
$options = ['cost' => 11];

$costs_to_try = [
	9,
	10,
	11,
];

foreach ($costs_to_try as $cost) {
	$options = ['cost' => $cost];
	$needs_rehash = password_needs_rehash($hash, PASSWORD_BCRYPT, $options);
	print "Does using cost=$cost require a rehash?: " . ($needs_rehash ? 'yes' : 'no') . "\n";
	if ($needs_rehash) {
		$new_hash = password_hash($password, PASSWORD_BCRYPT, $options);
		print "\tNew hash: $new_hash\n";
	}
}
