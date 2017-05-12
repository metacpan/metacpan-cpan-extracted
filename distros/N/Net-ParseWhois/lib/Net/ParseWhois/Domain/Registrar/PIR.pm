# Program: Net::ParseWhois::Domain::Registrar class for .org domains
# Version: 1.0
# Purpose: Parsing methods and configuration for .org domains, as reported
#          by the Public Interest Registry WHOIS servers. Domains may 
#          actually be registered with other registrars, PIR just provides
#          the info and does not act as an actual Registrar.
# Written: 11/16/05 by Jeff Mercer <riffer@vaxer.net>

package Net::ParseWhois::Domain::Registrar::PIR;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::PIR::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::PIR::VERSION = 1.0;

sub rdebug		{ 0 }
sub regex_org_start	{ '^Registrant ID:' }
sub regex_tag		{ '^Domain ID:(.*)$' }
sub regex_sponsor	{ '^Sponsoring Registrar:(.*) \(' }
sub regex_reg_name	{ '^Registrant Name:(.*)$' }
sub regex_reg_add1	{ '^Registrant Street1:(.*)$' }
sub regex_reg_add2	{ '^Registrant Street2:(.*)$' }
sub regex_reg_add3	{ '^Registrant Street3:(.*)$' }
sub regex_reg_city	{ '^Registrant City:(.*)$' }
sub regex_reg_state	{ '^Registrant State/Province:(.*)$' }
sub regex_reg_zip	{ '^Registrant Postal Code:(.*)$' }
sub regex_reg_country	{ '^Registrant Country:(.*)$' }
sub regex_reg_phone	{ '^Registrant Phone:(.*)$' }
sub regex_reg_fax	{ '^Registrant FAX:(.*)$' }
sub regex_reg_email	{ '^Registrant Email:(.*)$' }
sub regex_adm_name	{ '^Admin Name:(.*)$' }
sub regex_adm_add1	{ '^Admin Street1:(.*)$' }
sub regex_adm_add2	{ '^Admin Street2:(.*)$' }
sub regex_adm_add3	{ '^Admin Street3:(.*)$' }
sub regex_adm_city	{ '^Admin City:(.*)$' }
sub regex_adm_state	{ '^Admin State/Province:(.*)$' }
sub regex_adm_zip	{ '^Admin Postal Code:(.*)$' }
sub regex_adm_country	{ '^Admin Country:(.*)$' }
sub regex_adm_phone	{ '^Admin Phone:(.*)$' }
sub regex_adm_fax	{ '^Admin FAX:(.*)$' }
sub regex_adm_email	{ '^Admin Email:(.*)$' }
sub regex_tec_name	{ '^Tech Name:(.*)$' }
sub regex_tec_add1	{ '^Tech Street1:(.*)$' }
sub regex_tec_add2	{ '^Tech Street2:(.*)$' }
sub regex_tec_add3	{ '^Tech Street3:(.*)$' }
sub regex_tec_city	{ '^Tech City:(.*)$' }
sub regex_tec_state	{ '^Tech State/Province:(.*)$' }
sub regex_tec_zip	{ '^Tech Postal Code:(.*)$' }
sub regex_tec_country	{ '^Tech Country:(.*)$' }
sub regex_tec_phone	{ '^Tech Phone:(.*)$' }
sub regex_tec_fax	{ '^Tech FAX:(.*)$' }
sub regex_tec_email	{ '^Tech Email:(.*)$' }
sub regex_domain	{ '^Domain Name:(.*)$' }
sub regex_no_match	{ '^NOT FOUND' }
sub regex_created	{ '^Created On:(.*)$' }
sub regex_updated	{ '^Last Updated On:(.*)$' }
sub regex_expires	{ '^Expiration Date:(.*)$' }
sub regex_nameservers	{ '^Name Server:(.*)$' }
sub my_nameservers_noips { 1 }
sub my_contacts		{ [ qw(Admin Tech) ] }
sub my_data		{ [ qw(my_contacts regex_org_start regex_no_match regex_tag regex_sponsor regex_created regex_updated regex_expires regex_reg_name regex_reg_add1 regex_reg_add2 regex_reg_add3 regex_reg_city regex_reg_state regex_reg_zip regex_reg_country regex_reg_phone regex_reg_fax regex_reg_email regex_adm_name regex_adm_add1 regex_adm_add2 regex_adm_add3 regex_adm_city regex_adm_state regex_adm_zip regex_adm_country regex_adm_phone regex_adm_fax regex_adm_email regex_tec_name regex_tec_add1 regex_tec_add2 regex_tec_add3 regex_tec_city regex_tec_state regex_tec_zip regex_tec_country regex_tec_phone regex_tec_fax regex_tec_email regex_domain regex_nameservers) ] }

sub parse_text {
	my $self = shift;
	my $text = shift; # array ref, one line per element

	$self->dump_text($text) if $self->rdebug;

	$self->parse_start($text);
	$self->dump_text($text) if $self->rdebug;

	return $self;
}

# Replace the default parse_start method with one that can handle this
# format.
sub parse_start {
	my $self = shift;
	my $text = shift;
	my (@adm, @tec);
	$self->{'MATCH'} = 1;

	# Zip through remaining text and see what we can find
	for (@{$text}) {
		# Check if domain was never matched
		warn "Checking for never matched...\n" if $self->rdebug;
		/$self->{'regex_no_match'}/	&& do { $self->{'MATCH'} = 0; return 0; };

		# Domain ID / tag
		warn "Checking for Domain ID...\n" if $self->rdebug;
		/$self->{'regex_tag'}/		&& do { $self->{'TAG'} = $1; next; };

		# Sponsoring registrar
		warn "Checking for registrar sponsor\n" if $self->rdebug;
		/$self->{'regex_sponsor'}/	&& do { $self->{'SPONSOR'} = $1 if $1; next; };

		# Domain name
		warn "Checking for domain name...\n" if $self->rdebug;
		/$self->{'regex_domain'}/	&& do { $self->{'DOMAIN'} = $1; next; };

		# Creation, updated and expiration date checks
		warn "Checking for dates...\n" if $self->rdebug;
		/$self->{'regex_created'}/	&& do { $self->{'RECORD_CREATED'} = $1; next; };
		/$self->{'regex_updated'}/	&& do { $self->{'RECORD_UPDATED'} = $1; next; };
		/$self->{'regex_expires'}/	&& do { $self->{'RECORD_EXPIRES'} = $1; next; };

		# Registrant/Organizational contact info
		warn "Checking for registrant contact...\n" if $self->rdebug;
		/$self->{'regex_reg_name'}/	&& do { $self->{'NAME'} = $1; next; };
		/$self->{'regex_reg_add1'}/	&& do { push @{$self->{'ADDRESS'}}, $1 if $1; next; };
		/$self->{'regex_reg_add2'}/	&& do { push @{$self->{'ADDRESS'}}, $1 if $1; next; };
		/$self->{'regex_reg_add3'}/	&& do { push @{$self->{'ADDRESS'}}, $1 if $1; next; };
		/$self->{'regex_reg_city'}/	&& do { push @{$self->{'ADDRESS'}}, $1 if $1; next; };
		/$self->{'regex_reg_state'}/	&& do { ${$self->{'ADDRESS'}}[$#{$self->{'ADDRESS'}}] .= ", $1" if $1; next; };
		/$self->{'regex_reg_zip'}/	&& do { ${$self->{'ADDRESS'}}[$#{$self->{'ADDRESS'}}] .= "  $1" if $1; next; };
		/$self->{'regex_reg_country'}/	&& do { $self->{'COUNTRY'} = $1 if $1; next; };
		/$self->{'regex_reg_phone'}/	&& do { push @{$self->{'ADDRESS'}}, $1 if $1; next; };
		/$self->{'regex_reg_fax'}/	&& do { push @{$self->{'ADDRESS'}}, $1 if $1; next; };
		/$self->{'regex_reg_email'}/	&& do { push @{$self->{'ADDRESS'}}, $1 if $1; next; };

		# Administrative contact info
		warn "Checking for admin contact...\n" if $self->rdebug;
		/$self->{'regex_adm_name'}/	&& do { push @adm, $1 if $1; next; };
		/$self->{'regex_adm_add1'}/	&& do { push @adm, $1 if $1; next; };
		/$self->{'regex_adm_add2'}/	&& do { push @adm, $1 if $1; next; };
		/$self->{'regex_adm_add3'}/	&& do { push @adm, $1 if $1; next; };
		/$self->{'regex_adm_city'}/	&& do { push @adm, $1 if $1; next; };
		/$self->{'regex_adm_state'}/	&& do { $adm[$#adm] .= ", $1" if $1; next; };
		/$self->{'regex_adm_zip'}/	&& do { $adm[$#adm] .= "  $1" if $1; next; };
		/$self->{'regex_adm_country'}/	&& do { push @adm, $1 if $1; next; };
		/$self->{'regex_adm_phone'}/	&& do { push @adm, $1 if $1; next; };
		/$self->{'regex_adm_fax'}/	&& do { push @adm, $1 if $1; next; };
		/$self->{'regex_adm_email'}/	&& do { push @adm, $1 if $1; next; };

		# Technical contact info
		warn "Checking for tech contact...\n" if $self->rdebug;
		/$self->{'regex_tec_name'}/	&& do { push @tec, $1 if $1; next; };
		/$self->{'regex_tec_add1'}/	&& do { push @tec, $1 if $1; next; };
		/$self->{'regex_tec_add2'}/	&& do { push @tec, $1 if $1; next; };
		/$self->{'regex_tec_add3'}/	&& do { push @tec, $1 if $1; next; };
		/$self->{'regex_tec_city'}/	&& do { push @tec, $1 if $1; next; };
		/$self->{'regex_tec_state'}/	&& do { $tec[$#tec] .= ", $1" if $1; next; };
		/$self->{'regex_tec_zip'}/	&& do { $tec[$#tec] .= "  $1" if $1; next; };
		/$self->{'regex_tec_country'}/	&& do { push @tec, $1 if $1; next; };
		/$self->{'regex_tec_phone'}/	&& do { push @tec, $1 if $1; next; };
		/$self->{'regex_tec_fax'}/	&& do { push @tec, $1 if $1; next; };
		/$self->{'regex_tec_email'}/	&& do { push @tec, $1 if $1; next; };

		# Check for nameserver entries
		/$self->{'regex_nameservers'}/	&& do { push @{$self->{'SERVERS'}}, [$1, "IP not given"] if $1; next; };
	}

	# If we built an Admin contact array, stick it in our results
	if (@adm) {
		warn "Adding adm array to results\n" if $self->rdebug;
		@{$self->{'CONTACTS'}}{ADMIN} = \@adm;
	}

	# If we built a Tech contact array, stick it in our results
	if (@tec) {
		warn "Adding tec array to results\n" if $self->rdebug;
		@{$self->{'CONTACTS'}}{TECH} = \@tec;
	}

}

sub registrar {
	my $self = shift;

	if ($self->{'registrar_tag'}) {
		return "$self->{'registrar_tag'} (Sponsor: $self->{'SPONSOR'})";
	}

	return $self->na;
}

1;
