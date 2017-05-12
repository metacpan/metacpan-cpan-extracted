From POPmail Thu Aug 31 17:19:55 2000
Return-Path: <xwhois-devel-admin@lists.sourceforge.net>
Envelope-To: mail@vipul.net
Delivery-Date: Fri, 01 Sep 2000 02:36:07 +0530
Received: from mail1.sourceforge.net ([198.186.203.35]
    helo=lists.sourceforge.net) by krypton.netropolis.org with esmtp (Exim
    3.12 #1 (Debian)) id 13UbXC-00029Y-00 for <mail@vipul.net>; Fri,
    01 Sep 2000 02:36:06 +0530
Received: from mail1.sourceforge.net (localhost [127.0.0.1]) by
    lists.sourceforge.net (8.9.3/8.9.3) with ESMTP id KAA17978; Thu,
    31 Aug 2000 10:09:46 -0700
Received: from core.pavilion.net (core.pavilion.net [212.74.0.24]) by
    lists.sourceforge.net (8.9.3/8.9.3) with ESMTP id JAA16807 for
    <xwhois-devel@lists.sourceforge.net>; Thu, 31 Aug 2000 09:55:23 -0700
Received: (from matt@localhost) by core.pavilion.net (8.9.3/8.8.8) id
    RAA21712; Thu, 31 Aug 2000 17:55:11 +0100 (BST) (envelope-from matt)
Date: Thu, 31 Aug 2000 17:55:11 +0100
From: Matt Spiers <matt@pavilion.net>
To: Robert Chalmers <robert@chalmers.com.au>
Cc: xwhois-devel@lists.sourceforge.net
Subject: Re: [Xwhois-devel] ... RE: Registrant problem
Message-Id: <20000831175511.D99042@pavilion.net>
References: <20000830155354.P19357@pavilion.net>
    <006c01c012da$48048480$1a6001cb@chalmers.com.au>
Mime-Version: 1.0
Content-Type: text/plain; charset=us-ascii
X-Mailer: Mutt 1.0i
In-Reply-To: <006c01c012da$48048480$1a6001cb@chalmers.com.au>;
    from robert@chalmers.com.au on Thu, Aug 31, 2000 at 09:30:28AM +1000
X-NCC-Regid: uk.pavilion
Sender: xwhois-devel-admin@lists.sourceforge.net
Errors-To: xwhois-devel-admin@lists.sourceforge.net
X-Beenthere: xwhois-devel@lists.sourceforge.net
X-Mailman-Version: 2.0beta5
Precedence: bulk
List-Id: <xwhois-devel.lists.sourceforge.net>
Status: RO
Content-Length: 3085
Lines: 94

> 
> In the examples/whois example...
> 
> if ( $opts{r} ) { my @emails = $whois->registrant; $" = ", "; print
> "Registrants: @emails\n";  exit }
> 
> 
> This line has the word registrants, (plural) it should be 'registrant'
> singular.
> 
> It then works fine.
> 
> Bob

In the XWhois module the RIPE parser definition has 'registrants'
rather than 'registrant' as well. 

Below is what I've knocked up so far.  I notice that at present
all parser definitions in the XWhois module conform to the INTERNIC
so these don't fit in with that format.  All .uk domains have a
tag holder, which represents who has authority to alter the record
(see http://www.nic.uk/ref/tags.html).  As the .uk whois do not
include any contact info I guess this should be set as contact_tech.
Also the list @centralnic_tlds is only a small subset of what they offer.


Matt.
	-----------------------------------------

my @nominet_tlds = ("co.uk","org.uk","ltd.uk","plc.uk","net.uk",
		    "sch.uk","nhs.uk","police.uk", "mod.uk") ;
my @ukerna_tlds =  ("ac.uk", "gov.uk");
my @centralnic_tlds = ("uk.com", "eu.com", "gb.com", "uk.net", "gb.net");


my $w = new Net::XWhois;  
$w->register_cache ( undef );


$w->register_association (
	'whois.nic.uk' => ["NOMINET", [ @nominet_tlds ] ],
	'whois.ja.net' => ["UKERNA", [ @ukerna_tlds ] ],
	'whois.centralnic.com' => ["CENTRALNIC", [ @centralnic_tlds ] ],
);


$w->register_parser (
	Name => "NOMINET",
	Parser => {
		name => 'omain Name:\s+(\S+)',
		registrant => 'egistered For:\s*(.*?)\n',
		ips_tag => 'omain Registered By:\s*(.*?)\n',
		record_updated_date => 'Record last updated on\s*(.*?)\s+',
		record_updated_by => 'Record last updated on\s*.*?\s+by\s+(.*?)\n',
		nameservers => 'listed in order:[\s\n]+(\S+)\s.*?\n\s+(\S*?)\s.*?\n\s*\n',
		whois_updated => 'database last updated at\s*(.*?)\n',
	},
	 
);
$w->register_parser (
        Name => "CENTRALNIC",
        Parser => {
                name => 'omain Name:\s+(\S+)',
                registrant => 'egistrant:\s*(.*?)\n',
		contact_admin => 'lient Contact:\s*(.*?)\n\s*\n',
		contact_billing => 'illing Contact:\s*(.*?)\n\s*\n',
		contact_tech => 'echnical Contact:\s*(.*?)\n\s*\n',
		record_created_date => 'ecord created on\s*(.*?)\n',
		record_paid_date => 'ecord paid up to\s*(.*?)\n',
		record_updated_date => 'ecord last updated on\s*(.*?)\n',
		nameservers => 'listed in order:[\s\n]+(\S+)\s.*?\n\s+(\S*?)\s.*?\n\s*\n',
        },

);
$w->register_parser (
        Name => "UKERNA",
        Parser => {
                name => 'omain Name:\s+(\S+)',
                registrant => 'egistered For:\s*(.*?)\n',
		ips_tag => 'omain Registered By:\s*(.*?)\n',
		record_updated_date => 'ecord updated on\s*(.*?)\s+',
		record_updated_by => 'ecord updated on\s*.*?\s+by\s+(.*?)\n',
		nameservers => 'elegated Name Servers:[\s\n]+(\S+)[\s\n]+(\S+).*?\n\s*\n',
		domain_contact => 'Domain contact:\s*(.*?)\n',
        }
);



_______________________________________________
Xwhois-devel mailing list
Xwhois-devel@lists.sourceforge.net
http://lists.sourceforge.net/mailman/listinfo/xwhois-devel


