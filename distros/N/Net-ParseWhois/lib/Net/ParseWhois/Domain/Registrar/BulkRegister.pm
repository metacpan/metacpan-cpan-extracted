# Net::ParseWhois registrar parser driver
# Registrar: BulkRegister
# Version: 0.6
# Updated: 11/28/2005 by Jeff Mercer <riffer@vaxer.net>
# Note: whois.bulkregister.com will return results in no less than at least
#       FOUR variations. The layout is the same, but each format uses 
#       slightly different wording for domain stats, alternative 
#       puncutuation and other trivial differences. Presumably, this is 
#       some sort of anti-scraping approach, unless it's just stupidity 
#       on their part.
#       Regardless, this necessitates using complex regex matches, even 
#       with which there is still the chance of sometimes missing data.

package Net::ParseWhois::Domain::Registrar::BulkRegister;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::BulkRegister::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::BulkRegister::VERSION = 0.6;

sub rdebug { 0 }
sub regex_org_start	{ '^$'}
sub regex_no_match	{ '^Not found\!' }
sub regex_created	{ '^Record (?:created on|created date on:|create date - |created on->) (.*)$' }
sub regex_expires	{ '^Record (?:expires on|will be expiring on date:|will expire on - |expiring date->) (.*)$' }
sub regex_updated	{ '^Record (?:updated on|updated date on:|update date - |updated on->) (.*)$' }
sub regex_domain	{ '^Domain Name: (.*)$' }
sub regex_nameservers	{ '^Domain servers in listed order:$' }
sub my_contacts		{ [ qw(Administrative Technical Billing) ] }
sub my_data		{ [ qw(my_contacts regex_org_start regex_no_match regex_created regex_expires regex_updated regex_domain regex_nameservers) ] }

sub parse_text {
	my $self = shift;
	my $text = shift; # array ref, one line per element

	$self->dump_text($text) if $self->rdebug;

	$self->parse_start($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_org($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_domain_name($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_contacts($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_domain_stats($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_nameservers($text);
	$self->dump_text($text) if $self->rdebug;

	return $self;
}

#sub parse_start {
#	my $self = shift;
#	my $text = shift; 
#
#    my $t = shift @{ $text };
#	if (!defined $t || $t =~ /$self->{'regex_no_match'}/) {
#		$self->{'MATCH'} = 0;
#	} else {
#		$self->{'MATCH'} = 1;
#		if ($t =~ /^(.*)$/) {
#			$self->{'NAME'} = $1;
#			if ($self->{'NAME'} =~ /^(.*)\s+\((\S+)\)$/) {
#				$self->{'NAME'} = $1;
#				$self->{'TAG'} = $2;
#			}
#		} else {
#			die "Registrant Name not found in returned information\n";
#		}
#	}
#}


# Replace parse_contacts method from parent Registrar class. Mainly just
# to deal with alternate regex for matching Contact header lines
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
		if ($t =~ /contact(?:::|:| - |)$/i) {
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

			# Uh... Not sure what the point of this is.  --jcm, 11/16/05
			if ($self->{'my_contacts_extra_line'}) {
				$blah = shift(@{ $text });
			}

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

1;
