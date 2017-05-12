# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 16;
BEGIN { use_ok('PerlCryptLib', qw(:all)) };

use constant {
	BUFFERSIZE	=> 4*1024,
	MESSAGE		=> 'This is a test data to be enveloped!'
};

my $cryptContext = CRYPT_CONTEXT;
my $keyContext = CRYPT_CONTEXT;
my $encryptedKey = '';
my $encryptedKeyLength = 0;
my $encryptedKeyMaxLength = BUFFERSIZE;
my $salt = "01234567890";
my $saltLength = length($salt);

$action = 'start cryptlib session';
ok( cryptInit() == CRYPT_OK , $action );

#
# Export session key
#
$action = 'create 3DES export-key context';
ok( cryptCreateContext($keyContext, CRYPT_UNUSED, CRYPT_ALGO_3DES) == CRYPT_OK , $action );
$action = 'set keying-salt';
ok( cryptSetAttributeString($keyContext, CRYPT_CTXINFO_KEYING_SALT, $salt, $saltLength) == CRYPT_OK , $action );
$action = 'set keying-value';
ok( cryptSetAttributeString($keyContext, CRYPT_CTXINFO_KEYING_VALUE, MESSAGE, length(MESSAGE)) == CRYPT_OK , $action );
$action = 'create 3DES session-key encryption context';
ok( cryptCreateContext($cryptContext, CRYPT_UNUSED, CRYPT_ALGO_3DES) == CRYPT_OK , $action );
$action = 'generate session-key';
ok( cryptGenerateKey($cryptContext) == CRYPT_OK , $action );
my $null = 0;
$action = 'retrieve key length';
ok( cryptExportKey($null, 0, $encryptedKeyMaxLength, $keyContext, $cryptContext) == CRYPT_OK , $action );
$encryptedKey = ' ' x $encryptedKeyMaxLength;
$action = 'export key';
ok( cryptExportKey($encryptedKey, $encryptedKeyMaxLength, $encryptedKeyLength, $keyContext, $cryptContext) == CRYPT_OK , $action );

##### Query session key
my $cryptObjectInfo = CRYPT_OBJECT_INFO;
$action = 'query exported key';
ok( cryptQueryObject($encryptedKey, $encryptedKeyLength, $cryptObjectInfo) == CRYPT_OK , $action );
$action = 'verify exported key type';
ok( $cryptObjectInfo->{objectType} == CRYPT_OBJECT_ENCRYPTED_KEY , $action );

$action = 'destroy session-key encryption context';
ok( cryptDestroyContext($cryptContext) == CRYPT_OK, $action );
$action = 'destroy export-key context';
ok( cryptDestroyContext($keyContext) == CRYPT_OK, $action );

##### Query algo
my $cryptQueryInfo = CRYPT_QUERY_INFO;
$action = 'query 3DES-algo capability';
ok( cryptQueryCapability(CRYPT_ALGO_3DES, $cryptQueryInfo) == CRYPT_OK , $action );
$action = 'verify info-name';
ok( $cryptQueryInfo->{algoName} eq '3DES' , $action );
#foreach my $key (keys %{$cryptQueryInfo} ) {
#	warn "\t$key : ", $cryptQueryInfo->{$key}, "\n";
#}

$action = 'terminate cryptlib session';
ok( cryptEnd() == CRYPT_OK , $action );

