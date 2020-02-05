package Net::SecurityCenter;

use warnings;
use strict;

use Net::SecurityCenter::REST;
use Net::SecurityCenter::Error;

require Net::SecurityCenter::API::Analysis;
require Net::SecurityCenter::API::Credential;
require Net::SecurityCenter::API::Feed;
require Net::SecurityCenter::API::File;
require Net::SecurityCenter::API::Plugin;
require Net::SecurityCenter::API::PluginFamily;
require Net::SecurityCenter::API::Policy;
require Net::SecurityCenter::API::Report;
require Net::SecurityCenter::API::Repository;
require Net::SecurityCenter::API::Scan;
require Net::SecurityCenter::API::ScanResult;
require Net::SecurityCenter::API::Scanner;
require Net::SecurityCenter::API::System;
require Net::SecurityCenter::API::User;
require Net::SecurityCenter::API::Zone;

our $VERSION = '0.205';

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
    };

    bless $self, $class;

    $self->{'analysis'}      = Net::SecurityCenter::API::Analysis->new($client);
    $self->{'credential'}    = Net::SecurityCenter::API::Credential->new($client);
    $self->{'feed'}          = Net::SecurityCenter::API::Feed->new($client);
    $self->{'file'}          = Net::SecurityCenter::API::File->new($client);
    $self->{'plugin'}        = Net::SecurityCenter::API::Plugin->new($client);
    $self->{'plugin_family'} = Net::SecurityCenter::API::PluginFamily->new($client);
    $self->{'policy'}        = Net::SecurityCenter::API::Policy->new($client);
    $self->{'report'}        = Net::SecurityCenter::API::Report->new($client);
    $self->{'repository'}    = Net::SecurityCenter::API::Repository->new($client);
    $self->{'scan'}          = Net::SecurityCenter::API::Scan->new($client);
    $self->{'scan_result'}   = Net::SecurityCenter::API::ScanResult->new($client);
    $self->{'scanner'}       = Net::SecurityCenter::API::Scanner->new($client);
    $self->{'system'}        = Net::SecurityCenter::API::System->new($client);
    $self->{'user'}          = Net::SecurityCenter::API::User->new($client);
    $self->{'zone'}          = Net::SecurityCenter::API::Zone->new($client);

    return $self;

}

#-------------------------------------------------------------------------------
# COMMON METHODS
#-------------------------------------------------------------------------------

sub client {

    my ($self) = @_;
    return $self->{'client'};

}

#-------------------------------------------------------------------------------

sub error {

    my ( $self, $message, $code ) = @_;

    if ( defined $message ) {
        $self->{'client'}->{'_error'} = Net::SecurityCenter::Error->new( $message, $code );
        return;
    } else {
        return $self->{'client'}->{'_error'};
    }

}

#-------------------------------------------------------------------------------

sub login {

    my ( $self, $username, $password ) = @_;

    ( @_ == 3 ) or croak(q/Usage: $sc->login(USERNAME, PASSWORD)/);

    $self->client->login( $username, $password ) or return;
    return 1;

}

#-------------------------------------------------------------------------------

sub logout {

    my ($self) = @_;
    $self->client->logout() or return;
    return 1;

}

#-------------------------------------------------------------------------------
# HELPER METHODS
#-------------------------------------------------------------------------------

sub analysis {

    my ($self) = @_;
    return $self->{'analysis'};

}

#-------------------------------------------------------------------------------

sub credential {

    my ($self) = @_;
    return $self->{'credential'};

}

#-------------------------------------------------------------------------------

sub feed {

    my ($self) = @_;
    return $self->{'feed'};

}

#-------------------------------------------------------------------------------

sub file {

    my ($self) = @_;
    return $self->{'file'};

}

#-------------------------------------------------------------------------------

sub plugin {

    my ($self) = @_;
    return $self->{'plugin'};

}

#-------------------------------------------------------------------------------

sub plugin_family {

    my ($self) = @_;
    return $self->{'plugin_family'};

}

#-------------------------------------------------------------------------------

sub policy {

    my ($self) = @_;
    return $self->{'policy'};

}

#-------------------------------------------------------------------------------

sub report {

    my ($self) = @_;
    return $self->{'report'};

}

#-------------------------------------------------------------------------------

sub repository {

    my ($self) = @_;
    return $self->{'repository'};

}

#-------------------------------------------------------------------------------

sub scan {

    my ($self) = @_;
    return $self->{'scan'};

}

#-------------------------------------------------------------------------------

sub scan_result {

    my ($self) = @_;
    return $self->{'scan_result'};

}

#-------------------------------------------------------------------------------

sub scanner {

    my ($self) = @_;
    return $self->{'scanner'};

}

#-------------------------------------------------------------------------------

sub system {

    my ($self) = @_;
    return $self->{'system'};

}

#-------------------------------------------------------------------------------

sub user {

    my ($self) = @_;
    return $self->{'user'};

}

#-------------------------------------------------------------------------------

sub zone {

    my ($self) = @_;
    return $self->{'zone'};

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

    $sc->login('secman', 'password');

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

=item * C<timeout> : Request timeout in seconds (default is C<180> seconds).
If a socket open, read or write takes longer than the timeout, an exception is thrown.

=item * C<ssl_options> : A hashref of C<SSL_*> options to pass through to L<IO::Socket::SSL>.

=item * C<logger> : A logger instance (eg. L<Log::Log4perl> or L<Log::Any> for log
the REST request and response messages.

=item * C<no_check> : Disable the check of SecurityCenter instance.

=back


=head1 COMMON METHODS

=head2 $sc->client ()

Return the instance of L<Net::SecurityCenter::REST> class

=head2 $sc->login ( $username, $password )

Login into SecurityCenter.

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

This software is copyright (c) 2018-2019 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
