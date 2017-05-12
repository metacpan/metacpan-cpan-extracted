package Robotics::Fialab;

use warnings;
use strict;
use Moose; 
use Carp;

has 'connection' => ( is => 'rw' );
has 'serveraddr' => ( is => 'rw' );
has 'password' => ( is => 'rw' );
has 'port' => ( is => 'rw', isa => 'Int' );
has 'token' => ( is => 'rw');
has 'VERSION' => ( is => 'rw' );
has 'STATUS' => ( is => 'rw' );
has 'HWTYPE' => ( is => 'rw' );
has 'DATAPATH' => ( is => 'rw', isa => 'Maybe[Robotics::Fialab::Microsia]' );
has 'COMPILER' => ( is => 'rw' );
has 'compile_package' => (is => 'rw', isa => 'Str' );



use Robotics::Fialab::Serial;  # Software<->Hardware interface
use Robotics::Fialab::Microsia; # Software<->Software interface
#use Robotics::Fialab::Client;
#with 'Robotics::Fialab::Server';

# note for device driver:
# to write a "dying gasp" to the filehandle prior to closure from die,
# implement DEMOLISH, which would be called if BUILD dies

my $Debug = 1;

=head1 NAME

Robotics::Fialab - Control Fialab liquid pump/measurement/other hardware as Robotics module

See L<Robotics::Manual>

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';


sub BUILD {
    my ( $self, $params ) = @_;

    # Do only if called directly
    return unless $self->connection;
    
    my $connection = "local";
    
    my $server = $self->serveraddr;
    my $serverport;

    if ($server) { 
        my @host = split(":", $server);
        $server = shift @host;
        $serverport = shift @host || $self->port;
        $connection = "remote"; 
    }
    if ($self->connection) {
        $self->compile_package( (split(',', $self->connection))[1] );
        if ($connection eq "local") { 
            # Use Gemini
            warn "Opening Robotics::Fialab::Microsia->open()\n" if $Debug;
            $self->DATAPATH(
                    Robotics::Fialab::Serial->new(
                        object => $self)
                );
        }
        elsif ($connection eq "remote") { 
            # Use Robotics::Fialab socket protocol
            warn "Opening Robotics::Fialab::Client to $server:$serverport\n" if $Debug;
            $self->DATAPATH( 
                    Robotics::Fialab::Client->new(
                        object => $self,
                        server => $server, port => $serverport, 
                        password => $self->password)
                    );
        }

        $self->VERSION( undef );
        $self->HWTYPE( undef );
        $self->STATUS( undef );
        $self->password( undef );
    }
    else { 
       die "must give 'connection' for ".__PACKAGE__."->new()\n";
    }
}

=head2 probe
 
=cut
sub probe {
    my ($self, $params) = @_;
	my (%all, %found);

    # Find software interfaces then hardware interfaces
    %found = %{Robotics::Fialab::Serial->probe()};
    %all = (%all, %found); 
    %found = %{Robotics::Fialab::Microsia->probe()};
    %all = (%all, %found); 
    
    return \%all;
}

=head2 attach

Start communication with the hardware.

Arguments are:

=item Robotics object: The variable returned from new().

=item (optional) Flags.  A string which specifies attach options 
as single characters in the string: "o" for override 


Returns:  String containing hardware type and version from manufacturer "VERSION" output.

Will not attach to "BUSY" hardware unless override flag is given.

=cut

sub attach {
    my ($self) = shift;
    my $flags = shift || "";
    if ($self->DATAPATH()) { 
        $self->DATAPATH()->attach(option => $flags);
        if ($self->DATAPATH()->attached &&
                $self->compile_package) { 
            # Create a machine compiler for the attached hardware
            $self->COMPILER($self->compile_package()->new());
            # Compiler needs datapath for internal sub's
            $self->COMPILER()->DATAPATH( $self->DATAPATH() );
        }
    }
    return $self->VERSION();
}

sub literal { 
    my $self = shift;
    if (!$self->DATAPATH() || !$self->DATAPATH()->attached()) { 
        warn "! attempted 'command' when not Attached\n";
        return "";
    }
    if (!$self->COMPILER) { 
        warn "! No command compiler for ".$self->connection. "\n";
        return "";
    }
    
    my $code = $self->COMPILER()->compile(@_);
    if ($code) { 
        $self->DATAPATH()->write($code);
        return $self->DATAPATH()->read();
    }
    else { 
        warn "no data from compile()";
        return "";
    }
}

=head2 bypass

Bypass syrings pump

Return status string.
May take time to complete.

=cut

sub bypass {
	my $self  = shift;
	my $motor = shift || "pump1";
	my $reply;
	if ($motor =~ m/pump(\d*)/i) {
		$self->commandS("BYPASS", pumpnum => $1) if $1;
		$self->commandS("BYPASS", pumpnum => 1) if !$1;
	}
	return $reply = $self->read();
}

=head2 literal_read

Low level function to read commands from hardware.

=cut
sub literal_read {
    my $self = shift;
    # Reading while unattached may hang depending on device
    #  so always check attached()
	if ($self->DATAPATH() && $self->DATAPATH()->attached()) { 
        my $data;
        my $selector = $self->DATAPATH();
        $data = $selector->read();
	}
	else {
		warn "! attempted Read when not Attached\n";
		return "";
	}
}


=head2 detach

End communication to the hardware.

=cut

sub detach {
    my($self) = shift;
    if ($self->DATAPATH()) { 
        $self->DATAPATH()->close();
        $self->DATAPATH( undef );
    }
    warn "\nThank you for using ". __PACKAGE__. " !\n".
        "Please support this open source project by emailing\n".
        "your usage info to jcline\@ieee.org, thank you.\n\n";
    return;
}


=head2 configure

Loads configuration data into memory.  

=item pathname of configuration file in YAML format

Returns:
0 if success, 
1 if file error,
2 if configuration error.

=cut

sub configure {
    my $self = shift;
    my $infile = shift || croak "cant open configuration file";
	
	open(IN, $infile) || return 1;
	my $s = do { local $/ = <IN> };
    $self->{CONFIG} = YAML::XS::Load($s) || return 2;
    
    warn "Configuring from $infile\n";
    my $make;
    my $model;
    for $make (keys %{$self->{CONFIG}}) {
        if ($make =~ m/tecan/i) { 
            warn "Configuring $make\n";
            for $model (keys %{$self->{CONFIG}->{$make}}) {
                warn "Configuring $model\n";
                if ($model =~ m/genesis/i) {
                    Robotics::Fialab::Microsia::configure(
                            $self, $self->{CONFIG}->{$make}->{$model});                        
                }
            }
        }
    }
    return 0;
}

=head2 status

Read hardware status.  Return status string.

=cut

sub status {
    my $self = shift;
	my $reply;
	$self->Write("GET_STATUS");
	return $reply = $self->read();
}

=head2 initialize

Quickly initialize hardware for movement (perhaps running quick calibration).  
Return status string.
May take time to complete.

=cut

sub initialize {
    my $self = shift;
	my $reply;
	$self->literal("syringe", "INIT_ALL");
	return;
}


=head2 initialize_full

Fully initialize hardware for movement (perhaps running calibration).  
Return status string.
May take time to complete.

=cut

sub initialize_full {
    my $self = shift;
	my $reply;
	$self->literal("syringe", "INIT_ALL");
	return;
}




=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-robotics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics::Fialab


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


1; # End of Robotics::Fialab

__END__

