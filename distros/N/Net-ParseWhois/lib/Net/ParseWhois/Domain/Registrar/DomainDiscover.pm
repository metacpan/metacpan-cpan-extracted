# Net::ParseWhois registrar parser driver
#
# Registrar: DomainDiscover
# Version: 0.6
# Updated: 11/18/2005 by Jeff Mercer <riffer@vaxer.net>

package Net::ParseWhois::Domain::Registrar::DomainDiscover;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::DomainDiscover::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::DomainDiscover::VERSION = 0.6;

sub rdebug		{ 0 }
sub regex_org_start	{ '^Registrant:'}
sub regex_no_match	{ '^No match for' }
sub regex_created	{ '^Domain created on (.*)$' }
sub regex_expires	{ '^Domain expires on (.*)$' }
sub regex_updated	{ '^Last updated on (.*)$' }
sub regex_domain	{ '^Domain Name: (.*)$' }
sub regex_nameservers	{ '^Domain servers in listed order:$' }
sub my_nameservers_noips { 1 }
sub my_contacts		{ [ qw(Administrative Technical Zone) ] }
sub my_data		{ [ qw(my_nameservers_noips my_contacts regex_org_start regex_no_match regex_created regex_expires regex_updated regex_domain regex_nameservers) ] }

sub parse_text {
	my $self = shift;
	my $text = shift; # array ref, one line per element

	$self->dump_text($text) if $self->rdebug;
	$self->parse_start($text);
	$self->parse_org($text);
	$self->parse_domain_name($text);
	$self->parse_contacts($text);
	$self->parse_domain_stats($text);
	$self->parse_nameservers($text);

	return $self;
}

1;
