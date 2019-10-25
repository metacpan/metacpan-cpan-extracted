use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::Output;
use Mojolicious::Lite;
use Mojolicious::Command::bcrypt;

helper bcrypt => sub { $_[1] };

my $bcrypt = Mojolicious::Command::bcrypt->new;

throws_ok { $bcrypt->run('password') } qr/bcrypt/, 'bcrypt not installed helper throws';

$bcrypt->app(app);
for my $password (qw(password s3cr3t 0)) {
    stdout_is { $bcrypt->run($password) } "$password\n", "bcrypt helper used to crypt $password";
}

done_testing;