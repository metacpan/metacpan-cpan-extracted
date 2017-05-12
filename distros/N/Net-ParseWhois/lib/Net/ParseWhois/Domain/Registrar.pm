# Program: Net::ParseWhois base registrar class
# Version: 0.2
# Purpose: Provides the base class definition for all the registrar 
#          sub-classes. Methods defined here are over-ridden by the child
#	   classes as needed for each particular registrar. By default,
#	   this base class attempts to parse output of a Network Solutions
#	   WHOIS server.
# Updated: 11/21/2005 by Jeff Mercer <riffer@vaxer.net>

package Net::ParseWhois::Domain::Registrar;
require 5.004;
use strict;

$Net::ParseWhois::Domain::Registrar::VERSION = 0.2;
@Net::ParseWhois::Domain::Registrar::ISA = qw(Net::ParseWhois::Domain);

# used by new to import vals into $self->{} in specific registrar classes
sub my_data {}

sub registrar_data {
	{
	'whois.dotster.com'	=> {
		'registrar_tag'	=> 'DOTSTER, INC.',
		'referral_tag' 	=> 'http://www.dotster.com/help/whois',
		'class'		=> 'Dotster' },
	'whois.register.com'	=> {
		'registrar_tag' => 'REGISTER.COM, INC.',
		'referral_tag'	=> 'www.register.com',
		'class'		=> 'Register' },
	'whois.networksolutions.com' => {
		'registrar_tag'	=> 'NETWORK SOLUTIONS, INC.',
		'referral_tag'	=> 'www.networksolutions.com',
		'class'		=> 'Netsol' },
	'whois.opensrs.net' => {
		'registrar_tag' => 'TUCOWS.COM, INC.',
		'referral_tag'	=> 'www.opensrs.net',
		'class'		=> 'OpenSRS' },
	'whois.domaindiscover.com' => {
		'registrar_tag' => 'TIERRANET, INC.',
		'referral_tag'	=> 'www.domaindiscover.com',
		'class'		=> 'DomainDiscover' },
	'whois.bulkregister.com' => {
		'registrar_tag' => 'BULKREGISTER.COM, INC.',
		'referral_tag'	=> 'www.bulkregister.com',
		'class'		=> 'BulkRegister' },
	'rs.domainbank.net'	=> {
		'registrar_tag'	=> 'DOMAIN BANK, INC.',
		'referral_tag'	=> 'www.domainbank.net',
		'class'		=> 'DomainBank' },
	'whois.registrars.com'	=> {
		'registrar_tag'	=> 'INTERNET DOMAIN REGISTRARS',
		'referral_tag'	=> 'www.registrars.com',
		'class'		=> 'Registrars' },
	'whois.corenic.net'     => {
		'registrar_tag' => 'CORE INTERNET COUNCIL OF REGISTRARS',
		'referral_tag'  => 'www.corenic.net',
		'class'         => 'CoreNic' },
	'whois.melbourneit.com' => {
		'registrar_tag' => 'MELBOURNE IT, LTD. D/B/A INTERNET NAMES WORLDWIDE',
		'referral_tag'  => 'www.InternetNamesWW.com',
		'class'         => 'INameWW' },
	'whois.easyspace.com'   => {
		'registrar_tag' => 'EASYSPACE LTD',
		'referral_tag'  => 'www.easyspace.com',
		'class'         => 'Easyspace' },
	'whois.publicinterestregistry.net' => {
		'registrar_tag' => 'PUBLIC INTEREST REGISTRY',
		'referral_tag'  => 'www.pir.org',
		'class'         => 'PIR' },
	'whois.srsplus.com' => {
		'registrar_tag' => 'TLDs, LLC',
		'referral_tag'  => 'www.srsplus.com',
		'class'         => 'SRSPlus' },
	'whois.godaddy.com' => {
		'registrar_tag' => 'GO DADDY SOFTWARE, INC.',
		'referral_tag'  => 'www.godaddy.com',
		'class'         => 'GoDaddy' },
	'whois.enom.com' => {
		'registrar_tag' => 'ENOM, INC.',
		'referral_tag'  => 'www.enom.com',
		'class'         => 'Enom' },
	'whois.namesecure.com' => {
		'registrar_tag' => 'NAMESECURE LLC',
		'referral_tag'  => 'www.namesecure.com',
		'class'         => 'NameSecure' },
	'whois.namejuice.com' => {
		'registrar_tag' => 'DOMAIN REGISTRY GROUP INC',
		'referral_tag'  => 'www.namejuice.com',
		'class'         => 'NameJuice' },
	'whois.namescout.com' => {
		'registrar_tag' => 'NAMESCOUT CORP',
		'referral_tag'  => 'www.namescout.com',
		'class'         => 'NameScout' },
	'unknown_registrar'	=> {
		'registrar_tag'	=> 'Unknown',
		'referral_tag'	=> 'n/a',
		'class'		=> 'Unknown' }
	}
	# see perldoc Net::ParseWhois section 'REGISTRARS'
}


# Try and parse out all the garbage before the actual domain registration
# info.  Mostly skipping useless legal boilerplate and the like.  --jcm
sub parse_start {
	# Initialization
	my $self = shift;
	my $text = shift; 
	my $t = shift @{ $text };
	warn "DEBUG: parse_start() running\n" if $self->debug;

	# Keep going through raw text until we find our starting point	
	until (!defined $t || $t =~ /$self->{'regex_org_start'}/ ||
		$t =~ /$self->{'regex_no_match'}/) { $t = shift @{$text}; }

	#trim leading whitespace
	$t =~ s/^\s//;

	# Skip to next line if this line is blank
	$t = shift @{ $text } if ($t eq '');

	# If we find a match for the start of registrant data...
	if ($t =~ /$self->{'regex_org_start'}/) {
		# Prep the next input line and mark as a Match
		$t = shift @{ $text };
		$self->{'MATCH'} = 1;
	# since we have a referral, this should never get caught. --aai
	} elsif ($t =~ /$self->{'regex_no_match'}/) {
		$self->{'MATCH'} = 0;
	}

	# Did we find a match?
	if ($self->{'MATCH'} ) { 
		# Attempt to parse out registrant name, and tag if any
		if ($t =~ /^(.*)$/) {
			$self->{'NAME'} = $1;
			if ($self->{'NAME'} =~ /^(.*)\s+\((\S+)\)$/) {
				$self->{'NAME'} = $1;
				$self->{'TAG'} = $2;
			}
		} else {
			die "Registrant Name not found in returned information\n";
		}
	}

	warn "DEBUG: parse_start() ending\n" if $self->debug;
}


# Attempt to parse the organizational entity that has registered the domain.
# (I.E. the domain owner or registrant)
sub parse_org { 
	# Initialization
	my $self = shift;
	my $text = shift;
	my (@t, $c, $t);
	@t = ();
	warn "DEBUG: parse_org() running\n" if $self->debug;

	# read in text until next empty line
	push @t, shift @{ $text } while	${ $text }[0];

	# If a position for country info (in the registrant block) is defined
	if ($self->{'my_country_position'}) {
		# Extract country info
	    	$t = $t[$#t - $self->{'my_country_position'}];
	} else {
		# Set $t to the last line in the array, which will be the
		# last line before a blank line.
    		$t = $t[$#t];
	}

	# Try and figure out appropriate country code, if available
	if (!defined $t) {
		# do nothing
	# USA! USA!
	} elsif ($t =~ /^(?:usa|u\.\s*s\.\s*a\.)$/i) {
		pop @t;
		$t = 'US';
	} elsif ($self->code2country($t)) {
		pop @t;
		$t = uc $t;
	} elsif ($c = $self->country2code($t)) {
		pop @t;
		$t = uc $c;
	} elsif ($t =~ /,\s*([^,]+?)(?:\s+\d{5}(?:-\d{4})?)?$/) {
		# TODO - regex is too rigid. lots of times this shouldn't be matched
		# because a tel/fax line exists after address3/city,state zip ..
		$t = $self->US_State->{uc $1} ? 'US' : undef;
	} else {
		undef $t;
	}

	# Return registrant address and country info
	$self->{ADDRESS} = [@t];
	$self->{COUNTRY} = $t;

	warn "DEBUG: parse_org() ending\n" if $self->debug;
}

# Try and parse out all the contacts data. This is rather loose in that it 
# doesn't do any sub-parsing but just returns fat blocks of data. A future
# improvement would be to break it down into name, e-mail, address, etc.
#							--jcm
sub parse_contacts {
	# Initialization
	my ($self, $text) = @_;
	my ($done, $t, $blah, $ck);
	my (@ctypes, @c);
	warn "DEBUG: parse_contacts() running\n" if $self->debug;

	# As long as we have text to eat...
	while (@{ $text }) {
		# Check to see if all the contacts have been filled in
		$done = 1;
		foreach $ck (@{ $self->{'my_contacts'} }) {
			warn "DEBUG: ck=$ck\n" if $self->debug;
			unless ($self->{CONTACTS}->{uc($ck)}) { $done = 0; }
		}
		last if $done;

		# Grab next line of test, skip it if blank
		$t = shift(@{ $text });
		warn "DEBUG: t = $t\n" if $self->debug;
		next if $t=~ /^$/;


		# If this line is a contact header...
		if ($t =~ /contact.*:$/i) {
			# Figure out what contact type(s) it's for
			warn "DEBUG: Matched against /contact.*:/ regex\n" if $self->debug;
			@ctypes = ($t =~ /\b(\S+) contact/ig);
			@c=();
			if ($self->debug) {
				printf "DEBUG: ctypes=%d\n", $#ctypes+1 if $self->debug;
				foreach (@ctypes) {
					warn "DEBUG: ctypes contains=$_\n";
				}
			}

			# Uh... Not sure what the point of this is.  --jcm, 11/16/05
			if ($self->{'my_contacts_extra_line'}) {
				$blah = shift(@{ $text });
			}

			# Eat all the text until the next contact line and
			# store it in hash
			while ( ${ $text }[0] ) {
				warn "DEBUG: text[0]=${$text}[0]\n" if $self->debug;
				last if ${ $text }[0] =~ /contact.*:$/i;
				push @c, shift @{ $text };
			}

			# Take our contacts hash and map it to our objects
			# CONTACTS hash. Only I think this is foobar...
			printf "DEBUG: c=%d\n", $#c+1 if $self->debug;
			foreach (@ctypes) { @{$self->{CONTACTS}{uc $_}}=@c; }
		}
	}

	warn "DEBUG: parse_contacts() ending\n" if $self->debug;
}

# Parse out the nameservers
sub parse_nameservers {
	# Initialization
	my ($self, $text) = @_;
	my ($t, $dns, $key);
	my (@s, @temp);
	warn "DEBUG: parse_nameservers() running\n" if $self->debug;
	warn "DEBUG: text = $text, size = $#{$text}\n" if $self->debug;

	# As long as there's text in the array...
	warn "DEBUG: Starting text processing loop...\n" if $self->debug;
	while (@{ $text }) {
		# Done if we've got the nameservers already
		if ($self->{SERVERS}) {
		  warn "DEBUG: Servers defined, we're done.\n" if $self->debug;
		  last;
		}

		# Grab next line of text
		$t = shift(@{ $text });
		warn "DEBUG: t = $t\n" if $self->debug;

		# Skip to next line if current line is blank
		next if $t =~ /^$/;

		# If we get a match for our nameserver regex pattern...
		if ($t =~ /$self->{'regex_nameservers'}/) {
			warn "DEBUG: Matched $self->{'regex_nameservers'} regex pattern\n" if $self->debug;

			# HMMM??
			shift @{ $text } unless ${ $text }[0];

			while ($t = shift @{ $text }) {
				if ($self->{'my_nameservers_noips'}) {
					@temp = [ $t, $self->na ];
					push @s, @temp;
					warn "DEBUG: Nameserver with no IP\n" if $self->debug;
				} else {
					push @s, [split /\s+/,  $t];
					warn "DEBUG: Nameserver with IP\n" if $self->debug;
				}
			}
			$self->{SERVERS} = \@s;

			if ($self->debug) {
				foreach $dns (@s) { warn "DEBUG: DNS server = $dns\n"; }
			}
		}
	}

	warn "DEBUG: parse_nameservers() ending\n" if $self->debug;
}

# Parse out dates on when domain created, expires, and updated. Except
# NetSol doesn't give out when a domain was last updated. Some registrars
# might but that check is removed for now until script is stablized
#				 --jcm
# Ok, adding updated check back in, need to make sure it won't break for
# those registrars that don't provide the info (i.e. don't assume
# regex_expired exists!)	--jcm, 11/16/05
#
sub parse_domain_stats { 
	# Initialization
	my ($self, $text) = @_;
	my $t;

	warn "DEBUG: parse_domain_stats() running\n" if $self->debug;

	# As long as there's text to read...
	while (@{ $text}) {
		# Done if all three stats are defined
		last if ($self->{RECORD_CREATED} && $self->{RECORD_UPDATED} && $self->{RECORD_EXPIRES});

		# Grab next line of text, skip to next if blank
		$t = shift(@{ $text });
		next if $t=~ /^$/;

		warn "DEBUG: t = $t\nDEBUG: RECORD_CREATED = $self->{RECORD_CREATED}\nDEBUG: RECORD_UPDATED = $self->{RECORD_UPDATED}\nDEBUG: RECORD_EXPIRES = $self->{RECORD_EXPIRES}\n" if $self->debug;

		# If we match against any of our regex patterns, store the
		# the result in the appropriate parameter.
		if ($t =~ /$self->{'regex_created'}/) {
			$self->{RECORD_CREATED} = $1;
		} elsif ($t =~ /$self->{'regex_updated'}/) {
			$self->{RECORD_UPDATED} = $1;
		} elsif ($t =~ /$self->{'regex_expires'}/) {
			$self->{RECORD_EXPIRES} = $1;
		}
	}

	warn "DEBUG: parse_domain_stats() ending\n" if $self->debug;
}

# Parse out the domain name (which we already have of course, so not sure
# why we bother with this...) --jcm
sub parse_domain_name { 
	# Initialization
	my $self = shift;
	my $text = shift;
	my $t;
	warn "DEBUG: parse_domain_name() running\n" if $self->debug;

	# As long as there's text to read...
	while (@{ $text}) {
		# Done if the domain name has been found
		last if ($self->{DOMAIN});

		# Grab next line of text, skip if it's blank
		$t = shift(@{ $text });
		next if $t=~ /^$/;

		# If we match our domain name regex pattern...
		if ($t =~ /$self->{'regex_domain'}/) {
			# Define our domain value accordingly.
			$self->{DOMAIN} = $1;
		}
	}

	warn "DEBUG: parse_domain_name() ending\n" if $self->debug;
}

# Create a new instance of this object class (Net::ParseWhois)
sub new {
	my $class = shift;
	my $ref = shift;
	my %hash = %{ $ref } if ($ref);
	my $obj = bless ( \%hash, $class );
	
	if (defined $obj->my_data) {
		foreach my $field (@{ $obj->my_data }) {
			$obj->{$field} = $obj->$field();
		}
	}

	return $obj;
}
		
# Return a value of "Not applicable".
sub na {
	return "n/a";
}

# Subroutine to follow a referral on an object
sub follow_referral {
	# Initialization
	my $self = shift;
	warn "DEBUG: follow_referral() running\n" if $self->debug;

	# Try and connect to whois server
	$self->{'base_server_name'} = $self->whois_server;
	my $sock = $self->_connect || die "unable to open connection\n";
	my $text = $self->_send_to_sock( $sock );

	# Grab the raw whois text and store it for parsing by other routines
	$self->{RAW_WHOIS_TEXT} = join("\n", @{ $text } ); 

	# If this was an unknown registrar...
	if ($self->unknown_registrar) {
		# don't parse, just return $self with raw data
		$self->{MATCH} = 1;
		warn "DEBUG: follow_referral() ending\n" if $self->debug;
		return $self;
	} else {
		# Return with the parsed text (we hope)
		warn "DEBUG: follow_referral() ending\n" if $self->debug;
		$self->parse_text($text);
	}
}

# Return the current whois server
sub whois_server {
	my $self = shift;
	warn "DEBUG: whois_server() running\n" if $self->debug;

	return $self->{'whois_referral'};

	warn "DEBUG: whois_server() ending\n" if $self->debug;
}

# Dump all of the registry data returned from the whois server
sub dump_text {
	# Initialization
	my $self = shift;
	my $text = shift;
	warn "DEBUG: dump_text() running\n" if $self->debug;

	if ($self->debug) {
		warn "DEBUG: raw registry data:\n";
		warn "DEBUG: ----------------------------------\n";
		foreach (@{ $text }) { warn "DEBUG: \"$_\"\n"; }
		warn "DEBUG: ----------------------------------\n";
		warn "DEBUG: end registry data.\n";
	}

	warn "DEBUG: dump_text() ending\n" if $self->debug;
}

# This subroutine *should* be overloaded by the particular Registrar class
# being used. If not, then this code here runs and program exits.
sub parse_text {
	# Initialization
	my $self = shift;
	my $text = shift;
	warn "DEBUG: parse_text() running\n" if $self->debug;

	warn "DEBUG: \$self->parse_text NOT defined. Dumping data, and then dieing.\n" if $self->debug;

	foreach my $line (@{ $text }) {
		print "$line\n";
	}

	#TODO get rid of die ..
	die "$self->parse_text not defined.\n";

	return $self;

	warn "DEBUG: parse_text() ending\n" if $self->debug;
}


# TODO
# all of the below is silly. Via these accessor methods we should also be
# setting the values, rather than using UPPERCASE hash keys in $self. 
# or these should be named get_domain, get_name, etc.
# right .. ? --aai 12/05/00

sub domain {
	my $self = shift;
	$self->{DOMAIN} || $self->na;
}

sub name {
	my $self = shift;
	$self->{NAME} || $self->na;
}

sub tag {
	my $self = shift;
	$self->{TAG} || $self->na;
}

sub address {
	my $self = shift;
	my $addr = $self->{ADDRESS} || [ $self->na ];
	wantarray ? @ $addr : join "\n", @$addr;
}

sub country {
	my $self = shift;
	$self->{COUNTRY} || $self->na;
}

sub contacts {
	my $self = shift;
	$self->{CONTACTS} || { $self->na };
}

sub registrar {
	my $self = shift;
	return $self->{'registrar_tag'} || $self->na;
}

sub servers {
	my $self = shift;
	if (!$self->{SERVERS}) { # TODO: yuck ..
		my (@tmp, @ret);
		push(@tmp, $self->na);
		push(@tmp, $self->na);
		my $ref = \@tmp;
		push(@ret, $ref);
		return \@ret;
	}

	return $self->{SERVERS};
}

sub record_created {
	my $self = shift;
	$self->{RECORD_CREATED} || $self->na;
}

sub record_updated {
  my $self = shift;
  $self->{RECORD_UPDATED} || $self->na;
}

sub record_expires {
  my $self = shift;
  $self->{RECORD_EXPIRES} || $self->na;
}

sub raw_whois_text { 
	my $self = shift;
	$self->{RAW_WHOIS_TEXT} || $self->na;
}

sub unknown_registrar {
	my $self = shift;
	$self->{UNKNOWN_REGISTRAR} || '0';
}

1;
