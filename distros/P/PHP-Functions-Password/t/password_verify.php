<?php
# https://github.com/php/doc-en/issues/1328
mb_internal_encoding('UTF-8');
ini_set('default_charset', mb_internal_encoding());

$tests = [
	# These should all work with the same hash since the first 72 bytes in each are the same:
	'これは、それぞれが複数のバイトで構成される文字である日本語の文です。' => '$2y$10$8r90pAKtxZzcWQRsJpOKge6rXAP.1UtvQntdk38RhuAjrXXkplqr.',	# 34 chars, 102 bytes
	'これは、それぞれが複数のバイトで構成される文字であ'				=> '$2y$10$8r90pAKtxZzcWQRsJpOKge6rXAP.1UtvQntdk38RhuAjrXXkplqr.',	# 25 chars, 75 bytes
	'これは、それぞれが複数のバイトで構成される文字で'					=> '$2y$10$8r90pAKtxZzcWQRsJpOKge6rXAP.1UtvQntdk38RhuAjrXXkplqr.',	# 24 chars, 72 bytes

	# This should fail using the same hash as above since the byte length is less than 72:
	'これは、それぞれが複数のバイトで構成される文字'					=> '$2y$10$8r90pAKtxZzcWQRsJpOKge6rXAP.1UtvQntdk38RhuAjrXXkplqr.',	# 23 chars, 69 bytes (hash should fail)
];

$tests = [
	# These should all work with the same hash since the first 72 bytes in each are the same:
	'*これは、それぞれが複数のバイトで構成される文字である日本語の文です。'=> '$2y$10$dmQi9mPJWaEHifmpXlCoKOmcaSzFQ1kUszKzMBtig2lzBXLRvS8Wq',	# 34 chars, 102 bytes
	'*これは、それぞれが複数のバイトで構成される文字であ'				=> '$2y$10$dmQi9mPJWaEHifmpXlCoKOmcaSzFQ1kUszKzMBtig2lzBXLRvS8Wq',	# 25 chars, 75 bytes
	'*これは、それぞれが複数のバイトで構成される文字で'				=> '$2y$10$dmQi9mPJWaEHifmpXlCoKOmcaSzFQ1kUszKzMBtig2lzBXLRvS8Wq',	# 24 chars, 72 bytes

	# This should fail using the same hash as above since the byte length is less than 72:
	'*これは、それぞれが複数のバイトで構成される文字'					=> '$2y$10$dmQi9mPJWaEHifmpXlCoKOmcaSzFQ1kUszKzMBtig2lzBXLRvS8Wq',	# 23 chars, 69 bytes (hash should fail)
];

foreach ($tests as $password => $crypted) {
	$char_len = mb_strlen($password);
	$byte_len = strlen($password);
	error_log("password_verify('$password', '$crypted') (chars=$char_len, bytes=$byte_len) returns " . json_encode(password_verify($password, $crypted)));
	error_log("'$password' => '" . password_hash($password, PASSWORD_BCRYPT) . "'");
}


#error_log(password_hash('*これは、それぞれが複数のバイトで構成される文字で', PASSWORD_BCRYPT));
