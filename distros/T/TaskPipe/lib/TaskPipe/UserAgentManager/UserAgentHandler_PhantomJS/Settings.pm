package TaskPipe::UserAgentManager::UserAgentHandler_PhantomJS::Settings;

use Moose;

=head1 NAME

TaskPipe::UserAgentManager::UserAgentHandler_PhantomJS::Settings

=head1 DESCRIPTION

Settings for the PhantomJS useragent handler

=head1 METHODS

=over

=item process_name

The name to call the PhantomJS process on the database

=cut

has process_name => (is => 'ro', isa => 'Str', default => 'phantomjs');


=item base_port

Allocate ports from this port number upwards

=cut

has base_port => (is => 'ro', isa => 'Int', default => 8910);


=item proxy_schemes

How to convert a proxy scheme (as used by LWP) to a proxy 'type' (as used by PhantomJS)

=cut

has proxy_schemes => (is => 'ro', isa => 'HashRef[Str]', default => sub{{
    socks => 'socks5',
    http => 'http',
    https => 'http'
}});

=item page_load_wait_time

PhantomJS does wait for the general page to load, but doesn't seem to wait for ajax requests to return. This can be problematic. A crude solution is to wait a fixed length of time upon page load. Set this option to do that. However, using the poll_for method is a preferable solution where possible. (See the docs for TaskPipe::Task_Scrape

=cut

has page_load_wait_time => (is => 'ro', isa => 'Int', default => 0);

=item poll_for_interval

When using C<poll_for>, this is the period between checking if the element is present (in milliseconds)

=cut

has poll_for_interval => (is => 'ro', isa => 'Int', default => 300);


=item poll_for_timeout

When using C<poll_for> this is the maximum length of time to poll for before giving up

=cut

has poll_for_timeout => (is => 'ro', isa => 'Int', default => 30000);


=item debug

If set to 1, messages from PhantomJS will be echoed to the terminal

=back

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

has debug => (is => 'ro', isa => 'Bool', default => 0);

__PACKAGE__->meta->make_immutable;
1;

