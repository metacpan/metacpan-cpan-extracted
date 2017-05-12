package Plack::App::FakeApache::Server;

use Moose;

use Plack::App::FakeApache::Log;

has log => (
    is      => 'rw',
    default => sub { Plack::App::FakeApache::Log->new() },
    handles => [ qw(log_error log_serror warn) ],
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
