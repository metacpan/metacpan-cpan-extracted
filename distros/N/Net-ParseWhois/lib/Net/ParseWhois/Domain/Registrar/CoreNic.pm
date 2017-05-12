# Updated: 11/30/05 by Jeff Mercer <riffer@vaxer.net>
# Note: Only tested against corenic.net domain name, so the address 
#       parsing has not been fully tested. May need tweaking.	--jcm, 11/30/05

package Net::ParseWhois::Domain::Registrar::CoreNic;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::CoreNic::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::CoreNic::VERSION = 0.2;

sub rdebug		{ 0 }
sub regex_no_match	{ 'The requested domain (.*) is available$' }
sub regex_domain	{ '^Domain Name:\s*(.*)$' }
sub regex_org_start	{ '^Domain ID:\s*(.*)$' }
sub regex_org		{ '^Registrant Name:\s*(.*)$' }
sub regex_tag		{ '^Domain ID:\s*(.*)$' }
sub regex_address	{ '^Registrant Address:\s*(.*)$' }
sub regex_city		{ '^Registrant City:\s*(.*)$' }
sub regex_state		{ '^Registrant State/Province:\s*(.*)$' }
sub regex_zip		{ '^Registrant Postal Code:\s*(.*)$' }
sub regex_country	{ '^Registrant Country:\s*(.*)$' }
sub regex_admin_start	{ '^Admin ID:\s*(.*)$' }
sub regex_admin		{ '^Admin .*:\s*(.*)$' }
sub regex_tech_start	{ '^Tech ID:\s*(.*)$' }
sub regex_tech		{ '^Tech .*:\s*(.*)$' }
sub regex_zone_start	{ '^Zone ID:\s*(.*)$' }
sub regex_zone		{ '^Zone .*:\s*(.*)$' }
sub regex_created	{ '^Creation Date:\s*(.*)$' }
sub regex_updated	{ '^Last Modification Date:\s*(.*)$' }
sub regex_expires	{ '^Expiration Date:\s*(.*)$' }
sub regex_nserver	{ '^Name Server:\s*(\S*)$' }
sub regex_registrar	{ '^registrar:\s*(.*)$' }
sub my_nameservers_noips { 1 }
sub my_contacts		{ [ qw(Administrative Technical Zone) ] }
sub my_data 		{ [ qw(my_contacts my_nameservers_noips regex_no_match regex_domain regex_org_start regex_org regex_tag regex_address regex_city regex_state regex_zip regex_country regex_admin_start regex_tech_start regex_zone_start regex_admin regex_tech regex_zone regex_created regex_updated regex_expires regex_nserver regex_registrar) ] }

sub parse_text {
	my $self = shift;
	my $text = shift; # array ref, one line per element

	$self->dump_text($text) if $self->rdebug;

	$self->parse_start($text);

	return $self;
}

# This should probably all be in parse_text but it seemed nicer to
# break it out
sub parse_start {
	my $self = shift;
	my $text = shift;
	my $t = shift @{$text};
	warn "DEBUG: parse_start() running...\n" if $self->rdebug;

	# Keep going through raw text until we find our starting point
	warn "DEBUG: Skipping boilerplate\n" if $self->rdebug;
	until (!defined $t || $t =~ /$self->{'regex_org_start'}/ || 
	$t =~ /$self->{'regex_no_match'}/) {
		warn "DEBUG: skip t = $t\n" if $self->rdebug;
		$t = shift @{$text};
	}

	warn "DEBUG: skip t = $t\n" if $self->rdebug;
	warn "DEBUG: Done skipping\n" if $self->rdebug;
	$self->dump_text if $self->rdebug;

	# the first line should contian regex_no_match or else good data
	if ($t =~ /$self->{'regex_org_start'}/) {
		warn "DEBUG: Domain matched\n" if $self->rdebug;
		$self->{'MATCH'} = 1;
		$self->{'TAG'} = $1;
	} else {	
		$self->{'MATCH'} = 0;
		warn "DEBUG: Matched against regex_no_match\n" if $self->rdebug;
		return 0;
	}

	warn "DEBUG: Starting parsing loop...\n" if $self->rdebug;
	for (@{$text}) {
		warn "DEBUG: _ = $_\n" if $self->rdebug;

		/$self->{'regex_domain'}/	&& do { $self->{'DOMAIN'} = $1; next; };
		/$self->{'regex_org'}/		&& do { $self->{'NAME'} = $1; next; };
		/$self->{'regex_address'}/	&& do {
			push @{$self->{'ADDRESS'}}, $1; next; };
		/$self->{'regex_city'}/		&& do {
			push @{$self->{'ADDRESS'}}, $1; next; };
		/$self->{'regex_state'}/	&& do {
			${$self->{'ADDRESS'}}[$#{$self->{'ADDRESS'}}] .= ", $1"; next; };
		/$self->{'regex_zip'}/		&& do {
			${$self->{'ADDRESS'}}[$#{$self->{'ADDRESS'}}] .= " $1"; next; };
		/$self->{'regex_country'}/	&& do { $self->{'COUNTRY'} = $1; next; };
		/$self->{'regex_admin_start'}/	&& do {
			${$self->{'CONTACTS'}}{uc ${$self->{'my_contacts'}}[0]}
				= [ $self->parse_contacts($self->{'regex_admin'}, $text) ];
			next; };
		/$self->{'regex_tech_start'}/		&& do {
			${$self->{'CONTACTS'}}{uc ${$self->{'my_contacts'}}[1]}
				= [ $self->parse_contacts($self->{'regex_tech'}, $text) ];
			next; };
		/$self->{'regex_zone_start'}/		&& do {
			${$self->{'CONTACTS'}}{uc ${$self->{'my_contacts'}}[2]}
				= [ $self->parse_contacts($self->{'regex_zone'}, $text) ];
			next; };
		/$self->{'regex_created'}/	&& do {
			$self->{'RECORD_CREATED'} = $1; next; };
		/$self->{'regex_updated'}/	&& do {
			$self->{'RECORD_UPDATED'} = $1; next; };
		/$self->{'regex_expires'}/	&& do {
			$self->{'RECORD_EXPIRES'} = $1; next; };
		/$self->{'regex_nserver'}/	&& do {
			push @{$self->{'SERVERS'}}, [$1, $self->na]; next; };
	}

	warn "DEBUG: parse_start() ending...\n" if $self->rdebug;
}


# this goes out and gets the contact info
# Only doesn't work that way anymore, so this is completely different now.
#						--jcm, 11/30/05
sub parse_contacts {
	my $self = shift;
	warn "DEBUG: parse_contacts() starting...\n" if $self->rdebug;
	my $contactid = shift;
	my $text = shift;
	my ($t, @cont, $i);

	warn "DEBUG: contactid = $contactid\n" if $self->rdebug;
	warn "DEBUG: text = $text\n" if $self->rdebug;

#	foreach (@{$text}) {
#		warn "DEBUG: _ = $_\n" if $self->rdebug;
#		if (/$contactid/) { push @cont, $1; }
#	}

	for ($i=0; $i <= $#{$text}; $i++) {
		if (${$text}[$i] =~ /$contactid/) {
			push @cont, (split(/: /, ${$text}[$i+1]))[1];
			push @cont, (split(/: /, ${$text}[$i+2]))[1];
			push @cont, (split(/: /, ${$text}[$i+3]))[1];
			push @cont, (split(/: /, ${$text}[$i+4]))[1].", ".(split(/: /, ${$text}[$i+5]))[1]."  ".(split(/: /, ${$text}[$i+6]))[1];
			push @cont, (split(/: /, ${$text}[$i+7]))[1];
			push @cont, "Phone: ".(split(/: /, ${$text}[$i+8]))[1]."  FAX: ".(split(/: /, ${$text}[$i+9]))[1];
			push @cont, (split(/: /, ${$text}[$i+10]))[1];

			last;
		}
	}

	return @cont;
}

1;
