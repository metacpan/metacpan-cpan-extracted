package Mobile::UserAgent;
#
# Copyright (C) 2005 Craig Manley. All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# $Id: UserAgent.pm,v 1.5 2005/09/25 14:29:18 cmanley Exp $
#
use strict;
use Carp;

our $VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ m/ (\d+) \. (\d+) /xg;



# Contructor
# Parameter: optional user-agent string
sub new {
  my $proto = shift;
  my $useragent = shift || $ENV{'HTTP_USER_AGENT'};
  unless(defined($useragent)) {
    croak("Environment variable HTTP_USER_AGENT is missing!\n");
  }
  my $class = ref($proto) || $proto;
  my $self = {
    'useragent'   => $useragent,
    'is_standard' => 0,
    'is_imode'    => 0,
    'is_mozilla'  => 0,
    'is_rubbish'  => 0,
    'is_series60' => undef,
  };
  bless($self,$class);
  my $hashref = $self->_parseUserAgent($useragent);
  if (defined($hashref)) {
    $self->{'vendor'}      = $hashref->{'vendor'};
    $self->{'model'}       = $hashref->{'model'};
    $self->{'version'}     = $hashref->{'version'};
    $self->{'imode_cache'} = $hashref->{'imode_cache'};
    $self->{'screendims'}  = $hashref->{'screendims'};
  }
  return $self;
}




# Protected class method.
# Parses a standard mobile user agent string with the format vendor-model/version.
# If no match can be made, undef is returned.
# If a match is made, a hash ref is returned containing the compulsory
# keys "vendor" and "model", and the optional keys "version", and "screendims".
#
# Below are a few samples of these user agent strings:
#
#  Nokia8310/1.0 (05.57)
#  NokiaN-Gage/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0
#  SAGEM-myX-6/1.0 UP.Browser/6.1.0.6.1.c.3 (GUI) MMP/1.0 UP.Link/1.1
#  SAMSUNG-SGH-A300/1.0 UP/4.1.19k
#  SEC-SGHE710/1.0
#
# Parameter: user-agent string.
# Returns: hash ref or undef.
sub _parseUserAgentStandard {
  my $proto = shift;
  my $useragent = shift;
  # Standard vendor-model/version user agents
  unless ($useragent =~ /^
                          # Match the vendor-model combination (this goes into $1)....
                          (

                            # Match known vendor names (this goes into $2)...
                            (ACER|Alcatel|AUDIOVOX|BlackBerry|CDM|Ericsson|LG\b|LGE|Motorola|MOT|NEC|Nokia|Panasonic|PANTECH|PT|QCI|SAGEM|SAMSUNG|SEC|Sanyo|Sendo|SHARP|SIE|SonyEricsson|Telit|Telit_Mobile_Terminals|TSM)

                            # optionally followed by an irrelevant space or '-' character...
                            [- ]?

                            # followed by the model name (this goes into $3)...
                            ([^\/\s\_]+)
                          )

                          # Match possible version information after the slash seperator (this goes into $5)...
                          (\/(\S+))?

                        /x) {
    return undef;
  }
  my $both   = $1;
  my $vendor = $2;
  my $model  = $3;
  my $version = $5;
  # Fixup vendors and models.
  if ($vendor eq 'ACER') {
    $vendor = 'Acer';
  }
  elsif ($vendor eq 'AUDIOVOX') {
    $vendor = 'Audiovox';
  }
  elsif ($vendor eq 'CDM') {
    $vendor = 'Audiovox';
    $model = "CDM-$model";
  }
  elsif ($vendor eq 'Ericsson') {
    if ($model eq 'T68_NIL') {
      $model = 'T68';
    }
  }
  elsif (substr($vendor,0,2) eq 'LG') {
    $vendor = 'LG';
    if ($model =~ /^([A-Za-z\d]+)-/) { # LGE510W-V137-AU4.2
      $model = $1;
    }
  }
  elsif ($vendor eq 'MOT') {
    $vendor = 'Motorola';
    $model =~ s/[\._]$//;
  }
  elsif (($vendor eq 'PT') || ($vendor eq 'PANTECH')) {
    $vendor = 'Pantech';
  }
  elsif ($vendor eq 'PHILIPS') {
    $model = uc($model);
  }
  elsif ($vendor eq 'SAGEM') {
    if ($model eq '-') {
      return undef;
    }
  }
  elsif ($vendor eq 'SEC') {
    $vendor = 'SAMSUNG';
    $model =~ s/\*.*$//g;
  }
  elsif ($vendor eq 'SIE') {
    $vendor = 'Siemens';
  }
  elsif ($vendor eq 'Telit_Mobile_Terminals') {
    $vendor = 'Telit';
  }
  elsif ($vendor eq 'TSM') {
    $vendor = 'Vitelcom';
    $model = $both;
  }
  my %result = ('vendor' => $vendor,
                'model'  => $model);
  if (defined($version)) {
    $result{'version'} = $version;
  }
  return \%result;
}



# Protected class method.
# Parses an i-mode user agent string.
# If no match can be made, undef is returned.
# If a match is made, a hash ref is returned containing the compulsory
# keys "vendor" and "model", and the optional keys "version", "imode_cache",
# and "screendims".
#
# Below are a few samples of these user agent strings:
#
#  portalmmm/1.0 m21i-10(c10)
#  portalmmm/1.0 n21i-10(c10)
#  portalmmm/1.0 n21i-10(;ser123456789012345;icc1234567890123456789F)
#  portalmmm/2.0 N400i(c20;TB)
#  portalmmm/2.0 P341i(c10;TB)
#  portalmmm/2.0 L341i(c10;TB)
#  portalmmm/2.0 S341i(c10;TB)
#  portalmmm/2.0 SI400i(c10;TB)
#  DoCoMo/1.0/modelname
#  DoCoMo/1.0/modelname/cache
#  DoCoMo/1.0/modelname/cache/unique_id_information
#  DoCoMo/2.0 modelname(cache;individual_identification_information)
#
# Parameter: user-agent string.
# Returns: hash ref or undef.
sub _parseUserAgentImode {
  my $proto = shift;
  my $useragent = shift;
  my %vendors = (
	'D'  => 'Mitsubishi',
	'ER' => 'Ericsson',
	'F'  => 'Fujitsu',
	'KO' => 'Kokusai', # Hitachi
	'L'  => 'LG',
	'M'  => 'Mitsubishi',
	'P'  => 'Panasonic', # Matsushita
	'N'  => 'NEC',
	'NM' => 'Nokia',
	'R'  => 'Japan Radio',
	'S'  => 'SAMSUNG', # because of the other vendor codes starting with S below, the regex must try to match them first.
	'SG' => 'SAGEM',
	'SH' => 'Sharp',
	'SI' => 'Siemens',
	'SO' => 'Sony',
	'TS' => 'Toshiba');

  # Standard i-mode user agents
  my $pattern = '^(portalmmm|DoCoMo)\/(\d+\.\d+) ((' . join('|', reverse sort keys(%vendors)) . ')[\w\-]+) ?\((c(\d+))?';
  if ($useragent =~ /$pattern/i) {
    my $vendor  = $vendors{uc($4)};
    my $model   = $3;
    my $version = $2;
    my $cache;
    if (defined($6) && length($6)) {
      $cache = $6 + 0;
    }
    else {
      $cache = 5;
    }

    # Chop off trailing cache size from model name (e.g. N21i-10 becomes N21i).
    if (defined($model)) {
      $model =~ s/-\d+$//;
    }

    return {'vendor'  => $vendor,
            'model'   => $model,
            'version' => $version,
            'imode_cache' => $cache};
  }

  # DoCoMo HTML i-mode user agents
  $pattern = '^DoCoMo\/(\d+\.\d+)\/((' . join('|', keys(%vendors)) . ')[\w\.\-\_]+)(\/c(\d+))?';
  if ($useragent =~ /$pattern/i) {
    # HTML 1.0: DoCoMo/1.0/modelname
    # HTML 2.0: DoCoMo/1.0/modelname/cache
    # HTML 3.0: DoCoMo/1.0/modelname/cache/unique_id_information
    my %result = ('vendor'  => $vendors{uc($3)},
                  'model'   => $2,
                  'version' => $1);
    if (defined($6) && length($6)) {
      $result{'imode_cache'} = $5 + 0;
    }
    else {
      $result{'imode_cache'} = 5;
    }
    return \%result;
  }
  return undef;
}



# Protected class method.
# Parses a Mozilla (so called) compatible user agent string.
# If no match can be made, undef is returned.
# If a match is made, a hash ref is returned containing the compulsory
# keys "vendor" and "model", and the optional keys "version", and "screendims".
#
# Below are a few samples of these user agent strings:
#
#  Mozilla/4.1 (compatible; MSIE 5.0; Symbian OS; Nokia 3650;424) Opera 6.10  [en]
#  Mozilla/4.0 (compatible; MSIE 6.0; Nokia7650) ReqwirelessWeb/2.0.0.0
#  Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5)
#  Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5;Pz063e+wt16)
#  Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; PPC; 240x320)
#  mozilla/4.0 (compatible;MSIE 4.01; Windows CE;PPC;240X320) UP.Link/5.1.1.5
#  Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC; 240x320)
#  Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; SmartPhone; 176x220)
#  Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; 240x320; PPC)
#  Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; Smartphone; 176x220; Mio8380; Smartphone; 176x220)
#  Mozilla/4.0 (MobilePhone SCP-8100/US/1.0) NetFront/3.0 MMP/2.0
#  Mozilla/2.0(compatible; MSIE 3.02; Windows CE; Smartphone; 176x220)
#  Mozilla/4.1 (compatible; MSIE 5.0; Symbian OS Series 60 42) Opera 6.0 [fr]
#  Mozilla/SMB3(Z105)/Samsung UP.Link/5.1.1.5
#
# Parameter: user-agent string.
# Returns: hash ref or undef.
sub _parseUserAgentMozilla {
  my $proto = shift;
  my $useragent = shift;
  # SAMSUNG browsers
  if ($useragent =~ /^Mozilla\/SMB3\((Z105)\)\/(Samsung)/) {
    return {'vendor' => uc($2), 'model'  => $1};
  }
  # Extract the string between the brackets.
  unless($useragent =~ /^Mozilla\/\d+\.\d+\s*\(([^\)]+)\)/i) {
    return undef;
  }
  my @parts = split(/\s*;\s*/, $1); # split string between brackets on ';' seperator.
  # Micro$oft PPC and Smartphone browsers. Unfortunately, one day, if history repeats itself, this will probably be the only user-agent check necessary.
  if ((@parts >= 4) && ($parts[0] eq 'compatible') && ($parts[2] eq 'Windows CE')) {
    my %result = ('vendor' => 'Microsoft');
    if (($parts[3] eq 'PPC') || (lc($parts[3]) eq 'smartphone')) {
      $result{'model'} = 'SmartPhone';
      if ((@parts >= 5) && ($parts[4] =~ /^\d{1,4}x\d{1,4}$/i)) {
        $result{'screendims'} = lc($parts[4]);
      }
    }
    elsif ((@parts >= 5) && (($parts[4] eq 'PPC') || (lc($parts[4]) eq 'smartphone'))) {
    	$result{'model'} = 'SmartPhone';
    	if ($parts[3] =~ /^\d{1,4}x\d{1,4}$/i) {
        $result{'screendims'} = lc($parts[3]);
      }
    }
    if (exists($result{'model'})) {
      return \%result;
    }
  }

  # Nokia's with Opera browsers or SonyEricssons.
  if ((@parts >= 4) && ($parts[0] eq 'compatible') && ($parts[3] =~ /^(Nokia|Sony)\s*(\S+)$/)) {
    my $vendor = $1;
    my $model = $2;
    if ($vendor eq 'Sony') {
      $vendor = 'SonyEricsson';
    }
    return {'vendor' => $vendor, 'model' => $model};
  }

  # SANYO browsers
  if (@parts && ($parts[0] =~ /^MobilePhone ([^\/]+)\/([A-Z]+\/)?(\d+\.\d+)$/)) { # MobilePhone PM-8200/US/1.0
    return {'vendor' => 'Sanyo', 'model'  => $1, 'version' => $3};
  }

  # Nokias with ReqwirelessWeb browser
  if ((@parts >= 3) && ($parts[0] eq 'compatible') && ($parts[1] =~ /^(Nokia)\s*(\S+)$/)) {
    return {'vendor' => $1, 'model' => $2};
  }
  return undef;
}



# Protected class method.
# Parses a non-standard mobile user agent string.
# If no match can be made, undef is returned.
# If a match is made, a hash ref is returned containing the compulsory
# keys "vendor" and "model", and the optional keys "version", and "screendims".
#
# Below are a few samples of these user agent strings:
#
#  LGE/U8150/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.0
#  PHILIPS855 ObigoInternetBrowser/2.0
#  PHILIPS 535 / Obigo Internet Browser 2.0
#  PHILIPS-FISIO 620/3
#  PHILIPS-Fisio311/2.1
#  PHILIPS-FISIO311/2.1
#  PHILIPS-Xenium9@9 UP/4.1.16r
#  PHILIPS-XENIUM 9@9/2.1
#  PHILIPS-Xenium 9@9++/3.14
#  PHILIPS-Ozeo UP/4
#  PHILIPS-V21WAP UP/4
#  PHILIPS-Az@lis288 UP/4.1.19m
#  PHILIPS-SYSOL2/3.11 UP.Browser/5.0.1.11
#  Vitelcom-Feature Phone1.0 UP.Browser/5.0.2.2(GUI
#  ReqwirelessWeb/2.0.0 MIDP-1.0 CLDC-1.0 Nokia3650
#  SEC-SGHE710
#
# Notice how often one certain brand of these user-agents is handled by this function. I say no more.
#
# Parameter: user-agent string.
# Returns: hash ref or undef.
sub _parseUserAgentRubbish {
  my $proto = shift;
  my $useragent = shift;
  # Old ReqwirelessWeb browsers for Nokia. ReqwirelessWeb/2.0.0 MIDP-1.0 CLDC-1.0 Nokia3650
  if ($useragent =~ /(Nokia)\s*(N-Gage|\d+)$/) {
    return {'vendor' => $1, 'model' => $2};
  }

  # LG Electronics
  elsif ($useragent =~ /^(LG)E?\/(\w+)(\/(\d+\.\d+))?/) {  # LGE/U8150/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.0
    my %result = ('vendor' => $1, 'model' => $2);
    if (defined($4) && length($4)) {
      $result{'version'} = $4;
    }
    return \%result;
  }

  # And now for the worst of all user agents...
  elsif ($useragent =~ /^(PHILIPS)(.+)/) {
    my $vendor = $1;
    my $model;
    my $garbage = uc($2); # everything after the word PHILIPS in uppercase.
    $garbage =~ s/(^\s+|\s+$)//g; # trim
    if ($garbage =~ /^-?(\d+)/) { # match the model names that are just digits.
      $model = $1;
      # PHILIPS855 ObigoInternetBrowser/2.0
      # PHILIPS 535 / Obigo Internet Browser 2.0
    }
    elsif ($garbage =~ /^-?(FISIO)\s*(\d+)/) { # match the FISIO model names.
      $model = "$1$2";
      # PHILIPS-FISIO 620/3
      # PHILIPS-Fisio311/2.1
      # PHILIPS-FISIO311/2.1
    }
    elsif ($garbage =~ /^-?(XENIUM)/) { # match the XENIUM model names.
      $model = $1;
      # PHILIPS-Xenium9@9 UP/4.1.16r
      # PHILIPS-XENIUM 9@9/2.1
      # PHILIPS-Xenium 9@9++/3.14
    }
    elsif ($garbage =~ /^-?([^\s\/]+)/) { # match all other model names that contain no spaces and no slashes.
      $model = $1;
      # PHILIPS-Ozeo UP/4
      # PHILIPS-V21WAP UP/4
      # PHILIPS-Az@lis288 UP/4.1.19m
      # PHILIPS-SYSOL2/3.11 UP.Browser/5.0.1.11
    }
    if (defined($model)) {
      return {'vendor' => $vendor, 'model' => $model};
    }
  }

  # Vitelcom user-agents (used in Spain)
  elsif ($useragent =~ /^(Vitelcom)-(Feature Phone)(\d+\.\d+)/) {
    # Vitelcom-Feature Phone1.0 UP.Browser/5.0.2.2(GUI)  -- this is a TSM 3 or a TSM 4.
    return {'vendor'  => $1,
            'model'   => $2,
            'version' => $3};
  }
  return undef;
}



# Protected object method.
# Parses a user agent string.
# This method simply calls the other 4 _parseUserAgent*() methods to do the work.
# If no match can be made, undef is returned.
# If a match is made, a hash ref is returned containing the compulsory
# keys "vendor" and "model", and the optional keys "version", "imode_cache",
# and "screendims".
#
# Parameter: user-agent string.
# Returns: hash ref or undef.
sub _parseUserAgent {
  my $self = shift;
  my $useragent = shift;
  my $result;
  if ($result = $self->_parseUserAgentStandard($useragent)) {
    $self->{'is_standard'} = 1;
    return $result;
  }
  if ($result = $self->_parseUserAgentMozilla($useragent)) {
    $self->{'is_mozilla'} = 1;
    return $result;
  }
  if ($result = $self->_parseUserAgentImode($useragent)) {
    $self->{'is_imode'} = 1;
    return $result;
  }
  if ($result = $self->_parseUserAgentRubbish($useragent)) {
    $self->{'is_rubbish'} = 1;
    return $result;
  }
  return $result;
}



# Public object method.
# Returns true if the user-agent string passed into the constructor could be parsed, else false.
# If this method returns false, then it's probably not a mobile user agent string that was
# passed into the constructor.
sub success {
  my $self = shift;
  return defined($self->{'vendor'});
}


# Public object method.
# Returns the user agent string as passed into the constructor or read
# from the environment variable HTTP_USER_AGENT.
sub userAgent {
  my $self = shift;
  return $self->{'useragent'};
}



# Public object method.
# Returns the vendor of the handset if success() returns true, else undef.
sub vendor {
  my $self = shift;
  return $self->{'vendor'};
}


# Public object method.
# Returns the model of the handset if success() returns true, else undef.
sub model {
  my $self = shift;
  return $self->{'model'};
}


# Public object method.
# Returns the version (if any) of the user agent.
# The version information isn't always present, nor reliable.
#
# @return string|null
sub version {
  my $self = shift;
  return $self->{'version'};
}


# Public object method.
# Determines if the parsed user-agent string belongs to an i-mode handset.
# Returns boolean.
sub isImode() {
  my $self = shift;
  return $self->{'is_imode'};
}


# Public object method.
# Determines if the parsed user-agent string has a Mozilla 'compatible' format.
# Returns boolean.
sub isMozilla() {
  my $self = shift;
  return $self->{'is_mozilla'};
}


# Public object method.
# Determines if the parsed user-agent string has a standard vendor-model/version format.
# Returns true, if so, else false.
sub isStandard() {
  my $self = shift;
  return $self->{'is_standard'};
}


# Public object method.
# Determines if the parsed user-agent string has a non-standard or messed up format.
# Returns true, if so, else false.
sub isRubbish() {
  my $self = shift;
  return $self->{'is_rubbish'};
}


# Public object method.
# Returns the maximum i-mode cache data size in kb's of the user agent if it is
# an i-mode user-agent, else null.
sub imodeCache() {
  my $self = shift;
  return $self->{'imode_cache'};
}


# Public object method.
# Returns the screen dimensions in the format wxh if this information was parsed
# from the user agent string itself, else undef.
sub screenDims {
  my $self = shift;
  return $self->{'screendims'};
}


# Public object method.
# Determines if this is a Symbian OS Series 60 user-agent string.
sub isSeries60 {
  my $self = shift;
  unless(defined($self->{'is_series60'})) {
    # NokiaN-Gage/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0
    # Mozilla/4.1 (compatible; MSIE 5.0; Symbian OS Series 60 42) Opera 6.0 [fr]
    $self->{'is_series60'} = $self->{'useragent'} =~ /\b(Symbian OS Series 60|SymbianOS\/\S+ Series60)\b/;
  }
  return $self->{'is_series60'};
}


1;


__END__

=head1 NAME

Mobile::UserAgent - mobile user agent string parsing class

=head1 SYNOPSIS

  ### Print the information parsed from a user-agent string:
  use Mobile::UserAgent;
  my $useragent = 'Nokia6600/1.0 (4.09.1) SymbianOS/7.0s Series60/2.0 Profile/MIDP-2.0 Configuration/CLDC-1.0';
  my $uaobj = new Mobile::UserAgent($useragent);
  if ($uaobj->success()) {
    print 'Vendor:    ' . $uaobj->vendor() . "\n";
    print 'Model:     ' . $uaobj->model() . "\n";
    print 'Version:   ' . $uaobj->version() . "\n";
    print 'Series60:  ' . $uaobj->isSeries60() . "\n";
    print 'Imode?:    ' . $uaobj->isImode() . "\n";
    print 'Mozilla?:  ' . $uaobj->isMozilla() . "\n";
    print 'Standard?: ' . $uaobj->isStandard() . "\n";
    print 'Rubbish?:  ' . $uaobj->isRubbish() . "\n";
  }
  else {
    print "Not a mobile user-agent: $useragent\n";
  }


  ### Determine if the client is a mobile device.
  use Mobile::UserAgent ();
  use CGI ();

  # Check 1: (check if it sends a user-agent profile URL in it's headers)
  foreach my $name ('X_WAP_PROFILE','PROFILE','13_PROFILE','56_PROFILE') {
    if (exists($ENV{"HTTP_$name"})) {
      print "Client has a user-agent profile header, so it's probably a mobile device.\n";
      last;
    }
  }

  # Check 2: (check if it supports WML):
  my $q = new CGI();
  if ($q->Accept('text/vnd.wap.wml') == 1) {
    print "Client supports WML so it's probably a mobile device.\n";
  }

  # Check 3: (check if this class can parse it)
  my $uaobj = new Mobile::UserAgent();
  if ($uaobj->success()) {
    print "Client's user-agent could be parsed, so it's a mobile device.\n";
  }


=head1 DESCRIPTION

Parses a mobile user agent string into it's basic constituent parts, the
most important being vendor and model.

One reason for doing this would be to use this information to lookup
vendor-model specific device characteristics in a database. You can use also
use user agent profiles to do this (for which I've developed other classes),
but not all mobile phones have these, especially the older types.
Another reason would be to detect if the visiting client is a mobile handset.

Only real mobile user-agent strings can be parsed succesfully by this class.
Most WAP emulators are not supported because they usually don't use the same
user-agent strings as the devices they emulate.

=head1 CONSTRUCTOR

=over 4

=item $mua = Mobile::UserAgent->new( [$useragent] )

This class method constructs a new Mobile::UserAgent object. You can either pass a user-agent string as parameter or else
let the constructor try to extract it from the HTTP_USER_AGENT environment variable.

=back

=head1 PUBLIC OBJECT METHODS

The public object methods available are:

=over 4

=item $mua->success()

Returns true if the user-agent string passed into the constructor could be parsed, else false.
If this method returns false, then it's probably not a mobile user agent string that was
passed into the constructor.


=item $mua->userAgent()

Returns the user agent string as passed into the constructor or read
from the environment variable HTTP_USER_AGENT.


=item $mua->vendor()

Returns the vendor of the handset if success() returns true, else undef.


=item $mua->model()

Returns the model of the handset if success() returns true, else undef.


=item $mua->version()

Returns the version part, if any, of the parsed user-agent string, else undef.
The version information is often not present or unreliable.


=item $mua->isImode()

Determines if the parsed user-agent string belongs to an i-mode handset.
Returns a boolean.
Examples of such user-agent strings:

 portalmmm/1.0 m21i-10(c10)
 portalmmm/1.0 n21i-10(c10)
 portalmmm/1.0 n21i-10(;ser123456789012345;icc1234567890123456789F)
 portalmmm/2.0 N400i(c20;TB)
 portalmmm/2.0 P341i(c10;TB)
 DoCoMo/1.0/modelname
 DoCoMo/1.0/modelname/cache
 DoCoMo/1.0/modelname/cache/unique_id_information
 DoCoMo/2.0 modelname(cache;individual_identification_information)


=item $mua->isMozilla()

Determines if the parsed user-agent string has a Mozilla 'compatible' format.
Returns a boolean.
Examples of such user-agent strings:

 Mozilla/4.1 (compatible; MSIE 5.0; Symbian OS; Nokia 3650;424) Opera 6.10  [en]
 Mozilla/4.0 (compatible; MSIE 6.0; Nokia7650) ReqwirelessWeb/2.0.0.0
 Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5)
 Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5;Pz063e+wt16)
 Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; PPC; 240x320)
 mozilla/4.0 (compatible;MSIE 4.01; Windows CE;PPC;240X320) UP.Link/5.1.1.5
 Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC; 240x320)
 Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; SmartPhone; 176x220)
 Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; 240x320; PPC)
 Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; Smartphone; 176x220; Mio8380; Smartphone; 176x220)
 Mozilla/4.0 (MobilePhone SCP-8100/US/1.0) NetFront/3.0 MMP/2.0
 Mozilla/2.0(compatible; MSIE 3.02; Windows CE; Smartphone; 176x220)
 Mozilla/4.1 (compatible; MSIE 5.0; Symbian OS Series 60 42) Opera 6.0 [fr]
 Mozilla/SMB3(Z105)/Samsung UP.Link/5.1.1.5


=item $mua->isStandard()

Determines if the parsed user-agent string has a standard vendor-model/version format.
Returns a boolean.
Examples of such user-agent strings:

 Nokia8310/1.0 (05.57)
 NokiaN-Gage/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0
 SAGEM-myX-6/1.0 UP.Browser/6.1.0.6.1.c.3 (GUI) MMP/1.0 UP.Link/1.1
 SAMSUNG-SGH-A300/1.0 UP/4.1.19k
 SEC-SGHE710/1.0


=item $mua->isRubbish()

Determines if the parsed user-agent string has a non-standard or
messed up (to put it in general-public-friendly words) format.
Returns a boolean.
Examples of such user-agent strings:

 LGE/U8150/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.0
 PHILIPS855 ObigoInternetBrowser/2.0
 PHILIPS 535 / Obigo Internet Browser 2.0
 PHILIPS-FISIO 620/3
 PHILIPS-Fisio311/2.1
 PHILIPS-FISIO311/2.1
 PHILIPS-Xenium9@9 UP/4.1.16r
 PHILIPS-XENIUM 9@9/2.1
 PHILIPS-Xenium 9@9++/3.14
 PHILIPS-Ozeo UP/4
 PHILIPS-V21WAP UP/4
 PHILIPS-Az@lis288 UP/4.1.19m
 PHILIPS-SYSOL2/3.11 UP.Browser/5.0.1.11
 Vitelcom-Feature Phone1.0 UP.Browser/5.0.2.2(GUI
 ReqwirelessWeb/2.0.0 MIDP-1.0 CLDC-1.0 Nokia3650
 SEC-SGHE710

=item $mua->imodeCache()

Returns the maximum i-mode cache data size in kb's of the user agent if it is an i-mode user-agent, else undef.


=item $mua->screenDims()

Returns the screen dimensions in the format wxh if this information was parsed
from the user agent string itself, else undef. Only a few handsets contain this information
in the user-agent string such as these that use operating systems from the company
I hate most:

 mozilla/2.0 (compatible; MSIE 3.02; Windows CE; PPC; 240x320)
 mozilla/4.0 (compatible;MSIE 4.01; Windows CE;PPC;240X320) UP.Link/5.1.1.5
 Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC; 240x320)
 Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; SmartPhone; 176x220)
 Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; 240x320; PPC)
 Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; Smartphone; 176x220; Mio8380; Smartphone; 176x220)
 Mozilla/4.0 (MobilePhone SCP-8100/US/1.0) NetFront/3.0 MMP/2.0
 Mozilla/2.0(compatible; MSIE 3.02; Windows CE; Smartphone; 176x220)


=item $mua->isSeries60

Determines if the parsed user-agent string belongs to a Symbian OS Series 60 handset.
Examples of such user-agent strings:

 NokiaN-Gage/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0
 Mozilla/4.1 (compatible; MSIE 5.0; Symbian OS Series 60 42) Opera 6.0 [fr]
 Nokia6600/1.0 (4.09.1) SymbianOS/7.0s Series60/2.0 Profile/MIDP-2.0 Configuration/CLDC-1.0


=back

=head1 DEVELOPERS

Co-developers are very welcome. Please let me know if you want to help maintain this class.
Since the mobile world is evolving rapidly, this class will have to keep up with it when
new vendors and standards emerge in user-agent strings.

The project homepage is: http://sourceforge.net/projects/mobileuseragent/

=head1 RESOURCES

http://sourceforge.net/projects/mobileuseragent/

http://www.handy-ortung.com

http://www.mobileopera.com/reference/ua

http://www.appelsiini.net/~tuupola/php/Imode_User_Agent/source/

http://www.zytrax.com/tech/web/mobile_ids.html

http://webcab.de/wapua.htm

http://www.nttdocomo.co.jp/english/p_s/i/tag/s2.html

http://test.waptoo.com/v2/skins/waptoo/user.asp

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. There is NO warranty; not even for
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 AUTHOR

Craig Manley

=cut
