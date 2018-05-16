package TaskPipe::OpenProxyManager::Settings;

use Moose;
with 'MooseX::ConfigCascade';
with 'TaskPipe::Role::MooseType_StrArrayRef';
with 'TaskPipe::Role::MooseType_ShellMode';
with 'TaskPipe::Role::MooseType_IterateMode';


=head1 NAME

TaskPipe::OpenProxyManager::Settings - settings for TaskPipe::OpenProxyManager

=head1 METHODS

=over

=item shell

Whether to run in the terminal or daemonize. Options are C<foreground> and C<background>

=cut

has shell => (is => 'ro', isa => 'ShellMode', default => 'foreground');



=item iterate

Choices are 'once' or 'repeat'. To kick off a daemon process that continually polls for open proxies, use C<--shell=background> together with C<--iterate=repeat>

=cut

has iterate => (is => 'ro', isa => 'IterateMode', default => 'once');



=item poll_interval

If --iterate=repeat then --poll_interval is the number of seconds to wait between iterations. --poll_interval is ignored if --iterate=once

=cut

has poll_interval => (is => 'ro', isa => 'Int', default => '600');



=item proxy_scheme

The scheme passed to the proxy. Usually this is 'http' and does not need to be changed

=cut

has proxy_scheme => (is => 'ro', isa => 'Str', default => 'http');



=item protocols

Which protocols to proxy e.g. --protocols=http,https

=cut

has protocols => (is => 'ro', isa => 'StrArrayRef', default => sub{["http","https"]});



=item ip_list_names

The names of lists to check for open proxies

=cut

has ip_list_names => (is => 'ro', isa => 'StrArrayRef', default => sub{[
    'PremProxy',
    'ProxyNova',
    'Xroxy'
]});


=item unavailable_poll_interval

The number of seconds to wait before trying again if there are no available proxies

=cut

has unavailable_poll_interval => (is => 'ro', isa => 'Int', default => '60');



=item max_unavailable_fails

The maximum number of consecutive fails when requesting an open proxy with status "available", before giving up (and dying with an error)

=cut

has max_unavailable_fails => (is => 'ro', isa => 'Int', default => '30');



=item max_threads

The maximum number of concurrent threads to employ when testing proxies

=cut

has max_threads => (is => 'ro', isa => 'Int', default => '10');



=item clean_dud_proxies_after

The time interval (in days) to wait before deleting 'dud' proxies from the database. ie after this time period, if the proxy is encountered again on a list, it will be tested again

=back

=cut

has clean_dud_proxies_after => (is => 'ro', isa=> 'Int', default => '28');

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
