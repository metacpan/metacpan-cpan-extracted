package Net::Whois::IP;

########################################
#$Id: IP.pm,v 1.21 2007-03-07 16:49:36 ben Exp $
########################################

=head1 NAME

Net::Whois::IP - Perl extension for looking up the whois information for
ip addresses

=head1 SYNOPSIS

    use Net::Whois::IP qw(whoisip_query);

    my $ip = "192.168.1.1";
    my ($response, $array_of_responses) =
	whoisip_query($ip,
		      $optional_registry,
		      $optional_multiple_flag,
		      $optional_raw_flag,
		      $option_array_of_search_options);

In scalar context (single response hash returned):

    my $response = whoisip_query($ip);

The response will be a reference to a hash containing all information
provided by the whois registrar.

In list context (response hash and response chain returned):

    my ($response, $array_of_responses) = whoisip_query($ip,
							undef,
							"true");

    N.B.: See NOTES, below.

The array_of_responses is a reference to an array containing references
to hashes for each level of query performed.  For example, many records
must be searched several times to obtain the most detailed information;
this array contains the responses from each level.

If $optional_multiple_flag is not undef, all duplicate values for a given
field will be returned.

For example, normally only the last instance of TechPhone will be
returned if a record contains more than one.  However, setting this flag
to a non-undef value will return all values as an array.

As a consequence, all returned field values in the response hash become
references to arrays and must be dereferenced before use.

If $optional_raw_flag is not undef, the response will be a reference to
an array containing the raw responses from the registrar instead of a
reference to a hash. In raw mode, no parsed response chain is returned.

If $option_array_of_search_options is not undef, the first two entries
will be used to replace TechPhone and OrgTechPhone in the search method.
This is fairly dangerous and can cause the module not to work at all if
set incorrectly.

Normal unwrap of $response ($optional_multiple_flag not set):

    my $response = whoisip_query($ip);
    foreach (sort keys(%{$response}) ) {
	print "$_ $response->{$_} \n";
    }

$optional_multiple_flag set to a value:

    my $response = whoisip_query($ip, undef, "true");
    foreach ( sort keys %$response ) {
	print "$_ is\n"; foreach ( @{ $response->{ $_ } } ) { print " $_\n"; }
    }

$optional_raw_flag set to a value:

my $response = whoisip_query( $ip, undef, undef, "true");
foreach (@{$response}) { print $_; }

$optional_array_of_search_options set but not $optional_multiple_flag or
$optional_raw_flag:

my $search_options = ["NetName","OrgName"];
my $response = whoisip_query($ip, undef, undef, undef, $search_options);
foreach (sort keys(%{$response}) ) { print "$_ $response->{$_} \n"; }

=head1 NOTES

For certain ARIN queries, additional synthesized parent/ancestor
records may be prepended to the returned WHOIS response array
($array_of_responses). These records are synthesized from ARIN
summary/hierarchy output and are normalized into standard WHOIS
response hash format where possible.

Synthesized parent/ancestor records are tagged with the key
"Synthetic", currently containing the value "ARIN-SUMMARY".

Because ARIN summary records are abbreviated, synthesized records
may contain fewer fields than full WHOIS responses.

=head1 DESCRIPTION

Perl module to allow whois lookup of ip addresses. This module should
recursively query the various whois providers until it gets more
detailed information including either TechPhone or OrgTechPhone by
default; however, this is overrideable.

=head1 AUTHOR

Ben Schmitz -- ben@foink.com

Thanks to Orbitz for allowing the community access to this work

Please email me any suggestions, complaints, etc.

=head1 SEE ALSO

perl(1). Net::Whois

=cut

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use IO::Socket;
use Regexp::IPv6 qw($IPv6_re);
use File::Spec;
require Exporter;
use Carp;
use feature 'state';

@ISA = qw(Exporter);
@EXPORT = qw(
	     whoisip_query
	     set_debug
	    );
$VERSION = '1.20';

my %whois_servers = (
	   'RIPE' => 'whois.ripe.net',
	  'APNIC' => 'whois.apnic.net',
	  'KRNIC' => 'whois.krnic.net',
	 'LACNIC' => 'whois.lacnic.net',
	   'ARIN' => 'whois.arin.net',
	'AFRINIC' => 'whois.afrinic.net',
	);

# For queries:
#   If ARIN add n param. If RIPE or Afrinic add -B param
my %query_prefix = (
    $whois_servers{ARIN}    => 'n ',
    $whois_servers{RIPE}    => '-B ',
    $whois_servers{AFRINIC} => '-B ',
);

# Are we debugging?
my $do_debugging = 0;

use constant ARIN_EXACT_MATCH_PREFIX => '! ';

my $whois_query_delay = 2;	# Be conservative to avoid getting refused
my $first_arin_query_delay = 1;


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
      $reg = 'ARIN';
    }
    _do_debug("looking up $ip - at $reg");
    my ($response, $array_of_responses) =
        _do_lookup($ip, $reg, $multiple_flag, $raw_flag, $search_options);

    _do_debug("whois_ip_query sees: \$array_of_responses: " . scalar(@$array_of_responses));

    # Preserve historical scalar-context behavior while restoring
    # documented list-context behavior.
    return wantarray? ($response, $array_of_responses) : $response;
}

# Enabled/disable debugging
sub set_debug {
    my ($state) = @_;

    $do_debugging = $state ? 1 : 0;
}


######################################
#Private Subs
######################################
sub _do_lookup {
    my($ip,$registrar,$multiple_flag,$raw_flag,$search_options) = @_;
    _do_debug("do lookup $ip at $registrar");
    # let's not beat up on them too much
    my $extraflag = '1';
    my $whois_response;
    my $whois_raw_response;
    my $whois_response_hash;
    my @whois_response_array;
    my @arin_summary_records;

    LOOP: while($extraflag ne '') {
	_do_debug("Entering loop $extraflag");

	# Guard against unknown WHOIS registrars
	croak("Unknown WHOIS registrar: $registrar")
	    unless exists $whois_servers{$registrar};

	my $lookup_host = $whois_servers{$registrar};
	($whois_response,$whois_response_hash) = _do_query($lookup_host,$ip,$multiple_flag);
	_inspect_whois_response_lines($whois_response);
	push(@whois_response_array,$whois_response_hash);
	push(@{$whois_raw_response}, @{$whois_response});
	my($new_ip,$new_registrar) =
	    _do_processing($whois_response,
	                   $registrar,
			   $ip,
			   $whois_response_hash,
			   $search_options,
			   \@arin_summary_records
			  );

	if(($new_ip ne $ip) || ($new_registrar ne $registrar) ) {
	    _do_debug("ip was $ip -- new ip is $new_ip");
	    _do_debug("registrar was $registrar -- new registrar is $new_registrar");
	    $ip = $new_ip;
	    $registrar = $new_registrar;
	    $extraflag++;
	    next LOOP;
	}else{
	    $extraflag='';
	    last LOOP;
	}
    }
    
    # Return raw response from registrar
    if( ($raw_flag) && ($raw_flag ne '') ) {
	return ($whois_raw_response);
    }

    if(%{$whois_response_hash}) {
	foreach my $key (sort keys %{$whois_response_hash}) {
	    my $value = $whois_response_hash->{$key};

	    if (!defined $value) {
		_do_debug("sub -- $key -- undef");
	    }
	    elsif (ref($value) eq 'ARRAY') {
		foreach my $item (@{$value}) {
		    next unless defined($item) && $item =~ /\S/;
		    _do_debug("sub -- $key -- " . (defined $item ? $item : 'undef'));
		}
	    }
	    elsif (!ref($value)) {
		_do_debug("sub -- $key -- $value");
	    }
	    else {
		_do_debug("sub -- $key -- " . ref($value));
	    }
	}

	# If we've multiple records, normalize the add'l records into WHOIS-hash shape,
	# putting the "oldest" ancestor (widest range) at $whois_response_array[0]
	#
	# N.B.: These records are often highly-abbreviated. Preserve what ARIN
	# provides, but do not synthesize fields such as Country from child records.
	if(@arin_summary_records) {
	    unshift(@whois_response_array,
		    map { _arin_summary_to_whois_response($_) } @arin_summary_records);
	}
	_inspect_whois_response_array(\@whois_response_array);

        return($whois_response_hash,\@whois_response_array);
    }else{
        return($whois_response,\@whois_response_array);
    }
}

# Convert ARIN summary data to "standard" WHOIS response format
sub _arin_summary_to_whois_response {
    my ($rec) = @_;

    my %out;

    my %map = (
        netname     => 'NetName',
        nethandle   => 'NetHandle',
        description => 'OrgName',
        orgname     => 'OrgName',
        custname    => 'CustName',
        customer    => 'Customer',
        country     => 'Country',
        source      => 'Source',
    );

    for my $src_key (keys %map) {
        next if !defined $rec->{$src_key};
        $out{$map{$src_key}} = [ $rec->{$src_key} ];
    }

    $out{Source} ||= [ 'ARIN' ];
    $out{Synthetic} = [ 'ARIN-SUMMARY' ];	# Tag it for what it is

    if (defined $rec->{start} && defined $rec->{end}) {
        $out{NetRange} = [ "$rec->{start} - $rec->{end}" ];
        $out{CIDR} = [
            _range_to_cidr_strings(
                _ipv4_to_int($rec->{start}),
                _ipv4_to_int($rec->{end})
            )
        ];
    }

    return \%out;
}

sub _do_query {
    my($registrar,$ip,$multiple_flag) = @_;
    my @response;
    my $i =0;

    # Prevent abusing the registrars --- they may disable an ip if too many queries per minute
    _throttle_whois_query($registrar);

    LOOP: while(1) {    
	$i++;
	my $sock = _get_connect($registrar);

	_do_debug("Querying $registrar with " . ($query_prefix{$registrar} // q{}) . "$ip");
	print $sock (($query_prefix{$registrar} // q{}) . "$ip\n");

	@response = <$sock>;

	close($sock);

	if($#response < 0) {
	    _do_debug("No valid response recieved from $registrar -- attempt $i ");
	    if($i <=3) {
		next LOOP;
	    }else{
		croak("No valid response for 4th time... dying....");
	    }
	}else{
	    last LOOP;
	}
    }

    my %hash_response;
    _do_debug("multiple flag = |" . ($multiple_flag // '') . "|");

    foreach my $line (@response) {
	if($line =~ /^(.+):\s+(.+)$/) {
	  if( ($multiple_flag) && ($multiple_flag ne '') ) {
	    # Multiple_flag is set, so get all responses for a given record item
	    push @{ $hash_response{$1} }, $2;
	  }else{
	    # Multiple_flag is not set, so only the last entry for any given record item
	    $hash_response{$1} = $2;
	   }
	}
    }

    return(\@response,\%hash_response);
}

sub _do_processing {
    my($response,$registrar,$ip,$hash_response,$search_options,$arin_summary_records) = @_;

    # Response to comment.
    # Bug report stating the search method will work better with different options.  Easy way to do it now.
    # this way a reference to an array can be passed in, the defaults will still
    # be TechPhone and OrgTechPhone
    my $pattern1 = 'TechPhone';
    my $pattern2 = 'OrgTechPhone';

    if(ref($search_options) eq 'ARRAY' && defined $search_options->[0] && $search_options->[0] ne '') {
	$pattern1 = $search_options->[0];
	$pattern2 = $search_options->[1];
    }

    _do_debug("pattern1 = $pattern1 || pattern2 == $pattern2");

    LOOP:foreach (@{$response}) {
  	if (/Contact information can be found in the (\S+)\s+database/) {
	    $registrar = $1;
	    _do_debug("Contact -- registrar = $registrar -- trying again");
	    last LOOP;
	}elsif((/OrgID:\s+(\S+)/i || /source:\s+(\S+)/i) && !defined($hash_response->{$pattern1})) {
	    my $val = $1;	
	    _do_debug("Org/source match: value was $val--if not known registrar, will skip");
            if(exists $whois_servers{$val}) {
		$registrar = $val;
		_do_debug(" Known registrar match --> $registrar --> trying again ");
		last LOOP;
	    }
	}elsif(/Parent:\s+(\S+)/) {
	    # Use $pattern1 instead of default TechPhone
	    if(($1 ne '') && (!defined($hash_response->{$pattern1})) && (!defined($hash_response->{$pattern2})) ) {
		# End Modif
		$ip = $1;
		_do_debug(" Parent match ip will be $ip --> trying again");
		last LOOP;
	    }
	# Test Loop via Jason Kirk -- Thanks
	}elsif($registrar eq 'ARIN' && (/.+\((.+)\).+$/) && ($_ !~ /.+\:.+/)) {
	    my $arin_handle = $1;

	    if(/^(.+?)\s+(\S+)\s+\((NET-[^)]+)\)\s+
	       (\d+\.\d+\.\d+\.\d+)\s+-\s+
	       (\d+\.\d+\.\d+\.\d+)\s*$/x)
	    {
		push @$arin_summary_records, {
		    description => $1,
		    netname     => $2,
		    nethandle   => $3,
		    start       => $4,
		    end         => $5,
		};
	    }

	    my $origIp = $ip;
	    $ip = ARIN_EXACT_MATCH_PREFIX . $arin_handle;

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
	    _do_debug("parens match $ip $registrar --> trying again");
	}else{
	    $ip = $ip;
	    $registrar = $registrar;
	}
    }
    _do_debug("_do_processing returns arin_summary_records: ARIN summary records captured: " . scalar(@$arin_summary_records));
    return($ip,$registrar);
}
    
  

sub _get_connect {
    my($whois_registrar) = @_;
    my $sock = IO::Socket::INET->new(
				     PeerAddr=>$whois_registrar,
				     PeerPort=>'43',
				     Timeout=>'60',
				    );
    unless($sock) {
	carp("Failed to Connect to $whois_registrar at port 43: $!");
	sleep(5);
	$sock = IO::Socket::INET->new(
				      PeerAddr=>$whois_registrar,
				      PeerPort=>'43',
				      Timeout=>'60',
				     );
	unless($sock) {
	    croak("Failed to Connect to $whois_registrar at port 43 for the second time - $@");
	}
    }
    return($sock);
}

sub _ipv4_to_int {
    my ($ip) = @_;

    croak "Undefined IP address\n" if !defined $ip;
    croak "Invalid IPv4 address: '$ip'\n"
        if $ip !~ /\A(\d+)\.(\d+)\.(\d+)\.(\d+)\z/;

    my @octets = ($1, $2, $3, $4);

    for my $octet (@octets) {
        die "Invalid IPv4 octet in '$ip'\n"
            if $octet < 0 || $octet > 255;
    }

    return (($octets[0] << 24) |
            ($octets[1] << 16) |
            ($octets[2] <<  8) |
             $octets[3]);
}

sub _range_to_cidr_strings {
    my ($start, $end) = @_;

    croak "Invalid range" if $start > $end;

    my @cidrs;

    while ($start <= $end) {

        # Special case: the entire IPv4 space
        if ($start == 0 && $end == 0xFFFFFFFF) {
            push @cidrs, '0.0.0.0/0';
            last;
        }

        # Largest power-of-two block aligned at $start.
        # Special case: start==0, because the low-set-bit trick yields 0 there.
        my $max_size = $start ? ($start & -$start) : 0x8000_0000;

        # Limit block size so it does not exceed remaining range
        my $remaining = $end - $start + 1;

        while ($max_size > $remaining) {
            $max_size >>= 1;
        }

        # Convert block size to prefix length
        my $prefix = 32 - _log2($max_size);

        push @cidrs, _int_to_ipv4($start) . "/$prefix";

        $start += $max_size;
    }

    return @cidrs;
}

sub _log2 {
    my ($n) = @_;

    croak "log2(): undefined for n <= 0\n"
        if !defined($n) || $n <= 0;

    return int(log($n) / log(2));
}

sub _int_to_ipv4 {
    my ($n) = @_;

    croak "Undefined integer IP\n" if !defined $n;
    croak "Invalid IPv4 integer: '$n'\n"
        if $n < 0 || $n > 0xFFFFFFFF;

    return join '.',
        (($n >> 24) & 0xFF),
        (($n >> 16) & 0xFF),
        (($n >>  8) & 0xFF),
        ( $n        & 0xFF);
}

sub _throttle_whois_query {
    my ($registrar) = @_;

    state %last_query_time;

    my $now  = time();
    my $last = $last_query_time{$registrar};

    my $wait = defined($last)
        ? $whois_query_delay - ($now - $last)
        : 0;

    if (!defined($last) && $registrar eq $whois_servers{ARIN}) {
        $wait = $first_arin_query_delay;
    }

    if ($wait > 0) {
        _do_debug("WHOIS throttle for $registrar: sleeping $wait second(s)");
        sleep $wait;
    }

    $last_query_time{$registrar} = time();
}

sub _do_debug {
    return unless $do_debugging;

    state $did_warn = 0;

    my (@stuff) = @_;
    my $date = scalar localtime;
    my $tmp_dir = File::Spec->tmpdir() || '/tmp';
    my $outdebug = File::Spec->catfile($tmp_dir, 'Net.WhoisIP.log');

    unless($did_warn) {
	print STDERR "Net::Whois::IP: Debugging to \"$outdebug\" enabled!\n";
	$did_warn = 1;
    }

    open(my $debug_fh, '>>', $outdebug)
        or warn "Unable to open $outdebug: $!";
    return if !$debug_fh;

    for my $item (@stuff) {
        print {$debug_fh} "$date|$item|\n";
    }

    close($debug_fh);
}

# More debugging
sub _inspect_whois_response_lines {
    my ($lines, $label) = @_;

    return unless $do_debugging;

    $label //= 'WHOIS response';

    my @interesting;
    my @unknown;

    LINE:
    for my $line (@$lines) {
        chomp $line;

        next LINE if $line =~ /^\s*$/;
        next LINE if $line =~ /^#/;
        next LINE if $line =~ /^%/;

        if($line =~ /^(NetRange|CIDR|NetName|NetHandle|Parent|OrgName|Country):\s*(.+)$/i) {
            push @interesting, $line;
            next LINE;
        }

        if($line =~ /^(.+?)\s+(\S+)\s+\((NET-[^)]+)\)\s+(\d+\.\d+\.\d+\.\d+)\s+-\s+(\d+\.\d+\.\d+\.\d+)\s*$/) {
            push @interesting, "ARIN-SUMMARY: $line";
            next LINE;
        }

        next LINE if $line =~ /^(Comment|Remarks|RegDate|Updated|Created|Last-Modified):/i;
        next LINE if $line =~ /^(OrgAbuse|OrgTech|OrgNOC|RTech|RNOC|RAbuse)/i;

        push @unknown, $line;
    }

    _do_debug(sprintf(
    "|%s: %d interesting, %d unknown raw WHOIS lines|",
    $label, scalar @interesting, scalar @unknown
                     ));

    _do_debug("|\n=== $label: INTERESTING raw WHOIS lines ===|");
    if(@interesting) {
	_do_debug("|$_|") for @interesting;
    } else {
	_do_debug("|none|");
    }

    _do_debug("|\n=== $label: UNKNOWN raw WHOIS lines ===|");
    if(@unknown) {
	_do_debug("|$_|") for @unknown;
    } else {
	_do_debug("|none|");
    }

    return;
}

sub _inspect_whois_response_array {
    my ($responses, $label) = @_;

    return unless $do_debugging;

    $label //= 'WHOIS response array';

    my $out = "$label:\n";

    for my $i (0 .. $#$responses) {
        my $response = $responses->[$i];

        $out .= "  Response [$i]:\n";

        if (ref($response) ne 'HASH') {
            $out .= "    <not a HASH ref: " . (defined $response ? $response : 'undef') . ">\n";
            next;
        }

        for my $key (sort keys %$response) {
            my $value = $response->{$key};

            if (ref($value) eq 'ARRAY') {
                $out .= "    $key:\n";
                for my $item (@$value) {
                    $out .= "      - " . (defined $item ? $item : '<undef>') . "\n";
                }
            } elsif (ref($value)) {
                $out .= "    $key: <" . ref($value) . " ref>\n";
            } else {
                $out .= "    $key: " . (defined $value ? $value : '<undef>') . "\n";
            }
        }
    }

    _do_debug($out);
}

1;
