# Program: Net::ParseWhois::Domain::Registrar class for NameSecure
# Version: 1.0
# Purpose: Parsing methods and configuration for the NameSecure LLC Registrar
# Written: 11/28/05 by Jeff Mercer <riffer@vaxer.net>

package Net::ParseWhois::Domain::Registrar::NameSecure;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::NameSecure::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::NameSecure::VERSION = 1.0;

sub rdebug		{ 0 }
sub regex_org_start	{ '^Registrant:'}
sub regex_no_match	{ '^No match for \"' }
sub regex_created	{ '^Created on (.*)$' }
sub regex_expires	{ '^Expires on (.*)$' }
sub regex_domain	{ '^Domain: (.*)$' }
sub regex_nameservers	{ '^Name Servers:$' }
# Billing contacts no longer given via WHOIS
sub my_contacts		{ [ qw(Administrative Technical) ] }
sub my_data		{ [ qw(my_contacts regex_org_start regex_no_match regex_created regex_expires regex_domain regex_nameservers) ] }

sub parse_text {
	my $self = shift;
	my $text = shift; # array ref, one line per element

	# Because NameSecure doesn't give the last time a domain record was
	# updated, we need to pre-fill that data value so the parse_contacts
	# method won't screw-up.	--jcm, 11/28/05
	$self->{RECORD_UPDATED}="n/a";

	$self->dump_text($text) if $self->rdebug;

	$self->parse_start($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_org($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_domain_name($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_domain_stats($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_contacts($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_nameservers($text);
	$self->dump_text($text) if $self->rdebug;

	return $self;
}

1;
