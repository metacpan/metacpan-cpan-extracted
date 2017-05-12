package Nagios::Status::ServiceStatus;

use strict;
use Carp;
use Nagios::Status::Service;

=head1 NAME

Nagios::Status::ServiceStatus - Nagios 3.0 Class to maintain Services' Status.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    # Import the Module
    use Nagios::Status::ServiceStatus

    # Instantiate the ServiceStatus Object
    my $status = Nagios::Status::ServiceStatus->new($nagios_status_log_path);
        # OR
    my $status = Nagios::Status::ServiceStatus->new($nagios_status_log_path, $serv1, $serv2, ...);

    # Get services that are up.
    my $ok = $status->check_ok;

    # Get services that are down.
    my $warning = $status->check_warning;

    # Get services that are unreachable.
    my $unknown = $status->check_unknown;

    # Get services that are critical.
    my $critical = $status->check_critical;

=head1 DESCRIPTION

This module is an object oriented approach to Nagios 3.0 status services.

=head1 OBJECT CREATION METHOD

=over 4

=item new

 my $status = Nagios::Status::ServiceStatus->new($nagios_status_log_path [, $serv1 .. $servN]);

This class constructs a C<Nagios::Status::ServiceStatus> object. It requires one parameter. A file
path containing the path to the Nagios status.log file. There is an optional parameter. An array
of host names can be specified, whereby only those domains will be populated.

=back

=cut

sub new {
    my $class = shift;

    my $self = {
        status_log => shift,
    };

    $self->{ok} = ();
    $self->{warning} = ();
    $self->{unknown} = ();
    $self->{critical} = ();

    bless $self, $class;

    my (@services) = @_;

    if (@services) {
        $self->_populate_services(\@services);
    } else {
        $self->_populate_all;
    } # if/else

    return $self;
} # new

sub _populate_services {
    my ($self, $services) = @_;

    foreach (@$services) {
        my $service = Nagios::Status::Service->new($self->{status_log}, $_);

        if (defined $service) {
            if ($service->is_warning) {
                push @{ $self->{warning} }, $service;
            } elsif ($service->is_unknown) {
                push @{ $self->{unknown} }, $service;
            } elsif ($service->is_critical) {
                push @{ $self->{critical} }, $service;
            } else {
                push @{ $self->{ok} }, $service;
            } # if/elsif/else
        } else {
            $Nagios::Status::ServiceStatus::errstr = "Service not found: $_";
        } # if/else
    } # foreach

    return;
} # _populate_services

sub _populate_all {
    my ($self) = @_;

    open(STATUS, $self->{status_log}) or croak "Could not open Nagios status log: $!";

    my $found = 0;
    my $service = Nagios::Status::Service->new($self->{status_log});

    while(my $line = <STATUS>) {
        if ($line =~ /^servicestatus\s*{/) {
            $found = 1;
            next;
        } # if

        if ($found and $line =~ /}/) {
            if ($service->is_warning) {
                push @{ $self->{warning} }, $service;
            } elsif ($service->is_unknown) {
                push @{ $self->{unknown} }, $service;
            } elsif ($service->is_critical) {
                push @{ $self->{critical} }, $service;
            } else {
                push @{ $self->{ok} }, $service;
            } # if/elsif/else

            $service = Nagios::Status::Service->new($self->{status_log});
            $found = 0;
        } # if

        if (!$found) {
            next;
        } else {
            $service->set_attribute($line);
        } # if/else
    } # while

    close(STATUS);

    return;
} # _populate_all

=pod

=head1 METHODS

=over 4

=item check_ok

 my $servs_ok = $status->check_ok;

This method takes no parameters. It returns an array reference
to all services found to be OK. Otherwise, it returns undefined.

=cut

sub check_ok {
    my ($self) = @_;

    if ($self->{ok}) {
        return $self->{ok};
    } else {
        return undef;
    } # if/else
} # check_ok

=pod

=item check_warning

 my $servs_warning = $status->check_warning;

This method takes no parameters. It returns an array reference
to all services found to be WARNING. Otherwise, it returns undefined.

=cut

sub check_warning {
    my ($self) = @_;

    if ($self->{warning}) {
        return $self->{warning};
    } else {
        return undef;
    } # if/else
} # check_warning

=pod

=item check_unknown

 my $servs_unknown = $status->check_unknown;

This method takes no parameters. It returns an array reference
to all services found to be UNKNOWN. Otherwise, it returns undefined.

=cut

sub check_unknown {
    my ($self) = @_;

    if ($self->{unknown}) {
        return $self->{unknown};
    } else {
        return undef;
    } # if/else
} # check_unknown

=pod

=item check_critical

 my $servs_critical = $status->check_critical;

This method takes no parameters. It returns an array reference
to all services found to be CRITICAL. Otherwise, it returns undefined.

=back

=cut

sub check_critical {
    my ($self) = @_;

    if ($self->{critical}) {
        return $self->{critical};
    } else {
        return undef;
    } # if/else
} # check_critical

=head1 AUTHOR

Roy Crowder, C<< <rcrowder at cpan.org> >>

=head1 SEE ALSO

L<Nagios::Status::Service>,
L<perl>,
L<Changes>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nagios-status-servicestatus at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Status-ServiceStatus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nagios::Status::ServiceStatus


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nagios-Status-ServiceStatus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nagios-Status-ServiceStatus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nagios-Status-ServiceStatus>

=item * Search CPAN

L<http://search.cpan.org/dist/Nagios-Status-ServiceStatus/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 WorldSpice Technologies, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Nagios::Status::ServiceStatus
