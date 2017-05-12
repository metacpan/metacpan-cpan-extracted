package Net::ParseWhois::Domain::Registrar::Dotster;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::Dotster::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::Dotster::VERSION = 0.01;

sub rdebug { 0 }
sub regex_org_start { '^Registrant\:'}
sub regex_no_match { '^No match for' }
sub regex_created { '^Created on: (.*)$' }
sub regex_expires { '^Expires on: (.*)$' }
sub regex_updated { '^Last Updated on: (.*)$' }
sub regex_domain { '^Domain Name: (.*)$' }
sub regex_nameservers { '^Domain servers in listed order:$' }
sub my_nameservers_noips { 1 }
sub my_contacts { [ qw(Administrative Technical) ] }
sub my_data { [ qw(my_nameservers_noips regex_org_start regex_no_match regex_created regex_expires regex_updated regex_domain regex_nameservers my_contacts) ] }

sub parse_text {
	my $self = shift;
	my $text = shift; # array ref, one line per element

	$self->dump_text($text) if $self->rdebug;
	$self->parse_start($text);
	$self->parse_org($text);
	$self->parse_domain_name($text);
	$self->parse_domain_stats($text);
	$self->parse_contacts($text);
	$self->parse_nameservers($text);

	return $self;

}


1;
