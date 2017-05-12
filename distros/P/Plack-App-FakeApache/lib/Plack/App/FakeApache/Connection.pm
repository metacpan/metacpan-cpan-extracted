package Plack::App::FakeApache::Connection;

use Moose;
use Plack::App::FakeApache::Log;

has remote_ip => (
    is => 'rw',
    isa => 'Str',
);

has log => ( 
    is => 'rw',
    default => sub { Plack::App::FakeApache::Log->new() },
    handles => [qw(log_error log_serror warn)],
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Plack::App::FakeApache::Request::Connection - mock Apache::Connection for Plack

=head1 DESCRIPTION

Only the C<remote_ip> method is implmented.
