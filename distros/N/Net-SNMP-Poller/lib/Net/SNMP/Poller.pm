package Net::SNMP::Poller;

use 5.006;
use strict;
use warnings;
use Carp;
use Net::SNMP;

=head1 NAME

Net::SNMP::Poller - Simple poller for non-blocking SNMP queries

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

This module takes a hashref of hosts -> session / request info, performs SNMP
queries then returns the results.

    use Net::SNMP::Poller;

    # so far, logfile is the only supported option
    my $opts = {
        logfile => '/tmp/log',
    };

    my $obj = Net::SNMP::Poller->new( $opts ); # $opts is optional

    # data structure is hostname => key-value pairs of SNMP session / request
    # information.  You can specify any options that Net::SNMP::session() and
    # Net::SNMP::get_request() methods are supporting.  This module will perform
    # overrides appropriately.
    my $ref = {
        'localhost' => {
            version     => 1,
            community   => 'public',
            varbindlist => [ '.1.3.6.1.4.1.2021.11.50.0' ],
        },
    };

    my $data = $obj->run( $ref );
    
    # the content of $data would be the following:
    $data = {
          'localhost' => {
                           '.1.3.6.1.4.1.2021.11.50.0' => 414695
                         }
    };

=head1 SUBROUTINES/METHODS

=head2 new

    The constructor

=cut

sub new {
    my ( $class, $opts ) = @_;

    croak "opts passed in but not hashref" if ( $opts && ref( $opts ) ne 'HASH' );
    $opts = {} unless( $opts );
    
    my $self->{ opts } = $opts;
    bless $self, $class;
    $self->init();
    return $self;
}

=head2 init

    Validates args and initializes the object

=cut

sub init {
    my $self = shift;
    
    $self->{ session } = [ qw|
        hostname
        port
        localaddr
        localport
        nonblocking
        version
        domain
        timeout
        retries
        maxmsgsize
        translate
        debug
        community
        username
        authkey
        authpassword
        authprotocol
        privkey
        privpassword
        privprotocol
    | ];

    $self->{ request } = [ qw|
        callback
        delay
        contextengineid
        contextname
        varbindlist
    | ];
    
    if ( my $log = $self->{ opts }->{ logfile } ) {
        open( my $fh, ">", $log ) or croak "could not open $log: $!\n";
        $self->{ logfh } = $fh;
    }
}

=head2 run

    Performs non-blocking snmp queries and return a data structure

=cut

sub run {
    my ( $self, $ref ) = @_;
    croak "requires hashref of host data" unless ( $ref && ref( $ref ) eq 'HASH' );
    
    my $callback = sub {
        $self->callback(@_);
    };
    
    my $logfh = $self->{ logfh };
    
    for my $host ( keys %{ $ref } ) {
        my %session_opts;
        my @session = @{ $self->{ session } };
        for my $key ( @session ) {
            $session_opts{ $key } = $ref->{ $host }->{ $key }
                if ( defined $ref->{ $host }->{ $key } );
        }
        
        my ( $session, $error ) = Net::SNMP->session(
            hostname    => $host,
            nonblocking => 1,
            %session_opts,
        );

        if ( !defined $session ) {
            my $string = sprintf "ERROR: Failed to create session for host '%s': %s.\n", $host, $error;
            ( $logfh ) ? print $logfh $string : print $string;
            next;
        }
        
        my @request = @{ $self->{ request } };
        my %request_opts;
        for my $key ( @request ) {
            $request_opts{ $key } = $ref->{ $host }->{ $key }
                if ( defined $ref->{ $host }->{ $key } );
        }

        my $result = $session->get_request(
            callback => [$callback],
            %request_opts,
        );

        if ( !defined $result ) {
            my $string = sprintf "ERROR: Failed to queue get request for host '%s': %s.\n",
                $session->hostname(), $session->error();
            ( $logfh ) ? print $logfh $string : print $string;
        }
    }

    snmp_dispatcher();
    close( $logfh ) or croak "could not close log filehandle: $!" if ( $logfh );
    return $self->{ data };
}

=head2 callback

    Callback method for Net::SNMP to invoke.

=cut

sub callback {
    my ( $self, $session ) = @_;
    
    my $result = $session->var_bind_list();
    my $host = $session->hostname();
    my $logfh = $self->{ logfh };
    
    if ( !defined $result ) {
        my $string = sprintf "ERROR: Get request failed for host '%s': %s.\n", $host, $session->error();
        ( $logfh ) ? print $logfh $string : print $string;
        return;
    }

    $self->{ data }->{ $host } = $result;
}

=head1 AUTHOR

Satoshi Yagi, C<< <satoshi.yagi at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-snmp-poller at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SNMP-Poller>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SNMP::Poller


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SNMP-Poller>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SNMP-Poller>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SNMP-Poller>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SNMP-Poller/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Satoshi Yagi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Net::SNMP::Poller
