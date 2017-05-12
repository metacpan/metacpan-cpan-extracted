package Robotics::Tecan;

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
has 'HWALIAS' => ( is => 'rw' );
has 'HWNAME' => ( is => 'rw' );
has 'HWSPEC' => ( is => 'rw' );
has 'TIP_MAX' => ( is => 'rw' );
has 'HWDEVICES' => ( is => 'rw' );
has 'DATAPATH' => ( is => 'rw', isa => 'Maybe[Robotics::Tecan]' );
has 'COMPILER' => ( is => 'rw' );
has 'compile_package' => (is => 'rw', isa => 'Str' );

has 'CONFIG' => ( is => 'rw', isa => 'Maybe[HashRef]' );
has 'POINTS' => ( is => 'rw', isa => 'Maybe[HashRef]' );
has 'OBJECTS' => ( is => 'rw', isa => 'Maybe[HashRef]' );
has 'WORLD' => ( is => 'rw', isa => 'Maybe[HashRef]' );

use Robotics::Tecan::Gemini;  # Software<->Software interface
use Robotics::Tecan::Genesis; # Software<->Hardware interface
use Robotics::Tecan::Client;
with 'Robotics::Tecan::Server';

# note for gemini device driver:
# to write a "dying gasp" to the filehandle prior to closure from die,
# implement DEMOLISH, which would be called if BUILD dies

my $Debug = 1;

=head1 NAME

Robotics::Tecan - Control Tecan robotics hardware as Robotics module

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
        $serverport = shift @host || $self->port || 8090;
        $connection = "remote"; 
    }
    if ($self->connection) {
        $self->compile_package( (split(',', $self->connection))[1] );
        if ($connection eq "local") { 
            # Use Gemini
            warn "Opening Robotics::Tecan::Gemini->openPipe()\n" if $Debug;
            $self->DATAPATH(
                    Robotics::Tecan::Gemini->new(
                        object => $self)
                );
        }
        elsif ($connection eq "remote") { 
            # Use Robotics::Tecan socket protocol
            warn "Opening Robotics::Tecan::Client to $server:$serverport\n" if $Debug;
            $self->DATAPATH( 
                    Robotics::Tecan::Client->new(
                        object => $self,
                        server => $server, port => $serverport, 
                        simulate => $params->{"simulate"},
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
    %found = %{Robotics::Tecan::Gemini->probe()};
    %all = (%all, %found); 
    %found = %{Robotics::Tecan::Genesis->probe()};
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

sub hw_get_version {
    my $self = shift;
    return $self->command("GET_VERSION");
    
}

=head2 Write

Function to compile a command to hardware Robotics device driver
and send the command if attached to the hardware.

=cut

sub Write {
    my $self = shift;
    warn "!  Write needs removal\n";
	if ($self->DATAPATH() && $self->DATAPATH()->attached()) { 
	    if ($self->HWTYPE() =~ /GENESIS/) {
	        # XXX temporary
	        my $selector = $self->DATAPATH();
            my $rval = $selector->write(@_);
            return $rval;
	    }
	}
	else {
		warn "! attempted Write when not Attached\n";
		return "";
	}
}

sub command { 
    my $self = shift;
    if ($self->DATAPATH() && $self->DATAPATH()->attached()) { 
        if ($self->COMPILER) { 
            my $code = $self->COMPILER()->compile(@_);
            return $self->DATAPATH()->write($code) if $code;
        }
        else { 
            warn "! No command compiler for ".$self->connection. "\n";
        }
    }
	else {
		warn "! attempted 'command' when not Attached\n";
		return "";
	}
}

# sub command1 is for single(firmware) commands
sub command1 { 
    my $self = shift;
    if ($self->DATAPATH() && $self->DATAPATH()->attached()) { 
        if ($self->COMPILER) { 
            my $code = $self->COMPILER()->compile1(@_);
            return $self->DATAPATH()->write($code);
        }
        else { 
            warn "! No command compiler for ".$self->connection. "\n";
        }
    }
	else {
		warn "! attempted 'command' when not Attached\n";
		return "";
	}
}

=head2 park

Park robotics motor arm (perhaps running calibration), based on the motor name (see 'move') 

For parking roma-named arms, use the arguments:
=item (optional) grip - gripper (hand) action for parking: 
	"n" or false means unchanged grip (default), "p" for park the grip

For parking liha-named arms, use the arguments:


For parking 
Return status string.
May take time to complete.

=cut

sub park {
	my $self  = shift;
	my $motor = shift || "roma0";
	my $grip  = shift || "0";
	my $reply;
	if ($motor =~ m/liha(\d*)/i) {
		$self->command("LIHA_PARK", lihanum => $1) if $1;
		$self->command("LIHA_PARK", lihanum => "0") if !$1;
	}
	elsif ($motor =~ m/roma(\d*)/i) {
		my $motornum = 0;
		# XXX: Check if \d is active arm, if not use SET_ROMANO to make active
		if ($1 > 0) { 
			$motornum = $1;
		}
		$self->command("SET_ROMANO", romanum => $motornum);
		$reply = $self->Read();
		if ( $grip =~ m/p/i ) {
			$grip = "1";
		}
		else {
			$grip = "0";
		}
		$self->command("ROMA_PARK", grippos => $grip);
	}
	elsif ($motor =~ m/lihi(\d*)/i) {
		# "arm number always zero"
		my $arm = "0";
		$self->command("LIHA_PARK", lihanum => $arm);
	}
	elsif ($motor =~ m/pnp(\d*)/i) {

		# XXX: allow user to set handpos (gripper)
		my $handpos = 0;
		$self->command("PNP_PARK", gripcommand => $handpos);
	}
	return $reply = $self->Read();
}

=head2 grip

Grip robotics motor gripper hand, based on the motor name (see 'move').

For roma-named motors, the gripper hand motor name is the same as the arm motor name.

For roma-named motors, use the arguments:
=item (optional) direction - "o" for hand open, or "c" for hand closed (default)
=item (optional) distance - numeric, 60..140 mm (default: 110)
=item (optional) speed - numeric, 0.1 .. 150 mm/s (default: 100)
=item (optional) force - numeric when moving hand closed, 1 .. 249 (default: 40)

For pnp-named motors, use the arguments:
=item (optional) direction - "o" for hand open/release tube, or "c" for hand closed/grip (default)
=item (optional) distance - numeric, 7..28 mm (default: 16)
=item (optional) speed - numeric (unused)
=item (optional) force - numeric (unused)


Return status string.
May take time to complete.

=cut

sub grip {
	my $self     = shift;
	my $motor    = shift || "roma0";
	my $dir      = shift || "c";
	my $distance = shift;
	my $speed    = shift;
	my $force    = shift;

	# ROMA_GRIP  [distance;speed;force;strategy]
	#  Example: ROMA_GRIP;80;50;120;0
	# PNP_GRIP  [distance;speed;force;strategy]
	#  Example: PNP_GRIP;16;0;0;0
	# TEMO_PICKUP_PLATE [grid;site;plate type]
	# TEMO_DROP_PLATE [grid;site;plate type]
	# CAROUSEL_DIRECT_MOVEMENTS [device;action;tower;command]

	# C=close/gripped=1, O=open/release=0
	if ( $dir =~ m/c/i ) { $dir = "1"; }
	else { $dir = "0"; }

	my $reply;
	if ( $motor =~ m/roma(\d*)/i ) {
		if (!$distance) { $distance = "110" };
		if (!$speed) { $speed = "50" };
		if (!$force) { $force = "50" };
		# XXX: Check if \d is active arm, if not use SET_ROMANO to make active
		$self->command("ROMA_GRIP", 
            distance => $distance, speed => $speed,
            force => $force, gripcommand => $dir);
	}
	elsif ( $motor =~ m/pnp(\d*)/i ) {
		# "speed, force: unused"
		if (!$distance) { $distance = "16" };
		$self->command("PNP_GRIP", 
            distance => $distance, speed => $speed, 
            force => $force, strategy => $dir);
	}
	return $reply = $self->Read();
}



=head2 move

Move robotics motor arm, based on the case-insensitive motor name and given coordinates.  

Note: The Gemini application asks the user for arm numbers 1,2,3... in the GUI application, 
whereas the robotics command language (and this Perl module) use arm numbers 0,1,2,..
The motors are named as follows:


=item "roma0" .. "romaN" - access RoMa arm number 0 .. N.  Automatically switches to make the arm
the current arm.  Alternatively, "romaL" or "romal" can be used for the left arm (same as "roma0") 
and "romaR" or "romar" can be use for the right arm (same as "roma1"). 

=item "pnp0" .. "pnpN" - access PnP arm number 0 .. N.   Alternatively, "pnpL" or "pnpl" can be used 
for the left arm (same as "pnp0") 
and "pnpR" or "pnpr" can be use for the right arm (same as "pnp1").  Note: The Gemini application 
asks the user for arm numbers 1,2,3... in the GUI application, whereas the robotics command language
(and this Perl module) use arm numbers 0,1,2,..

=item "temo0" .. "temoN" - access TeMo arm number 0 .. N.

=item "liha0" .. "lihaN" - access LiHA arm number 0 .. N.  (Note: no commands exist)
 
For moving roma-named motors with Gemini-defined vectors, use the arguments:

=item vector - name of the movement vector (programmed previously in Gemini)

=item (optional) direction - "s" = travel to vector start, "e" = travel to vector end 
(default: go to vector end)

=item (optional) site - numeric, (default: 0)

=item (optional) relative x,y,z - three arguments indicating relative positioning (default: 0)

=item (optional) linear speed (default: not set)

=item (optional) angular speed (default: not set)

For moving roma-named motors with Robotics::Tecan points (this module's custom software),
use the arguments:

=item point - name of the movement point (programmed previously)

For moving pnp-named motors, use the arguments:

=item TBD

For moving temo-named motors, use the arguments:

=item TBD

For moving carousel-named motors, use the arguments:

=item TBD

Return status string.
May take time to complete.

=cut


sub move_object {
    my $self           = shift;

    my %param        = @_;
    my $motor        = $param{"motor"} || "roma0";
    my $dest         = $param{"to"} || "HOME1";
    my $on           = $param{"on"};
    my $object       = $param{"object"};
    my $position     = $param{"position"};
    my $point1       = $param{"point_from"};
    my $point2       = $param{"point_to"};
    
    if ((!$on && !$position) && (!$point1 || !$point2)) { 
        confess __PACKAGE__. "no object or point given, @_";
    }
    
    if ($point1) { 
        # Do point-based move
        
        # move to point1
        # grip close object
        # move to point2
        # grip open object
        return;
    }
    
    # Do object-lookup-based move
    
    my $coordref1;
    $coordref1 = $self->_object_get_coord(
            motor => $motor, 
            object => $object, 
            position => $position);
    if (!defined($coordref1)) { 
        confess __PACKAGE__." no position for object @_";
    }
    
    print YAML::XS::Dump($coordref1);
    die;
    
    my $coordref2;
    $coordref2 = $self->_object_get_coord(
            motor => $motor, 
            on => $dest);
    if (!defined($coordref1)) { 
        confess __PACKAGE__." no position for object @_";
    }
    
    # Do the move to fetch
    $self->move();
    
    # Do the move to discard
    
    
}

sub move {
	my ($self)         = shift;
	
	my (%param)        = @_;
	my $motor        = $param{"motor"} || "roma0";
	my $name         = $param{"to"} || "HOME1";
	my $dir          = $param{"dir"} || "0";
	my $site         = $param{"site"} || "0";
	my $xdelta       = $param{"xdelta"} || "0";
	my $ydelta       = $param{"ydelta"} || "0";
	my $zdelta       = $param{"zdelta"} || "0";
	my $speedlinear  = $param{"speedlinear"} || 0;
	my $speedangular = $param{"speedangular"} || 0;
	my $coordref     = $param{"coord"};
	my $grip         = $param{"grip"};

# ROMA_MOVE  [vector;site;xOffset;yOffset;zOffset;direction;XYZSpeed;rotatorSpeed]
#  Example: ROMA_MOVE;Stacker1;0;0;0;0;0
# PNP_MOVE [vector;site;position;xOffset;yOffset;zOffset;direction;XYZSpeed]
# TEMO_MOVE [site;stacker flag]
#	Example: TEMO_MOVE;1
# CAROUSEL_DIRECT_MOVEMENTS [device;action;tower;command]

	# S=vector points to start=1, E=vector points to end=0
    # ""0 = from safe to end position, 1 = from end to safe position""
	if    ( $dir =~ m/s/i ) { $dir = "1"; }
	#elsif ( $dir =~ m/e/i ) { $dir = "0"; }
	else { $dir = "0"; }
	
	my $reply;
	if ( $motor =~ m/roma(\d*)/i ) {
        # First check for Robotics::Tecan point
        if (grep {$_ eq $name} keys %{$self->{POINTS}->{$motor}}) { 
            my $motornum = $1 + 1; # XXX motornum needs verification with docs

            # Verify motors are OK to move
            $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
            
            # Program the coords
            my ($x, $y, $z, $r, $g, $speed) = split(",", $self->{POINTS}->{$motor}->{$name});
            if (!defined($speed)) { 
                # note "speed=0" is ~1cm? per second.. *super* slow
                $speed = "1"; 
            }
            if (!defined($g) && defined($grip)) { 
                $g = $grip;
            }
            $self->command1("SAA", 
                    motorname => $motor,
                    index => 1,
                    x => $x,
                    y => $y, 
                    z => $z,
                    r => $r,
                    g => $g,
                    speed => $speed);
            ## No reply for SAA
            my $reply = $self->Read();
            my $result = $self->COMPILER()->decompile_reply($reply);
            if ($result =~ /^E/ || !($reply =~ /^0/)) { 
                carp(__PACKAGE__. " $motor move error $result");
                return "";
            }
            # Assume Program coords is OK
            # Perform move
            $self->command1("AAA", 
                    motorname => $motor);
            $reply = $self->Read();
            $result = $self->COMPILER()->decompile_reply($reply);
            if ($result =~ /^E/ || !($reply =~ /^0/)) { 
                carp(__PACKAGE__. " $motor move error $result");
                return "";
            }

            # Verify move is correct
            $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
            return $reply;
        }
        else { 
            # Use ROMA_MOVE
            my $motornum = 0;
            # XXX: Check if \d is active arm, if not use SET_ROMANO to make active
            if ($1 > 0) {
                $motornum = $1;
                
            }
            $self->command("SET_ROMANO", romanum => $motornum);
            $reply = $self->Read();
            
            if ( $speedangular > 0 && $speedlinear < 1 ) { 
                # linear must be set if angular is set
                $speedlinear = "400";
            }
            $self->command("ROMA_MOVE",
                    vectorname => $name, site => $site,
                    deltax => $xdelta, deltay => $ydelta, deltaz => $zdelta,
                    direction => $dir, 
                    xyzspeed => $speedlinear, 
                    rotatorspeed => $speedangular);
                                
            return $reply = $self->Read();
        }
	}
	elsif ( $motor =~ m/pnp(\d*)/i ) {

		# XXX: TBD
	}
    elsif ( $motor =~ m/liha(\d*)/i ) {
        my $motornum = $1 + 1; # XXX motornum needs verification with docs
        
        if (defined($coordref)) { 
            # Do coordinate reference
            # Verify motors are OK to move
            $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
            # Perform movement command
            $self->command1("SHZ", 
                unit => $motor,
                ztravel1 => 2080, ztravel2 => 2080, ztravel3 => 2080, ztravel4 => 2080,
                ztravel5 => 2080, ztravel6 => 2080, ztravel7 => 2080, ztravel8 => 2080);
            $reply = $self->Read();
            my ($x, $y, $ys, $z1, $z2, $z3, $z4, $z5, $z6, $z7, $z8) = 
                    ($coordref->{x}, $coordref->{y}, $coordref->{ys},
                    $coordref->{z1}, $coordref->{z2}, $coordref->{z3},
                    $coordref->{z4}, $coordref->{z5}, $coordref->{z6},
                    $coordref->{z7}, $coordref->{z8});
            # TODO: Add run-time offsets here if any
            $self->command1("PAA", 
                unit => $motor,
                x => $x, y => $y, yspace => $ys, 
                z1 => $z1, z2 => $z2, z3 => $z3,
                z4 => $z4, z5 => $z5, z6 => $z6,
                z7 => $z7, z8 => $z8);  
            $reply = $self->Read();
            my $result = $self->COMPILER()->decompile_reply($reply);
            if ($result =~ /^E/ || !($reply =~ /^0/)) { 
                carp(__PACKAGE__. " $motor move error $result");
                return "";
            }
            # Verify move is correct
            $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
            return $reply;
        }
        elsif (grep {$_ eq $name} keys %{$self->{POINTS}->{$motor}}) { 
            # Do Robotics::Tecan point
            
            # Verify motors are OK to move
            $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
            # Perform movement command
            $self->command1("SHZ", 
                unit => $motor,
                ztravel1 => 2080, ztravel2 => 2080, ztravel3 => 2080, ztravel4 => 2080,
                ztravel5 => 2080, ztravel6 => 2080, ztravel7 => 2080, ztravel8 => 2080);
            $reply = $self->Read();
            my ($x, $y, $ys, $z1, $z2, $z3, $z4, $z5, $z6, $z7, $z8) = 
                    split(",", $self->{POINTS}->{$motor}->{$name});
            # TODO: Add run-time offsets here if any
            $self->command1("PAA", 
                unit => $motor,
                x => $x, y => $y, yspace => $ys, 
                z1 => $z1, z2 => $z2, z3 => $z3,
                z4 => $z4, z5 => $z5, z6 => $z6,
                z7 => $z7, z8 => $z8);  
            $reply = $self->Read();
            my $result = $self->COMPILER()->decompile_reply($reply);
            if ($result =~ /^E/ || !($reply =~ /^0/)) { 
                carp(__PACKAGE__. " $motor move error $result");
                return "";
            }
            # Verify move is correct
            $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
            return $reply;
        }
    }
}

=head2 move_path

Move robotics motor arm along predefined path, based on the case-insensitive motor name and given coordinates.  See move. 

Arguments:

=item Name of motor.

=item Array of Robotics::Tecan custom points (up to 100 for Genesis)

Return status string.
May take time to complete.

=cut

sub move_path {
	my $self         = shift;
	my $motor        = shift || "roma0";
	my @points       = @_;
	my $name;
	my $reply;
	if ( $motor =~ m/roma(\d*)/i ) {
        my $motornum = $1 + 1; # XXX motornum needs verification with docs
        # Verify motors are OK to move
        $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
        my $p = 1;
        foreach $name (@points) { 
            # First check for Robotics::Tecan point
            if (grep {$_ eq $name} keys %{$self->{POINTS}->{$motor}}) { 
                # Program the coords
                my ($x, $y, $z, $r, $g, $speed) = split(",", $self->{POINTS}->{$motor}->{$name});
                if (!$speed) { 
                    # note "speed=0" is ~1cm? per second.. *super* slow
                    $speed = "1"; 
                }
                $self->command1("SAA", 
                        motorname => $motor,
                        index => $p,
                        x => $x,
                        y => $y, 
                        z => $z,
                        r => $r,
                        g => $g,
                        speed => $speed);
                ## No reply for SAA
                my $reply = $self->Read();
                my $result = $self->COMPILER()->decompile_reply($reply);
                if ($result =~ /^E/ || !($reply =~ /^0/)) { 
                    carp(__PACKAGE__. " $motor Error programming point '$name': $result");
                    return "";
                }
                $p++;
            }
            last if $p > 100;
    	}
	    if ($p > 1) {
            # Program point is OK - Start Move
            # Perform move
            $self->command1("AAA", 
                    motorname => $motor);
            my $reply = $self->Read();
            my $result = $self->COMPILER()->decompile_reply($reply);
            if ($result =~ /^E/ || !($reply =~ /^0/)) { 
                carp(__PACKAGE__. " $motor move error $result");
                return "";
            }
                
            # Verify move is correct
            $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
            return $reply;
	    }
	}
}

# Find coords of "carrier" aka "fixed object"
sub _object_get_coord_offset_fixed { 
    my $self = shift;
    my %param = @_;
    my $fixedname = $param{"fixedname"} || confess;
    my $fixedobjref = $param{"fixedref"} || die;
    my $coordref = $param{"hashref"} || die;
    my $position = $param{"position"} || "1,1,1";
    my $axisref = $param{"axis"} || die;
    my $movobjref = $param{"movableref"} || die;
    
    my $axismax = $#{@$axisref};
    my @obj_pos = (split(",", $position), 0, 0, 0, 0, 0);
    my $type = "fixed";
    if ($fixedobjref) { 
        ## genesis->fixed->JCplateholder->move: 
        my $objmoveref = $fixedobjref->{move};
        for my $index (0.. $axismax) { 
            my $axisname = $axisref->[$index];
            my $axispos = $obj_pos[$index] || next;
            ## genesis->fixed->JCplateholder->move->[xyz]->[1..n]
            $coordref->{$axisname} = $objmoveref->{$axisname}->{$axispos}
                if defined($objmoveref->{$axisname}) && 
                defined($objmoveref->{$axisname}->{$axispos});
        }
        # Find the platform coordinates of the relative object defining the above
        # and subtract out the relative offset
        ## genesis->fixed->JCplateholder->move->relativeto: 
        my $relmoveref = $objmoveref->{"relativeto"};
        if (defined($relmoveref->{"fixed"}) && !($relmoveref->{"fixed"} =~ /none/i)) { 
            for my $index (0.. $axismax) { 
                my $axisname = $axisref->[$index];
                ## genesis->fixed->JCplateholder->move->relativeto->[xyz]
                $coordref->{$axisname} -= $relmoveref->{$axisname}
                    if defined($relmoveref->{$axisname});
            }
        }
    }
    print "_object_get_coord_offset_fixed ". YAML::XS::Dump($coordref);
    return 1;
}

sub _object_get_coord {
    my ($self, %param) = @_;
    
    my $object = $param{"object"};
    my $grippos = $param{"grippos"};
    my $couplingtype = $param{"couplingtype"};
    my $couplingobj = $param{"coupling"};
    my $orientation = $param{"orientation"};
    my $liquidhandling = $param{"liquidaction"};
    my $motor = $param{"motor"};
    my $tipnum = $param{"tip"};
    
    if (!$object) { 
        confess __PACKAGE__." no object";
    }
    if (!$self->OBJECTS()) { 
        confess __PACKAGE__." no object table";
    }
    
    # Check that object exists in the world
    my $worldref = $self->WORLD();
    my $worldobjref;
    if (!($worldobjref = $worldref->{$object})) { 
        carp __PACKAGE__. "Object $object not placed yet";
    }
    my $parentname = $worldobjref->{"parent"};
    my $pos = $worldobjref->{"position"};
    
    my @axis = $self->COMPILER()->_getAxisNames($motor);
    my @axisalias;
    my %welladdr;
    my %action;
    my $arm_offsetref;
    if ($motor =~ /roma/i) {
        $action{"g"} = $grippos || "open";
        $action{"r"} = $orientation || "landscape";
        # This offset is subtracted from final coord
        $arm_offsetref = $self->OBJECTS()->{"genesis"}->{"arm_offset"}->{$motor};
    }
    elsif ($motor =~ /liha/i) { 
        # Convert well name to well address
        my %welladdr = _convertWellToXY(
                wellname => $param{"well"},
                wellnum => $param{"wellnum"},
                tips => $param{"tipnum"},
                );
        if (!%welladdr) { 
            confess __PACKAGE__. " no well address";
        }
        
        # got wells, set couplingtype tip
        if (defined($couplingobj) && !defined($couplingtype)) { 
            $couplingtype = "tips";
        }
        if (!defined($liquidhandling)) { 
            die __PACKAGE__. " liha action required";
        }
        for my $axisname (grep(/z/, @axis)) { 
            my $tip = $tipnum || "1";
            if ($axisname eq "z$tip") {
                # Active tip
                # TODO: need to add multiple tip operation here
                $action{$axisname} = $liquidhandling;
            }
            else {
                # default axis or other tips use "free"
                $action{$axisname} = "free";
            }
        }
        # This offset is subtracted from final coord
        $arm_offsetref = $self->OBJECTS()->{"genesis"}->{"arm_offset"}->{$motor};
    }
    else { 
        die __PACKAGE__. "no motorname reference";
    }
    
    # Look up the references
    my $carrierref;
    if (grep {$_ eq $parentname} keys %{$self->OBJECTS()->{"fixed"}}) { 
        $carrierref = $self->OBJECTS()->{"fixed"}->{$parentname};
    }
    my $locref;
    my $locrelativetofixedref;
    if (grep {$_ eq $object} keys %{$self->OBJECTS()->{"movable"}}) { 
        $locref = $self->OBJECTS()->{"movable"}->{$object};
        if (defined($locref->{"move"}) && 
                defined($locref->{"move"}->{"relativeto"}) &&
                defined($locref->{"move"}->{"relativeto"}->{"fixed"})) {
            my $locrelativetofixedname = $locref->{"move"}->{"relativeto"}->{"fixed"};
            if (grep {$_ eq $locrelativetofixedname} keys %{$self->OBJECTS()->{"fixed"}}) { 
                $locrelativetofixedref = $self->OBJECTS()->{"fixed"}->{$locrelativetofixedname};
            }
        }
    }
    my $couplingref;
    if (defined($couplingobj) && defined($couplingtype) &&
            (grep {$_ eq $couplingobj} keys %{$self->OBJECTS()->{$couplingtype}})) { 
        $couplingref = $self->OBJECTS()->{$couplingtype}->{$couplingobj};
    }
    
    # 
    # Find the platform coordinates of what 'this object' is "on"
    # i.e. calculate carrier grid/site coordinates
    my %carrier_offset;
    warn "Object Offset $parentname @ site $pos";
    $self->_object_get_coord_offset_fixed(
            fixedname => $parentname,
            fixedref => $carrierref,
            movableref => $locref, 
            relfixedref => $locrelativetofixedref,
            position => $pos,
            hashref => \%carrier_offset,
            axis => \@axis);
    
    # Find the platform coordinates of 'this' (the object)
    my %loc_offset;
    if (defined($locref)) {
        warn "Object Offset $object";
        my $locposref = $locref->{numpositions};
        my $locmoveref = $locref->{move};
        for my $index (0 .. $#axis) { 
            my $axisname = $axis[$index];
            my $axisoffset;
            my $locmovename = $axisname;
            if ($axisname =~ /^z/ && !defined($locmoveref->{$axisname}) && $motor =~ /liha/) { 
                # Map "z1".."z8" to alias ("z") if "z1".."z8" not defined, for liha
                $locmovename = "z";
            }
            if (defined($action{$axisname})) { 
                # action is: z=(free|aspirate|dispense|max), for liha
                # g=(open|close|force|speed), r=(landscape|portrait), for roma
                $axisoffset = $locmoveref->{$locmovename}->{$action{$axisname}}
                        if defined($locmoveref->{$locmovename});
                #warn "axis=$axisname locmovename=$locmovename action=$action{$axisname} axisoffset=$axisoffset";
            }
            elsif (defined($locmoveref->{$axisname}) && defined($welladdr{$axisname})) {
                # look up offset in database by well address ("1", "2", ...)
                $axisoffset = $locmoveref->{$axisname}->{$welladdr{$axisname}};
            }
            if (defined($axisoffset)) { 
                # this offset has an entry in the database
                $loc_offset{$axisname} = $axisoffset;                
            }
            elsif ($axisname =~ /^ys/ && $motor =~ /liha/ && (my $pos1 = $locmoveref->{$locmovename}->{"1"})) {
                # Map values for ys to ys=1 as default
                $loc_offset{$axisname} = $pos1;
            }
            elsif (defined($locmoveref->{$locmovename}) && defined($locposref->{$locmovename})) { 
                # Calculate from linear extrapolation
                my $pos1 = $locmoveref->{$locmovename}->{"1"};
                my $posn = $locmoveref->{$locmovename}->{$locposref->{$locmovename}};
                if (defined($welladdr{$axisname})) { 
                    # Calculate spot offset from well address
                    if (defined($pos1) && defined($posn)) { 
                        $loc_offset{$axisname} = $pos1 + 
                                int(($posn - $pos1) * 
                                ($welladdr{$axisname}-1)/($locposref->{$locmovename}-1));
                        #warn "\tcalc spot_offset_$axisname=$loc_offset{$axisname} ".
                        #        "from welladdr=$welladdr{$axisname}\n";
                    }
                }
                else { 
                    # calculate offset from position
                }
            }
        }
        
        # Find the platform coordinates of the relative object defining 'this'
        # and subtract out the relative offset
        # (this should be recursive, to allow 
        # objects within objects which are all relative)
        
        my $relmoveref = $locmoveref->{"relativeto"};
        ## genesis->moveable->JCgreinerVbottom96->move->relativeto:
        if (defined($relmoveref->{"fixed"}) && !($relmoveref->{"fixed"} =~ /none/i)) { 
            my $fixobj = $relmoveref->{"fixed"};
            my $fixobjref = $self->OBJECTS()->{"fixed"}->{$fixobj}->{"move"};
            ## genesis->fixed->JCplateholder->move:
            my %relpos = ("x", $relmoveref->{"x"}, "y", $relmoveref->{"y"}, "z", $relmoveref->{"z"});
            for my $index (0 .. $#axis) { 
                my $axisname = $axis[$index];
                my $relposnum = $relpos{$axisname} if defined($relpos{$axisname});
                ## genesis->moveable->JCgreinerVbottom96->move->relativeto->[xyz]
                warn "($loc_offset{$axisname} -= $fixobjref->{$axisname}->{$relposnum} for site $axisname=$relposnum)" 
                        if defined($fixobjref->{$axisname}) && 
                        defined($fixobjref->{$axisname}) && defined($relposnum);
                $loc_offset{$axisname} -= ($fixobjref->{$axisname}->{$relposnum})
                        if defined($fixobjref) && defined($axisname) && defined($relposnum) &&
                        defined($fixobjref->{$axisname}) && 
                        defined($fixobjref->{$axisname}->{$relposnum});
            }
        }
    }
    
    # Optimization note: if 'this object' is defined in the database
    # with coords from the 'on object', at the same position, 
    # then the offset is added and then
    #  the relative offset from the relative object is subtracted
    # resulting in a no-op.  better to check if 'this object' was defined
    # with coords as on the 'on object' and skip the offset+relative lookup.
    
    # Find the coupling-object offset, if an object is coupled.
    # Example, a tip may be coupled to the pipette end
    my %coupling_offset;
    if (defined($couplingref)) { 
        for my $index (0 .. $#axis) {
            my $axisname = $axis[$index];
            my $objaxisname = $axisname;
            my $tip = $tipnum || "1";
            if ($axisname =~ m/^z([\d])/ && !defined($couplingref->{$axisname}) && $motor =~ /liha/) { 
                # Map "z1".."z8" to alias ("z") if "z1".."z8" not defined, for liha
                $objaxisname = "z";
            }
            if (defined($action{$axisname}) && !($action{$axisname} =~ /free/)) { 
                $coupling_offset{$axisname} = $couplingref->{$objaxisname}->{length}
                        if defined($couplingref->{$objaxisname}) && 
                        defined($couplingref->{$objaxisname}->{length});
            }
        }
    }
    
    my %coord;
    for my $index (0 .. $#axis) { 
        my $axisname = $axis[$index];
        $coord{$axisname} = 0;
        $coord{$axisname} = $carrier_offset{$axisname} if defined($carrier_offset{$axisname});
        $coord{$axisname} += $loc_offset{$axisname} if defined($loc_offset{$axisname});
        # subtract the distance if an object (like a tip) is coupled to the arm        
        $coord{$axisname} -= $coupling_offset{$axisname} if defined($coupling_offset{$axisname});
        $coord{$axisname} -= $arm_offsetref->{$axisname} if defined($arm_offsetref) && defined($arm_offsetref->{$axisname});
    }
    #print "on_offset ".YAML::XS::Dump(\%on_offset)."\n";
    #print "loc_offset ".YAML::XS::Dump(\%loc_offset)."\n";
    #print "coord ".YAML::XS::Dump($coord)."\n";
    return \%coord;
}

sub _get_aspirate_point {
    my $self = shift;
    my %param = @_;
    my $name = $param{"at"};
    my $motor = $param{"motor"} || "liha0";

    my $coords;
    if (grep {$_ eq $name} keys %{$self->{POINTS}->{$motor}}) { 
        $coords = $self->{POINTS}->{$motor}->{$name};
    }
    else {
        return undef;
    }
    return $coords;
}

# Rename this method to better abstraction
sub aspirate { 
    my $self = shift;
    my %param = @_;
    my $coord;
    my $action = "aspirate";
    $coord = $self->_get_aspirate_point(@_);
    if (!defined($coord)) { 
        $coord = $self->_object_get_coord(
                motor => "liha0", 
                coupling => "tip200",
                @_, liquidaction => $action);
    }
    if (!defined($coord)) { 
        confess __PACKAGE__. "destination unknown, @_";
    }
    
    # TODO: Get the motorname from a state variable
    if (!$self->move("liha0", coord => $coord)) { 
        carp __PACKAGE__. " movement error";
        return "";
    }

    $self->COMPILER()->tip_aspirate(@_);
    
} 
# Rename this method to better abstraction
sub dispense { 
    my $self = shift;
    my %param = @_;
    my $coord;
    my $action = "dispense";
    $coord = $self->_get_aspirate_point(@_);
    if (!defined($coord)) { 
        $coord = $self->_object_get_coord(
                motor => "liha0", 
                coupling => "tip200",
                @_, liquidaction => $action);
    }
    if (!defined($coord)) { 
        confess __PACKAGE__. "destination unknown, @_";
    }
    
    # TODO: Get the motorname from a state variable
    if (!$self->move("liha0", coord => $coord)) { 
        carp __PACKAGE__. " movement error";
        return "";
    }
    $self->COMPILER()->tip_dispense(@_);
    
} 

sub WriteRaw {
# This function provided for debug only - do not use
    my $self = shift;
    warn "!  WriteRaw needs removal\n";
    my $data;
	if ($self->{ATTACHED}) { 
        $data =~ s/[\r\n\t\0]//go;
        $data =~ s/^\s*//go;
        $data =~ s/\s*$//go;
        if ($self->{FID}) { 
            $self->{FID}->Write($data . "\0");
        }
        elsif ($self->{SERVER}) { 
            my $socket = $self->{SOCKET};
            print $socket ">$data\n";
            print STDERR ">$data\n" if $Debug;
        }
	}
	else {
		warn "! attempted Write when not Attached\n";
		return "";
	}
     warn "!! delete this function";
          
}
=head2 Read

Low level function to read commands from hardware.

=cut
sub Read {
    my $self = shift;
    # Reading while unattached may hang depending on device
    #  so always check attached()
	if ($self->DATAPATH() && $self->DATAPATH()->attached()) { 
        my $data;
        if (!$self->DATAPATH()->EXPECT_RECV()) { 
            warn "!! read when no reply expected; system hang is possible; ignoring Read()";
            carp;
        }
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
            "GEM scripts and logs to jcline\@ieee.org, thank you.\n\n";
    return;
}

=head2 status_hardware

Read hardware type.  
Return hardware type string (should always be "GENESIS").

=cut

sub status_hardware {
    my $self = shift;
	my $reply;
	$reply = $self->command("GET_RSP");
	if (!($reply =~ m/genesis/i)) {
		warn "Expected response GENESIS from hardware"
	}
	return $reply;
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

	open(IN, $infile) || return 0;
	my $s = do { local $/ = <IN> };
	close(IN);
	return 2 unless $s;
    $self->CONFIG( YAML::XS::Load($s) );
    
    warn "Configuring from $infile\n";
    my $make;
    my $model;
    for $make (keys %{$self->CONFIG()}) {
        if ($make =~ m/tecan/i) { 
            warn "Configuring $make\n";
            for $model (keys %{$self->{CONFIG}->{$make}}) {
                warn "Configuring $model\n";
                if ($model =~ m/genesis/i) {
                    Robotics::Tecan::Genesis::configure(
                            $self, $self->CONFIG()->{$make}->{$model});                        
                }
            }
        }
    }
    return 1;
}


sub configure_place {
    my ($self, %param) = @_;

    my $object = $param{"object"};
    my $parent = $param{"on"};
    my $pos    = $param{"position"};
    my $replace = $param{"replace"};
    
    my $ref = $self->WORLD();
    if (!defined($ref)) { 
        $self->WORLD( YAML::XS::Load("") );
        $ref = $self->WORLD();
    }

    if ($ref->{$object} && !$replace) { 
        carp __PACKAGE__. " object $object already exists; overwriting placement for now";
    }
    $ref->{$object}->{"parent"} = $parent;
    $ref->{$object}->{"position"} = $pos;
    
    print __PACKAGE__. " Enviroment ". YAML::XS::Dump($ref);
}

    
=head2 status

Read hardware status.  Return status string.

=cut

sub status {
    my $self = shift;
	my $reply;
	$self->Write("GET_STATUS");
	return $reply = $self->Read();
}

=head2 initialize

Quickly initialize hardware for movement (perhaps running quick calibration).  
Return status string.
May take time to complete.

=cut

sub initialize {
    my $self = shift;
	my $reply;
	
	#$self->command("#".$self->{HWNAME}."PIS");
	#return $reply = $self->Read();
	return "0;IDLE";
}


=head2 initialize_full

Fully initialize hardware for movement (perhaps running calibration).  
Return status string.
May take time to complete.

=cut

sub initialize_full {
    my $self = shift;
	my $reply;
	return $self->command("INIT_RSP");
}


=head2 simulate_enable

Robotics::Tecan internal hook for simulation and test.  Not normally used.

=cut

sub simulate_enable {
	# Modify internals to do simulation instead of real communication
	$Robotics::Tecan::Gemini::PIPENAME = '/tmp/gemini';
}



=head1 REFERENCE ON NAMED PIPES

Named pipes must be accessed as UNCs. This means that the computer name where the 
named pipe is running is a part of its name. Just like any UNC a share name must 
be specified. For named pipes the share name is pipe. Examples are:

\\machinename\pipe\My Named Pipe
\\machinename\pipe\Test
\\machinename\pipe\data\Logs\user_access.log

Notice how the third example makes use of an arbitrarly long path and that 
it has what appear to be subdirectories. Since a named pipe is not truly a part 
of the a disk based file system there is no need to create the data\logs subdirectories; 
they are simply part of the named pipes name.
Also notice that the third example uses a file extension (.log). This extension does 
absolutely nothing and is (like the subdirectories) simply part of the named pipes name.

When a client process attempts to connect to a named pipe it must specify a full UNC. 
If, however, the named pipe is on the same computer as the client process then the 
machine name part of the UNC can be replaced with a dot "." as in:

\\.\pipe\My Named Pipe


=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-robotics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics::Tecan


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


1; # End of Robotics::Tecan

__END__

