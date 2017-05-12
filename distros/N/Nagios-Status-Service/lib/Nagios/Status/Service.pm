package Nagios::Status::Service;

use strict;
use Carp;

=head1 NAME

Nagios::Status::Service - Nagios 3.0 Container Class for Status Services.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    # Import Module
    use Nagios::Status::Service;

    # Instantiate the Service object.
    my $serv = Nagios::Status::Service->new($nagios_status_log_path);
        # OR
    my $serv = Nagios::Status::Service->new($nagios_status_log_path, $host_name);

    # You can set single attributes.
    $serv->set_attribute('hostname=testserver');

    # You can get single attributes.
    my $attr = $serv->get_attribute('host_name');
        # OR
    my $attr = $serv->get_attribute('all');

    # Check if service is warning, unknown, critical, or up.
    if ($serv->is_warning) {
        print 'Service is warning...';
    } elsif ($serv->is_unknown) {
        print 'Service is unknown...';
    } elsif ($serv->is_critical) {
        print 'Service is critical...';
    } else {
        print 'Service is up...';
    }

    # Simple method for obtaining hostname
    my $name = $serv->get_hostname;

    # Get warning time
    my $warning_time = $serv->get_warning_time if $serv->is_warning;

    # Get unknown time
    my $unknown_time = $serv->get_unknown_time if $serv->is_unknown;

    # Get critical time
    my $critical_time = $serv->get_critical_time if $serv->is_critical;

=head1 DESCRIPTION

This module is an object oriented approach to Nagios 3.0 status services.

=head1 OBJECT CREATION METHOD

=over 4

=item new

 my $serv = Nagios::Status::Service->new($nagios_status_log_path [, $host_name]);

This class constructs a C<Nagios::Status::Service> object. It requires one parameter. A file
path containing the path to the Nagios status.log file. There is one optional parameter. A
hostname can be specified to populate the service object. If no hostname is specified, subroutines
must be used to populate the service.

=back

=cut

sub new {
    my $class = shift;

    my $self = {
        status_log => shift,
    };

    bless $self, $class;

    my ($serv) = @_;

    $self->_populate($serv) if defined $serv;

    return $self;
} # new

=pod

=head1 METHODS

=over 4

=item set_attribute

 print 'Attribute added...' if $serv->set_attribute('host_name=testserver');

This method takes one required parameter, a string (attribute=value). Returns
TRUE if attribute was added successfully otherwise returns undefined.

=cut

sub set_attribute {
    my ($self, $attr) = @_;

    if (!defined $attr) {
        return;
    } # if

    # This was a patch written by Jeremy Krieg to handle a bug not reading '='
    # signs in service status descriptions. Thanks to Jeremy for the patch!
    if ( $attr =~ /^\s*([^=]+)=(.*?\S)\s*$/ ) {
        $self->{attributes}->{$1} = $2;
        return 1;
    }

    return;
}

=pod

=item get_attribute

 my $attr = $serv->get_attribute($attribute);

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
            return;
        } # if/else
    } # if/else
} # get_attributes

=pod

=item is_warning

 print 'Service is warning...' if $serv->is_warning;

This method take no parameters. Returns TRUE if service
is warning. Otherwise, returns FALSE.

=cut

sub is_warning {
    my ($self) = @_;

    if ($self->{attributes}->{last_time_ok} < $self->{attributes}->{last_time_warning}) {
        return 1;
    } else {
        return 0;
    } # if/else
} # is_warning

=pod

=item is_unknown

 print 'Service unknown...' if $serv->is_unknown;

This method take no parameters. Returns TRUE if service
is unknown. Otherwise, returns FALSE.

=cut

sub is_unknown {
    my ($self) = @_;

    if ($self->{attributes}->{last_time_ok} < $self->{attributes}->{last_time_unknown}) {
        return 1;
    } else {
        return 0;
    } # if/else
} # is_unknown

=pod

=item is_critical

 print 'Service critical...' if $serv->is_critical;

This method take no parameters. Returns TRUE if service
is critical. Otherwise, returns FALSE.

=cut

sub is_critical {
    my ($self) = @_;

    if ($self->{attributes}->{last_time_ok} < $self->{attributes}->{last_time_critical}) {
        return 1;
    } else {
        return 0;
    } # if/else
} # is_critical

=pod

=item get_hostname

 my $name = $serv->get_hostname;

This method takes no parameters. Returns hostname of
service.

=cut

sub get_hostname {
    my ($self) = @_;

    return $self->{attributes}->{host_name};
} # get_hostname

=pod

=item get_warning_time

 my $warning_time = $serv->get_warning_time;

This method takes no parameters. Returns warning time in seconds
if service is warning. Otherwise, returns 0 seconds;

=cut

sub get_warning_time {
    my ($self) = @_;

    if ($self->is_warning) {
        my $cur_time = time;
        my $time = $cur_time - $self->{attributes}->{last_state_change};
        return $time;
    } else {
        return 0;
    } # if/else
} # get_warning_time

=pod

=item get_unknown_time

 my $utime = $serv->get_unknown_time;

This method takes no parameters. Returns unknown time in seconds
if service is unknown. Otherwise, returns 0 seconds.

=cut

sub get_unknown_time {
    my ($self) = @_;

    if ($self->is_unknown) {
        my $cur_time = time;
        my $time = $cur_time - $self->{attributes}->{last_state_change};
        return $time;
    } else {
        return 0;
    } # if/else
} # get_unknown_time 

=pod

=item get_critical_time

 my $ctime = $serv->get_critical_time;

This method takes no parameters. Returns critical time in seconds
if service is critical. Otherwise, returns 0 seconds.

=cut

sub get_critical_time {
    my ($self) = @_;

    if ($self->is_critical) {
        my $cur_time = time;
        my $time = $cur_time - $self->{attributes}->{last_state_change};
        return $time;
    } else {
        return 0;
    } # if/else
} # get_critical_time

=pod

=back

=cut

sub _populate {
    my ($self, $serv) = @_;

    my %attributes;
    my $found = 0;
    my $found_serv = 0;

    open(STATUS, $self->{status_log}) or croak "Cannot open status log file: $!";

    while(my $line = <STATUS>) {
        if ($line =~ /^servicestatus\s*{/) {
            $found = 1;
            next;
        } # if

        if ($found and $line =~ /$serv/) {
            $found_serv = 1;
        }

        if ($found and $line =~ /}/) {
            if ($found_serv) {
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
            # Pointed out by Jeremy Krieg, there was duplicate code
            # here. Thanks!
            $self->set_attribute($line);
        } # if/else
    } # while

    close(STATUS);
} # _populate

=head1 AUTHOR

Roy Crowder, C<< <rcrowder at cpan.org> >>

Thanks to Jeremy Krieg for patch on release 0.02.

=head1 SEE ALSO

L<perl>,
L<Changes>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nagios-status-service at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Status-Service>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nagios::Status::Service


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nagios-Status-Service>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nagios-Status-Service>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nagios-Status-Service>

=item * Search CPAN

L<http://search.cpan.org/dist/Nagios-Status-Service/>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 WorldSpice Technologies, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Nagios::Status::Service
