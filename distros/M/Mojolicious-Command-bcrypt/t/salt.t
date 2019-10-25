use Mojo::Base -strict;
use Test::More;
use Crypt::Eksblowfish::Bcrypt ();
use Crypt::URandom ();
use Mojolicious::Command::bcrypt;

my @salts = qw(GjIdEnVRcKnfDYM7.E6H2O 1PvhX.RV6DWqccApMFwX1u puAdC2TbsnDm60hcMxyimO);
my @passwords = (
    0,
    'password',
    'U*U',
    'U*U*',
    'U*U*U',
    '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
);
my @wrong_passwords = qw(foo quux supercalifragilisticexpialidocious);

for my $salt (@salts) {
    for my $password (@passwords) {
        my $bcrypt = Mojolicious::Command::bcrypt->new;

        close STDOUT;
        open STDOUT, '>', \my $crypted_password or die "Couldn't open STDOUT: $!";
        $bcrypt->run($password, '--salt', $salt);
        close STDOUT;

        is chomp($crypted_password), 1, 'newline exists in crypted password output';

        ok $crypted_password =~ m#\A\$2(a?)\$([0-9]{2})\$([./A-Za-z0-9]{22})#x, 'bcrypt returns valid crypted text';

        my ($key_nul, $cost, $salt_base64) = ($1, $2, $3);
        is $key_nul, 'a', 'key_nul set';
        is $cost, '12', 'cost is 12';
        is $salt_base64, $salt;

        my $settings = '$2a$' . $cost . '$' . $salt_base64;
        my $settings_with_different_salt = '$2a$' . $cost . '$' . Crypt::Eksblowfish::Bcrypt::en_base64(Crypt::URandom::urandom(16));

        my $password_for_string = !defined $password ? 'undef'
                                : $password eq ''    ? 'empty string'
                                : $password;
        isnt $crypted_password, Crypt::Eksblowfish::Bcrypt::bcrypt($_, $settings), qq{crypted $password_for_string doesn't equal crypted $_} for (@wrong_passwords);
        is $crypted_password, Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings), qq{BcryptSecure's crypted text matches Crypt::Eksblowfish::Bcrypt for '$password_for_string'};
        isnt $crypted_password, Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings_with_different_salt), q{different salt doesn't match};
    }
}

done_testing;
