# Net::Dev::Tools::SyslogMessage.pm
#
# Copyright (c) 2007 Dmitri Sologoubenko <dmitri.sologoubenko@gmail.com>. 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::Dev::Tools::SyslogMessage;

use 5.006001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    syslog_getFacilityName
    syslog_getFacilityCode
    syslog_getSeverityName
    syslog_getSeverityCode
    syslog_packPriority
    syslog_unpackPriority
    syslog_dumpMessage
    syslog_parseMessage
);

our $VERSION = '1.01';

our %SYSLOG_FACILITY_CODES = (
   'kern' => 0, 'kernel' => 0, 'user' => 1, 'mail' => 2, 'daemon' => 3, 'auth' => 4, 'syslog' => 5, 'lpr' => 6, 'news' => 7,
   'uucp' => 8, 'cron' => 9, 'authpriv' => 10, 'ftp' => 11, 'ntp' => 12, 'audit' => 13, 'alert' => 14, 'at' => 15, 'local0' => 16,
   'local1' => 17, 'local2' => 18, 'local3' => 19, 'local4' => 20, 'local5' => 21, 'local6' => 22, 'local7' => 23,
);


our %SYSLOG_FACILITY_NAMES = (
   0 => 'kern', 1 => 'user', 2 => 'mail', 3 => 'daemon', 4 => 'auth', 5 => 'syslog', 6 => 'lpr', 7 => 'news', 8 => 'uucp',
   9 => 'cron', 10 => 'authpriv', 11 => 'ftp', 12 => 'ntp', 13 => 'audit', 14 => 'alert', 15 => 'at', 16 => 'local0',
   17 => 'local1', 18 => 'local2', 19 => 'local3', 20 => 'local4', 21 => 'local5', 22 => 'local6', 23 => 'local7',
);

our %SYSLOG_SEVERITY_NAMES = (
   0  => 'emerg', 1  => 'alert', 2  => 'crit', 3  => 'err', 4  => 'warn', 5  => 'notice', 6  => 'info', 7  => 'debug'
);

our %SYSLOG_SEVERITY_CODES = (
   'emerg' => 0, 'emergency' => 0, 'alert' => 1, 'crit' => 2, 'critical' => 2, 'err' => 3, 'error' => 3,
   'warn' => 4, 'warning' => 4, 'notice' => 5, 'info' => 6, 'information' => 6, 'informational' => 6, 'debug' => 7,
);

our @SYSLOG_FACILITIES = qw( 
    kern    user     mail      daemon   auth     syslog   lpr       news    
    uucp    cron     authpriv  ftp      ntp      audit    alert     at
    local0  local1   local2    local3   local4   local5   local6    local7
);
our @SYSLOG_SEVERITIES = qw( emerg alert crit err warn notice info debug );

our $SYSLOG_DEFAULT_PRI = 13;		# RFC 3164 § 4.3.3

our %SYSLOG_MONTH_NAMES = ( 
	1=>'Jan', 2=>'Feb', 3=>'Mar', 4=>'Apr', 5=>'May', 6=>'Jun', 
	7=>'Jul', 8=>'Aug', 9=>'Sep', 10=>'Oct', 11=>'Nov', 12=>'Dec', 
);
our %SYSLOG_MONTH_CODES = (
	'Jan'=>1, 'Feb'=>2, 'Mar'=>3, 'Apr'=>4, 'May'=>5, 'Jun'=>6, 
	'Jul'=>7, 'Aug'=>8, 'Sep'=>9, 'Oct'=>10, 'Nov'=>11, 'Dec'=>12,
);

our $SYSLOG_REGEX_PRI              = '<(\d{1,3})>';	# ex. "<123>"
our $SYSLOG_REGEX_TIMESTAMP_STRICT = '(([JFMASOND]\w\w) {1,2}(\d+) ((\d{2}):(\d{2}):(\d{2})))';		# ex. "Jan  1 12:23:59"
our $SYSLOG_REGEX_TIMESTAMP        = '(([JFMASONDjfmasond]\w\w) {1,2}(\d+) ((\d{2}):(\d{2}):(\d{2})))';	# ex. "jan  3 13:22:12"
our $SYSLOG_REGEX_HOSTNAME  	   = '([a-zA-Z0-9_\.\-]+)';	# Hostname or IP address
our $SYSLOG_REGEX_MSG		   = '(.+)';
our $SYSLOG_REGEX_PATTERN          = sprintf('^%s%s %s$', $SYSLOG_REGEX_PRI, $SYSLOG_REGEX_TIMESTAMP, $SYSLOG_REGEX_MSG);
our $SYSLOG_REGEX_TAG              = '(([^\[: ]+)(\[(\d+)\])?):';

sub syslog_getFacilityName {
	my $code = shift;
	return undef unless(defined($code));
	return $SYSLOG_FACILITY_NAMES{$code};
}

sub syslog_getFacilityCode {
	my $name = shift;
	return undef unless(defined($name));
	return $SYSLOG_FACILITY_CODES{$name};
}

sub syslog_getSeverityName {
	my $code = shift;
	return undef unless(defined($code));
	return $SYSLOG_SEVERITY_NAMES{$code};
}

sub syslog_getSeverityCode {
	my $name = shift;
	return undef unless(defined($name));
	return $SYSLOG_SEVERITY_CODES{$name};
}

sub syslog_packPriority {
    my ($fac,$sev) = @_;
    return undef unless(defined($fac) && defined($sev));
    $fac = $SYSLOG_FACILITY_CODES{$fac} unless ($fac =~ /^\d+$/);
    $sev = $SYSLOG_SEVERITY_CODES{$sev} unless ($sev =~ /^\d+$/);
    return (int($fac) << 3) + int($sev);
}

sub syslog_unpackPriority { # syslog_PRI_unpack
    my $pri = int(shift);
    return ($pri >> 3, $pri & 7);
}

sub syslog_dumpMessage {
	my ($stream, $msg) = @_;
	return unless (defined($stream));
	unless (defined($msg)) {
		print $stream "syslog {undef};";
		return;
	}
	print $stream 'syslog { '."\n";
	print $stream "\t".'PRI='.$msg->{'PRI'}."\n" if (defined($msg->{'PRI'}));
	print $stream "\t".'facility='.$msg->{'facility'}."\n" if (defined($msg->{'facility'}));
	print $stream "\t".'severity='.$msg->{'severity'}."\n" if (defined($msg->{'severity'}));
	print $stream "\t".'timestamp='.$msg->{'timestamp'}."\n" if (defined($msg->{'timestamp'}));
	print $stream "\t".'date='.sprintf('%02d/%02d/%04d %02d:%02d:%02d'."\n", $msg->{'timestamp_D'}, $msg->{'timestamp_M'}, $msg->{'timestamp_Y'}, $msg->{'timestamp_h'}, $msg->{'timestamp_m'}, $msg->{'timestamp_s'}) if (defined($msg->{'timestamp_D'}));
	print $stream "\t".'hostname='.$msg->{'hostname'}."\n" if (defined($msg->{'hostname'}));
	print $stream "\t".'program='.$msg->{'program'}."\n" if (defined($msg->{'program'}));
	print $stream "\t".'pid='.$msg->{'pid'}."\n" if (defined($msg->{'pid'}));
	print $stream "\t".'HEADER='.$msg->{'HEADER'}."\n" if (defined($msg->{'HEADER'}));
	print $stream "\t".'tag='.$msg->{'tag'}."\n" if (defined($msg->{'tag'}));
	print $stream "\t".'MSG='.$msg->{'MSG'}."\n" if (defined($msg->{'MSG'}));
	print $stream "\t".'content='.$msg->{'content'}."\n" if (defined($msg->{'content'}));
	print $stream '};'."\n";
}

sub syslog_parseMessage {
	my $msg = substr(shift, 0, 1024);
	my %ret = ();

	$ret{'PRI'} = '';		# OK
	$ret{'facility'} = 0;		# OK
	$ret{'severity'} = 0;		# OK
	$ret{'HEADER'} = '';		# OK
	$ret{'timestamp'} = 0;		# OK
	$ret{'timestamp_Y'} = 1900;	# OK
	$ret{'timestamp_M'} = 1;	# OK
	$ret{'timestamp_D'} = 1;	# OK
	$ret{'timestamp_h'} = 0;	# OK
	$ret{'timestamp_m'} = 0;	# OK
	$ret{'timestamp_s'} = 0;	# OK
	$ret{'hostname'} = '';		# OK
	$ret{'MSG'} = '';		# OK
	$ret{'tag'} = '';		# OK
	$ret{'content'} = '';		# OK
	$ret{'program'} = '';		# OK
	$ret{'pid'} = -1;		# OK
	
	if ($msg =~ /^$SYSLOG_REGEX_PRI(.*)$/) {
		# 4.3.1, 4.3.2 - Valid PRI
		$ret{'PRI'} = $1;
		$msg = $2;
		($ret{'facility'}, $ret{'severity'}) = &syslog_unpackPriority($ret{'PRI'});
		# Checking timestamp
		if ($msg =~ /^$SYSLOG_REGEX_TIMESTAMP (.*)$/) {
			# 4.3.1 - Valid PRI and TIMESTAMP
			$ret{'timestamp'} = $1;
			$ret{'timestamp_M'} = $SYSLOG_MONTH_CODES{$2};
			$ret{'timestamp_D'} = int($3);
			my @tim = localtime(time());
			$ret{'timestamp_Y'} = $tim[5]+1900;
			$ret{'timestamp_h'} = int($5);
			$ret{'timestamp_m'} = int($6);
			$ret{'timestamp_s'} = int($7);
			$msg = $8;
		} else {
			# 4.3.2 - Valid PRI but no TIMESTAMP or invalid TIMESTAMP
			my @tim = localtime(time());
			$ret{'timestamp'} = sprintf('%s % d %02d:%02d:%02d', $SYSLOG_MONTH_NAMES{$tim[4]+1}, $tim[3], $tim[2], $tim[1], $tim[0]);
			$ret{'timestamp_M'} = $tim[4]+1;
                        $ret{'timestamp_D'} = $tim[3];
                        $ret{'timestamp_Y'} = $tim[5]+1900;
                        $ret{'timestamp_h'} = $tim[2];
                        $ret{'timestamp_m'} = $tim[1];
                        $ret{'timestamp_s'} = $tim[0];
		}
		$ret{'MSG'} = $msg;
	} else {
		# 4.3.3 - No PRI or unidentifiable PRI
		$ret{'PRI'} = $SYSLOG_DEFAULT_PRI;
		($ret{'facility'}, $ret{'severity'}) = &syslog_unpackPriority($ret{'PRI'});
		my @tim = localtime(time());
                $ret{'timestamp'} = sprintf('%s % d %02d:%02d:%02d', $SYSLOG_MONTH_NAMES{$tim[4]+1}, $tim[3], $tim[2], $tim[1], $tim[0]);
		$ret{'MSG'} = $msg;
	}

	if ($msg =~ /^$SYSLOG_REGEX_HOSTNAME (.*)$/) {
		$ret{'hostname'} = $1;
		$msg = $2;
	} else {
		$ret{'hostname'} = '0.0.0.0';
	}

	$ret{'HEADER'} = sprintf('%s %s', $ret{'timestamp'}, $ret{'hostname'});
	$ret{'MSG'} = $msg;

	if ($msg =~ /$SYSLOG_REGEX_TAG (.*)$/) {
		$ret{'tag'} = $1;
		$ret{'program'} = $2;
		$ret{'pid'} = ((!defined($4) || ($4 eq ''))?-1:int($4));
		$msg = $5;
	}
	$ret{'content'} = $msg;

	return \%ret;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

Net::Dev::Tools::SyslogMessage - Perl library for Unix/Linux Syslog message parsing

=head1 SYNOPSIS

  use Net::Dev::Tools::SyslogMessage;
  my $msg = syslog_parseMessage($msgstr);
  syslog_dumpMessage(\*STDOUT, $msg);

=head1 DESCRIPTION

This library is written entirely in Perl, based on, but not fully compliant to,
IETF RFC 3164 - The BSD Syslog Protocol.

=head2 EXPORT

=over 4

=item syslog_getFacilityName (facilityCode)

Returns the syslog facility name (I<string>) that matches the given numerical code C<facilityCode>.
Returns C<undef> if C<facilityCode> is undefined or does not match any RFC 3164 numerical facility code.

=item syslog_getFacilityCode (facilityName)

Returns the syslog facility numerical code (I<int>, RFC 3164) that matches the given C<facilityName>.
Returns C<undef> if C<facilityName> is undefined or does not match any RFC 3164 facility code.

=item syslog_getSeverityName (severityCode)

Returns the syslog severity name (I<string>) that matches the given numerical code C<severityCode>.
Returns C<undef> if C<severityCode> is undefined or does not match any RFC 3164 numerical severity code.

=item syslog_getSeverityCode (severityName)

Returns the syslog severity numerical code (I<int>, RFC 3164) that matches the given C<severityName>.
Returns C<undef> if C<severityName> is undefined or does not match any RFC 3164 severity code.

=item syslog_packPriority (facility,severity)

Given facility and severity (RFC 3164) codes or names, returns packed syslog priority code (C<string>).
Returns C<undef> if C<facility> or C<severity> are undefined.

=item syslog_unpackPriority (priorityCode)

Given a syslog priority numerical code (C<int>), translates it in a list containing
(in order) syslog facility code and severity code.
Returns C<undef> if C<priorityCode> is undefined.

=item syslog_dumpMessage (outStream,syslogMessageObj)

Prints textual form of a parsed syslog message hashref C<syslogMessageObj> on stream C<outStream>.

=item syslog_parseMessage (syslogMessageStr)

Parses a received syslog message C<syslogMessageStr> and returns a reference to a hash
containing syslog message parsed elements.

=back

=head1 SEE ALSO

IETF RFC 3164 - The BSD Syslog Protocol
E<lt>http://www.ietf.org/rfc/rfc3164.txtE<gt>

=head1 AUTHOR

Dmitri Sologoubenko, E<lt>dmitri.sologoubenko@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Dmitri Sologoubenko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
