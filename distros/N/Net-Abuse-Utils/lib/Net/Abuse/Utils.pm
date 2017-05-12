package Net::Abuse::Utils;
# ABSTRACT: Routines useful for processing network abuse

use 5.006;
use strict;
use warnings;

use Net::DNS;
use Net::Whois::IP 1.11 'whoisip_query';
use Email::Address;
use Net::IP;
# use Memoize;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    get_asn_info get_peer_info get_as_description get_soa_contact get_ipwi_contacts
    get_rdns get_dnsbl_listing get_ip_country get_asn_country
    get_abusenet_contact is_ip get_as_company get_domain get_malware
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = '0.25';
$VERSION = eval $VERSION;

# memoize('_return_rr');
my @tlds;
our @RESOLVERS;

sub _reverse_ip {
    my $ip = shift;
    my $ver = Net::IP::ip_get_version($ip);
    my @parts = split( /\./, Net::IP::ip_reverse( $ip, $ver == 4 ? 32 : 128 ) );
    # strip in-addr.arp or ip6.arpa from results
    return join('.', @parts[0 .. $#parts-2]);
}

sub _return_rr {
    my $lookup  = shift;
    my $rr_type = shift;
    my $concat  = shift;

    my @result;

    my $res = Net::DNS::Resolver->new(  );
    $res->nameservers(@RESOLVERS) if @RESOLVERS;

    my $query = $res->query($lookup, $rr_type);
    if ($query) {
            foreach my $rr ($query->answer) {
                if ($rr->type eq $rr_type) {
                    if    ($rr_type eq 'TXT') {
                        push @result, $rr->txtdata;
                    }
                    elsif ($rr_type eq 'SOA') {
                        push @result, $rr->rname;
                    }
                    elsif ($rr_type eq 'PTR') {
                        push @result, $rr->ptrdname;
                    }
                    last if !$concat;
                }
            }

            if ($concat && $concat == 2) {
                return @result;
            }
            else {
                return join ' ', @result;
            }
    }

    return;
}

sub _return_unique {
    my $array_ref = shift;
    my %unique_elements;

    foreach my $element (@$array_ref) {
        $unique_elements{ $element }++;
    }

    return keys %unique_elements;
}

sub _strip_whitespace {
    my $string = shift;

    return unless $string;

    for ($string) {
        s/^\s+//;
        s/\s+$//;
    }

    return $string;
}

sub get_ipwi_contacts {
    my $ip = shift;
    my $ver = Net::IP::ip_get_version($ip);
    return unless $ver;

    my @addresses;
    my %unique_addresses;

    # work-around for the new way arin works
    # it doesn't like networks very well.
    my @bits = split(/\//,$ip);
    $ip = $bits[0] if($#bits > 0);

    my $response = whoisip_query($ip);

    # whoisip_query returns array ref if not found
    return unless ref($response) eq 'HASH';

    foreach my $field (keys %$response) {
        push @addresses, Email::Address->parse($response->{$field});
    }

    @addresses = map { $_->address } @addresses;

    return _return_unique (\@addresses);
}

sub get_all_asn_info {
    my $ip = shift;
    my $ver = Net::IP::ip_get_version($ip);
    return unless $ver;

    my $domain
        = ( $ver == 4 ) ? '.origin.asn.cymru.com' : '.origin6.asn.cymru.com';

    my $lookup = _reverse_ip($ip) . $domain;
    my $data = [ _return_rr( $lookup, 'TXT', 2 ) ] or return;

    # Separate fields and order by netmask length
    # 23028 | 216.90.108.0/24 | US | arin | 1998-09-25
    # 701 1239 3549 3561 7132 | 216.90.108.0/24 | US | arin | 1998-09-25
    for my $asinfo (@$data) {
        $asinfo = { data => [ split m/ \| /, $asinfo ] };
        $asinfo->{length} = ( split m|/|, $asinfo->{data}[1] )[1];
    }
    $data = [ map { $_->{data} }
            reverse sort { $a->{length} <=> $b->{length} } @$data ];

    return $data;
}

sub get_asn_info {
    my $data = get_all_asn_info(shift);
    return unless $data && @$data;

    # just the first AS if multiple ASes are listed
    if ($data->[0][0] =~ /^(\d+) \d+/) {
        $data->[0][0] = $1;
    }

    # return just the first result, as a list
    return @{ $data->[0] };
}

sub get_peer_info {
    my $ip = shift;

    # IPv4 only until Cymru has an IPv6 peer database
    my $ver = Net::IP::ip_get_version($ip);
    return unless $ver && $ver == 4;

    my $lookup    = _reverse_ip($ip) . '.peer.asn.cymru.com';
    my @origin_as = _return_rr($lookup, 'TXT', 2) or return;

    my $return = [];
    foreach my $as (@origin_as){
        my @peers = split(/\s\|\s?/,$as);
        my %hash = (
            prefix  => $peers[1],
            cc      => $peers[2],
            rir     => $peers[3],
            date    => $peers[4],
        );
        my @asns = split(/\s/,$peers[0]);
        foreach (@asns){
            $hash{'asn'} = $_;
            push(@$return,{
                prefix  => $peers[1],
                cc      => $peers[2],
                rir     => $peers[3],
                date    => $peers[4],
                asn     => $_,
            });
        }
    }
    return(@$return) if wantarray;
    return($return);
}

# test with 733a48a9cb49651d72fe824ca91e8d00
# http://www.team-cymru.org/Services/MHR/

sub get_malware {
    my $hash = shift;
    return unless($hash && lc($hash) =~ /^[a-z0-9]{32}$/);

    my $lookup = $hash.'.malware.hash.cymru.com';

    my $res = _return_rr($lookup, 'TXT') or return;
    my ($last_seen,$detection_rate) = split(/ /,$res);
    return({
        last_seen   => $last_seen,
        detection_rate  => $detection_rate,
    });
}

sub get_as_description {
    my $asn = shift;
    my @ASdata;

    if ( my $data = _return_rr( "AS${asn}.asn.cymru.com", 'TXT' ) ) {
        @ASdata = split( '\|', $data );
    }
    else {
        return;
    }

    return unless $ASdata[4];
    my $org = _strip_whitespace( $ASdata[4] );

    # for arin we get "HANDLE - AS Org"
    # we want to make it "HANDLE AS Org" to match other RIRs
    $org =~ s/^(\S+) - (.*)$/$1 $2/ if ( $ASdata[2] eq ' arin ' );

    return $org;
}

sub get_as_company {
    my $asn = shift;

    my $desc = get_as_description($asn);
    return unless defined($desc);

    # remove leading org id/handle/etc
    $desc =~ s/^[-_A-Z0-9]+ //;

    # remove trailing 'AS'
    $desc =~ s/AS(:? Number)?$//;

    # remove trailing 'Autonomous System'
    $desc =~ s/Autonomous System(:? Number)?$//i;

    return $desc;
}

sub get_soa_contact {
    my $ip = shift;

    my $lookup = _reverse_ip($ip) . '.in-addr.arpa';
    $lookup =~ s/^\d+\.//;

    if ( my $soa_contact = _return_rr($lookup, 'SOA') ) {
        $soa_contact =~ s/\./@/ unless $soa_contact =~ m/@/;
        return $soa_contact;
    }

    return;
}

sub get_rdns {
    my $ip = shift;
    my $ver = Net::IP::ip_get_version($ip);
    return unless $ver;

    my $suffix = ($ver == 4) ? '.in-addr.arpa' : '.ip6.arpa';
    return _return_rr( _reverse_ip($ip) . $suffix, 'PTR');
}

sub get_dnsbl_listing {
    my ($ip, $dnsbl) = @_;

    # IPv4 Only
    my $ver = Net::IP::ip_get_version($ip);
    return unless $ver && $ver == 4;

    my $lookup = join '.', _reverse_ip( $ip ), $dnsbl;

    return _return_rr($lookup, 'TXT', 1);
}

sub get_ip_country {
     my $ip = shift;
     return (get_asn_info($ip))[2];
}

sub get_asn_country {
    my $asn   = shift;
    return unless $asn =~ /^\d+$/;

    my $as_cc = (split (/\|/,_return_rr("AS${asn}.asn.cymru.com", 'TXT')))[1];
    if ($as_cc) {
        return _strip_whitespace($as_cc);
    }
    return;
}

sub get_abusenet_contact {
    my $domain = shift;
    return _return_rr("$domain.contacts.abuse.net", 'TXT', 1)
}

sub is_ip {
    my $ip = shift;
    return defined Net::IP::ip_get_version($ip);
}

sub get_domain {
    my $hostname = shift;

    @tlds = grep {!/^#/} <DATA> unless scalar @tlds;
    my @parts = reverse (split /\./, $hostname);

    if (scalar @parts == 2) {
        # just two parts, lets return it
        return join '.', @parts[1, 0];
    }
    if (grep /^\Q$parts[1].$parts[0]\E$/, @tlds) {
        #  last two parts found in tlds
        return join '.', @parts[2, 1, 0];
    } else {
        # last two not found so *host.domain.name
        return join '.', @parts[1, 0];
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Net::Abuse::Utils - Routines useful for processing network abuse

=head1 VERSION

version 0.25

=head1 SYNOPSIS

    use Net::Abuse::Utils qw( :all );
    print "IP Whois Contacts: ", join( ' ', get_ipwi_contacts($ip) ), "\n";
    print "Abuse.net Contacts: ", get_abusenet_contact($domain), "\n";

=head1 DESCRIPTION

Net::Abuse::Utils provides serveral functions useful for determining
information about an IP address including contact/reporting addresses,
ASN/network info, reverse dns, and DNSBL listing status.  Functions which take
an IP accept either IPv6 or IPv4 IPs unless indicated otherwise.

=head1 NAME

Net::Abuse::Utils - Routines useful for processing network abuse

=head1 VERSION

version 0.24

=head1 CONFIGURATION

There is a C<@RESOLVERS> package variable you can use to specify name servers
different than the systems nameservers for queries from this module.  If you
intend to use Google's nameservers here, please see L<This issue on GitHub for
a note of caution|https://github.com/mikegrb/Net-Abuse-Utils/issues/9#issuecomment-24387435>.

=head1 FUNCTIONS

The following functions are exportable from this module.  You may import all
of them into your namespace with the C<:all> tag.

=head2 get_asn_info ( IP )

Returns a list containing (ASN, Network/Mask, CC code, RIR, modified date)
for the network announcing C<IP>.

=head2 get_all_asn_info ( IP )

Returns a reference to a list of listrefs containting ASN(s), Network,Mask,
CC code, RIR, and modified date fall all networks announcing C<IP>.

=head2 get_peer_info ( IP )

IPv4 Only. Returns an array of hash references containing (ASN, Network/Mask,
CC code, RIR, modified date) for the peers of the network announcing C<IP>.

=head2 get_as_description ( ASN )

Returns the AS description for C<ASN>.

=head2 get_as_company ( ASN )

Similiar to C<get_as_description> but attempts to clean it up some before
returning it.

=head2 get_soa_contact( IP )

Returns the SOA contact email address for the reverse DNS /24
zone containing C<IP>.

=head2 get_ipwi_contacts( IP )

Returns a list of all email addresses found in whois information
for C<IP> with duplicates removed.

=head2 get_rdns( IP )

Returns the reverse PTR for C<IP>.

=head2 get_dnsbl_listing( IP, DNSBL zone )

IPv4 Only. Returns the listing text for C<IP> for the designated DNSBL.
C<DNSBL zone> should be the zone used for looking up addresses in the
blocking list.

=head2 get_ip_country( IP )

Returns the 2 letter country code for C<IP>.

=head2 get_asn_country( ASN )

Returns the 2 letter country code for C<ASN>.

=head2 get_abusenet_contact ( domain )

Returns the abuse.net listed contact email addresses for C<domain>.

=head2 is_ip ( IP )

Returns true if C<IP> looks like an IP, false otherwise.

=head2 get_domain ( IP )

Takes a hostname and attempts to return the domain name.

=head2 get_malware ( md5 )

Takes a malware md5 hash and tests it against
http://www.team-cymru.org/Services/MHR. Returns a HASHREF of last_seen and
detection_rate.

=head1 DIAGNOSTICS

Each subroutine will return undef if unsuccessful.  In the furture,
debugging output will be available.

=head1 CONFIGURATION AND ENVIRONMENT

There are two commented out lines that can be uncommented to enable Memoize
support.  I haven't yet decided whether to include this option by default.  It
may be made available in the future via an import flag to use.

=head1 DEPENDENCIES

This module makes use of the following modules:

L<Net::IP>, L<Net::DNS>, L<Net::Whois::IP>, and L<Email::Address>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Michael Greb (mgreb@linode.com)

Patches are welcome.

=head1 ACKNOWLEDGEMENTS

This module was inspired by Karsten M. Self's SpamTools shell scripts,
available at http://linuxmafia.com/~karsten/.

Thanks as well to my employer, Linode.com, for allowing me the time to work
on this module.

Rik Rose, Jon Honeycutt, Brandon Hale, TJ Fontaine, A. Pagaltzis, and
Heidi Greb all provided invaluable input during the development of this
module.

=head1 SEE ALSO

For a detailed usage example, please see examples/ip-info.pl included in
this module's distribution.

=head1 AUTHORS

=over 4

=item *

mikegrb <michael@thegrebs.com>

=item *

Wes Young <github@barely3am.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mike Greb.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHORS

=over 4

=item *

mikegrb <michael@thegrebs.com>

=item *

Wes Young <github@barely3am.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by =over 4.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHORS

=over 4

=item *

mikegrb <michael@thegrebs.com>

=item *

Wes Young <github@barely3am.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by =over 4.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# from http://spamcheck.freeapp.net/two-level-tlds
# a source for more current/kept up to date data would be greatly
# appreciated
2000.hu
ab.ca
ab.se
abo.pa
ac.ae
ac.am
ac.at
ac.bd
ac.be
ac.cn
ac.com
ac.cr
ac.cy
ac.fj
ac.fk
ac.gg
ac.gn
ac.hu
ac.id
ac.il
ac.im
ac.in
ac.ir
ac.je
ac.jp
ac.ke
ac.kr
ac.lk
ac.ma
ac.mw
ac.ng
ac.nz
ac.om
ac.pa
ac.pg
ac.rs
ac.ru
ac.rw
ac.se
ac.th
ac.tj
ac.tz
ac.ug
ac.uk
ac.vn
ac.yu
ac.za
ac.zm
ac.zw
act.au
ad.jp
adm.br
adult.ht
adv.br
adygeya.ru
aero.mv
aero.tt
aeroport.fr
agr.br
agrar.hu
agro.pl
ah.cn
aichi.jp
aid.pl
ak.us
akita.jp
al.us
aland.fi
alderney.gg
alt.na
alt.za
altai.ru
am.br
amur.ru
amursk.ru
aomori.jp
ar.us
arkhangelsk.ru
army.mil
arq.br
art.br
art.do
art.dz
art.ht
art.pl
arts.co
arts.ro
arts.ve
asn.au
asn.lv
ass.dz
assedic.fr
assn.lk
asso.dz
asso.fr
asso.gp
asso.ht
asso.mc
asso.re
astrakhan.ru
at.tf
at.tt
atm.pl
ato.br
au.com
au.tt
auto.pl
av.tr
avocat.fr
avoues.fr
az.us
baikal.ru
barreau.fr
bashkiria.ru
bbs.tr
bc.ca
bd.se
be.tt
bel.tr
belgie.be
belgorod.ru
bg.tf
bialystok.pl
bib.ve
bio.br
bir.ru
biz.az
biz.bh
biz.cy
biz.et
biz.fj
biz.ly
biz.mv
biz.nr
biz.om
biz.pk
biz.pl
biz.pr
biz.tj
biz.tr
biz.tt
biz.vn
bj.cn
bl.uk
bmd.br
bolt.hu
bourse.za
br.com
brand.se
british-library.uk
bryansk.ru
buryatia.ru
busan.kr
c.se
ca.tf
ca.tt
ca.us
casino.hu
cbg.ru
cc.bh
cci.fr
ch.tf
ch.vu
chambagri.fr
chel.ru
chelyabinsk.ru
cherkassy.ua
chernigov.ua
chernovtsy.ua
chiba.jp
chirurgiens-dentistes.fr
chita.ru
chukotka.ru
chungbuk.kr
chungnam.kr
chuvashia.ru
cim.br
city.hu
city.za
ck.ua
club.tw
cmw.ru
cn.com
cn.ua
cng.br
cnt.br
co.ae
co.ag
co.am
co.ao
co.at
co.ba
co.bw
co.ck
co.cr
co.dk
co.ee
co.fk
co.gg
co.hu
co.id
co.il
co.im
co.in
co.ir
co.je
co.jp
co.ke
co.kr
co.ls
co.ma
co.mu
co.mw
co.mz
co.nz
co.om
co.rs
co.rw
co.st
co.th
co.tj
co.tt
co.tv
co.tz
co.ua
co.ug
co.uk
co.us
co.uz
co.ve
co.vi
co.yu
co.za
co.zm
co.zw
com.ac
com.ae
com.af
com.ag
com.ai
com.al
com.am
com.an
com.ar
com.au
com.aw
com.az
com.ba
com.bb
com.bd
com.bh
com.bm
com.bn
com.bo
com.br
com.bs
com.bt
com.bz
com.cd
com.ch
com.cn
com.co
com.cu
com.cy
com.dm
com.do
com.dz
com.ec
com.ee
com.eg
com.er
com.es
com.et
com.fj
com.fk
com.fr
com.ge
com.gh
com.gi
com.gn
com.gp
com.gr
com.gt
com.gu
com.hk
com.hn
com.hr
com.ht
com.io
com.jm
com.jo
com.kg
com.kh
com.ki
com.kw
com.ky
com.kz
com.la
com.lb
com.lc
com.li
com.lk
com.lr
com.lv
com.ly
com.mg
com.mk
com.mm
com.mn
com.mo
com.mt
com.mu
com.mv
com.mw
com.mx
com.my
com.na
com.nc
com.nf
com.ng
com.ni
com.np
com.nr
com.om
com.pa
com.pe
com.pf
com.pg
com.ph
com.pk
com.pl
com.pr
com.ps
com.pt
com.py
com.qa
com.re
com.ro
com.ru
com.rw
com.sa
com.sb
com.sc
com.sd
com.sg
com.sh
com.st
com.sv
com.sy
com.tj
com.tn
com.tr
com.tt
com.tw
com.ua
com.uy
com.uz
com.vc
com.ve
com.vi
com.vn
com.vu
com.ws
com.ye
conf.au
conf.lv
consulado.st
coop.br
coop.ht
coop.mv
coop.mw
coop.tt
cpa.pro
cq.cn
cri.nz
crimea.ua
csiro.au
ct.us
cul.na
cv.ua
cz.tf
d.se
daegu.kr
daejeon.kr
dagestan.ru
dc.us
de.com
de.net
de.tf
de.tt
de.us
de.vu
dk.org
dk.tt
dn.ua
dnepropetrovsk.ua
dni.us
dns.be
donetsk.ua
dp.ua
dpn.br
dr.tr
dudinka.ru
e-burg.ru
e.se
e164.arpa
ebiz.tw
ecn.br
ed.ao
ed.cr
ed.jp
edu.ac
edu.af
edu.ai
edu.al
edu.am
edu.an
edu.ar
edu.au
edu.az
edu.ba
edu.bb
edu.bd
edu.bh
edu.bm
edu.bn
edu.bo
edu.br
edu.bt
edu.ck
edu.cn
edu.co
edu.cu
edu.dm
edu.do
edu.dz
edu.ec
edu.ee
edu.eg
edu.er
edu.es
edu.et
edu.ge
edu.gh
edu.gi
edu.gp
edu.gr
edu.gt
edu.gu
edu.hk
edu.hn
edu.ht
edu.hu
edu.in
edu.it
edu.jm
edu.jo
edu.kg
edu.kh
edu.kw
edu.ky
edu.kz
edu.lb
edu.lc
edu.lk
edu.lr
edu.lv
edu.ly
edu.mg
edu.mm
edu.mn
edu.mo
edu.mt
edu.mv
edu.mw
edu.mx
edu.my
edu.na
edu.ng
edu.ni
edu.np
edu.nr
edu.om
edu.pa
edu.pe
edu.pf
edu.ph
edu.pk
edu.pl
edu.pr
edu.ps
edu.pt
edu.py
edu.qa
edu.rs
edu.ru
edu.rw
edu.sa
edu.sb
edu.sc
edu.sd
edu.sg
edu.sh
edu.sk
edu.st
edu.sv
edu.tf
edu.tj
edu.tr
edu.tt
edu.tw
edu.ua
edu.uk
edu.uy
edu.ve
edu.vi
edu.vn
edu.vu
edu.ws
edu.ye
edu.yu
edu.za
edunet.tn
ehime.jp
ekloges.cy
embaixada.st
eng.br
ens.tn
ernet.in
erotica.hu
erotika.hu
es.kr
es.tt
esp.br
etc.br
eti.br
eu.com
eu.org
eu.tf
eu.tt
eun.eg
experts-comptables.fr
f.se
fam.pk
far.br
fareast.ru
fax.nr
fed.us
fgov.be
fh.se
fhs.no
fhsk.se
fhv.se
fi.cr
fie.ee
film.hu
fin.ec
fin.tn
firm.co
firm.ht
firm.in
firm.ro
firm.ve
fj.cn
fl.us
fm.br
fnd.br
folkebibl.no
forum.hu
fot.br
fr.tt
fr.vu
from.hr
fst.br
fukui.jp
fukuoka.jp
fukushima.jp
fylkesbibl.no
g.se
g12.br
ga.us
game.tw
games.hu
gangwon.kr
gb.com
gb.net
gc.ca
gd.cn
gda.pl
gdansk.pl
geek.nz
gen.in
gen.nz
gen.tr
geometre-expert.fr
ggf.br
gifu.jp
gmina.pl
go.cr
go.id
go.jp
go.ke
go.kr
go.th
go.tj
go.tz
go.ug
gob.bo
gob.do
gob.es
gob.gt
gob.hn
gob.mx
gob.ni
gob.pa
gob.pe
gob.pk
gob.sv
gok.pk
gon.pk
gop.pk
gos.pk
gouv.fr
gouv.ht
gouv.rw
gov.ac
gov.ae
gov.af
gov.ai
gov.al
gov.am
gov.ar
gov.au
gov.az
gov.ba
gov.bb
gov.bd
gov.bf
gov.bh
gov.bm
gov.bo
gov.br
gov.bt
gov.by
gov.ch
gov.ck
gov.cn
gov.co
gov.cu
gov.cx
gov.cy
gov.dm
gov.do
gov.dz
gov.ec
gov.eg
gov.er
gov.et
gov.fj
gov.fk
gov.ge
gov.gg
gov.gh
gov.gi
gov.gn
gov.gr
gov.gu
gov.hk
gov.hu
gov.ie
gov.il
gov.im
gov.in
gov.io
gov.ir
gov.it
gov.je
gov.jm
gov.jo
gov.jp
gov.kg
gov.kh
gov.kw
gov.ky
gov.kz
gov.lb
gov.lc
gov.li
gov.lk
gov.lr
gov.lt
gov.lu
gov.lv
gov.ly
gov.ma
gov.mg
gov.mm
gov.mn
gov.mo
gov.mt
gov.mv
gov.mw
gov.my
gov.ng
gov.np
gov.nr
gov.om
gov.ph
gov.pk
gov.pl
gov.pr
gov.ps
gov.pt
gov.py
gov.qa
gov.rs
gov.ru
gov.rw
gov.sa
gov.sb
gov.sc
gov.sd
gov.sg
gov.sh
gov.sk
gov.st
gov.sy
gov.tj
gov.tn
gov.to
gov.tp
gov.tr
gov.tt
gov.tv
gov.tw
gov.ua
gov.uk
gov.ve
gov.vi
gov.vn
gov.ws
gov.ye
gov.za
gov.zm
gov.zw
govt.nz
gr.jp
greta.fr
grozny.ru
grp.lk
gs.cn
gsm.pl
gub.uy
guernsey.gg
gunma.jp
gv.ao
gv.at
gwangju.kr
gx.cn
gyeongbuk.kr
gyeonggi.kr
gyeongnam.kr
gz.cn
h.se
ha.cn
hb.cn
he.cn
health.vn
herad.no
hi.cn
hi.us
hiroshima.jp
hk.cn
hl.cn
hn.cn
hokkaido.jp
hotel.hu
hotel.lk
hs.kr
hu.com
huissier-justice.fr
hyogo.jp
i.se
ia.us
ibaraki.jp
icnet.uk
id.au
id.fj
id.ir
id.lv
id.ly
id.us
idf.il
idn.sg
idrett.no
idv.hk
idv.tw
if.ua
il.us
imb.br
in-addr.arpa
in.rs
in.th
in.ua
in.us
incheon.kr
ind.br
ind.er
ind.gg
ind.gt
ind.in
ind.je
ind.tn
inf.br
inf.cu
info.au
info.az
info.bh
info.co
info.cu
info.cy
info.ec
info.et
info.fj
info.ht
info.hu
info.mv
info.nr
info.pl
info.pr
info.ro
info.sd
info.tn
info.tr
info.tt
info.ve
info.vn
ing.pa
ingatlan.hu
inima.al
int.am
int.ar
int.az
int.bo
int.co
int.lk
int.mv
int.mw
int.pt
int.ru
int.rw
int.tf
int.tj
int.tt
int.ve
int.vn
intl.tn
ip6.arpa
iris.arpa
irkutsk.ru
isa.us
ishikawa.jp
isla.pr
it.ao
it.tt
ivano-frankivsk.ua
ivanovo.ru
iwate.jp
iwi.nz
iz.hr
izhevsk.ru
jamal.ru
jar.ru
jeju.kr
jeonbuk.kr
jeonnam.kr
jersey.je
jet.uk
jl.cn
jobs.tt
jogasz.hu
jor.br
joshkar-ola.ru
js.cn
jx.cn
k-uralsk.ru
k.se
k12.ec
k12.il
k12.tr
kagawa.jp
kagoshima.jp
kalmykia.ru
kaluga.ru
kamchatka.ru
kanagawa.jp
kanazawa.jp
karelia.ru
katowice.pl
kawasaki.jp
kazan.ru
kchr.ru
kemerovo.ru
kg.kr
kh.ua
khabarovsk.ru
khakassia.ru
kharkov.ua
kherson.ua
khmelnitskiy.ua
khv.ru
kids.us
kiev.ua
kirov.ru
kirovograd.ua
kitakyushu.jp
km.ua
kms.ru
kobe.jp
kochi.jp
koenig.ru
komforb.se
komi.ru
kommunalforbund.se
kommune.no
komvux.se
konyvelo.hu
kostroma.ru
kr.ua
krakow.pl
krasnoyarsk.ru
ks.ua
ks.us
kuban.ru
kumamoto.jp
kurgan.ru
kursk.ru
kustanai.ru
kuzbass.ru
kv.ua
ky.us
kyonggi.kr
kyoto.jp
la.us
lakas.hu
lanarb.se
lanbib.se
law.pro
law.za
lel.br
lg.jp
lg.ua
lipetsk.ru
lkd.co.im
ln.cn
lodz.pl
ltd.co.im
ltd.cy
ltd.gg
ltd.gi
ltd.je
ltd.lk
ltd.uk
lublin.pl
lugansk.ua
lutsk.ua
lviv.ua
m.se
ma.us
magadan.ru
magnitka.ru
mail.pl
maori.nz
mari-el.ru
mari.ru
marine.ru
mat.br
matsuyama.jp
mb.ca
md.us
me.uk
me.us
med.br
med.ec
med.ee
med.ht
med.ly
med.om
med.pa
med.pro
med.sa
med.sd
medecin.fr
media.hu
media.pl
mi.th
mi.us
miasta.pl
mie.jp
mil.ac
mil.ae
mil.am
mil.ar
mil.az
mil.ba
mil.bd
mil.bo
mil.br
mil.by
mil.co
mil.do
mil.ec
mil.eg
mil.er
mil.fj
mil.ge
mil.gh
mil.gt
mil.gu
mil.hn
mil.id
mil.in
mil.io
mil.jo
mil.kg
mil.kh
mil.kr
mil.kw
mil.kz
mil.lb
mil.lt
mil.lu
mil.lv
mil.mg
mil.mv
mil.my
mil.no
mil.np
mil.nz
mil.om
mil.pe
mil.ph
mil.pl
mil.ru
mil.rw
mil.se
mil.sh
mil.sk
mil.st
mil.tj
mil.tr
mil.tw
mil.uk
mil.uy
mil.ve
mil.ye
mil.za
miyagi.jp
miyazaki.jp
mk.ua
mn.us
mo.cn
mo.us
mob.nr
mobi.tt
mobil.nr
mobile.nr
mod.gi
mod.om
mod.uk
mordovia.ru
mosreg.ru
ms.kr
ms.us
msk.ru
mt.us
muni.il
murmansk.ru
mus.br
museum.mn
museum.mv
museum.mw
museum.no
museum.om
museum.tt
music.mobi
mytis.ru
n.se
nagano.jp
nagasaki.jp
nagoya.jp
nakhodka.ru
nalchik.ru
name.ae
name.az
name.cy
name.et
name.fj
name.hr
name.mv
name.my
name.pr
name.tj
name.tr
name.tt
name.vn
nara.jp
nat.tn
national-library-scotland.uk
naturbruksgymn.se
navy.mil
nb.ca
nc.us
nd.us
ne.jp
ne.ke
ne.kr
ne.tz
ne.ug
ne.us
nel.uk
net.ac
net.ae
net.af
net.ag
net.ai
net.al
net.am
net.an
net.ar
net.au
net.az
net.ba
net.bb
net.bd
net.bh
net.bm
net.bn
net.bo
net.br
net.bs
net.bt
net.bz
net.cd
net.ch
net.ck
net.cn
net.co
net.cu
net.cy
net.dm
net.do
net.dz
net.ec
net.eg
net.er
net.et
net.fj
net.fk
net.ge
net.gg
net.gn
net.gp
net.gr
net.gt
net.gu
net.hk
net.hn
net.ht
net.id
net.il
net.im
net.in
net.io
net.ir
net.je
net.jm
net.jo
net.jp
net.kg
net.kh
net.ki
net.kw
net.ky
net.kz
net.la
net.lb
net.lc
net.li
net.lk
net.lr
net.lu
net.lv
net.ly
net.ma
net.mm
net.mo
net.mt
net.mu
net.mv
net.mw
net.mx
net.my
net.na
net.nc
net.nf
net.ng
net.ni
net.np
net.nr
net.nz
net.om
net.pa
net.pe
net.pg
net.ph
net.pk
net.pl
net.pr
net.ps
net.pt
net.py
net.qa
net.ru
net.rw
net.sa
net.sb
net.sc
net.sd
net.sg
net.sh
net.st
net.sy
net.tf
net.th
net.tj
net.tn
net.tr
net.tt
net.tw
net.ua
net.uk
net.uy
net.uz
net.vc
net.ve
net.vi
net.vn
net.vu
net.ws
net.ye
net.za
new.ke
news.hu
nf.ca
ngo.lk
ngo.ph
ngo.pl
ngo.za
nh.us
nhs.uk
nic.im
nic.in
nic.tt
nic.uk
nieruchomosci.pl
niigata.jp
nikolaev.ua
nj.us
nkz.ru
nl.ca
nls.uk
nm.cn
nm.us
nnov.ru
no.com
nom.ad
nom.ag
nom.br
nom.co
nom.es
nom.fk
nom.fr
nom.mg
nom.ni
nom.pa
nom.pe
nom.pl
nom.re
nom.ro
nom.ve
nom.za
nome.pt
norilsk.ru
not.br
notaires.fr
nov.ru
novosibirsk.ru
ns.ca
nsk.ru
nsn.us
nsw.au
nt.au
nt.ca
nt.ro
ntr.br
nu.ca
nui.hu
nv.us
nx.cn
ny.us
o.se
od.ua
odessa.ua
odo.br
off.ai
og.ao
oh.us
oita.jp
ok.us
okayama.jp
okinawa.jp
olsztyn.pl
omsk.ru
on.ca
opole.pl
or.at
or.cr
or.id
or.jp
or.ke
or.kr
or.th
or.tz
or.ug
or.us
orenburg.ru
org.ac
org.ae
org.ag
org.ai
org.al
org.am
org.an
org.ar
org.au
org.az
org.ba
org.bb
org.bd
org.bh
org.bm
org.bn
org.bo
org.br
org.bs
org.bt
org.bw
org.bz
org.cd
org.ch
org.ck
org.cn
org.co
org.cu
org.cy
org.dm
org.do
org.dz
org.ec
org.ee
org.eg
org.er
org.es
org.et
org.fj
org.fk
org.ge
org.gg
org.gh
org.gi
org.gn
org.gp
org.gr
org.gt
org.gu
org.hk
org.hn
org.ht
org.hu
org.il
org.im
org.in
org.io
org.ir
org.je
org.jm
org.jo
org.jp
org.kg
org.kh
org.ki
org.kw
org.ky
org.kz
org.la
org.lb
org.lc
org.li
org.lk
org.lr
org.ls
org.lu
org.lv
org.ly
org.ma
org.mg
org.mk
org.mm
org.mn
org.mo
org.mt
org.mu
org.mv
org.mw
org.mx
org.my
org.na
org.nc
org.ng
org.ni
org.np
org.nr
org.nz
org.om
org.pa
org.pe
org.pf
org.ph
org.pk
org.pl
org.pr
org.ps
org.pt
org.py
org.qa
org.ro
org.rs
org.ru
org.sa
org.sb
org.sc
org.sd
org.se
org.sg
org.sh
org.st
org.sv
org.sy
org.tj
org.tn
org.tr
org.tt
org.tw
org.ua
org.uk
org.uy
org.uz
org.vc
org.ve
org.vi
org.vn
org.vu
org.ws
org.ye
org.yu
org.za
org.zm
org.zw
oryol.ru
osaka.jp
oskol.ru
otc.au
oz.au
pa.us
palana.ru
parliament.cy
parliament.uk
parti.se
pb.ao
pc.pl
pe.ca
pe.kr
penza.ru
per.kh
per.sg
perm.ru
perso.ht
pharmacien.fr
pl.tf
pl.ua
plc.co.im
plc.ly
plc.uk
plo.ps
pol.dz
pol.ht
pol.tr
police.uk
poltava.ua
port.fr
powiat.pl
poznan.pl
pp.az
pp.ru
pp.se
ppg.br
prd.fr
prd.mg
press.cy
press.ma
press.se
presse.fr
pri.ee
principe.st
priv.at
priv.hu
priv.no
priv.pl
pro.ae
pro.br
pro.cy
pro.ec
pro.fj
pro.ht
pro.mv
pro.om
pro.pr
pro.tt
pro.vn
psc.br
psi.br
pskov.ru
ptz.ru
pub.sa
publ.pt
pvt.ge
pyatigorsk.ru
qc.ca
qc.com
qh.cn
qld.au
qsl.br
re.kr
realestate.pl
rec.br
rec.co
rec.ro
rec.ve
red.sv
reklam.hu
rel.ht
rel.pl
res.in
ri.us
rnd.ru
rnrt.tn
rns.tn
rnu.tn
rovno.ua
rs.ba
ru.com
ru.tf
rubtsovsk.ru
rv.ua
ryazan.ru
s.se
sa.au
sa.com
sa.cr
saga.jp
saitama.jp
sakhalin.ru
samara.ru
saotome.st
sapporo.jp
saratov.ru
sark.gg
sc.cn
sc.ke
sc.kr
sc.ug
sc.us
sch.ae
sch.gg
sch.id
sch.ir
sch.je
sch.lk
sch.ly
sch.ng
sch.om
sch.sa
sch.sd
sch.uk
sch.zm
school.fj
school.nz
school.za
sci.eg
sd.cn
sd.us
se.com
se.tt
sebastopol.ua
sec.ps
sendai.jp
seoul.kr
sex.hu
sex.pl
sg.tf
sh.cn
shiga.jp
shimane.jp
shizuoka.jp
shop.ht
shop.hu
shop.pl
simbirsk.ru
sk.ca
sklep.pl
sld.do
sld.pa
slg.br
slupsk.pl
smolensk.ru
sn.cn
snz.ru
soc.lk
soros.al
sos.pl
spb.ru
sport.hu
srv.br
sshn.se
stat.no
stavropol.ru
store.co
store.ro
store.st
store.ve
stv.ru
suli.hu
sumy.ua
surgut.ru
sx.cn
syzran.ru
szczecin.pl
szex.hu
szkola.pl
t.se
takamatsu.jp
tambov.ru
targi.pl
tas.au
tatarstan.ru
te.ua
tec.ve
tel.no
tel.nr
tel.tr
telecom.na
telememo.au
ternopil.ua
test.ru
tirana.al
tj.cn
tld.am
tlf.nr
tm.cy
tm.fr
tm.hu
tm.mc
tm.mg
tm.mt
tm.pl
tm.ro
tm.se
tm.za
tmp.br
tn.us
tochigi.jp
tokushima.jp
tokyo.jp
tom.ru
tomsk.ru
torun.pl
tottori.jp
tourism.pl
tourism.tn
toyama.jp
tozsde.hu
travel.pl
travel.tt
trd.br
tsaritsyn.ru
tsk.ru
tula.ru
tur.br
turystyka.pl
tuva.ru
tv.bo
tv.br
tv.sd
tver.ru
tw.cn
tx.us
tyumen.ru
u.se
udm.ru
udmurtia.ru
uk.com
uk.net
uk.tt
ulan-ude.ru
ulsan.kr
unam.na
unbi.ba
uniti.al
unsa.ba
upt.al
uri.arpa
urn.arpa
us.com
us.tf
us.tt
ut.us
utazas.hu
utsunomiya.jp
uu.mt
uy.com
uzhgorod.ua
va.us
vatican.va
vdonsk.ru
vet.br
veterinaire.fr
vgs.no
vic.au
video.hu
vinnica.ua
vladikavkaz.ru
vladimir.ru
vladivostok.ru
vn.ua
volgograd.ru
vologda.ru
voronezh.ru
vrn.ru
vt.us
vyatka.ru
w.se
wa.au
wa.us
wakayama.jp
warszawa.pl
waw.pl
weather.mobi
web.co
web.do
web.id
web.lk
web.pk
web.tj
web.tr
web.ve
web.za
wi.us
wroc.pl
wroclaw.pl
wv.us
www.ro
wy.us
x.se
xj.cn
xz.cn
y.se
yakutia.ru
yamagata.jp
yamaguchi.jp
yamal.ru
yamanashi.jp
yaroslavl.ru
yekaterinburg.ru
yk.ca
yn.cn
yokohama.jp
yuzhno-sakhalinsk.ru
z.se
za.com
za.pl
zaporizhzhe.ua
zgora.pl
zgrad.ru
zhitomir.ua
zj.cn
zlg.br
zp.ua
zt.ua
