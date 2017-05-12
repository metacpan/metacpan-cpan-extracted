#! perl -w
use strict;

use Test::More;
use Test::NoWarnings ();

use Crypt::CBC;

my $secret = 'This is a kind of safe password for its length';
my $cipher_key = 'Here is an other longish string';
my $secret_file = 't/password.private';

END { unlink $secret_file }

subtest 'Create crypted file' => sub {
    local $ENV{PERL5LIB} = 'lib';
    local @ARGV = (
        '--file-name'  => $secret_file,
        '--cipher-key' => $cipher_key,
        '--password'   => $secret,
    );
    do "bin/create_crypted_password";
    is($@, "", "programme ran successfully");
    ok(-e $secret_file, "crypted password file exists");
};

subtest 'Read crypted file' => sub {
    use autodie;
    my $content = do {local (@ARGV, $/) = ($secret_file); <>};

    my $dcrypt = Crypt::CBC->new(cipher => 'Rijndael', cipher_key => $cipher_key);
    my $un_secret = $dcrypt->decrypt($content);

    is($un_secret, $secret, "Decryption was successful");
};

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing;
