package Net::ParseWhois::Domain;
require 5.004;

$Net::ParseWhois::Domain::VERSION = 0.5;
@Net::ParseWhois::Domain::ISA = qw(Net::ParseWhois);

use Net::ParseWhois::Domain::Registrar;
#use strict;
use Carp;

BEGIN {
  if (eval { require Locale::Country }) {
    Locale::Country->import(qw(code2country country2code));
  } else {
    *code2country = sub { ($_[1] =~ /^[^\W\d_]{2}$/i) && $_[1] };
    *country2code = sub { undef };
  }
}

sub new {
	# Initialization
	my $obj = shift;
	my $class = ref($obj) || 'Net::ParseWhois::Domain';

	croak "usage: new \$class DOMAIN" if (!@_);

	my $self = { 'domain' 		=> shift,
		     'base_server_name'	=> 'whois.internic.net',
		     'base_server_addr' => undef,
		     'whois_referral' 	=> undef,
		     'nameservers'	=> undef
		   };
	bless($self, $class);

	my $opt = shift;
	if ($opt->{'debug'}) {
		$self->debug( $opt->{'debug'} );
	}

	return $self->chase_referral;
}

# trys to chase_referral in specific registrar class or sets $self->ok = 0
sub chase_referral {
	my $self = shift;
	my @zone_parts = split(/\./, $self->{'domain'});
	my $tld = $zone_parts[$#zone_parts];
	my ($text, $t, $ref, $class, $rc);
        $rc = 0;

	#uppercase key
	$tld =~ tr /a-z/A-Z/;
	warn "tld = $tld\n" if $self->debug;

	$self->{'base_server_name'} = $self->TLDs->{$tld} if defined $self->TLDs->{$tld};

	warn "base_server_name = $self->{'base_server_name'}\n" if $self->debug;

	if (!$self->{'base_server_name'}) {
		die "unknown TLD - $tld\n";
	}

	# If this TLD uses a thick model, we don't need to chase referrals
	# for it, we have a single authoritative source to query. Sort of
	# a kludge to make sure correct Registrar module is called.
	#		--jcm, 11/10/05
	if ($self->TLDModel->{$tld} eq "thick") {
 		$self->{'whois_referral'} = $self->{'base_server_name'};
	}

	# = make NSI Registry return only one result. enter just 
	# register.com there without the equal to see what happens..

	# Unfortunately, that WON'T work with the PIR whois server. Kludge
	# to get around it for now, will need to add search format data
	# to the class so this will be self-contained and not need any
	# special checks.	--jcm, 11/10/05

	if ($self->{'base_server_name'} eq "whois.publicinterestregistry.net") {
		$text = $self->_send_to_sock($self->_connect, "$self->{'domain'}\x0d\x0a");
	} else {
		$text = $self->_send_to_sock($self->_connect, "=$self->{'domain'}\x0d\x0a");
	}

	# Read raw results of WHOIS query and do some initial parsing
	foreach $t (@{ $text} ) {
		warn "whois line = $t ..\n" if $self->debug;

		# Domain not found at this whois server
		if ($t =~ /^No match for \".*\"/i) {	# Tightened pattern matching --jcm
			$self->{'MATCH'} = 0;
			warn "Found 'No match for ' in results. MATCH = $self->{'MATCH'}\n" if $self->debug;
		# Match found! But we need to follow a referral
		} elsif ($t =~ /Whois Server: (\S+)/) {
			$self->{'MATCH'} = 1;
 			$self->{'whois_referral'} = $1;
			warn "whois_referral = $1\n" if $self->debug;
			warn "MATCH = $self->{'MATCH'}\n" if $self->debug;
		# Registered nameserver for this domain (assumes match found)
		} elsif ($t =~ /Name Server: (\S+)/) {
			push(@{ $self->{'nameservers'} }, $1);
			warn "nameserver: $1\n" if $self->debug;
		} 
	}

	
	# If a referral was found...
	if ($self->{'whois_referral'}) {
		warn "Chasing referral to $self->{'whois_referral'}\n" if $self->debug;

		# Create referral handle based on whois server name given by
		# previous query.
		$ref = Net::ParseWhois::Domain::Registrar::registrar_data()->{$self->{'whois_referral'}} || "";

		# If the referred whois server isn't recoginized...
		unless ($ref) {
			# This is an unknown registrar
			$ref = Net::ParseWhois::Domain::Registrar::registrar_data()->{'unknown_registrar'};
			$ref->{'UNKNOWN_REGISTRAR'} = 1;
			$ref->{'error'} = "Sorry, I don't know how to parse output from $self->{'whois_referral'}";
			warn "Sorry, I don't know how to parse output from $self->{'whois_referral'}\n" if $self->debug;
		}

		# Get the class name for this registrar
		$class = 'Net::ParseWhois::Domain::Registrar::' . $ref->{'class'};

		# Load that registrar's module
		$self->_load_module($class);
		warn "Loaded $class Registrar module\n" if $self->debug;

		# Now create a new instance of this particular registrar
		# module, using the referral data, domain name and of
		# course the whois server
		$rc = $class->new( { %{ $ref }, 
				domain => $self->{'domain'},
				whois_referral => $self->{'whois_referral'},
				debug => $self->{'debug'}
				} );

		warn "Created new $class object.\n" if $self->debug;
		warn "$class->follow_referral = $rc->follow-referral\n" if $self->debug;

		return $rc->follow_referral;
	} else {
		# TODO catch if no whois_referral line .. set $self->{error}, something
		# Net::Whois behavior is to just return undef
		$self->{'error'} = "No WHOIS referral server found. Maybe I'm confused...";

		return $self;
	}
}

sub ok {
	my $self = shift;
	$self->{MATCH};
}

1;
