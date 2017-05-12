package Net::DLookup;

=head1 NAME

Net::DLookup - Perform domain lookups on 2-letter and 3-letter TLDs

=head1 SYNOPSIS

     use Net::DLookup;

     # Initialize Net::DLookup object
     my $dlu = Net::DLookup -> new;

     # Replace domain definitions from a file
     $dlu -> LoadTLD($file, 1);

     # Add domain definitions from a file
     $dlu -> LoadTLD($file, 0);

     # Check domain name validity and assign it to the object
     @errors = $dlu -> IsValid($domain);

     # Return availability
     @response = $dlu -> DoWhois(0);

     # Return availability and registrar information
     @response = $dlu -> DoWhois(1);


=head1 DESCRIPTION

Net::DLookup performs domain lookups for 2-letter and 3-letter top level domains.  It also verifies the validity of 
domain names by checking punctuation, length, metacharacters, etc..

Information for currently recognized top level domains is included within the module. This list may be replaced or 
added to by calling $dlu->LoadTLD().

With the advent of new registrars for 3-letter top level domains, it's become difficult to get the 
whois output from a single domain lookup, unless you know what registration agency to look at.  Net::DLookup solves
this problem by checking Internic's database first and then performing a second query to the respective registrar
for full whois output.


=head1 USAGE

These functions must be used in order:

Of course:

     use Net::DLookup;

Create an object that contains the default top level domains.

     my $dlu = Net::DLookup -> new;

Validate domain name ($domaintocheck) and associate it with the object.
This must be the full domain name, such as yourdomain.com.

     my @errors = $dlu -> IsValid($domaintocheck);

It checks for the following possible errors:

=over 4

=item Is 67 characters or less for 3-letter TLDs

=item Is not a 3rd level domain for 3-letter TLDs (me.yourdomain.com)

=item Is 26 characters or less for 2-letter TLDs

=item Is not a 4th level domain for 2-letter TLDs (me.yourdomain.co.uk)

=item Does not start or end with a non-alphanumeric character

=item Does not contain non alphanumeric characters (except a dash) within the domain name

=item Is a valid TLD*

=back

* All CCTLDs (Country Code TLDs) currently listed at IANA as well as the .com, .net, .org, .edu and .mil are checked

@errors will contain a list of all possible errors that the domain name may have, such as:

=over 4

=item Domain name can't start or end with non-alphanumeric character.

=item Domains with the .com extension cannot exceed 67 characters.

=back

Last, the domain lookup.  

     @response = $domain->Net::DLookup::DoWhois();

=over 4 @response will contain (in order)

=item Is domain registered?   1 for yes; 0 for no

=item Name of Registration Agency or Country

=item URL of Registration Agency for TLD

=item Whois Server for TLD

=item Whois Output

=item A "worded" reponse for domain availability "{domain} is available"

=back

If you're looking up a 3-letter TLD domain (.com, .net, .org, .edu and .mil), you have the choice to NOT perform 
the second lookup.  This would be useful if you're just checking for domain availability and don't care who's 
already registered it.  You can disable the second lookup by removing the 1.  This will give you Internic's
plain Jane, uninformative whois information.

     @response = $domain->Net::DLookup::DoWhois(1);

=cut


=head1 RESTRICTIONS

Net::DLookup requires that the Sockets (included with the Perl distribution) module is installed.

=head1 VERSION

Net::DLookup Version 1.01  6/10/2000

=head1 CAVEATS

Registration agencies are finicky beasts.  They may change their whois server, urls, or responses (that this module
relies on) without notice.  As of 6/10/2000, the agency data in the module is accurate.

=head1 CREDITS

Many thanks goes to Michael Chase for the new LoadTLD() and DumpTLD() routines.

=head1 AUTHOR

D. Jasmine Merced  <djasmine@tnsgroup.com>, CPAN ID: DJASMINE

The Perl Archive  <http://www.perlarchive.com>

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 
If you make modifications, the author would like to know so that they can be incorporated into future releases. 

=cut


use strict;
use vars qw( $VERSION %_tld_data );
$VERSION = '1.01';

use Exporter;
my @ISA = qw( Exporter );

# Initialize class level data
my ( $MAX2TLD, $MAX3TLD, @ERRORS ) = ( 26, 67 );

sub new {
    my $class = ref $_[0] || $_[0];

    my $dlu = bless {
	_TLD_DATA      	=>	undef,

	_FULLDOMAIN	=>	$_[1],
	_NAME		=>	undef,
	_TLD		=>	undef,
	_NATION		=>	undef,

	_ISVALID	=>	undef,
	_RESPONSE	=>	undef,
	_WHOISOUTPUT	=>	undef,
	_ISREGISTERED	=>	undef,

	_TLDNAME	=>	undef,
	_TLDURL		=>	undef,
	_TLDMATCHRESP	=>	undef,
	_TLDQUERYDB	=>	undef,

	ERROR		=>	undef,

    }, $class;

    $dlu -> LoadTLD( $_[1], 1 );
    return $dlu;
}

sub LoadTLD {
	my ( $dlu, $file, $clear ) = @_;
	my $oldfile = '';
	my ( $TLD, $URL, $QUERYDB, $MATCHRESP, $NAME );

	$dlu -> {_TLD_DATA} = {} if $clear || ! $dlu -> {_TLD_DATA};

	if ( $file ) {
		if ( ! ref $file ) {
			open( FILE, "<$file" ) or die "Can't read from $file, $!";
			$oldfile = $file;
			$file = \*FILE;
		}
		while ( <$file> ) {
			s/\s+$//;
			next if '' eq $_ || /^\s*#/;
			( $TLD, $URL, $QUERYDB, $MATCHRESP, $NAME ) = split(/\t/,$_);
			foreach ( $TLD, $URL, $QUERYDB, $MATCHRESP, $NAME ) {
				$_ = '' if ! defined $_;
			}
			${$dlu -> {_TLD_DATA}}{$TLD} = [ $URL, $QUERYDB, $MATCHRESP, $NAME ]; 
		}
		close $file if $oldfile;
	}
	if ( ! keys %{$dlu -> {_TLD_DATA}} ) {
		my $start = tell DATA;
		$dlu -> LoadTLD( \*DATA, 1 );
		seek DATA, $start, 0;
	}
}

sub DumpTLD {
	my ( $dlu, $file ) = @_;
	return if ! $file || ! $dlu -> {_TLD_DATA};
	my ( $oldfile, $TLD, $line, @dom );

	if ( ! ref $file ) {
		open( FILE, ">$file" ) or die "Can't write to $file, $!";
		$oldfile = $file;
		$file = \*FILE;
	}
	foreach $TLD (
		# Sort domains by most general part first
		map { @dom = split /\t/, $_; join ".",  reverse @dom }
		sort
		map { @dom = split /\./, $_; join "\t", reverse @dom }
		keys %{$dlu -> {_TLD_DATA}} 
	){
		$line = join "\t", $TLD, @{$dlu -> {_TLD_DATA}{$TLD}};
		$line =~ s/\s+$//;
		print $file "$line\n";
	}
	close $file if $oldfile;
}


sub IsValid {
	my ($self,$domain) = @_;
	@ERRORS = ();
	unless ($domain){
		push(@ERRORS,"Error.  No domain has been entered.\n");
	}
	else {
		$self->{_FULLDOMAIN} = $domain;
		my @DOMAIN = ();
		@DOMAIN = split(/\./,$self->{_FULLDOMAIN});
		my @REVERSED = reverse @DOMAIN;

		if($DOMAIN[3]){
			push(@ERRORS,"Error.  Fourth level domains are not acceptable.\n")
		}
		elsif ($DOMAIN[2]){
			if(length($REVERSED[0])==2){
				$self->{_TLD} = $REVERSED[1].'.'.$REVERSED[0];
				$self->{_NAME} = $REVERSED[2];
			}
			else {
				push(@ERRORS,"This program cannot handle 3rd level domains.\n");
			}
		}
		else {
			$self->{_TLD} = $REVERSED[0];
			$self->{_NAME} = $REVERSED[1];
		}

		if (($self->{_TLD})&&($self->{_NAME})){
			_GetRegistrar($self);
			_ValidateName($self);
		}
		else {
			push(@ERRORS,"Error.  Invalid domain name.\n");
		}

	}
	return @ERRORS;
}

sub DoWhois {
	my $self = shift;
	my $INTERNICWHOIS = shift;
	my ($ATTEMPTS,$MAXTRIES) = "";

	unless ($self->{TLDQUERYDB}){
		_GetRegistrar($self);
	}

	if ($self->{_TLDQUERYDB}){

		my (@RESULT) = _PerformWhois($self);
		foreach(@RESULT){
			$self->{_WHOISOUTPUT} .= $_;
		}

		$self->{_ISREGISTERED} = 1;

		$self->{_RESPONSE} = "$self->{_FULLDOMAIN} is already registered.\n";

		if ($self->{_WHOISOUTPUT} =~ /$self->{_TLDMATCHRESP}/mig){
			$self->{_ISREGISTERED} = 0;
			$self->{_RESPONSE} = "$self->{_FULLDOMAIN} is available for registration.";
		}
		elsif ($self->{_WHOISOUTPUT} =~ /^\*/mig) {
			$ATTEMPTS++;
			sleep(1);
			if ($ATTEMPTS > $MAXTRIES) {
				$self->{_RESPONSE} = "Internic's Whois database is unavailable.";
			}  
		} 
		elsif ($self->{_RESPONSE} =~ /$!/g) {
			$self->{_RESPONSE} = "Could not connect to whois server $self->{_TLDQUERYDB}: $!";
		}

		if (($self->{_ISREGISTERED}==1)&&(length($self->{_TLD})==3)){
			foreach(@RESULT){
				chomp;
				if (/Registrar: /){
					$self->{_TLDNAME} = (split(/Registrar: /,$_))[1];
				}
				if (/Whois Server\: /){
					$self->{_TLDQUERYDB} = (split(/Whois Server: /,$_))[1];
				}
				if (/Referral URL: /){
					$self->{_TLDURL} = (split(/Referral URL: /,$_))[1];
				}	
			}
		}
		if($INTERNICWHOIS){
			@RESULT = _PerformWhois($self);
			if (@RESULT){$self->{_WHOISOUTPUT}=undef;}
			foreach(@RESULT){
				$self->{_WHOISOUTPUT} .= $_;
			}
		}
	}
	else {
		$self->{_RESPONSE} = "$self->{_TLD} does not have a whois server to look up. ";
		$self->{_RESPONSE} .= "More information can be found at $self->{_TLDURL}" if $self->{_TLDURL};
	}

	return ($self->{_ISREGISTERED},$self->{_TLDNAME},$self->{_TLDURL},$self->{_TLDQUERYDB},$self->{_WHOISOUTPUT},$self->{_RESPONSE},$self->{_TLD});
}

sub _ValidateName {
	my $self = shift;

	my $tldlength 		= length($self->{_TLD});
	my $domlength 		= length($self->{_FULLDOMAIN});
	my $strip_dashes 	= $self->{_NAME};
	my $temptest 		= $self->{_TLD};
	my @tippytoptld 	= split(/\./,$self->{_TLD});

	unless($tippytoptld[1]){
		$tippytoptld[1] = $tippytoptld[0];
	}

	$strip_dashes =~ s/(-||\.)//g;

	# Check TLD length
	if (($tldlength > 6)||($tldlength <2)){
		push(@ERRORS,"Invalid TLD.\n")
	}

	# Check fully qualified domain name length
	if ((length($tippytoptld[1]) == 2)&&($domlength > $MAX2TLD)){
		push(@ERRORS,"Domains with the $self->{_TLD} extension cannot exceed $MAX2TLD characters.\n");
	}
	elsif ((length($tippytoptld[1]) == 3)&&($domlength > $MAX3TLD)){
		push(@ERRORS,"Domains with the $self->{_TLD} extension cannot exceed $MAX3TLD characters.\n");
	}

	# Check dash placement
	if (($self->{_NAME} =~ /^\W/)||($self->{_NAME} =~ /\W$/)){
		push(@ERRORS,"Domain name can't start or end with non-alphanumeric character.\n");
	}

	# Check for invalid characters
	if ($strip_dashes =~ /\W/){
		push(@ERRORS,"Invalid characters in domain name $strip_dashes.\n");
	}

}


sub _GetRegistrar {
	my $self = shift;

	$self -> LoadTLD( '', 1 ) if ! keys %{$self -> {_TLD_DATA}};

	my $TLD = '';
	if    ( exists $self -> {_TLD_DATA}{$self -> {_TLD}} ) {
		$TLD = $self -> {_TLD};
	}
	elsif ( exists $self -> {_NATION} &&
		exists $self -> {_TLD_DATA}{$self -> {_NATION}} ) {
		$TLD = $self -> {_NATION};
	}

	if ( $TLD ) {
		my ( $URL, $QUERYDB, $MATCHRESP, $NAME ) = @{$self -> {_TLD_DATA}{$TLD}};
		$self -> {_TLDNAME}		= $NAME;
		$self -> {_TLDURL}		= $URL;
		$self -> {_TLDMATCHRESP}	= $MATCHRESP;
		$self -> {_TLDQUERYDB}		= $QUERYDB;
	}

	unless ($self->{_TLDNAME}){
		push @ERRORS, ".$self->{_TLD} is not a valid top level domain.\n";
	}

}

sub _PerformWhois {
	my $self = shift;
	my(@RESULT,$SIN,$LEN,$OFFSET,$WRITTEN,$BUFFER) = "";
	return "No whois server for $self->{_TLD}" if ! $self->{_TLDQUERYDB};
	my ( $whois, $opts ) = ( $self->{_TLDQUERYDB}, '' );
	( $whois, $opts ) = split /\s+/, $whois, 2 if $whois =~ /\s/;
	use Socket;
	socket(SOCK, PF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2]) || return ((""));

	$SIN = sockaddr_in(43, inet_aton( $whois ));
	connect(SOCK, $SIN) || return (("$!"));
	$OFFSET = 0;
	$BUFFER = $self->{_FULLDOMAIN} . "$opts\r\n";
	$LEN = length($BUFFER);
	while($LEN) {
		$WRITTEN = syswrite(SOCK,$BUFFER,$LEN,$OFFSET);
		$LEN -= $WRITTEN;
		$OFFSET += $WRITTEN;
	}

	@RESULT=<SOCK>;
	close(SOCK);
	return @RESULT;
}

1;


__DATA__
mil	http://www.networksolutions.com/	whois.internic.net	No match	Internic Military
com	http://www.networksolutions.com/	whois.internic.net	No match	Internic Commercial
net	http://www.networksolutions.com/	whois.internic.net	No match	Internic Network
org	http://www.networksolutions.com/	whois.internic.net	No match	Internic Organization
edu	http://www.networksolutions.com/	whois.internic.net	No match	Internic Educational
ac	http://www.nic.ac/	whois.ripe.net	No entries found	Ascension Isl. General
ac.ac	http://www.nic.ac/	whois.ripe.net	No entries found	Ascension Isl. Academic
ac.at	http://www.nic.at/	whois.aco.net	No entries found	Austria Academic
ac.be	http://www.dns.be/	whois.ripe.net	No entries found	Belgium Academic
ac.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Academic
ac.il	http://www.isoc.org.il/	whois.ripe.net	No entries found	Israel Academic
ac.in	http://soochak.ncst.ernet.in/~domainreg/	whois.iisc.ernet.in	no entries found	India Academic
ac.jp	http://www.nic.ad.jp/	whois.nic.ad.jp	No match	Japan Academic
ac.kr	http://www.krnic.net/english/index.html	whois.nic.or.kr	is not registered	Korea Academic
ac.th	http://www.thnic.net/	whois.thnic.net	No entries	Thailand Academic
ac.uk	http://www.nic.uk/	whois.ja.net	No match	UK Academic
ac.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Academic
ad	http://www.nic.ad/			Andorra
ae	http://www.emirates.net.ae/			United Arab Emirates
af		whois.netnames.net	No Match	Afghanistan
ah.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
ai	http://www.offshore.com.ai/domain_names/			Anguilla
al	inima@inima.al			Albania
alt.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Alternative
am	http://www.amnic.net/	whois.nic.am	No information available	Armenia
an				Netherlands Antilles
arts.ro	http://www.rnc.ro/	whois.ripe.net	No entries found	Romania Artistic
as	http://www.nic.as/	whois.nic.as	Domain Not Found	American Somoa
asn.au	http://www.aunic.net/	whois.aunic.net	No entries found	Australia Association
asso.fr	http://www.nic.fr/	whois.nic.fr	No entries found	France Asso
asso.mc	http://www.nic.mc/	whois.ripe.net	No entries found	Monaco Organization
at	http://www.nic.at/	whois.aco.net	No entries found	Austria General
ba	http://www.utic.net.ba/			Bosnia & Herzegovina
bbs.tr	http://dns.metu.edu.tr/	whois.metu.edu.tr	Not found in database	Turkey BBS
bc.ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada Regional
be	http://www.dns.be/	whois.ripe.net	No entries found	Belgium
bf	http://www.onatel.bf/domaine.htm			Burkina Faso
bg	http://www.digsys.bg/bg-nic/			Bulgaria
bi	http://www.nic.cd/			Burundi
bj.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
bn	http://jtb.brunet.bn/brunet/brunet.htm			Brunei Darussalam
br	http://registro.fapesp.br/			Brazil
bt	http://www.nic.bt/	whois.nic.bt	shrubbery.com	Bhutan
bv				Bouvet Island
bw				Botswana
ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada
cc	http://www.nic.cc/	whois.nic.cc	No match	ISC International
cd	http://www.nic.cd/			Zaire
cf	http://www.socatel.intnet.cf/			Central African Republic
cg	http://www.nic.cd/			Congo
ch	http://www.nic.ch/	whois.nic.ch	No entries found	Switzerland
ci	oumtana@aipdi.ci			Ivory Coast
ck				Cook Islands
cl	http://www.nic.cl/			Chile
cm	http://info.intelcam.cm/			Cameroon
cn	http://www.cnnic.net.cn/indexeng.html			China
co	http://polifemo.uniandes.edu.co/PAGINAS/NEWDOMCO/defsolict.htm			Colombia
co.ac	http://www.nic.ac/	whois.ripe.net	No entries found	Ascension Isl. Commercial
co.at	http://www.nic.at/	whois.aco.net	No entries found	Austria Commercial
co.il	http://www.isoc.org.il/	whois.ripe.net	No entries found	Israel Commercial
co.in	http://soochak.ncst.ernet.in/~domainreg/	whois.iisc.ernet.in	no entries found	India Commercial
co.jp	http://www.nic.ad.jp/	whois.nic.ad.jp	No match	Japan Commercial
co.kr	http://www.krnic.net/english/index.html	whois.nic.or.kr	is not registered	Korea Commercial
co.th	http://www.thnic.net/	whois.thnic.net	No entries	Thailand Commercial
co.uk	http://www.nic.uk/	whois.nic.uk	No match	UK Commercial
co.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Commercial
com.al	nfra@inima.al			Albania
com.au	http://www.aunic.net/	whois.aunic.net	No entries found	Australia Commercial
com.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Commercial
com.ec	http://www.nic.ec/	whois.lac.net	No match found	Ecuador Commercial
com.hk	http://www.cuhk.hk/	whois.hknic.net.hk	returns no relevent	Hong Kong Commercial
com.mm	http://www.nic.mm/	whois.nic.mm	No domains matched	Myanmar Commercial
com.mx	http://www.nic.mx/	whois.nic.mx	Referencias de Organization No Encontradas	Mexico Commercial
com.pl	http://www.nask.pl/	whois.ripe.net	No entries found	Poland Commercial
com.ro	http://www.rnc.ro/	whois.ripe.net	No entries found	Romania Commercial
com.ru	http://www.ripn.net/nic/	whois.ripn.net	No entries found	Russia Commercial
com.sg	http://www.nic.net.sg/	whois.nic.net.sg	NO entry found	Singapore Commercial
com.tr	http://dns.metu.edu.tr/	whois.metu.edu.tr	Not found in database	Turkey Commercial
cq.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
cr	http://www.nic.cr/			Costa Rica
cs				Czechoslovakia (former)
cu	http://www.nic.cu/			Cuba
cv				Cape Verde Islands
cx	http://www.nic.cx/	whois.nic.cx	Domain not found	Christmas Island
cy	http://www.ucy.ac.cy/form1.html			Cyprus
cz	http://www.nic.cz	whois.ripe.net	No entries found	Czech Republic
de	http://www.nic.de/	whois.ripe.net	No entries found	Germany
dj	http://www.intnet.dj/			Djibouti
dk	http://www.dk-hostmaster.dk/	whois.ripe.net	No entries found	Denmark
dm				Dominica
do	http://www.nic.do/			Dominican Republic
dz				Denmark
ec	http://www.nic.ec/			Ecuador
edu.al	gdaci@uptal.tirana.al			Albania
edu.au	http://www.aunic.net/	whois.aunic.net	No entries found	Australia Educational
edu.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Educational
edu.hk	http://www.cuhk.hk/	whois.hknic.net.hk	returns no relevent	Hong Kong Educational
edu.mm	http://www.nic.mm/	whois.nic.mm	No domains matched	Myanmar Educational
edu.mx	http://www.nic.mx/	whois.nic.mx	Referencias de Organization No Encontradas	Mexico Educational
edu.tr	http://dns.metu.edu.tr/	whois.metu.edu.tr	Not found in database	Turkey Educational
edu.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Educational
ee	http://www.eenet.ee/services/subdomains.html			Estonia
eg	http://www.frcu.eun.eg/			Egypt
eh				Western Sahara
er				Eritrea
ernet.in	http://soochak.ncst.ernet.in/~domainreg/	whois.iisc.ernet.in	no entries found	India ERNET
es	http://www.nic.es/			Spain
et	http://www.telecom.net.et/			Ethiopia
fi	http://www.thk.fi/			Finland
fin.ec	http://www.nic.ec/	whois.lac.net	No match found	Ecuador Finance
firm.ro	http://www.rnc.ro/	whois.ripe.net	No entries found	Romania Firm
fj	http://www.usp.ac.fj/domreg/			Fiji
fk	http://www.fidc.org.fk/domain-registration/home.htm			Falkland Islands
fm	http://www.dot.fm/			Micronesia
fo	http://www.nic.fo/	whois.ripe.net	No entries found	Faroe Islands
fr	http://www.nic.fr/	whois.nic.fr	No entries found	France General
fx				France - Metropolitan
ga				Gabon
gb	http://www.nic.uk/			United Kingdom
gb.com	http://www.nic.uk/	whois.nomination.net	No match for	Alternative UK Name
gb.net	http://www.nic.uk/	whois.nomination.net	No match for	Alternative UK Name
gd				Grenada
gd.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
ge	http://www.nic.net.ge/			Georgia
gf	http://www.nplus.gf/	whois.nplus.gf	not found in our database	French Guiana
gg	http://www.isles.net/			Guernsey
gh	http://www.ghana.com/inet/domreg.html			Ghana
gi	http://www.gibnet.gi/nic/			Gibraltar
gl	http://www.nic.gl/			Greenland
gm				Gambia
gn	http://www.psg.com/dns/gn/			Guinea
go.jp	http://www.nic.ad.jp/	whois.nic.ad.jp	No match	Japan Government
go.kr	http://www.krnic.net/english/index.html	whois.nic.or.kr	is not registered	Korea Government
go.th	http://www.thnic.net/	whois.thnic.net	No entries	Thailand Government
gov.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Government
gov.ec	http://www.nic.ec/	whois.lac.net	No match found	Ecuador Government
gov.hk	http://www.cuhk.hk/	whois.hknic.net.hk	returns no relevent	Hong Kong Government
gov.il	http://www.isoc.org.il/	whois.ripe.net	No entries found	Israel Government
gov.in	http://soochak.ncst.ernet.in/~domainreg/	whois.iisc.ernet.in	no entries found	India Government
gov.mm	http://www.nic.mm/	whois.nic.mm	No domains matched	Myanmar Government
gov.mx	http://www.nic.mx/	whois.nic.mx	Referencias de Organization No Encontradas	Mexico Government
gov.sg	http://www.nic.net.sg/	whois.nic.net.sg	NO entry found	Singapore Government
gov.tr	http://dns.metu.edu.tr/	whois.metu.edu.tr	Not found in database	Turkey Government
gov.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Government
gp	http://www.nic.gp/			Guadeloupe
gq	http://www.getesa.gq/			Equatorial Guinea
gr	http://www.hostmaster.gr/			Greece
gs	http://www.gs/			Georgia
gs.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
gt	http://www.gt/cir/cir.htm			Guatemala
gu	http://gadao.gov.gu/			Guam
gv.ac	http://www.nic.ac/	whois.ripe.net	No entries found	Ascension Isl. Government
gv.at	http://www.nic.at/	whois.aco.net	No entries found	Austria Government
gw				Guinea-Bissau
gx.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
gy				Guyana
gz.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
hb.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
he.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
hi.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
hk	http://www.cuhk.hk/			Hong Kong
hk.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
hl.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
hm	http://www.hmnic.net/			Hearn and McDonald Islands
hn	http://www.hn/			Honduras
hn.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
hr	http://www.carnet.hr/DNS/			Croatia
ht	http://www.haitiworld.com/			Haiti
hu	http://www.nic.hu/			Hungary
id	http://www.idnic.net.id/			Indonesia
ie	http://www.ucd.ie/hostmaster/			Ireland
il	http://www.isoc.org.il/			Israel
im	http://www.nic.im/			Isle of Man
in	http://soochak.ncst.ernet.in/~domainreg/			India
info.ro	http://www.rnc.ro/	whois.ripe.net	No entries found	Romania Informational
io	http://www.nic.io/			British Indian Ocean Territory
iq				Iraq
ir	http://www.nic.ir/			Iran
is	http://www.isnet.is/nic/	whois.ripe.net	No entries found	Iceland
it	http://www.nic.it/	whois.ripe.net	No entries found	Italy
je	http://www.isles.net/			Jersey
jl.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
jm				Jamaica
jo	http://www.nic.gov.jo/			Jordan
jp	http://www.nic.ad.jp/			Japan
ad.jp	http://www.nic.ad.jp/	whois.nic.ad.jp	No match	Japan Admin
js.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
k12.il	http://www.isoc.org.il/	whois.ripe.net	No entries found	Israel K12
k12.tr	http://dns.metu.edu.tr/	whois.metu.edu.tr	Not found in database	Turkey K12
ke	http://www.nbnet.co.ke/index.html			Kenya
kg	http://www.kg/			Kyrgystan
kh	http://www.camnet.com.kh/			Cambodia
ki				Kiribati
km				Comoros
kn				St. Kitts & Nevis
kp				Korea, Democratic People's Rep
kr	http://www.krnic.net/english/index.html			Korea, Republic of
kw				Kuwait
ky	http://www.nic.ky			Cayman Islands
kz	http://www.domain.kz/			Kazakhstan
la				Laos
lb	http://www.aub.edu.lb/lebanon-online/			Lebanon
lc	http://www.sluonestop.com/isis/dns/			St. Lucia
li	http://www.nic.li/	whois.nic.li	No entries found	Liechtenstein
lk	http://www.nic.lk/			Sri Lanka
ln.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
lr				Liberia
ls				Lesotho
lt	http://vingis.sc-uni.ktu.lt/domreg/	whois.ripe.net	No entries found	Lithuania
ltd.uk	http://www.nic.uk/	whois.nic.uk	No match	UK Ltd
lu	http://www.dns.lu/	whois.ripe.net	No entries found	Luxembourg
lv	http://www.nic.lv/DNS/			Latvia
ly	http://www.nic.ly/			Libya
ma				Morocco
mb.ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada Regional
mc	http://www.nic.mc/			Monaco
md	http://www.nic.md/			Moldova
med.ec	http://www.nic.ec/	whois.lac.net	No match found	Ecuador Medical
mg	nic-mg@orstom.mg			Madagascar
mh	http://www.nic.net.mh/			Marshall Islands
mi.th	http://www.thnic.net/	whois.thnic.net	No entries	Thailand Military
mil.ec	http://www.nic.ec/	whois.lac.net	No match found	Ecuador Military
mil.tr	http://dns.metu.edu.tr/	whois.metu.edu.tr	Not found in database	Turkey Military
mil.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Military
mk	http://www.mpt.com.mk/			Macedonia
ml				Mali
mm	http://www.nic.mm/	Myanmar		
mn	http://www.mongoliaonline.mn/			Mongolia
mo	http://www.umac.mo/other/index.html			Macao
mo.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
mp				Northern Marianas Islands
mq	http://www.nic.mq/			Martinique
mr	http://www.univ-nkc.mr/nic_mr.html			Mauritania
ms	http://www.ms/			Montserrat
mt	http://www.um.edu.mt/nic/			Malta
mu	http://www.posix.co.za/mu/			Mauritius
muni.il	http://www.isoc.org.il/	whois.ripe.net	No entries found	Israel Municipality
mv				Maldives
mw	http://www.tarsus.net/			Malawi
mx	http://www.nic.mx/	whois.nic.mx	Referencias de Organization No Encontradas	Mexico General
my	http://www.mynic.net/			Malaysia
mz				Mozambique
na	http://www.lisse.na/dns/			Namibia
nb.ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada Regional
nc	http://www.orstom.nc/BASE/ORSTOM_CENTRE/TLD_NC/registration.html			New Caledonia
ne				Niger
ne.jp	http://www.nic.ad.jp/	whois.nic.ad.jp	No match	Japan Network
ne.kr	http://www.krnic.net/english/index.html	whois.nic.or.kr	is not registered	Korea Network
net.au	http://www.aunic.net/	whois.net.au	AUNIC -T domain	Australia ISP
net.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Internet/Networking
net.ec	http://www.nic.ec/	whois.lac.net	No match found	Ecuador ISP
net.hk	http://www.cuhk.hk/	whois.hknic.net.hk	returns no relevent	Hong Kong Network
net.il	http://www.isoc.org.il/	whois.ripe.net	No entries found	Israel Network
net.in	http://soochak.ncst.ernet.in/~domainreg/	whois.iisc.ernet.in	no entries found	India Network
net.mm	http://www.nic.mm/	whois.nic.mm	No domains matched	Myanmar Network
net.mx	http://www.nic.mx/	whois.nic.mx	Referencias de Organization No Encontradas	Mexico Network
net.pl	http://www.nask.pl/	whois.ripe.net	No entries found	Poland Network
net.ru	http://www.ripn.net/nic/	whois.ripn.net	No entries found	Russia Network
net.sg	http://www.nic.net.sg/	whois.nic.net.sg	NO entry found	Singapore Network
net.th	http://www.thnic.net/	whois.thnic.net	No entries	Thailand Network
net.tr	http://dns.metu.edu.tr/	whois.metu.edu.tr	Not found in database	Turkey Network
net.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Network
nf	http://www.names.nf/			Norfolk Island
nf.ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada Regional
ng				Nigeria
ngo.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Non Govt Org
ni	http://165.98.1.2/nic-for.html			Nicaragua
nl	http://www.domain-registry.nl/	whois.nic.nl	not a registered domain	Netherlands
nm.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
nm.kr	http://www.krnic.net/english/index.html	whois.nic.or.kr	is not registered	Korea Nm
no	http://www.uninett.no/navn/	whois.ripe.net	No entries found	Norway
nom.ro	http://www.rnc.ro/	whois.ripe.net	No entries found	Romania Personal
nom.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Individual
np				Nepal
nr				Nauru
ns.ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada Regional
nt				Neutral Zone
nt.ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada Regional
nt.ro	http://www.rnc.ro/	whois.ripe.net	No entries found	Romania Nt
nu	http://www.nunames.nu/	whois.nic.nu	No match	Niue
nx.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
nz	http://www.domainz.net.nz/			New Zealand
om	http://www.gto.net.om/index.shtml			Oman
on.ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada Regional
or.ac	http://www.nic.ac/	whois.ripe.net	No entries found	Ascension Isl. Organization
or.at	http://www.nic.at/	whois.aco.net	No entries found	Austria Organization
or.jp	http://www.nic.ad.jp/	whois.nic.ad.jp	No match	Japan Organization
or.kr	http://www.krnic.net/english/index.html	whois.nic.or.kr	is not registered	Korea Organization
or.th	http://www.thnic.net/	whois.thnic.net	No entries	Thailand Organization
org.al	rezi@soros.al			Albania
org.au	http://www.aunic.net/	whois.aunic.net	No entries found	Australia Organization
org.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Organization
org.ec	http://www.nic.ec/	whois.lac.net	No match found	Ecuador Organization
org.hk	http://www.cuhk.hk/	whois.hknic.net.hk	returns no relevent	Hong Kong Organization
org.il	http://www.isoc.org.il/	whois.ripe.net	No entries found	Israel Organization
org.mm	http://www.nic.mm/	whois.nic.mm	No domains matched	Myanmar Organization
org.mx	http://www.nic.mx/	whois.nic.mx	Referencias de Organization No Encontradas	Mexico Organization
org.pl	http://www.nask.pl/	whois.ripe.net	No entries found	Poland Organization
org.ro	http://www.rnc.ro/	whois.ripe.net	No entries found	Romania Organization
org.ru	http://www.ripn.net/nic/	whois.ripn.net	No entries found	Russia Organization
org.sg	http://www.nic.net.sg/	whois.nic.net.sg	NO entry found	Singapore Organization
org.tr	http://dns.metu.edu.tr/	whois.metu.edu.tr	Not found in database	Turkey Organization
org.uk	http://www.nic.uk/	whois.nic.uk	No match	UK Organization
org.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Organization
pa	http://www.nic.pa/			Panama
pe	http://ekeko.rcp.net.pe/rcp/PE-NIC/			Peru
pe.ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada Regional
pf				French Polynesia
pg				Papua New Guinea
ph	http://www.domreg.org.ph/			Philippines
pk	http://www.pknic.net.pk/			Pakistan
pl	http://www.nask.pl/	whois.ripe.net	No entries found	Poland General
plc.uk	http://www.nic.uk/	whois.nic.uk	No match	UK Plc
pm	http://www.nic.pm/			St. Pierre
pn	http://www.nic.pn/			Pitcairn
pr	http://www.uprr.pr/main.html			Puerto Rico
presse.fr	http://www.nic.fr/	whois.nic.fr	No entries found	France Presse
pt	http://www.dns.pt/	whois.ripe.net	No entries found	Portugal
pw				Palau
py	http://www.cnc.una.py/regdom/			Paraguay
qa	http://www.qatar.net.qa/			Qatar
qc.ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada Regional
qh.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
re	http://www.nic.fr/			Reunion Island
re.kr	http://www.krnic.net/english/index.html	whois.nic.or.kr	is not registered	Korea Research
rec.ro	http://www.rnc.ro/	whois.ripe.net	No entries found	Romania Recreational
res.in	http://soochak.ncst.ernet.in/~domainreg/	whois.iisc.ernet.in	no entries found	India Research
ro	http://www.rnc.ro/			Romania
ru	http://www.ripn.net/nic/	whois.ripn.net	No entries found	Russian Companies Only
rw	http://www.nic.cd/			Rwanda
sa	http://www.saudinic.net.sa/			Saudi Arabia
sb	http://www.nic.net.sb/			Solomon Islands
sc	http://www.sc/			Seychelles
sc.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
school.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa School
sd	http://www.sudatel.sd/			Sudan
se	http://www.nic-se.se/	whois.nic-se.se	No entries found	Sweden
sg	http://www.nic.net.sg/			Singapore
sh	http://www.nic.sh/			St. Helena
sh.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
si	http://www.arnes.si/si-domene/			Slovenia
sj				Svalbard and Jan Mayen Islands
sk	http://www.eunet.sk/sk-nic/	whois.ripe.net	No entries found	Slovak Republic
sk.ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada Regional
sl				Sierra Leone
sm	http://www.intelcom.sm/Naming/			San Marino
sn	http://www.ucad.sn/nic.html			Senegal Republic
sn.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
so	http://www.wcd.so/			Somalia
sr				Surinam
st	http://www.nic.st/			Sao Tome
store.ro	http://www.rnc.ro/	whois.ripe.net	No entries found	Romania Store
su	http://www.ripn.net/nic/			USSR (former)
sv	http://www.svnet.org.sv/			El Salvador
sy				Syria
sz	http://www.iafrica.sz/domreg/			Swaziland
tc	http://www.tc/			Turks & Caicos
td				Chad
tf	http://www.tf/	French Southern Territories		
tg				Togo
th	http://www.thnic.net/			Thailand
tj	http://www.nic.tj/	whois.nic.tj	No match	Tajikistan
tj.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
tk				Tokelau
tm	http://www.nic.tm/	whois.nic.tm	No Match	Turkmenistan
tm.fr	http://www.nic.fr/	whois.nic.fr	No entries found	France Trade Mark
tm.mc	http://www.nic.mc/	whois.ripe.net	No entries found	Monaco Commercial
tm.ro	http://www.rnc.ro/	whois.ripe.net	No entries found	Romania TradeMark
tm.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Trademark
tn	http://www.ati.tn/Nic/			Tunisia
to	http://www.tonic.to/	monarch.tonic.to	FULL 0	Tonga
tp	http://www.nic.tp/			East Timor
tr	http://dns.metu.edu.tr/			Turkey
tt	http://ns1.tstt.net.tt/nic/			Trinidad And Tobago
tv	http://www.nic.tv/			Tuvalu
tw	http://www.twnic.net/			Taiwan
tw.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
tz				Tanzania
ua	http://nic.ua.net/			Ukraine
ug	http://www.nic.ug/			Uganada
uk	http://www.nic.uk/			United Kingdom
uk.co	http://www.nic.uk/	whois.uk.co	No match	UK Commercial Alternative
uk.com	http://www.nic.uk/	whois.nomination.net	No match for	Alternative UK Name
uk.net	http://www.nic.uk/	whois.nomination.net	No match for	Alternative UK Name
um	http://www.isi.edu/us-domain/			US Minor Outlying Islands
us	http://www.isi.edu/in-notes/usdnr/			United States
uy	http://www.rau.edu.uy/rau/dom/			Uruguay
uz	http://www.freenet.uz/			Uzbekistan
va				Vatican City
vc				St. Vincent
ve	http://www.nic.ve/			Venezuela
vg	http://www.vg/			British Virgin Islands
vi	http://www.usvi.net/cobex/			Us Virgin Islands
vn	http://www.batin.com.vn/			Vietnam
vu				Vanuatu
web.za	http://www.frd.ac.za/uninet/zadomains.html	whois.co.za	No information available	South Africa Web
wf	http://www.nic.fr/			Wallis and Futuna Islands
ws				Samoa
www.ro	http://www.rnc.ro/	whois.ripe.net	No entries found	Romania Web
xj.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
xz.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
ye				Yemen
yk.ca	http://www.cdnnet.ca/	whois.cdnnet.ca	Not found	Canada Regional
yn.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
yt	http://www.nic.fr/Procedures/English/			Mayotte
yu	http://www.nic.yu/			Yugoslavia
za	http://www.frd.ac.za/uninet/zadomains.html			South Africa
zj.cn	http://www.cnnic.net.cn/indexeng.html	whois.cnnic.cn	No entries	China Regional
zm	http://www.zamnet.zm/			Zambia
zr	http://www.nic.zr/			Zaire
zw				Zimbabwe


