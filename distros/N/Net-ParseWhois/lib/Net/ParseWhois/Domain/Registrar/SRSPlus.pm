# Program: Net::ParseWhois::Domain::Registrar class for SRSPlus
# Version: 1.0
# Purpose: Provides parsing methods and configurations for the SRSPlus
#          registrar (a division of Network Solutions)
# Written: 11/21/05 by Jeff Mercer <riffer@vaxer.net>

package Net::ParseWhois::Domain::Registrar::SRSPlus;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::SRSPlus::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::SRSPlus::VERSION = 1.0;

sub rdebug		{ 0 }
sub regex_org_start	{ '^Registrant:'}
sub regex_no_match	{ '^No match for' }
sub regex_created	{ '^Record created on (.*)\.$' }
sub regex_expires	{ '^Record expires on (.*)\.$' }
# NetSol/SRSPLus no longer gives last updated date for individual domains
sub regex_updated	{ '^Record last updated on (.*)\.$' }
sub regex_domain	{ '^Domain Name: (.*)$' }
sub regex_nameservers	{ '^Domain servers:$' }
sub my_nameservers_noips	{ 1 }
sub my_contacts		{ [ qw(Admin Technical Billing) ] }
sub my_data		{ [ qw(my_nameservers_noips my_contacts regex_org_start regex_no_match regex_created regex_updated regex_expires regex_domain regex_nameservers) ] }

sub parse_text {
	my $self = shift;
	my $text = shift; # array ref, one line per element

	# Because NetSol doesn't give the last time a domain record was
	# updated, we need to pre-fill that data value so the parse_contacts
	# method won't screw-up.	--jcm, 11/16/05
	$self->{RECORD_UPDATED}="n/a";

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

1;
