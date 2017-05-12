use Sub::Installer;
use Test::More 'no_plan';
use warnings;

my $ok = q{ ok $_[0], $_[1] };
my $is = q{ is $_[0], $_[1], $_[2] };

my $sub_ref = main->install_sub({ ok1 => $ok, ok2 => $is });

ok1(1                                    => 'first installed sub runs');
ok2(2,2                                  => 'second installed sub runs');

$SIG{__WARN__}
    = sub { ok 0 => "warned unexpected: @_" if $_[0] =~ /redefined/ };

$sub_ref = main->reinstall_sub({ ok1 => $is, ok2 => $ok });

ok1(2,2                                  => 'first reinstalled sub runs');
ok2(2                                    => 'second reinstalled sub runs');

ok !eval{$sub_ref = main->reinstall_sub({ ok1 => $is.'%^&%#@^&#%' }) }
                                         => 'bad code failed as expected';

like $@, qr/Can't install invalid code/  => 'failed with correct message';


