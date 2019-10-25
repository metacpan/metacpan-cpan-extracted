use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojolicious::Command::bcrypt;

{
    my $bcrypt = Mojolicious::Command::bcrypt->new;

    throws_ok { $bcrypt->run() } qr/Usage: myapp\.pl bcrypt password \[OPTIONS\]/, 'no password throws';
    throws_ok { $bcrypt->run(undef) } qr/Usage: myapp\.pl bcrypt password \[OPTIONS\]/, 'undef password throws';

    use Mojolicious::Lite;
    helper bcrypt => sub {};

    $bcrypt->app(app);
    lives_ok { $bcrypt->run('') } 'empty password lives';
    lives_ok { $bcrypt->run('password') } 'string password lives';
}

my $bcrypt = Mojolicious::Command::bcrypt->new;

for my $cost_arg (qw(-c --cost)) {
    throws_ok { $bcrypt->run('password', $cost_arg) } qr/Error parsing options/, "undef $cost_arg throws";
    throws_ok { $bcrypt->run('password', $cost_arg, '') } qr/Error parsing options/, "empty $cost_arg throws";
    throws_ok { $bcrypt->run('password', $cost_arg, 's') } qr/Error parsing options/, "string $cost_arg throws";
    throws_ok { $bcrypt->run('password', $cost_arg, '-1') } qr/cost must be between 1 and 99/, "-1 $cost_arg throws";
    throws_ok { $bcrypt->run('password', $cost_arg, '0') } qr/cost must be between 1 and 99/, "0 $cost_arg throws";
    throws_ok { $bcrypt->run('password', $cost_arg, '100') } qr/cost must be between 1 and 99/, "100 $cost_arg throws";
    lives_ok { $bcrypt->run('password', $cost_arg, '1') } "1 $cost_arg lives";
    lives_ok { $bcrypt->run('password', $cost_arg, '8') } "8 $cost_arg lives";
}

for my $nkn_arg (qw(-nkn --no-key-nul)) {
    lives_ok { $bcrypt->run('password', $nkn_arg) } "$nkn_arg lives";
}

for my $salt_arg (qw(-s --salt)) {
    throws_ok { $bcrypt->run('password', $salt_arg) } qr/Error parsing options/, "no $salt_arg throws";
    lives_ok { $bcrypt->run('password', $salt_arg, '7Wsy4kWKT56wIZdd/UVGku') } "non-empty $salt_arg lives";
}

throws_ok
    { $bcrypt->run('password', '-c', '8', '-nkn', '-s', '7Wsy4kWKT56wIZdd/UVGku', '--unknown-arg') }
    qr/Error parsing options/,
    'unknown arg throws';

throws_ok
    { $bcrypt->run('password', '-c', '8', '-nkn', '-s', '7Wsy4kWKT56wIZdd/UVGku', 'extra_arg1', 'extra_arg2', 'extra_arg3') }
    qr/unknown args passed: 'extra_arg1', 'extra_arg2', 'extra_arg3'/,
    'extra args throw';

done_testing;