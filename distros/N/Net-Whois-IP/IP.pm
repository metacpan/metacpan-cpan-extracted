package Net::Whois::IP;


########################################
#$Id: IP.pm,v 1.21 2007-03-07 16:49:36 ben Exp $
########################################

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use IO::Socket;
use Regexp::IPv6 qw($IPv6_re);
use File::Spec;
require Exporter;
use Carp;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(
	     whoisip_query
	    );
$VERSION = '1.19';

my %whois_servers = (
	"RIPE"=>"whois.ripe.net",
	"APNIC"=>"whois.apnic.net",
	"KRNIC"=>"whois.krnic.net",
	"LACNIC"=>"whois.lacnic.net",
	"ARIN"=>"whois.arin.net",
	"AFRINIC"=>"whois.afrinic.net",
	);

######################################
# Public Subs
######################################

sub whoisip_query {
    my($ip,$reg,$multiple_flag,$raw_flag,$search_options) = @_;
	# It allows to set the first registry to query
    if(($ip !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)  &&  ($ip !~ /^$IPv6_re$/) ) {
				croak("$ip is not a valid ip address");
    }
    if(!defined($reg)) {
      $reg = "ARIN";
    }
#DO_DEBUG("looking up $ip - at $reg");
    my($response) = _do_lookup($ip,$reg,$multiple_flag,$raw_flag,$search_options);
    return($response);
}


######################################
#Private Subs
######################################
sub _do_lookup {
    my($ip,$registrar,$multiple_flag,$raw_flag,$search_options) = @_;
#DO_DEBUG("do lookup $ip at $registrar");
#let's not beat up on them too much
    my $extraflag = "1";
    my $whois_response;
    my $whois_raw_response;
    my $whois_response_hash;
    my @whois_response_array;
    LOOP: while($extraflag ne "") {
#DO_DEBUG("Entering loop $extraflag");
	my $lookup_host = $whois_servers{$registrar};
	($whois_response,$whois_response_hash) = _do_query($lookup_host,$ip,$multiple_flag);
	push(@whois_response_array,$whois_response_hash);
	push(@{$whois_raw_response}, @{$whois_response});
	my($new_ip,$new_registrar) = _do_processing($whois_response,$registrar,$ip,$whois_response_hash,$search_options);
	if(($new_ip ne $ip) || ($new_registrar ne $registrar) ) {
#DO_DEBUG("ip was $ip -- new ip is $new_ip");
#DO_DEBUG("registrar was $registrar -- new registrar is $new_registrar");
	    $ip = $new_ip;
	    $registrar = $new_registrar;
	    $extraflag++;
	    next LOOP;
	}else{
	    $extraflag="";
	    last LOOP;
	}
    }
    
		# Return raw response from registrar
		if( ($raw_flag) && ($raw_flag ne "") ) {
		    return ($whois_raw_response);
		}


    if(%{$whois_response_hash}) {
	foreach (sort keys(%{$whois_response_hash}) ) {
#DO_DEBUG("sub -- $_ -- $whois_response_hash->{$_}");
	}
        return($whois_response_hash,\@whois_response_array);
    }else{
        return($whois_response,\@whois_response_array);
    }
}

sub _do_query{
    my($registrar,$ip,$multiple_flag) = @_;
    my @response;
    my $i =0;
LOOP:while(1) {    
      $i++;
      my $sock = _get_connect($registrar);
      # Replaced by: if ARIN add n param, if RIPE or Afrinic add -B param
      if    ($registrar eq 'whois.arin.net') { 
          print $sock "n $ip\n";  
      } elsif ($registrar eq 'whois.ripe.net' or $registrar eq "whois.afrinic.net") { 
          print $sock "-B $ip\n"; 
      } else  { 
          print $sock "$ip\n";    
      }
      @response = <$sock>;
      close($sock);
      if($#response < 0) {
	#DO_DEBUG("No valid response recieved from $registrar -- attempt $i ");
	if($i <=3) {
	  next LOOP;
	}else{
	  croak("No valid response for 4th time... dying....");
	}
      }else{
	last LOOP;
      }
    }
#Prevent killing the whois.arin.net --- they will disable an ip if greater than 40 queries per minute
    sleep(1);
    my %hash_response;
    #DO_DEBUG("multiple flag = |$multiple_flag|");
    foreach my $line (@response) {
	if($line =~ /^(.+):\s+(.+)$/) {
	  if( ($multiple_flag) && ($multiple_flag ne "") ) {
#Multiple_flag is set, so get all responses for a given record item
	    #DO_DEBUG("Flag set ");
	    push @{ $hash_response{$1} }, $2;
	  }else{
#Multiple_flag is not set, so only the last entry for any given record item
	    #DO_DEBUG("Flag not set");
	    $hash_response{$1} = $2;
	   }
	}
    }
    return(\@response,\%hash_response);
}

sub _do_processing {
    my($response,$registrar,$ip,$hash_response,$search_options) = @_;

#Response to comment.
#Bug report stating the search method will work better with different options.  Easy way to do it now.
#this way a reference to an array can be passed in, the defaults will still
#be TechPhone and OrgTechPhone
    my $pattern1 = "TechPhone";
    my $pattern2 = "OrgTechPhone";
    if(($search_options) && ($search_options->[0] ne "") ) {
	$pattern1 = $search_options->[0];
	$pattern2 = $search_options->[1];
    }
    #DO_DEBUG("pattern1 = $pattern1 || pattern2 == $pattern2");
		
		

    LOOP:foreach (@{$response}) {
  	if (/Contact information can be found in the (\S+)\s+database/) {
	    $registrar = $1;
#DO_DEBUG("Contact -- registrar = $registrar -- trying again");
	    last LOOP;

	}elsif((/OrgID:\s+(\S+)/i) || (/source:\s+(\S+)/i) && (!defined($hash_response->{$pattern1})) ) {
	    my $val = $1;	
#DO_DEBUG("Orgname match: value was $val if not RIPE,APNIC,KRNIC,or LACNIC.. will skip");
	    if($val =~ /^(?:RIPE|APNIC|KRNIC|LACNIC|AFRINIC)$/) {
		$registrar = $val;
#DO_DEBUG(" RIPE - APNIC match --> $registrar --> trying again ");
		last LOOP;
	    }
	}elsif(/Parent:\s+(\S+)/) {
	    # Modif: if(($1 ne "") && (!defined($hash_response->{'TechPhone'})) && (!defined($hash_response->{$pattern2})) ) {
		# Use $pattern1 instead of default TechPhone
	    if(($1 ne "") && (!defined($hash_response->{$pattern1})) && (!defined($hash_response->{$pattern2})) ) {
		# End Modif
		$ip = $1;
#DO_DEBUG(" Parent match ip will be $ip --> trying again");
		last LOOP;
	    }
#Test Loop via Jason Kirk -- Thanks
	  }elsif($registrar eq 'ARIN' && (/.+\((.+)\).+$/) && ($_ !~ /.+\:.+/)) {
##Change 3-1-07
#	    my $origIp = $ip;$ip = '! '.$1;
#	    if ($ip !~ /\d{1,3}\-\d{1,3}\-\d{1,3}\-\d{1,3}/){
#	      $ip = $origIp;
#	    }
	    my $origIp = $ip;$ip = '! '.$1;
		# Modif: Keep the smallest block
	    if ($origIp =~ /! NET-(\d{1,3}\-\d{1,3}\-\d{1,3}\-\d{1,3})/) {
	      my $orIP = $1;
	      if ($ip =~ /! NET-(\d{1,3}\-\d{1,3}\-\d{1,3}\-\d{1,3})/) {
	        my $nwIP = $1;
	        if (pack('C4', split(/\-/,$orIP)) ge pack('C4', split(/\-/,$nwIP))) {
			$ip = $origIp;
	        }
	      }
	    }
	    if ($ip !~ /\d{1,3}\-\d{1,3}\-\d{1,3}\-\d{1,3}/){
	      $ip = $origIp;
	    }
#	}elsif((/.+\((.+)\).+$/) && ($_ !~ /.+\:.+/)) {
#	    $ip = $1;
#	    $registrar = "ARIN";
#DO_DEBUG("parens match $ip $registrar --> trying again");
	}else{
	    $ip = $ip;
	    $registrar = $registrar;
	}
    }
    return($ip,$registrar);
}
	    
  

sub _get_connect {
    my($whois_registrar) = @_;
    my $sock = IO::Socket::INET->new(
				     PeerAddr=>$whois_registrar,
				     PeerPort=>'43',
				     Timeout=>'60',
#				     Blocking=>'0',
				    );
    unless($sock) {
	carp("Failed to Connect to $whois_registrar at port print -$@");
	sleep(5);
	$sock = IO::Socket::INET->new(
				      PeerAddr=>$whois_registrar,
				      PeerPort=>'43',
				      Timeout=>'60',
#				      Blocking=>'0',
				     );
	unless($sock) {
	    croak("Failed to Connect to $whois_registrar at port 43 for the second time - $@");
	}
    }
    return($sock);
}

sub DO_DEBUG {
    my(@stuff) = @_;
    my $date = scalar localtime;
    my $tmp_dir = File::Spec->tmpdir();
    if(!defined($tmp_dir)) {
	$tmp_dir = "/tmp/";
    }
    my $outdebug = $tmp_dir . "/Net.WhoisIP.log";
    open(DEBUG,">>$outdebug") or warn "Unable to open $outdebug";
    foreach my $item ( @stuff) {
        print DEBUG "$date|$item|\n";
    }
    close(DEBUG);
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Net::Whois::IP - Perl extension for looking up the whois information for ip addresses

=head1 SYNOPSIS

  use Net::Whois::IP qw(whoisip_query);

  my $ip = "192.168.1.1";
#Response will be a reference to a hash containing all information
#provided by the whois registrar
#The array_of_responses is a reference to an array containing references
#to hashes containing each level of query done.  For example,
#many records have to be searched several times to
#get to the correct information, this array contains the responses
#from each level
  my ($response,$array_of_responses) = whoisip_query($ip,$optional_multiple_flag,$optional_raw_flag,$option_array_of_search_options);
#if $optional_multiple_flag is not null, all possible responses for a give record will be returned
#for example, normally only the last instance of Tech phone will be give if record
#contains more than one, however, setting this flag to a not null will return both is an array.
#The other consequence, is that all records returned become references to an array and must be 
#dereferenced to utilize
#if $optional_raw_flag is not null, response will be a reference to an array containing the raw
#response from the registrar instead of a reference to a hash.
#If $option_array_of_search_options is not null, the first two entries will be used to replace
#TechPhone and OrgTechPhone is the search method.  This is fairly dangerous, and can
#cause the module not to work at all if set incorrectly

#Normal unwrap of $response ($optional_multiple_flag not set)
 my $response = whoisip_query($ip);
 foreach (sort keys(%{$response}) ) {
           print "$_ $response->{$_} \n";
 }

#$optional_multiple_flag set to a value
my $response = whoisip_query( $ip,"true");
foreach ( sort keys %$response ){
          print "$_ is\n";
          foreach ( @{ $response->{ $_ } } ) {
                      print "  $_\n";
          }
}

#$optional_raw_flag set to a value
my $response = whoisip_query( $ip,"","true");
foreach (@{$response}) {
          print $_;
}

#$optonal_array_of_search_options set but not $optional_multiple_flag or $optional_raw_flag
my $search_options = ["NetName","OrgName"];
my $response = whois_query($ip,"","",$search_options);
foreach (sort keys(%{$response}) ) {
           print "$_ $response->{$_} \n";
}



=head1 DESCRIPTION

Perl module to allow whois lookup of ip addresses.  This module should recursively query the various
whois providers until it gets the more detailed information including either TechPhone or OrgTechPhone
by default; however, this is overrideable.

=head1 AUTHOR

Ben Schmitz -- ben@foink.com

Thanks to Orbitz for allowing the community access to this work

Please email me any suggestions, complaints, etc.

=head1 SEE ALSO

perl(1).
Net::Whois

=cut
