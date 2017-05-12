use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Mojo::Snoo');
}

diag('Creating Mojo::Snoo object');
my $snoo = Mojo::Snoo->new();
isa_ok($snoo, 'Mojo::Snoo');

diag('Creating Mojo::Snoo object with OAuth fields');
my $oauth_snoo = Mojo::Snoo->new(
    username      => 'user',
    password      => 'verysecret',
    client_id     => 'clientID',
    client_secret => 'clientSecret',
);
isa_ok($snoo, 'Mojo::Snoo');

diag('Creating Mojo::Snoo object with insufficient OAuth fields');
throws_ok { Mojo::Snoo->new(username => 'foobar') }
qr/^OAuth requires the following fields to be defined: username, password, client_id, client_secret
Fields defined: username at\b/;

diag(q@Checking can_ok for Mojo::Snoo's methods@);
can_ok($snoo, qw(multireddit subreddit link comment user));

my $multi = $snoo->multireddit('foo');
isa_ok($multi, 'Mojo::Snoo::Multireddit');

my $sub = $snoo->subreddit('foo');
isa_ok($sub, 'Mojo::Snoo::Subreddit');

my $link = $snoo->link('foo');
isa_ok($link, 'Mojo::Snoo::Link');

my $comment = $snoo->comment('foo');
isa_ok($comment, 'Mojo::Snoo::Comment');

my $user = $snoo->user('foo');
isa_ok($user, 'Mojo::Snoo::User');

done_testing();
