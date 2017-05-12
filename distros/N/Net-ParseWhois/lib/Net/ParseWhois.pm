package Net::ParseWhois;
require 5.004;
use strict;

use IO::Socket;
use IO::File;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Net::ParseWhois::Domain;

$VERSION = '0.7';

require Exporter;

@ISA = qw(Exporter);
@EXPORT = ();

sub debug { 
    my $self = shift;
    my $opt = shift;
    $self->{'debug'} = $opt if ($opt);
    return $self->{'debug'} || 0;
}

# Mapping of whois servers to Top-Level domains. Originally quite sparse, 
# these all pointed to whois.nsiregistry.com. --jcm
sub TLDs {
	{
		COM => 'whois.internic.net',
		NET => 'whois.internic.net',
		ORG => 'whois.publicinterestregistry.net',
		EDU => 'whois.educause.net',
		GOV => 'whois.nic.gov',
		MIL => 'whois.nic.mil'
	}
}


# Mapping of TLDs to their WHOIS model. Basically, this will let us know 
# if there's any referrals to bother to chase. Generally, we're only going
# to chase referrals for .com and .net domains.		--jcm, 11/10/05
sub TLDModel {
	{
		COM => 'thin',
		NET => 'thin',
		ORG => 'thick',
		EDU => 'thick',
		GOV => 'thick',
		MIL => 'thick'
	}
}


sub _connect {
	my $self = shift;

	unless ($self->{'base_server_addr'}) {
		my $a = gethostbyname $self->{'base_server_name'};
		$self->{'base_server_addr'} = inet_ntoa($a) if $a;
	}

	$self->{'base_server_addr'} or croak 'Net::ParseWhois:: no server';

	warn "connecting to $self->{'base_server_addr'} 43\n" if $self->debug;

	my $sock = IO::Socket::INET->new(PeerAddr => $self->{'base_server_addr'},
						 		PeerPort => 'whois',
								Proto => 'tcp')
		or croak "Net::ParseWhois: Can't connect to $self->{'base_server_name'}: $@";
	$sock->autoflush;
	return $sock;
}

sub _load_module {
	my ($self, $module) = @_;
	eval "use $module";
	die "failed to load $module\n" if $@;
}

sub _send_to_sock {
	my $self = shift;
	my $sock = shift;
	my $text_to_send = shift;
	my $sock_text;

	unless ($text_to_send) {
		print $sock "$self->{'domain'}\x0d\x0a";
	} else {
		print $sock $text_to_send;
	}

	{
		local $/; $sock_text = <$sock>;
	}
	undef $sock;
	$sock_text || die "No data returned from $self->{'base_server_name'}\n";
	$sock_text =~ s/^ +//gm;
	my @text = split / *\x0d?\x0a/, $sock_text;
	for (@text) { s/^ +//} # get rid of leading whitespace
	return \@text;
}



sub US_State {
	{
	AL => 'ALABAMA',
	AK => 'ALASKA',
	AZ => 'ARIZONA',
	AR => 'ARKANSAS',
	CA => 'CALIFORNIA',
	CO => 'COLORADO',
	CT => 'CONNECTICUT',
	DE => 'DELAWARE',
	DC => 'DISTRICT OF COLUMBIA',
	FL => 'FLORIDA',
	GA => 'GEORGIA',
	GU => 'GUAM',
	HI => 'HAWAII',
	ID => 'IDAHO',
	IL => 'ILLINOIS',
	IN => 'INDIANA',
	IA => 'IOWA',
	KS => 'KANSAS',
	KY => 'KENTUCKY',
	LA => 'LOUISIANA',
	ME => 'MAINE',
	MH => 'MARSHALL ISLANDS',
	MD => 'MARYLAND',
	MA => 'MASSACHUSETTS',
	MI => 'MICHIGAN',
	MN => 'MINNESOTA',
	MS => 'MISSISSIPPI',
	MO => 'MISSOURI',
	MT => 'MONTANA',
	'NE' => 'NEBRASKA', # nebraska ne 'a real state', heh
	NV => 'NEVADA',
	NH => 'NEW HAMPSHIRE',
	NJ => 'NEW JERSEY',
	NM => 'NEW MEXICO',
	NY => 'NEW YORK',
	NC => 'NORTH CAROLINA',
	ND => 'NORTH DAKOTA',
	MP => 'NORTHERN MARIANA ISLANDS',
	OH => 'OHIO',
	OK => 'OKLAHOMA',
	OR => 'OREGON',
	PA => 'PENNSYLVANIA',
	PR => 'PUERTO RICO',
	RI => 'RHODE ISLAND',
	SC => 'SOUTH CAROLINA',
	SD => 'SOUTH DAKOTA',
	TN => 'TENNESSEE',
	TX => 'TEXAS',
	UT => 'UTAH',
	VT => 'VERMONT',
	VI => 'VIRGIN ISLANDS',
	VA => 'VIRGINIA',
	WA => 'WASHINGTON',
	WV => 'WEST VIRGINIA',
	WI => 'WISCONSIN',
	WY => 'WYOMING',
	}
}

1;


__END__

=head1 NAME

Net::ParseWhois - An extendable alternative to Net::Whois for parsing whois information.

=head1 SYNOPSIS

  # below code based on t/whois.pl in Net::ParseWhois distribution package ...

  use Net::ParseWhois;

  my $dom = 'honestabe.net';

  my $w = Net::ParseWhois::Domain->new($dom);
  unless ($w->ok) {
  	warn "error: " . $w->{'error'} . "\n" if $w->{'error'};
	die "No match for $dom\n";
  }

  print "Registrar: ", $w->registrar, "\n";
  print "Domain: ", $w->domain, "\n";
  print "Name: ", $w->name, "\n";
  print "Tag: ", $w->tag, "\n";
  print "Address:\n", map { "    $_\n" } $w->address;
  print "Country: ", $w->country, "\n";
  print "Name Servers:\n", map { "    $$_[0] ($$_[1])\n" }  @{$w->servers};
  my ($c, $t);
  if ($c = $w->contacts) {
    print "Contacts:\n";
    for $t (sort keys %$c) {
      print "    $t:\n";
      print map { "\t$_\n" } @{$$c{$t}};
    }
  }
  print "Record created:", $w->record_created ;
  print "\nRecord updated:", $w->record_updated,"\n";


=head1 DESCRIPTION

Net::ParseWhois currently only supports domains from major TLDs and 
Registrars (.com, .net & .org -- see REGISTRARS for an exact list of who's 
supported) and tries to maintain backward interface
compatability with Net::Whois.

Net::ParseWhois is my attempt at updating Net::Whois to support whois 
referrals. The author of Net::Whois (Dana Hudes) and I disgreed on how to 
solve the problem of parsing a distrubuted and non-standardized whois 
system, so I created this divergent module. (It's my understanding that 
Mr. Hudes wants to create an IETF draft and assumes registrars/registries 
will then follow it. I've simply taken the current not-so-defined 
situation and coded around it.) 

Net::ParseWhois contains a generalized parsing system that can be 
configured for each Registrar, or completely overridden as needed. 

The class C<Net::ParseWhois::Domain::Registrar> contains a list of known 
servers that could be returned in a whois referral, and specifies the 
specific class to use for each. When C<Net::ParseWhois> receives a 
referral from the 'root' whois server, it creates the specified object 
and calls follow_referral on that object. If a domain is found and a 
referral given, but no Registrar class has been defined to handle that 
referral, the method I<ok> will return true but method 'unknown_registrar' 
will also return true. Net::ParseWhois will still follow the referral, and 
the raw output from the registrar will be available via the method 
'raw_whois_text'.

=head1 REGISTRARS

Currently supported:

	whois.dotster.com - Dotster, Inc.
	whois.register.com - Register.com, Inc.
	whois.networksolutions.com - Network Solutions, Inc.
	whois.opensrs.net - Tucows.com, Inc.
	whois.domaindiscover.com - Tierranet, Inc.
	whois.bulkregister.com - Bulkregister.com, Inc.
	rs.domainbank.net - Domain Bank, Inc.
	whois.registrars.com - INTERNET DOMAIN REGISTRARS (Shopnow?)
	whois.corenic.net - Core Internet Council of Registrars
	whois.InternetNamesWW.com -  Melbourne IT, aka Internet Names Worldwide
	whois.easyspace.com - Easyspace, Ltd.

Not supported (with notes..):

	whois.nordnet.net - should be easy.
	whois.namesecure.com - easy
	whois.compuserve.com - easy
	whois.itsyourdomain.com - easy
	whois.namesdirect.com - easy
	whois.enom.com - easy, but no nameserver or expire/updated data
	whois.domaininfo.com - not too hard. follows same structure, but uses different template/style
	whois.nameit.net - different style, not too hard
	whois.yesnic.com - Korean based registrar, field's are labeled. would require work.
	whois.gandi.net - French, RIPE style whois.
	whois.dotearth.com - might be ugly. no newlines between different sections
	whois.names4ever.com - no data?? down?

	Known registrars that I haven't looked at --

	whois.schlund.de
	whois.registrars.com
	whois.gandi.net
	whois.doregi.com
	whois.dotregistrar.com
	whois.ibi.net
	whois.OnlineNIC.com
	whois.paycenter.com.cn
	whois.domainpeople.com
	whois.awregistry.net
	whois.discount-domain.com
	whois.dotearth.com
	whois.psi-domains.com
	whois.gkg.net
	whois.enetregistry.com
	whois.speednic.net
	whois.domaininfo.com
	whois.catalog.com
	whois.oleane.net
	whois.totalnic.net
	whois.alldomains.com
	whois.signaturedomains.com
	whois.1stdomain.net
	whois.enterprice.net
	whois.stargateinc.com
	whois.e-names.org
	nswhois.domainregistry.com
	whois.worldnet.net
	whois.naame.com
	whois.eastcom.com
	whois.domainzoo.com

Note: Now that CoreNic is supported (thanks Vern!), Net::ParseWhois's 
supported registrars should cover upwards of 90% of the GTLD registrations 
that are out there.

=head1 COMMON METHODS (Specific to Net::ParseWhois)

I<new("a-domain-name-goes-here")>
  Creates a new instance of a Net::ParseWhois object, which attempts a 
lookup of the specified domain name.

I<ok>
  Returns a boolean value indicating whether the Net::ParseWhois object is
"safe" or not. If it returns false, then a match was not found or some 
other error occurred when creating the object. A value of true indicates a
match was found and the various methods for returning Registrar data 
should function.
  Coders should always check this method first after creating a new 
Net::ParseWhois object to avoid script failures.

I<error>
  Returns the error message indicating why the Whois lookup could not be
completed. Will return null if there is no error.

  print "Tag: ", $w->tag, "\n";
  print "Country: ", $w->country, "\n";
  print "Name Servers:\n", map { "    $$_[0] ($$_[1])\n" }  @{$w->servers};
  if ($c = $w->contacts) {
    print "Contacts:\n";
    for $t (sort keys %$c) {
      print "    $t:\n";
      print map { "\t$_\n" } @{$$c{$t}};

The following methods apply only to when a succesful WHOIS lookup was 
performed.

I<domain>
  Returns the domain name the Net::ParseWhois object looked up.

I<registrar>
  Returns the name of the registrar of the domain

I<record_created>
  Returns the date and time the domain's entry was put into this 
registrar's system. Note that this does not necessarily reflect the 
original registration date of the domain!

I<record_updated>
  Returns the date and time the domain's entry was last updated. Updates 
include changes to contact info, registered name servers, etc.

I<name>
  Returns the name of the entity that registerted the domain. Typically 
this will be the name of either a person or a company, but pretty much 
depends on what was used in the initial registration process.

I<address>
  Returns an array of strings representing the physical address registered 
for the domain. This will be the domain owner's address, not that of a 
technical or administrative contact.

I<>


I<>


I<>


I<>


I<>



=head1 GENERIC METHODS (From Net::Whois)

 todo

=head1 SEE ALSO

The Net::ParseWhois project homepage:

    http://dajoba.com/projects/netparsewhois/

The Net::ParseWhois mailing list:

    netparsewhois at lists dot dajoba dot com
    http://lists.dajoba.com/m/listinfo/netparsewhois/

L<Net::Whois>, L<Net::Whois::Raw>, L<Net::RWhois>

=head1 AUTHORS / ACKNOWLEDGMENTS

Net::ParseWhois is maintained by Abraham A. Ingersoll <abe@dajoba.com>.

This module is a based on Net::Whois, which is maintained by
Dana Hudes (dhudes@hudes.org). Net::Whois was originally written by Chip 
Salzenberg (chip@pobox.com).

Thanks to:

Joseph Ingersoll for testing under ActivePerl.
Curtis Poe for comments and bug testing.
Andy Baio for first version of Registrars.pm.
Simon Flack for newer registrars.com parsing module & bug sleuthing.
Douglas Freake for (yet to be used) address parsing contribution.
Vern Hart for (especially tough) CoreNic.pm parsing module.
Adam Stubbs for INameWW.pm and Easyspace.pm parsing modules.

=head1 COPYRIGHT

Copyright 2000 Abraham A Ingersoll <abe@dajoba.com>

Some portions may be copyright 1998 Dana Hudes & Chip Salzenberg.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
