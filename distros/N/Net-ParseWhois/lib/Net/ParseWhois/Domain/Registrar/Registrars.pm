package Net::ParseWhois::Domain::Registrar::Registrars;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::Registrars::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::Registrars::VERSION = 0.5;

sub rdebug { 0 }
sub regex_org_start { '^Registrant:'}
sub regex_no_match { '^No Information Available' }
sub regex_created { '^Registration Date:   (.*)$' }
sub regex_expires { '^Expiration Date: (.*)$' }
sub regex_domain { '^Domain Name: (.*)$' }
sub regex_nameservers { '^Domain servers in listed order:$' }
sub my_contacts { [ qw(Administrative Technical Billing) ] }
sub my_data { [ qw(regex_org_start regex_no_match regex_domain my_contacts regex_created regex_expires regex_nameservers ) ] }

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

# Registrars doesn't display Updated date
sub parse_domain_stats { 
	my ($self, $text) = @_;
	while (@{ $text}) {
		last if ($self->{RECORD_CREATED} && $self->{RECORD_EXPIRES});
		my $t = shift(@{ $text });
		next if $t=~ /^$/;
		if ($t =~ /$self->{'regex_created'}/) {
			$self->{RECORD_CREATED} = $1;
		} elsif ($t =~ /$self->{'regex_expires'}/) {
			$self->{RECORD_EXPIRES} = $1;
		}
	}
}

1;
