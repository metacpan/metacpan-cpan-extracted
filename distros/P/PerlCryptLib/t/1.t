# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 17;
BEGIN { use_ok('PerlCryptLib', qw(:all)) };

use constant {
	BUFFERSIZE	=> 4096,
	MESSAGE		=> 'This is a test data to be enveloped!',
	PASSWORD	=> 'mypassword'
};

my $rc = CRYPT_OK;
my $bytesCopied = 0;
my $cryptEnvelope = CRYPT_ENVELOPE;
my $cryptDeEnvelope = CRYPT_ENVELOPE;
my $envelopedData = ' ' x BUFFERSIZE;
my $finalMessage = ' ' x BUFFERSIZE;
my $messageLength = length(MESSAGE);
my $passwordLength = length(PASSWORD);
my $bytesRead = 0;
my $action;

$action = 'start cryptlib session';
ok( cryptInit() == CRYPT_OK , $action );

$action = 'create an envelope for data encryption';
ok( cryptCreateEnvelope($cryptEnvelope, CRYPT_UNUSED, CRYPT_FORMAT_CRYPTLIB) == CRYPT_OK , $action );

$action = 'set encryption password';
ok( cryptSetAttributeString($cryptEnvelope, CRYPT_ENVINFO_PASSWORD, PASSWORD, $passwordLength) == CRYPT_OK , $action );
$action = 'set envelope data size';
ok( cryptSetAttribute($cryptEnvelope, CRYPT_ENVINFO_DATASIZE, $messageLength) == CRYPT_OK , $action );

$action = 'push data into envelope';
ok( cryptPushData($cryptEnvelope, MESSAGE, $messageLength, $bytesCopied) == CRYPT_OK , $action );

$action = 'flush envelope data';
ok( cryptFlushData($cryptEnvelope) == CRYPT_OK , $action );

$action = 'pop data from the envelope';
ok( cryptPopData($cryptEnvelope, $envelopedData, BUFFERSIZE, $bytesRead) == CRYPT_OK , $action );

$action = 'destroy encryption envelope';
ok( cryptDestroyEnvelope($cryptEnvelope) == CRYPT_OK , $action );

$action = 'create another envelope for data decryption';
ok( cryptCreateEnvelope($cryptDeEnvelope, CRYPT_UNUSED, CRYPT_FORMAT_AUTO) == CRYPT_OK , $action );

$action = 'push data to decrypt';
$rc = cryptPushData($cryptDeEnvelope, $envelopedData, $bytesRead, $bytesCopied);
ok( $rc == CRYPT_ENVELOPE_RESOURCE  ||  $rc == CRYPT_OK , $action );

$action = 'set decryption password';
ok( cryptSetAttributeString($cryptDeEnvelope, CRYPT_ENVINFO_PASSWORD, PASSWORD, $passwordLength) == CRYPT_OK , $action );

$action = 'flush de-envelope data';
ok( cryptFlushData($cryptDeEnvelope) == CRYPT_OK , $action );

$action = 'pop decrypted data';
ok( cryptPopData($cryptDeEnvelope, $finalMessage, BUFFERSIZE, $bytesRead) == CRYPT_OK , $action );

$action = 'compare raw and decrypted data';
$finalMessage = substr($finalMessage, 0, $bytesRead);
ok( MESSAGE eq $finalMessage , $action );

$action = 'destroy decryption envelope';
ok( cryptDestroyEnvelope($cryptDeEnvelope) == CRYPT_OK , $action );

$action = 'terminate cryptlib session';
ok( cryptEnd() == CRYPT_OK , $action );

