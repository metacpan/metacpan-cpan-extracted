#!/usr/bin/perl -sw 
##
## Whiplash 
##
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: Whiplash.pm,v 1.7 2007/05/08 22:22:36 rsoderberg Exp $

package Razor2::Signature::Whiplash; 

use Digest::SHA1;

sub new { 

    my ($class, %args) = @_;
    my %self = ( 
        uri_terminators => "/><\"",
        length_error    => 100,
        al_terminators  => " /><\"\r\n",
    );

    my @DPL = qw( 

        .com
        .net
        .org
        .info
        .biz
        .edu

        .gov.ar
        .int.ar
        .net.ar
        .com.ar
        .mil.ar
        .ar

        .com.au
        .org.au
        .gov.au
        .org.au
        .id.au
        .oz.au
        .info.au
        .net.au
        .asn.au
        .csiro.au
        .telememo.au
        .conf.au
        edu.au
        .au

        .com.az
        .net.az
        .org.az
        .az

        .art.br
        .com.br
        .esp.br
        .etc.br
        .g12.br
        .gov.br
        .ind.br
        .inf.br
        .mil.br
        .net.br
        .org.br
        .pro.br
        .psi.br
        .rec.br
        .tmp.br
        .br

        .ab.ca
        .bc.ca
        .gc.ca
        .mb.ca
        .nf.ca
        .ns.ca
        .nt.ca
        .on.ca
        .pe.ca
        .qc.ca
        .sk.ca
        .yk.ca
        .ca

        .ac.cn
        .com.cn
        .edu.cn
        .gov.cn
        .net.cn
        .org.cn
        .bj.cn
        .sh.cn
        .tj.cn
        .cq.cn
        .he.cn
        .sx.cn
        .nm.cn
        .ln.cn
        .jl.cn
        .hl.cn
        .js.cn
        .zj.cn
        .ah.cn
        .hb.cn
        .hn.cn
        .gd.cn
        .gx.cn
        .hi.cn
        .sc.cn
        .gz.cn
        .yn.cn
        .xz.cn
        .sn.cn
        .gs.cn
        .qh.cn
        .nx.cn
        .xj.cn
        .tw.cn
        .hk.cn
        .mo.cn
        .cn

        .arts.co
        .com.co
        .edu.co
        .firm.co
        .gov.co
        .info.co
        .int.co
        .nom.co
        .mil.co
        .org.co
        .rec.co
        .store.co
        .web.co
        .co

        .ac.cr
        .co.cr
        .ed.cr
        .fi.cr
        .go.cr
        .or.cr
        .sa.cr
        .cr

        .com.cu
        .net.cu
        .org.cu
        .cu

        .ac.cy
        .com.cy
        .gov.cy
        .net.cy
        .org.cy
        .cy

        .cz

        .de

        .com.ec
        .k12.ec
        .edu.ec
        .fin.ec
        .med.ec
        .gov.ec
        .mil.ec
        .org.ec
        .net.ec
        .ec

        .com.eg
        .edu.eg
        .eun.eg
        .gov.eg
        .net.eg
        .org.eg
        .sci.eg
        .eg

        .ac.fj
        .com.fj
        .gov.fj
        .id.fj
        .org.fj
        .school.fj
        .fj 

        .site.voila.fr
        .fr

        .com.ge
        .edu.ge
        .gov.ge
        .mil.ge
        .net.ge
        .org.ge
        .pvt.ge
        .ge

        .co.gg
        .org.gg
        .sch.gg
        .ac.gg
        .gov.gg
        .ltd.gg
        .ind.gg
        .net.gg
        .alderney.gg
        .guernsey.gg
        .sark.gg
        .gg

        .edu.gu
        .com.gu
        .mil.gu
        .gov.gu
        .net.gu
        .org.gu
        .gu 

        .com.hk
        .edu.hk
        .gov.hk
        .idv.hk
        .net.hk
        .org.hk
        .hk

        .co.hu
        .org.hu
        .priv.hu
        .info.hu
        .tm.hu
        .nui.hu
        .hu

        .ac.id
        .co.id
        .go.id
        .mil.id
        .net.id
        .or.id
        .id

        .k12.il
        .org.il
        .ac.il
        .gov.il
        .muni.il
        .co.il
        .net.il
        .il

        .co.im
        .lkd.co.im
        .plc.co.im
        .net.im
        .gov.im
        .org.im
        .nic.im
        .ac.im
        .im

        .ernet.in
        .nic.in
        .ac.in
        .co.in
        .gov.in
        .net.in
        .res.in
        .in

        .com.jo
        .gov.jo
        .edu.jo
        .net.jo
        .jo

        .co.jp
        .ne.jp
        .or.jp
        .lg.jp
        .ne.jp
        .ad.jp
        .ac.jp
        .go.jp
        .gr.jp
        .jp

        .ac.kr
        .co.kr
        .go.kr
        .ne.kr
        .or.kr
        .re.kr
        .pe.kr
        .seoul.kr
        .kyonggi.kr

        .com.la
        .net.la
        .org.la
        .la

        .com.lb
        .org.lb
        .net.lb
        .gov.lb
        .mil.lb
        .lb

        .com.lc
        .edu.lc
        .gov.lc
        .net.lc
        .org.lc
        .lc

        .com.lv
        .edu.lv
        .gov.lv
        .org.lv
        .mil.lv
        .id.lv
        .net.lv
        .asn.lv
        .conf.lv
        .lv

        .com.ly
        .net.ly
        .org.ly
        .ly

        .edu.mm
        .com.mm
        .gov.mm
        .net.mm
        .org.mm
        .mm

        .com.mo
        .edu.mo
        .gov.mo
        .net.mo
        .org.mo
        .mo

        .com.mt
        .net.mt
        .org.mt
        .mt

        .com.mx
        .net.mx
        .org.mx
        .mx

        .com.my
        .org.my
        .gov.my
        .edu.my
        .net.my
        .my

        .com.na
        .org.na
        .net.na
        .na

        .com.nc
        .net.nc
        .org.nc
        .nc

        .ne

        .nf

        .ng

        .com.ni
        .ni

        .com.np
        .net.np
        .ort.np
        .np

        .co.nz
        .net.nz
        .govt.nz
        .ac.nz
        .nz

        .ac.pa
        .com.pa
        .net.pa
        .org.pa
        .edu.pa
        .gob.pa
        .sld.pa
        .pa

        .com.pe
        .net.pe
        .org.pe
        .pe

        .com.ph
        .net.ph
        .org.ph
        .mil.ph
        .ngo.ph
        .ph

        .com.pl
        .net.pl
        .org.pl
        .pl

        .com.py
        .net.py
        .org.py
        .edu.py
        .py

        .org.ru
        .net.ru
        .pp.ru
        .com.ru
        .ru

        .com.sg
        .net.sg
        .org.sg
        .edu.sg
        .gov.sg
        .sg

        .com.sh
        .edu.sh
        .gov.sh
        .net.sh
        .mil.sh
        .org.sh
        .sh

        .co.sv
        .sv

        .com.sy
        .net.sy
        .org.sy
        .sy

        .ac.th
        .co.th
        .go.th
        .net.th
        .or.th
        .in.th
        .th

        .com.tn
        .ind.tn
        .tourism.tn
        .fin.tn
        .net.tn
        .gov.tn
        .nat.tn
        .org.tn
        .info.tn
        .ens.tn
        .intl.tn
        .rnrt.tn
        .rnu.tn
        .rns.tn
        .edunet.tn
        .tn

        .bbs.tr
        .com.tr
        .edu.tr
        .gov.tr
        .k12.tr
        .mil.tr
        .net.tr
        .org.tr
        .tr

        .com.tw
        .net.tw
        .org.tw
        .gove.tw
        .tw

        .com.ua
        .net.ua
        .gov.ua
        .ua

        .ac.ug
        .co.ug
        .or.ug
        .go.ug
        .ug

        .ac.uk
        .co.uk
        .gov.uk
        .ltd.uk
        .me.uk
        .mod.uk
        .net.uk
        .nic.uk
        .nhs.uk
        .org.uk
        .plc.uk
        .police.uk
        .sch.uk
        .uk

        .ak.us
        .al.us
        .ar.us
        .az.us
        .sf.ca.us
        .ca.us
        .co.us
        .ct.us
        .dc.us
        .de.us
        .fed.us
        .fl.us
        .ga.us
        .hi.us
        .ia.us
        .id.us
        .il.us
        .in.us
        .isa.us
        .kids.us
        .ks.us
        .ky.us
        .la.us
        .ma.us
        .md.us
        .me.us
        .mi.us
        .mn.us
        .mo.us
        .ms.us
        .mt.us
        .nc.us
        .nd.us
        .ne.us
        .nh.us
        .nj.us
        .nm.us
        .nsn.us
        .nv.us
        .ny.us
        .oh.us
        .ok.us
        .or.us
        .pa.us
        .ri.us
        .sc.us
        .sd.us
        .tn.us
        .tx.us
        .ut.us
        .vt.us
        .va.us
        .wa.us
        .wi.us
        .wv.us
        .wy.us
        .us

        .com.uy
        .edu.uy
        .net.uy
        .org.uy
        .uy

        .com.ve
        .edu.ve
        .gov.ve
        .net.ve
        .co.ve
        .bib.ve
        .tec.ve
        .int.ve
        .org.ve
        .firm.ve
        .store.ve
        .web.ve
        .arts.ve
        .rec.ve
        .info.ve
        .nom.ve
        .mil.ve
        .ve

        .co.vi
        .net.vi
        .org.vi
        .vi

        .ac.yu
        .co.yu
        .edu.yu
        .org.yu
        .yu

        .ws

        .ac.za
        .alt.za
        .co.za
        .edu.za
        .gov.za
        .mil.za
        .net.za
        .ngo.za
        .nom.za
        .org.za
        .school.za
        .tm.za
        .web.za
        .za

    );

    $self{dpl} = [@DPL];
    return bless \%self, $class;

}


sub whiplash { 

    my ($self, $text) = @_;

    # Wrap all the text in case the URL is broken up on multiple lines.

    # $text =~ s/[\r\n]//g;

    return unless $text;

    my @hosts = $self->extract_hosts($text);

    unless (scalar @hosts) { 

        # No hostnames were found in the text, 
        # return undef;

        debug("No hosts found in the message.");

        return;

    }

    # We have one or more hosts. Generate one signature for each host.

    my $length = length($text);
    my $corrected_length = $length - ($length % $$self{length_error});

    my @sigs;
    my %sig_meta;

    for my $host (@hosts) { 

        # Compute a SHA1 of host and corrected length.  The corrected length is 
        # the value of length to the nearest multiple of ``length_error''.
        # Take the first 20 hex chars from SHA1 and call it the signature.

        my $sha1 = Digest::SHA1->new();

        $sha1->add($host);
        $sig = substr $sha1->hexdigest, 0, 12;

        $sha1->add($corrected_length);
        $sig .= substr $sha1->hexdigest, 0, 4;

        push @sigs, $sig;
        $sig_meta{$sig} = [$host, $corrected_length];

        debug("$sig ($host + $corrected_length)");

    }

    return (\@sigs, \%sig_meta);

}


sub extract_hosts { 

    my ($self, $text) = @_;

    #
    # Test Vectors:
    #
    #  1. http://www.nodg.com@www.geocities.com/nxcisdsfdfdsy/off
    #  2. http://www.ksleybiuh.com@213.171.60.74/getoff/
    #  3. <http://links.verotel.com/cgi-bin/showsite.verotel?vercode=12372:9804000000374206> 
    #  4. http://217.12.4.7/rmi/http://definethis.net/526/index.html
    #  5. http://magalygr8sex.free-host.com/h.html
    #  6. http://%3CVenkatrs%3E@218.80.74.102/thecard/4index.htm
    #  7. http://EBCDVKIGURGGCEOKXHINOCANVQOIDOXJWTWGPC@218.80.74.102/thecard/5in
    #  8. http://g.india2.bag.gs/remove_page.htm
    #  9. https://220.97.40.149
    # 10. http://&#109;j&#97;k&#101;d.b&#105;z/u&#110;&#115;&#117;bscr&#105;&#98;e&#46;d&#100;d?leaving
    # 11. http://g5j99m8@it.rd.yahoo.com/bassi/*http://www.lekobas.com/c/index.php
    # 12. <a href="http://Chettxuydyhv   vwyyrcmgbxzj  n as ecq kkurxtrvaug nfsygjjjwhfkpaklh t a qsc  exinscfjtxr
    #     jobg @www.mmv9.org?affil=19">look great / feel great</a> 
    # 13. <A
    #      HREF="http://href=www.churchwomen.comhref=www.cairn.nethref=www.teeter.orghr
    #      ef=www.lefty.bizhref=wwwbehold.pitfall@www.mmstong5f.com/host/index.asp?ID=0
    #      1910?href=www.corrode.comhref=www.ode.nethref=www.clergy.orghref=www.aberrat
    #      e.biz" >
    # 14.  www.pillzthatwork.com  # anything that starts with www.
    # 

    # Decode Hex URI encoding (TV #6) (SPEC-REF: UNESCAPE)
    $text =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

    # Decode Decimal URI encoding (TV #10) (SPEC-REF: UNESCAPE)
    $text =~ s/\&\#([0-9]{2,3})\;/chr($1)/eg;

    debug("host_tokens(): will attempt to extract host names");

    my @hosts;
    my @autolinks = $text =~ m|\s+(www.[^$$self{al_terminators}]+)|ig; # Outlook with autolink these URLs
    push @hosts, @autolinks;

    #
    # We extract host portions from all HTTP/HTTPS URIs found on the text.
    # URIs are decoded if they are encoded, usernames (usually random) are
    # thrown away and all unique hosts are extracted.
    #

    if ($text =~ m|^.*?href\s*=\s*"?https?://?(.*)$|si) { 
        $text = "a href = http://$1";
    } elsif ($text =~ m|^.*?https?://?(.*)$|si) { 
        $text = "http://$1";
    } else { 
        return;
    }

    while ($host = next_host($text)) {  

        last unless $host;

        # Strip to the domain or IP 

        my $canonical_domain;
        
        if ($host =~ /^[\d\.]+$/) { 
    
            # This is an IP address, just use it.
            $canonical_domain = $host;

        } else { 

            # See if it's a non country domain.  If so, 
            # we'll extract the hostname. (SPEC-REF: NORMALIZE)

            $canonical_domain = $self->canonify($host);
   
        }

        # Ensure the hostname is not already in the list and that it is
        # potentially a routable hostname: length > 1 and contains
        # atleast one "."

        unless (grep { /^\Q$canonical_domain\E$/ } @hosts) {
            if ((length($canonical_domain) > 1) and ($canonical_domain =~ /\./)) {
                push @hosts, $canonical_domain;
            }
        }

        last unless $text =~ m"http://(.*)$";
        $text = $1;

    }

    return @hosts;
   
}


sub next_host { 

        ($_) = @_;

        my ($host, $authority);

        # Algorithm:
        # 1. Find http://
        # 2. Find [@"></]
        # 3. If found @, ignore everything before it and look for ["></]
        # 4. Everything from @ to [">/?] is the host. 
        # 5. If @ was not found, the whole thing is the host
        # 

        my $inside_href = 0;
        if (/^a href/) { 
            $inside_href = 1;
            s|^a href\s*=\s*||;
        }

        # Remove the protocol name
        s|^http://||i;

        # Find a terminator 
        if (( $inside_href and m|(.*?)[>\"\/\?\<]|s) or 
            (!$inside_href and m|(.*?)[>\"\/\?\<\n\r]|s)) {
            $_ = $1;
        }

        # Remove the authority section if the URL has one
        s/^[^@]*@//si;

        # The host name is everything after the last `='
        s/\S+=//si;
        $host = $_;
        
        # The host part cannot contains whitespace or linefeeds.
        # Everything including and beyond these characters should be
        # throw away.

        $host =~ s/[\r\n\s].*$//s;

        # />
      
        # Lowercase the hostname and remove ``='' chars (which can be part
        # of the hostname sometimes when deQP didn't work correctly.

        $host = lc($host);
        $host =~ s/=//g;   
        $host =~ s/\s*$//g;

        # Throw away the TCP port spec

        $host =~ s/:.*$//;

        # Throw away ``.'' at the end

        $host =~ s/\.$//;

        return $host;

}


sub canonify { 

    my ($self, $host) = @_;

    # Extract canonical domain name. See the section on
    # Domain Part List in the Whiplash spec for details on
    # how this works.

    for my $pattern (@{$$self{dpl}}) { 

        if ($pattern =~ /^\./) { 
            if ($host =~ /([^\.]+\Q$pattern\E)$/) { 
                return $1;
            }
        } else { 
            if ($host =~ /\Q$pattern\E$/) { 
                return $pattern;
            }
        }
    
    }

    return $host;
        
}


sub debug { 
    my $message = shift;
    # print "debug: $message\n";
}


1;

