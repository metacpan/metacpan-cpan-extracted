# Net::ParseWhois registrar parser driver
#
# Registrar: Easyspace Ltd
# Version: 0.2
# Contributor: Adam Stubbs <astubbs@advantagecommunication.com>
# Date: 04/14/2001
# Updated: 11/16/2005 by Jeff Mercer <riffer@vaxer.net>

package Net::ParseWhois::Domain::Registrar::Easyspace;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::Easyspace::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::Easyspace::VERSION = 0.2;

sub rdebug		{ 0 }
sub regex_org_start	{ '^Registrant:'}
sub regex_no_match	{ '^No match for' }
sub regex_created	{ '^Record created on (.*)\.$' }
sub regex_expires	{ '^Record expires on (.*)\.$' }
sub regex_updated	{ '^Record last updated on (.*)\.$' }
sub regex_domain	{ '^Domain name: (.*)$' }
sub regex_nameservers	{ '^Domain servers in listed order:$' }
sub my_contacts		{ [ qw(Administrative Technical) ] }
sub my_data		{ [ qw(my_contacts regex_org_start regex_no_match regex_created regex_expires regex_updated regex_domain regex_nameservers) ] }

sub parse_text {
        my $self = shift;
        my $text = shift; # array ref, one line per element
	
	my $atext = join("\n",@{ $text });
	$atext =~ s/\nRegistrar:\s*\n\s*".*?".*?hostmaster\@easyspace\.com.*?\n.*?\s*Phone:\s*.*?\n\s*Fax:\s*.*?\n/\n/gsi;
	my @newtext = split(/\n/, $atext);
	$text = \@newtext;

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
