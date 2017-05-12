# Updated: 11/30/05 by Jeff Mercer <riffer@vaxer.net>

package Net::ParseWhois::Domain::Registrar::OpenSRS;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::OpenSRS::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::OpenSRS::VERSION = 0.5;

sub rdebug { 1 }

sub regex_org_start	{ '^Registrant:'}
sub regex_no_match	{ '^Can\'t get information on non-local domain .*$' }
sub regex_created	{ '^Record created on (.*).$' }
sub regex_expires	{ '^Record expires on (.*).$' }
sub regex_updated	{ '^Record last updated on (.*).$' }
sub regex_domain	{ '^Domain name: (.*)$' }
sub regex_nameservers	{ '^Domain servers in listed order:$' }
sub my_contacts		{ [ qw(Administrative Technical) ] }
sub my_data 		{ [ qw(regex_org_start regex_no_match regex_created regex_expires regex_updated regex_domain regex_nameservers my_contacts) ] }

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

1;
