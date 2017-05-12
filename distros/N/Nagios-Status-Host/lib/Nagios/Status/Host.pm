package Nagios::Status::Host;

use strict;
use Carp;

=head1 NAME

Nagios::Status::Host - Nagios 3.0 Container Class for Status Hosts.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    # Import Module
    use Nagios::Status::Host;

    # Instantiate the Host object.
    my $host = Nagios::Status::Host->new($nagios_status_log_path);
        # OR
    my $host = Nagios::Status::Host->new($nagios_status_log_path, $host_name);

    # You can set single attributes.
    $host->set_attribute('hostname=testserver');

    # You can get single attributes.
    my $attr = $host->get_attribute('host_name');
        # OR
    my $attr = $host->get_attribute('all');

    # Check if host is down, unreachable, or up.
    if ($host->is_down) {
        print 'Host is down...';
    } elsif ($host->is_unreachable) {
        print 'Host is unreachable...';
    } else {
        print 'Host is up...';
    }

    # Simple method for obtaining hostname
    my $name = $host->get_hostname;

    # Get downtime
    my $downtime = $host->get_downtime if $host->is_down;

    # Get unreachable time
    my $unreach_time = $host->get_unreachable_time if $host->is_unreachable;

=head1 DESCRIPTION

This module is an object oriented approach to Nagios 3.0 status hosts.

=head1 OBJECT CREATION METHOD

=over 4

=item new

 my $host = Nagios::Status::Host->new($nagios_status_log_path [, $host_name]);

This class constructs a C<Nagios::Status::Host> object. It requires one parameter. A file
path containing the path to the Nagios status.log file. There is one optional parameter. A
hostname can be specified to populate the host object. If no hostname is specified, subroutines
must be used to populate the host.

=back

=cut

sub new {
    my $class = shift;

    my $self = {
        status_log => shift,
    };

    bless $self, $class;

    my ($host) = @_;

    $self->_populate($host) if defined $host;

    return $self;
} # new

=pod

=head1 METHODS

=over 4

=item set_attribute

 print 'Attribute added...' if $host->set_attribute('host_name=testserver');

This method takes one required parameter, a string (attribute=value). Returns
TRUE if attribute was added successfully otherwise returns undefined.

=cut

sub set_attribute {
    my ($self, $attr) = @_;

    if (!defined $attr) {
        return undef;
    } # if

    my @attributes = split(/=/, $attr);

    chomp($attributes[1]);
    $attributes[0] =~ s/^\s*(.+)/$1/;

    $self->{attributes}->{$attributes[0]} = $attributes[1];

    return 1;
}

=pod

=item get_attribute

 my $attr = $host->get_attribute($attribute);

This method takes one required parameter, an attribute or 'all'. If 'all'
is specified, a hash reference of attributes(keys) and values is returned.
If an attribute is specified and is found, the value is returned. Otherwise,
undefined is returned.

=cut

sub get_attribute {
    my ($self, $attr) = @_;

    if ($attr eq 'all') {
        return $self->{attributes};
    } else {
        if (exists $self->{attributes}->{$attr}) {
            return $self->{attributes}->{$attr};
        } else {
            return undef;
        } # if/else
    } # if/else
} # get_attributes

=pod

=item is_down

 print 'Host down...' if $host->is_down;

This method take no parameters. Returns TRUE if host
is down. Otherwise, returns FALSE.

=cut

sub is_down {
    my ($self) = @_;

    if ($self->{attributes}->{last_time_up} < $self->{attributes}->{last_time_down}) {
        return 1;
    } else {
        return 0;
    } # if/else
} # is_down

=pod

=item is_unreachable

 print 'Host unreachable...' if $host->is_unreachable;

This method take no parameters. Returns TRUE if host
is unreachable. Otherwise, returns FALSE.

=cut

sub is_unreachable {
    my ($self) = @_;

    if ($self->{attributes}->{last_time_up} < $self->{attributes}->{last_time_unreachable}) {
        return 1;
    } else {
        return 0;
    } # if/else
} # is_unreachable

=pod

=item get_hostname

 my $name = $host->get_hostname;

This method takes no parameters. Returns hostname of
host.

=cut

sub get_hostname {
    my ($self) = @_;

    return $self->{attributes}->{host_name};
} # get_hostname

=pod

=item get_downtime

 my $downtime = $host->get_downtime;

This method takes no parameters. Returns downtime in seconds
if host is down. Otherwise, returns 0 seconds;

=cut

sub get_downtime {
    my ($self) = @_;

    if ($self->is_down) {
        my $cur_time = time;
        my $time = $cur_time - $self->{attributes}->{last_state_change};
        return $time;
    } else {
        return 0;
    } # if/else
} # get_downtime

=pod

=item get_unreachable_time

 my $utime = $host->get_unreachable_time;

This method takes no parameters. Returns unreachable time in seconds
if host is unreachable. Otherwise, returns 0 seconds.

=cut

sub get_unreachable_time {
    my ($self) = @_;

    if ($self->is_unreachable) {
        my $cur_time = time;
        my $time = $cur_time - $self->{attributes}->{last_state_change};
        return $time;
    } else {
        return 0;
    } # if/else
} # get_unreachable_time 

=pod

=back

=cut

sub _populate {
    my ($self, $host) = @_;

    my %attributes;
    my $found = 0;
    my $found_host = 0;

    open(STATUS, $self->{status_log}) or croak "Cannot open status log file: $!";

    while(my $line = <STATUS>) {
        if ($line =~ /^hoststatus\s*{/) {
            $found = 1;
            next;
        } # if

        if ($found and $line =~ /$host/) {
            $found_host = 1;
        }

        if ($found and $line =~ /}/) {
            if ($found_host) {
                foreach (keys %attributes) {
                    $self->{attributes}->{$_} = $attributes{$_};
                } # foreach

                last;
            } else {
                %attributes = ();
                $found = 0;
            } # if/else
        } # if

        if (!$found) {
            next;
        } else {
            my @attr = split(/=/, $line);

            chomp($attr[1]);
            $attr[0] =~ s/^\s*(.+)/$1/;
            $attributes{$attr[0]} = $attr[1];
        } # if/else
    } # while

    close(STATUS);
} # _populate

=head1 AUTHOR

Roy Crowder, C<< <rcrowder at cpan.org> >>

=head1 SEE ALSO

L<perl>,
L<Changes>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nagios-status-host at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Status-Host>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nagios::Status::Host


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nagios-Status-Host>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nagios-Status-Host>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nagios-Status-Host>

=item * Search CPAN

L<http://search.cpan.org/dist/Nagios-Status-Host/>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 WorldSpice Technologies, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Nagios::Status::Host
