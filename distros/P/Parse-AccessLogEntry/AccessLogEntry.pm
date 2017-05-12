package Parse::AccessLogEntry;

use strict;
use warnings;

require Exporter;
our $VERSION = '0.06';

sub new
{
        my $Proto=shift;
        my $Class=ref($Proto) || $Proto;
        my $Self={};
        bless $Self;
        return $Self;
}

sub parse
{
	my $Self=shift;
        my $Line=shift;
        my $Ref;
        my $Rest;
        my $R2;
        ($Ref->{host},$Ref->{user},$Ref->{date},$Rest)= $Line=~m,^([^\s]+)\s+-\s+([^ ]+)\s+\[(.*?)\]\s+(.*),;
        my @Dsplit=split(/\s+/,$Ref->{date});
	$Ref->{diffgmt}=$Dsplit[1];
	my @Ds2=split(/\:/,$Dsplit[0],2);
        $Ref->{date}=$Ds2[0];
        $Ref->{time}=$Ds2[1];
        if ($Rest)
        {
                ($Ref->{rtype},$Ref->{file},$Ref->{proto},$Ref->{code},$Ref->{bytes},$R2)=split(/\s/,$Rest,6);
		$Ref->{rtype}=~tr/\"//d;
		$Ref->{proto}=~tr/\"//d;
                if ($R2)
                {
                        my @Split=split(/\"/,$R2);
                        $Ref->{refer}=$Split[1];
                        $Ref->{agent}=$Split[3];
                }
        }
        return $Ref;
}


1;
__END__
=head1 NAME

Parse::AccessLogEntry - Parse one line of an Apache access log

=head1 SYNOPSIS

  use Parse::AccessLogEntry;
  my $P=Parse::AccessLogEntry::new();

  # $Line is a string containing one line of an access log
  my $Hashref=$P->parse("$Line");

=head1 DESCRIPTION

There are several modules that focus on generating web reports,
like Apache::ParseLog.  There are also several places on the
web where you can find the regex required to parse the lines 
on your own.  This is simply for users who dont want to mess
with any of that, and just want to have a quick way to implement
this functionality in their code.

This module handles the standard Apache access_log formats, 
including the combined log file format that includes the 
referrer and user-agent.  The return form the parse() call
is a hashref with key names being the fields in the line just
parsed.

  $Hashref->{host}    client ip of the request
  $Hashref->{user}    user logged in ("-" for none)
  $Hashref->{date}    date of the request
  $Hashref->{time}    server time of the request
  $Hashref->{diffgmt} server offset from GMT 
  $Hashref->{rtype}   type of request (GET, POST, etc)
  $Hashref->{file}    file requested
  $Hashref->{proto}   protocol used (HTTP/1.1, etc)
  $Hashref->{code}    code returned by apache (200, 304, etc)
  $Hashref->{bytes}   number of bytes returned to the client
  $Hashref->{refer}   referrer
  $Hashref->{agent}   user-agent

If you noticed that the RFC1413 field is missing, you're right. 
I don't plan on including this anytime soon, since hardly anyone
uses it.

This is a pretty early release.  But since much of this code is
lifted from other sources it should be pretty reliable.  If 
anybody has any ideas on how to make it more robust then let me 
know.

=head1 AUTHOR

Marc Slagle - marc.slagle@online-rewards.com

=head1 SEE ALSO

L<perl>.

=cut

