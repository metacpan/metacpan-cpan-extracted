package SNMP::LogParserDriver::ProxyLog;
use strict;
use warnings;
use parent 'SNMP::LogParserDriver';

our %nsCacheIPClient;
our %nsCacheUserClient;
our %nsCacheURL;
our @nsCacheIPClient;
our @nsCacheUserClient;
our @nsCacheURL;

=head1 NAME SNMP::LogParserDriver::ProxyLog

SNMP::LogParserDriver::ProxyLog

=head1 SYNOPSIS

A bit more complicated class

=head1 DESCRIPTION

example class to parse proxy files

=head2 new

Initialization code for variables

=cut 

# Class constructor
sub new {
  my $class = shift;
  my $self  = $class->SUPER::new();
  bless ($self, $class);
  $self->pattern('^(\d+\.\d+\.\d+\.\d+)\s\S+\s(\S+)\s\[[^]]+\]\s\"[^"]+\"\s(\S+)\s(\S+)\s\"[^"]+\"\s\"[^"]+\"\s\S+\s(\S+)\s\S+\s\"[^"]+\"\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s\S+\s\S+\s\S+\s\S+\s\S+\s\S+\s(\S+)\s\S+$');
  return $self;
}

=head2 evalBegin

This will be invoked before the first parsing of the log

=cut 


sub evalBegin {
  my $self = shift;
  for my $name ('nsCacheClientRequests', 'nsCacheClientSuccess',
		'nsCacheClientErrors', 'nsCacheClientNoStatus',
                'nsCacheClientInByte', 'nsCacheClientOutByte',
		'nsCacheServerRequests', 'nsCacheServerSuccess',
                'nsCacheServerErrors', 'nsCacheServerNoStatus',
		'nsCacheServerInByte', 'nsCacheServerOutByte',
		'nsCacheClientResponseTimeEntries',
		'nsCacheClientAvgResponseTime',
		'nsCacheClientStdDeviationResponseTime',
		'nsCacheClientMinResponseTime',
		'nsCacheClientMaxResponseTime',
		'nsCacheClientDNSResponseTimeEntries',
		'nsCacheClientAvgDNSResponseTime',
		'nsCacheClientStdDeviationDNSResponseTime',
		'nsCacheClientMinDNSResponseTime',
		'nsCacheClientMaxDNSResponseTime' )
  {
    $self->{savespace}{$name} = 0 if (!defined($self->{savespace}{$name}));
  }
  $self->{savespace}{'responseTime'} = Statistics::Descriptive::Sparse->new();
  $self->{savespace}{'dnsResponseTime'} = Statistics::Descriptive::Sparse->new();
}

=head2 evalIterate

This will be invoked whenever the pattern matches
the log line parsed
Input:
 - The line to be parsed
Output:
 - 1 if the line has matched the regular expression and 0 otherwise

=cut

sub evalIterate {
  my $self = shift;
  my ($line) = @_;
  my $pattern = $self->{pattern};
  if ($line =~ /$pattern/) {
    my ($ip, $user, $url, $serverStatus, $remServerStatus) = ($1, $2, $5, $3, $6);
    my ($CLp2c, $CLr2p, $CLc2p, $CLp2r, $HLc2p, $HLp2c, $HLp2r, $HLr2p) =
      ($4, $7, $8, $9, $10, $11, $12, $13);
    my ($totalTime, $dnsTime) = ($14, $15) ;
    if ($url =~ /^([^:]+:\/\/[^\/]+)\//) {
      $url = $1;
    }
    if (!exists($nsCacheIPClient{$ip})) {
      $nsCacheIPClient{$ip}{'Addr'} = $ip ;
      $nsCacheIPClient{$ip}{'Requests'} = 0 ;
      $nsCacheIPClient{$ip}{'Success'} = 0 ;
      $nsCacheIPClient{$ip}{'Error'} = 0 ;
      $nsCacheIPClient{$ip}{'NoStatus'} = 0 ;
      $nsCacheIPClient{$ip}{'InByte'} = 0 ;
      $nsCacheIPClient{$ip}{'OutByte'} = 0 ;
      $nsCacheIPClient{$ip}{'ServerInByte'} = 0 ;
      $nsCacheIPClient{$ip}{'ServerOutByte'} = 0 ;
      $nsCacheIPClient{$ip}{'ResponseTime'} = Statistics::Descriptive::Sparse->new();
    }
    if (!exists($nsCacheUserClient{$user})) {
      $nsCacheUserClient{$user}{'Uid'} = $user ;
      $nsCacheUserClient{$user}{'Requests'} = 0 ;
      $nsCacheUserClient{$user}{'Success'} = 0 ;
      $nsCacheUserClient{$user}{'Error'} = 0 ;
      $nsCacheUserClient{$user}{'NoStatus'} = 0 ;
      $nsCacheUserClient{$user}{'InByte'} = 0 ;
      $nsCacheUserClient{$user}{'OutByte'} = 0 ;
      $nsCacheUserClient{$user}{'ServerInByte'} = 0 ;
      $nsCacheUserClient{$user}{'ServerOutByte'} = 0 ;
      $nsCacheUserClient{$user}{'ResponseTime'} = Statistics::Descriptive::Sparse->new();
    }
    if (!exists($nsCacheURL{$url})) {
      $nsCacheURL{$url}{'String'} = $url ;
      $nsCacheURL{$url}{'Requests'} = 0 ;
      $nsCacheURL{$url}{'Success'} = 0 ;
      $nsCacheURL{$url}{'Error'} = 0 ;
      $nsCacheURL{$url}{'NoStatus'} = 0 ;
      $nsCacheURL{$url}{'InByte'} = 0 ;
      $nsCacheURL{$url}{'OutByte'} = 0 ;
      $nsCacheURL{$url}{'ServerInByte'} = 0 ;
      $nsCacheURL{$url}{'ServerOutByte'} = 0 ;
      $nsCacheURL{$url}{'ResponseTime'} = Statistics::Descriptive::Sparse->new();
    }
    $nsCacheIPClient{$ip}{'Requests'} ++;
    $nsCacheUserClient{$user}{'Requests'} ++;
    $nsCacheURL{$url}{'Requests'} ++;
    $self->{savespace}{'nsCacheClientRequests'} ++;
    if ($serverStatus =~ /\d+/) {
      if ($serverStatus <= 399) {
	$self->{savespace}{'nsCacheClientSuccess'} ++;
	$nsCacheIPClient{$ip}{'Success'} ++;
	$nsCacheUserClient{$user}{'Success'} ++;
	$nsCacheURL{$url}{'Success'} ++;
      }
      else {
	$self->{savespace}{'nsCacheClientErrors'} ++;
	$nsCacheIPClient{$ip}{'Error'} ++;
	$nsCacheUserClient{$user}{'Error'} ++;
	$nsCacheURL{$url}{'Error'} ++;
      }
    }
    else {
      $self->{savespace}{'nsCacheClientNoStatus'} ++;
      $nsCacheIPClient{$ip}{'NoStatus'} ++;
      $nsCacheUserClient{$user}{'NoStatus'} ++;
      $nsCacheURL{$url}{'NoStatus'} ++;
    }
    if ($remServerStatus =~ /\d+/)
      { if ($remServerStatus <= 399 )
	  {  $self->{savespace}{'nsCacheServerSuccess'} ++; }
	else
	  { $self->{savespace}{'nsCacheServerErrors'} ++; }
      }
    else
      { $self->{savespace}{'nsCacheServerNoStatus'} ++; }
    $CLc2p = 0 if ($CLc2p eq '-');
    $HLc2p = 0 if ($HLc2p eq '-');
    $CLp2c = 0 if ($CLp2c eq '-');
    $HLp2c = 0 if ($HLp2c eq '-');
    $CLr2p = 0 if ($CLr2p eq '-');
    $HLr2p = 0 if ($HLr2p eq '-');
    $CLp2r = 0 if ($CLp2r eq '-');
    $HLp2r = 0 if ($HLp2r eq '-');
    $self->{savespace}{'nsCacheClientInByte'} += $CLc2p + $HLc2p;
    $nsCacheIPClient{$ip}{'InByte'} += $CLc2p + $HLc2p;
    $nsCacheUserClient{$user}{'InByte'} += $CLc2p + $HLc2p;
    $nsCacheURL{$url}{'InByte'} += $CLc2p + $HLc2p;
    $self->{savespace}{'nsCacheClientOutByte'} += $CLp2c + $HLp2c;
    $nsCacheIPClient{$ip}{'OutByte'} += $CLp2c + $HLp2c;
    $nsCacheUserClient{$user}{'OutByte'} += $CLp2c + $HLp2c;
    $nsCacheURL{$url}{'OutByte'} += $CLp2c + $HLp2c;
    $self->{savespace}{'nsCacheServerInByte'} += $CLr2p + $HLr2p;
    $nsCacheIPClient{$ip}{'ServerInByte'} += $CLr2p + $HLr2p;
    $nsCacheUserClient{$user}{'ServerInByte'} += $CLr2p + $HLr2p;
    $nsCacheURL{$url}{'ServerInByte'} += $CLr2p + $HLr2p;
    $self->{savespace}{'nsCacheServerOutByte'} += $CLp2r + $HLp2r;
    $nsCacheIPClient{$ip}{'ServerOutByte'} += $CLp2r + $HLp2r;
    $nsCacheUserClient{$user}{'ServerOutByte'} += $CLp2r + $HLp2r;
    $nsCacheURL{$url}{'ServerOutByte'} += $CLp2r + $HLp2r;
    if ($totalTime =~ /\d+/) {
      $self->{savespace}{'responseTime'}->add_data($totalTime * 1000);
      $nsCacheIPClient{$ip}{'ResponseTime'}->add_data($totalTime * 1000);
      $nsCacheUserClient{$user}{'ResponseTime'}->add_data($totalTime * 1000);
      $nsCacheURL{$url}{'ResponseTime'}->add_data($totalTime * 1000);
    }
    if ($dnsTime =~ /\d+/)
      { $self->{savespace}{'dnsResponseTime'}->add_data($dnsTime * 1000); }
  }
}

=head2 evalEnd

This will be invoked after the last log line has been parsed

=cut

sub evalEnd {
  my $self = shift;
  my $rt = $self->{savespace}{'responseTime'};
  my $dt = $self->{savespace}{'dnsResponseTime'};
  if ($rt->count() != 0)
    {
      $self->{savespace}{'nsCacheClientResponseTimeEntries'} = $rt->count();
      $self->{savespace}{'nsCacheClientAvgResponseTime'} = $rt->mean();
      $self->{savespace}{'nsCacheClientStdDeviationResponseTime'} = defined($rt->standard_deviation()) ? $rt->standard_deviation() : 0;
      $self->{savespace}{'nsCacheClientMinResponseTime'} = $rt->min();
      $self->{savespace}{'nsCacheClientMaxResponseTime'} = $rt->max();
    }
  if ($dt->count() != 0)
    {
      $self->{savespace}{'nsCacheClientDNSResponseTimeEntries'} = $dt->count();
      $self->{savespace}{'nsCacheClientAvgDNSResponseTime'} = $dt->mean();
      $self->{savespace}{'nsCacheClientStdDeviationDNSResponseTime'} = defined($dt->standard_deviation()) ? $dt->standard_deviation() : 0;
      $self->{savespace}{'nsCacheClientMinDNSResponseTime'} = $dt->min();
      $self->{savespace}{'nsCacheClientMaxDNSResponseTime'} = $dt->max();
    }
  my $maxArrayIndex = 50;
  $self->{logger}->debug("Starting sort of IPClient");
  use Tie::Array::Sorted;
  tie @nsCacheIPClient, "Tie::Array::Sorted", sub { ${$_[1]}{'Requests'} <=> ${$_[0]}{'Requests'} };
  foreach my $k (keys %nsCacheIPClient)
    {
      if ($#nsCacheIPClient < $maxArrayIndex  - 1)
	{
	  push @nsCacheIPClient, $nsCacheIPClient{$k};
	}
      else
	{
	  if (${$nsCacheIPClient[$#nsCacheIPClient]}{'Requests'} < $nsCacheIPClient{$k}{'Requests'})
	    {
	      delete $nsCacheIPClient[$#nsCacheIPClient];
	      push @nsCacheIPClient, $nsCacheIPClient{$k};
	    }
	}
    }
  $self->{logger}->debug("End of sort of IPClient");
  $self->{savespace}{'nsCacheIPClientTableEntries'} = $#nsCacheIPClient + 1;
  for (my $i = 0 ; $i <= $#nsCacheIPClient; $i ++) {
    my $i1 = $i + 1;
    $self->{savespace}{'nsCacheIPClientIndex.'.$i1} = $i1;
    foreach my $k (keys %{$nsCacheIPClient[$i]}) {
      if ($k ne 'ResponseTime') {
	$self->{savespace}{'nsCacheIPClient' . $k . '.'. $i1} = ${$nsCacheIPClient[$i]}{$k};
      } else {
	if (${$nsCacheIPClient[$i]}{$k}->count == 0) {
	  $self->{savespace}{'nsCacheIPClientResponseTimeEntries'. '.'. $i1} = 0;
	  $self->{savespace}{'nsCacheIPClientAvgResponseTime'. '.'. $i1} =  0;
	  $self->{savespace}{'nsCacheIPClientStdDeviationResponseTime'. '.'. $i1} =  0;
	  $self->{savespace}{'nsCacheIPClientMinResponseTime'. '.'. $i1} =  0;
	  $self->{savespace}{'nsCacheIPClientMaxResponseTime'. '.'. $i1} =  0;
	} else {
	  $self->{savespace}{'nsCacheIPClientResponseTimeEntries'. '.'. $i1} = ${$nsCacheIPClient[$i]}{'ResponseTime'}->count();
	  $self->{savespace}{'nsCacheIPClientAvgResponseTime'. '.'. $i1} = ${$nsCacheIPClient[$i]}{'ResponseTime'}->mean();
	  $self->{savespace}{'nsCacheIPClientStdDeviationResponseTime'. '.'. $i1} = defined(${$nsCacheIPClient[$i]}{'ResponseTime'}->standard_deviation()) ? ${$nsCacheIPClient[$i]}{'ResponseTime'}->standard_deviation() : 0;
	  $self->{savespace}{'nsCacheIPClientMinResponseTime'. '.'. $i1} = ${$nsCacheIPClient[$i]}{'ResponseTime'}->min();
	  $self->{savespace}{'nsCacheIPClientMaxResponseTime'. '.'. $i1} = ${$nsCacheIPClient[$i]}{'ResponseTime'}->max();
	}
      }
    }
  }
  $self->{logger}->debug("Starting sort of UserClient");
  use Tie::Array::Sorted;
  tie @nsCacheUserClient, "Tie::Array::Sorted", sub { ${$_[1]}{'Requests'} <=> ${$_[0]}{'Requests'} };
  foreach my $k (keys %nsCacheUserClient)
    {
      if ($#nsCacheUserClient < $maxArrayIndex - 1 )
	{
	  push @nsCacheUserClient, $nsCacheUserClient{$k};
	}
      else
	{
	  if (${$nsCacheUserClient[$#nsCacheUserClient]}{'Requests'} < $nsCacheUserClient{$k}{'Requests'})
	    {
	      delete $nsCacheUserClient[$#nsCacheUserClient];
	      push @nsCacheUserClient, $nsCacheUserClient{$k};
	    }
	}
    }
  $self->{logger}->debug("End of sort of UserClient");
  $self->{savespace}{'nsCacheUserClientTableEntries'} = $#nsCacheUserClient + 1;
  for (my $i = 0 ; $i <= $#nsCacheUserClient; $i ++) {
    my $i1 = $i + 1;
    $self->{savespace}{'nsCacheUserClientIndex.'.$i1} = $i1;
    foreach my $k (keys %{$nsCacheUserClient[$i]}) {
      if ($k ne 'ResponseTime') {
	$self->{savespace}{'nsCacheUserClient' . $k . '.'. $i1} = ${$nsCacheUserClient[$i]}{$k};
      } else {
	if (${$nsCacheUserClient[$i]}{$k}->count == 0) {
	  $self->{savespace}{'nsCacheUserClientResponseTimeEntries'. '.'. $i1} = 0;
	  $self->{savespace}{'nsCacheUserClientAvgResponseTime'. '.'. $i1} =  0;
	  $self->{savespace}{'nsCacheUserClientStdDeviationResponseTime'. '.'. $i1} =  0;
	  $self->{savespace}{'nsCacheUserClientMinResponseTime'. '.'. $i1} =  0;
	  $self->{savespace}{'nsCacheUserClientMaxResponseTime'. '.'. $i1} =  0;
	} else {
	  $self->{savespace}{'nsCacheUserClientResponseTimeEntries'. '.'. $i1} = ${$nsCacheUserClient[$i]}{'ResponseTime'}->count();
	  $self->{savespace}{'nsCacheUserClientAvgResponseTime'. '.'. $i1} = ${$nsCacheUserClient[$i]}{'ResponseTime'}->mean();
	  $self->{savespace}{'nsCacheUserClientStdDeviationResponseTime'. '.'. $i1} = defined(${$nsCacheUserClient[$i]}{'ResponseTime'}->standard_deviation()) ? ${$nsCacheUserClient[$i]}{'ResponseTime'}->standard_deviation() : 0;
	  $self->{savespace}{'nsCacheUserClientMinResponseTime'. '.'. $i1} = ${$nsCacheUserClient[$i]}{'ResponseTime'}->min();
	  $self->{savespace}{'nsCacheUserClientMaxResponseTime'. '.'. $i1} = ${$nsCacheUserClient[$i]}{'ResponseTime'}->max();
	}
      }
    }
  }
  $self->{logger}->debug("Starting sort of URL");
  use Tie::Array::Sorted;
  tie @nsCacheURL, "Tie::Array::Sorted", sub { ${$_[1]}{'Requests'} <=> ${$_[0]}{'Requests'} };
  foreach my $k (keys %nsCacheURL)
    {
      if ($#nsCacheURL < $maxArrayIndex - 1)
	{
	  push @nsCacheURL, $nsCacheURL{$k};
	}
      else
	{
	  if (${$nsCacheURL[$#nsCacheURL]}{'Requests'} < $nsCacheURL{$k}{'Requests'})
	    {
	      delete $nsCacheURL[$#nsCacheURL];
	      push @nsCacheURL, $nsCacheURL{$k};
	    }
	}
    }
  $self->{logger}->debug("End of sort of URL");
  $self->{savespace}{'nsCacheURLTableEntries'} = $#nsCacheURL + 1;
  for (my $i = 0 ; $i <= $#nsCacheURL; $i ++) {
    my $i1 = $i + 1;
    $self->{savespace}{'nsCacheURLIndex.'.$i1} = $i1;
    foreach my $k (keys %{$nsCacheURL[$i]}) {
      if ($k ne 'ResponseTime') {
	$self->{savespace}{'nsCacheURL' . $k . '.'. $i1} = ${$nsCacheURL[$i]}{$k};
      } else {
	if (${$nsCacheURL[$i]}{$k}->count == 0) {
	  $self->{savespace}{'nsCacheURLResponseTimeEntries'. '.'. $i1} = 0;
	  $self->{savespace}{'nsCacheURLAvgResponseTime'. '.'. $i1} =  0;
	  $self->{savespace}{'nsCacheURLStdDeviationResponseTime'. '.'. $i1} =  0;
	  $self->{savespace}{'nsCacheURLMinResponseTime'. '.'. $i1} =  0;
	  $self->{savespace}{'nsCacheURLMaxResponseTime'. '.'. $i1} =  0;
	} else {
	  $self->{savespace}{'nsCacheURLResponseTimeEntries'. '.'. $i1} = ${$nsCacheURL[$i]}{'ResponseTime'}->count();
	  $self->{savespace}{'nsCacheURLAvgResponseTime'. '.'. $i1} = ${$nsCacheURL[$i]}{'ResponseTime'}->mean();
	  $self->{savespace}{'nsCacheURLStdDeviationResponseTime'. '.'. $i1} = defined(${$nsCacheURL[$i]}{'ResponseTime'}->standard_deviation()) ? ${$nsCacheURL[$i]}{'ResponseTime'}->standard_deviation(): 0;
	  $self->{savespace}{'nsCacheURLMinResponseTime'. '.'. $i1} = ${$nsCacheURL[$i]}{'ResponseTime'}->min();
	  $self->{savespace}{'nsCacheURLMaxResponseTime'. '.'. $i1} = ${$nsCacheURL[$i]}{'ResponseTime'}->max();
	}
      }
    }
  }

  $self->properties($self->savespace);
  delete $self->{properties}{responseTime};
  delete $self->{properties}{dnsResponseTime};
}

1;

=head1 OPTIONS

N/A

=head1 BUGS

To be reported

=head1 TODO

=over 8

=item * document logger.

=back

=head1 SEE ALSO

L<SNMP::MibProxy>

=head1 AUTHOR

Nito at Qindel dot ES -- 7/9/2006

=head1 COPYRIGHT & LICENSE

Copyright 2007 by Qindel Formacion y Servicios SL, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
