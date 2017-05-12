package Net::Magrathea;

use strict;
use warnings;
use Moose;
use Net::Telnet;
use namespace::autoclean;
use Carp qw/carp croak/;

our $VERSION = '0.03';

has 'username' => (
    isa      => 'Str',
    is       => 'rw',
    required => 1
);

has 'password' => (
    isa      => 'Str',
    is       => 'rw',
    required => 1
);

has 'authenticated' => (
    isa => 'Int',
    is  => 'rw'
);

has 'success' => (
    isa => 'Int',
    is  => 'rw'
);

has 'result' => (
    isa => 'Str',
    is  => 'rw'
);

has 'debug' => (
    isa => 'Int',
    is  => 'rw'
);

our $COMMANDS_AND_RESPONSES = {
    AUTH  => q{0 Magrathea NTS GW \(ntsapi.c\(V0.1\)\)},
    QUIT  => q{0 Many thanks. Goodbye},
    ALLO  => q{0\s+\d+\s+Allocated},
    ACTI  => q{0 Number activated OK},
    DEAC  => q{0 Number deactivated OK},
    REAC  => q{0 Number reactivated OK},
    STAT  => q{0\s+\d+\s+.*},
    SET   => q{0 Number updated OK},
    SPIN  => q{},
    FEAT  => q{},
    ORDE  => q{},
    ALTEN => q{},
    INFO  => q{0 Information updated},
};

sub _auth {
    my $self   = shift;
    my $ntsapi = Net::Telnet->new(
        Host            => 'www.magrathea-telecom.co.uk',
        Port            => '777',
        Telnetmode      => 0,
        Cmd_remove_mode => 1,
        Timeout         => 5,
        Errmode         => \&_telnet_error,
    );

    if ( defined $ntsapi->waitfor('/0 Magrathea NTS GW \(ntsapi.c\(V0.1\)\)/') )
    {
        $ntsapi->print("AUTH $self->{username} $self->{password}");
        print $ntsapi->lastline if $self->debug;
        $ntsapi->getline;

        if ( $ntsapi->getline =~ m{0 Access granted. Welcome \(cl=500\)} ) {
            print $ntsapi->lastline if $self->debug;
            $self->{_ntsapi} = $ntsapi;
            $self->authenticated(1);
            $self->success(1);
        }
        else {
            croak 'Error: ' . $ntsapi->lastline;
        }
    }
    else {
        carp "Connection error\n";
        $self->success(0);
        exit 1;
    }
}

sub _send_command {
    my $self    = shift;
    my $command = shift;
    my $number  = shift;

    $self->_auth if !$self->authenticated;
    $self->{_ntsapi}->print( "$command " . $number );

    if ( $self->{_ntsapi}->waitfor("/$COMMANDS_AND_RESPONSES->{$command}/") ) {
        print $self->{_ntsapi}->lastline if $self->debug;
        $self->result( $self->{_ntsapi}->lastline );
        $self->success(1);
        return $self;
    }
    else {
        print 'Error: ' . $self->{_ntsapi}->lastline . "\n";
        $self->success(0);
        exit 1;
    }
}

sub quit {
    my $self = shift;

    $self->{_ntsapi}->print('QUIT');
    $self->{_ntsapi}->getline;
    print $self->{_ntsapi}->getline if $self->debug;
    return;
}

sub allocate {
    my $self            = shift;
    my $number_to_alloc = shift;

    croak "No number supplied.\n" if !$number_to_alloc;

    $self->_auth if !$self->authenticated;
    $self->{_ntsapi}->print( 'ALLO ' . $number_to_alloc );

    if ( $self->{_ntsapi}->waitfor("/$COMMANDS_AND_RESPONSES->{ALLO}/") ) {
        print $self->{_ntsapi}->lastline if $self->debug;
        my ($number) = ( $self->{_ntsapi}->lastline =~ m{(\d\d+)} );
        $self->success(1);
        return $number;
    }
    else {
        print 'Error: ' . $self->{_ntsapi}->lastline . "\n";
        $self->success(0);
        exit 1;
    }
}

sub activate {
    my $self   = shift;
    my $number = shift;

    croak "No number supplied.\n" if !$number;
    return $self->_send_command( 'ACTI', $number );
}

sub deactivate {
    my $self   = shift;
    my $number = shift;

    croak "No number supplied.\n" if !$number;
    return $self->_send_command( 'DEAC', $number );
}

sub reactivate {
    my $self   = shift;
    my $number = shift;

    croak "No number supplied.\n" if !$number;
    return $self->_send_command( 'REAC', $number );
}

sub status {
    my $self   = shift;
    my $number = shift;

    croak "No number supplied.\n" if !$number;
    return $self->_send_command( 'STAT', $number );
}

sub set {
    my $self   = shift;
    my $number = shift;
    my $index  = shift;
    my $dest   = shift;

    $self->_auth if !$self->authenticated;
    $self->{_ntsapi}->print("SET $number $index $dest");

    if ( $self->{_ntsapi}->waitfor('/0 Number updated OK/') ) {
        print $self->{_ntsapi}->lastline if $self->debug;
        $self->success(1);
        return;
    }
    else {
        print "Cannot set $number to $index $dest: "
          . $self->{_ntsapi}->lastline . "\n";
        $self->success(0);
        exit 1;
    }
}

sub feature { confess 'Not supported yet.' }

sub secure_pin { confess 'Not supported yet.' }

sub time_of_day_route { confess 'Not supported yet.' }

sub allocate_ten { confess 'Not supported yet.' }

sub user_info {
    my $self   = shift;
    my $number = shift;
    my $text   = shift;

    $self->_auth if !$self->authenticated;
    $self->{_ntsapi}->print( 'INFO ' . $number . ' GEN ' . $text );

    if ( $self->{_ntsapi}->waitfor('/0 Information updated/') ) {
        print $self->{_ntsapi}->lastline if $self->debug;
        $self->success(1);
        return $self->{_ntsapi}->lastline;
    }
    else {
        print 'User info error: ' . $self->{_ntsapi}->lastline . "\n";
        $self->success(0);
        exit 1;
    }
}

sub ported_numbers { confess 'Not supported yet.' }

sub errormsg {
    my $self = shift;
    return $self->{_ntsapi}->getline;
}

sub _telnet_error {
    my $error = shift;
    return "Net::Telnet error: $error";
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Net::Magrathea - Perl interface to the Magrathea Telecom NTS API


=head1 VERSION

This document describes Net::Magrathea version 0.03


=head1 SYNOPSIS

    use strict;
    use warnings;
    use Net::Magrathea;
    
    my $ntsapi = Net::Magrathea->new(
        username => 'user',
        password => 'pass',
        debug    => 1,
    );
    
    my $index = 1;
    my $dest  = 'S:01224279484@sip.surevoip.co.uk';
    
    my $number = $ntsapi->allocate('01224______');
    
    $ntsapi->activate($number) if $ntsapi->success;
    
    $ntsapi->set( $number, $index, $dest ) if $ntsapi->success;
    
    $ntsapi->status($number) if $ntsapi->success;
    
    $ntsapi->user_info(
        $number, 'Suretec Systems Ltd., 24 Cormack Park,
        Rothienorman, Inverurie, AB51 8GL.'
    ) if $ntsapi->success;
    
    $ntsapi->deactivate($number) if $ntsapi->success;
    $ntsapi->quit;
  
  
=head1 DESCRIPTION

This module provides a Perl interface allowing you to connect 
to and operate the Magrathea Telecom 'Number Translation Service' API.



=head1 INTERFACE 

=head2 quit

Terminates the session. Should be called after the final command.

    $ntsapi->quit;

=head2 allocate

Attempt to allocate a phone number. The <number> can either be an entire
number, or may include underscores, to indicate any digit is acceptable.
This is the only command that accepts underscores as part of the <number>
parameter (now B<allocate_ten> also accepts underscores).

NOTE: This command does NOT reserve the number – you must issue an immediate
B<activate> command to ensure the number is allocated to your account and not 
available for allocation by others.

    $ntsapi->allocate('01224______');

Returns an allocated number.


=head2 activate

Activates a number obtained using the B<allocate> command. This command must
be used to finalise the reservation process.

    $ntsapi->allocate($number);

Result available via 

    my $message = $ntsapi->result;


=head2 deactivate

Deactivate the specified number. The number will no longer operate when
dialled.

The exact number must be entered; underscores are not permitted when using
this command.

NOTE: If you deactivate a number it becomes available for others to allocate, so
it cannot be guaranteed that you will be able to retrieve the number at a later
date

    $ntsapi->deactivate($number);

Result available via 

    my $message = $ntsapi->result;


=head2 reactivate

Reactivates a number that has previously been deactivated using the DEAC
command (if it has not since been allocated by someone else).

    $ntsapi->reactivate($number);

Result available via 

    my $message = $ntsapi->result;


=head2 status

Query the current status of the specified number. A successful reply contains
the information about the number’s current settings.

    $ntsapi->status($number);

Result available via 

    my $message = $ntsapi->result;

=head2 set

This command sets up destination for when the number is dialled.

    my $index = 1;
    my $dest  = 'S:01224279484@sip.surevoip.co.uk';

    $ntsapi->set( $number, $index, $dest ) if $ntsapi->success;

See the full NTS API docs for complete information (more than two pages).

=head2 user_info

This command has been added to enable storage of information about the user
of the number.

    $ntsapi->user_info(
        $number, 'Suretec Systems Ltd., 24 Cormack Park, Rothienorman, 
                  Inverurie, AB51 8GL.'
        if $ntsapi->success;

=head2 feature

The FEAT command can be used to check, enable or disable a particular
feature for an account.

NOTE: Not supported yet.


=head2 secure_pin

Set a PIN for the number.

NOTE: Not supported yet.


=head2 time_of_day_route

This command sets the destination usage by time of day, allowing (for
advanced NTS only) multiple targets to be setup and configuration when each
target is active.

NOTE: Not supported yet.


=head2 allocate_ten

This command has been provided to help locate ranges of ten numbers that are
available for allocation. The syntax of the <number> parameter is identical to
that of ALLO and the system will attempt to find a range of ten numbers (0
through to 9) that matches the passed <number> format.

NOTE: Not supported yet.


=head2 ported_numbers
 
NOTE: Not supported yet.
 
Control numbers that have been ported to Magrathea, if
your NTSAPI account has been given permission to do so.


=head2 errormsg

Retrieve the last message from the NTS API
 

=head1 DIAGNOSTICS

The last message from the Magrathea session can be retrieved via 
    
    print $ntsapi->errormsg

If you have set $ntsapi->debug(1) the session messages will be printed via
B<print>


=head1 CONFIGURATION AND ENVIRONMENT

Net::Magrathea requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Moose>

L<Net::Telnet>

L<namespace::autoclean>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-magrathea@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Gavin Henry  C<< <ghenry@suretecsystems.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) 2009, Suretec Systems Ltd. <http://www.suretecsystems.com>

Copyright (c) 2009, Gavin Henry <ghenry@suretecsystems.com>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
