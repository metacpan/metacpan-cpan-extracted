use strict;
use Test::More tests => 10;
use Test::Exception;
use POSIX ();

use_ok 'Sys::Signals::Block' or exit 1;

my $instance = Sys::Signals::Block->instance;

lives_ok {
    $instance->import(qw(INT TERM));
} 'named signals';
ok $instance->sigset->ismember(POSIX::SIGINT());
ok $instance->sigset->ismember(POSIX::SIGTERM());

lives_ok {
    $instance->import(qw(SIGINT SIGTERM));
} 'SIG named signals';
ok $instance->sigset->ismember(POSIX::SIGINT());
ok $instance->sigset->ismember(POSIX::SIGTERM());

lives_ok {
    $instance->import(POSIX::SIGINT(), POSIX::SIGTERM());
} 'numeric signals';
ok $instance->sigset->ismember(POSIX::SIGINT());
ok $instance->sigset->ismember(POSIX::SIGTERM());
