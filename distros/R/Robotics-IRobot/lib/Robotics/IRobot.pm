#!/usr/bin/perl

package Robotics::IRobot;

=head1 NAME

Robotics::IRobot - provides interface to iRobot Roomba and Create robots

=head1 SYNOPSIS

	use Robotics::IRobot;
	
	my $robot=Robotics::IRobot->new('/dev/rfcomm0');
	#could be /dev/ttyUSB0, /dev/ttyS0, etc.
	
	#Initializes port and sends OI Init command
	$robot->init();
	
	#Takes robot out of passive mode and enables
	#hardware based safeties
	$robot->startSafeMode();
	
	#Move robot forward at 100mm/s
	$robot->forward(100);
	
	#Get sensor state hash ref
	$robot->refreshSensors();
	my $sensorState=$robot->getSensorState();
	
	#Wait until we have moved 500mm
	while($sensorState->{totalDistance}<500) {
		sleep 1;
		$robot->refreshSensors();
	}
	
	$robot->stop();
	
	$robot->close();

=head1 VERSION

Version 0.14

=cut

our $VERSION='0.14';

=head1 REFERENCES

IRobot Open Interface specification -- L<http://www.irobot.com/filelibrary/pdfs/hrd/create/Create%20Open%20Interface_v2.pdf>

=head1 REQUIRES

Time::HiRes, Device::SerialPort, YAML::Tiny, POSIX, Math::Trig

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

Robotics::IRobot provides an interface for controlling and accessing
sensor data from iRobot robots that support the OI Interface.

This module provides on object oriented interface to the robot and allows
for both event-driven and polling-based reading of sensor data. It provides
all functionality defined in the OI Interface for Roomba 400 series and
Create robots. Also provided is some additional functionality such as primative
dead reckoning and enhanced use of the Create's song functionality.

I<NOTE:  This module is designed for controlling Create but will work with
Roomba where applicable.>

=head1 NOTICE

I make no warranty as to the correct functioning of this module.   Use may cause your 
robot to fall down your basement stairs, catch fire, and burn your house down.  Be prepared
to take physical control of robot at all times.  

I assume no responsibility or liability for damage to robot or its surroundings.  If you do not agree to this, do not
use this module.

=head1 DEVELOPMENT STATUS

This software is currently in alpha status.  Telemetry is still a work in progress.  

=cut

use strict;
use Time::HiRes qw(usleep ualarm time sleep);
use Device::SerialPort;
use POSIX qw(fmod);
use YAML::Tiny;
use Math::Trig;
use Math::Trig ':pi';
use Math::Trig ':radial';

my $DEBUG=0;
my $EPSILON=0.015;
my $WHEEL_WIDTH=258;
my $ROBOT_WIDTH=330;

#Class Data (defined at end of file)
my ($sensorSpecs,$sensorGroups,@sensorFields,
	$calibrationDefaults, $notes, $keys, @sharps,
	$sensorLocations, @cliffSensors);

########initialization Commands################
=head1 METHODS

=head2 Creation and Initialization

=over 4

=item Robotics::IRobot->new($port,$indirectSensorsOn)

Creates a new IRobot object using the given communications port (defaults to /dev/iRobot)
and enables indirect sensors if $indirectSensorsOn is true (this is the default).

=cut

sub new {
	shift;
	my $self={
		portFile=>(shift || '/dev/iRobot'), indirectSensorsOn=>(shift || 1),
		deadReckoning=>\&_correctiveDeadReckoning,
		readBuffer=> '', sensorState=>{lastSensorRefresh=>time()}, ledState=>{},
		pwmState=>[0,0,0], outputState=>[0,0,0],
		sensorListeners=>[], safetyChecks=>1, scriptMode=>0,
		timeEvents=>[],
		nextListenerId=>0, lastCliff=>{}, gatherCliffStatistics=>0,
		calibration=>$calibrationDefaults
		};
	bless($self);
	
	$self->markOrigin();

	$self->{indirectSensorsId}=$self->addSensorListener(0,\&_indirectSensors) if ($self->{indirectSensorsOn});
	
	$self->loadCalibrationData();
	
	die "Data not loaded" unless (defined $notes->{a});
	
	return $self;
}

=item $robot->init()

Initializes the port, connects to the robot, and initiates the OI Interface.

I<You must call one of startSafeMode or startFullMode before calling
actuator commands.>

=cut

sub init {
	my $self=shift;
	
	$self->initPort()  || die "Unable to initialize port";
	sleep 1;
	
	$self->writeBytes(128);
	my ($bytes,$startupMsg)=$self->{port}->read(255);
	
	$self->_writeTelem('R',$startupMsg);
	
	return $startupMsg;
}

=item $robot->initForReplay($telemetryFile)

Replays saved telemetry data, can be used for testing or analysis.

See section TELEMETRY

=back

=cut

sub initForReplay($$) {
        my $self=shift;
        my $file=shift;
        
	my $replay;
	
        open $replay, $file;
        $self->{replay}=$replay;
        
        my ($time,$type,$data)=$self->_readTelem();
        
        die "Invalid replay file!" unless ($type eq 'B');
        
        $self->{replayDelta}=time-$time;
        
        while($type ne 'R') {
                ($time,$type,$data)=$self->_readTelem();
        }
        
}

######Actuator Commands########

=head2 Actuators

=over 4

=item $robot->reset()

Does a soft-reset of robot.  Needed to begin charging or recover after
triggering hardware based safeties.

=cut

sub reset($) {
	my $self=shift;
	
	$self->writeBytes(7);
	
	$self->close();
	sleep 5;
	
	return $self->init();
}

=item $robot->startPassiveMode()

Puts robot into passive mode.

=cut

sub startPassiveMode {
	my $self=shift;
	
	$self->writeBytes(128);
}

=item $robot->startSafeMode()

Puts robot into safe mode.  (Turns on hardware based safeties.)

I<You must call one of startSafeMode or startFullMode before calling
other actuator commands.>

=cut

sub startSafeMode {
	my $self=shift;
	
	$self->writeBytes(131);
	
	sleep .03;
}

=item $robot->startFullMode()

Puts robot into full mode.  (Turns off hardware based safeties.)

I<You must call one of startSafeMode or startFullMode before calling
other actuator commands.>

=cut

sub startFullMode {
	my $self=shift;
	
	$self->writeBytes(132);
	
	sleep .03;
}

=item $robot->startDemo($demoId)

Puts robot in passive mode and starts built in demo.  Consult OI Interface doc for
available demos.

=cut

sub startDemo($$) {
	my $self=shift;
	my $demo=shift;
	
	$self->writeBytes(136,$demo);
}

=item $robot->stopDemo()

Stops currently running demo.

=cut

sub stopDemo($) {
	my $self=shift;
	
	$self->startDemo(255);
}

=item $robot->drive($velocity, $radius)

Sends robot command to make a turn with speed $velocity (in mm/s), negative values are reverse;
and turning radius $radius (in mm), positive values turn counter-clockwise, negative turn clockwise.

=cut

sub drive($$$) {
	my $self=shift;
	
	my $velocity=shift;
	my $radius=shift;
	
	$self->{lastVelocity}=$velocity if ($velocity!=0);
	
	$self->writeBytes(137,_convertFSS($velocity),_convertFSS($radius));
}

=item $robot->driveDirect($rightVelocity,$leftVelocity)

Sends robot command to drive right wheel at $rightVelocity (mm) and 
left wheel at $leftVelocity (mm).  Positive values are forward, negative values are
reverse.

=cut

sub driveDirect($$$) {
	my $self=shift;
	my $rightVelocity=shift;
	my $leftVelocity=shift;
	
	$self->{lastVelocity}=(abs($rightVelocity)+abs($leftVelocity))/2 if ($rightVelocity!=0 && $leftVelocity!=0);
	
	$self->writeBytes(145,_convertFSS($rightVelocity),_convertFSS($leftVelocity));
}

=item $robot->stop()

Stops robot.

=cut

sub stop($) {
	my $self=shift;
	
	$self->drive(0,0);
}

=item $robot->forward($velocity)

Moves robot forward at $velocity in (mm/s).

I<NOTE:  This does not actually drive robot in a straight line, it actually performs right turn with
a radius of 32768mm.>

=cut

sub forward($$) {
	my $self=shift;
	my $velocity=shift;
	
	$self->drive($velocity,32768);
}

=item $robot->reverse($velocity)

Moves robot in reverse at $velocity in (mm/s).

=cut

sub reverse($$) {
	my $self=shift;
	my $velocity=shift;

	$self->drive(-$velocity,32768);
}

=item $robot->rotateRight($velocity)

Rotates robot in place right (clockwise) at $velocity (in mm/s).

=cut

sub rotateRight($$) {
	my $self=shift;
	my $velocity=shift;

	$self->drive($velocity,-1);
}

=item $robot->rotateLeft($velocity)

Rotates robot in place left (counter-clockwise) at $velocity (in mm/s).

=cut

sub rotateLeft($$) {
	my $self=shift;
	my $velocity=shift;
	$self->{turning}=1;

	$self->drive($velocity,1);
}

=item $robot->setLEDs($powerColor, $powerIntensity, $playOn, $advanceOn)

Sets robot LEDs

	$powerColor should be >=0 and <=255.  0 is green, 255 is red.
	$powerIntensity should be >=0 and <=255
	$playOn and $advanceOn are boolean

=cut

sub setLEDs($$$$$) {
	my $self=shift;
	my $powerColor=shift;
	my $powerIntensity=shift;
	my $playOn=shift;
	my $advanceOn=shift;
	my $ledState=$self->{ledState};
	
	$ledState->{play}=$playOn;
	$ledState->{advance}=$advanceOn;
	$ledState->{powerColor}=$powerColor;
	$ledState->{powerIntensity}=$powerIntensity;
	
	$self->updateLEDs();
}

=item $robot->setPlayLED($playOn)

Sets "Play" LED on or off.

=cut

sub setPlayLED($$) {
	my $self=shift;
	my $playOn=shift;
	
	$self->{ledState}{play}=$playOn;
	
	$self->updateLEDs();
}

=item $robot->togglePlayLED()

Toggles "Play" LED.

=cut

sub togglePlayLED($) {
	my $self=shift;
	
	$self->{ledState}{play}=!$self->{ledState}{play};
	
	$self->updateLEDs();
}

=item $robot->setAdvanceLED($advanceOn)

Sets "Advance" LED on or off.

=cut

sub setAdvanceLED($$) {
	my $self=shift;
	my $advanceOn=shift;
	
	$self->{ledState}{advance}=$advanceOn;
	
	$self->updateLEDs();
}

=item $robot->toggleAdvanceLED()

Toggles "Advance" LED.

=cut

sub toggleAdvanceLED($) {
	my $self=shift;
	
	$self->{ledState}{advance}=!$self->{ledState}{advance};
	
	$self->updateLEDs();
}

=item $robot->setPowerLED($powerColor,$powerIntensity)

Sets "Power" LED

	$powerColor should be >=0 and <=255.  0 is green, 255 is red.
	$powerIntensity should be >=0 and <=255

=cut

sub setPowerLED($$$) {
	my $self=shift;
	my $powerColor=shift;
	my $powerIntensity=shift;
	my $ledState=$self->{ledState};
	
	$ledState->{powerColor}=$powerColor;
	$ledState->{powerIntensity}=$powerIntensity;
	
	$self->updateLEDs();
}

=item $robot->getLEDState()

Returns a hash reference with keys advance, play, powerColor, and powerIntensity that
give current LED state.  If modified, calls to updateLEDs will send modifications to robot.

I<NOTE: Values in hash reflect history of commands sent through interface.  Actual LED state
on robot may be different.>

=cut

sub getLEDState($) {
	my $self=shift;
	
	return $self->{ledState};
}

=item $robot->updateLEDs()

Writes current values in hash reference returned by getLEDState to robot.

=cut

sub updateLEDs($) {
	my $self=shift;
	my $ledState=$self->{ledState};
	
	$self->writeBytes(139,(1 & $ledState->{play})*2+(1 & $ledState->{advance}) * 8, $ledState->{powerColor},$ledState->{powerIntensity});
}

=item $robot->setDigitalOutputs($output0,$output1,$output2)

Sets state of robot's digital outputs.  Values are boolean.

=cut

sub setDigitalOutputs($$$$) {
	my $self=shift;
	
	$self->{outputState}=\@_;

	$self->updateDigitalOutputs;
}

=item $robot->setDigitalOutput($output,$state)

Sets state of output $output to $state.
	
	$output is >=0 and <=2. 
	$state is boolean.

=cut

sub setDigitalOutput($$$) {
	my $self=shift;
	my $output=shift;
	my $state=shift;
	
	$self->{outputState}[$output]=$state;
	
	$self->updateDigitalOutputs();
}

=item $robot->toggleDigitalOutput($output)

Toggles state of digital output $output

=cut

sub toggleDigitalOutput($$) {
	my $self=shift;
	my $output=shift;
	
	$self->{outputState}[$output]=!$self->{outputState}[$output];
	
	$self->updateDigitalOutputs();
}

=item $robot->getDigitalOutputs()

Returns an array ref containing state of robots digital outputs.
If modified, calls to updateDigitalOutputs will send modifications to robot.

I<NOTE: Values in array reflect history of commands sent through interface.  Actual output state
on robot may be different.>

=cut

sub getDigitalOutputs($) {
	my $self=shift;
	
	return $self->{outputState};
}

=item $robot->updateDigitalOutputs()

Writes current values in array reference returned by getDigitalOutputs to robot.

=cut

sub updateDigitalOutputs($) {
	my $self=shift;
	
	my $byte=0;
	my $outputState=$self->{outputState};
	
	for(my $i=2;$i>=0;$i--) {
		$byte*=2;
		$byte+=($outputState->[$i] & 1);
	}
	
	$self->writeBytes(147,$byte);
}

=item $robot->setPWMLoads($lsd0, $lsd1, $lsd2)

Sets pwm duty cycle on low side drivers.  Load values should be between 0 and 1 inclusive.  

	0 is off, 1 is on, .5 is pulsed on 50% of the time, etc.

=cut

sub setPWMLoads($$$$) {
	my $self=shift;
	
	foreach my $l (@_) {
		return 0 if ($l<0 || $l > 1);
	}
	
	$self->{pwmState}=[map "int($_*128)",@_];
	
	$self->updatePWMLoads();
}

=item $robot->setPWMLoad($lsd, $load)

Sets pwm duty cycle on low side driver $lsd to $load.  
Load values should be between 0 and 1 inclusive.  

	0 is off, 1 is on, .5 is pulsed on 50% of the time, etc.

=cut

sub setPWMLoad($$$) {
	my $self=shift;
	my $pwm=shift;
	my $load=shift;
	
	$self->{pwmState}[$pwm]=int($load*128) if ($load <= 1 && $load >= 0);
	
	$self->updatePWMLoads();
}

=item $robot->changePWMLoad($lsd, $loadDelta)

Changes pwm duty cycle on low side driver $lsd by $loadDelta.  Load Delta should
be between 0 and 1 inclusive.

=cut

sub changePWMLoad($$$) {
	my $self=shift;
	my $pwm=shift;
	my $load=shift;
	
	$self->{pwmState}[$pwm]+=int($load*128);
	$self->{pwmState}[$pwm]=0 if ($self->{pwmState}[$pwm]<0);
	$self->{pwmState}[$pwm]=128 if ($self->{pwmState}[$pwm]>128);
	
	$self->updatePWMLoads();
}

=item $robot->getPWMLoads()

Returns an array reference that contains current duty cycles of low side drivers.
If modified, calls to updatePWMLoads will send modifications to robot.

I<NOTE:  Values returned in this array are in the range 0-128, not 0-1 like the other methods.
Also, values in array reflect history of commands sent through interface.  Actual output state
on robot may be different.>

=cut

sub getPWMLoads($) {
	my $self=shift;
	
	return $self->{pwmState};
}

=item $robot->updatePWMLoads()

Writes current values in array reference returned by getPWMLoads to robot.

=cut

sub updatePWMLoads($) {
	my $self=shift;
	
	my $pwmState=$self->{pwmState};
	
	$self->writeBytes(144,CORE::reverse(@{$self->{pwmState}}));
	print "Setting pwm loads: " . join(", ",@{$self->{pwmState}}) . "\n";
}

=item $robot->setPWMOnOff($lsd0, $lsd1, $lsd2)

Turns on and off low side drivers.  Values are boolean.

=cut

sub setPWMOnOff($$$$) {
	my $self=shift;
	
	my $lsd0=shift;
	my $lsd1=shift;
	my $lsd2=shift;
	
	my $byte=($lsd0 & 1) + ($lsd1 & 1) * 2 + ($lsd2 & 1) * 4;
	
	$self->writeBytes(138,$byte);
}

=item $robot->sendIR($byte)

Sends IR byte through LED hooked up to LSD1.

See Open Interface doc for details.

=cut

sub sendIR($$) {
	my $self=shift;
	
	my $irByte=shift;
	$self->writeBytes(151,$irByte);
}

=item $robot->setSongRaw($songId, @songBytes)

Sets song $songId in robot's memory to @songBytes.  
@songBytes can contain up to 16 notes.

See Open Interface doc for details.

=cut

sub setSongRaw($$@) {
	my $self=shift;
	my $songId=shift;
	
	print "setting song: " . $songId . ": ". join(", ",@_) , "\n";
	
	$self->writeBytes(140,$songId,(@_/2),@_);
}

=item $robot->playABCNotation($file, $callback)

Loads song in ABC format (see abcnotation.com) from $file and begins playing on Create.
If passed, calls &$callback($robot) when done.

I<NOTE:  You must either poll sensor values frequently or use the sensor data streaming methods
for this method to work properly.  Calling this method will overwrite any data contained in song banks 14 and 15>

=cut

sub playABCNotation($$$) {
	my $self=shift;
	my $file=shift;
	my $callback=shift;
	
	$self->playLongSongRaw($callback,loadABCNotation($file));
 
}

=item $robot->playLongSongRaw($callback, @songBytes)

Plays song contained in @songBytes (may be longer than 16 notes).  If passed, calls &$callback($robot) when done.

I<NOTE:  You must either poll sensor values frequently or use the sensor data streaming methods
for this method to work properly.  Calling this method will overwrite any data contained in song banks 14 and 15>

=cut

sub playLongSongRaw($$@) {
	my $self=shift;
	my $callback=shift;
 
	my @song=@_;
	
	#print "playing: " . join(", ",@song) . "\n";
	
	$self->setSongRaw(15,splice(@song,0,32));
	
	$self->addSensorEvent(300,sub{
			my $self=shift;
			my $listener=shift;
			
			if ($self->{sensorState}{songPlaying}) {
				$listener->{param}=$listener->{param}==15?-14:-15 if ($listener->{param}>0);
			} else {
				if ($listener->{param}<0) {
					$listener->{param}=-$listener->{param};
					return 1;
				}
			}
			
			return 0;
		},
		sub {
			my $self=shift;
			my $listener=shift;
			
			my $last=(@song==0);
			
			$self->playSong($listener->{param});
			print "Song length: " . (@song+0) . "\n";
			if ($last) {
				$self->removeSensorListener($listener->{id});
				&$callback($self) if ($callback);
			} else {
				$self->setSongRaw(($listener->{param}==15?14:15),splice(@song,0,32));
			}
			
			return 1;
		},-15,0);

}

=item IRobot::loadABCNotation($file)

Loads song in ABCNotation format from $file (see abcnotation.com).
Returns song in format defined in OI Interface.  If smaller than 16 notes (32 bytes)
can be passed to setSongRaw.  Otherwise resulting bytes can be passed to playLongSongRaw.

=cut
	

sub loadABCNotation($) {
	#my $self=shift;
	my $file=shift;
	
	open ABC,$file;
	
	my $header=1;
	my (@song,$key,$length,$nkey);
	
	$length=8;
	$key=[];
	$nkey=0;
	
	while(<ABC>) {
		chomp;
		my @line=split(/:/,$_);
		
		if ($line[0] eq 'K') {
			my $nkey=$keys->{$line[1]};
			if ($nkey>0) {
				$key=[$sharps[0 .. $nkey-1]];
			} elsif ($nkey<0) {
				$key=[$sharps[@sharps+$nkey .. $#sharps]];
			}
		} elsif ($line[0] eq 'L') {
			my @length=split(/\//,$line[1]);
			$length=$length[1];
		} elsif ($line[0]=~/^%/) {
			#comment
		} elsif (length($line[0])>1 || $line[0] eq '|') {
			s/".{1,3}"//g;
			s/\[.{1,3}\]//g;
			s/[^[A-Ga-gz0-9\/,'\^_=]//g;
			my $line=$_;
			while ($line ne '') {
				$line=~/^([\^_=]?)([A-Ga-gz])([',]*)(\d*\/?\d*)(.*)/;
				my $sharp=$1;
				my $note=$2;
				my $octave=$3;
				my $duration=$4;
				$line=$5;
				
				my $noctave=6;
				if (uc($note) eq $note) {
					$noctave--;
				}
				if ($octave=~/'/) {
					$noctave+=length($octave);
				} elsif ($octave=~/,/) {
					$noctave-=length($octave);
				}
				
				my $nnote=_getNote($sharp,$note,$nkey,$key,$noctave);
				
				my $nlength=1;
				if ($duration=~/(\d*)^\/(\d*)/) {
					$nlength=($1 || 1)/($2 || 2);
				} else {
					$nlength=$duration || 1;
				}
				
				$nlength/=$length;
				
				$nlength*=64;
				
				push @song,$nnote,int($nlength);
				
			}
		}
			
	}
	
	close ABC;
	return @song;
	
}



sub _getNote($$$) {
	my ($sharp,$note,$nkey,$key,$octave)=@_;
	
	if ($note eq 'z') {
		return 0;
	}
	
	if ($sharp eq '' && $nkey) {
		
		my $k;
		$sharp=0;
		foreach $k (@$key) {
			$sharp=($key<=>0) if (lc($note) eq $k);
		}
		
	} else {
		$sharp=($sharp eq '^')?1:(($sharp eq '_')?-1:0);
	}
	
	return $notes->{lc($note)}+$sharp+$octave*12;


}

=item $robot->setSong($songId,$song)

Sets song bank $songId to the song specified in $song.

$song is expected to be a whitespace seperated list of notes.
Each note is made up of an optional octave number, a note letter (a-g)
or r for a rest, an optional sharp designator (#), and a duration in 64ths of
a second.  If no octave is given the last octave specified is used.  If no octave
has yet been specified octave 4 is used.  Example:

	d16 a16 r32 3a16 a#32 b16 2b8 c#16

The example above will play a d in the 4th octave for 1/4 second, an a in the 4th
octave for 1/4 second, rest for 1/2 second, an a in the 3rd octave for 1/4 second,
and a sharp in the 3rd octage for 1/2 second, a b in the 3rd octave for 1/4 second,
a b in the 2nd octave for 1/8 second, and a c sharp in the 2nd octave for 1/4 second.

The method will return the estimated duration in seconds the song will play.  Using the example
above the method would return 2.375

=cut

sub setSong($$$) {
	my $self=shift;
	
	my $songId=shift;
	my $song=shift;
	
	my $lastOctave=4;
	
	my @song;
	my $note;
	my $totalDuration=0;
	foreach $note (split(/\s/,lc($song))) {
		$note=~/(\d?)([a-gr]#?)(\d{1,3})/;
		my $octave=$1 || $lastOctave;
		my $letter=$2;
		my $duration=$3;
		
		my $num;
		if ($letter eq 'r') {
			$num=0;
		} else {
			$num=$notes->{$letter}+($octave+1)*12;
		}
		
		push @song,$num,$duration;
		
		$lastOctave=$octave;
		$totalDuration+=$duration;
	}
	
	$self->setSongRaw($songId,@song);
	
	return $totalDuration/64;
}

=item $robot->playSong($songId)

Plays song from bank $songId.

=cut

sub playSong($$) {
	my $self=shift;
	my $songId=shift;
	
	#print "playing song: $songId\n";
	
	$self->writeBytes(141,$songId);
}

=item $robot->turnTo($direction, $speed, $callback)

Attempts to turn the robot to face $direction relative to the direction it
was facing when $robot->init() was called or last $robot->markOrigin call.
Robot will make the turn at $speed.  Robot will stop once complete and call
&$callback($robot) if $callback is passed.

See section DEAD RECKONING for more information.

I<NOTE:  You must either poll sensor values frequently or use the sensor data streaming methods
for this method to work properly.>

=cut

sub turnTo($$$) {
	my $self=shift;
	my $angle=shift;
	my $speed=shift;
	my $callback=shift;
	
	$angle=_normalizeAngle($angle);
	my $direction=$self->{sensorState}{direction};
	my $delta=_normalizeAngle($angle-$direction);

	#print join(", ",$angle,$delta,$speed) . "\n";
	
	$self->waitAngle(200,$delta-8*$EPSILON*$speed/$WHEEL_WIDTH, sub {
		$self->stop();
		&$callback($self,$delta) if ($callback);
	});
	$self->rotateLeft(($delta<=>0)*$speed);
	
}

=item $robot->goTo($x, $y, $speed, $callback)

Attempts to drive the robot to position ($x,$y) relative to its location
when $robot->init() was called or last $robot->markOrigin call.
Robot will make the proceed at $speed.  Robot will stop once complete
and call &$callback($robot) if $callback is passed.

See section DEAD RECKONING for more information.

I<NOTE:  You must either poll sensor values frequently or use the sensor data streaming methods
for this method to work properly.>

=cut

sub goTo($$$$$) {
	my ($self,$destX,$destY,$speed,$callback)=@_;
	
	my $x=$self->{sensorState}{x};
	my $y=$self->{sensorState}{y};
	
	my $deltaX=$destX-$x;
	my $deltaY=$destY-$y;
	
	my ($distance,$angle)=cartesian_to_cylindrical($x,$y);
	$angle+=pip2; #so 0 is along +y axis
	
	$self->turnTo($angle,$speed,
		sub {
			$self->forward($speed);
			$self->waitDistance(200,$distance,
				sub {
					$self->stop();
					&$callback($self,$distance) if ($callback);
				}
			);
		}
	);
}

######Sensor Commands##########
=back

=head2 Sensors

The robot's sensor data can be retrieved in several different ways.  The easiest is 
to simply call $robot->refreshSensors on a regular basis.  This will retrieve all sensor
data from the robot, which can then be accessed from the hash returned by
$robot->getSensorState().  If you do not want all sensor data to be retrieved, then
you can use the $robot->getSensor($id) method.  This will only retrieve data for
one sensor (or sensor set) but, it is not recommended.

Consult the OI Interface document for more details on sensor ids.

Another method is to use the iRobot's sensor streaming functionality.  When the
robot is put in streaming mode it will send back sensor data once every 15ms.  Use the
$robot->startSteam, $robot->pauseStream. $robot->resumeStream method to start and
stop the stream.  The $robot->getStreamFrame method should be called at least every
15ms to read in the sensor data and update the sensor state hash.  As with the polling
method, you can pass a sensor ids to $robot->startStream to have the robot stream data
for only particular sensors, but again, this is not recommeded.

The third method is to use the event-driven approach.  Your program can register sensor listeners
or events to listen for using the $robot->addSensorListener, $robot->addSensorEvent,
$robot->runEvery, $robot->waitTime, $robot->waitDistance, and $robot->waitAngle methods.  Once these
have been registered the $robot->runSensorLoop and $robot->exitSensorLoop methods will put the robot in
streaming mode then read sensor data as it comes in while updating the sensor state hash and calling any
sensor listeners or events.

=over 4

=item $robot->getSensorState()

Returns a hash reference containing last read values from robot sensors.

=cut

sub getSensorState() {
	my $self=shift;
	
	return $self->{sensorState};
}

=item $robot->getDockSignal()

Returns an array indicating the presense of a "home base" docking station and any docking beacons seen.

Example:

	my ($dockPresent,$greenBeacon,$forceField,$redBeacon)=$robot->getDockSignal();

=cut

sub getDockSignal($) {
	my $self=shift;
	my $irByte=$self->{sensorState}{irByte};
	
	my $dock=(($irByte & 241)==240);
	
	#print join(", ",$irByte,($irByte & 241)) . "\r\n";
	
	if ($dock) {
		my $green=($irByte & 4) >> 2;
		my $red=($irByte & 8) >> 3;
		my $force=($irByte & 2) >> 1;
		
		return (1,$green,$force,$red);
	} else {
		return (0,0,0,0);
	}
}


=item $robot->getSensorLocation($sensor)

Gets the current location of a sensor relative to the origin.  Possible sensors:

=over 4

=item cliffLeft

=item cliffFrontLeft

=item cliffFrontRight

=item cliffRight

=item bumpLeft

=item bumpCenter

=item bumpRight

=item caster

=item irSensor

=item wheelLeft

=item wheelRight

=item

=back

=cut	

sub getSensorLocation($$) {
	my $self=shift;
	my $sensor=shift;
	
	my $sensorState=$self->{sensorState};
	my ($x,$y);

	if (defined($sensorLocations->{$sensor})) {
		my $sensorLocation=$sensorLocations->{$sensor};
		($x,$y)=cylindrical_to_cartesian($sensorLocation->[0],$sensorLocation->[1]+$self->{sensorState}{direction});
	} else {
		($x,$y)=0;
	}
	
	return ($sensorState->{x}+$x,$sensorState->{y}+$y);
}

=item $robot->refreshSensors()

Retrieves all sensor data, refreshes sensor state hash, and triggers any sensor listeners or events.  This method will
block for up to 15ms if called more than once every 15ms.

If you are not calling this method more than once every few seconds.  You may wish to switch the movement correction
mode to 'robot' or 'raw', as these may be more accurate in this situation.  See setMovementCorrectionMode method.

=cut

sub refreshSensors($) {
	my $self=shift;
	
	my $sinceLastRefresh=(time()-$self->{sensorState}{lastSensorRefresh});
	
	sleep($EPSILON - $sinceLastRefresh) if ($sinceLastRefresh < $EPSILON);
	
	$self->getSensor(6);
}

=item $robot->getSensor($sensorId)

Retreives data from a single sensor, refreshes sensor state hash, and triggers any sensor listeners or events.
This method is generally not recommedended.  $robot->refreshSensors() should be used instead.

If you are not polling the distance and angle sensors more than once every few seconds.  You may wish to switch the dead reckoning
mode to 'robot' or 'raw', as these may be more accurate in this situation.  See setMovementCorrectionMode method.

See OI Documentation for sensor ids.

=cut

sub getSensor($$) {
	my $self=shift;
	my $sensorId=shift;

	$self->writeBytes(142,$sensorId);
	my @data=$self->_readSensorData($sensorId);
	
	$self->_triggerSensorEvents([$sensorId]);
	
	return wantarray ? @data : $data[0];
}

=item $robot->getSensors($sensorId1, $sensorId2, ... )

Retrieves data for a particular sensor, refreshes sensor state hash, and triggers any sensor listeners or events.  This method is
generally not recommended.  $robot->refreshSensors() should be used instead.

If you are not polling the distance and angle sensors more than once every few seconds.  You may wish to switch the dead reckoning
mode to 'robot' or 'raw', as these may be more accurate in this situation.  See setMovementCorrectionMode method.

See OI Documentation for sensor ids.

=cut

sub getSensors($@) {
	my $self=shift;
	
	$self->writeBytes(149,(@_+0),@_);
	
	my @retArr;
	
	my $sensorId;
	foreach $sensorId (@_) {
		push @retArr,$self->_readSensorData($sensorId);
	}
	
	$self->_triggerSensorEvents(\@_);
	
	return @retArr;
}

=item $robot->runSensorLoop()

Begins streaming sensor data from the robot.  Updates sensor state hash every 15ms and triggers any
sensor listeners or events.  This method will block until $robot->exitSensorLoop() is called.

=cut

sub runSensorLoop($) {
	my $self=shift;
	
	$self->{exitLoop}=0;

	$self->startStream(6);

	while(!$self->{exitLoop}) {
		$self->getStreamFrame();
	}
	
	$self->pauseStream();
}

=item $robot->exitSensorLoop()

Stops streaming data from robot.  Causes any previous call to runSensorLoop to return.

=cut

sub exitSensorLoop($) {
	my $self=shift;

	$self->{exitLoop}=1;
}

=item $robot->startStream()

=item $robot->startStream($sensorId)

Puts robot into streaming mode.  If a $sensorId is passed only streams that sensor (not recommended).  Otherwises streams data from
all sensors.

See OI Documentation for more details

=cut

sub startStream($@) {
	my $self=shift;
	
	push @_,6 unless (@_ > 0);
	
	$self->writeBytes(148,(@_+0),@_);
	$self->{isStreaming}=1;
	
	$self->_syncStream();
}

=item $robot->pauseStream()

Pauses the sensor data stream.

=cut

sub pauseStream($) {
	my $self=shift;
	
	$self->writeBytes(150,0);
	$self->{isStreaming}=0;
}

=item $robot->resumeStream()

Resumes a previously paused sensor stream.

=cut

sub resumeStream($) {
	my $self=shift;
	
	$self->writeBytes(150,1);
	$self->{isStreaming}=1;
}

=item $robot->getStreamFrame()

Gets one frame of sensor data, updates sensor data hash, and triggers any sensor listeners or events.
Should be called at least once every 15ms.  Method will block
until one frame of sensor data has been read.

See OI Documentation for more details.

=cut

sub getStreamFrame($) {
	my $self=shift;
		
	my (@data,$readBytes);
	
	if ($self->{isStreaming}) {
		while ($data[0]!=19) {
			$readBytes=$self->readData(2);
			@data=unpack('CC',$readBytes);
		
		
			print "Read bytes: " . join(", ",@data) . "\n" if ($DEBUG);
			if ($data[0]!=19) {
				print "Stream lost.  Attempting to re-sync.\n";
				$self->_syncStream();
			}
		}
		
		my $packetLength=$data[1];
		
		$readBytes=$self->readData($packetLength+1);
		print "Read bytes: " . join(", ",unpack('C*',$readBytes)) . "\n" if ($DEBUG);
		
		my $i=0;
		my @sensorIds;
		while($i<$packetLength) {
			my $sensorId=unpack('C',substr($readBytes,$i,1));
			$i++;
			
			my ($readLength, $packString)=@{$sensorSpecs->[$sensorId]};
			
			my @data=unpack($packString,substr($readBytes,$i,$readLength));
			_updateSensorState($sensorId,$self->{sensorState},$self->{slipFactor},@data);
			
			push @sensorIds,$sensorId;
			
			$i+=$readLength;
		}
		$self->_triggerSensorEvents(\@sensorIds);
		
	}
	
}

=item $robot->addSensorListener($priority,$action,$param)

Adds a sensor listener.  This listener will be called whenever sensor data is retrieved, either as a group
such as when $robot->refreshSensors or $robot->getStreamFrame is called or when individual sensors
are retrieved using $robot->getSensors.

The priority parameter is used to determine the order in which listeners are called.  Lower priorities are called first.
Any listeners with a negative priority will be called before indirect sensors (dead reckoning) is calculated.  Listeners with
a priority less than 200 will be called before triggers for waitDistance, waitAngle, etc. events are called.

On each sensor data retrieval &$action($robot,$listener,$sensorIds) will be called.  $sensorIds is a array ref containing the read sfensorIds. 
$listener is a hash containing the following keys:

=over 5

=item id:
listener id -- used to remove listener

=item priority:
listener priority -- do not changed this value

=item action:
the function being called

=item param:
the value of $param passed to addSensorListener

=back

The same hash ref is returned with each call, so this can be used by the action callback to store values.

Additionally, setting $listener->{stop} to true will prevent listeners with a higher priority value from executing.  This is useful for listeners
which implement safeties.

$robot->addSensorListener returns the listener id.  This can be used to remove the listener later.

=cut

sub addSensorListener($$$$) {
	my $self=shift;
	my $id=$self->{nextListenerId};
	my $priority=shift;
	my $action=shift;
	my $param=shift;
	
	$self->{nextListenerId}++;
	
	my $newSensorListener={id=>$id, priority=>$priority, action=>$action,param=>$param};
	
	my $sensorListeners=$self->{sensorListeners};
	
	my $added=0;
	for(my $i=0;!$added && $i<@{$sensorListeners};$i++) {
		if (($sensorListeners->[$i]{priority}) > $priority) {
			splice(@{$sensorListeners},$i,0,$newSensorListener);
			$added=1;
		}
	}
	
	push @{$sensorListeners},$newSensorListener unless ($added);
	
	return $id;
}

=item $robot->removeSensorListener($id)

Remove listener or event with $id.

=cut

sub removeSensorListener($$) {
	my $self=shift;
	my $id=shift;
	
	for(my $i=0;$i<@{$self->{sensorListeners}};$i++) {
		if ($self->{sensorListeners}[$i]{id}==$id) {
			splice(@{$self->{sensorListeners}},$i,1);
			last;
		}
	}
}


=item $robot->addSensorEvent($priority,$test,$action,$param,$oneTime)

Executes &$test($robot,$listener,$sensorIds) each time sensor data is retrieved.  $listener
is a hash reference (see addSensorListener).  $sensorIds is the array ref containing ids of the sensors read.  &$action($robot,$listener,$sensorIds)
is called if $test returns true. $param is included in the $listener hash ref.  If $oneTime is true, the created listener is
automatically removed the first time $test returns true.

As with addSensorListener, setting $listener->{stop} to true will stop further listeners and events from processing.

This method returns an id which can be passed to removeSensorListener to remove the event.

=cut

sub addSensorEvent($$$$$$) {
	my ($self,$priority,$test,$action,$param,$oneTime)=@_;
	
	my $eventListener=sub {
		if (&$test(@_)) {
			$_[0]->removeSensorListener($_[1]->{id}) if ($oneTime);
			return &$action(@_);
		} else {
			return 1;
		}
	};
	
	return $self->addSensorListener($priority,$eventListener,$param);
}

=item $robot->runEvery($priority,$time,$callback)

Creates a sensor event with $priority that calls &$callback($robot) every $time seconds.  Returns an id
that can be passed to removeSensorListener.

=cut

sub runEvery($$$$) {
	my ($self,$priority,$time,$callback) = @_;
	
	my $test=sub {
		my $self=shift;
		my $listener=shift;
		
		if (time()>$listener->{param}) {
			$listener->{param}+=$time;
			return 1;
		} else {
			return 0;
		}
	};
	
	return $self->addSensorEvent($priority,$test,$callback,time(),0);
}

=item $robot->waitDistance($priority,$distance,$callback)

Creates a one time sensor event with $priority that calls &$callback($robot) once the robot has traveled $distance mm.
Distance must be positive.  Distances traveled in reverse will be used in determining total distance traveled.
Returns an id that can be passed to removeSensorListener.

I<NOTE: if this method is called while in scripting mode, $priority and $callback are ignored and the scriptWaitDistance will be executed instead.  (See scripting section below.)>

=cut

sub waitDistance($$$) {
	my $self=shift;
	
	if ($self->{scriptMode}) {
		my $distance=shift;
		
		$self->scriptWaitDistance($distance);
	} else {
		my $priority=shift;
		my $distance=shift;
		my $callback=shift;
		
		my $listener=sub ($$$) {
			my ($self,$listener,$sensorId)=@_;
			
			$listener->{param}-=abs($self->{sensorState}{distance});
			
			if ($listener->{param}<0)  {
				$self->removeSensorListener($listener->{id});
				&$callback($self) if ($callback);
			}
			
			return 1
		};
		
		return $self->addSensorListener(200,$listener,$distance);
	}
}

=item $robot->waitAngle($priority,$angle,$callback)

Creates a one time sensor event with $priority that will call &$callback($robot) after robot has turned $angle radians in either direction.
$angle must be positive.  Turns in either direction will be used to determine total angle turned.
Returns an id that can be passed to removeSensorListener.

I<NOTE: if this method is called while in scripting mode,  $priority and $callback are ignored and the scriptWaitAngle will be executed instead.  (See scripting section below.)>

=cut

sub waitAngle($$$$) {
	my $self=shift;
	
	if ($self->{scriptMode}) {
		my $angle=shift;
		
		$self->scriptWaitAngle($angle);
	} else {
		my $priority=shift;
		my $angle=shift;
		my $callback=shift;
		
		my $listener=sub ($$$) {
			my ($self,$listener,$sensorId)=@_;
			
			$listener->{param}-=abs($self->{sensorState}{actualAngle});
			#print "Angle: " . $listener->{param} . "\n";
			
			if ($listener->{param}<0)  {
				$self->removeSensorListener($listener->{id});
				&$callback($self) if ($callback);
			}
			
			return 1;
		};
		
		return $self->addSensorListener(200,$listener,abs($angle));
	}
}

=item $robot->waitTillFacing($priority,$direction,$maxDelta,$callback)

Creates a one-time sensor event with priority $priority that will call &$callback($robot) when robot is
within $maxDelta of absolute direction $direction (in radians).  0 radians is the direction the robot was facing
when last $robot->init or $robot->markOrigin was called.  $direction should be between -PI and PI.
Returns an id that can be passed to removeSensorListener.


=cut

sub waitTillFacing($$$$) {
	my $self=shift;
	my $priority = shift;
	my $direction=shift;
	my $maxDelta=shift;
	my $callback=shift;
	
	return $self->addSensorEvent($priority,
		sub {
			return (abs($self->{sensorState}{direction}-$direction)<$maxDelta);
		},
		$callback,
		0,
		1
	);
}

=item $robot->waitTime($priority,$time,$callback)

Creates a one-time sensor event with priority $priority that will call &$callback($robot) after $time seconds.
Returns an id that can be passed to removeSensorListener.

I<NOTE: if this method is called while in scripting mode,  $priority and $callback are ignored and the scriptWaitTime will be executed instead.  (See scripting section below.)>

=cut

sub waitTime($$$) {
	my $self=shift;
	
	if ($self->{scriptMode}) {
		my $time=shift;

		$self->scriptWaitTime($time);
	} else {
		my $priority=shift;
		my $time=shift;
		my $callback=shift;
		
		return $self->addSensorEvent($priority,sub {return (time()>$_[1]->{param});},$callback,time()+$time,1);
	}
}

=item $robot->markOrigin()

Sets the robot's current position as (0,0) and the direction the robot is currently facing as 0.

=cut

sub markOrigin($) {
	my $self=shift;
	
	$self->{sensorState}{x}=0;
	$self->{sensorState}{y}=0;
	$self->{sensorState}{direction}=0;
}

=item $robot->setPosition($x,$y,$direction)

Sets the robots current position as ($x,$y) and the direction $direction (in radians).  0 is along the +y axis.

=back

=cut

sub setPosition($$$$) {
	my $self=shift;
	
	$self->{sensorState}{x}=shift;
	$self->{sensorState}{y}=shift;
	$self->{sensorState}{direction}=shift;
	
}

sub _triggerSensorEvents($$) {
	my $self=shift;
	my $sensorIds=shift;

	my $sensorListener;
	foreach $sensorListener (@{$self->{sensorListeners}}) {
		$sensorListener->{stop}=0;
		&{$sensorListener->{action}}($self,$sensorListener,$sensorIds);
		last if ($sensorListener->{stop});
	}
	
}

sub _readSensorData($$) {
	my $self=shift;
	my $sensorId=shift;
	
	my ($readLength, $packString)=@{$sensorSpecs->[$sensorId]};
	
	my $readBytes=$self->readData($readLength);

	print "Read $readLength bytes: " . join(', ',unpack('C*',$readBytes)) . "\n" if ($DEBUG);

	my @data=unpack($packString,$readBytes);
	
	_updateSensorState($sensorId,$self->{sensorState},$self->{slipFactor},@data);
	
	return @data;
}

sub _syncStream($) {
	my $self=shift;
	
	my $synched=0;
        
        while(!$synched) {
                my $buffer='';
                my $checksum=19;
                my $read='';
        

                while (ord($buffer)!=19) {
                        $buffer=$self->readData(1);
                }

		
                $read.=$buffer;
                $buffer=$self->readData(1);
		
		my $count=ord($buffer);
                $checksum+=$count;
                $read.=$buffer;
                
                $buffer=$self->readData($count + 1);
                
                $read.=$buffer;
                my @buffer=unpack('C*',$buffer);
                
                my $byte;
                foreach  $byte (@buffer) {
                        $checksum+=$byte;
		}
		
		$synched=(($checksum & 255)==0);

                substr($read,0,1,'') unless ($synched);

                $self->{readBuffer}=$read . $self->{readBuffer};
		
	}
	
	$self->logTelemetry(16);
}		

=head2 Display

=over 4

=item $robot->getSensorString()

Returns a string listing each sensor value from the sensor state hash.

=cut

sub getSensorString($) {
	my $self=shift;
	
	my $sensorState=$self->{sensorState};
	my $c=0;
	my $output='';
	my @keys=sort keys %{$self->{sensorState}};
	
	foreach my $key (@keys) {
		$output .= $key . ": " . ($key eq 'direction'?rad2deg($sensorState->{$key}):$sensorState->{$key}) . ((($c % 4)==3) ? "\r\n" : "\t");
		$c++;
	}
	return "$output---------------------------------\n";
}

=item $robot->getCondensedString()

=item $robot->getCondensedString($lineEnding)

Returns a string condensed version of the current state of the robots sensors.  Suitable for output in a command line
program.

Example:

	Bu Bp Cliff  DIn  AIn  Chrg Wl Whl   Oc  Sng Md
	AP LR LFlFrR 0123 0704 HbIn AV LCR 012LR P00 1
	Batt: 2606/2702 +1087@17200 (32) C Ir: 254
	(+00003,+00052) -002  DGFR      
	Cliff: 0000 0000 00000 00000 Wall: 00000

In the first 2 lines, Bu shows the status of the buttons on the robot.  In the example above both the Advance and Play
Buttons are pressed.  Bp shows the status of the left (L) and right (R) bump sensors.  Cliff shows the status of left (L),
front-left (Fl), front-right (Fr), and right (R) sensors.  DIn shows the state of the 4 digital inputs, AIn shows the value of
the analog input.  Chrg shows if charging is available from the home base (Hb) or internal (In) chargers.
Wl shows the state of the actual (A) and virtual (V) wall sensors.  Whl shows the state of the left (L),
caster (C), and right (R) wheeldrop sensors.  Oc shows the state of the overcurrent sensors for the 3 low side drivers, 
(0-2) and the left (L) and right (R) wheels.  Sng indicates is a song is playing (P) and the currently selected song bank.
Md shows the current mode number.

The battery line shows the battery charge and maxium capacity, the current and voltage flowing from the battery, 
the battry temperature, the charging state.  Also, the byte recieved by the IR sensor is shown on this line.   In the example above,
the battery has charge of 2606 mAh out of a maximum capacity of 2702 mAh.  The battery is charging at 1087 mA and 17200 mV.
Positive current values indicate charging, negative ones indicate discharge.  The battery temperature is 32 degrees C.  The C indicates
the battery is charging.  The IR sensor is receiving byte 254.

The fourth line shows the estimated x and y position in mm, and the current direction in degrees.  Also shown is any docking
indicators: dock present (D), green beacon (G), force field (F), red beacon (R).

The last line indicates the raw signal values of the four cliff sensors (left, front-left, front-right, and right) and the wall
sensor.

=back

=cut

sub getCondensedString($) {
	my $self=shift;
	my $endLine = shift || "\n";
	
	my $sensorState=$self->{sensorState};
	my $inputs='';
	for(my $i=0;$i<4;$i++) {
		$inputs.=($sensorState->{'digitalInput' . $i}?$i:' ');
	}
	my $ocLDs='';
	for(my $i=0;$i<3;$i++) {
		$ocLDs.=($sensorState->{'ocLD' . $i}?$i:' ');
	}
	my @dock=$self->getDockSignal();
	
	return "Bu Bp Cliff  DIn  AIn  Chrg Wl Whl   Oc  Sng Md$endLine"
		.($sensorState->{playButton}?'P':' ') . ($sensorState->{advanceButton}?'A':' ') .' '
		.($sensorState->{bumpLeft}?'L':' ').($sensorState->{bumpRight}?'R':' ') . ' '
		.($sensorState->{cliffLeft}?'L':' ').($sensorState->{cliffFrontLeft}?'Fl':'  ')
		.($sensorState->{cliffFrontRight}?'Fr':'  ') .($sensorState->{cliffRight}?'R':' ') . ' '
		.$inputs
		.' '
		.sprintf("%0*s ",4,$sensorState->{analogIn})
		.($sensorState->{homeBaseAvailable}?'Hb':'  ').($sensorState->{internalCharger}?'In':'  ') . ' '
		.($sensorState->{wall}?'A':' ').($sensorState->{virtualWall}?'V':' ') . ' '
		.($sensorState->{wheeldropLeft}?'L':' ').($sensorState->{wheeldropCaster}?'C':' ')
		.($sensorState->{wheeldropRight}?'R':' ') . ' '
		.$ocLDs
		.($sensorState->{ocLeftWheel}?'L':' ').($sensorState->{ocRightWheel}?'R':' ') . ' '
		.($sensorState->{songPlaying}?'P':' ').sprintf("%0*d ",2,$sensorState->{songNumber})
		.$sensorState->{oiMode}.$endLine
		.sprintf("Batt: %0*d/%0*d %+0*d@%0*d (%0*d) ",4,$sensorState->{batteryCharge},
			4,$sensorState->{batteryCapacity},5,$sensorState->{current},
			5,$sensorState->{voltage},2,$sensorState->{batteryTemp})
		.($sensorState->{chargingState}?'C ':'  ')
		.sprintf("Ir: %0*d",3,$sensorState->{irByte})
		.$endLine
		.sprintf("(%+0*d,%+0*d) %+0*d  ",6,$sensorState->{x},
			6,$sensorState->{y},
			4,rad2deg($sensorState->{direction}))
		.($dock[0]?'D':' ').($dock[1]?'G':' ').($dock[2]?'F':' ').($dock[3]?'R':' ').$endLine
		.sprintf("Cliff: %0*d %0*d %0*d %0*d Wall: %0*d",
			4,$sensorState->{cliffLeftSignal},
			4,$sensorState->{cliffFrontLeftSignal},
			5,$sensorState->{cliffFrontRightSignal},
			5,$sensorState->{cliffRightSignal},
			5,$sensorState->{wallSignal})
		.$endLine;
}



###########Utility functions################
sub _convertFSS($) {
	unpack('C2',pack('n!',shift()));
}

sub _normalizeAngle($) {
	my $angle=shift;
	$angle=fmod($angle,pi2);
	$angle+=pi2 if ($angle<0);
	$angle-=pi2 if ($angle>pi);
	return $angle;
}

#############Scripting commands####################
=head2 Scripting

These commands make use of the builtin scripting functionality of the iRobot create.

See OI Documentation for more details.

=over 4

=item $robot->startScript()

Puts robot in scripting mode.  Subsequent commands will not be sent to robot,
but instead be saved to robots script memory.  Create can store a maximum of 100 bytes
of scripting commands.

=cut

sub startScript($) {
	my $self=shift;
	
	$self->{scriptMode}=1;
	$self->{scriptBytes}=[];
}

=item $robot->runScript()

Runs the script currently stored in robot.  This will cause the robot to go into passive mode
and not respond to commands until script is complete.

=cut

sub runScript($) {
	my $self=shift;
	
	$self->writeBytes(153);
}

=item $robot->repeatScript()

If called while in scripting mode, causes script to repeat from begining.

=cut

sub repeatScript($) {
	my $self=shift;
	
	$self->runScript();
}

=item $robot->scriptMode()

Returns true if currently in scripting mode, false otherwise.

=cut

sub scriptMode($) {
	my $self=shift;
	
	return $self->{scriptMode};
}

=item $robot->cancelScript()

Leaves scripting mode without writing script to robot.

=cut

sub cancelScript($) {
	my $self=shift;
	
	$self->{scriptMode}=1;
}

=item $robot->endScript()

Leaves scripting mode and writes script to robot.

=cut

sub endScript($) {
	my $self=shift;
	
	$self->{scriptMode}=0;
	my $scriptBytes=$self->{scriptBytes};
	
	$self->writeBytes(152,(@{$scriptBytes}+0),@$scriptBytes);
}


=item $robot->scriptWaitTime($time)

Waits $time seconds (rounded to nearest tenth).  Robot will not respond to commands during this time.
Not recommended to be used outside of scripting mode.

=cut

sub scriptWaitTime($$) {
	my $self=shift;
	my $timeSecs=shift;
	
	$self->writeBytes(155,int($timeSecs*10));
}

=item $robot->scriptWaitDistance($distance)

Waits until robot travels $distance mm.  Robot will not respond to commands during this time.
Not recommended to be used outside of scripting mode.

=cut

sub scriptWaitDistance($$) {
	my $self=shift;
	my $distance=shift;
	
	$self->writeBytes(156,_convertFSS($distance));
}

=item $robot->scriptWaitAngle($angle)

Waits until robot turns through $angle degrees.  Robot will not respond to commands during this time.
Not recommended to be used outside of scripting mode.

=cut

sub scriptWaitAngle($$) {
	my $self=shift;
	my $angle=shift;
	
	$self->writeBytes(157,_convertFSS($angle));
}

=item $robot->waitEvent($eventId)
=item $robot->scriptWaitEvent($eventId)

Waits until event with id $eventId occurs.  Robot will not respond to commands during this time.
Not recommended to be used outside of scripting mode.

See OI Documentation for list of event ids.

=back

=cut

sub waitEvent($$) { scriptWaitEvent(@_); }
sub scriptWaitEvent($$) {
	my $self=shift;
	my $event=shift;
	
	$self->writeBytes(158,$event);
}

#######Telemetry############
=head2 Telemetry

This module has the ability to record telemetry data containing bytes sent to and from robot.  And any debuging
data that can be provided by client programs.

=over 4

=item $robot->startTelemetry($file,$overwrite)

Begins writing telemetry data to $file.  Appends data unless $overwrite is true.

=cut

sub startTelemetry($$$) {
	my $self=shift;
	my $file=shift;
	my $overwrite=shift || 0;
	
	if (!$self->{telem}) {
		open my $telem,">" . ($overwrite?'':'>') .$file;
		$self->{telem}=$telem;
		
		print $telem pack("QAC",int(time*1000),"B",0);
	}
}

=item $robot->stopTelemetry()

Stops recording telemetry data.

=cut

sub stopTelemetry($) {
	my $self=shift;
	
	if ($self->{telem}) {		
		print {$self->{telem}} pack("QAC",int(time*1000),"E",0);
	}
	
	$self->{telem}=0;

}

=item $robot->logTelemetry($type,$data)

Write client application provided data to telemetry file.  The $type value should use the following specification
for maxium compatibility with other applications.  $data can be any binary value.

	Types:
		0- indirect sensor field
		16 - stream sync indicator
		32 - 63 -- reserved for client UI
			32 - key press
		64-127 -- Debug info
			64 - general debug
		255 - String message

=back

=cut

sub logTelemetry($$$) {
	my $self=shift;
	my $type=shift;
	my $data=shift || '';

	$self->_writeTelem('M',chr($type) . $data);
}

sub _readTelem($) {
	my $self=shift;
 
	my ($bytes,$data,$time,$type,$length,$tdata,$timeLow,$timeHigh);
	
	$length=10;

	$data='';
	while($length>0) {
		$bytes=read $self->{replay}, $tdata,$length;
		return (0,'E','') unless ($bytes);
		$length-=$bytes;
		$data.=$tdata;
	}
 
	($timeLow,$timeHigh,$type,$length)=unpack("LLAC",$data);
	
	$time=($timeHigh * 0xFFFFFFFF) + $timeLow;

	$data='';
	while($length>0) {
		$bytes=read $self->{replay}, $tdata, $length;
		return (0,'E','') unless ($bytes);
		$length-=$bytes;
		$data.=$tdata;
	}

	return ($time/1000,$type,$data);
}

sub _writeTelem($$$) {
	my $self=shift;
	my $type=shift;
	my $data=shift;
	
	my $time=int(time()*1000);
	my $timeLow=$time & 0xFFFFFF;
	my $timeHigh=$time >> 32;
	
	print {$self->{telem}} pack("LLACa*",$timeLow,$timeHigh,$type,length($data),$data) if ($self->{telem});
}

=head2 Sensor Calibration

Sensor calibration can be used to correct for some inconsistancies and inaccuracies of the robot.  2 sets of sensors can be calibrated.

The first is the angle sensor.  This sensor is supposed to return the angle turned in degrees since the last sensor reading.  In practice it
is extremely inaccurate.  The accuracy can be some what improved by calculating the ratio between actual angle turned and angle reported
at different velocities and then applying this ratio to read sensor values.  This corrected value can be seen in the actualAngle and totalActualAngle
indirect sensors.

The second set are the cliff signal sensors.  These sensors report the IR reflectivity of 4 sections of floor near the front of the robot.
These values could be used for example, to follow a dark line drawn on the ground.
The sensors tend to be accurate individually, but each sensor will have a slightly different bias-- meaning each sensor will read the same
section of floor differently.  To correct for this we can generate statistics describing the range of values seen by each sensor
over the same section of floor.  We can then use this to determine the distance from the mean in standard deviations for
a value read by a particular sensor based on the previous values read for that sensor.  This value should be the same for each sensor
when reading the same section of floor.  These values are seen in the cliff...SignalDev indirect sensors.

Once these calibration data are created.  They can be saved and retrieved using the saveCalibrationData and loadCalibrationData methods.

Note: default calibration values are provided, these were generated from calibration of my robot on my carpet.  However, it is strongly
recommended to calibrate your own robot and create a calibration file for each type of flooring on which you plan to operate the robot.  The
type of flooring will change both the wheel slipage and IR reflectivity, so both the angle and cliff signal sensors will need to be recalibrated.


See section Indirect sensors for more information.

=over 4

=item $robot->loadCalibrationData($file)

Loads saved calibration file from $file or calibration.yaml if no file is given.  This is called automatically on initialization.  So, it is only
necessary if you wish to load calibration data from another file.

=cut

sub loadCalibrationData($$) {
	my $self=shift;
	my $file=shift || 'calibration.yaml';
	
	my $calibData=YAML::Tiny->read($file);
	
	$self->{calibration}=$calibData->[0] if ($calibData);
}

=item $robot->saveCalibrationData($file)

Saves calibration data to $file or calibration.yaml if no file is given.  

=cut

sub saveCalibrationData($$) {
	my $self=shift;
	my $file=shift || 'calibration.yaml';
	
	my $calibData=YAML::Tiny->new;
	
	$calibData->[0]=$self->{calibration};
	
	$calibData->write($file);
}

=item $robot->calibrate($sensor)

Calibrates indirect sensors.  Method will block until calibration is complete.  Robot will go though several complete rotations.
Be sure to follow any instructions in calicration proceedure below.  Returns true on calibration success, false otherwise.
$sensor can be one of the following:

=over 5

=item actualAngle:
Calibrates actualAngle correction factors for dead reckoning

=item cliffDev:
Calibrates cliffSignalDev sensors

=item all:
Calibrates all sensors.

=back

Calibration procedure: For cliffDev, the robot needs only to be on the type of surface it will be used on most often.  For actualAngle, the
procedure is more complicated.  A "Home Base" docking station and a way to block of part of the robots IR sensor is required.  Block all but a small
section in the front of the IR Sensor.  I usually do this with a strip of aluminum foil.  Then place the robot a few feet away from the docking station and
in a position so that the docking station can only be seen though the small gap you left in the IR sensor.

Note:  You will need to call $robot->saveCalibrationData afterwards to save calibration to file.

=cut

sub calibrate($$) {
	my $self=shift;
	my $sensor=shift;
	
	my $wasStreaming=$self->{isStreaming};
	my @calibration;
	
	my $seeDock=sub { ($self->getDockSignal())[0]; };
	my $notSeeDock=sub { !(($self->getDockSignal())[0]); };
	
	if ($sensor eq 'actualAngle' || $sensor eq 'all') {
		
		if ($sensor eq 'all') {
			$self->{gatherCliffStatistics}=1;
			$self->{calibration}{cliffStatistics}={};
		}
		
		my $rejectCount=0;
		
		my $testSpeed=100;
	
		while ($testSpeed<=500) {
			my ($startAngle,$endAngle);
	
			$self->rotateLeft(200);
			
			$self->addSensorEvent(50,$seeDock,
				sub {
					$self->waitTime(50,1,sub {
						$self->addSensorEvent(50,$notSeeDock,
							sub {
								$self->waitTime(50,1,sub {
									$self->stop();
									$self->waitTime(50,2,sub {
										$self->rotateRight($testSpeed);
										$self->addSensorEvent(50,$seeDock,
											sub {
												$startAngle=$self->{sensorState}{totalAngle};
												
												$self->addSensorEvent(50,$notSeeDock,
													sub {
														$self->addSensorEvent(50,$seeDock,
															sub {
																$endAngle=$self->{sensorState}{totalAngle};
																$self->exitSensorLoop();
															}
														,0,1);
													}
												,0,1);
											}
										,0,1);
									});	
								});
							}
						,0,1);
					});
				}
			,0,1);

			$self->runSensorLoop();

			my $testAngle=($startAngle-$endAngle)*($testSpeed<=>0);
		
			if ($testAngle<400 && $testAngle>200) {
				push @calibration,(2*pi)/$testAngle;
				
				if ($testSpeed==100) {
				for (my$i=0;$i<2;$i++) {
					push @calibration,(2*pi)/$testAngle;
				}
			}
				
				$testSpeed+=50;
			} else {
				$rejectCount++;
				return 0 if ($rejectCount>5);
			}
		}

		$self->stop();
		
		sleep 2;
		
		$self->{calibration}{angleCorrection}=\@calibration;
	}
	
	if ($sensor eq 'cliffDev') {
		$self->{calibration}{cliffStatistics}={};
		$self->{gatherCliffStatistics}=1;
		
		$self->waitAngle(50,4*pi,sub { $self->exitSensorLoop(); });
		
		$self->rotateLeft(200);
		
		$self->runSensorLoop();
		
		$self->stop();
	}
	
	$self->{gatherCliffStatistics}=0;
	
	
	$self->startStream(6) if ($wasStreaming);
	
	return 1;
	
}

=item $robot->setMovementCorrectionMode($mode)

Sets the movementCorrection method used by the module.  Can be one of the following:

=over 5

=item calibration:
(default) Uses result of calibration to correct reported sensor values. This works best when robot is limited to straight movement and rotation in place.  See Sensor Calibration.

=item time:
Ignores angle sensor values and relies solely on requested movement and time.

=item robot:
Trusts value reported by robot angle sensor is accurate.  Assumes
sensor value is difference between distance traveled by left wheel
and distance travel by right wheel.  (This seems to actually be the case.)

=item raw:
Trusts value reported by robot angle sensor is accurate.  Assumes
sensor value is degrees rotated.  (This is the value reported by the OI
doc, but does not actually seem to be the case.)

=back

I<<Or>> you can pass your own sub to perform movement correction.  When called it will be passed $robot, $listener, and $sensorIds.
$sensorIds is a array ref containing the read sensorIds. $listener is a hash containing the details of the sensor listener used to calculate
indirect sensor values.  See addSensorListener for more details.  The sub must return a list containing actual distance traveled in mm
followed by actual angle rotated in radians.

=back

=cut

sub setMovementCorrectionMode($$) {
	my $self=shift;
	my $deadReckoner=shift;

	if ($deadReckoner eq 'calibration') {
		$deadReckoner=\&_correctiveDeadReckoning;
	} elsif ($deadReckoner eq 'time') {
		$deadReckoner=\&_timeDeadReckoning;
	} elsif ($deadReckoner eq 'robot') {
		$deadReckoner=\&_robotDeadReckoning;
	} elsif ($deadReckoner eq 'raw') {
		$deadReckoner=\&_rawDeadReckoning;
	} 
	
	$self->{deadReckoning}=$deadReckoner;
	
}

=head2 Closing Connection

=over 4

=item $robot->close()

Stops the robot motion and sensor streaming and closes communication port.

=back

=cut


sub close($) {
	my $self=shift;
	
	$self->stop();
	
	$self->stopTelemetry if ($self->{telem});
	
	if ($self->{replay}) {
                close $self->{replay};
        } else {
                $self->{port}->close();
        }

}

=head1 SENSORS

The sensor state hash can be retrieved from the $robot->getSensorState() method.  This only need be retrieved once
as subsequent updates will be made to the same hash.  Each direct and indirect sensor reading can be retrieved from this
hash using the keys below.

=head2 Direct Sensors

These are sensor values that are read directly from the robot.

=head3 Keys

=over 5

=item wheeldropCaster --
wheeldrop sensor on front caster (boolean)

=item wheeldropLeft --
wheeldrop sensor on left wheel (boolean)

=item wheeldropRight --
wheeldrop sensor on right wheel (boolean)

=item bumpLeft --
left bump sensor (boolean)

=item bumpRight --
right bump sensor (boolean)

=item wall --
physical wall sensor (boolean)

=item cliffLeft --
left cliff sensor (boolean)

=item cliffFrontLeft --
front-left cliff sensor (boolean)

=item cliffFrontRight --
front-right cliff sensor (boolean)

=item virtualWall --
virtual wall sensor (boolean)

=item ocLeftWheel --
overcurrent on left wheel (boolean)

=item ocRightWheel --
overcurrent on right wheel (boolean)

=item ocLD0 --
overcurrent on low side driver 0 (boolean)

=item ocLD1 --
overcurrent on low side driver 1 (boolean)

=item ocLD2 --
overcurrent on low side driver 2 (boolean)

=item irByte --
byte received by IR sensor (unsigned byte)

=item advanceButton --
advance button state (boolean)

=item playButton --
play button state (boolean)

=item distance --
distance travelled in mm since last sensor refresh (signed short)

=item angle --
angle turned in degrees since last sensor refresh (signed short)
	
	positive angles are counter-clockwise
	negative are clockwise
	NOTE: This sensor is extremely inaccurate (see actualAngle)

=item chargingState --
indicates if robot is charging (boolean)

=item voltage --
voltage of battery (unsigned short)

=item current --
current of battery charge/discharged (signed short)
	
	positive values indicate charging
	negative indicate discharging

=item batteryTemp --
temperature of battery in degrees C (unsigned byte)

=item batteryCharge --
current battery charge in mAh (unsigned short)

=item batteryCapacity --
maximum battery capacity in mAh (unsigned short)

=item wallSignal --
raw signal value of wall sensor (unsigned short)

=item cliffLeftSignal --
raw signal value of left cliff sensor (unsigned short)

=item cliffFrontLeftSignal --
raw signal value of front-left sensor (unsigned short)

=item cliffFrontRightSignal --
raw signal value of front-right cliff sensor (unsigned short)

=item cliffRightSignal --
raw signal value of right cliff sensor (unsigned short)

=item deviceDetect --
state of robot's device detect pin (boolean)

=item digitalInput0 --
state of digital input 0 (boolean) 

=item digitalInput1 --
state of digital input 1 (boolean) 

=item digitalInput2 --
state of digital input 2 (boolean) 

=item digitalInput3 --
state of digital input 3 (boolean) 

=item analogIn --
value of analog input (unsigned short)

=item homeBaseAvailable --
true if robot is connected to home base (boolean)

=item internalCharger --
true if robot can charge battery using internal charger (boolean)

=item oiMode --
OI Interface mode (unsigned byte)

=item songNumber --
last selected song bank (unsigned byte)

=item songPlaying --
true if song is playing (boolean)

=item numPackets --
number of packets sent in last stream (byte)

=item requestedVelocity --
last requested velocity (signed short)

=item requestedRadius --
last requested turning radius (signed short)

=item requestedRightVelocity --
last requested right wheel velocity (signed short)

=item requestedLeftVelocity --
last requested left wheel velocity (signed short)

=back

=head2 Indirect Sensors

These are sensor values that are derived from direct sensors.

=head3 Keys

=over 5

=item totalAngle --
sum of all previous angle readings

=item totalDistance --
sum of all previous distance readings

=item lastSensorReading --
Timestamp in seconds of last reading

=item deltaT --
time in seconds since last reading

=item deltaX --
change in x coordinate since last reading

=item deltaY --
change in y coordinate since last reading

=item x --
x coordinate of current position

=item y --
y coordinate of current position

=item direction --
direction robot is currently facing in radians (between -PI and PI)

=item actualAngle --
an attempt to correct angle sensor; the actual angle turned in radians

=item totalActualAngle --
sum of all previous actual angle readings

=item actualDistance --
an attempt to correct distance sensor; the distance traveled in mm

=item totalActualDistance --
an attempt to correct distance sensor; the distance traveled in mm

=item turningRadius --
estimated actual turning radius

=item cliffFrontSignalDelta, cliffFrontRightSignalDelta,
	cliffLeftSignalDelta, cliffFrontLeftSignalDelta --
change in cliff sensors since last reading

=item cliffFrontSignalDev, cliffFrontRightSignalDev,
	cliffLeftSignalDev, cliffFrontLeftSignalDev --
difference from mean of current cliff sensor
		value in standard deviations

=back

=head1 DEAD RECKONING

This module attempts to do some sensor correction and dead reckoning using sensor readings.

=head2 Coordinate System

When the $robot->new or $robot->markOrigin is called.  The x,y, and direction values of the robot
are set to 0.  The robot is then assumed to be facing along the positive y-axis (direction 0).  The positive x-axis is
90 clockwise.  Positive directions are counter-clockwise, negative directions are clockwise.

=head2 Sensor Correction

An attempt is made to correct inaccurate angle readings.  The correction is done using error factors determined
experimentally on a Create.  Your mileage may vary.

It is recommended that you calibrate your robot using the calibrate method before relying on dead reckoning.

=cut

sub _updateSensorState($$$@);
sub _updateSensorState($$$@) {
	my $sensorId=shift;
	my $sensorState=shift;
	my $slipFactor=shift;
	my $data=$_[0];

	if ($sensorId<7) {
		my $sensorGroup=$sensorGroups->[$sensorId];
		my $start=$sensorGroup->[0];
		my $end=$sensorGroup->[1];
		for(my $i=0;$i<=($end-$start);$i++) {
			_updateSensorState($i+$start,$sensorState,$slipFactor,$_[$i]);
		}
	} elsif ($sensorId==7) {
		$sensorState->{wheeldropCaster}=(($data&16)>>4);
		$sensorState->{wheeldropLeft}=(($data&8)>>3);
		$sensorState->{wheeldropRight}=(($data&4)>>2);
		$sensorState->{bumpLeft}=(($data&2)>>1);
		$sensorState->{bumpRight}=$data&1;
	} elsif ($sensorId==14) {
		$sensorState->{ocLeftWheel}=($data&16)>>4;
		$sensorState->{ocRightWheel}=($data&8)>>3;
		$sensorState->{ocLD2}=($data&4)>>2;
		$sensorState->{ocLD1}=($data&2)>>1;
		$sensorState->{ocLD0}=($data&1);
	} elsif ($sensorId==15 || $sensorId==16) {
		#reserved sensor packet ids
	} elsif ($sensorId==18) {
		$sensorState->{advanceButton}=($data&4)>>2;
		$sensorState->{playButton}=($data&1);
	} elsif ($sensorId==32) {
		$sensorState->{deviceDetect}=($data&16)>>4;
		$sensorState->{digitalInput3}=($data&8)>>3;
		$sensorState->{digitalInput2}=($data&4)>>2;
		$sensorState->{digitalInput1}=($data&2)>>1;
		$sensorState->{digitalInput0}=($data&1);
	} elsif ($sensorId==34) {
		$sensorState->{homeBaseAvailable}=($data&2)>>1;
		$sensorState->{internalCharger}=($data&1);
	} else {
		my $sensorField=$sensorFields[$sensorId];
		$sensorState->{$sensorField}=$data;
	}
}

sub _timeDeadReckoning($$$) {
	my $self=shift;
	my $listener=shift;
	my $sensorIds=shift;
	
	my $sensorState=$self->{sensorState};
	
	my $requestedVelocity=$sensorState->{requestedVelocity};
	my $requestedRadius=$sensorState->{requestedRadius};
	my $deltaT=$self->{isStreaming}?$EPSILON:$sensorState->{deltaT};
	
	my $turnDistance=$deltaT*$requestedVelocity;
	my $actualAngle=($requestedRadius<=>0)*$turnDistance/(abs($requestedRadius)+$WHEEL_WIDTH/2);
	my $distance=$sensorState->{distance};
	
	return ($distance,$actualAngle);
}

sub _correctiveDeadReckoning($$$) {
	my $self=shift;
	my $listener=shift;
	my $sensorIds=shift;
	
	my $sensorState=$self->{sensorState};
	
	my $distance=$sensorState->{distance};
	my $angle=$sensorState->{angle};

	my $lastVelocity=$self->{lastVelocity};
	my $angleCorrection=$self->{calibration}{angleCorrection}[int(abs($lastVelocity)/50)];

	my $actualAngle=$angle*$angleCorrection;


	return ($distance,$actualAngle);
	
}

sub _robotDeadReckoning($$$) {
	my $self=shift;
	my $listener=shift;
	my $sensorIds=shift;
	
	my $sensorState=$self->{sensorState};
	
	my $distance=$sensorState->{distance};
	my $angle=$sensorState->{angle};
	
	my $actualAngle= 2* $angle/$WHEEL_WIDTH;
	
	return ($distance,$actualAngle);
}

sub _rawDeadReckoning($$$) {
	my $self=shift;
	my $listener=shift;
	my $sensorIds=shift;
	
	my $sensorState=$self->{sensorState};
	
	my $distance=$sensorState->{distance};
	my $angle=$sensorState->{angle};
	
	my $actualAngle=pi * $angle / 180;
	
	return ($distance,$actualAngle);
}
	

sub _indirectSensors($$$) {
	my $self=shift;
	my $listener=shift;
	my $sensorIds=shift;

	my $sensorState=$self->{sensorState};
	
	my $now=time();
	$sensorState->{deltaT}=$now-$self->{lastSensorRefresh};
	$sensorState->{lastSensorRefresh}=$now;
	
	my $angle=$sensorState->{angle};
	my $direction=$sensorState->{direction};
	
	my ($distance,$actualAngle)=&{$self->{deadReckoning}}($self,$listener,$sensorIds);
	my ($dxf,$dyf)=_getRelativeMovement($actualAngle,$distance);
	my ($dx,$dy)=_getAbsoluteMovement($direction,$dxf,$dyf);
	
		
	$sensorState->{totalAngle}+=$angle;
	$sensorState->{totalDistance}+=$distance;
		
	$sensorState->{deltaX}=$dx;
	$sensorState->{deltaY}=$dy;
	$sensorState->{x}+=$dx;
	$sensorState->{y}+=$dy;
			
	$direction=_normalizeAngle($direction+$actualAngle);
	$sensorState->{direction}=$direction;
	$sensorState->{actualDistance}=$distance;
	$sensorState->{actualAngle}=$actualAngle;
	$sensorState->{totalActualAngle}+=$actualAngle;
	$sensorState->{totalActualDistance}+=$distance;
	my $turningRadius=$actualAngle!=0?$distance/$actualAngle:undef;
	$sensorState->{turningRadius}=$turningRadius;
			
	$self->_updateCliffStatistics() if ($self->{gatherCliffStatistics});
	
	my $lastCliff=$self->{lastCliff};
	
	foreach my $sensor (@cliffSensors) {
		my $signal=$sensorState->{$sensor . 'Signal'};
		$sensorState->{$sensor . 'SignalDev'}=$self->_getCliffDeviation($sensor,$signal);
		$sensorState->{$sensor . 'SignalDelta'}=defined($lastCliff->{$sensor})?$signal-$lastCliff->{$sensor}:0;
		$lastCliff->{$sensor}=$signal;
	}
		
	return 1;
}

sub _getRelativeMovement($$) {
	my ($actualAngle,$distance)=@_;
	
	if ($actualAngle==0) {
		return (0,$distance);
	} else {
		my $turningRadius=$distance/$actualAngle;
		my $dxf=$turningRadius*(1-cos($actualAngle));
		my $dyf=$turningRadius*sin($actualAngle);
		
		return ($dxf,$dyf);
	}
}

sub _getAbsoluteMovement($$$) {
	my ($direction,$dxf,$dyf)=@_;
	
	return ($dyf*sin(-$direction)+$dxf*cos(-$direction),
		   $dyf*cos(-$direction)-$dxf*sin(-$direction));

}

sub _updateCliffStatistics($) {
	my $self=shift;
	my $sensorState=$self->{sensorState};
	my $cliffStatistics=$self->{calibration}{cliffStatistics};
	
	if (!defined($cliffStatistics->{$cliffSensors[0]})) {
		$cliffStatistics={};
		$self->{calibration}{cliffStatistics}=$cliffStatistics;
		
		for my $sensor (@cliffSensors) {
			$cliffStatistics->{$sensor}=[0,0,0];
		}
	}
	
	for my $sensor (@cliffSensors) {
		my $sensorStats=$cliffStatistics->{$sensor};
		my $signal=$sensorState->{$sensor.'Signal'};
		
		$sensorStats->[0]++;
		$sensorStats->[1]+=$signal;
		$sensorStats->[2]+=($signal*$signal);
	}
	
	#print Dump($self->{calibration});
}

sub _getCliffDeviation($$) {
	my $self=shift;
	my $sensor=shift;
	my $signal=shift;
	
	my $sensorStats=$self->{calibration}{cliffStatistics}{$sensor};
	
	my $mean=$sensorStats->[0]?$sensorStats->[1]/$sensorStats->[0]:0;
	my $stddev=$sensorStats->[0]?sqrt($sensorStats->[2]/$sensorStats->[0]-$mean*$mean):1;
	
	return $stddev==0?0:($signal-$mean)/$stddev;
}
	

##########Serial Port Comm##############

=head1 RAW COMMUNICATION

The below methods can be used to for raw communication with the robot.  Use of these within the same application as
the rest of the methods in this module is strongly discouraged.

=over 4

=item $robot->initPort()

Initializes the communications port.  Returns true on success, false otherwise.

=cut

sub initPort($) {
	my $self=shift;
	
	my $port;
	
	my $retries=5;

	while(!$port && $retries>0) {
		$port=Device::SerialPort->new($self->{portFile});
		unless ($port) {
			sleep 1;
			$retries--;
		}
	}
	
	if ($retries>0) {
		$port->databits(8);
		$port->baudrate(57600);
		$port->parity("none");
		$port->stopbits(1);
		$port->read_char_time(0);
		$port->read_const_time(15);

		$self->{port}=$port;
		
		return 1;
	} else {
		return 0;
	}
}

=item $robot->writeBytes(@bytes)

Writes bytes in @bytes to robot.

=cut

sub writeBytes(@) {
	my $self=shift;
	
	if ($self->{scriptMode}) {
		push @{$self->{scriptBytes}}, @_;
	} else {
		print "Writing bytes: " . join(", ",@_) . "\n" if ($DEBUG);
		
		my $data=pack('C*',@_);
		
		$self->_writeTelem('W',$data);

                $self->{port}->write($data) unless ($self->{replay});
        }
}

sub _handleReplayWriteBytes($@) {
	my $self=shift;
}

sub _handleReplayWrite($$$) {
	my $self=shift;
	my $time=shift;
	my $data=shift;
	
	my $command=ord($data);
	
	if ($command==137) {
		my ($command,$velocity,$radius)=unpack('Cn!2',$data);
		$self->{lastVelocity}=$velocity unless ($velocity==0);
		#print "LastVelocity: " . $self->{lastVelocity} . "\n";
	}
}

sub _handleReplayMessage($$$$) {
	my $self=shift;
	my $time=shift;
	my $data=shift;
	
}

sub _readReplayData($) {
        my $self=shift;

        my $replayDelta=$self->{replayDelta};
        
        my ($time,$type,$data);
        
        while($type ne 'R') {
                ($time,$type,$data)=$self->_readTelem();
                die "End of Telemetry Data" if ($type eq 'E');
		if ($type eq 'W') {
			$self->_handleReplayWrite($time,$data);
		} elsif ($type eq 'M') {
			$self->_handleReplayMessage($time,$data);
		}
	}
	
	 my $now=time();
       
	if ($now<($time+$replayDelta)) {
		sleep (($time+$replayDelta)-$now);
	}
        
        return (length($data),$data);
}

=item $robot->readData($length)

Reads $length bytes from robot.  Blocks until bytes are read.  Returns bytes read as string.  

Data returned by this method will probably need to be passed to unpack.  For example, to get an array of 4 bytes from robot use:

	unpack('C*',$robot->readData(4))

=back

=cut

sub readData($$) {
	my $self=shift;
	my $length=shift;
	my $data='';
	
	if (length($self->{readBuffer})>=$length) {
		return substr($self->{readBuffer},0,$length,'');
	}
	
	$data=$self->{readBuffer};
	$self->{readBuffer}='';
	$length-=length($data);

	while($length>0) {
		my ($got,$saw)=$self->{replay}?$self->_readReplayData():$self->{port}->read($length);
		$self->_writeTelem('R',$saw);

		if ($got>=$length) {
			$data.=substr($saw,0,$length,'');
			$length=0;
			$self->{readBuffer}.=$saw;
		} else {
			$length-=$got;
			$data.=$saw;
		}
		#dsleep 0.01;
	}

	return $data;

}

###########Data#############
$sensorSpecs=[[26,'C12n!n!Cnn!Cnn'],
	[16,'C10'],[6,'CCn!n!'],[10,'Cnn!Cnn'],
	[14,'n5CnC'],[12,'C4n!n!n!n!'],
	[52,'C12n!n!Cnn!Cn7CnC5n!n!n!n!'],
	[1,'C'],[1,'C'],[1,'C'],[1,'C'],[1,'C'],
	[1,'C'],[1,'C'],[1,'C'],[1,'C'],[1,'C'],
	[1,'C'],[1,'C'],
	[2,'n!'],[2,'n!'],
	[1,'C'],[2,'n'],[2,'n!'],[1,'C'],
	[2,'n'],[2,'n'],[2,'n'],[2,'n'],
	[2,'n'],[2,'n'],[2,'n'],
	[1,'C'],[2,'n'],
	[1,'C'],[1,'C'],[1,'C'],[1,'C'],[1,'C'],
	[2,'n!'],[2,'n!'],[2,'n!'],[2,'n!']
	];

$sensorGroups=[[7,26],[7,16],[17,20],[21,26],[27,34],[35,42],[7,42]];

@sensorFields=('','','','','','','','','wall','cliffLeft',
'cliffFrontLeft','cliffFrontRight','cliffRight','virtualWall','','undef1','undef2','irByte','','distance',
'angle','chargingState','voltage','current','batteryTemp','batteryCharge','batteryCapacity','wallSignal','cliffLeftSignal','cliffFrontLeftSignal',
'cliffFrontRightSignal','cliffRightSignal','','analogIn','','oiMode','songNumber','songPlaying','numPackets','requestedVelocity',
'requestedRadius','requestedRightVelocity','requestedLeftVelocity');

$calibrationDefaults={angleCorrection=>[0.0240735069240597, 0.0240735069240597, 0.0240735069240597,
	0.0160695276398455, 0.0212269773891202, 0.0162776821429523,
	0.0165346981767884, 0.0185893056425432, 0.0181071622685291,
	0.0178499582590329, 0.0179008128409675],
	cliffStatistics=>{cliffRight=>[5811,4813494,4025842820],
		cliffFrontRight=>[5811,3588708,2232898560],
		cliffFrontLeft=>[5811,2352886,960201844],
		cliffLeft=>[5811,3137619,1706701033]}
};

$notes={
	'c'=>0,
	'c#'=>1,
	'd'=>2,
	'd#'=>3,
	'e'=>4,
	'f'=>5,
	'f#'=>6,
	'g'=>7,
	'g#'=>8,
	'a' => 9,
	'a#' => 10,
	 'b' =>11
};

$keys={'Cb'=>-7,
'Gb'=>-6,'Db'=>-5,'Ab'=>-4,'Eb'=>-3,'Bb'=>-2,
'F'=>-1,'C'=>0,'G'=>1,'D'=>2,'A'=>3,'E'=>4,
'B'=>5,'F#'=>6,'C#'=>7};

@sharps=('f','c','g','d','a','e','b');

$sensorLocations={cliffLeft=>[$ROBOT_WIDTH/2-10,deg2rad(150)],
	cliffFrontLeft=>[$ROBOT_WIDTH/2-10,deg2rad(105)],
	cliffFrontRight=>[$ROBOT_WIDTH/2-10,deg2rad(75)],
	cliffRight=>[$ROBOT_WIDTH/2-10,deg2rad(30)],
	bumpLeft=>[$ROBOT_WIDTH/2-10,deg2rad(135)],
	bumpCenter=>[$ROBOT_WIDTH/2-10,deg2rad(90)],
	bumpRight=>[$ROBOT_WIDTH/2-10,deg2rad(45)],
	caster=>[$ROBOT_WIDTH/2-10,deg2rad(90)],
	irSensor=>[$ROBOT_WIDTH/2-10,deg2rad(90)],
	wheelLeft=>[$ROBOT_WIDTH/2-10,deg2rad(180)],
	wheelRight=>[$WHEEL_WIDTH/2,0]
};

@cliffSensors=('cliffLeft','cliffFrontLeft','cliffFrontRight','cliffRight');


=head1 EXAMPLES

=head2 Wall bouncing

Moves robot foward until a bump sensor is triggered, then backs up and
turns a random angle before continuing forward.  Runs unil user hits the 'c' (close) or 's' (stop) keys.

	#!/usr/bin/perl
	
	use Robotics::IRobot;
	use Term::ReadKey;
	use Math::Trig; #for deg2rad
	
	print "Connecting...\n";
	my $iRobot=Robotics::IRobot->new('/dev/rfcomm0');
	
	#init robot and turn on hardware safeties
	$iRobot->init();
	print "Connected\n";
	$iRobot->startSafeMode();
	
	ReadMode 4,STDIN;
	
	my $sensorState=$iRobot->{sensorState};
	
	#check for a key press and display sensor output with every sensor read
	$iRobot->addSensorListener(300,sub {
			my $c=ReadKey -1, STDIN;
	
			if ($c) {
				if ($c eq  's') {
					#stop robot on s
					$iRobot->stop();
				} elsif ($c eq 'c') {
					#stop loop and exit program on c
					$iRobot->exitSensorLoop();
				}
			}
			
			#display sensor output
			print $iRobot->getCondensedString("\n") . "\n";
			
		},0);
	
	#action=0 moving foward
	#action=1 turning left
	#action=2 turning right
	#used to track whether we are responding to a bump event
	my $action=0;
	
	#trigger event when we are not responding to a bump event and one of
	#the bump sensors activates.
	$iRobot->addSensorEvent(200,sub {!$action && ($sensorState->{bumpRight} || $sensorState->{bumpLeft})},
		sub {
			#figure out which way to turn
			$action=$sensorState->{bumpRight}?1:2;
			
			#back up
			$iRobot->reverse(200);
			
			#after .5s
			$iRobot->waitTime(200,.5,sub {
			
				#rotate away from bump
				if ($action==1) {
					$iRobot->rotateLeft(200);
				} else {
					$iRobot->rotateRight(200);
				}
				
				#wait for random angle
				$iRobot->waitAngle(200,deg2rad(10 + 120*rand()),
					sub {
						
						#then continue forward
						$iRobot->forward(300);
						$action=0;
					}
				);
			});
		},0,0);
	
	#begin moving forward
	$iRobot->forward(300);
	
	#start sensor loop and event processing
	$iRobot->runSensorLoop();
	
	#close connection
	$iRobot->close();
	
	ReadMode 0, STDIN;

=head2 Scripting

Uses robot's on board scripting to continuously move 500mm back and forth.  Robot will continue to do this until power button is pressed.

See OI Documentation for more details.

	#!/usr/bin/perl

	use Robotics::IRobot;

	my $robot=Robotics::IRobot->new();

	$robot->init();
	$robot->startSafeMode();

	$robot->startScript();

		$robot->forward(300);
		$robot->waitDistance(500);
		$robot->rotateLeft(200);
		$robot->waitAngle(180);
		$robot->forward(300);
		$robot->waitDistance(500);
		$robot->rotateLeft(200);
		$robot->waitAngle(180);
		$robot->repeatScript();

	$robot->endScript();

	$robot->runScript();


=head1 AUTHOR

Michael Ratliff, C<< <$_='email@michaelratlixx.com'; s/x/f/g; print;> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-robotics-irobot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics-IRobot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

I only have an iRobot Create to use for testing.  So, any Roomba bugs that are unable to be reproduced on a Create may
go unresolved.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics::IRobot


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Robotics-IRobot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Robotics-IRobot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Robotics-IRobot>

=item * Search CPAN

L<http://search.cpan.org/dist/Robotics-IRobot/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michael Ratliff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See section NOTICE at the top of this document.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Robotics::IRobot

