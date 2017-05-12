From POPmail Tue Sep  5 00:25:13 2000
Return-Path: <xwhois-devel-admin@lists.sourceforge.net>
Envelope-To: mail@vipul.net
Delivery-Date: Tue, 05 Sep 2000 09:22:08 +0530
Received: from mail1.sourceforge.net ([198.186.203.35]
    helo=lists.sourceforge.net) by krypton.netropolis.org with esmtp (Exim
    3.12 #1 (Debian)) id 13W9mK-0003Ml-00 for <mail@vipul.net>; Tue,
    05 Sep 2000 09:22:08 +0530
Received: from mail1.sourceforge.net (localhost [127.0.0.1]) by
    lists.sourceforge.net (8.9.3/8.9.3) with ESMTP id QAA11911; Mon,
    4 Sep 2000 16:56:02 -0700
Received: from munitions2.xs4all.nl (root@munitions2.xs4all.nl
    [194.109.217.74]) by lists.sourceforge.net (8.9.3/8.9.3) with ESMTP id
    QAA11896 for <xwhois-devel@lists.sourceforge.net>; Mon, 4 Sep 2000
    16:55:27 -0700
Date: Tue, 5 Sep 2000 05:31:39 +0530
From: Vipul Ved Prakash <mail@vipul.net>
To: xwhois-devel@lists.sourceforge.net
Message-Id: <20000905053139.B13603@fountainhead.vipul.net>
Reply-To: mail@vipul.net
Mime-Version: 1.0
Content-Type: text/plain; charset=us-ascii
X-Mailer: Mutt 1.0i
X-Operating-System: Linux fountainhead.vipul.net 2.2.16
X-PGP-Fingerprint: D5F78D9FC694A45A00AE086062498922
Subject: [Xwhois-devel] [jong@larva.jong.org: Net::XWhois extension for ARIN]
Sender: xwhois-devel-admin@lists.sourceforge.net
Errors-To: xwhois-devel-admin@lists.sourceforge.net
X-Beenthere: xwhois-devel@lists.sourceforge.net
X-Mailman-Version: 2.0beta5
Precedence: bulk
List-Id: <xwhois-devel.lists.sourceforge.net>
Status: RO
Content-Length: 2286
Lines: 73

This will go in next release as well. 

best,
vipul.

----- Forwarded message from Jon Gilbert <jong@larva.jong.org> -----

Envelope-To: mail@vipul.net
Delivery-Date: Tue, 05 Sep 2000 08:59:58 +0530
Date: Mon, 4 Sep 2000 16:33:14 -0700
To: mail@vipul.net
Subject: Net::XWhois extension for ARIN
User-Agent: Mutt/1.2i
From: Jon Gilbert <jong@larva.jong.org>

Greetings, 

I'm not sure if you're still supporting the 
Net::XWhois module for perl5, but if so, 
here's a %PARSER and %ASSOC addition for 
a whois type of ARIN.  It's not the most 
efficent parser set (but it works and I'm 
not really complaining).

Anyway, if you're needing more associations, 
here's one that I've found very useful.  

Thanks for the module.

jong.


my $w = Net::XWhois->new;
$w->register_parser(Name => 'ARIN',
    Retain => 1,
    Parser => {
        netname => 'etname:\s*(\S+)\n+',
        netblock => 'etblock:\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3} - \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})[\n\s]*',
        netnumber => 'Netnumber:\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})[\n\s]*',
        hostname => 'Hostname:\s*(\S+)[\n\s]*',
        maintainer => 'Maintainer:\s*(\S+)',
        record_update => 'Record last updated on (\S+)\.\n+',
        database_update => 'Database last updated on (.+)\.[\n\s]+The',
        registrant => '^(.*?)\n\n',
        reverse_mapping => 'Domain System inverse[\s\w]+:[\n\s]+(.*?)\n\n',
        coordinator => 'Coordinator:[\n\s]+(.*?)\n\n',
        coordinator_handle =>'Coordinator:[\n\s]+[^\(\)]+\((\S+?)\)',
        address => 'Address:\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})',
        system => 'System:\s+([^\n]*)\n',
        non_portable => 'ADDRESSES WITHIN THIS BLOCK ARE NON-PORTABLE',
        },
);
$w->register_association('arin.net' => [ ARIN, [ qw/*/]]);

$w->lookup(Domain => '198.95.251.10',
    Format => 'ARIN',
    Server => 'arin.net');


----- End forwarded message -----

-- 

VIPUL VED PRAKASH               |  Cryptography
mail@vipul.net                  |  Distributed Systems
http://www.vipul.net            |  Network Agents
91 11 2233328                   |  Perl Hacking

_______________________________________________
Xwhois-devel mailing list
Xwhois-devel@lists.sourceforge.net
http://lists.sourceforge.net/mailman/listinfo/xwhois-devel


