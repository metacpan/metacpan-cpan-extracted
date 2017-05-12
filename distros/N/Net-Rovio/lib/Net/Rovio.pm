package Net::Rovio;
use strict;
use warnings;
use LWP::Simple;
use vars qw($VERSION);
$VERSION = "1.5";
my $answer ="";

sub new {
  my $package = shift;
  my $self;
  $self->{'opened'} = 1;
  $self->{'host'} = $_[0];
  if ((($_[1]) && ($_[2])) && (($_[1] ne "") && ($_[2] ne ""))) {
  #  $self->{'auth'} = 1;
  #  $self->{'username'} = $_[1];
  #  $self->{'password'} = $_[2];
  $self->{'host'} = $_[1].':'.$_[2].'@'.$self->{'host'};
  }
  return bless($self, $package);
}

sub send
{
    my $self = shift;
    if ($self->{'opened'})
    {
        if ($_[0] ne "")
        {
        #my $request = WWW::Mechanize->new();
        #my $auth;
        #if ($self->{'auth'}) {
        #$request->credentials($self->{'username'}, $self->{'password'});
        #}
            my $file = $_[0];
            my $GET = $_[1];
            if ((!$GET) or ($GET eq ""))
            {
                $GET = " ";
            }
        #$request->get('http://'.$self->{'host'}.'/'.$file.'?'.$GET);
            get('http://'.$self->{'host'}.'/'.$file.'?'.$GET);
        }
        else
        {
            warn "Host not specified\n";

        }
    }
    else
    {
        warn "No connection to $self->{'host'}\n";

    }
}

sub camera_head
{
    my $self = shift;
    if ($_[0] =~ /down/i)
    {
        $answer = $self->send('rev.cgi', 'Cmd=nav&action=18&drive=12');
    }
    elsif ($_[0] =~ /mid/i)
    {
        $answer = $self->send('rev.cgi', 'Cmd=nav&action=18&drive=13');
    }
    elsif ($_[0] =~ /up/i)
    {
        $answer = $self->send('rev.cgi', 'Cmd=nav&action=18&drive=11');
    }
    else
    {
        warn "Invalid argument for camera_head()\n";
    }
    return processanswer();
}

# The lights_blue function was submitted to me by kyncl on the Robocommunity.com forum. Thanks!

sub lights_blue {
  my $self = shift;
  if ($_[0] =~ /off/i) {
  $self->send("/mcu", "parameters=114D4D00010053485254000100011A000000");
  }
  if ($_[0] =~ /on/i) {
  $self->send("/mcu", "parameters=114D4D00010053485254000100011AFF0000");
  }

  if (($_[0] =~ /1/i) or ($_[0] =~ /0/i)) {
  my $line = $_[0];
  my $hex = unpack("H*", pack ("B*", $line));
  $self->send("/mcu",'parameters=114D4D00010053485254000100011A'.$hex.'0000');
  }
}

sub halt
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=17");
    return processanswer();
}

sub startrecording
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=2");
    return processanswer();
};

sub abortrecording
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=3");
    return processanswer();
};

sub stoprecording
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=4&name=$_[0]");
    return processanswer();
};

sub deletepath
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=5&name=$_[0]");
    return processanswer();
};

sub changeresolution
{
    my $self = shift;
    if (defined $_[0])
    {
        if ($_[0] =~ m/[0|1|2|3]/g)
        {
            $answer = $self->send("/ChangeResolution.cgi", "ResType=$_[0]");
        }
        else
        {
            return "Value must be 0,1,2, or 3";
        }
    }
    else
    {
        return "Value must be 0,1,2, or 3";
    }
    return "OK";
};

# Input Parameter
# Camera supports 4 types of resolution:
# 0 - {176, 144}
# 1 - {352, 288}
# 2 - {320, 240} (Default)
# 3 - {640, 480}

sub changecompressratio
{
    my $self = shift;
    if (defined $_[0])
    {
        if ($_[0] =~ m/[0|1|2]/g)
        {
            $answer = $self->send("/ChangeCompressRatio.cgi", "Ratio=$_[0]");
        }
        else
        {
            return "Value must be 0,1, or 2";
        }
    }
    else
    {
        return "Value must be 0,1, or 2";
    }
    return "OK";
};

# Compression Ratios (MPEG mode only)
#
# 0 - Low
# 1 - Medium
# 2 - High

sub changeframerate
{
    my $self = shift;
    if (defined $_[0])
    {
        if (($_[0] >= 2) && ($_[0] <= 32))
        {
            $answer = $self->send("/ChangeFramerate.cgi", "Framerate=$_[0]");
        }
        else
        {
            return "Value must be 2 - 32.";
        }
    }
    else
    {
        return "Value must be 2 - 32";
    }
    return "OK";
};

# Supports 2-32 Frames per sec as input values

sub changebrightness
{
    my $self = shift;
    if (defined $_[0])
    {
        if (($_[0] >= 0) && ($_[0] <= 6))
        {
            $answer = $self->send("/ChangeBrightness.cgi", "Brightness=$_[0]");
        }
        else
        {
            return "Value must be 0 - 6.";
        }
    }
    else
    {
        return "Value must be 0 - 6";
    }
    return "OK";
};

# Brightness from 0 - 6. 6 = Brightest setting.

sub changespeakervolume
{
    my $self = shift;
    if (defined $_[0])
    {
        if (($_[0] >= 0) && ($_[0] <= 31))
        {
            $answer = $self->send("/ChangeSpeakerVolume.cgi", "SpeakerVolume=$_[0]");
        }
        else
        {
            return "Value must be 0 - 31.";
        }
    }
    else
    {
        return "Value must be 0 - 31";
    }
    return "OK";
};

# Speaker Volume from 0 - 31, 31 = Loudest.

sub changemicvolume
{
    my $self = shift;
    if (defined $_[0])
    {
        if (($_[0] >= 0) && ($_[0] <= 31))
        {
            $answer = $self->send("/ChangeMicVolume.cgi", "MicVolume=$_[0]");
        }
        else
        {
            return "Value must be 0 - 31.";
        }
    }
    else
    {
        return "Value must be 0 - 31";
    }
    return "OK";
};

# Mic Volume from 0 - 31, 31 = Loudest.

sub getreport
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=1");
    my ($config, %config, $var, $value) = "";
    my @settings = split(/\|/,$answer);
    foreach (@settings)
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        #print $_ . "\n";
        ($var, $value) = split(/\s*=\s*/, $_, 2);
        $config{$var} = $value
    };
    return (\%config);
}

#          'wifi_ss' => '205',
#          'show_time' => '0',
#          'theta' => '-2.497',
#          'frame_rate' => '25',
#          'state' => '0',
#          'y' => '1041',
#          'ss' => '17326',
#          'speaker_volume' => '27',
#          'next_room_ss' => '55',
#          'video_compression' => '1',
#          'mic_volume' => '29',
#          'ui_status' => '0',
#          'brightness' => '6',
#          'email_state' => '0',
#          'resolution' => '2',
#          'privilege' => '0',
#          'beacon' => '0',
#          'x' => '3575',
#          'room' => '0',
#          'battery' => '118',
#          'Cmd' => 'nav responses = 0',
#          'beacon_x' => '0',
#          'user_check' => '1',
#          'flags' => '0005',
#          'next_room' => '9',
#          'pp' => '0',
#          'sm' => '15',
#          'charging' => '72',
#          'head_position' => '204',
#          'ac_freq' => '2',
#          'resistance' => '0',
#          'ddns_state' => '0'

sub getlog
{
    my $self = shift;
    $answer = $self->send("/GetLog.cgi", "");
    my ($log, %log, $var, $value, $line, $timeinsecs, $lognum, @lognum) = "";
    if ($answer =~ m/Time = ([0-9].*)/g) { $timeinsecs = $1; };
    while ( $answer =~ /Log = ([0-9].*)/g )
    {
        push @lognum, $1;
    };
    $log{'Time'} = $timeinsecs;
    $log{'LogLines'} = \@lognum;
    return (\%log);
}

#	0	Information
#	1	Error
#	11	Set user
#	12	Del user
#	13	Set user check
#	14	Open camera
#	15	Close camera
#	16	Change resolution
#	17	Change quality
#	18	Change brightness
#	19	Change contrast
#	20	Change saturation
#	21	Change hue
#	22	Change Sharpness
#	23	Set email
#	24	Set ftp server
#	25	Dial (pppoe)
#	26	Dial (modem)
#	27	New client
#	28	Set Motion Detect
#	29	Set Monite Area
#	30	Set Server Time
#	31	Set Server IP
#	32	Set Http Port


sub getmcureport
{
    my $self = shift;
    my ($report) = "";
    my %report;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=20");
    if ($answer)
    {
        chomp $answer;
        $answer =~ m/responses = 0(.*?)$/g;
        $report{packet_length}         = hex(substr($1, 0, 1));
        $report{left_wheel_dir}        = substr($1, 2, 1);
        $report{left_encoder_ticks}    = substr($1, 3, 2);
        $report{right_wheel_dir}       = substr($1, 5, 1);
        $report{right_encoder_ticks}   = substr($1, 6, 2);
        $report{rear_wheel_dir}        = substr($1, 8, 1);
        $report{rear_encoder_ticks}    = substr($1, 9, 2);
        $report{head_position}         = substr($1, 12, 1);
        $report{picture_index}         = substr($1, 13, 1);
        #print "\n Getstatus: " . $answer . "\n";
        #print "\nAnswer: " . length($1) . " - $1\n";
        return \%report;
    }
    else
    {
        return "FAIL";
    };

}

# TODO: Finish setups for bit compare
#	Offset 	Length 	Description
#	0	1B 	Length of the packet
#	1	1B 	NOT IN USE
#	2	1B 	Direction of rotation of left wheel since last read (bit 2)
#	3	2B 	Number of left wheel encoder ticks since last read
#	5	1B 	Direction of rotation of right wheel since last read (bit 2)
#	6	2B 	Number of right wheel encoder ticks since last read
#	8	1B 	Direction of rotation of rear wheel since last read (bit 2)
#	9	2B 	Number of rear wheel encoder ticks since last read
#	11	1B 	NOT IN USE
#	12	1B 	Head position
#	13	1B 	0x7F: Battery Full (0x7F or higher for new battery)  0x??: Orange light in Rovio head.
# ( to be define)  0x6A: Very low battery (Hungry, danger, very low battery level)  libNS need take
# control to go home and charging  0x64: Shutdown level (MCU will cut off power for protecting the battery)
#	14	1B 	bit 0 : Light LED (head) status, 0: OFF, 1: ON  bit 1 : IR-Radar power status. 0: OFF, 1: ON
# bit 2 : IR-Radar detector status: 0: fine, 1: barrier detected.  bit 3-5: Charger staus  0x00 : nothing
# happen  0x01 : charging completed.  0x02 : in charging  0x04 : something wrong, error occur.
# bit 6,7: undefined, do not use.


sub getpathlist
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=6");
    $answer =~ m/= (.*?)$/g;
    $answer ="";
    return split(/\|/,$1);
}

sub gettime
{
    my $self = shift;
    $answer = $self->send("/GetTime.cgi", "");
    my ($config, %config, $var, $value) = "";
    my @settings = split(/\n/,$answer);
    foreach (@settings)
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        #print $_ . "\n";
        ($var, $value) = split(/\s*=\s*/, $_, 2);
        $config{$var} = $value
    };
    return (\%config);
}


sub getmediaformat
{
    my $self = shift;
    $answer =$self->send("/GetMediaFormat.cgi", "");
    #print "\n Media answer: $answer \n";
    my ($config, %config, $var, $value) = "";
    my @settings = split(/\n/,$answer);
    foreach (@settings)
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        #print $_ . "\n";
        ($var, $value) = split(/\s*=\s*/, $_, 2);
        $config{$var} = $value
    };
    return (\%config);
}

#Formats returned:
# Audio
# 0 - AMR
# 1 - PCM
# 2 - IMAADPCM
# 3 - ULAW
# 4 - ALAW
#
# Video
# 1 - H263
# 2 - MPEG4

sub setmediaformat
{
    my $self = shift;
    my ($command,$params) = "";
    my %params;
    ($params) = @_;
    if ($params->{Video}) { if ($params->{Video} =~ m/[1|2]/g){} else { return "Video must be 1 or 2"; }; $command .= "&Video=" . $params->{Video}; };
    if ($params->{Audio}) { if ($params->{Audio} =~ m/[0|1|2|3|4]/g){} else { return "Audio must be 1, 2, 3, or 4"; }; $command .= "&Audio=" . $params->{Audio}; };
    $answer = $self->send("/SetMediaFormat.cgi", "$command");
    return "OK";
}

sub getcamera
{
    my $self = shift;
    $answer =$self->send("/GetCamera.cgi", "");
    my ($config, %config, $var, $value) = "";
    my @settings = split(/\|/,$answer);
    foreach (@settings)
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        #print $_ . "\n";
        ($var, $value) = split(/\s*=\s*/, $_, 2);
        $config{$var} = $value
    };
    return (\%config);
}

sub gethttp
{
    my $self = shift;
    $answer =$self->send("/GetHttp.cgi", "");
    #print "\n Http answer: $answer \n";
    my ($config, %config, $var, $value) = "";
    my @settings = split(/\n/,$answer);
    foreach (@settings)
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        #print $_ . "\n";
        ($var, $value) = split(/\s*=\s*/, $_, 2);
        $config{$var} = $value
    };
    return (\%config);
}

sub sethttp
{
    my $self = shift;
    my ($command,$params) = "";
    my %params;
    ($params) = @_;
    if ($params->{Port1}) { if ($params->{Port1})   { $command .= "&Port1=" . $params->{Port1}; };  };
    if ($params->{Port0}) { if ($params->{Port0}) { $command .= "&Port0=" . $params->{Port0}; }; };
    $answer = $self->send("/SetHttp.cgi", "$command");
    return "OK";
}

# This command will cause the http server to reset, briefly making it inaccessable - prepare for this to prevent errors.

sub getmail
{
    my $self = shift;
    $answer =$self->send("/GetMail.cgi", "");
    #print "\n Getmail answer: $answer \n";
    my ($config, %config, $var, $value) = "";
    my @settings = split(/\n/,$answer);
    foreach (@settings)
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        #print $_ . "\n";
        ($var, $value) = split(/\s*=\s*/, $_, 2);
        $config{$var} = $value
    };
    return (\%config);
}

# GetMail Returns:
#
#          'Subject' => 'Rovio Snapshot',
#          'User' => '',
#          'MailServer' => '',
#          'Port' => '25',
#          'Sender' => '',
#          'CheckFlag' => '0',
#          'Enable' => '0',
#          'Receiver' => '',
#          'PassWord' => '',
#          'Body' => 'Check out this photo from my Rovio.'

sub setmail
{
    my $self = shift;
    my ($command,$params) = "";
    my %params;
    ($params) = @_;
    if ($params->{Mailserver}) { if ($params->{Mailserver})     { $command .= "&Mailserver=" . $params->{Mailserver}; };  };
    if ($params->{Sender})     { if ($params->{Sender})         { $command .= "&Sender="     . $params->{Sender}; };  };
    if ($params->{Receiver})   { if ($params->{Receiver})       { $command .= "&Receiver=" . $params->{Receiver}; };  };
    if ($params->{Subject})    { if ($params->{Subject})        { $command .= "&Subject=" . $params->{Subject}; };  };
    if ($params->{User})       { if ($params->{User})           { $command .= "&User=" . $params->{User}; };  };
    if ($params->{PassWord})   { if ($params->{PassWord})       { $command .= "&PassWord=" . $params->{PassWord}; };  };
    if ($params->{CheckFlag})  { if ($params->{CheckFlag})      { $command .= "&CheckFlag=" . $params->{CheckFlag}; };  };
    $answer = $self->send("/SetMail.cgi", "$command");
    return "OK";
}

# SetMail.cgi
# Input Parameters
#
# Enable - Ignored
# MailServer - mail server address
# Sender - sender’s email address
# Receiver - receiver’s email address, multi-receivers separated by ‘;’
# Subject - subject of email
# User - user name for logging into the MailServer
# PassWord - password for logging into the MailServer
# CheckFlag - whether the MailServer needs to check password
# Interval - Ignored

sub getver
{
    my $self = shift;
    $answer = $self->send("/GetVer.cgi", "");
    if ($answer)
    {
        chomp $answer;
        $answer =~ m/Version = (.*?)$/g;
        return $1;
    }
    else
    {
        return 0;
    }
}

sub getstatus
{
    my $self = shift;
    my($status) = "";
    my %status;
    $answer = $self->send("/GetStatus.cgi", "");
    chomp $answer;
    $answer =~ m/= (.*?)$/g;
    $status{camera_state}          = substr($1, 0, 2);
    $status{modem_state}           = substr($1, 2, 2);
    $status{pppoe_state}           = substr($1, 4, 2);
    $status{x_direction}           = substr($1, 6, 3);
    $status{y_direction}           = substr($1, 9, 3);
    $status{focus}                 = substr($1, 12, 3);
    $status{bright}                = substr($1, 15, 3);
    $status{contrast}              = substr($1, 18, 3);
    $status{resolution}            = substr($1, 21, 1);
    $status{compression_ratio}     = substr($1, 22, 1);
    $status{privilege}             = substr($1, 23, 1);
    $status{picture_index}         = substr($1, 24, 6);
    $status{email_state}           = substr($1, 30, 1);
    $status{user_check}            = substr($1, 31, 1);
    $status{image_file_length}     = substr($1, 32, 8);
    $status{monitor_rect}          = substr($1, 40, 16);
    $status{ftp_state}             = substr($1, 56, 1);
    $status{saturation}            = substr($1, 57, 3);
    $status{motion_detected_index} = substr($1, 60, 6);
    $status{hue}                   = substr($1, 66, 3);
    $status{sharpness}             = substr($1, 69, 3);
    $status{motion_detect_way}     = substr($1, 72, 1);
    $status{sensors_frequency}     = substr($1, 73, 1);
    $status{channel_mode}          = substr($1, 74, 1);
    $status{channel_value}         = substr($1, 75, 2);
    $status{audio_volume}          = substr($1, 77, 3);
    $status{dynamic_dns_state}     = substr($1, 80, 1);
    $status{audio_state}           = substr($1, 81, 1);
    $status{frame_rate}            = substr($1, 82, 3);
    $status{speaker_volume}        = substr($1, 85, 3);
    $status{mic_volume}            = substr($1, 88, 3);
    $status{show_time}             = substr($1, 91, 1);
    $status{wifi_strength}         = hex(substr($1, 93, 1));
    $status{battery_level}         = hex(substr($1, 94, 2));
    #print "\n Getstatus: " . $answer . "\n";
    $answer ="";
    return \%status;
}
#
# GetStatus: 01000000000000000600021099999901000000000000000000000000000099999900000000000000000250270290c575 -96
#
#	Byte 		Description 		Value
#	0, 1 		Camera State 		00 - off 01 – on
#	2, 3 		Modem State 		00 - off 01 - on line(common mode) 02 - connecting(common mode)
#	4, 5 		PPPoE State 		same as Modem state
#	6, 7, 8 		x-direction 		Reserved
#	9, 10, 11 		y-direction 		Reserved
#	12, 13, 14 		Focus 		Reserved
#	15, 16, 17 		Bright 		0 – 255
#	18, 19, 20 		contrast 		0 – 255
#	21		resolution 		00 - {176, 144} 01 - {320, 240} 02 - {352, 288} 03 - {640, 480}
#	22		compression ratio 		Reserved
#	23		privilege 		0 - super user(administrator) 1 - common user
#	24, 25, .., 29 		picture index 		(999999 - invalid picture)
#	30		email state 		0 - do not send motion-detected pictures 1 - send motion-detected pictures, success 2 - send motion-detected pictures, fail (wrong IP, user or password?)
#	31		user check 		0 - do not check user, any user can connect and act as a super user 1 - username and password required, only username is "administrator" has the super privilege.
#	32, 34, .., 39 		image file length 		length in bytes
#	40, 42, .., 55 		monitor rect 		4 - left(0-9999) 4 - top(0-9999) 4 - right(0-9999) 4 - bottom(0-9999)
#	56		ftp state 		0 - disable ftp upload 1 - enable ftp upload, and upload success 2 - enable ftp upload, but fail(wrong IP, user or password?)
#	57, 58, 59 		saturation 		0 - 255
#	60, 61, ..., 65 		motion detected index 		(999999 - init value)
#	66, 67, 68 		Hue 		0 - 255
#	69, 70, 71 		sharpness 		0 - 255
#	72		motion detect way 		0 - no motion detect non-zero - motion detect
#	73		sensor's frequency 		0 - outdoor 1 - 50Hz 2 - 60Hz
#	74		channel mode 		0 - fixed mode 1 - round robin mode
#	75, 76 		channel value 		In fixed mode, the value may be from 0 to 3 In round robin mode, the value may be from 1 to 15
#	77, 78, 79 		audio volume
#	80		dynamic DNS state 		0 - no update 1 - updating 2 - update successfully 3 - update failed
#	81		audio state 		0 - audio disabled 1 - audio enabled
#	82, 83, 84 		frame rate
#	85,86, 87 		Speaker volume
#	88, 89, 90 		Mic volume
#	91		Show Time 		0 - do not show time in image  1 – show time in image
#	92		WiFi Strength 		0-15, 0 is Max.
#	93, 94 		BatteryLevel 		0-0xFF, 255 is Max.


sub state
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=22");
    $answer =~ m/state=(.*?)$/g;
    if ($1 == "0") { return "idle"; };
    if ($1 == "1") { return "driving home"; };
    if ($1 == "2") { return "docking"; };
    if ($1 == "3") { return "executing path"; };
    if ($1 == "4") { return "recording path"; };
    return 0;
}

sub gohomeanddock
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=13");
    return processanswer();
}

sub dock
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=13");
    return processanswer();
}

sub resetnavstatemachine
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=17");
    return processanswer();
}

sub updatehomeposition
{
    my $self = shift;
    $answer =$self->send("/rev.cgi", "Cmd=nav&action=14");
    return processanswer();
}

sub gettuningparameters
{
    my $self = shift;
    $answer =$self->send("/rev.cgi", "Cmd=nav&action=16");
    my ($config, %config, $var, $value) = "";
    my @settings = split(/\|/,$answer);
    foreach (@settings)
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        #print $_ . "\n";
        ($var, $value) = split(/\s*=\s*/, $_, 2);
        $config{$var} = $value
    };
    return (\%config);
}

#          'ManTurn' => '8',
#          'ManDrive' => '7',
#          'DockTimeout' => '72',
#          'Reverse' => '6',
#          'LeftRight' => '6',
#          'Cmd' => 'nav responses = 0',
#          'Forward' => '5',
#          'DriveTurn' => '8',
#          'HomingTurn' => '9'

sub settuningparameters
{
    my $self = shift;
    my ($command,$params) = "";
    my %params;
    ($params) = @_;
    if ($params->{ManTurn})     { $command .= "&ManTurn=" . $params->{ManTurn}; };
    if ($params->{ManDrive})    { $command .= "&ManDrive=" . $params->{ManDrive}; };
    if ($params->{DockTimeout}) { $command .= "&DockTimeout=" . $params->{DockTimeout}; };
    if ($params->{Reverse})     { $command .= "&Reverse=" . $params->{Reverse}; };
    if ($params->{LeftRight})   { $command .= "&LeftRight=" . $params->{LeftRight}; };
    if ($params->{Forward})     { $command .= "&Forward=" . $params->{Forward}; };
    if ($params->{DriveTurn})   { $command .= "&DriveTurn=" . $params->{DriveTurn}; };
    if ($params->{HomingTurn})  { $command .= "&HomingTurn=" . $params->{HomingTurn}; };
    $answer =$self->send("/rev.cgi", "Cmd=nav&action=15$command");
    return processanswer();
}

sub getlogo
{
    my $self = shift;
    $answer =$self->send("/GetLogo.cgi", "");
    #print "\n" , $answer . "\n";
    my ($config, %config, $var, $value) = "";
    my ($lastvar) = " ";
    my @settings = split(/\n/,$answer);
    foreach (@settings)
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        #print $_ . "\n";
        ($var, $value) = split(/\s*=\s*/, $_, 2);
        if ($var eq $lastvar)
        {
            $var .= "2";
            $config{$var} = $value
        }
        else
        {
            $config{$var} = $value
        }
        $lastvar = $var;
    };
    return (\%config);
}

sub getip
{
    my $self = shift;
    if (($_[0] ne "wlan0") && ($_[0] ne "eth1")) { return "Value must be wlan0 or eth1"; };
    $answer =$self->send("/GetIP.cgi", "Interface=$_[0]");
    #print "\n" , $answer . "\n";
    my ($config, %config, $var, $value) = "";
    my ($lastvar) = " ";
    my @settings = split(/\n/,$answer);
    foreach (@settings)
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        #print $_ . "\n";
        ($var, $value) = split(/\s*=\s*/, $_, 2);
        if ($var eq $lastvar)
        {
            $var .= "2";
            $config{$var} = $value
        }
        else
        {
            $config{$var} = $value
        }
        $lastvar = $var;
    };
    return (\%config);
}

#GetIP Returns:
#
#         'CurrentDNS0' => '4.2.2.3',
#          'DNS2' => '0.0.0.0',
#          'IPWay' => 'manually',
#          'CurrentNetmask' => '255.255.255.0',
#          'Netmask' => '255.255.255.0',
#          'DNS1' => '0.0.0.0',
#          'Gateway' => '192.168.1.1',
#          'DNS0' => '4.2.2.3',
#          'CurrentGateway' => '192.168.1.1',
#          'CurrentDNS1' => '0.0.0.0',
#          'CameraName' => 'RovioCam',
#          'CurrentIP' => '192.168.1.200',
#          'Enable' => '1',
#          'CurrentDNS2' => '0.0.0.0',
#          'IP' => '192.168.1.200',
#          'CurrentIPState' => 'STATIC_IP_OK'

sub getwlan
{
    my $self = shift;
    $answer =$self->send("/GetWlan.cgi", "");
    #print "\n" , $answer . "\n";
    my ($config, %config, $var, $value) = "";
    my ($lastvar) = " ";
    my @settings = split(/\n/,$answer);
    foreach (@settings)
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        #print $_ . "\n";
        ($var, $value) = split(/\s*=\s*/, $_, 2);
        if ($var eq $lastvar)
        {
            $var .= "2";
            $config{$var} = $value
        }
        else
        {
            $config{$var} = $value
        }
        $lastvar = $var;
    };
    return (\%config);
}

#GetWlan Returns:
#
#          'Wep128type' => 'Wep128HEX',
#          'Wep64type' => 'Wep64HEX',
#          'Channel' => '5',
#          'ESSID' => 'YourRouterSSID',
#          'WepSet' => 'Asc',
#          'CurrentWiFiState' => 'OK',
#          'Mode' => 'Managed',
#          'Key' => '',
#          'WepGroup' => '0',
#          'WepAsc' => ''

sub getddns
{
    my $self = shift;
    my($status) = "";
    my %status;
    $answer = $self->send("/GetDDNS.cgi", "");
    #print "(" . $answer . ")\n";
    my ($config, %config, $var, $value) = "";
    my ($lastvar) = " ";
    my @settings = split(/\n/,$answer);
    foreach (@settings)
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        ($var, $value) = split(/\s*=\s*/, $_, 2);
        if ($var eq $lastvar)
        {
            $var .= "2";
            $config{$var} = $value
        }
        else
        {
            $config{$var} = $value
        }
        $lastvar = $var;
    };
    return (\%config);
}

#GetDDNS Returns:

#          'User' => '',
#          'Pass' => '',
#          'Service' => '',
#          'ProxyPass' => '',
#          'Proxy' => '',
#          'ProxyPort' => '0',
#          'Info' => 'Not Update',
#          'ProxyUser' => '',
#          'Enable' => '0',
#          'IP' => '0.0.0.0',
#          'DomainName' => ''

#Info can return:
# Updated
# Updating
# Failed
# Updating IP
# Checked
# Not Update

# TODO: Write a handler for the streamed video from GetData
sub getdata
{
    my $self = shift;
    $answer = $self->send("/GetData.cgi", "");
    return $answer;
};

sub gohome
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=12");
    return processanswer();
}

sub getname
{
    my $self = shift;
    $answer = $self->send("/GetName.cgi", "");
    $answer =~ m/CameraName = (.*?)$/g;
    return $1;
}

sub setname
{
    my $self = shift;
    $answer = $self->send("/SetName.cgi", "&CameraName=$_[0]");
    if (getname($self) eq $_[0]) { return "OK" } else { return 0; };
}

sub playpathforward
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=7&name=$_[0]");
    return processanswer();
}

sub playpathbackward
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=8&name=$_[0]");
    return processanswer();
}

sub renamepath
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=11&name=$_[0]&newname=$_[1]");
    return processanswer();
}

sub stopplaying
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=9");
    return processanswer();
}

sub clearallpaths
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=21");
    return processanswer();
}

sub pauseplaying
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=10");
    return processanswer();
}

sub manualdrive
{
    my $self = shift;
    $answer = $self->send("/rev.cgi", "Cmd=nav&action=18&drive=$_[0]&speed=$_[1]");
    return processanswer();
}

sub light
{
    my $self = shift;
    if ((!$_[0]) or ($_[0] =~ /off/i))
    {
        $answer = $self->send("/rev.cgi", "Cmd=nav&action=19&LIGHT=0");
    }
    else
    {
        $answer = $self->send("/rev.cgi", "Cmd=nav&action=19&LIGHT=1");
    }
    return processanswer();
}

sub camimg
{
    my $self = shift;
    $answer = get('http://'.$self->{'host'}.'/'.'Jpeg/CamImg0002.jpg');
    if ($answer)
    {
        return $answer;
    }
    else
    {
        return 0;
    };
}

sub send_photo
{
    my $self = shift;
    $self->send("/SendMail.cgi");
    return "OK";
}

sub sendmail
{
    my $self = shift;
    $self->send("/SendMail.cgi");
    return "OK";
}

sub reboot
{
    my $self = shift;
    $answer = $self->send("/Reboot.cgi", "");
    return processanswer();
    
}

sub processanswer
{
    my $self = shift;
    if ($answer)
    {
        chomp $answer;
        if ($answer =~ m/responses = 0/ig)  { return "OK"; };
        if ($answer =~ m/responses = 9/ig)  { return "PATH_NOT_FOUND"; };
        if ($answer =~ m/responses = 8/ig)  { return "PATH_BASEADDRESS_NOT_INITIALIZED"; };
        if ($answer =~ m/responses = 7/ig)  { return "FAILED_TO_READ_PATH"; };
        if ($answer =~ m/responses = 6/ig)  { return "NO_EMPTY_PATH_AVAILABLE"; };
        if ($answer =~ m/responses = 5/ig)  { return "NO_NS_SIGNAL"; };
        if ($answer =~ m/responses = 4/ig)  { return "UNKNOWN_CGI_ACTION"; };
        if ($answer =~ m/responses = 3/ig)  { return "FEATURE_NOT_IMPLEMENTED"; };
        if ($answer =~ m/responses = 23/ig) { return "NO_PARAMETER"; };
        if ($answer =~ m/responses = 22/ig) { return "PARAMETER_OUTOFRANGE"; };
        if ($answer =~ m/responses = 21/ig) { return "NS_UART_READ_ERROR"; };
        if ($answer =~ m/responses = 20/ig) { return "NS_PACKET_CHECKSUM_ERROR"; };
        if ($answer =~ m/responses = 2/ig)  { return "ROBOT_BUSY"; };
        if ($answer =~ m/responses = 19/ig) { return "NO_NS_PORT_AVAILABLE"; };
        if ($answer =~ m/responses = 18/ig) { return "NO_MCU_PORT_AVAILABLE"; };
        if ($answer =~ m/responses = 17/ig) { return "NO_MEMORY_AVAILABLE"; };
        if ($answer =~ m/responses = 16/ig) { return "FLASH_NOT_READY"; };
        if ($answer =~ m/responses = 15/ig) { return "FAILED_TO_WRITE_TO_FLASH"; };
        if ($answer =~ m/responses = 14/ig) { return "FAILED_TO_READ_FROM_FLASH"; };
        if ($answer =~ m/responses = 13/ig) { return "FAILED_TO_DELETE_PATH"; };
        if ($answer =~ m/responses = 12/ig) { return "FLASH_NOT_INITIALIZED"; };
        if ($answer =~ m/responses = 11/ig) { return "NOT_RECORDING_PATH"; };
        if ($answer =~ m/responses = 10/ig) { return "PATH_NAME_NOT_SPECIFIED"; };
        if ($answer =~ m/responses = 1/ig)  { return "FAIL"; };
        return 0;
    };
};

1;
__END__

=head1 NAME

Net::Rovio - A Perl module for Rovio manipulation

=head1 SYNOPSIS

  use Net::Rovio;
  my $rovio = Net::Rovio->new('my-rovio.ath.cx', 'admin', 'password');
  $rovio->light('on');
  $rovio->send_photo();
  sleep 1;
  $rovio->camera_head('mid');
  $rovio->send_photo();
  sleep 1;
  $rovio->camera_head('up');
  $rovio->send_photo();
  sleep 1;
  $rovio->camera_head('mid');
  sleep 1;
  $rovio->camera_head('down');
  sleep 1;
  $rovio->light('off');

  # Any functions that need parameters can have them sent in this fashion:
  @params = {   "Forward" => 8,
              "DriveTurn" => 6,
             "HomingTurn" => 8
             };
  $rovio->settuningparameters(@params);
  
  # Any functions that return parameters can be accessed in this fashion:
  
  $tuning = $rovio->gettuningparameters();
  print "Forward Value: $tuning->{Forward}";

  # Send the Rovio home to the charging cradle.

  $rovio->dock();


=head1 DESCRIPTION

Use Net::Rovio to control your Rovio robot from Perl. Uses basic Rovio API commands.

The Rovio L<http://www.wowwee.com/en/products/tech/telepresence/rovio/rovio> is a
Wi-Fi enabled mobile webcam that lets you view and interact with its environment
through streaming video and audio.

=head1 FUNCTIONS

Functions usually return "OK" upon success, unless otherwise noted per function.

=over 4

=head2 C<$rovio = Net::Rovio->new('hostname'[, 'username', 'password'])>

Opens the Rovio for communication.

=head2 $rovio->abortrecording()

Cancels the recording of a path and discards the path.

=head2 $rovio->camera_head('up'|'down'|'mid')

Moves the camera head to the up, down, or middle position.

=head2 $rovio->camimg()

Returns a picture from the camera in JPEG format. You can then save the data down as a binary file.

=head2 $rovio->changebrightness(0..6)

Sets the brightness level of the camera. Accepts values from 0 to 6, with 6 being the brightest.

=head2 $rovio->changecompressratio(0..2)

Change the quality setting of camera's images (only available with MPEG4). Accepts values from 0 to 2, representing low, medium and high quality, with 2 being the high quality setting.

=head2 $rovio->changeframerate(2..32)

Change the frame rate setting of camera's images. Accepts values from 2 - 32 frames per second.

=head2 $rovio->changemicvolume(0..31)

Changes the Mic volume on the Rovio. Accepts values from 0 - 31, with 31 being the highest.

=head2 $rovio->changeresolution(0..3)

Changes the resolution of the camera. Accepts values from 0 - 3 as defined below:

=over 4

          0 - {176, 144}
          1 - {352, 288}
          2 - {320, 240} (Default)
          3 - {640, 480}

=back

=head2 $rovio->changespeakervolume(0..31)

Changes the Speaker volume on the Rovio. Accepts values from 0 - 31, with 31 being the highest.

=head2 $rovio->clearallpaths()

Delete all saved paths within the Rovio.

=head2 $rovio->deletepath("PathName")

Delete a specific saved path within the Rovio. Accepts the name of the path to delete.

=head2 $rovio->dock() or $rovio->gohomeanddock()

Sends the Rovio to the charging base to dock. This only works when Rovio has navigation signal
available. To match up with the Rovio API, this command is synonymous with the
gohomeanddock() command.

=head2 $rovio->getcamera()

Returns the camera sensor setting:

=over 4

          50 - 50Hz
          60 - 60Hz
          0 - Auto detect

=back

=head2 $rovio->getdata()

Enables streaming video. Incomplete at this time.

=head2 $rovio->getddns()

Gets the Dynamic DNS settings within the Rovio. Returns

GetDDNS Returns:

=over 4

          'User' => '',
          'Pass' => '',
          'Service' => '',
          'ProxyPass' => '',
          'Proxy' => '',
          'ProxyPort' => '0',
          'Info' => 'Not Update',
          'ProxyUser' => '',
          'Enable' => '0',
          'IP' => '0.0.0.0',
          'DomainName' => ''

          Info above can return:

          Updated
          Updating
          Failed
          Updating IP
          Checked
          Not Update

=back

=head2 $rovio->gethttp()

Returns the http server port settings within the Rovio for both possible ports.

GetHTTP Returns:

=over 4

          'Port1' => '',
          'Port0' => '80'

=back

Note that the Port0 setting should only be changed if you know what you are doing.
This can complicate communication to the Rovio. See sethttp() to change the settings using the same parameters.

=head2 $rovio->getip()

Returns the settings for IP within the Rovio.

GetIP Returns:

=over 4

          'CurrentDNS0' => '4.2.2.3',
          'DNS2' => '0.0.0.0',
          'IPWay' => 'manually',
          'CurrentNetmask' => '255.255.255.0',
          'Netmask' => '255.255.255.0',
          'DNS1' => '0.0.0.0',
          'Gateway' => '192.168.1.1',
          'DNS0' => '4.2.2.3',
          'CurrentGateway' => '192.168.1.1',
          'CurrentDNS1' => '0.0.0.0',
          'CameraName' => 'RovioCam',
          'CurrentIP' => '192.168.1.200',
          'Enable' => '1',
          'CurrentDNS2' => '0.0.0.0',
          'IP' => '192.168.1.200',
          'CurrentIPState' => 'STATIC_IP_OK'

=back

=head2 $rovio->getlog()

Returns the log data from the Rovio. Currently an incomplete function, though still functional.

GetLog Returns:

=over 4

          'Time' => '0000001029',
          'LogLines' => [
                         '27    C0A8017D18F09FE518F00000000007'
                        ]


The Time represents time since power on in seconds. LogLines are individual log events.

Log Lines -

          byte 0, 1 - reason for recording this log, refer to table below. eg: 27 is shown that new client connect to the IP Camera.
          byte 2 ~ 5 - reserved.
          byte 6 ~ 13 - operator's IP. eg: 0A820B57 is 10.130.11.87.
          byte 14 ~ 25 - operator's MAC. eg: 0000E8E26A88 is 00:00:E8:E2:6A:88.
          byte 26 ~ 35 - time of this log.

          For byte 0, 1 - Log reason
          0 Information
          1 Error
          11 Set user
          12 Del user
          13 Set user check
          14 Open camera
          15 Close camera
          16 Change resolution
          17 Change quality
          18 Change brightness
          19 Change contrast
          20 Change saturation
          21 Change hue
          22 Change Sharpness
          23 Set email
          24 Set ftp server
          25 Dial (pppoe)
          26 Dial (modem)
          27 New client
          28 Set Motion Detect
          29 Set Monitor Area
          30 Set Server Time
          31 Set Server IP
          32 Set Http Port

=back

=head2 $rovio->getlogo()

Gets the 2 possible strings of text currently overlayed on the image, and thier position.

GetLogo Returns:

=over 4

          'ShowString' => '',
          'ShowPos' => '0',
          'ShowString2' => '',
          'ShowPos2' => '0'

=back

=head2 $rovio->getmail()

Gets the current email settings within the Rovio.

GetMail Returns:

=over 4

          'Subject' => 'Rovio Snapshot',
          'User' => '',
          'MailServer' => '',
          'Port' => '25',
          'Sender' => '',
          'CheckFlag' => '0',
          'Enable' => '0',
          'Receiver' => '',
          'PassWord' => '',
          'Body' => 'Check out this photo from my Rovio.'

=back

=head2 $rovio->getmcureport()

Incomplete function.

GetMCUReport Currently Returns:

=over 4

          'rear_encoder_ticks' => '00',
          'packet_length' => 14,
          'right_encoder_ticks' => '00',
          'right_wheel_dir' => '0',
          'left_encoder_ticks' => '00',
          'head_position' => '0',
          'picture_index' => '0',
          'rear_wheel_dir' => '0',
          'left_wheel_dir' => '1'

=back

=head2 $rovio->getmediaformat()

Gets the current media format setting in the Rovio.

GetMediaFormat Returns:

=over 4

          'Video' => '1',
          'Audio' => '4'

          The possible return values are:

          For Audio:
          0 - AMR
          1 - PCM
          2 - IMAADPCM
          3 - ULAW
          4 - ALAW

          For Video:
          1 - H263
          2 - MPEG4

=back

The same values can be used with the setmediaformat() command.
Note that some Video settings will not work with the built-in Rovio webpage
controls.

=head2 $rovio->getname()

This returns the currently defined camera name for the Rovio.

=head2 $rovio->getpathlist()

This returns an array of the current saved paths. You may then reference these paths to tell the Rovio to navigate to them.

=head2 $rovio->getreport()

This returns a large amount of status data from the Rovio.

GetReport Returns:

=over 4

          'wifi_ss' => '200',
          'show_time' => '0',
          'theta' => '1.098',
          'frame_rate' => '24',
          'state' => '0',
          'y' => '2936',
          'ss' => '12383',
          'speaker_volume' => '31',
          'next_room_ss' => '48',
          'video_compression' => '2',
          'mic_volume' => '30',
          'ui_status' => '0',
          'brightness' => '6',
          'email_state' => '0',
          'resolution' => '2',
          'privilege' => '0',
          'beacon' => '0',
          'x' => '-426',
          'room' => '0',
          'battery' => '118',
          'Cmd' => 'nav
responses = 0',
          'beacon_x' => '0',
          'user_check' => '1',
          'flags' => '0005',
          'next_room' => '1',
          'pp' => '1',
          'sm' => '15',
          'charging' => '72',
          'head_position' => '203',
          'ac_freq' => '2',
          'resistance' => '0',
          'ddns_state' => '0'

=back

=head2 $rovio->getstatus()

Returns detailed status of the Rovio.

GetStatus Returns:

=over 4

          'ftp_state' => '0',
          'saturation' => '000',
          'camera_state' => '01',
          'show_time' => '0',
          'monitor_rect' => '0000000000000000',
          'frame_rate' => '024',
          'pppoe_state' => '00',
          'sensors_frequency' => '0',
          'motion_detected_index' => '999999',
          'channel_mode' => '0',
          'picture_index' => '999999',
          'wifi_strength' => 8,
          'bright' => '006',
          'speaker_volume' => '031',
          'modem_state' => '00',
          'mic_volume' => '030',
          'audio_volume' => '000',
          'compression_ratio' => '2',
          'email_state' => '0',
          'resolution' => '2',
          'privilege' => '0',
          'audio_state' => '0',
          'focus' => '000',
          'motion_detect_way' => '0',
          'dynamic_dns_state' => '0',
          'x_direction' => '000',
          'y_direction' => '000',
          'user_check' => '1',
          'hue' => '000',
          'contrast' => '000',
          'battery_level' => 118,
          'channel_value' => '00',
          'image_file_length' => '00000000',
          'sharpness' => '000'

=back

=head2 $rovio->gettime()

Returns time information from the Rovio.

GetTime Returns:

=over 4

          'TimeZone' => '240',
          'NtpServer' => '',
          'UseNtp' => '0',
          'Sec1970' => '99663'

=back

=head2 $rovio->gettuningparameters()

Returns the tuning parameters from the Rovio.

GetTuningParameters Returns:

=over 4

          'ManTurn' => '8',
          'ManDrive' => '7',
          'DockTimeout' => '72',
          'Reverse' => '6',
          'LeftRight' => '6',
          'Cmd' => 'nav
responses = 0',
          'Forward' => '8',
          'DriveTurn' => '6',
          'HomingTurn' => '8'

=back

=head2 $rovio->getver()

Returns Version information.

GetVer Returns:

=over 4

 Ver: Jan 12 2010 14:41:24 $Revision: 5.3503$

=back

=head2 $rovio->getwlan()

Returns Wireless LAN information from the Rovio.

GetWlan Returns:

=over 4

          'Wep128type' => 'Wep128HEX',
          'Wep64type' => 'Wep64HEX',
          'Channel' => '5',
          'ESSID' => 'YourSSID',
          'WepSet' => 'Asc',
          'CurrentWiFiState' => 'OK',
          'Mode' => 'Managed',
          'Key' => '',
          'WepGroup' => '0',
          'WepAsc' => ''

=back

=head2 $rovio->halt()

Cancel current processing within the Rovio.

=head2 $rovio->light()

Controls the integrated light within the Rovio.

Sample:

=over 4

$rovio->light('on');
$rovio->light('off');

=back

=head2 $rovio->lights_blue()

Controls the blue LED lights around the Rovio. This supports two methods of controlling the LEDs, shown below:

Sample:

=over 4

          $rovio->lights_blue('on');        # Turn on all LEDs
          $rovio->lights_blue('off');       # Turn off all LEDs
          $rovio->lights_blue("00100000");  # Turn on right front LED
          $rovio->lights_blue("00010000");  # Turn on right mid LED
          $rovio->lights_blue("00001000");  # Turn on right back LED
          $rovio->lights_blue("00000100");  # Turn on left back LED
          $rovio->lights_blue("00000010");  # Turn on left mid LED
          $rovio->lights_blue("00000001");  # Turn on left front LED
          $rovio->lights_blue("00100001");  # Turn on two front LEDs (etc)

=back

=head2 $rovio->manualdrive(<drive value>,<speed value>)

Allows manual control of the Rovio movement.

Sample:

=over 4

          $rovio->manualdrive("1","2");

          Drive Values:
          0 (Stop)
          1 (Forward)
          2 (Backward)
          3 (Straight left)
          4 (Straight right)
          5 (Rotate left by speed)
          6 (Rotate right by speed)
          7 (Diagonal forward left)
          8 (Diagonal forward right)
          9 (Diagonal backward left)
          10 (Diagonal backward right)
          11 (Head up)
          12 (Head down)
          13 (Head middle)
          14 (Reserved)
          15 (Reserved)
          16 (Reserved)
          17 (Rotate left by 20 degree angle increments)
          18 (Rotate right by 20 degree angle increments)

          Speed Values:
          1 (fastest) - 10 (slowest)

=back

=head2 $rovio->pauseplaying()

Pause the currently playing path.

=head2 $rovio->playpathbackward(<pathname>)

Replay a stored path from the closest point to the beginning.

=head2 $rovio->playpathforward(<pathname>)

Replay a stored path from the closest point to the end.

=head2 $rovio->reboot()

Reboot the Rovio.

=head2 $rovio->renamepath(<old pathname>,<new pathname>)

Rename an existing path to a new name.

=head2 $rovio->resetnavstatemachine()

Stops the Rovio, and resets back to idle.

=head2 $rovio->send_photo() also as $rovio->sendmail()

Send a snapshot of the current camera image to the email address specified in the Rovio settings.

=head2 $rovio->sethttp()

Sets the webserver ports within the Rovio. See gethttp() for acceptable parameters.

=head2 $rovio->setmail(@params)

See getmail() for the acceptable parameters to send.

=head2 $rovio->setmediaformat(@params)

See getmediaformat() for acceptable parameters to send.

=head2 $rovio->setname(<newname>)

Sets the Camera name within the Rovio.

=head2 $rovio->settuningparameters(%params)

Sets the speed and other parameters in the Rovio. See the acceptable values in gettuningparameters().

Sample:

=over 4

          @params = {   "Forward" => 8,
                      "DriveTurn" => 6,
                     "HomingTurn" => 8
                     };
          $rovio->settuningparameters(@params);

=back

=head2 $rovio->startrecording()

Begins recording.

=head2 $rovio->state()

Reports the current state of the Rovio.

State Returns:

=over 4

          idle
          driving home
          docking
          executing path
          recording path

=back

=head2 $rovio->stopplaying()

Stops playing the current path.

=head2 $rovio->stoprecording(<save pathname>)

Stops recording the current path, and saves it in the Rovio with the name given.

=head2 $rovio->updatehomeposition()

Updates the saved home position within the Rovio to the current location of the Rovio.

=back

=head1 DEPENDENCIES

LWP::Simple

=head1 TODO

Finish all functions available for the Rovio.
Clean up the documentation (alot)

=head1 AUTHOR

Ivan Greene (ivantis@ivantis.net)
Ty Roden (tyroden@cpan.org)

=head1 SEE ALSO

LWP::Simple
WWW::Mechanize

=cut
