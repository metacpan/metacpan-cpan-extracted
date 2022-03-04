#! perl -I. -w
use t::Test::abeltje;
use autodie;
use File::Temp qw( tempdir );
use File::Spec::Functions;

use Crypt::CBC;

note('Basic test');
{
    my $obj = WithPwd->new(password => 'Secret-as-hell', username => 'abeltje');
    isa_ok($obj, 'WithPwd');
    ok($obj->DOES('MooX::Role::CryptedPassword'), "role consumed");

    is($obj->password, 'Secret-as-hell', "Plain text password");
    is($obj->username, 'ABELTJE', "Username is uppercased");
}

note('Encrypted password');
{
    my $tmp_dir = tempdir(CLEANUP => 1);
    my $private = catfile($tmp_dir, 'a_password.priv');
    my $to_protect = 'Dit-is-een-lang-en-zeer-geheim-zinnetje.';
    {
        open my $fh, '>:raw', $private;
        my $c = Crypt::CBC->new(
            -cipher => 'Rijndael',
            -key    => 'BlahBlahBlahBlah',
            -pbkdf  => 'pbkdf2',
        );
        print $fh $c->encrypt($to_protect);
        close($fh);
    }

    my $obj = WithPwd->new(password_file => $private, username => 'abeltje');
    is($obj->password, $to_protect, "Password is decrypted");
    is($obj->username, 'ABELTJE', "Username is uppercased");

    unlink($private);
}

abeltje_done_testing();

BEGIN {
    package WithPwd;
    use Moo;
    with 'MooX::Role::CryptedPassword';

    has username    => (is => 'ro', required => 1);

    around BUILDARGS => sub {
        my $bldargs = shift;
        my $class => shift;

        my %args = @_;
        $args{username} = uc($args{username});

        $class->$bldargs(%args);
    };

    1;
}
