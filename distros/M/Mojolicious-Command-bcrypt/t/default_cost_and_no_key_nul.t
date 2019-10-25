use Mojo::Base -strict;
use Test::More;
use Crypt::Eksblowfish::Bcrypt ();
use Mojolicious::Command::bcrypt;

my @passwords = (
    0,
    'password',
    'U*U',
    'U*U*',
    'U*U*U',
    '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
);
my @wrong_passwords = qw(foo quux supercalifragilisticexpialidocious);
for my $password (@passwords) {
    my $bcrypt = Mojolicious::Command::bcrypt->new;

    close STDOUT;
    open STDOUT, '>', \my $crypted_password or die "Couldn't open STDOUT: $!";
    $bcrypt->run($password, '--nkn');
    close STDOUT;

    is chomp($crypted_password), 1, 'newline exists in crypted password output';

    ok $crypted_password =~ m#\A\$2(a?)\$([0-9]{2})\$([./A-Za-z0-9]{22})#x, 'bcrypt returns valid crypted text';

    my ($key_nul, $cost, $salt_base64) = ($1, $2, $3);
    ok !$key_nul, 'key_nul not set';
    is $cost, '12', 'cost is 12';

    my $settings = '$2$' . $cost . '$' . $salt_base64;
    my $settings_with_different_cost = '$2$08$' . $salt_base64;

    my $password_for_string = !defined $password ? 'undef'
                            : $password eq ''    ? 'empty string'
                            : $password;
    isnt $crypted_password, Crypt::Eksblowfish::Bcrypt::bcrypt($_, $settings), qq{crypted $password_for_string doesn't equal crypted $_} for (@wrong_passwords);
    is $crypted_password, Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings), qq{BcryptSecure's crypted text matches Crypt::Eksblowfish::Bcrypt for '$password_for_string'};
    isnt $crypted_password, Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings_with_different_cost), q{different cost doesn't match};

}

done_testing;
