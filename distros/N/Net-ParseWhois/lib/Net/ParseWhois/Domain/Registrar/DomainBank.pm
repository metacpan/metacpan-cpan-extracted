# Updated on 11/21/05 by Jeff Mercer <riffer@vaxer.net>
#
package Net::ParseWhois::Domain::Registrar::DomainBank;

require 5.004;
use strict;

# TODO:
# this one needs work on parse_contacts .. try domainbank.net and domainbank.com.
# bleh.

@Net::ParseWhois::Domain::Registrar::DomainBank::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::DomainBank::VERSION = 0.2;

sub rdebug		{ 0 }
sub regex_org_start	{ '^Registrant:'}
sub regex_no_match	{ '^No Match for \"' }
sub regex_created	{ '^Created on: (.*)$' }
sub regex_expires	{ '^Expires on: (.*)$' }
sub regex_updated	{ '^Last Updated on: (.*)$' } 
sub regex_domain	{ '^Domain Name: (.*)$' }
sub regex_nameservers	{ '^Domain servers in listed order:$' }
# Doesn't seem to offer Zone contacts anymore.  --jcm, 11/18/05
sub my_contacts		{ [ qw(Administrative Technical) ] }
# Nope, not needed anymore.  --jcm, 11/18/05
#sub my_contacts_extra_line { 1 }
sub my_nameservers_noips { 1 }
sub my_data		{ [ qw(my_contacts my_nameservers_noips regex_org_start regex_no_match regex_created regex_expires regex_updated regex_domain regex_nameservers) ] }

sub parse_text {
	my $self = shift;
	my $text = shift; # array ref, one line per element

	# Re-render output to make Contacts section format like NetSol type
	# (Only relevant for contacts that have multiple roles)
	#					--jcm, 11/21/05
	my $atext = join("\n",@{ $text });
	$atext =~ s/Administrative, Technical Contact:/Administrative Contact, Technical Contact:/g;
	$atext =~ s/Technical, Administrative Contact:/Administrative Contact, Technical Contact:/g;
	my @newtext = split(/\n/, $atext);
	$text = \@newtext;

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

# Shouldn't need this anymore.   --jcm, 11/18/05
#sub parse_domain_stats { 
#
## required because they don't have UPDATED info .. changing base class would
## be complicated, and I think ICANN requires the updated: string in whois output.
## --aai
#
#	my ($self, $text) = @_;
#	while (@{ $text}) {
#		last if ($self->{RECORD_CREATED} && $self->{RECORD_EXPIRES});
#		my $t = shift(@{ $text });
#		next if $t=~ /^$/;
#		if ($t =~ /$self->{'regex_created'}/) {
#			$self->{RECORD_CREATED} = $1;
#		} elsif ($t =~ /$self->{'regex_expires'}/) {
#			$self->{RECORD_EXPIRES} = $1;
#		}
#	}
#}


1;
