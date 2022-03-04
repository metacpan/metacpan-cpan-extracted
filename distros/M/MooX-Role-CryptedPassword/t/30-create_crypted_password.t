#! perl -I. -w
use t::Test::abeltje;
use autodie;
use File::Temp qw( tempdir );
use File::Spec::Functions;

use Crypt::CBC;

my $secret = 'This is a kind of safe password for its length';
my $cipher_key = 'Here is an other longish string';
my $tmp_dir = tempdir(CLEANUP => 1);
my $secret_file = catfile($tmp_dir, 'password.private');

note('Create crypted file');
{
    local $ENV{PERL5LIB} = 'lib';
    local @ARGV = (
        '--file-name'  => $secret_file,
        '--cipher-key' => $cipher_key,
        '--password'   => $secret,
    );
    do "bin/create_crypted_password";
    is($@, "", "programme ran successfully");
    ok(-e $secret_file, "crypted password file exists");
}

note('Read crypted file');
{
    my $content = do {
        use autodie;
        open(my $fh, '<:raw', $secret_file);
        local $/;
        <$fh>;
    };

    my $dcrypt = Crypt::CBC->new(
        -cipher => 'Rijndael',
        -key    => $cipher_key,
        -pbkdf  => 'pbkdf2',
    );
    my $un_secret = $dcrypt->decrypt($content);

    is($un_secret, $secret, "Decryption was successful");
}

ok(unlink($secret_file), "temp-file removed");

abeltje_done_testing;
