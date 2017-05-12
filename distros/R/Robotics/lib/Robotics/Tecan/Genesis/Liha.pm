
package Robotics::Tecan::Genesis::Liha;

# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

use warnings;

use strict;
use Moose::Role;
use Carp;
#extends 'Robotics::Tecan::Genesis';

#
# Tecan Genesis 
# Liquid handling commands
#

has 'position' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] }, );
has 'plungerMin' => ( is => 'rw', isa => 'Int', default => 0 );
has 'plungerMax' => ( is => 'rw', isa => 'Int', default => 3150 );
has 'MAX_STEP' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] }, );
my $Debug = 1;

=head1 NAME

Robotics::Tecan::Genesis::Liha - (Internal module)
Handlers for low level liquid handling hardware

=cut
sub getPipettePosition { 
    my ($self, %params) = @_;

    my $position;
    my $tip = $params{"tip"};
    my $code = $self->compile_xp("GET_STATUS",
            tip => $tip, parameter => 0);
    $self->DATAPATH()->write($code);
    my $reply = $self->DATAPATH()->read();
    if (!($reply =~ /^0/)) { 
        warn "!! ". __PACKAGE__. " expected '0' got '$reply' from hardware\n";
        return -1;
    } 
    $position = (split(/[,;]/,$reply))[1];
    if (!defined($position) || $position < 0) { 
        warn __PACKAGE__. " - tip position error in reply '$reply'\n";
        return -1;
    }
    warn __PACKAGE__. "Position of tip=$tip is ". $position. "\n" if $Debug>2;
    $self->position()->[$tip] = $position;
    
    return $position;
}

sub checkPipetteSteps {
    my ($self, %params) = @_;
    
    my $start = $params{"start"};
    my $stop =  $params{"stop"};
    my $tip = $params{"tip"};
    my $dir =  $params{"dir"};
    
    if (0) { 
        # From reading the vendor documentation,
        # it would seem proper to get the "max displacement"
        # of the syringe pump, for later calculations.
        # However it returns "300".  (?)
        my $max = $self->MAX_STEPS()->[$tip];
        if (!$max < 1) { 
            my $code = $self->compile_xp("RPP",
                    tip => $tip, parameter => 5);
            $self->DATAPATH()->write($code);
            my $reply = $self->DATAPATH()->read();
            if (!($reply =~ /^0/)) { 
                warn "!! ". __PACKAGE__. " expected '0' got '$reply' from hardware\n";
                return -1;
            } 
            $max = (split(/[,;]/,$reply))[1];
            if (!defined($max) || $max < 0) { 
                warn __PACKAGE__. " - tip max error in reply '$reply'\n";
                return -1;
            }
            warn __PACKAGE__. "Max of tip=$tip is ". $max. "\n" if $Debug;
            $self->MAX_STEPS()->[$tip] = $max;
        }
    }
    
    if ($dir eq "a") { 
        if ($stop > $self->plungerMax || $stop < $self->plungerMin) { 
            return 0;
        }
        if ($stop < 1) { 
            return 0;
        }
        if ($start > $stop) { 
            return 0;
        }
        if ($start eq $stop) { 
            carp "plunger start eq stop";
        }
        return 1;
    }
    elsif ($dir eq "d") { 
        if ($stop > $self->plungerMax || $stop < $self->plungerMin) { 
            return 0;
        }
        if ($stop < 0) { 
            return 0;
        }
        if ($start < $stop) { 
            return 0;
        }
        if ($start eq $stop) { 
            carp "plunger start eq stop";
        }
        return 1;
    }
    else {
        die "bad dir '$dir' for tip '$tip'";
    }
        
}

sub getPipetteSpeed {
    my ($self, %params) = @_;
    
    # TODO: Get from liquid database
    my $tip = $params{"tip"};
    
    # return (plunger start speed, plunger end speed)
    return (900, 1400, 2400);
}

sub getPipetteDelay {
    my ($self, %params) = @_;
    
    # TODO: Get from liquid database
    my $tip = $params{"tip"};
    
    # return delay
    return 0;
}

sub convertVolToSteps { 
    my ($self, $vol) = @_;
    
    # Constants should be queried from the hardware 
    # itself to be portable.  Still looking for a way to 
    # do that.
    my $maxvol = 1000; # uL
    my $maxstep = 3150; 
    my $step;
    
    # Tecan vol->steps uses uL
    $vol =~ /^(\d+)([munp]*)/i;
    if ($2 eq "u") { 
        $vol = $1;
    }
    elsif ($2 eq "n") { 
        $vol = $1 * 1000;
    }
    elsif ($2 eq "p") {
        $vol = $1 * 1000 * 1000;
    }
    elsif ($2 eq "m") {
        $vol = $1 / 1000;
    }
    
    
    if ($vol > $maxvol) {
        carp __PACKAGE__. " improper volume '$vol'";
        return -1; 
    }
    $step = int($vol * $maxstep / $maxvol);
    warn __PACKAGE__. " new steps for vol $vol ". $step. "\n" if $Debug;
    return $step;
}

=head2 tip_aspirate

Aspirate with coupled tips from named arm.  Use tip string to specify tips.

Specify volume and location, with optional liquid type, flags, etc.
Requires work table to be previously loaded.

Return status string.
May take time to complete.

=item named motor arm - string, motor name (default: "liha")

=item (optional) tips - string, "1" or "2-6" or "2,4,1,7" or "1,5-8" or "all" (default: "1")
=item (optional) volume - string, specifying volume of 1-1000 for each tip, such as "20,20,20" (default: 10)
=item (optional) location - string, specifying "well" numbers or well co-ordinates (default: "1")
=item (optional) liquid type - string, from configuration database (default: "Water")
=item (optional) position - numeric, carrier location, 1-67 (default: 1)
=item (optional) site - numeric, rack position, 0-127 (default: 0)
=item (optional) inter-tip distance - numeric, 1-n (default: 1)
=item (optional) flags - various flags for specifying actions after aspiration (default: "") 
=item (optional) flag argument - various arguments depending on flags (default: "")

=cut

sub tip_aspirate { 
    my $self = shift;
    my %param = @_;
    $self->tip_aspirate_type0( @_ );
}

sub tip_aspirate_type0 {
    my ($self, %params) = @_;
    
    my $motor = $params{"name"} || "liha";
    my $tips = $params{"tips"} || "1";
    my $volume = $params{"volume"} || "10";
    my $location = $params{"at"} || 0;
    my $liquid = $params{"liquid"} || "Water";
    my $grid = $params{"grid"} || "11";
    my $site = $params{"site"} || "0";
    my $tipdist = $params{"tipdistance"} || "1";
    my $flags = $params{"flags"} || "";
    my $flagarg = $params{"flagarg"} || "";
    
    my @tiparray = _tipStringToArray8($tips);

    my $reply;        
    for my $tip (@tiparray) { 
        my $code;
        
        my $position = $self->getPipettePosition(
                tip => $tip);
        
        if ($position < 0) { 
            warn __PACKAGE__. " bad tip position, ignoring operation\n";
            next;
        }
        my $step = $self->convertVolToSteps($volume);
        if ($step < 1) { 
            carp __PACKAGE__. " cant aspirate $volume";
            return "";
        }
        
        my $newposition = $step + $position;
        # TODO: Add liquid property adjustments here
        
        if (!$self->checkPipetteSteps(
                tip => $tip,
                start => $position, 
                stop => $newposition, 
                dir => 'a')) {
            carp("Robotics plunger error, cant aspirate $step steps");
            return "";
        }
        
        my ($ss, $se, $cutoff) = $self->getPipetteSpeed(tip => $tip);
        my $delay = $self->getPipetteDelay(tip => $tip);
        
        $code = $self->compile_xp("SET_SPEED", 
                endspeed => $se,    
                startspeed => $ss,
                tip => $tip);
        $code = $self->compile_xp("ASPIRATE", 
                position => $step, 
                tip => $tip,
                chain => $code);
        $code = $self->compile_xp("DELAY", 
                msec => $delay, 
                tip => $tip,
                chain => $code);
        $code = $self->compile_xp("EXECUTE", 
                tip => $tip,
                chain => $code);
            
        $self->DATAPATH()->write($code) if $code;

        my $replyref = $self->DATAPATH()->EXPECT_RECV();
        if ($replyref) { 
            if ($Debug>1) { 
                my $debug_str = YAML::XS::Dump($replyref);
                $debug_str =~ s/\n/ /g;
                warn __PACKAGE__." expected reply $debug_str\n";
            }
            $reply = $self->DATAPATH()->read();
            warn __PACKAGE__." got reply ".
                    $self->decompile_reply_xp($reply). "\n" if $Debug;
            if ($reply =~ /^[^0]/) { 
                # command error
                carp "Robotics cmd error: $reply\n";
                return 0;       
            }
        }
    }
    return $self->decompile_reply_xp($reply);
}

sub tip_aspirate_type2 {
    my $self = shift;
    # Due to Tecan limitation on passing ASPIRATE and DISPENSE
    # through the named pipe, transmitting these commands do not work.
    # Use tip_dispense_type0 instead to talk directly to the
    #  Tecan syringe pump.
    if (0) { 
        my $motor = shift || "liha";
        my $tips = shift || "1";
        my $volume = shift || "10";
        my $location = shift || '"0C0810000000000000"';
        my $liquid = shift || "Water";
        my $grid = shift || "11";
        my $site = shift || "0";
        my $tipdist = shift || "1";
        my $flags = shift || "0";
        my $flagarg = shift || "";
        
        # ASPIRATE() 
        #  Example: Aspirate(7,">> MagBeads in Viscous Soln <<  23","BUFFER_UL",
        #       "BUFFER_UL","BUFFER_UL",0,0,0,0,0,0,0,0,0,11,0,1,"0C0870000000000000",0);
        # Example: Aspirate(85,"Water","5",0,"5",0,"5",0,"5",0,0,0,0,0,18,0,1,"0C08ˆ0000000000000",0);
        
        my $tipMask = _tipStringToMask8($tips);
        my @volumes = split(",", $volume . ",0,0,0,0,0,0,0,0,0,0");
        for $volume (0..7) {
            if ($volumes[$volume] > 0) { 
                $volumes[$volume] .= '"'. $volumes[$volume]. '"';   
            }
        }
        my $volumestring = join(",", @volumes[0..7]);
        my $wellstring = $location;
        my $loopoption = "0";
        my $loopname = "";
        my $loopaction = "";
        my $loopindex = "";
        if ($flags) { 
            $loopoption = $flags;
        }
        
        my $cmd = "B;ASPIRATE(";
        $liquid =~ s/"//g;
        $liquid = '"'. $liquid. '"';
        if ($loopoption > 0) {
        	$cmd .= join(",", ($tipMask, $liquid, $volume, 
        	       $grid, $site, $tipdist, $wellstring, 
        	       $loopoption, $loopname, $loopaction, $loopindex)). ");";
        }
        else {
            $cmd .= join(",", ($tipMask, $liquid, $volume, 
                    $grid, $site, $tipdist, $wellstring, "0")). ");";
        }
        $self->Write($cmd);
    	return $self->Read();
    }
    my $reply;
    return $reply;
}

sub tip_dispense_type2 {
    # Due to Tecan limitation on passing ASPIRATE and DISPENSE
    # through the named pipe, transmitting these commands do not work.
    # Use tip_dispense_type0 instead to talk directly to the
    #  Tecan syringe pump.

    if (0) { 
        my $motor = shift || "liha";
        my $tips = shift || "1";
        my $volume = shift || "10";
        my $location = shift || "0C0810000000000000";
        my $liquid = shift || "Water";
        my $grid = shift || "11";
        my $site = shift || "0";
        my $tipdist = shift || "1";
        my $flags = shift || "";
        my $flagarg = shift || "";
        
        # DISPENSE() 
        #  Example: Dispense(7,">> MagBeads in Viscous Soln <<  33",
        #       "SAMPLE_UL","SAMPLE_UL","SAMPLE_UL",0,0,0,0,0,0,0,0,0,11,1,1,"0C0870000000000000",0);
        my $tipMask = _tipStringToMask8($tips);
        my @volumes = split(",", $volume . "," x 7);
        my $volumestring = join(",", @volumes[0..7]);
        my $wellstring = $location;
        my $loopoption;
        my $loopname;
        my $loopaction;
        my $loopindex;
        if ($flags) { 
            $loopoption = $flags;
        }
        my $cmd = "B;DISPENSE(". join(",", ($tipMask, $liquid, $volume, 
                   $grid, $site, $tipdist, $wellstring));
        if ($loopoption > 0) {
            $cmd .= join(",", ($loopoption, $loopname, $loopaction, $loopindex));
        }
        else {
            $cmd .= "0";
        }
        $cmd .= ");";
        
    }
}

=head2 tip_dispense

Aspirate with coupled tips from named arm.  Use tip string to specify tips.

Specify volume and location, with optional liquid type, flags, etc.
Requires work table to be previously loaded.

Return status string.
May take time to complete.

=item named motor arm - string, motor name (default: "liha")

=item All other arguments (many) are the same as tip_aspirate.

=cut
sub tip_dispense {
    my $self = shift;
    my %param = @_;
    return $self->tip_dispense_type0(@_);
}

sub tip_dispense_type0 {
    my ($self, %params) = @_;
    
    my $motor = $params{"name"} || "liha";
    my $tips = $params{"tips"} || "1";
    my $volume = $params{"volume"} || "10";
    my $location = $params{"at"} || 0;
    my $liquid = $params{"liquid"} || "Water";
    my $grid = $params{"grid"} || "11";
    my $site = $params{"site"} || "0";
    my $tipdist = $params{"tipdistance"} || "1";
    my $flags = $params{"flags"} || "";
    my $flagarg = $params{"flagarg"} || "";
    
    my @tiparray = _tipStringToArray8($tips);

    my $reply;        
    
    for my $tip (@tiparray) { 
        my $code;
        
        my $position = $self->getPipettePosition(
                tip => $tip);
        if ($position < 0) { 
            warn __PACKAGE__. " bad tip position, ignoring operation\n";
            next;
        }
        my $step = $self->convertVolToSteps($volume);
        if ($step < 1) { 
            carp __PACKAGE__. " cant dispense $volume";
            return "";
        }
        
        my $newposition = $position - $step;
        # TODO: Add liquid property adjustments here
        
        if (!$self->checkPipetteSteps(
                tip => $tip,
                start => $position, 
                stop => $newposition, 
                dir => 'd')) {
            carp(__PACKAGE__. " plunger error, cant dispense $step steps");
            return "";
        }
        
        my ($ss, $se, $cutoff) = $self->getPipetteSpeed(tip => $tip);
        my $delay = $self->getPipetteDelay(tip => $tip);
        
        $code = $self->compile_xp("SET_SPEED_END", 
                speed => $se,
                tip => $tip);
        $code = $self-> compile_xp("SET_CUTOFF", 
                steps => $cutoff, 
                tip => $tip,
                chain => $code);
        $code = $self->compile_xp("DISPENSE", 
                position => $step, 
                tip => $tip,
                chain => $code);
        $code = $self->compile_xp("DELAY", 
                msec => $delay, 
                tip => $tip,
                chain => $code);
        $code = $self->compile_xp("EXECUTE", 
                tip => $tip,
                chain => $code);
        $self->DATAPATH()->write($code) if $code;

        my $replyref = $self->DATAPATH()->EXPECT_RECV();
        if ($replyref) { 
            if ($Debug>1) { 
                my $debug_str = YAML::XS::Dump($replyref);
                $debug_str =~ s/\n/ /g;
                warn __PACKAGE__." expected reply $debug_str\n";
            }
            $reply = $self->DATAPATH()->read();
            warn __PACKAGE__." got reply ".
                    $self->decompile_reply_xp($reply). "\n" if $Debug;
            if ($reply =~ /^[^0]/) { 
                # command error
                carp "Robotics cmd error: $reply\n";
                return 0;       
            }
        }
    }
    return $self->decompile_reply_xp($reply);
}

=head2 tip_set_supply

Set type and location for the supply of pipette tips.
Return status string.
Returns immediately.

=item (optional) type - numeric, 1-4 (default: 1)
=item (optional) grid - numeric, 1-99 (default: 1)
=item (optional) site - carrier location, 0-63 (default: 0)
=item (optional) position - rack position, 0-95 (default: 0)
=cut

sub tip_set_supply {
    my $self = shift;
    my $type = shift || "1";
    my $grid = shift || "1";
    my $site = shift || "0";
    my $position = shift || "0";

    # SET_DITI  [type;grid;site;position]
    #  Example: SET_DITI;1;32;0;0

	my $cmd = join(";", ("set_diti", $type, $grid, $site, $position));

    $self->Write($cmd);
	return $self->Read();
}

=head2 tip_query

Query next available tip location, given tip type.
Return query status string (example: "0;32;0;0")
Returns immediately.

=item type - numeric, 1-4 (default: 1)

=cut
sub tip_query {
    my $self = shift;
    my $type = shift || "1";

    # GET_DITI  [type]
    #  Example: GET_DITI;1

	my $cmd = join(";", ("get_diti", $type));

    $self->Write($cmd);
	return $self->Read();
}

=head2 tip_query_usage

Query usage of tip type.
Return tip usage string (example: "0;96")
Returns immediately.

=item (optional) type - numeric, 1-4 (default: 1)

=cut

sub tip_query_usage {
    my $self = shift;
    my $type = shift || "1";

    # GET_USED_DITIS  [type]
    #  Example: GET_USED_DITIS;1 

	my $cmd = join(";", ("get_used_ditis", $type));

    $self->Write($cmd);
	return $self->Read();
}

=head2 tip_pause

Pause pipetting if robotics is in the PIPETTING state.
No arguments.
Returns error if any.
Returns immediately (?).

=cut

sub tip_pause {
    my $self = shift;

    # PAUSE_PIPETTING 

    $self->Write("pause_pipetting");
	return $self->Read();
}

=head2 tip_couple

Connect pipetting tips to liquid handling arm.

=item (optional) Tips to use.  String, in the format: "1" or "2-5" or "1,4,8" or "all".  Default: "1"
=item (optional) Type of tip.  Numeric, 0-3, as defined in Tecan configuration MINUS ONE.  Default: 0
=item (optional) Operational flags.  Numeric.  0=none.  1=retry tip fetching up to 3 times at 
successive positions.  Default: 0

Returns error if any.
May take time to complete.

=cut

sub tip_coupleWorklist {
    my $self = shift;
    my $motor = shift || "liha";
    my $tiparg = shift || "1";
    my $type = shift || 0;
    my $flag = shift || 0;
	
    # GetDITI(1,0,0);  - connect a tip to pipette #1 (the first pipette)
	my $tipmask = _tipStringToMask8($tiparg);

	my $cmd = "B;GetDITI(". join(',', ($tipmask, $type, $flag)) . ");";
	
    #open(WORKLIST, ">/cygdrive/c/temp/genesis.gwl") || die;
    #print WORKLIST "$cmd\n";
    #close WORKLIST;

    $cmd = 'LOAD_WORKLIST;Worklist(0,c:\temp\genesis.gwl,15,"Water");'.
        'Wash(1,255,255,255,255,"2.0",500,"1.0",500,10,70,30,0,0,1000);';
        
    $self->Write($cmd);
	my $reply = $self->Read();

    sleep(5);
    return $reply;
}

=head2 tip_coupleFirmware

Couple (mechanically join) a pipetting tip(s) to liquid handling arm at the current arm position.

=item (optional) Tips to use.  String, in the format: "1" or "2-5" or "1,4,8" or "all".  Default: "1"
=item (optional) Type of tip.  Numeric, 0-3, as defined in Tecan configuration MINUS ONE.  Default: 0
=item (optional) Operational flags.  Numeric.  0=none.  1=retry tip fetching up to 3 times at 
successive positions.  Default: 1

Returns error if any.
May take time to complete.

See also: tip_uncouple

=cut

sub tip_coupleFirmware {
    my $self = shift;
    my $tiparg = shift || "1";
    my $type = shift || 0;
    my $flag = shift || 1;
	
    # GetDITI(1,0,0); 
	my $tipmask = _tipStringToMask8($tiparg);

	# use firmware cmd; example #A1AGT170,500,100
	my $cmd = "#A1AGT". join(',', ($tipmask, $type, $flag)) . ");";
    $self->Write($cmd);
	return $self->Read();
}


=head2 tip_uncoupleFirmware

Uncouple (mechanically unjoin) a pipetting tip(s) from liquid handling arm at the current arm position.

=item (optional) Tips to use.  String, in the format: "1" or "2-5" or "1,4,8" or "all".  Default: "1"

Returns error if any.
May take time to complete.

See also: tip_couple

=cut

sub tip_uncoupleFirmware { 
    my $self = shift;
    my $tiparg = shift || "1";
    my $type = shift || 0;
    my $flag = shift || 1;
	
    # GetDITI(1,0,0); 
	my $tipmask = _tipStringToMask8($tiparg);

	# use firmware cmd; example #A1ADT170
	my $cmd = "#A1AGT". $tipmask;
    $self->Write($cmd);
	return $self->Read();
}


=head2 _tipStringToMask8

Internal function.
Convert tip string into a numeric tip mask, where tips are numbered "1" to "8".

=item String: "1" or "2-6" or "2,4,1,7" or "1,5-8" or "all" (default: "1")

Returns: 8-bit numeric value.

=cut

sub _tipStringToMask8 {
    my $s = shift || "1";
    
    # tip 1 => return mask=1
    # tip 8 => return mask=128
    # tips 1-8 => return mask=255
    
    # base index = 1 for calling argument of 1-8 vs. index=0 for calling argument of 0-7
    return $s =~ m/all/i ? 255 : _convertStringRangeToMask8($s, 1);
}

sub _convertStringRangeToMask8 {  
	# arg0: string to parse,  "1" or "1,2,3" or "1-3" or "3-5,6,7-8"
	# arg1: index, 0 means bits are 0..7, 1 means bits are 1..8
	# returns: 8-bit number
	my $index = pop;
	my $s = shift; 
	$s =~ s/(\d+)-(\d+)/join ',', $1 .. $2/eg;
	return _convertArrayToMask8($s =~ /\d+/g, $index);
}

sub _convertArrayToMask8 {
	# arg0: numbers in array,  (1,4,8)
	# arg1: base index for bit number, 0 means bits are 0..7, 1 means bits are 1..8
	# error checking:  bit numbers outside 0+index .. 7+index are ignored
	# returns: 8-bit number
	my $n = 0;
	my $base = pop @_;
	my @bits = @_;
	$n |= 1 << ($_ - $base) for grep { $_ >= $base && $_ <= 7+$base } @bits;
	return $n;
}

sub _tipStringToArray8 {
    my $s = shift || "1";
    
    if ($s =~ /all/i) { 
        return (1,2,3,4,5,6,7,8);
    }
    $s =~ s/(\d+)-(\d+)/join ',', $1 .. $2/eg;
    return ($s =~ /\d+/g);
}

sub _convertWellToXY {
    my ($self, %param) = @_; 
    my %coord;
    if ($param{"wellname"}) { 
        ($coord{"x"}, $coord{"y"}) = 
                Robotics::convertWellStringToXY($param{"wellname"});
    }
    elsif ($param{"wellnum"}) { 
        ($coord{"x"}, $coord{"y"}) = 
                Robotics::convertWellNumberToXY($param{"wellnum"});
    }
    if ($coord{"x"} < 1 || $coord{"y"} < 1) { 
        carp "cant calculate well number from ". $param{"wellname"}. $param{"wellnum"};
        return undef;
    }
    
    # Set y-space from tip number, default tip=1
    $coord{"ys"} = $param{"tips"} || 1;
            
    return %coord;
}



=head3 Developer information: Example LIHA firmware commands

position at waste: 
    A1PAA875,2423,90,2100,2100,2100,2100,2100,2100,2100,2100

dispense:
	tip 1 : dispense 119.30<B5>l 12, 8 JC-Greiner V-Bottom [11,2]
	                            100.00<B5>l "Water" DITI <15 - 200<B5>l> Single
	       "Water" =>     
	                            
		M1,GFC
		D1,V3600c2400D358M0R
		M1,GSC

aspirate:
	tip 1 : aspirate 104.30<B5>l  1, 7 Tube 13*100mm, 16 Pos. [8,1]
	                            100.00<B5>l ">> Water <<    10" DITI <15 - 200<B5>l>
	 Single 
		M1,GFC
		D1,OV420P15M0R
		M1,GSC
		M1,GFC	
		D1,V600P313M200R
		M1,GSC

status?

> D1,Q0
< D1,0,448

flush:
    D1,IV5400P3000OA0R
    
    
initialize:
    A1,PAA45,1031,90,2080,2080,2080,2080,2080,2080,2080,2080
    D1,YIP100OS9OD100R
    

Sequence to position at well1, aspirate, dispense, position at waste:
>COMMAND;A1PAA2612,743,90,670,2080,2080,2080,2080,2080,2080,2080
>COMMAND;D1Q0
>COMMAND;D1V3600c2400P358M0R
>COMMAND;D1Q0
>COMMAND;A1PAA2612,743,90,720,2080,2080,2080,2080,2080,2080,2080
>COMMAND;D1Q0
>COMMAND;D1V3600c2400D358M0R
>COMMAND;D1Q0
>COMMAND;A1PAA875,2423,90,2100,2100,2100,2100,2100,2100,2100,2100


? P = move relative plunger (pick liquid)
? I = turn valve to input
? O = turn valve to output
? D = move relative plunger (dispense liquid)
? c = set plunger stop speed (=SPP)
? V = set plunger drive end speed (=SEP)
R = execute command(s)
M = delay (milliseconds)


Dispense command sequence for tests:

    The following has "no reply from GSC, pipe seems hung" bug:
            A1PAA2612,743,90,695,2080,2080,2080,2080,2080,2080,2080
            M1GFC
            D1Q0
            D1V3600c2400D358M0R
            D1Q0
            M1GSC
            
    The following works OK:
    
            A1PAA2612,743,90,670,2080,2080,2080,2080,2080,2080,2080 
            D1Q0
            D1V3600c2400P358M0R
            D1Q0
            A1PAA2612,743,90,720,2080,2080,2080,2080,2080,2080,2080
            D1Q0
            D1V3600c2400D358M0R
            D1Q0
            A1PAA875,2423,90,2100,2100,2100,2100,2100,2100,2100,2100
            
Aspirate command sequence for tests:

    # XXX
    # XXX "GSC" command does not seem to transmit through named pipe?
    # XXX
            #M1GFC
            #D1Q0
            #D1OV420P15M0R
            #D1Q0
            #M1GSC
            
            A1PAA2612,743,90,695,2080,2080,2080,2080,2080,2080,2080
            M1GFC   
            D1Q0
            D1V600P313M200R
            D1Q0
            M1GSC
    
    A1PAA2612,743,90,695,2080,2080,2080,2080,2080,2080,2080
    D1Q0
    D1V600P313M200R
    D1Q0

=cut
 

1; # End of Robotics::Tecan::Genesis::Liha

__END__

