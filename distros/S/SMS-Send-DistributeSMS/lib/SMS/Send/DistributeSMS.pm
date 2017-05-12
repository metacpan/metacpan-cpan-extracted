package SMS::Send::DistributeSMS;

use warnings;
use strict;

=head1 NAME

SMS::Send::DistributeSMS - SMS::Send DistributeSMS Driver

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS
  
  # Create a sender
  my $send = SMS::Send->new('DistributeSMS'
    _account_no  => '1234',
    _login       => 'login',
    _password    => 'password',
    _proxy       => 'http://host:port/', # optional.
    _verbose     => 1, # optional. for debugging purposes only.
  );
  
  # Send a message
  $send->send_sms(
  	text  => 'Hi there',
  	to    => '+61-400-111-222',
  	_from => 'TEST',
  );

  # Get send status (NOTE: specific to this driver)
  my @status = $sms->status_sms();
  print "status: $status[0] (state: $status[1])\n";

=head1 DESCRIPTION

SMS::Send::DistributeSMS is a driver for L<SMS::Send> for
the SMS gateway at www.distributesms.com.au.

It currently supports the ability to send an SMS to any country
in the world.  This is possible by including a translation map
from international dialing codes to DistributeSMS specific IDs,
requiring no intervention or assistance on the programmer's behalf.

As an added bonus, retrieving the send status is possible,
although specific to this driver only.

Bugs, fixes, flames, rants, patches and messages are welcome.

=head1 AUTHOR

David Sobon, C<< <dsobon.at.cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sms-send-distributesms at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-DistributeSMS>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Send::DistributeSMS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Send-DistributeSMS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Send-DistributeSMS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-Send-DistributeSMS>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-Send-DistributeSMS>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 David Sobon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

use URI::Escape;
use base 'SMS::Send::Driver';

require LWP::UserAgent;
require HTTP::Cookies;

#####################################################################
# Constructor

sub new {
	my $class = shift;
	my %args  = @_;

	#
    # Create the object
	#
	my $self = bless {
		ua            => undef,
		cj            => undef,
		verbose       => $args{'_verbose'},
		proxy         => $args{'_proxy'},
		messages      => [],
		private       => \%args,

		account_no    => $args{'_account_no'},
		login         => $args{'_login'},
		password      => $args{'_password'},

		# private variables.
		_MessageID    => 0,
		_loggedin     => 0,
	}, $class;

	return $self;
}

#####################################################################
# PUBLIC METHODS

#####
#  Usage: $class->send_sms(%args);
# Return: 1 on success, croak-before-return on failure.
#
sub send_sms {
    my $self = shift;
	my %hash = @_;

	# error: to
	if (!$hash{'to'}) {
		Carp::croak("[send_sms] to number not specified");
	}

	# login.
	$self->_login();
	$self->_getCredits();

	# post.
	my $url  = "http://www.distributesms.com.au/cgi-bin/sm.pl";
	my %dial = $self->_getDialInfoByNumber( $hash{'to'} );
	$hash{'to'} =~ s#^\+$dial{'DialCode'}##;

	my %post = (
		PhoneNumber     => $hash{'to'},
		ReplyTo         => $hash{'_from'} || '',
		Message         => uri_escape( $hash{'text'} ),
		DialCodeSeq     => $dial{'DialCodeSeq'},
		PhoneGroup      => "",
		Send            => 'send',
	);

	# error: dialcodeseq could not be determined.
	if (!$post{'DialCodeSeq'}) {
		Carp::croak("send_sms: could not determine DialCodeSeq from $hash{'to'}");
	}

	# send.
	$self->print('verbose', "[send_sms] sending message:");
	$self->print('verbose', "[send_sms]   to: $post{'PhoneNumber'}");
	$self->print('verbose', "[send_sms]   from: $post{'ReplyTo'}") if ($post{'ReplyTo'});
	$self->print('verbose', "[send_sms]   dialcode: $post{'DialCodeSeq'}");
	$self->print('verbose', "[send_sms]   message: $post{'Message'}");
	my $res = $self->_getURL($url, \%post);

	# error: check if send failed.
    if ($res->content !~ /Processed/) {
		my $data = $res->content();
		$data =~ s#<\/?(body|html)>##gi;

		Carp::croak("send_sms: could not send sms - $data");
    }

	# if successful, get the current message ID, so we can
	# determine the message status.
	$self->_setLastMessageID();

	return 1;
}

#####
#  Usage: $class->status_sms([$mid]);
#   Args: $mid - if not set, $class->{_MessageID} is used.
# Return: failure: array: current status string, state (YES/NO).
# Return: success: array: (undef, undef)
#   Note: this method is specific to DistributeSMS as there
#         is no standardized way to obtain whether an sms
#         was successfully delivered or not.
#         to be called $MODULE->_OBJECT->status_sms($mid);
#
sub status_sms {
	my $class   = shift;
	my ($mid)   = @_ || $class->{'_MessageID'};

	# error: no mid specified.
	if (!$mid) {
		Carp::croak("error: status_sms: no messageid specified");
	}

	# if not logged in yet, log in!
	if (!$class->{'_loggedin'}) {
		$class->_login();
	}

	# todo: check if $mid is valid?
	my $hashref = $class->_getMessageIDStatus($mid);
	my %status  = %{ $hashref };

	# valid status strings.
	my @_status = (
		'Scheduled',
		'Sent to Gateway',
		'Delivered to Network',
		'Delivered to Phone'
	);

	# return last status.
	for (my $i=0; $i<scalar(@_status); $i++) {
		my $status = $_status[$#_status - $i];
		my $state  = $status{ $status };
		next unless ($state);

		return ($status, $state);
	}

	return (undef, undef);
}

#####
#  Usage: $class->print($level, $string);
#   Args:
#	$level  - 'verbose'
#	$string - string to print.
# Return: undef or return code from printf()
#
sub print {
	my $class = shift;
	my ($level, $string) = @_;

	# error: level is NULL.
	if (!$level) {
		Carp::croak("DistributeSMS::print: no level specified.");
	}

	# error: invalid level.
	if ($level !~ /^(verbose)$/) {
		Carp::croak("DistributeSMS::print: invalid level: $level");
	}

	# error: string is NULL.
	if (!$string) {
		Carp::croak("DistributeSMS::print: string is NULL.");
	}

	# do not print unless this level has been set via the new constructor
	return unless ($class->{ $level });

	printf "::: %s\n", $string;
}

#####################################################################
# PRIVATE METHODS
#####################################################################

#####
#  Usage: $class->_getMessageIDStatus( $MessageID );
# Return: %hash reference of status and states.
#
sub _getMessageIDStatus {
	my $class = shift;
	my ($mid) = @_;
	my $url   = "http://www.distributesms.com.au/cgi-bin/md.pl?mls=$mid";
	my $res   = $class->_getURL($url);
	my $data  = $res->content();
	my %status;

	$class->print('verbose', "[getMessageIDStatus] length(data) == ".length($data) );

	# we could use HTML::TreeBuilder... but that is just overkill!
	while ($data =~ s#(<tr class=body.*?<\/tr>)##) {
		my $row = $1;
		my @col;
###		$class->print('verbose', "[getMessageIDStatus] line: $row");

		while ($row =~ s#<td.*?>(.*?)(</td>)##) {
			$class->print('verbose', "[getMessageIDStatus] col: $1");
			push(@col, $1);
		}

		my $status = $col[0];
		my $state  = $col[2];

		# status:
		#   Scheduled
		#   Sent to Gateway
		#   Delivered to Network
		#   Delivered to Phone

		$class->print('verbose', "[getMessageIDStatus] status{ $status } = $state;");

		$status{ $status } = $state;
	}

	return \%status;
}

#####
#   Desc: get the last/current message ID and store it privately.
#  Usage: $class->_getLastMessageID();
# Return: $MessageID
#
sub _getLastMessageID {
	my $class = shift;
	return $class->{'_MessageID'};
}

#####
#   Desc: set the last/current message ID and store it privately.
#  Usage: $class->_setLastMessageID();
# Return: 0 on failure, 1 on success.
#   Note: MessageID is determined within the function itself, not provided
#         as an input. We are misleading!
#
sub _setLastMessageID {
	my $class = shift;
	my $url   = "http://www.distributesms.com.au/cgi-bin/ml.pl";
	my $res   = $class->_getURL($url);

	if ($res->content() !~ /DeliveryStatus\('\/cgi-bin\/md.pl\?mls=(\d+)'/) {
		# todo: warning message?
		return 0;
	}

	$class->{'_MessageID'} = $1;

	return 1;
}

#####
#  Usage: $class->_getDialInfoByNumber( $number );
# Return: undef on failure.
# Return: %hash on success:
#   'CountryCode' - ISO3166-1-alpha-2 country code.
#   'CountryName' - country string.
#   'DialCodeSeq' - DistributeSMS specific integer.
#   'DialCode'    - international dial code.
#
sub _getDialInfoByNumber {
	my $class    = shift;
	my ($number) = @_;
	$number      =~ s/^\+//;

	while (<DATA>) {
		chop;

		next unless (/^(\S{2}):(.*?):(\d+):(\d+)/);
		my %hash = (
			'CountryCode' => $1,
			'CountryName' => $2,
			'DialCodeSeq' => $3,
			'DialCode'    => $4,
		);

		if ($number =~ /^$hash{'DialCode'}/) {
			$class->print('verbose', "[getDialInfoByNumber] number $number matched dialcode $hash{'DialCode'}");
			return %hash;
		}
	}

	# error.
	Carp::croak("getDialInfoByNumber: could not determine dial info by $number");
}

#####
#  Usage: $class->_login();
# Return: 1 for failure, 0 for success.
#
sub _login {
	my $class = shift;

	if ($class->{'_loggedin'}) {
		$class->print('verbose', "[login] already logged in!");
		return 0;
	}

	$class->print('verbose', "[login] logging in");

	#
	# error handling.
	#

	# error: no account_no
	if (!$class->{'account_no'}) {
		Carp::croak("login: no account_no specified");
	}

	# error: user
	if (!$class->{'login'}) {
		Carp::croak("login: no login specified");
	}

	# error: password.
	if (!$class->{'password'}) {
		Carp::croak("login: no password specified");
	}

	#
	# post details.
	#
	my %post  = (
		AccountNo  => $class->{'account_no'},
		UserId1    => $class->{'login'},
		Password1  => $class->{'password'},
		Remember1  => 1,
		OK1        => 'ok',
		Retry      => '',
    );

	#
	# login.
	#
	$class->print('verbose', "[login] logging in with");
	$class->print('verbose', "[login]   account number: ".$post{'AccountNo'} );
	$class->print('verbose', "[login]   username: ".$post{'UserId1'} );
	$class->print('verbose', "[login]   password: ".$post{'Password1'} );

	my $url = "http://www.distributesms.com.au/cgi-bin/li.pl";
	my $res = $class->_getURL($url, \%post);

	#
	# error: login failed.
	#
	if ($res->content() !~ /sm\.pl/) {
		my $data = $res->content();
#		$data =~ s#<\/?(body|html)>##gi;

		$class->print('verbose', "[login] ".$data);

		die("login: could not log in");
	}

	$class->print('verbose', "[login] successful!");
	$class->{'_loggedin'} = 1;

	return 1;
}

#####
#  Usage: $class->_getCredits();
# Return: 0 for failure, # of credits left for success.
#
sub _getCredits {
	my $class = shift;
	my $url   = "http://www.distributesms.com.au/cgi-bin/sm.pl";
	my $res   = $class->_getURL($url);
	my $check = 0;

	$check++ if ($res->content() =~ /Pre-Paid Messages Left/);
	$check++ if ($res->content() =~ /Leave blank to send immediately/);

	#
	# error: login or something weird failed.
	#
	if (!$check) {
		my $data = $res->content();
		$data =~ s#<\/?(body|html)>##gi;

		Carp::croak("getCredits: login failed - $data");
	}

	# todo: change so it returns # of credits left.
	return 1;
}

#####
#  Usage: $class->_getURL($url, $postref);
# Return: $res object
#
sub _getURL {
	my $class = shift;
	my ($url, $postref) = @_;
	my $req;
	my $res;

	# initialize.
	if (!$class->{'ua'} || !$class->{'cj'}) {
		$class->{'cj'} = $class->_newCJ();
		$class->{'ua'} = $class->_newUA();
	}

	# todo: check if url exists and is valid.
	# todo: if postref exists and is a hash reference.

	$class->print('verbose', "[getURL] url: $url");

	if ($postref) {
		my %post = %{ $postref };
		my $post = join('&', map { $_.'='.$post{$_} } keys %post);

		foreach (sort keys %post) {
			$class->print('verbose', "[getURL] post: $_ => $post{$_}");
		}
		$class->print('verbose', "[getURL] POST: $post");

		$req = HTTP::Request->new('POST', $url);
		$req->content_type('application/x-www-form-urlencoded');
		$req->content($post);
	} else {
		$req = HTTP::Request->new('GET', $url);
	}

	# todo: convert all $class->{'cj'} to $cj = $class->_getCJ();
	$class->{'cj'}->add_cookie_header($req);
	$res = $class->{'ua'}->request($req);
	$class->{'cj'}->extract_cookies($res);

	$class->{'cj'}->scan( sub {
		$class->{'cj'}->set_cookie(@_);
	} );

	# error: http 500 or something catastrophic.
	if ($res->code() =~ /^5/ && $res->content() =~ /timeo/i) {
		Carp::croak("getURL: proxy is dead; please update.");
	}

	return $res;
}

#####
#  Usage: $class->_newCJ();
# Return: $cj object.
#
sub _newCJ {
	my $class = shift;
	my $cj    = new HTTP::Cookies;

	return $cj;
}

#####
#  Usage: $class->_newUA();
# Return: $ua object.
#
sub _newUA {
	my $class = shift;
	my $ua    = new LWP::UserAgent;

	$ua->agent("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)");
	$ua->cookie_jar($class->{'cj'});
	$ua->timeout(10);

	# set useragent.
	if ($class->{'agent'}) {
		$class->print('verbose', "[newUA] setting useragent to ".$class->{'agent'} );
		$ua->agent( $class->{'agent'} );
	}

	# set proxy.
	if ($class->{'proxy'}) {
		$class->print('verbose', "[newUA] setting proxy to ".$class->{'proxy'} );
		$ua->proxy('http', $class->{'proxy'});
	}

	return $ua;
}

1;

###########################################################
# DATA:
###########################################################

__DATA__
# COUNTRYCODE:COUNTRYNAME:DIALCODE:DIALCODESEQ
AC:Ascension Island:13:247
AC:Reunion Island:187:247
AD:Andorra:5:376
AE:United Arab Emirates:233:971
AF:Afghanistan:1:93
AG:Barbuda:21:1268
AG:Antigua:9:1268
AI:Anguilla:7:1264
AL:Albania:2:355
AM:Armenia:11:374
AN:Netherlands Antilles:163:599
AO:Angola:6:244
AR:Argentina:10:54
AS:American Samoa:4:1684
AT:Austria:15:43
AU:Australia:14:61
AW:Aruba:12:297
AZ:Azerbaijan:16:994
BA:Bosnia and Herzegovina:32:387
BB:Barbados:20:1246
BD:Bangladesh:19:880
BE:Belgium:23:32
BF:Burkina Faso:38:226
BG:Bulgaria:37:359
BH:Bahrain:18:973
BI:Burundi:39:257
BJ:Benin:25:229
BM:Bermuda:26:1441
BN:Brunei Darussalam:36:673
BO:Bolivia (AES):28:591
BO:Bolivia (BOLIVIATEL):29:591
BO:Bolivia (ENTEL):30:591
BO:Bolivia (TELEDATA):31:591
BR:Brazil:34:55
BS:Bahamas:17:1242
BT:Bhutan:27:975
BW:Botswana:33:267
BY:Belarus:22:375
BZ:Belize:24:501
CA:Canada:42:1
CC:Cocos Islands:51:61
CD:Democratic Republic of Congo:142:243
CD:Democratic Republic of Congo:57:243
CF:Central African Republic:45:236
CG:Republic of Congo:56:242
CH:Switzerland:215:41
CI:Côte d'Ivoire:116:225
CK:Cook Islands:58:682
CL:Chile:48:56
CL:Chile:72:56
CM:Cameroon:41:237
CN:People's Republic of China:49:86
CO:Colombia:52:57
CO:Colombia:53:57
CO:Colombia:54:57
CR:Costa Rica:59:506
CU:Cuba:61:53
CV:Cape Verde:43:238
CX:Christmas Island:50:61
CY:Cyprus:64:357
CZ:Czech Republic:65:420
DE:Germany:91:49
DJ:Djibouti:68:253
DK:Denmark:66:45
DM:Dominica:69:1767
DO:Dominican Republic:70:1809
DZ:Algeria:3:213
EC:Ecuador:73:593
EE:Estonia:78:372
EG:Egypt:74:20
ER:Eritrea:77:291
ES:Spain:209:34
ET:Ethiopia:79:251
FI:Finland:83:358
FK:Falkland Islands:81:500
FM:Federated States of Micronesia:150:691
FO:Faroe Islands:80:298
FR:France:84:33
GA:Gabon:88:241
GB:United Kingdom:234:44
GD:Grenada:96:1473
GF:French Guiana:86:594
GH:Ghana:92:233
GI:Gibraltar:93:350
GL:Greenland:95:299
GM:The Gambia:89:220
GN:Guinea:102:224
GP:Guadeloupe:97:590
GQ:Equatorial Guinea:76:240
GR:Greece:94:30
GT:Guatemala:100:502
GU:Guam:98:1671
GW:Guinea-Bissau:101:245
GY:Guyana:103:592
HK:Hong Kong:106:852
HN:Honduras:105:504
HR:Croatia:60:385
HT:Haiti:104:509
HU:Hungary:107:36
ID:Indonesia:110:62
IE:Republic of Ireland:113:353
IL:Israel:114:972
IN:India:109:91
IO:British Indian Ocean Territory:67:246
IQ:Iraq:112:964
IR:Iran:111:98
IS:Iceland:108:354
IT:Italy:115:39
JM:Jamaica:117:1876
JO:Jordan:119:962
JP:Japan:118:81
KE:Kenya:121:254
KG:Kyrgyzstan:126:996
KH:Cambodia:40:855
KI:Kiribati:122:686
KM:Comoros:55:269
KN:St. Kitts and Nevis:164:1869
KN:St. Kitts and Nevis:192:1869
KP:North Korea:123:850
KR:South Korea:124:82
KW:Kuwait:125:965
KY:Cayman Islands:44:1345
KZ:Kazakhstan:120:7
LA:Laos:127:856
LB:Lebanon:129:961
LC:St. Lucia:193:1758
LI:Liechtenstein:133:423
LK:Sri Lanka:210:94
LR:Liberia:131:231
LS:Lesotho:130:266
LT:Lithuania:134:370
LU:Luxembourg:135:352
LV:Latvia:128:371
LY:Libya:132:218
MA:Morocco:156:212
MC:Monaco:153:377
MD:Moldova:152:373
MG:Madagascar:138:261
MH:Marshall Islands:144:692
MK:Republic of Macedonia:137:389
MK:Republic of Macedonia:247:389
MM:Burma:158:95
MN:Mongolia:154:976
MO:Macau:136:853
MP:Northern Mariana Islands:172:1670
MQ:Martinique:145:596
MQ:Martinique:85:596
MR:Mauritania:146:222
MS:Montserrat:155:1664
MT:Malta:143:356
MU:Mauritius:147:230
MV:Maldives:141:960
MW:Malawi:139:265
MX:Mexico:149:52
MY:Malaysia:140:60
MZ:Mozambique:157:258
NA:Namibia:159:264
NC:New Caledonia:165:687
NE:Niger:168:227
NF:Norfolk Island:171:672
NG:Nigeria:169:234
NI:Nicaragua:167:505
NL:Netherlands:162:31
NO:Norway:173:47
NP:Nepal:161:977
NR:Nauru:160:674
NU:Niue:170:683
NZ:New Zealand:166:64
NZ:New Zealand:47:64
OM:Oman:174:968
PA:Panama:178:507
PE:Peru:181:51
PF:French Polynesia:87:689
PG:Papua New Guinea:179:675
PH:Philippines:182:63
PK:Pakistan:175:92
PL:Poland:183:48
PM:St. Pierre and Miquelon:194:508
PR:Puerto Rico:185:1939
PS:Palestinian Authority:177:972
PT:Portugal:184:351
PW:Palau:176:680
PY:Paraguay:180:595
QA:Qatar:186:974
RO:Romania:188:40
RS:Serbia:200:381
RU:Russia:189:7
RW:Rwanda:190:250
SA:Saudi Arabia:198:966
SB:Solomon Islands:206:677
SC:Seychelles:201:248
SD:Sudan:211:249
SE:Sweden:214:46
SG:Singapore:203:65
SH:Saint Helena:191:290
SI:Slovenia:205:386
SK:Slovakia:204:421
SL:Sierra Leone:202:232
SM:San Marino:196:378
SN:Senegal:199:221
SO:Somalia:207:252
SR:Suriname:212:597
ST:São Tomé and Príncipe:197:239
SV:El Salvador:75:503
SY:Syria:216:963
SZ:Swaziland:213:268
TC:Turks and Caicos Islands:229:1649
TD:Chad:46:235
TG:Togo:222:228
TH:Thailand:220:66
TJ:Tajikistan:218:992
TK:Tokelau:223:690
TL:East Timor:71:670
TM:Turkmenistan:228:993
TN:Tunisia:226:216
TO:Tonga:224:676
TR:Turkey:227:90
TT:Trinidad and Tobago:225:1868
TV:Tuvalu:230:688
TW:Republic of China:217:886
TZ:Tanzania:219:255
TZ:Tanzania:249:255
UA:Ukraine:232:380
UG:Uganda:231:256
UY:Uruguay:237:598
UZ:Uzbekistan:238:998
VA:Vatican City:240:39
VC:St. Vincent and the Grenadines:195:1784
VE:Venezuela:241:58
VG:British Virgin Islands:35:1284
VI:U.S. Virgin Islands:236:1340
VN:Vietnam:242:84
VU:Vanuatu:239:678
WF:Wallis and Futuna:244:681
WS:Samoa:245:685
XS:???Shared Cost Service???:243:808
YE:Yemen:246:967
YT:Mayotte:148:262
ZA:South Africa:208:27
ZM:Zambia:248:260
ZW:Zimbabwe:250:263
..:Midway Island:151:1
US:United States:235:1
..:Guantanamo Bay:62:5399
..:Guantanamo Bay:99:5399
..:Fiji Islands:82:679
..:Georgia:90:995
..:Cura?ao:63:599
