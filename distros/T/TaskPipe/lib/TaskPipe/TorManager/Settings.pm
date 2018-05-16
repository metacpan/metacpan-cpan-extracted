package TaskPipe::TorManager::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::TorManager::Settings - settings for L<TaskPipe::TorManager>

=head1 METHODS

=over

=item exec_name

The name of the tor executable (usually 'tor')

=cut

has exec_name => (is => 'ro', isa => 'Str', default => 'tor');


=item process_name

The name to identify tor processes on the database

=cut

has process_name => (is => 'ro', isa => 'Str', default => 'tor');


=item exec_opts

A hash describing which tor option to get from which command line parameter

=cut

has exec_opts => (is => 'ro', isa => 'HashRef', default => sub{{
    f => '-f',
    ControlPort => "--ControlPort",
    SocksPort => "--SocksPort",
    DataDirectory => "--DataDirectory",
    HashedControlPassword => "--HashedControlPassword",
    "hash-password" => "--hash-password"
}});


=item kill_cmd

The command used to kill tor processes

=cut

has kill_cmd => (is => 'ro', isa => 'Str', default => 'kill <pid>');


=item scheme

The scheme to use to connect to tor 

=cut

has scheme => (is => 'ro', isa => 'Str', default => 'socks');


=item ip

The ip to use to connect to tor

=cut

has ip => (is => 'ro', isa => 'Str', default => '127.0.0.1');


=item base_port

The lowest port number to use to connect to tor

=cut

has base_port => (is => 'ro', isa => 'Str', default => '9050'); 


=item config_path

The path to the tor config (normally 'torrc')

=cut

has config_path => (is => 'ro', isa => 'Str', default => '/etc/tor/torrc');


=item protocols

The protocols to proxy with tor

=back

=cut

has protocols => (is => 'ro', isa => 'ArrayRef', default => sub{['http','https']});


=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;
