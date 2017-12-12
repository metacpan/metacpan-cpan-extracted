use strictures 1;
use Term::Prompt;
use Mojito::Auth;
use Mojito::Model::Config;
use 5.010;

my $config = Mojito::Model::Config->new->config;
my $realm = 'Mojito';
my ( $first_name, $last_name, $email, $username, $password_1, $password_2 );
USERNAME_PROMPT:
{

    #realm = prompt( 'x', 'realm:',    '', 'Mojito' );
    $username   = prompt( 'x', "\nusername:",         '', '' );
    my $mojito_auth = Mojito::Auth->new(config => $config);
    if ($mojito_auth->get_user($username)) {
        say "Username '$username' already taken!";
        goto USERNAME_PROMPT;
    }
}
PASSWORD_PROMPT:
{
    $password_1 = prompt( 'p', "\npassword:",         '', '' );
    $password_2 = prompt( 'p', "\nconfirm password:", '', '' );
    if ( $password_1 ne $password_2 ) {
        say "Passwords don't match!";
        goto PASSWORD_PROMPT;
    }
}
$first_name = prompt( 'x', "\n\nfirst name:",       '', '' );
$last_name  = prompt( 'x', "\nlast name:",        '', '' );
$email      = prompt( 'x', "\nemail:",            '', '' );
    
my $mojito_auth = Mojito::Auth->new(
    config     => $config,
    first_name => $first_name,
    last_name  => $last_name,
    email      => $email,
    username   => $username,
    realm      => $realm,
    password   => $password_1
);


my $id = $mojito_auth->add_user;

print "\nAdded user: $username with id: $id\n\n";
