use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Crypt::Eksblowfish::Bcrypt;

plugin 'BcryptSecure';

my @passwords = (
    '',
    undef,
    0,
    'password',
    'U*U',
    'U*U*',
    'U*U*U',
    '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
);
my @wrong_passwords = qw(foo quux supercalifragilisticexpialidocious);
for my $password (@passwords) {
    my $crypted_password = app->bcrypt($password);

    ok $crypted_password =~ m#\A\$2(a?)\$([0-9]{2})\$([./A-Za-z0-9]{22})#x, 'bcrypt returns valid crypted text';

    my ($key_nul, $cost, $salt_base64) = ($1, $2, $3);
    is $key_nul, 'a', 'key_nul set';
    is $cost, 12, 'cost is 12';

    my $settings = '$2a$' . $cost . '$' . $salt_base64;
    my $settings_with_different_cost = '$2a$08$' . $salt_base64;
    is $crypted_password, Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings), q{BcryptSecure's crypted text matches Crypt::Eksblowfish::Bcrypt};
    isnt $crypted_password, Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings_with_different_cost), q{different cost doesn't match};

    my $password_for_string = !defined $password ? 'undef'
                            : $password eq ''    ? 'empty string'
                            : $password;
    isnt $crypted_password, Crypt::Eksblowfish::Bcrypt::bcrypt($_, $settings), qq{crypted $password_for_string doesn't equal crypted $_} for (@wrong_passwords);
}

done_testing;
