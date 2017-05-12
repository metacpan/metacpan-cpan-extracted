package Nagios::Status::HostStatus;

use strict;
use Carp;
use Nagios::Status::Host;

=head1 NAME

Nagios::Status::HostStatus - Nagios 3.0 Class to maintain Hosts' Status.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    # Import the Module
    use Nagios::Status::HostStatus

    # Instantiate the HostStatus Object
    my $status = Nagios::Status::HostStatus->new($nagios_status_log_path);
        # OR
    my $status = Nagios::Status::HostStatus->new($nagios_status_log_path, $host1, $host2, ...);

    # Get hosts that are up.
    my $up = $status->check_up;

    # Get hosts that are down.
    my $down = $status->check_down;

    # Get hosts that are unreachable.
    my $unreach = $status->check_unreachable;

=head1 DESCRIPTION

This module is an object oriented approach to Nagios 3.0 status hosts.

=head1 OBJECT CREATION METHOD

=over 4

=item new

 my $status = Nagios::Status::HostStatus->new($nagios_status_log_path [, $host1 .. $hostN]);

This class constructs a C<Nagios::Status::HostStatus> object. It requires one parameter. A file
path containing the path to the Nagios status.log file. There is an optional parameter. An array
of host names can be specified, whereby only those domains will be populated.

=back

=cut

sub new {
    my $class = shift;

    my $self = {
        status_log => shift,
    };

    $self->{up} = ();
    $self->{down} = ();
    $self->{unreachable} = ();

    bless $self, $class;

    my (@hosts) = @_;

    if (@hosts) {
        $self->_populate_hosts(\@hosts);
    } else {
        $self->_populate_all;
    } # if/else

    return $self;
} # new

sub _populate_hosts {
    my ($self, $hosts) = @_;

    foreach (@$hosts) {
        my $host = Nagios::Status::Host->new($self->{status_log}, $_);

        if (defined $host) {
            if ($host->is_down) {
                push @{ $self->{down} }, $host;
            } elsif ($host->is_unreachable) {
                push @{ $self->{unreachable} }, $host;
            } else {
                push @{ $self->{up} }, $host;
            } # if/elsif/else
        } else {
            $Nagios::Status::HostStatus::errstr = "Host not found: $_";
        } # if/else
    } # foreach

    return;
} # _populate_hosts

sub _populate_all {
    my ($self) = @_;

    open(STATUS, $self->{status_log}) or croak "Could not open Nagios status log: $!";

    my $found = 0;
    my $host = Nagios::Status::Host->new($self->{status_log});

    while(my $line = <STATUS>) {
        if ($line =~ /^hoststatus\s*{/) {
            $found = 1;
            next;
        } # if

        if ($found and $line =~ /}/) {
            if ($host->is_down) {
                push @{ $self->{down} }, $host;
            } elsif ($host->is_unreachable) {
                push @{ $self->{unreachable} }, $host;
            } else {
                push @{ $self->{up} }, $host;
            } # if/elsif/else

            $host = Nagios::Status::Host->new($self->{status_log});
            $found = 0;
        } # if

        if (!$found) {
            next;
        } else {
            $host->set_attribute($line);
        } # if/else
    } # while

    close(STATUS);

    return;
} # _populate_all

=pod

=head1 METHODS

=over 4

=item check_up

 my $hosts_up = $status->check_up;

This method takes no parameters. It returns an array reference
to all hosts found to be UP. Otherwise, it returns undefined.

=cut

sub check_up {
    my ($self) = @_;

    if ($self->{up}) {
        return $self->{up};
    } else {
        return undef;
    } # if/else
} # check_up

=pod

=item check_down

 my $hosts_down = $status->check_down;

This method takes no parameters. It returns an array reference
to all hosts found to be DOWN. Otherwise, it returns undefined.

=cut

sub check_down {
    my ($self) = @_;

    if ($self->{down}) {
        return $self->{down};
    } else {
        return undef;
    } # if/else
} # check_down

=pod

=item check_unreachable

 my $hosts_unreach = $status->check_unreachable;

This method takes no parameters. It returns an array reference
to all hosts found to be UNREACHABLE. Otherwise, it returns undefined.

=back

=cut

sub check_unreachable {
    my ($self) = @_;

    if ($self->{unreachable}) {
        return $self->{unreachable};
    } else {
        return undef;
    } # if/else
} # check_unreachable

=head1 AUTHOR

Roy Crowder, C<< <rcrowder at cpan.org> >>

=head1 SEE ALSO

L<Nagios::Status::Host>,
L<perl>,
L<Changes>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nagios-status-hoststatus at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Status-HostStatus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nagios::Status::HostStatus


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nagios-Status-HostStatus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nagios-Status-HostStatus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nagios-Status-HostStatus>

=item * Search CPAN

L<http://search.cpan.org/dist/Nagios-Status-HostStatus/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 WorldSpice Technologies, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1; # End of Nagios::Status::HostStatus
