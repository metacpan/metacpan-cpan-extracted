package Net::SecurityCenter;

use warnings;
use strict;

use parent 'Net::SecurityCenter::Base';

use Net::SecurityCenter::REST;

our $VERSION = '0.310';

my @api = qw(
    analysis
    credential
    device_info
    feed
    file
    notification
    plugin
    plugin_family
    policy
    report
    repository
    scan
    scan_result
    scanner
    status
    system
    ticket
    user
    zone
);

#-------------------------------------------------------------------------------
# CONSTRUCTOR
#-------------------------------------------------------------------------------

sub new {

    my ( $class, $host, $options ) = @_;

    my $client = Net::SecurityCenter::REST->new( $host, $options ) or return;

    my $self = {
        host    => $host,
        options => $options,
        client  => $client,
        api     => {}
    };

    bless $self, $class;

    foreach my $method (@api) {
        my $api_class = 'Net::SecurityCenter::API::' . join '', map {ucfirst} split /_/, $method;
        eval "require $api_class";    ## no critic
        $self->{api}->{$method} = $api_class->new($client);
    }

    return $self;

}

#-------------------------------------------------------------------------------
# COMMON METHODS
#-------------------------------------------------------------------------------

sub login {

    my ( $self, %args ) = @_;

    $self->client->login(%args) or return;
    return 1;

}

#-------------------------------------------------------------------------------

sub logout {

    my ($self) = @_;
    $self->client->logout or return;
    return 1;

}

#-------------------------------------------------------------------------------
# HELPER METHODS
#-------------------------------------------------------------------------------

foreach my $method (@api) {

    no strict 'refs';    ## no critic

    *{$method} = sub {
        my ($self) = @_;
        return $self->{api}->{$method};
    };

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter - Perl interface to Tenable.sc (SecurityCenter) REST API


=head1 SYNOPSIS

    use Net::SecurityCenter;

    my $sc = Net::SecurityCenter('sc.example.org');

    if (! $sc->login(username => 'secman', password => 's3cr3t')) {
        die $sc->error;
    }

    my $running_scans = $sc->scan_result->list_running;

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter->new ( host [, $params ] )

Create a new instance of B<Net::Security::Center> using L<Net::SecurityCenter::REST> class.

Params:

=over 4

=item * C<timeout> : Request timeout in seconds (default is 180) If a socket open,
read or write takes longer than the timeout, an exception is thrown.

=item * C<ssl_options> : A hashref of C<SSL_*> options to pass through to L<IO::Socket::SSL>.

=item * C<logger> : A logger instance (eg. L<Log::Log4perl>, L<Log::Any> or L<Mojo::Log>)
for log the REST request and response messages.

=item * C<scheme> : URI scheme (default: HTTPS).

=back


=head1 COMMON METHODS

=head2 $sc->client ()

Return the instance of L<Net::SecurityCenter::REST> class

=head2 $sc->login ( ... )

Login into SecurityCenter.

See "Username and password authetication" and "API Key authentication" in L<Net::SecurityCenter::REST>.

=head2 $sc->logout

Logout from SecurityCenter.


=head1 HELPER METHODS

=head2 analysis

Return L<Net::SecurityCenter::API::Analysis> instance.

=head2 credential

Return L<Net::SecurityCenter::API::Credential> instance.

=head2 feed

Return L<Net::SecurityCenter::API::Feed> instance.

=head2 file

Return L<Net::SecurityCenter::API::File> instance.

=head2 notification

Return L<Net::SecurityCenter::API::Notification> instance.

=head2 plugin

Return L<Net::SecurityCenter::API::Plugin> instance.

=head2 plugin_family

Return L<Net::SecurityCenter::API::PluginFamily> instance.

=head2 policy

Return L<Net::SecurityCenter::API::Policy> instance.

=head2 report

Return L<Net::SecurityCenter::API::Report> instance.

=head2 repository

Return L<Net::SecurityCenter::API::Repository> instance.

=head2 scan

Return L<Net::SecurityCenter::API::Scan> instance.

=head2 scan_result

Return L<Net::SecurityCenter::API::ScanResult> instance.

=head2 scanner

Return L<Net::SecurityCenter::API::Scanner> instance.

=head2 status

Return L<Net::SecurityCenter::API::Status> instance.

=head2 system

Return L<Net::SecurityCenter::API::System> instance.

=head2 user

Return L<Net::SecurityCenter::API::User> instance.

=head2 zone

Return L<Net::SecurityCenter::API::Zone> instance.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-SecurityCenter>

    git clone https://github.com/giterlizzi/perl-Net-SecurityCenter.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018-2021 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
