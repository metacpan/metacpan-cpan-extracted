package Plack::App::FakeApache::Server;
$Plack::App::FakeApache::Server::VERSION = '0.09';
use Moo;

use Plack::App::FakeApache::Log;

has log => (
    is      => 'rw',
    default => sub { Plack::App::FakeApache::Log->new() },
    handles => [ qw(log_error log_serror warn) ],
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
