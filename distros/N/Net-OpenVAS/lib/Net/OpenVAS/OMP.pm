package Net::OpenVAS::OMP;

use strict;
use warnings;
use utf8;
use feature ':5.10';

use Carp;
use IO::Socket::SSL;
use XML::Simple qw( :strict );

use Net::OpenVAS::Error;
use Net::OpenVAS::OMP::Response;
use Net::OpenVAS::OMP::Request;

our $VERSION = '0.101';

sub import {

    my ( $class, @flags ) = @_;

    if ( grep( /^-commands$/, @_ ) ) {
        my @commands = qw(
            authenticate commands create_agent create_alert create_asset create_config
            create_credential create_filter create_group create_note create_override
            create_permission create_port_list create_port_range create_report
            create_report_format create_role create_scanner create_schedule create_tag
            create_target create_task create_user delete_agent delete_asset
            delete_config delete_alert delete_credential delete_filter delete_group
            delete_note delete_override delete_report delete_permission delete_port_list
            delete_port_range delete_report_format delete_role delete_scanner
            delete_schedule delete_tag delete_target delete_task delete_user
            describe_auth empty_trashcan get_agents get_configs get_aggregates
            get_alerts get_assets get_credentials get_feeds get_filters get_groups
            get_info get_notes get_nvts get_nvt_families get_overrides get_permissions
            get_port_lists get_preferences get_reports get_report_formats get_results
            get_roles get_scanners get_schedules get_settings get_system_reports
            get_tags get_targets get_tasks get_users get_version help modify_agent
            modify_alert modify_asset modify_auth modify_config modify_credential
            modify_filter modify_group modify_note modify_override modify_permission
            modify_port_list modify_report modify_report_format modify_role
            modify_scanner modify_schedule modify_setting modify_target modify_tag
            modify_task modify_user move_task restore resume_task run_wizard start_task
            stop_task sync_cert sync_feed sync_config sync_scap test_alert verify_agent
            verify_report_format verify_scanner
        );

        foreach my $command (@commands) {

            my $sub = sub {
                my ( $self, %hash ) = @_;
                return $self->command( $command, \%hash );
            };

            no strict 'refs';    ## no critic
            *{$command} = $sub;

        }
    }

}

sub new {

    my ( $class, %options ) = @_;

    my $openvas  = delete( $options{'host'} )        || undef;
    my $ssl_opts = delete( $options{'ssl_options'} ) || {};
    my $logger   = delete( $options{'logger'} )      || undef;
    my $timeout  = delete( $options{'timeout'} )     || 60;
    my $username = delete( $options{'username'} );
    my $password = delete( $options{'password'} );

    if ( !$openvas ) {
        $@ = 'Specify valid OpenVAS hostname or IP address and port (eg. 127.0.0.1:9330)';    ## no critic
        return;
    }

    if ( !$username || !$password ) {
        $@ = 'Specify OpenVAS username and password';                                         ## no critic
        return;
    }

    my ( $host, $port ) = split /:/, $openvas;

    $port ||= 9390;

    my $self = {
        host     => $host,
        port     => $port,
        options  => \%options,
        logger   => $logger,
        timeout  => $timeout,
        username => $username,
        password => $password,
        socket   => undef,
        error    => undef,
    };

    bless $self, $class;

    if ( !$self->_connect ) {
        $@ = $self->error;
        return;
    }

    return $self;

}

sub _connect {

    my ($self) = @_;

    my %ssl = (
        PeerHost        => $self->{'host'},
        PeerPort        => $self->{'port'},
        Timeout         => $self->{'timeout'},
        Proto           => 'tcp',
        SSL_verify_mode => 0,
    );

    my $socket = IO::Socket::SSL->new(%ssl)
        or croak( sprintf 'Unable to connect to OpenVAS via %s:%s (%s - %s)',
        $self->{'host'}, $self->{'port'}, $!, $SSL_ERROR );

    $self->{'socket'} = \*$socket;

    my $request = Net::OpenVAS::OMP::Request->new(
        command   => 'authenticate',
        arguments => {
            'credentials' => [
                {
                    'username' => [ $self->{'username'} ],
                    'password' => [ $self->{'password'} ]
                }
            ]
        }
    );

    $self->{'socket'}->syswrite( $request->raw );

    my $omp_response = $self->_read;
    my $response     = Net::OpenVAS::OMP::Response->new(
        request  => $request,
        response => $omp_response
    );

    if ( !$response->error ) {
        return 1;
    } else {
        $self->{'error'} = $response->error;
    }

    return;

}

sub _read {

    my ($self) = @_;

    my $response;

    while ( my $length = $self->{'socket'}->sysread( my $buffer, 1024 ) ) {
        $response .= $buffer;
        last if ( $length < 1024 || $length == 0 );
    }

    return $response;

}

sub _write {

    my ( $self, $data ) = @_;

    $self->_connect;

    $self->{'socket'}->syswrite($data);
    my $response = $self->_read;

    return $response;

}

sub command {

    my ( $self, $command, $arguments ) = @_;

    my $request = Net::OpenVAS::OMP::Request->new(
        command   => $command,
        arguments => $arguments
    );

    if ( defined( $self->{'logger'} ) ) {
        $self->{'logger'}->debug( $request->raw );
    }

    my $omp_response = $self->_write( $request->raw );

    if ( defined( $self->{'logger'} ) ) {
        $self->{'logger'}->debug($omp_response);
    }

    my $response = Net::OpenVAS::OMP::Response->new(
        request  => $request,
        response => $omp_response
    );

    if ( $response->error ) {
        $self->{'error'} = $response->error;
    }

    return $response;

}

sub error {

    my ( $self, $message, $code ) = @_;

    if ( defined $message ) {
        $self->{'error'} = Net::OpenVAS::Error->new( $message, $code );
    }

    return $self->{'error'};

}

1;

=head1 NAME

Net::OpenVAS - Perl extension for OpenVAS Scanner

=head1 SYNOPSIS

    use Net::OpenVAS qw( -commands );

    my $openvas = Net::OpenVAS->new(
        host     => 'localhost:9390',
        username => 'admin',
        password => 's3cr3t'
    ) or die "ERROR: $@";

    my $task = $openvas->create_task(
        name   => [ 'Scan created via Net::OpenVAS' ],
        target => { id => 'a800d5c7-3493-4f73-8401-c42e5f2bfc9c' },
        config => { id => 'daba56c8-73ec-11df-a475-002264764cea' }
    );

    if ( $task->is_created ) {

        my $task_id = $task->result->{id};

        say "Created task $task_id";

        my $task_start = $openvas->start_task( task_id => $task_id );

        say "Task $task_id started (" . $task_start->status_text . ')' if ( $task_start->is_accepted );

    }

    if ( $openvas->error ) {
        say "ERROR: " . $openvas->error;
    }

=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the OMP (OpenVAS Management Protocol) of OpenVAS.

For more information about the OPM follow the online documentation:

L<https://docs.greenbone.net/API/OMP/omp.html>


=head1 CONSTRUCTOR

=head2 Net::OpenVAS::OMP->new ( host => $host, username => $username, password => $password [, logger => $logger, timeout => 60, ssl_options => \%ssl_options ] )

Create a new instance of L<Net::Net::OpenVAS::OMP>.

Params:

=over 4

=item * C<host> : OpenVAS host (and port)

=item * C<username>, C<password> : OpenVAS Credentials

=item * C<timeout> : Request timeout in seconds (default is 60) If a socket open,
read or write takes longer than the timeout, an exception is thrown.

=item * C<ssl_options> : A hashref of C<SSL_*> options to pass through to L<IO::Socket::SSL>.

=item * C<logger> : A logger instance (eg. L<Log::Log4perl> or L<Log::Any> for log
the REST request and response messages.

=back


=head1 METHODS

=head2 $openvas->command ( $command [, \%arguments ] )

Execute a command to OpenVAS via OMP and return L<Net::OpenVAS::OMP::Result> class instance.

    my $task = $openvas->command( 'get_tasks', task_id => '46f15597-b721-403c-96a1-cce439af63a7' );

=head2 $openvas->error

Return L<Net::OpenVAS::Error> class instance.

=head2 COMMANDS HELPER

L<Net::OpenVAS::OMP> provide a flag (C<-commands>) for import all OpenVAS OMP commands.

    use Net::OpenVAS::OMP;
    [...]
    my $version = $openvas->command('get_version');

    use Net::OpenVAS::OMP qw( -commands );
    [...]
    my $version = $openvas->get_version;

Available commands:

    authenticate commands create_agent create_alert create_asset create_config
    create_credential create_filter create_group create_note create_override
    create_permission create_port_list create_port_range create_report
    create_report_format create_role create_scanner create_schedule create_tag
    create_target create_task create_user delete_agent delete_asset
    delete_config delete_alert delete_credential delete_filter delete_group
    delete_note delete_override delete_report delete_permission delete_port_list
    delete_port_range delete_report_format delete_role delete_scanner
    delete_schedule delete_tag delete_target delete_task delete_user
    describe_auth empty_trashcan get_agents get_configs get_aggregates
    get_alerts get_assets get_credentials get_feeds get_filters get_groups
    get_info get_notes get_nvts get_nvt_families get_overrides get_permissions
    get_port_lists get_preferences get_reports get_report_formats get_results
    get_roles get_scanners get_schedules get_settings get_system_reports
    get_tags get_targets get_tasks get_users get_version help modify_agent
    modify_alert modify_asset modify_auth modify_config modify_credential
    modify_filter modify_group modify_note modify_override modify_permission
    modify_port_list modify_report modify_report_format modify_role
    modify_scanner modify_schedule modify_setting modify_target modify_tag
    modify_task modify_user move_task restore resume_task run_wizard start_task
    stop_task sync_cert sync_feed sync_config sync_scap test_alert verify_agent
    verify_report_format verify_scanner

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-OpenVAS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-OpenVAS>

    git clone https://github.com/giterlizzi/perl-Net-OpenVAS.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
