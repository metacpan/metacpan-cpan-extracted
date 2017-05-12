# Updated: 12/01/05 by Jeff Mercer <riffer@vaxer.net>

package Net::ParseWhois::Domain::Registrar::Register;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::Register::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::Register::VERSION = 0.6;

sub rdebug		{ 0 }
sub regex_org_start	{ '^(?:Organization|Registrant).*:$'}
sub regex_no_match	{ '^No match for .*\.$' }
sub regex_created	{ '^Created on..............: (.*)$' }
sub regex_expires	{ '^Expires on..............: (.*)$' }
sub regex_updated	{ '^Record last updated on..: (.*)$' }
sub regex_domain	{ '^Domain Name: (.*)$' }
sub regex_nameservers	{ '^(?:Domain servers in listed order|DNS Servers):' }
sub my_nameservers_noips { 1 }
sub my_contacts		{ [ qw(Administrative Technical) ] }
sub my_data		{ [ qw(regex_org_start my_nameservers_noips regex_no_match regex_created regex_expires regex_updated regex_domain regex_nameservers my_contacts) ] }

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

