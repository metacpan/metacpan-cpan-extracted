# Net::ParseWhois registrar parser driver
#
# Registrar: Internet Names 
# Version: 0.12
# Contributor: Adam Stubbs <astubbs@advantagecommunication.com>
# Date: 04/14/2001
# Updated: 11/18/2005 by Jeff Mercer <jcm@vaxer.net>
# 

package Net::ParseWhois::Domain::Registrar::INameWW;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::INameWW::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::INameWW::VERSION = 0.1;

sub rdebug		{ 0 }
sub regex_org_start	{ '^Registrant:'}
sub regex_no_match	{ '^No match for' }
sub regex_created	{ '^Record created on (.*).$' }
sub regex_expires	{ '^Record expires on (.*).$' }
sub regex_updated	{ '^Record last updated on (.*).$' }
sub regex_domain	{ '^Domain Name: (.*)$' }
sub regex_nameservers	{ '^Domain servers in listed order:$' }
sub my_contacts		{ [ qw(Administrative Technical Billing) ] }
sub my_nameservers_noips { 1 }
sub my_data		{ [ qw(my_contacts regex_org_start regex_no_match regex_created regex_expires regex_updated regex_domain regex_nameservers my_nameservers_noips) ] }

sub parse_text {
        my $self = shift;
        my $text = shift; # array ref, one line per element
	my %data = ();

	foreach my $line (@{$text}){
		$line .= "\n";
		if($line =~ /^(.*?)\.+\s(.*?)\n/){
            #if ($1 eq 'Name Server') {
            #    push(@{$data{$1}}, $2 . 'n/a'); # kludge so that t/whois.pl's map won't complain.
            #} else {
			    push(@{$data{$1}}, $2);
            #}
		}
	}
	
	my $country = $data{'Organisation Address'}[-1];	

	foreach my $k (keys %data){
		if(ref($data{$k}) eq 'ARRAY'){
			$data{$k} = join("\n", @{$data{$k}});
		}
	}

	my $newtext = qq~Registrant:
$data{'Organisation Name'}
$data{'Organisation Address'}

Domain Name: $data{'Domain Name'}

Administrative Contact, Billing Contact:
$data{'Admin Name'}  $data{'Admin Email'}
$data{'Admin Address'}
Phone: $data{'Admin Phone'}
Fax: $data{'Admin Fax'}
Technical Contact:
$data{'Tech Name'} $data{'Tech Email'}
$data{'Tech Address'}
Phone: $data{'Tech Phone'}
Fax: $data{'Tech Fax'}

Record expires on $data{'Expiry Date'}.
Record created on $data{'Creation Date'}.

Domain servers in listed order:

$data{'Name Server'}

~;

	my @newtext = split(/\n/, $newtext);
	$text = \@newtext;

        $self->dump_text($text) if $self->rdebug;

	$self->{RECORD_UPDATED} = 'n/a';

        $self->parse_start($text);
        $self->parse_org($text);
        $self->parse_domain_name($text);
        $self->parse_contacts($text);
        $self->parse_domain_stats($text);
        $self->parse_nameservers($text);


	$self->{COUNTRY} = $country;
        return $self;
}

1;
