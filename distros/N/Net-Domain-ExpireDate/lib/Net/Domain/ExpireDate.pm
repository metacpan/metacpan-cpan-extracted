package Net::Domain::ExpireDate;

use strict;
use Time::Piece;
use Net::Whois::Raw;
use Encode;
use utf8;

use constant FLG_EXPDATE => 0b0001;
use constant FLG_CREDATE => 0b0010;
use constant FLG_ALL     => 0b1111;

use constant ONE_DAY => 86_400;
use constant ONE_YEAR => 31_556_930; # 365.24225 days

our @EXPORT = qw(
    expire_date expdate_int expdate_fmt credate_fmt domain_dates domdates_fmt
    $USE_REGISTRAR_SERVERS
);

our $VERSION = '1.20';

our $USE_REGISTRAR_SERVERS;
our $CACHE_DIR;
our $CACHE_TIME;

$USE_REGISTRAR_SERVERS = 0;
# 0 - make queries to registry server
# 1 - make queries to registrar server
# 2 - make queries to registrar server and in case of fault make query to registry server

# for Net::Whois::Raw
$Net::Whois::Raw::OMIT_MSG = 2;
$Net::Whois::Raw::CHECK_FAIL = 3;

sub expire_date {
    my ( $domain, $format ) = @_;

    if ( $USE_REGISTRAR_SERVERS == 0 ) {
        return _expire_date_query( $domain, $format, 1 );
    }
    elsif ( $USE_REGISTRAR_SERVERS == 1 ) {
        return _expire_date_query( $domain, $format, 0 );
    }
    elsif ( $USE_REGISTRAR_SERVERS == 2 ) {
        return _expire_date_query( $domain, $format, 0 )
            || _expire_date_query( $domain, $format, 1 );
    }
}

sub domain_dates {
    my ( $domain, $format ) = @_;

    _config_netwhoisraw();

    return  unless $domain =~ /(.+?)\.([^.]+)$/;
    my ( $name, $tld ) = ( lc $1 , lc $2 );

    my $whois;

    if ( $USE_REGISTRAR_SERVERS == 0 ) {
        $whois = Net::Whois::Raw::whois( $domain, undef, 'QRY_FIRST' );
    }
    elsif ( $USE_REGISTRAR_SERVERS == 1 ) {
        $whois = Net::Whois::Raw::whois( $domain, undef, 'QRY_LAST' );
    }
    elsif ( $USE_REGISTRAR_SERVERS == 2 ) {
        $whois = Net::Whois::Raw::whois( $domain, undef, 'QRY_LAST'  )
              || Net::Whois::Raw::whois( $domain, undef, 'QRY_FIRST' )
    }

    return domdates_fmt( $whois, $tld, $format )  if $format;

    return domdates_int( $whois, $tld );
}

sub _expire_date_query {
    my ( $domain, $format, $via_registry ) = @_;

    _config_netwhoisraw();

    return  unless $domain =~ /(.+?)\.([^.]+)$/;
    my ( $name, $tld ) = ( lc $1, lc $2 );

    my $whois = Net::Whois::Raw::whois( $domain, undef, $via_registry ? 'QRY_FIRST' : 'QRY_LAST' );

    return expdate_fmt( $whois, $tld, $format )  if $format;

    return expdate_int( $whois, $tld );
}

sub domdates_fmt {
    my ( $whois, $tld, $format, $flags ) = @_;
    $format ||= '%Y-%m-%d';

    my ( $cre_date, $exp_date, $fre_date ) = domdates_int( $whois, $tld, $flags );

    local $^W = 0;  # prevent warnings

    $cre_date = $cre_date ? $cre_date->strftime( $format ) : '';
    $exp_date = $exp_date ? $exp_date->strftime( $format ) : '';
    $fre_date = $fre_date ? $fre_date->strftime( $format ) : '';

    return $cre_date, $exp_date, $fre_date;
}

sub expdate_fmt {
    my ( $whois, $tld, $format ) = @_;

    my ( $cre_date, $exp_date ) = domdates_fmt( $whois, $tld, $format, FLG_EXPDATE );

    return $exp_date;
}

sub credate_fmt {
    my ( $whois, $tld, $format ) = @_;

    my ( $cre_date, $exp_date ) = domdates_fmt( $whois, $tld, $format, FLG_CREDATE );

    return $cre_date;
}

sub domdates_int {
    my ( $whois, $tld, $flags ) = @_;
    $tld ||= 'com';
    $flags ||= FLG_ALL;

    if ( _isin( $tld, [ qw( ru su xn--p1ai pp.ru net.ru org.ru ) ] ) ) {
        return _dates_int_ru( $whois );
    }

    if ( $tld eq 'jp' ) {
        $whois = eval { Encode::decode( 'UTF-8', $whois ) } || $whois;
    }

    my $expdate = $flags & FLG_EXPDATE ? _expdate_int_cno( $whois ) : undef;
    my $credate = $flags & FLG_CREDATE ? _credate_int_cno( $whois ) : undef;

    return $credate, $expdate;
}

sub expdate_int {
    my ( $whois, $tld ) = @_;

    my ( $cre_date, $exp_date, $fre_date ) = domdates_int( $whois, $tld, 1 );

    return $exp_date;
}

sub decode_date {
    my ( $date, $format) = @_;
    return  unless $date;
    $format ||= '%Y-%m-%d';

    my $t = eval { Time::Piece->strptime( $date, $format ) };

    if ( $@ ) {
        warn "Can't parse date: ($date, $format)";
        return;
    }

    return $t;
}

# --- internal functions ----

sub _config_netwhoisraw {
    $Net::Whois::Raw::CACHE_DIR  = $CACHE_DIR   if $CACHE_DIR ;
    $Net::Whois::Raw::CACHE_TIME = $CACHE_TIME  if $CACHE_TIME;
}

# extract expiration date from whois output
sub _expdate_int_cno {
    my ( $whois ) = @_;
    return  unless $whois;

    # $Y - The year, including century
    # $y - The year within century (0-99)
    # $m - The month number (1-12)
    # $b - The month name
    # $d - The day of month (1-31)
    my ( $rulenum, $Y, $y, $m, $b, $d );

    # [whois.networksolutions.com]	Record expires on 27-Apr-2011.
    # [whois.opensrs.net]
    # [whois.namesdirect.com]
    # [whois.dotregistrar.com]
    # [whois.domaininfo.com]		Domain expires: 24 Oct 2010
    # [whois.ibi.net]			Record expires on........: 03-Jun-2005 EST.
    # [whois.gkg.net]			Expires on..............: 24-JAN-2003
    # [whois.enom.com]			Expiration date: 11 Jun 2005 14:22:48
    if ( $whois =~ m/\sexpir.+?:?\s+(\d{2})[- ](\w{3})[- ](\d{4})/is ) {
        $rulenum = 1.1;	$d = $1; $b = $2; $Y = $3;
    # [whois.discount-domain.com]	Expiration Date: 02-Aug-2003 22:07:21
    # [whois.publicinterestregistry.net] Expiration Date:03-Mar-2004 05:00:00 UTC
    # [whois.crsnic.net]		Expiration Date: 21-sep-2004
    # [whois.nic.uk]			Renewal Date:   23-Jan-2006
    # [whois.aero]			    Expires On:18-May-2008 01:53:51 UTC
    # [whois.nic.me]			Domain Expiration Date:28-Aug-2012 17:57:10 UTC
    # [whois.domainregistry.ie]
    } elsif ( $whois =~ m/(?:Expi\w+|Renewal) (?:Date|On):\s*(\d{2})-(\w{3})-(\d{4})/is ) {
        $rulenum = 1.2;	$d = $1; $b = $2; $Y = $3;
    # [whois.bulkregister.com]		Record expires on 2003-04-25
    # [whois.bulkregister.com]		Record will be expiring on date: 2003-04-25
    # [whois.bulkregister.com]		Record expiring on -  2003-04-25
    # [whois.bulkregister.com]		Record will expire on -  2003-04-25
    # [whois.bulkregister.com]		Record will be expiring on date: 2003-04-25
    # [whois.eastcom.com]
    # [whois.corenic.net]		Record expires:       2003-07-29 10:45:05 UTC
    # [whois.gandi.net]			expires:        2003-05-21 10:09:56
    # [whois.dotearth.com]		Record expires on:       2010-04-07 00:00:00.0 ET
    # [whois.names4ever.com]		Record expires on 2012-07-15 10:23:10.000
    # [whois.OnlineNIC.com]		Record expired on 2008/8/26
    # [whois.ascio.net]			Record expires:           2003-03-12 12:16:45
    # [whois.totalnic.net]		Record expires on 2010-04-24 16:03:20+10
    # [whois.signaturedomains.com]	Expires on: 2003-11-05
    # [whois.1stdomain.net]		Domain expires: 2007-01-20.
    # [whois.easyspace.com]
    # [whois.centralnic.com]    Expiration Date:2014-05-13T23:59:59.0Z
    } elsif ( $whois =~ m&(?:Record |Domain )?(?:will )?(?:be )?expir(?:e|ed|es|ing|ation)(?: on)?(?: date)?\s*[-:]?\s*(\d{4})[/-](\d{1,2})[/-](\d{1,2})&is ) {
        $rulenum = 2.1;	$Y = $1; $m = $2; $d = $3;
    # [whois.InternetNamesWW.com]	Expiry Date.......... 2009-06-16
    # [whois.aitdomains.com]		Expire on................ 2002-11-05 16:42:41.000
    # [whois.yesnic.com]		    Valid Date     2010-11-02 05:21:35 EST
    # [whois.enetregistry.net]		Expiration Date     : 2002-11-19 04:18:25-05
    # [whois.enterprice.net]		Date of expiration  : 2003-05-28 11:50:58
    # [nswhois.domainregistry.com]	Expires on..............: 2006-07-24
    # [whois.cira.ca]			    Renewal date:   2006/10/27
    # [whois.cira.ca]               Expiry date:           2015/12/27
    # [whois.kr]                    Expiration Date             : 2013. 03. 02.
    # [whois.nic.ir]                expire-date:   2015-05-26
    # [whois.nic.io]                Expiry : 2017-01-25
    } elsif ( $whois =~ m&(?:Expiry|Expiry Date|expire-date|Expire(?:d|s)? on|Valid[ -][Dd]ate|[Ee]xpiration [Dd]ate|Date of expiration|Renewal[- ][Dd]ate)(?:\.*|\s*):?\s+(\d{4})[/.-] ?(\d{2})[/.-] ?(\d{2})&si ) {
        $rulenum = 2.2;	$Y = $1; $m = $2; $d = $3;
    # [whois.oleane.net]		expires:        20030803
    # [whois.nic.it]			expire:      20051011
    } elsif ( $whois =~ m/expires?:\s+(\d{4})(\d{2})(\d{2})/is ) {
        $rulenum = 2.3;	$Y = $1; $m = $2; $d = $3;
    # [whois.ripe.net] .FI		expires:  1.9.2007
    # [whois.fi] .FI			expires............:  1.9.2007
    # [whois.rnids.rs]          Expiration date: 15.09.2012 11:58:33
    # [whois.dns.pt]            Expiration Date (dd/mm/yyyy): 31/12/2013
    # [whois.nic.im]            Expiry Date: 28/12/2012 00:59:59
    # [whois.isoc.org.il]       validity:     15-08-2012
    # [whois.register.bg]       expires at: 08/01/2013 00:00:00 EET
    } elsif ( $whois =~ m/(?:validity|Expiry Date|expires?(?:\.*)(?: at)?|expiration date(?: \(dd\/mm\/yyyy\))?):\s+(\d{1,2})[.\/-](\d{1,2})[.\/-](\d{4})/is ) {
        $rulenum = 2.4; $Y = $3; $m = $2; $d = $1;
    # [whois.dotster.com]		Expires on: 12-DEC-05
    # [whois for domain rosemount.com] Expires on..............: 26-Oct-15
    # [whois.godaddy.com]		Expires on: 02-Mar-16
    } elsif ( $whois =~ m/Expires on\.*: (\d{2})-(\w{3})-(\d{2})/s ) {
        $rulenum = 3;	$d = $1; $b = $2; $y = $3;
    # [whois.register.com]		Expires on..............: Tue, Aug 04, 2009
    # [whois.registrar.aol.com]	Expires on..............: Oct  5 2002 12:00AM
    # [whois.itsyourdomain.com]	Record expires on March 06, 2011
    # [whois.doregi.com]		Record expires on.......: Oct  28, 2011
    # [www.nic.ac]		        Expires : January 27 2019.
    # [whois.isnic.is]          expires:      September  5 2012
    } elsif ( $whois =~ m/(?:Record )?expires(?: on)?\.* ?:? +(?:\w{3}, )?(\w{3,9})\s{1,2}(\d{1,2}),? (\d{4})/is ) {
        $rulenum = 4.1;	$b = $1; $d = $2; $Y = $3;
    # [whois.domainpeople.com]		Expires on .............WED NOV 16 09:09:52 2011
    # [whois.e-names.org]		Expires after:   Mon Jun  9 23:59:59 2003
    # [whois.corporatedomains.com]	Created on..............: Mon, Nov 12, 2007
    } elsif ( $whois =~ m/(?:Created|Expires) (?:on|after)\s?\.*:?\s*\w{3},? (\w{3})\s{1,2}(\d{1,2})(?: \d{2}:\d{2}:\d{2})? (\d{4})?/is ) {
        $rulenum = 4.2;	$b = $1; $d = $2; $Y = $3;
    # [whois.enom.com]			Expiration date: Fri Sep 21 2012 13:45:09
    # [whois.enom.com]			Expires: Fri Sep 21 2012 13:45:09
    # [whois.neulevel.biz]		Domain Expiration Date: Fri Mar 26 23:59:59 GMT 2004
    } elsif ( $whois =~ m/(?:Domain )?(?:Expires|Expiration Date):\s+\w{3} (\w{3}) (\d{2}) (?:\d{2}:\d{2}:\d{2} \w{3}(?:[-+]\d{2}:\d{2})? )(\d{4})/is ) {
        $rulenum = 4.3; $b = $1; $d = $2; $Y = $3;
    # [rs.domainbank.net]		Record expires on 10-05-2003 11:21:25 AM
    # [whois.psi-domains.com]
    # [whois.namesecure.com]		Expires on 10-09-2011
    # [whois.catalog.com]		Record Expires on 08-24-2011
    } elsif ( $whois =~ m&expires.+?(\d{2})-(\d{2})-(\d{4})&is ) {
        $rulenum = 5.1;	$m = $1; $d = $2; $Y = $3;
    # [whois.stargateinc.com]		Expiration: 6/3/2004
    # [whois.bookmyname.com]		Expires on 11/26/2007 23:00:00
    } elsif ( $whois =~ m&(?:Expiration|Expires on):? (\d{1,2})[-/](\d{1,2})[-/](\d{4})&is ) {
        $rulenum = 5.2;	$m = $1; $d = $2; $Y = $3;
    # [whois.belizenic.bz]		Expiration Date..: 15-01-2005 12:00:00
    } elsif ( $whois =~ m&Expiration Date.+?(\d{2})-(\d{2})-(\d{4}) \d{2}:\d{2}:\d{2}&is ) {
        $rulenum = 5.3;	$d = $1; $m = $2; $Y = $3;
    # edit for .uk domains: Adam McGreggor <cpan[...]amyl.org.uk>;
    # kudos on a typo to <ganesh[...]urchin.earth.li>, via irc.mysociety.org
    # [whois.nic.uk] Registered on: 21-Oct-2003
    } elsif ( $whois =~ m&Registered on.+?(\d{2})-(\w{3})-(\d{4})&is ) {
        $rulenum = 5.4; $d = $1; $b = $2; $Y = $3;
    # [whois.nordnet.net]		Record expires on 2010-Apr-03
    # [whois.nic.nu]			Record created on 1999-Apr-5.
    # [whois.alldomains.com]		Expires on..............: 2006-Jun-12
    } elsif ( $whois =~ m/(?:Record |Domain )?expires on\.*:? (\d{4})-(\w{3})-(\d{1,2})/is ) {
        $rulenum = 6;	$Y = $1; $b = $2; $d = $3;
    # [whois.enom.com]			Expiration date: 09/21/03 13:45:09
    } elsif ( $whois =~ m|Expiration date: (\d{2})/(\d{2})/(\d{2})|s ) {
        $rulenum = 7;	$m = $1; $d = $2; $y = $3;
    } elsif ( $whois =~ m/Registered through- (\w{3}) (\w{3}) (\d{2}) (\d{4})/is ) {
        $rulenum = 7.1; $b = $2; $d = $3; $Y = $4;
    } elsif ( $whois =~ m|Expires: (\d{2})/(\d{2})/(\d{2})|is ) {
        $rulenum = 7.2;	$m = $1; $d = $2; $y = $3;
    } elsif ( $whois =~ m|Registered through- (\d{2})/(\d{2})/(\d{2})|is ) {
        $rulenum = 7.3; $m = $1; $d = $2; $y = $3;
    # [whois.jprs.jp]                   [有効期限]                      2006/12/31
    } elsif ( $whois =~ m{ \[有効期限\] \s+ ( \d{4} ) / ( \d{2} ) / ( \d{2} )}sx ) {
        $rulenum = 7.4; $Y = $1; $m = $2; $d = $3;
    }
    # [whois.ua]			status:     OK-UNTIL 20121122000000
    elsif ( $whois =~ m|status:\s+OK-UNTIL (\d{4})(\d{2})(\d{2})\d{6}|s ) {
        $rulenum = 7.5; $Y = $1; $m = $2; $d = $3;
    }
	# [whois.fi


    unless ( $rulenum ) {
        warn "Can't recognise expiration date format: $whois\n";
        return;
    }
    else {
        # warn "rulenum: $rulenum\n";
    }

    my $fstr = '';
    my $dstr = '';
    $fstr .= $Y ? '%Y ' : '%y ';
    $dstr .= $Y ? "$Y " : "$y ";

    if ( $b && length $b > 3 ) {
        $fstr .= '%B ';
    }
    elsif ( $b && length $b == 3 ) {
        $fstr .= '%b ';
    }
    else {
        $fstr .= '%m ';
    }

    $dstr .= $b ? "$b " : "$m ";

    $fstr .= '%d';
    $dstr .= $d;

    return decode_date( $dstr, $fstr );
}

# extract creation date from whois output
sub _credate_int_cno {
    my ( $whois ) = @_;
    return  unless $whois;

    # $Y - The year, including century
    # $y - The year within century (0-99)
    # $m - The month number (1-12)
    # $b - The month name
    # $d - The day of month (1-31)
    my ( $rulenum, $Y, $y, $m, $b, $d );
    # [whois.crsnic.net]		Creation Date: 06-sep-2000
    # [whois.afilias.info]		Created On:31-Jul-2001 08:42:21 UTC
    # [whois.enom.com]			Creation date: 11 Jun 2004 14:22:48
    # [whois for domain ibm.com] Record created on 19-Mar-1986.
    # [whois.nic.me]		Domain Create Date:28-Aug-2008 17:57:10 UTC
    if ( $whois =~ m/Creat(?:ion|ed On|e)[^:]*?:?\s*(\d{2})[- ](\w{3})[- ](\d{4})/is ) {
        $rulenum = 1.2;	$d = $1; $b = $2; $Y = $3;
    # [whois.nic.name]			Created On: 2002-02-08T14:56:54Z
    # [whois.worldsite.ws]		Domain created on 2002-10-29 03:54:36
    # [..cn]				Registration Date: 2003-03-19 08:06
    } elsif ( $whois =~ m/(?:Creat.+?|Registration Date):?\s*?(\d{4})[\/-](\d{1,2})[\/-](\d{1,2})/is ) {
        $rulenum = 2.1;	$Y = $1; $m = $2; $d = $3;
	# created: 16.12.2006
    # created............: 16.12.2006
	# created: 1.1.2006
     } elsif ( $whois =~ m/(?:created|registered)(?:\.*):\s+(\d{1,2})[-.](\d{1,2})[-.](\d{4})/is ) {
         $rulenum = 2.2;        $Y = $3; $m = $2; $d = $1;
    # [whois.org.ru] created: 2006.12.16
    } elsif ( $whois =~ m/(?:created|registered):\s+(\d{4})[-.](\d{2})[-.](\d{2})/is ) {
        $rulenum = 2.3;	$Y = $1; $m = $2; $d = $3;
    # [whois.nic.it]			created:     20000421
    } elsif ( $whois =~ m/created?:\s+(\d{4})(\d{2})(\d{2})/is ) {
        $rulenum = 2.4;	$Y = $1; $m = $2; $d = $3;
    # [whois.relcom.net]		changed:      support@webnames.ru 20030815
    } elsif ( $whois =~ m/changed:.+?(\d{4})(\d{2})(\d{2})/is ) {
        $rulenum = 2.5;	$Y = $1; $m = $2; $d = $3;
    # [whois.tv]			Record created on Feb 21 2001.
    } elsif ( $whois =~ m/Creat.+?:?\s*(?:\w{3}, )?(\w{3,9})\s{1,2}(\d{1,2}),? (\d{4})/is ) {
        $rulenum = 4.1;	$b = $1; $d = $2; $Y = $3;
    # [whois.dns.be]			Registered:  Wed Jan 17 2001
    } elsif ( $whois =~ m/Regist.+?:\s*\w{3} (\w{3})\s+(\d{1,2}) (?:\d{2}:\d{2}:\d{2} )?(\d{4})/is ) {
        $rulenum = 4.2;	$b = $1; $d = $2; $Y = $3;
    # [whois.whois.neulevel.biz]	Domain Registration Date: Wed Mar 27 00:01:00 GMT 2002
    } elsif ( $whois =~ m/Registration.*?:\s+\w{3} (\w{3}) (\d{2}) (?:\d{2}:\d{2}:\d{2} \w{3}(?:[-+]\d{2}:\d{2})? )?(\d{4})/is ) {
        $rulenum = 4.3; $b = $1; $d = $2; $Y = $3;
    } elsif ( $whois =~ m&created.+?(\d{2})-(\d{2})-(\d{4})&is ) {
        $rulenum = 5.1;	$m = $1; $d = $2; $Y = $3;
    # [whois.belizenic.bz]		Creation Date....: 15-01-2003 05:00:00
    } elsif ( $whois =~ m&Creation Date.+?(\d{2})-(\d{2})-(\d{4}) \d{2}:\d{2}:\d{2}&is ) {
        $rulenum = 5.3;	$d = $1; $m = $2; $Y = $3;
    # [whois.jprs.jp]                   [登録年月日]                    2001/04/23
    } elsif ( $whois =~ m{ \[登録年月日\] \s+ ( \d{4} ) / ( \d{2} ) / ( \d{2} ) }sx ) {
        $rulenum = 7.4; $Y = $1; $m = $2; $d = $3;
    # [whois.ua]			created:    0-UANIC 20050104013013
    } elsif ( $whois =~ m|created:\s+0-UANIC (\d{4})(\d{2})(\d{2})\d{6}|s ) {
        $rulenum = 7.5; $Y = $1; $m = $2; $d = $3;
    } else {
        warn "Can't recognise creation date format\n";
        return;
    }

    my $fstr = '';
    my $dstr = '';
    $fstr .= $Y ? '%Y ' : '%y ';
    $dstr .= $Y ? "$Y " : "$y ";

    if ( $b && length $b > 3 ) {
        $fstr .= '%B ';
    }
    elsif ( $b && length $b == 3 ) {
        $fstr .= '%b ';
    }
    else {
        $fstr .= '%m ';
    }

    $dstr .= $b ? "$b " : "$m ";

    $fstr .= '%d';
    $dstr .= $d;

    return decode_date( $dstr, $fstr );
}

# extract creation/expiration dates from whois output for .ru, .su, .pp.ru, .net.ru, .org.ru, .рф domains
sub _dates_int_ru {
    my ( $whois ) = @_;
    return  unless $whois;

    my ( $reg_till, $free_date, $created );

    $reg_till  = $1  if $whois =~ /reg-till:\s*(.+?)\n/s     ;
    $reg_till  = $1  if $whois =~ /payed-till:\s*(.+?)\n/s   ;
    $reg_till  = $1  if $whois =~ /paid-till:\s*(.+?)\n/s    ;
    $free_date = $1  if $whois =~ /free-date:\s*(.+?)\n/s    ;
    $created   = $1  if $whois =~ /created:\s+(.+?)\n/s  ;
    $reg_till  = $1  if $whois =~ /Delegated till\s*(.+?)\n/s;

    my $format = '%Y-%m-%dT%H:%M:%SZ';
    # OLD format date
    if (
        $created && $created     =~ /\./
          ||
        $reg_till && $reg_till   =~ /\./
          ||
        $free_date && $free_date =~ /\./
    ) {

      $format = '%Y-%m-%d';

      $reg_till  =~ tr/./-/  if $reg_till;
      $free_date =~ tr/./-/  if $free_date;
      $created   =~ tr/./-/  if $created;
    }

    if ( $created ) {
        # Guess reg-till date
        $created = decode_date( $created, $format );

        my $t = $created;

        if ( $t && !$reg_till && !$free_date ) {
            $t += 0;
            while ( $t < localtime() ) {
                $t += ONE_YEAR + ( $t->is_leap_year() ? 1 : 0 );
            }
            $reg_till = $t->strftime( $format );
        }
    }

    unless ( $reg_till || $free_date ) {
        warn "Can't obtain expiration date from ($reg_till)\n";
        return;
    }

    $reg_till  = decode_date( $reg_till,  $format );
    $free_date = decode_date( $free_date, '%Y-%m-%d' );

    if ( !$reg_till && $free_date ) {
        $reg_till = $free_date - 33 * ONE_DAY;
    }

    return $created, $reg_till, $free_date;
}

sub _isin {
    my ( $val, $arr ) = @_;
    return 0  unless $arr;

    for ( @$arr ) {
        return 1  if $_ eq $val;
    }

    return 0;
}

sub import {
    my $mypkg = shift;
    my $callpkg = caller;

    no strict 'refs';

    # export subs
    *{ "$callpkg\::$_" } = \&{ "$mypkg\::$_" }  for @EXPORT, @_;
}


1;
__END__

=head1 NAME

Net::Domain::ExpireDate -- obtain expiration date of domain names

=head1 SYNOPSIS

 use Net::Domain::ExpireDate;

 $expiration_obj = expire_date( 'microsoft.com' );
 $expiration_str  = expire_date( 'microsoft.com', '%Y-%m-%d' );
 $expiration_obj = expdate_int( $whois_text, 'com' );
 $expiration_str  = expdate_fmt( $whois_text, 'ru', '%Y-%m-%d' );

 ($creation_obj, $expiration_obj) = domain_dates( 'microsoft.com' );
 ($creation_str, $expiration_str) = domain_dates( 'microsoft.com', '%Y-%m-%d' );
 ($creation_obj, $expiration_obj) = domdates_int( $whois_text, 'com' );

=head1 ABSTRACT

Net::Domain::ExpireDate gets WHOIS information of given domain using
Net::Whois::Raw and tries to obtain expiration date of domain.
Unfortunately there are too many different whois servers which provides
whois info in very different formats.
Net::Domain::ExpireDate knows more than 40 different formats of
expiration date representation provided by different servers (almost
all gTLD registrars and some ccTLD registrars are covered).
Now obtaining of domain creation date is also supported.

"$date" in synopsis is an object of type L<Time::Piece>.

=head1 FUNCTIONS

=over 4

=item expire_date( DOMAIN [,FORMAT] )

Returns expiration date of C<DOMAIN>.
Without C<FORMAT> argument returns L<Time::Piece> object.
With C<FORMAT> argument returns date formatted using C<FORMAT> template.
See L<strftime> man page for C<FORMAT> specification.

=item expdate_int( WHOISTEXT [,TLD] )

Extracts expiration date of domain in TLD from C<WHOISTEXT>.
If no TLD is given 'com' is the default. There is no
distinction between 'com' or 'net' TLDs in this function.
Also 'org', 'biz', 'cz', 'info', 'us', 'uk', 'ru' and 'su' TLDs are supported.
Returns L<Time::Piece> object.

With C<FORMAT> argument returns date formatted using C<FORMAT> template
(see L<strftime> man page for C<FORMAT> specification)

=item expdate_fmt( WHOISTEXT [,TLD [,FORMAT]]  )

Similar to expdate_int except that output value is formatted date.
If no C<FORMAT> specified, '%Y-%m-%d' is assumed.
See L<strftime> man page for C<FORMAT> specification.

=item domain_dates( DOMAIN [,FORMAT] )

Returns list of two values -- creation and expiration date of C<DOMAIN>.
Without C<FORMAT> argument returns L<Time::Piece> objects.
With C<FORMAT> argument dates are formatted using C<FORMAT> template.
See L<strftime> man page for C<FORMAT> specification.

=item domdates_int( WHOISTEXT [,TLD [,FLAGS]] )

Returns list of three values -- creation, expiration and
free date of domain extracted from C<WHOISTEXT>.
If no TLD is given 'com' is the default. There is no
distinction between 'com' or 'net' TLDs in this function.
Also 'org', 'biz', 'cz', 'info', 'us', 'ru' and 'su' TLDs are supported.
Returns L<Time::Piece> object.

=item domdates_fmt( WHOISTEXT [,TLD [,FORMAT [,FLAGS]]] )

The same as domdates_int, except it returns formatted results
instead of Time::Piece objects.


=back

=head1 AUTHOR

Walery Studennikov, <despair@cpan.org>

=head1 SEE ALSO

L<Net::Whois::Raw>, L<Time::Piece>.

=cut
