#! perl -w
use strict;
use autodie;

use Test::More;
BEGIN {
    eval "require Moose";
    plan skip_all => "Moose not found..." if $@;
}
use Test::NoWarnings ();

use Crypt::CBC;

subtest 'Basic test' => sub {
    my $private = 't/a_password.priv';
    my $to_protect = 'Dit-is-een-lang-en-zeer-geheim-zinnetje.';
    {
        open my $fh, '>', $private;
        my $c = Crypt::CBC->new(cypher => 'Rijndael', key => 'BlahBlahBlahBlah');
        print $fh $c->encrypt($to_protect);
        close($fh);
    }

    my $obj = WithPwd->new(password_file => $private, username => 'abeltje');
    is($obj->password, $to_protect, "Password is decrypted");
    is($obj->username, 'ABELTJE', "Username is uppercased");

    unlink($private);
};

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing;

BEGIN {
    package WithPwd;
    use Moose;
    with 'MooX::Role::CryptedPassword';

    has username    => (is => 'ro', required => 1);

    around BUILDARGS => sub {
        my $bldargs = shift;
        my $class => shift;

        my %args = @_;
        $args{username} = uc($args{username});

        $class->$bldargs(%args);
    };

    no Moose;
    __PACKAGE__->meta->make_immutable();
    1;
}
