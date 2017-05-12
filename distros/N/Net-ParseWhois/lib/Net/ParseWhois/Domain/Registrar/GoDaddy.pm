# Program: Net::ParseWhois::Domain::Registrar class for GoDaddy registrar
# Version: 1.0
# Purpose: Parsing methods and configuration for the GoDaddy.com registrar
# Written: 11/21/05 by Jeff Mercer <riffer@vaxer.net>

package Net::ParseWhois::Domain::Registrar::GoDaddy;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::GoDaddy::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::GoDaddy::VERSION = 1.0;

sub rdebug		{ 0 }
sub regex_org_start	{ '^Registrant:'}
sub regex_no_match	{ '^No match for' }
sub regex_created	{ '^Created on: (.*)$' }
sub regex_expires	{ '^Expires on: (.*)$' }
sub regex_updated	{ '^Last Updated on: (.*)$' }
sub regex_domain	{ '^Domain Name: (.*)$' }
sub regex_nameservers	{ '^Domain servers in listed order:' }
sub my_nameservers_noips { 1 }
sub my_contacts		{ [ qw(Administrative Technical) ] }
sub my_data		{ [ qw(my_nameservers_noips my_contacts regex_org_start regex_no_match regex_created regex_updated regex_expires regex_domain regex_nameservers) ] }

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
	$self->parse_domain_stats($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_contacts($text);
	$self->dump_text($text) if $self->rdebug;
	$self->parse_nameservers($text);
	$self->dump_text($text) if $self->rdebug;

	return $self;
}

1;
