# Program: Net::ParseWhois::Domain::Registrar class for NameScout
# Version: 1.0
# Purpose: Parsing methods and configuration for the NameScout Registrar
# Written: 11/28/05 by Jeff Mercer <riffer@vaxer.net>
# Updated: 11/29/05 by Jeff Mercer <riffer@vaxer.net>

package Net::ParseWhois::Domain::Registrar::NameScout;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::NameScout::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::NameScout::VERSION = 0.6;

sub rdebug		{ 0 }
sub regex_org_start	{ '^Registrant$'}
sub regex_no_match	{ '^We are unable to process your request at this time.' }
sub regex_created	{ '^Date Registered: (.*)$' }
sub regex_expires	{ '^Expiry Date: (.*)$' }
sub regex_updated	{ '^Date Modified: (.*)$' }
sub regex_domain	{ '^Domain (.*)$' }
sub regex_nameservers	{ '^DNS[0-9]+: (.*)$' }
sub my_nameservers_noips { 1 }
sub my_contacts		{ [ qw(Administrative Technical) ] }
sub my_data		{ [ qw(my_contacts my_nameservers_noips regex_org_start regex_no_match regex_created regex_updated regex_expires regex_domain regex_nameservers) ] }

sub parse_text {
	my $self = shift;
	my $text = shift; # array ref, one line per element

	$self->dump_text($text) if $self->rdebug;

	$self->parse_domain_name($text);
	$self->dump_text($text) if $self->rdebug;

	$self->parse_domain_stats($text);
	$self->dump_text($text) if $self->rdebug;

	$self->parse_nameservers($text);
	$self->dump_text($text) if $self->rdebug;

	$self->parse_start($text);
	$self->dump_text($text) if $self->rdebug;

	$self->parse_org($text);
	$self->dump_text($text) if $self->rdebug;

	$self->parse_contacts($text);
	$self->dump_text($text) if $self->rdebug;

	return $self;
}

###############################################################################

# Overload the default parse_start method from the Registar parent class,
# to handle the extra blank lines NameScout WHOIS throws in.
#					--jcm, 11/29/05
sub parse_start {
	# Initialization
	my $self = shift;
	my $text = shift; 
	my $t = shift @{ $text };
	warn "DEBUG: parse_start() running\n" if $self->rdebug;

	# Keep going through raw text until we find our starting point	
	until (!defined $t || $t =~ /$self->{'regex_org_start'}/ ||
		$t =~ /$self->{'regex_no_match'}/) { $t = shift @{$text}; }

	#trim leading whitespace
	$t =~ s/^\s//;

	# Skip to next line if this line is blank
	$t = shift @{$text} if ($t eq '');

	# If we find a match for the start of registrant data...
	if ($t =~ /$self->{'regex_org_start'}/) {
		# Prep the next input line and mark as a Match
		$t = shift @{ $text };
		$t = shift @{ $text };
		$self->{'MATCH'} = 1;
	}

	# Did we find a match?
	if ($self->{'MATCH'} ) { 
		# Attempt to parse out registrant name, and tag if any
		if ($t =~ /^(.*)$/) { $self->{'NAME'} = $1; }
	}

	warn "DEBUG: parse_start() ending\n" if $self->rdebug;
}


# Replace the default Registrar method for parsing contacts, to deal with
# extra blank lines given by NameScout WHOIS server	--jcm 11/28/05
sub parse_contacts {
	# Initialization
	my ($self, $text) = @_;
	my ($done, $t, $blah, $ck);
	my (@ctypes, @c);
	warn "DEBUG: parse_contacts() running\n" if $self->rdebug;

	# As long as we have text to eat...
	while (@{ $text }) {
		# Check to see if all the contacts have been filled in
		$done = 1;
		foreach $ck (@{ $self->{'my_contacts'} }) {
			warn "DEBUG: ck=$ck\n" if $self->rdebug;
			unless ($self->{CONTACTS}->{uc($ck)}) { $done = 0; }
		}
		last if $done;

		# Grab next line of test, skip it if blank
		$t = shift(@{ $text });
		warn "DEBUG: t = $t\n" if $self->rdebug;
		next if $t=~ /^$/;

		# If this line is a contact header...
		if ($t =~ /contact.*$/i) {
			# Figure out what contact type(s) it's for
			warn "DEBUG: Matched against /contact.*:/ regex\n" if $self->rdebug;
			@ctypes = ($t =~ /\b(\S+) contact/ig);
			@c=();
			if ($self->rdebug) {
				printf "DEBUG: ctypes=%d\n", $#ctypes+1 if $self->rdebug;
				foreach (@ctypes) {
					warn "DEBUG: ctypes contains=$_\n";
				}
			}
			shift(@{ $text });

			# Eat all the text until the next contact line and
			# store it in hash
			while ( ${ $text }[0] ) {
				warn "DEBUG: text[0]=${$text}[0]\n" if $self->rdebug;
				last if ${ $text }[0] =~ /contact.*:$/i;
				push @c, shift @{ $text };
			}

			# Take our contacts hash and map it to our objects
			# CONTACTS hash. Only I think this is foobar...
			printf "DEBUG: c=%d\n", $#c+1 if $self->rdebug;
			foreach (@ctypes) { @{$self->{CONTACTS}{uc $_}}=@c; }
		}
	}

	warn "DEBUG: parse_contacts() ending\n" if $self->rdebug;
}


# Overload default parse_nameservers method from parent Registrar class.
# Nameservers info in NameScout WHOIS output is near top instead of bottom
# and has no leading block indicator. Each nameserver has a unique prefix
# so this requires substantially different logic than the default method.
#						--jcm, 11/29/05
sub parse_nameservers {
	# Initialization
	my ($self, $text) = @_;
	my ($t, $dns, $key);
	my (@s, @temp);
	warn "DEBUG: parse_nameservers() running\n" if $self->rdebug;
	warn "DEBUG: text = $text, size = $#{$text}\n" if $self->rdebug;
	warn "DEBUG: Starting text processing loop...\n" if $self->rdebug;

	# Prime the pump
#	$t = shift(@{$text});

	# As long as there's a nameserver entry to process...
	while (($t = shift(@{$text})) =~ /$self->{'regex_nameservers'}/) {
		warn "DEBUG: t = $t\n" if $self->rdebug;

		if ($self->{'my_nameservers_noips'}) {
			@temp = [ $1, $self->na ];
			push @s, @temp;
			warn "DEBUG: Nameserver with no IP\n" if $self->rdebug;
		} else {
			push @s, [split /\s+/,  $1];
			warn "DEBUG: Nameserver with IP\n" if $self->rdebug;
		}

	}

	# Store our array of nameservers in our instance
	$self->{SERVERS} = \@s;

	if ($self->rdebug) {
		foreach $dns (@s) { warn "DEBUG: DNS server = $dns\n"; }
		warn "DEBUG: parse_nameservers() ending\n";
	}
}

1;
