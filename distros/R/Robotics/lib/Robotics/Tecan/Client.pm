package Robotics::Tecan::Client;

use warnings;
use strict;

use Moose;

has 'SOCKET' => ( isa => 'Maybe[IO::Socket]', is => 'rw' );
has 'SERVER' => ( isa => 'Str', is => 'rw', default => 0 );
has 'PORT' => ( isa => 'Int', is => 'rw', default => 0 );
has 'PASSWORD' => ( isa => 'Str|Undef', is => 'rw', default => 0 );
has 'attached' => ( is => 'rw', isa => 'Bool' );
has 'last_reply' => ( is => 'rw', isa => 'Str' );
has 'object' => ( is => 'ro', isa => 'Robotics::Tecan' );
has 'EXPECT_RECV' => ( is => 'rw', isa => 'Maybe[HashRef]' );

extends 'Robotics::Tecan', 'Robotics::Tecan::Genesis';

# This module is not meant for direct inclusion.
# Use it "with" Tecan::Genesis.

my $Debug = 1;
my $Simulate = 0;

=head1 NAME

Robotics::Tecan::Client - (Internal module)
Software-to-Software interface for Tecan Gemini, network client.
Application for controlling robotics hardware

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';

=head1 SYNOPSIS

Network client software interface support for Robotics::Tecan. 
This software can connect to a network server created with 
Robotics::Tecan::Server.

=head1 EXPORT
=cut

sub BUILD {
    my ($self, $params) = @_;
    
    use IO::Socket;
    if ($Simulate || $params->{simulate}) { 
        warn __PACKAGE__. " SIMULATING CONNECTION\n";
        return; 
    }
    if (!$params->{port}) { 
        die "Must specify port for server ". $params->{server}. "\n"; 
    }
    my $socket = IO::Socket::INET->new( Proto     => "tcp",
                     PeerAddr  => $params->{server},
                     PeerPort  => $params->{port})
         || die "cannot connect to $params->{server}:$params->{port}\n";
    $socket->autoflush(1);
    $self->SOCKET( $socket );
    $self->SERVER( $params->{server} );
    $self->PORT( $params->{port} );
    $self->PASSWORD( $params->{password} );
    $self->attached( 0 );
    my $reply = <$socket>;
    warn "CONNECTED $params->{server}:$params->{port}\n" if $Debug;
}

sub attach {
    my ($self, %params) = @_;
    
    if ($Simulate) { $self->attached( 1 ); return; }
        
    # Design Note: The attach() functions can not use the COMPILER() since
    # Compiler has not yet been allocated (by design).  Thus the machine commands
    # in attach() functions must be hand-coded as necessary. 
    
    my $socket = $self->SOCKET;
    warn "AUTHENTICATING\n";
    my $tries = 0;
    my $reply;
    if (!$self->PASSWORD()) {
    	die "Must supply server password\n";
    }
    while ($reply = <$socket>) { 
        print STDOUT $reply;
        if ($reply =~ /^login:/) { 
            print $socket $self->PASSWORD . "\n";
        }
        if ($reply =~ /Authentication OK/i) { 
            $tries = 0;
            last;
        }
        $tries++;
        if ($tries > 3) { last; }
    }
    $self->PASSWORD( undef );
    if ($tries) { 
        $self->detach();
        warn "can not authenticate to tecan network server\n";
        return 0;
    }
    warn "ATTACHED ". __PACKAGE__. "\n";
    $self->attached( 1 );
    # Probe for Genesis
    $self->object()->HWTYPE( "GENESIS" ); 
    $self->object()->HWNAME( "M1" );
    
    #$self->{VERSION} = $self->hw_get_version();
    $self->write("GET_VERSION");
    $self->object()->VERSION( $self->read() );
    print STDERR "\nVersion: ". $self->object()->VERSION(). "\n" if $Debug;
    $self->write("GET_RSP");
    $self->object()->HWTYPE( $self->read() );
    print STDERR "\nHardware: ". $self->object()->HWTYPE(). "\n" if $Debug;
    if (!($self->object()->HWTYPE() =~ /GENESIS/)) {
        $self->detach();
        warn "Robotics is not Genesis; reports '".
            $self->object()->HWTYPE(). "': closed network\n";
        return 0;
    }
    # Force client to only attach if Robot is IDLE
    $self->write("GET_STATUS");
    $self->object()->STATUS( $self->read() );
    print STDERR "\nStatus: ". $self->object()->STATUS(). "\n" if $Debug;
    if (!($self->object()->STATUS() =~ /IDLE/)) {
        warn "Robotics is not idle; reports '".
            $self->object()->STATUS(). "'\n";
        if ($params{option} =~ !/o/i) {
            $self->detach();
            warn "closed network\n";
            return 0;
        }
    }
    
    # XXX assign this via arg to new 
    # The HWALIAS and HWNAME should be set via hardware probe, user
    # discovers value from query
    $self->object()->HWALIAS( "genesis0" );
    $self->object()->HWNAME( "M1" );

    my $m = $self->object()->HWNAME();

    for my $addr ("M", "A", "P", "R") { 
        $self->write("COMMAND;". $addr. "1". "REE");
        $reply = $self->read();
        if ($reply =~ m/0;(.*)/) {
            my $status = $1;
            if (!$status) { 
                confess __PACKAGE__. " arm '$addr' status error!";
            }
            if ($status =~ m/[^@]/) { 
                warn __PACKAGE__. " arm '$addr' motor error!";
            }
        }
    }
    
    # Scan and get hardware device specifics
    # no. arms, diluters, options, posids, 
    # romas, uniports, options, voptions
    $self->write("COMMAND;A1RNT1");
    my $num_tips = $self->read();
    my @devices;
    if ($num_tips =~ m/0;(\d+)/) { 
        $num_tips = $1;
        for my $d (0 .. 7) { 
            $self->write("COMMAND;". $m."RSD".$d.",1");
            $reply = $self->read();
            if ($reply =~ m/0;(\d+)/) { 
                push(@devices, $1);
            }
            else { 
                push(@devices, 0);
            }
        }
    }
    else { 
        # technically speaking A1RNT1 num tips should
        # always equal the M1RSD num diluters (I assume)
        $num_tips = 0;
    }
    $self->object()->HWSPEC(
            "lihas=". $devices[0].
            ":diluters=". $devices[1].
            ":options=". $devices[2].
            ":posids=". $devices[3].
            ":romas=". $devices[4].
            ":uniports=". $devices[5].
            ":optionst=". $devices[6].
            ":optionsv=". $devices[7]         
            );
    print STDERR "\nHW Spec: ". $self->object()->HWSPEC(). "\n" if $Debug;
    # Get firmware revision of LIHA devices (syringe pumps)
    my $maxdev;
    my @dev_versions;
    for my $d (1 .. $num_tips) { 
        $self->write("COMMAND;D". $d. "Q23");
        my $reply = $self->read();
        if ($reply =~ /^0;(.*)/) { 
            # found
            push(@dev_versions, "D". $d. "=". $1);

            $maxdev = $d;
        }
    }
    $self->object()->HWDEVICES( join(":", @dev_versions) );
    print STDERR "\nHW Liquid Devices: ". $self->object()->HWDEVICES(). "\n"
            if $Debug;
    $self->object()->TIP_MAX( $maxdev );
}


sub read {
    my $self = shift;
    my $data;
    if ($Simulate) { 
        print STDOUT "[waiting for data] :";
        local $_ = <STDIN>; s/[\r\n\t\s]*//g; return $_; 
    }
    
    my $socket = $self->{SOCKET};
    # OS/X perl 5.8.8 returns $data=undef if socket closed by server
    # cygwin-perl 5.10 returns $data="" if socket closed by server
    while ($data = <$socket>) { 
        last if !$data;
        last if $data =~ s/^<//;
    }
    # $data may be undef on socket error (OS/X perl 5.8.8)
    if ($data) { 
        print STDERR "<$data" if $Debug;
        $data =~ s/[\r\n\t\0]//go;
        $data =~ s/^\s*//go;
        $data =~ s/\s*$//go;
        $self->last_reply( $data );
        return $data;
    }
    $self->last_reply( "" );
    return "";
}

sub write { 
    my $self = shift;
    my $data = shift;
    if ($Simulate) { print STDERR ">$data\n"; return; }
    
    my $socket = $self->{SOCKET};
    print $socket ">$data\n";
    print STDERR ">$data\n" if $Debug;
}
        
sub close {
    my ( $self ) = shift;
    $self->attached( 0 );
    if ($self->SOCKET()) { 
        $self->SOCKET()->close();
        $self->SOCKET( undef );
    }
        
}


=head1 FUNCTIONS

=head2 new

=head1 FUNCTIONS

=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-robotics at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics::Tecan::Gemini


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Robotics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Robotics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Robotics>

=item * Search CPAN

L<http://search.cpan.org/dist/Robotics/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jonathan Cline.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

no Moose;

__PACKAGE__->meta->make_immutable;

1; # End of Robotics::Tecan::Client

__END__

