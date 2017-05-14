#!/usr/bin/perl -w
# Copyright (c) 2007 celmorlauren limited. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.

package Sendmail::M4::Mail8;
require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
use strict;

@ISA    = qw(Exporter);
@EXPORT = ();
$VERSION= 0.33;

use Sendmail::M4::Utils;

=head1 NAME

Sendmail::M4::Mail8 - Stop fake MX and most spammers, sendmail M4 hack file

=head1 STATUS

Version 0.33 (Beta)
    
Now running at B<mail.celmorlauren.com> our own mail server, and has been doing so since 0.23

=head1 SYNOPSIS

SPAM consitutes the bulk of e-mail on the internet, many methods exist to fight this scurge, some better than others. However we think that this module is the simplest, quickest and most efective, relying as it does on the basic power of B<sendmail> macros for most of its methods.

=head2 METHOD OF PROTECTION

=over 4

=item 1

=over 4

=item Local_check_relay

=over 4

=item {GoodRelay}

Local system, local private IP address, contained in B<w>, B<{VirtHost}>, B<R>, B<mail1.db> and B<mail2.db>. 

Generally exempted from tests, except for B<From:> and B<Reply-to:>

=item {BadRelay}

External system, that fails one or more tests, and you want to receive mail from, these must be contained by B<mail4.db>

Generally exempted from tests, except for B<Received:>

=item {Refused}

External systems that are not allowed to send e-mail.

=over 4

Currently requires additional Perl helpers that are not included in the CPAN distribution.

For basic protection use the standard sendmail B<access> database.

=back

=back

=item Local_check_mail

=over 4

=item *

Only {GoodRely} may have a B<f> domain-name part that is local to this system.

=item *

{Bounce} B<f> of E<lt>E<gt>, only permitted on {Paranoid} values of 3 or less.

=item *

All hosts B<s>|(HELO), apart from {GoodRelay} and {BadRelay}, must

=over 4

=item *

Not pretend to be one of our domains or a local private IP address.

=item *

Must either be the same as {client_name} or resolve to be the same as {client_addr}.

=item *

B<f>|(FROM:) domains names containing B<yahoo> or B<hotmail> may only come from MX systems containing these names, also the B<Reply-to:> must either not exist or not differ.

=item *

Not contain more than 2 parts of their {client_addr} IP address encoded within their domain name,
or be overly numeric.

This traps the bulk of B<zombie> spammers. 

Traps pessimists like B<hotmail> as well, as they use very numeric MX mail relays. As I do not know of anyone who uses B<hotmail>, nothing this end will be done about it. It is upto <hotmail> to have confidence in the mail they are relaying, and hence use clearer MX domain names.

=back

=back

=back

=item 2

=over 4

=item Local_check_rcpt

=over 4

=item {Bounce}

{Bounce} delt with depending on {Paranoid}, many are B<callback verify> requests an unhelpfull sudo bounce that some other anti-spam systems have adopted.

A level of 3 says OK to anything (even domains not hosted here)! Systems that waste our time with dubious rubbish like B<callback verify> deserve to get rubbish back.

=item *

B<mail3> trouble ticket, one shot e-mail allowed from web-site will be delt with here.

=back

=back

=item 3

=over 4

=item check_data

Only with {Paranoid} of 0 will any {Bounce} with data be accepted!

=back

=item 4

=over 4

=item screen_header

=over 4

=item From:

Must be the same as b<f>, much SPAM uses a From: of yahoo or hotmail or some other mail address in a attempt to evade the B<local_check_mail> tests. Also as only {BadRelay} is exempted it traps your own users who are trying to send out as someone else, or perhaps has become a B<zombie>.

=item Reply-to:

Not permitted for yahoo or hotmail domains, otherwise must be the same domain as B<f>

=item Received:

=over 4

=item by

Detection of B<fake> headers, spammers often included faked headers perporting to come from one of your own domains.

=item with HTTP

Web-mail is so insecure and open to abuse by spammers, that with a {Paranoid} setting of 2 and above it will be refused.


=back

=back

=back

=back

=head2 GENERAL

=over 4

As all systems have an IP address and most have some sought of domain-name, it is possible to base the protection on wether the IP ties up with whom they claim to be at the <helo> stage. You can set B<sendmail> to be picky about this. But many peoples IP address does not resolve to what they would like, its easy to setup domain to IP via people like B<network solutions>, but the other way round needs a friendy ISP. 
So as this is a common problem, base the protection on the B<helo> resolving to their IP.

Next check that their domain does not contain their IP encoded somehow, people who are not real MXs tend to have numeric user addresses, this has tuning to control how strict this is.

Keep a record of whom the system has sent mail to, so that we have a chance of spotting spammers using fake bounces to fill up a users email box, at the most paranoid this refuses all bounces. That causes some problems with some systems who use fake bounces to check wether you are an MX, some even come from a completly different domain to the one being talked to at the time!??! Stupid or what?

Next check that the B<From> address is not pretending to be one of your own hosted domains, ie the IP is external and is not known to you as an outside user.

After that noraml B<sendmail> DB files will do the rest, use the B<cookbook>, all you need to know is there.

Sendmail::M4::Utils does most of the work for this module, all this does is format the B<rule>s and supply a default name for the hack. Various tuning methods exist, and of course you can add your own B<rule>s to this.


This module is non OO, and exports the methods descriped under EXPORTS.

=head1 AUTHOR

Ian McNulty, celmorlauren limited (registered in England & Wales 5418604). 

email E<lt>development@celmorlauren.comE<gt>

=head1 USES

 Sendmail::M4::Utils    the module created to make testing this easier

=head1 EXPORTS

=cut

=head2 HASH REF = mail8_setup(@_)   Sendmail::M4::Utils::setup HASH REF

=over 4

This configures this module, and is allways required first.

Expected/Allowed values allways as a (hash value pairing), see C<Sendmail::M4::Utils> for hash=>value pairings it expects, the list bellow are either default values or additional for use by this.

    file    SCALAR with default value of "mail8-stop-fake-mx.m4",
    build   SCALAR with default value of 1
    install SCALAR with default value of 1
    test    SCALAR with default value of 1

    paranoid
            SCALAR see heading below for values

=over 12

=over 4

=item 0 

not paranoid at all, has local users and is content to accept bounces and "callback verify" sudo bounces.

Standard sendmail rules and databases will handle user and bounce requests.
This just verifys that the sending host appears to be legimate.
Assuming that the hit rate on the system is not too great, use sendmail "milters" as well to take care of "spam" and "viruses"

=item 1 

slightly paranoid, has local users and is content to accept "callback verify" sudo bounces, but will refuse any bounce request that really is a bounce, that is a bounce with data.

=item 2

mildly paranoid, is a relay host with no local users, will say OK to all "callback verify" requests that refer to hosted domains, regardless of wether the user exits or not!
Refuses all real bounces.

=item 3

paranoid, is a hassled relay host, will just say OK to any "callback verify" request, regardless of wether it relays for that domain or not! Refuses all real bounces.

=item 4

fairly paranoid, is a really hasseled relay host, and has no time for any type of bounce, all refused. Most e-mail and even more bounces are bogus.

=back

=back


=cut
push @EXPORT, "mail8_setup";
my $mail8_setup;
sub mail8_setup
{
    $mail8_setup = setup   file=>"mail8-stop-fake-mx.m4", 
                           build=>1, 
                           install=>1, 
                           test=>1, 
                           @_;
# decalare items to be used with packed maceo {MashFound} this is a "long names" conservation method
# one name instead of many, but no more than 8
    define_MashFound qw(RelayChecked GoodRelay BadRelay Refused AlreadyRefused Bounce RestrictedHost, RestrictedUser);
    return $mail8_setup;
}


=head2 copyright(@_)

=over 4

copyright message to list at the start of the B<hack>, anything supplied will replace the first two lines below.

Copyright (c) 2007 celmorlauren Limited England
Author: Ian McNulty       <development\@celmorlauren.com>

this should live in /usr/share/sendmail/hack/

some settings that are advised
  FEATURE(`access_db',	`hash -TE<lt>TMPFE<gt> -o /etc/mail/access.db')
  FEATURE(`greet_pause',	`2000')
  define(`confPRIVACY_FLAGS', `goaway')

=back

=cut
push @EXPORT, "copyright";
sub copyright
{
    my @cr = (scalar @_)
        ?(@_)
        :(  "Copyright (c) 2007 celmorlauren Limited England",
            "Author: Ian McNulty       <development\@celmorlauren.com>");
    dnl @cr, <<DNL;

this should live in /usr/share/sendmail/hack/

some settings that are advised
  FEATURE(`access_db',	`hash -T<TMPF> -o /etc/mail/access.db')
  FEATURE(`greet_pause',	`2000')
  define(`confPRIVACY_FLAGS', `goaway')
DNL

}

=head2 version_id

=over 4

This is really a reminder to use B<VERSIONID> with your own value, or just use this to use the default

VERSIONID "ANTI SPAM & FAKE MX"

=back

=cut
push @EXPORT, "version_id";
sub version_id
{
    VERSIONID "ANTI SPAM & FAKE MX";
}

=head2 local_config

=over 4

Required statement, this inserts required statements into the hack file.

This inserts required statements before and after B<LOCAL_CONFIG>, you may add more statements that belong here.

Main items
    "-"                 added to confOPERATORS
    KRlookup            for DNS check on HELO host name
    H*: $>+ScreenHeader to check received headers
    KMath arith         to join the IP address together into a single token
    KCleanFrom regex    to enable checking of Header line "From:"

    KZombie program  /etc/mail/mail8/mail8_zombie
                        this is included in the script regardless 
                        of wether it is installed or not.
                        Included as part of the distro, install it
                        to get the full benifits.

    dnl white list      no other way to to let these past
    Kmail4db hash -o -a.FOUND /etc/mail/mail8/mail4.db

    Standard black list, checked at Reply-to: Header
    dnl standard black list
    Kstdaccessdb hash -o -a.FOUND /etc/mail/access.db

=back

=cut
push @EXPORT, "local_config";
sub local_config
{
    dnl <<DNL;

SPAM checking additions --------------------------
'-' added to trap DSL faked domain names

DNL
    echo <<ECHO;
define(`confOPERATORS',`.:@!^/[]-')
ECHO

    LOCAL_CONFIG;

    echo <<ECHO;
KRlookup dns -RA -a.FOUND -d5s -r4
KMath arith
KCleanFrom regex  -s1 ([[:alnum:]_\.\-]+\@[[:alnum:]\.\-]+) 
KCleanAtHost regex  -s1 (\@[[:alnum:]\.\-]+) 
KCleanHost regex  -s1 ([[:alnum:]\.\-]+) 
KReceivedBy regex -m -a.FOUND  (by [[:alnum:]\.\-]+) 
KReceivedWithHTTP regex -m -a.FOUND (with HTTP)
ECHO
#mail8_zombie takes care of Zombie names that sendmail can not detect
    if ( -x "/etc/mail/mail8/mail8_zombie" )
    {
    echo <<ECHO;
KZombie program -t /etc/mail/mail8/mail8_zombie
ECHO
    }
    echo <<ECHO;
dnl white list
Kmail4db hash -o -a.FOUND /etc/mail/mail8/mail4.db
dnl standard black list
Kstdaccessdb hash -o -a.FOUND /etc/mail/access.db
ECHO

# we can do some checking with HEADER lines
    echo <<ECHO;

HFrom: £>+ScreenHeader
HReply-to: £>+ScreenHeader
HReceived: £>+ScreenHeader

ECHO

}



=head2 PerlHelpers

=over 4

This enables the use of the additional Perl scripts to identify and block bogus e-mail hosts, especialy when the site is being bombed by an abusive system.

None of the scripts are currently available on CPAN, and there is no current intention of releasing them at this time, this is mostly due to the extra system setup required, such as interfaces to the B<iptables> firewall script bring used!

If you would like to use these, contact celmorlauren for help.

=back

=cut
push @EXPORT, "PerlHelpers";
sub PerlHelpers
{
# perl scripts, last resort due to high overhead in starting
    $mail8_setup->{'PerlHelpers'} = 1;
    echo <<ECHO;
dnl perl programs, used as last resort
Kmail8 program /etc/mail/mail8/mail8.pl
Kmail8b program /etc/mail/mail8/mail8block.pl
Kmail9b program /etc/mail/mail8/mail9block.pl
ECHO
}

=head2 mail8_db(SCALAR test)

=over 4

These are configured automatically by the above B<PerlHelpers>, and are only useable with  B<PerlHelpers>, if the above has not been defined then this returns without doing anything.

However there is one exception to this, B<mail4> is always required as there is no other way of allowing "broken mail systems" that you want to accept mail from!

To keep sendmail error messages down (/var/log/mail) ensure you create all the required database's by hand, B<mail4> at the very least!

For manual creation of files,
use B<vi ###; makemap hash ###.db E<lt>###> where ### is the database source.

    /etc/mail/mail8/mail9.db        ip (address port 25) to TarPit
                                    in firewall rules
    /etc/mail/mail8/mail8.db        refuse connect to SPAMMER
                                    access.db also does this and more
    /etc/mail/mail8/mail4.db        allow, OK this host would fail tests
    /etc/mail/mail8/mail3.db        single shot, allow, like mail4
    /etc/mail/mail8/mail2.db        relays hosted domains
                                    $=R, $=w, & ${VirtHost} also does this
    /etc/mail/mail8/mail1.db        relays internal hosts by IP
                                    192.168.#.#     assummed local
                                    172.16.#.#      assummed local
                                    10.#.#.#        assummed local


B<NOTE> This files are all optional, so this can be specified even if none of these exist.

The single useable argument if SCALAR will place the DataBases in /var/tmp/mail8, which enables you to test with alternate files to the running version.

=back

=cut
push @EXPORT, "mail8_db";
sub mail8_db
{
    my ($testmode) = @_; 
    unless ( $mail8_setup->{'PerlHelpers'} )
    {
        return;
    }
    else
    {
# black and white lists
        $mail8_setup->{'mail8_db'} = 1;
        my $mail8_base = (scalar $testmode)?("/var/tmp"):("/etc/mail/mail8");
        echo <<ECHO;
dnl black list (firewall) should also be in mail8
Kmail9db hash -o -a.FOUND $mail8_base/mail9.db
dnl black list
Kmail8db hash -o -a.FOUND $mail8_base/mail8.db
Kmail4db hash -o -a.FOUND $mail8_base/mail4.db
dnl one off white list
Kmail3db hash -o -a.FOUND $mail8_base/mail3.db
dnl our own domains, stops people claiming to be us!
Kmail2db hash -o -a.FOUND $mail8_base/mail2.db
dnl our own IP's, this is mostly to by pass these routines, but also traps some spammers
Kmail1db hash -o -a.FOUND $mail8_base/mail1.db
ECHO
    }
}

=head2 local_rulesets

=over 4

Required statement, this inserts required statements into the hack file.

This inserts required statements before and after B<LOCAL_RULESETS>, you may add more statements that belong here.

Main items
    D{Paranoid}"%setup{paranoid}"           paranoid level set above
    D{mail8yhabr}"YOU HAVE ALREADY BEEN REFUSED!"
    D{mail8ctboood}"SPAMMER CLAIMED TO BE ONE OF OUR DOMAINS!"
    D{mail3tt}"ONLY MAIL TO SUPPLIED Trouble Ticket ACCEPTED"

=back

=cut
push @EXPORT, "local_rulesets";
sub local_rulesets
{
# some error messages
    echo <<ECHO;
D{Paranoid}"$mail8_setup->{'paranoid'}" 
D{mail8yhabr}"YOU HAVE ALREADY BEEN REFUSED!"
D{mail8ctboood}"SPAMMER CLAIMED TO BE ONE OF OUR DOMAINS!"
D{mail3tt}"ONLY MAIL TO SUPPLIED Trouble Ticket ACCEPTED"
ECHO

# this is the start of the real code
    LOCAL_RULESETS;
}

##############################################################################
# CODE is INLINED where possible, and declared before use.
# why does sendmail have such small limits on "named  rulsets"???

##############################################################################
##############################################################################
##############################################################################
##############################################################################
#TODO
##############################################################################
##############################################################################
##############################################################################
##############################################################################

=head2 screen_domain    GLOBAL B

=over 4

HELO DOMAIN NAME CHECKING

Most SPAMMERS use ZOMBIE PC's to send their spam, most if not all have completly numeric DNS names.

=over 4

=item *

Most have their IP address in simple dotted or dashed notation, often all 4 parts of their IP address, we will not let any who have 2 or more parts of their address as their name through.

We are considering a tuning element to vary this, maybe to just one, however a lot of real senders with several servers use the last part of the IP address in their name.

=item *

Some unhelpfull ISP's string the IP's together as a single number.

=item *

Some very unhelpfull ISP's encode the numbers in HEX.

=item *

And finally totally random strings of numbers and letters, which have led us in the past to completly block the entire domain in the standard B<access.db> file, this is often the best thing to do with hard to otherwise stop SPAMMER domains.

=back


=cut
push @EXPORT, "screen_domain";
sub screen_domain
{

=pod

As much as possible of the code is INLINED to reduce the "B<named rulesets>" total, as inlined code must be defined before use, macros are in reverse order.

=cut

=pod

[Pad,Hex,PadHex]Number convert single digits to what the name sugests.

=cut

# must be a better way of doing this

# IP's are often encoded in DNS names, sometimes with leading zeros
    rule "SPadNumber", "GLOBAL D", "INLINE NOMASH", "NOTEST AUTO", map { sprintf "R %u    £: %.3u",$_,$_ } (0..99); 
# alternativly maybe coded in hexidecimal
    rule "SHexNumber", "GLOBAL D", "INLINE NOMASH", "NOTEST AUTO", map { sprintf "R %u    £: %x",$_,$_ } (10..255); 
# padded, normally coded with leading zero for values under F
    rule "SPadHexNumber",
        "GLOBAL D",  
        "INLINE NOMASH",
        "NOTEST AUTO", 
        (map { sprintf "R %u    £: %.2x",$_,$_ } (0..15)),
        (map { sprintf "R %x    £: %.2x",$_,$_ } (10..15));


=pod

(Pad,Hex,PadHex)IpNumber 

=over 4

convert four digit IP address to what the name sugests.

=back

=cut
    foreach ( qw(Pad Hex PadHex ) )
    {
        my $S = "S".$_."IpNumber";
        my $M = $_."Number";
        rule <<RULE;
$S
GLOBAL C
INLINE
NOTEST AUTO
R £-.£-.£-.£-       £: £1
R £*                £: £>$M £1
R £*                £: £(SelfMacro {MashTempA} £@ £1 £) £1        Padded digit 1
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £2
R £*                £: £>$M £1
R £*                £: £(SelfMacro {MashTempB} £@ £1 £) £1        Padded digit 2
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £3
R £*                £: £>$M £1
R £*                £: £(SelfMacro {MashTempC} £@ £1 £) £1        Padded digit 3
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £4
R £*                £: £>$M £1
R £*                £: £(SelfMacro {MashTempD} £@ £1 £) £1        Padded digit 4
R £*                £: £&{MashTempA}.£&{MashTempB}.£&{MashTempC}.£&{MashTempD}
RULE
    }


=pod

ScreenMash     

=over 4

The worker, matchs supplied patten with $s (HELLO).

However Hello must be clearly tokenised.

=back

=cut

    rule <<RULE;
SScreenMash
GLOBAL F
INLINE MASH
dnl if not clearly tokenised then will not work
TEST D(see123456789.local.bogus) V(123456789)
TEST D(see123456789s.local.bogus) V(123456789)
TEST D(s123456789s.local.bogus) V(123456789)
TEST D(see.123456789s.local.bogus) V(123456789)
TEST D(sff.ee.123456789s.local.bogus) V(123456789)
TEST D(sqq.ff.ee.123456789s.local.bogus) V(123456789)
TEST D(see.qq.ff.ee.123456789s.local.bogus) V(123456789)
dnl token match works on these below
TEST D(s123456789.local.bogus) E(123456789)
TEST D(see.123456789.local.bogus) E(123456789)
TEST D(sff.ee.123456789.local.bogus) E(123456789)
TEST D(sqq.ff.ee.123456789.local.bogus) E(123456789)
TEST D(see.qq.ff.ee.123456789.local.bogus) E(123456789)
R £*                    £: £&s                                  Get Helo name
R £&{MashSelf}.£+       £#error £@ 5.1.8 £: "550 I am not your MX, go away! (S.<" £&{MashSelf} ">)"
R £&{MashSelf}£+        £#error £@ 5.1.8 £: "550 I am not your MX, go away! (SJ.<" £&{MashSelf} ">)"
R £+.£&{MashSelf}.£+    £#error £@ 5.1.8 £: "550 I am not your MX, go away! (L.<" £&{MashSelf} ">)"
R £+£&{MashSelf}.£+     £#error £@ 5.1.8 £: "550 I am not your MX, go away! (LJ.<" £&{MashSelf} ">)"
R £+£&{MashSelf}£+      £#error £@ 5.1.8 £: "550 I am not your MX, go away! (MJ.<" £&{MashSelf} ">)"
RULE


=pod

Splice          used by ScreenIP

=over 4

There must be a better way to do this, however as far as decimal numerics goes this works, nothing todate (lots of time spent trying) works for HEX.

celmorlauren will continue to use the original Perl helpers for now.

=back

=cut
    rule <<RULE;
SSplice
GLOBAL E
INLINE
NOTEST AUTO
R £-.£-.£-.£-       £: £(Math * £@ £1 £@ 1000000000 £: ERR £)       must not resolv to 0
R £*                £: £(SelfMacro {MashTempA} £@ £1 £) £1         digit 1
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £(Math * £@ £2 £@ 1000000 £: ERR £)          however following digits can be 0
R £*                £: £(SelfMacro {MashTempB} £@ £1 £) £1         digit 2
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £(Math * £@ £3 £@ 1000 £: ERR £)
R £*                £: £(SelfMacro {MashTempC} £@ £1 £) £1         digit 3
R £*                £: £&{MashSelf}
R £-.£-.£-.£-       £: £(SelfMacro {MashTempD} £@ £4 £) £1         digit 4
dnl now add the parts dnl
R £*                £: £(Math + £@ £&{MashTempA} £@ £&{MashTempB} £: ERR £)
R £*                £: £(SelfMacro {MashTempA} £@ £1 £) £1       1 and 2
R £*                £: £(Math + £@ £&{MashTempC} £@ £&{MashTempD} £: ERR £)
R £*                £: £(SelfMacro {MashTempB} £@ £1 £) £1       3 and 4
R £*                £: £(Math + £@ £&{MashTempA} £@ £&{MashTempB} £: ERR £)
R 0                 £: £&{MashSelf}                                 a value of zero means nothing worked
RULE

=pod

ScreenIpPatten      used by above, trys patten dotted then dashed

=cut
    rule <<RULE;
SScreenIpPatten
GLOBAL E
INLINE MASH
NOTEST AUTO
R £*                £: £>ScreenMash £1                      Got IP or part
R £-.£-.£-.£-       £: £1-£2-£3-£4                          dash it
R £-.£-.£-          £: £1-£2-£3
R £-.£-             £: £1-£2
R £*                £: £>ScreenMash £1
RULE

=pod

ScreenIP    

=over 4

used by above, trims IP address from 4 then 3 then 2, also trys re-arranging and all 4 parts spliced together as a single token

=back

=cut
    rule <<RULE;
SScreenIP
GLOBAL D
INLINE MASH
NOTEST AUTO
R £*                £: £>ScreenIpPatten £1              Check 4 part address
R £-.£-.£-.£-       £: £2.£3.£4
R £*                £: £>ScreenIpPatten £1              Check 3 part address
R £-.£-.£-          £: £2.£3
R £*                £: £>ScreenIpPatten £1              Check 2 part address
dnl restore and try again
R £*                £: £&{MashSelf}                     Restore Original
R £-.£-.£-.£-       £: £1.£2.£3                         OK try other end trimmed
R £*                £: £>ScreenIpPatten £1              Check 3 part address
R £-.£-.£-          £: £1.£2
R £*                £: £>ScreenIpPatten £1              Check 2 part address
dnl restore and try again
R £*                £: £&{MashSelf}                     Restore Original
R £*                £: £>Splice £1                      ok lets join the IP parts together
R £*                £: £>ScreenMash £1                  try the joined-up ip
RULE


=pod

ScreenDomainIP   small often used macro, re-arranges IP to check

=cut
    rule <<RULE;
SScreenDomainIP
GLOBAL C
INLINE MASH
NOTEST AUTO
    R £*                £: £>ScreenIP £1            Check normal IP direction
    R £-.£-.£-.£-       £: £4.£3.£2.£1              Reverse 
    R £*                £: £>ScreenIP £1            Check reverse IP direction
    R £*                £: £&{MashSelf}             restore
    R £-.£-.£-.£-       £: £4.£1.£2.£3              lead with trailing ip
    R £*                £: £>ScreenIP £1            try pattern
    R £*                £: £&{MashSelf}             restore
    R £-.£-.£-.£-       £: £3.£4.£1.£2              lead with trailing 2 ip
    R £*                £: £>ScreenIP £1            try pattern
RULE

#TODO
# now this should only be stated if the Perl Helpers are defined.
# But as we have failed to incorperate all the testing we wanted,
# we will re-write one of the current helpers without stuff that 
# will not work on systems that we have not installed ourselves.
    my ($ZOMBIE, $zombie_e);
    if ( -x "/etc/mail/mail8/mail8_zombie" )
    {
        $zombie_e = "E";
        $ZOMBIE = <<ZOMBIE;
    R £*        £: MACRO{ £1
        INLINE NOMASH
        dnl these tests will only work with the Perl Helper installed
        TEST D(sLEAD.c0a97b8c.DOMAIN) V(192.169.123.140)
        TEST D(sLEAD.C0A97B8C.DOMAIN) V(192.169.123.140)
        dnl            hello, connected ip,
        R £*        £: £&s £&{client_addr}
        R £*        £: £(Zombie £1 £)
        R ERR.£*    £#error £@ 5.1.8 £: "550 I am not your MX, go away! ERR=" £1
    }MACRO
ZOMBIE
    }
    else
    {
        $zombie_e = "V";
        moan <<MOAN;
/etc/mail/mail8/mail8_zombie is not installed on this system
as it is now part of the standard distribrution
Please install it
mail8_zombie takes care of Zombie names that sendmail can not detect
MOAN
        ok "carry on regardless? [Y|n]" or exit;
        $ZOMBIE = <<ZOMBIE;
        dnl /etc/mail/mail8/mail8_zombie is not installed on this system dnl
        dnl as it is now part of the standard distribrution dnl
        dnl please install it dnl
        dnl mail8_zombie takes care of Zombie names that sendmail can not detect dnl
ZOMBIE
    }

    
    rule <<RULE;
SScreenDomain
GLOBAL B
TEST D({client_addr}192.168.0.14)
TEST D(sLEAD.192.168.0.14.DOMAIN) E(192.168.0.14)
TEST D(sLEAD192.168.0.14.DOMAIN)  E(192.168.0.14)
TEST D(sLEAD168.0.14.DOMAIN)      E(192.168.0.14)
TEST D(sLEAD.0.14.DOMAIN)         E(192.168.0.14)
TEST D(sLEAD.192.168.0.DOMAIN)    E(192.168.0.14)
TEST D(sLEAD.192.168.DOMAIN)      E(192.168.0.14)
TEST D(sLEAD.192168000014.DOMAIN) E(192.168.0.14)
# should be noted that run together IP's are detected by Zombie
TEST D(sLEAD.192168014.DOMAIN)    $zombie_e(192.168.0.14)
# HELLO host with IP with leading ZEROS
TEST D(sLEAD.192.168.000.014.DOMAIN) E(192.168.0.14)
TEST D(sLEAD192.168.000.014.DOMAIN)  E(192.168.0.14)
TEST D(sLEAD168.000.014.DOMAIN)      E(192.168.0.14)
TEST D(sLEAD.000.014.DOMAIN)         E(192.168.0.14)
TEST D(sLEAD.192.168.000.DOMAIN )    E(192.168.0.14)
TEST D(sLEAD.192.168.DOMAIN)         E(192.168.0.14)
# now  for HEX hosts that should fail
TEST D(sLEAD.c0.a8.0.e.DOMAIN)    E(192.168.0.14)
TEST D(sLEAD.C0.A8.0.E.DOMAIN)    E(192.168.0.14)
TEST D({client_addr}192.169.123.140)
TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  E(192.169.123.140)
TEST D(sLEAD.c0.a9.7b.8c.DOMAIN)  E(192.169.123.140)
TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  E(192.169.123.140)
TEST D({client_addr}10.11.12.9)
TEST D(sLEAD.A.B.C.9.DOMAIN)      E(10.11.12.9)
TEST D(sLEAD.0A.0B.0C.09.DOMAIN)  E(10.11.12.9)
# this can not cope with run together HEX encoding
TEST D({client_addr}192.169.123.140)
TEST D(sLEAD.c0a97b8c.DOMAIN) $zombie_e(192.169.123.140)
TEST D(sLEAD.C0A97B8C.DOMAIN) $zombie_e(192.169.123.140)
TEST D(sLEADc0joa97b8c.DOMAIN) $zombie_e(192.169.123.140)
TEST D(sLEADC0A97Bkzs8C.DOMAIN) $zombie_e(192.169.123.140)
R £*    £: MACRO{ £1    # should have been supplied with HELO host IP
    INLINE MASH
    dnl HELLO host with IP encoded directly within it
    TEST D({client_addr}192.168.0.14)
    TEST D(sLEAD.192.168.0.14.DOMAIN) E(192.168.0.14)
    TEST D(sLEAD192.168.0.14.DOMAIN)  E(192.168.0.14)
    TEST D(sLEAD168.0.14.DOMAIN)      E(192.168.0.14)
    TEST D(sLEAD.0.14.DOMAIN)         E(192.168.0.14)
    TEST D(sLEAD.192.168.0.DOMAIN)    E(192.168.0.14)
    TEST D(sLEAD.192.168.DOMAIN)      E(192.168.0.14)
    TEST D(sLEAD.192168000014.DOMAIN) E(192.168.0.14)
    dnl should be noted that run together IP's dont work, except when padded 
    TEST D(sLEAD.192168014.DOMAIN)    V(192.168.0.14)
    dnl now to for hosts that should pass this, but will fail later
    TEST D(sLEAD.c0.a8.0.e.DOMAIN)    V(192.168.0.14)
    TEST D(sLEAD.C0.A8.0.E.DOMAIN)    V(192.168.0.14)
    TEST D({client_addr}192.169.123.140)
    TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  V(192.169.123.140)
    R £*                £: £>ScreenDomainIP £1
}MACRO
R £*    £: MACRO{ £1    # still here, maybe the HELO address has padded IP?
    INLINE MASH
    dnl HELLO host with IP with leading ZEROS
    TEST D({client_addr}192.168.0.14)
    TEST D(sLEAD.192.168.000.014.DOMAIN) E(192.168.0.14)
    TEST D(sLEAD192.168.000.014.DOMAIN)  E(192.168.0.14)
    TEST D(sLEAD168.000.014.DOMAIN)      E(192.168.0.14)
    TEST D(sLEAD.000.014.DOMAIN)         E(192.168.0.14)
    TEST D(sLEAD.192.168.000.DOMAIN )    E(192.168.0.14)
    TEST D(sLEAD.192.168.DOMAIN)         E(192.168.0.14)
    dnl hum below is caught by the preceeding check, but fails here as leading ZEROs 
    dnl cause arith to assume the number is something other than decimal
    TEST D(sLEAD.192168000014.DOMAIN)    V(192.168.0.14)
    dnl now to for hosts that should pass this, but will fail later
    TEST D(sLEAD.c0.a8.0.e.DOMAIN)    V(192.168.0.14)
    TEST D(sLEAD.C0.A8.0.E.DOMAIN)    V(192.168.0.14)
    TEST D({client_addr}192.169.123.140)
    TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  V(192.169.123.140)
    TEST D(sLEAD.c0.a9.7b.8c.DOMAIN)  V(192.169.123.140)
    TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  V(192.169.123.140)
    TEST D({client_addr}10.11.12.9)
    TEST D(sLEAD.A.B.C.9.DOMAIN)      V(10.11.12.9)
    TEST D(sLEAD.0A.0B.0C.09.DOMAIN)  V(10.11.12.9)
    R £*                £: £>PadIpNumber £1         OK now pad number and try again
    R £*                £: £>ScreenDomainIP £1
}MACRO
R £*    £: MACRO{ £1    # still here, maybe the HELO address has HEX coded IP?
    INLINE MASH
    dnl this would have failed above, but are included here to check that they pass here
    TEST D({client_addr}192.168.0.14)
    TEST D(sLEAD.192.168.000.014.DOMAIN) V(192.168.0.14)
    TEST D(sLEAD192.168.000.014.DOMAIN)  V(192.168.0.14)
    TEST D(sLEAD168.000.014.DOMAIN)      V(192.168.0.14)
    TEST D(sLEAD.000.014.DOMAIN)         V(192.168.0.14)
    TEST D(sLEAD.192.168.000.DOMAIN )    V(192.168.0.14)
    TEST D(sLEAD.192.168.DOMAIN)         V(192.168.0.14)
    TEST D(sLEAD.192168000014.DOMAIN)    V(192.168.0.14)
    dnl now to for hosts that should fail
    TEST D(sLEAD.c0.a8.0.e.DOMAIN)    E(192.168.0.14)
    TEST D(sLEAD.C0.A8.0.E.DOMAIN)    E(192.168.0.14)
    TEST D({client_addr}192.169.123.140)
    TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  E(192.169.123.140)
    TEST D(sLEAD.c0.a9.7b.8c.DOMAIN)  E(192.169.123.140)
    TEST D(sLEAD.C0.A9.7B.8C.DOMAIN)  E(192.169.123.140)
    TEST D({client_addr}10.11.12.9)
    TEST D(sLEAD.A.B.C.9.DOMAIN)      E(10.11.12.9)
    TEST D(sLEAD.0A.0B.0C.09.DOMAIN)  E(10.11.12.9)
    dnl this can not cope with run together HEX encoding
    TEST D({client_addr}192.169.123.140)
    TEST D(sLEAD.c0a97b8c.DOMAIN) V(192.169.123.140)
    TEST D(sLEAD.C0A97B8C.DOMAIN) V(192.169.123.140)
    R £*                £: £>HexIpNumber £1         OK now Hex number and try again
    R £*                £: £>ScreenDomainIP £1
    dnl still here, maybe the HELO address has padded HEX coded IP? dnl
    R £*                £: £>PadHexIpNumber £1         OK now Hex number and try again
    R £*                £: £>ScreenDomainIP £1
    dnl nothing for it, must use an external program to do the last ditch testing dnl
    dnl at least most ZOMBIES will have been stopped by the above rules dnl
    $ZOMBIE
}MACRO
RULE
}
##############################################################################
##############################################################################
##############################################################################
#TODO
##############################################################################
##############################################################################
##############################################################################

=head2 local_check_relay        GLOBAL A

=over 4

CONTACT

This bit arrived at on first contact, and so permissions based on IP can be set

Local_check_relay standard rule, to check incoming connection against mail8 databases and of course standard local ip addresses, further rules are based on what happens here.

=cut
push @EXPORT, "local_check_relay";
sub local_check_relay
{
    echo <<ECHO;

dnl this bit is for mail8, intial contact and flood checking?
dnl bit below checked, see p288 sendmail 3rd edition
ECHO

    sane <<SANE;
GoodRelay
{GoodRelay}this.one.FOUND, {BadRelay}this.one.FOUND
{RelayChecked}done.FOUND
{client_resolve}OK
SANE
    sane <<SANE;
BadRelay
{BadRelay}this.one.FOUND
{GoodRelay}notset.clear
{RelayChecked}done.FOUND
SANE
    sane <<SANE;
Local_check_relay
{GoodRelay}notset.clear, {BadRelay}notset.clear
SANE
    rule <<RULE;
SLocal_check_relay
GLOBAL A
HINT This bit arrived at on first contact, and so permissions based on IP can be set
TEST SANE(Local_check_relay) T(Translate) AUTO(D; OUR; {client_resolve} RESOLVE, V OUR DOMAIN IP)     
TEST SANE(Local_check_relay) T(Translate) F(localhost 127.0.0.1)
TEST D({client_resolve}OK)
TEST SANE(Local_check_relay) T(Translate) F(pc1.local 192.168.0.1, pc2.local 172.16.4.1, serv1.local 10.0.0.1) V(uknown.bogus.bogus 987.654.321.0)
TEST D({client_resolve}FAIL)
TEST SANE(Local_check_relay) T(Translate) V(bogus.bogus 721.0.0.1)
# init {MashFound} or it will not work
DEFINE_MASHFOUND
R £*            £: MACRO{ £1    # mail8 DB, check both name and IP
    NOTEST AUTO Local_check_relay wraps this entirely, mail8 will block access
    R £* £| £*      £: £(SelfMacro {MashTempC} £@ £1 £) £1 £| £2
    R £* £| £*      £: £(SelfMacro {MashTempD} £@ £2 £) £1 £| £2
    dnl sendmail's own tables wrap IP in square brackets dnl
    R £*            £: £&{MashTempD}                          try IP
    R £*            £: [ £1 ]                               wrap with brackets
    R £*            £: £>Screen_bad_relay £1
    R £+.FOUND      £@ £1.FOUND                             found IP
    dnl now try IP as is, may be found in mail8 db? dnl
    R £*            £: £>Screen_bad_relay £&{MashTempD}       try IP
    R £+.FOUND      £@ £1.FOUND                             found IP
    dnl now try domain name
    R £*            £: £&{client_resolve}                   try name if it resolved
    R OK            £@ £>Screen_bad_relay £&{MashTempC}     found it?
}MACRO
R £*            £: Check.FOUND
STORE RelayChecked
RULE

=pod

uses Macro B<Screem_bad_relay> (GLOBAL B) to do the main checking

{GoodRelay} and {BadRelay} both contain result of check, such values as (where # is checked value).
    
    #.Local.FOUND       $w                                  {GoodRelay}
    #.VirtHost.FOUND    ${VirtHost}                         {GoodRelay}
    #.RelayDomain.FOUND $R                                  {GoodRelay}
    #.mail1.FOUND       mail1.db                            {GoodRelay}
    #.Private.FOUND     192.168.#.# 172.16.#.# 10.#.#.#     {GoodRelay}
    #.mail4.FOUND
    #.mail3.FOUND

mail8 amd mail9 checks result im $#error

Being found does not mean that the host is a BadRelay, just that it will need handling differently to other hosts.
Hosts recorded as being GoodRelay.

yahoo and hotmail hosts are recorded as {RestrictedHosts}, to help to ensure that e-mail purporting to come from these domains does infact come from these domains.

=back

=cut

    my $Screen_bad_relay_rule = <<RULE;
SScreen_bad_relay
GLOBAL B
HINT Called by 'Local_check_relay' with IP then domain name
TEST F(localhost, 127.0.0.1, 192.168.0.1, 172.16.0.1, 10.0.0.1)
TEST V(bogus.bogus, 987.6.5.4, 321.123.321.123)
R £*    £: MACRO{ £1    # check for local systems
    TEST F(localhost, [127.0.0.1], 127.0.0.1, 192.168.254.200, 172.16.34.5, 10.4.5.6)
    TEST V(BOGUS.BOGUS, 987.64.34.1)
    dnl standard sendmail tables first dnl
    R £=w               £@ £1.Local.FOUND
    R £={VirtHost}      £@ £1.VirtHost.FOUND
    R £=R               £@ £1.RelayDomain.FOUND
RULE
    if ( scalar $mail8_setup->{'PerlHelpers'} )
    {
        $Screen_bad_relay_rule .= <<RULE;
    dnl mail8 database checks, some duplicate standard databases dnl
    dnl now for mail1 table, IP's in preference to names dnl
    R £*                £: £(mail1db £1 £: £1 £)          mail1 DB, our domain IP's check
    R £+.FOUND          £@ £1.mail1.FOUND
RULE
    }
    $Screen_bad_relay_rule .= <<RULE;
    dnl  standard private domains are assumed to be ok dnl
    R 192.168.£+        £@ £&{MashSelf}.Private.FOUND
    R 172.16.£+         £@ £&{MashSelf}.Private.FOUND
    R 10.£+             £@ £&{MashSelf}.Private.FOUND
    R 127.£+            £@ £&{MashSelf}.Private.FOUND
}MACRO
FOUND GoodRelay     found? then is one of our domains
R £+.FOUND      £@ £1.FOUND    ok one of our domains
RULE
    if ( scalar $mail8_setup->{'PerlHelpers'} )
    {
        $Screen_bad_relay_rule .= <<RULE;
# now for systems that are not local
R £*    £: MACRO{ £1    # check for systems that may have problems
    OPTION MASH 1
    HINT This checks mail8's DataBases for IP's or domain names?
    dnl mail8 database checks  dnl
    R £*            £: £(mail4db £1 £: £1 £)          mail4 DB, poorly configured systems, that will fail tests
    R £+.FOUND      £@ £1.mail4.FOUND
    R £*            £: £(mail3db £1 £: £1 £)          mail3 DB, single shot white list
    R £+.FOUND      £@ £1.mail3.FOUND
    R £*            £: £(mail8db £1 £: £1 £)          mail8 DB, spammer check
    R £+.FOUND      £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!"
    dnl if firewall interface is working should never get here dnl
    R £*            £: £(mail9db £1 £: £1 £)          mail9 DB, spammer check
    R £+.FOUND      £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!"
}MACRO
FOUND BadRelay      found? then save here
R £+.FOUND      £@ £1.FOUND    ok then may be OK?
RULE
    }
    else
    {
        unless ( -d "/etc/mail/mail8" and -f "/etc/mail/mail8/mail4.db" )
        {
            ok "/etc/mail/mail8 or /etc/mail/mail8/mail4.db does not exist: carry on? [Y|n]" or exit;
        }
        $Screen_bad_relay_rule .= <<RULE;
# now for systems that are not local
R £*    £: MACRO{ £1    # check for systems that may have problems
    OPTION MASH 1
    HINT This checks mail8's DataBases for IP's or domain names?
    dnl mail8 database checks  dnl
    R £*            £: £(mail4db £1 £: £1 £)          mail4 DB, poorly configured systems, that will fail tests
    R £+.FOUND      £@ £1.mail4.FOUND
}MACRO
FOUND BadRelay      found? then save here
R £+.FOUND      £@ £1.FOUND    ok then may be OK?
RULE
    }
    $Screen_bad_relay_rule .= <<RULE;
# hotmail and yahoo senders may be refused elsewhere, but if they really are sending mail    
R £+.hotmail.£+     £: hotmail.FOUND
R £+.yahoo.£+       £: yahoo.FOUND
FOUND RestrictedHost    yahoo or hotmail need special treatment
RULE
    rule $Screen_bad_relay_rule;
}

=head2 local_check_mail     GLOBAL A

=over 4

HELO & FROM

After intial HELO and every FROM following

This insists that the HELO host name must either be the same as the {client_name} or resolve to an address that is the same as the {client_name}.

This insists that mail purporting to come from B<hotmail> or B<yahoo> does come from the relevant domain. The mail addres is recorded by {RestrictedHost}

This also handles empty FROM's which are normally bounces of some kind, or the un-helpfull B<callback verify> sudo bounce, which often originates from poorly configured e-mail systems that blindly B<bounce> back to B<Forged FROM> addresses.

{Bounce} records that a empty FROM has been recieved, these are accepted according to the value of {Paranoid}.

{Refused} and {RefusedAgain} record that the connection has been refused, only spammers will cause {RefusedAgain} to be generated, also if the B<Perl Helpers> are installed these will attempt to ammend both sendmail databases and the firewall rules.

Refers to 

=over 4

=item ScreenMail8blocker    GLOBAL B

this is called regardless of wether the B<PerlHelpers> have been installed.

=item ScreenMail9blocker    GLOBAL B

this is called regardless of wether the B<PerlHelpers> have been installed.

=item ScreenDomain          GLOBAL B

this checks the HELO host for being highly numeric, and having its IP encoded in the name.

=back

=back

=cut
push @EXPORT, "local_check_mail";
sub local_check_mail
{
    sane <<SANE;
Local_check_mail
{RelayChecked}ok.FOUND    
{Refused}ok.clear
{AlreadyRefused}ok.clear
{Bounce}ok.clear
SANE

    my $local_check_mail_rule = <<RULE;
SLocal_check_mail
GLOBAL A
# reset globals that are set in above rules
TEST SANE(Local_check_relay)
# also use lowest sensible value for paranoid
TEST D({Paranoid}1)
# 1st check normal legal external senders who have no special rights or needs
TEST SANE(Local_check_mail) AUTO(D; OK; s HELO; {client_name} DOMAIN; {client_addr} IP; {client_resolve} RESOLVE; f FROM, F OK FROM)     
# retest assuming sudo bounce (callback verify) which we have to tollarate to some degree
TEST SANE(Local_check_mail) F(<>) AUTO(D; OK; s HELO; {client_name} DOMAIN; {client_addr} IP; {client_resolve} RESOLVE; f FROM)     
# 2nd check senders who failed with the last release, and should still fail
TEST SANE(Local_check_mail) AUTO(D; BAD; s HELO; {client_name} DOMAIN; {client_addr} IP; {client_resolve} RESOLVE; f FROM;, E BAD FROM)     
# 3rd check our domain who should be able to do anthing
TEST SANE(GoodRelay)
TEST SANE(Local_check_mail) AUTO(D; OUR; s HELO; {client_name} DOMAIN; {client_addr} IP; {client_resolve} RESOLVE; f FROM;, F OUR FROM)     
# retest assuming sudo bounce (callback verify) which we have to tollarate to some degree
TEST SANE(Local_check_mail) F(<>) AUTO(D; OUR; s HELO; {client_name} DOMAIN; {client_addr} IP; {client_resolve} RESOLVE; f FROM)     
FIND Refused      has this host already been refused?
R £+.FOUND      £@ MACRO{ £1
    OPTION NOMASH
    TEST D({Refused}991.2.3.4) E(991.2.3.4, blah.blah)
    TEST D({AlreadyRefused}994.3.2.1.FOUND) E(994.3.2.1)
    FIND AlreadyRefused     refused more than once?
    R £+.FOUND      £: MACRO{
        OPTION NOMASH
        TEST E(nogin.the.nog)
        dnl even if the perl helpers are not installed  dnl
        R £*        £: £>ScreenMail9blocker £{mail8yhabr}       already has been warned, attempt to drop IP
        dnl should not get here, however put something in logs to get sys-admin to do the blocking dnl
        R £*        £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY! " £{mail8yhabr} " SYSTEM ADMIN ATTN"
    }MACRO
    dnl record that this system is trying again dnl
    ALREADYREFUSED £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY! " £{mail8yhabr} " Next time you will be dropped!"
}MACRO
# 2nd time around it has been found that sendmail clobbers macro values!
R £*      £: MACRO{
    OPTION NOMASH
    TEST D({RelayChecked}done.FOUND,{client_name}localhost,{client_addr}127.0.0.1) F(NA)
    TEST D({RelayChecked}done.not,{client_name}localhost,{client_addr}127.0.0.1) F(NA)
    IS FOUND RelayChecked £@ £1
    # Ok if here need to reset various macro names, essentially GoodRelay and BadRelay
    R £*    £: £&{client_name}£|£&{client_addr}
    R £*    £: £>Local_check_relay £1
}MACRO
# 1st time round we get FROM, 2nd time round we get the connected as HOST and IP?
# so we must use f, as this will allways be as expected
R £*            £: £&f
R £*            £: MACRO{ £1
    OPTION NOMASH
    TEST SANE(Local_check_mail, BadRelay) E(you\@localhost)
    TEST SANE(Local_check_mail) D({Paranoid}1) V(<>)
    TEST SANE(Local_check_mail) D({Paranoid}2) V(<>)
    TEST SANE(Local_check_mail) D({Paranoid}3) V(<>)
    TEST SANE(Local_check_mail) D({Paranoid}4) E(<>)
    R < £+ >        £1
    R £+ @ £+       £@ MACRO{ £2    # check HOST part of FROM address
        OPTION NOMASH
        TEST SANE(Local_check_relay)
        TEST SANE(Local_check_mail) E(localhost, host.localhost, any.host.localhost)
        TEST SANE(GoodRelay)
        TEST SANE(Local_check_mail) F(localhost, host.localhost, any.host.localhost)
        TEST SANE(Local_check_relay)
        dnl NOTE: sendmail already checks that the HOST part of the domain name makes sense dnl
        IS FOUND GoodRelay £@ £1    our own systems are presumed OK
        R £*            £: MACRO{ £1 # check claimed host name against local names
            OPTION NOMASH
            TEST F(home.localhost, this.is.home.localhost)
            R £* £&{daemon_addr}    £@ £&{daemon_addr}.MyIP.FOUND
            R £* £=w                £@ £1.Local.FOUND
            R £* £={VirtHost}       £@ £1.VirtHost.FOUND
            R £* £=R                £@ £1.RelayDomain.FOUND
RULE
    if ( $mail8_setup->{'PerlHelpers'} )
    {
        $local_check_mail_rule .= <<RULE;
            R £*                £: £(mail2db £1 £: £1 £)          mail2 DB
            R £+.FOUND          £@ £1.mail2.FOUND
RULE
    }
    $local_check_mail_rule .= <<RULE;
        }MACRO
        dnl is system claiming to be us? dnl
        IS THISFOUND AND REFUSED £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY! " £{mail8ctboood}
        # OK system does not claim to be sending from us
        # these mail domains are hard coded due to be a common favorite of SPAMMERS
        R yahoo.£+      £: yahoo.£1.FOUND
        R hotmail.£+    £: hotmail.£1.FOUND
        R £+.FOUND      £: MACRO{ £1
            OPTION NOMASH
            TEST D(ftest\@yahoo.com, {RestrictedHost}0) E(yahoo.com) 
            TEST D(ftest\@yahoo.com, {RestrictedHost}yahoo.FOUND) V(yahoo.com) 
            R £*            £: £(SelfMacro {MashTempC} £@ £1 £) £1
            FIND RestrictedHost
            R hotmail.£+    £: hotmail
            R yahoo.£+      £: yahoo
            R £*            £: £(SelfMacro {MashTempD} £@ £1 £) £1
            R £*            £: £&{MashTempC}
            R £&{MashTempD}.£+      £@ £&{MashTempC}
            REFUSED £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY! Mail from <" £&f "> WILL ONLY BE ACCEPTED FROM MAIL DOMAIN: " £&{MashTempC} , £&{MashTempD}, £&{MashFound0}
            R £*            £: £&f.FOUND
            FOUND RestrictedUser
        }MACRO
    }MACRO
    #
    dnl record attempt at bounce, we will need this to check at RCPT and DATA checking routines dnl
    dnl local systems are allowed to bounce dnl
    IS FOUND GoodRelay £@ £1
    dnl other systems have limited permissions dnl
    IS FOUND Bounce AND REFUSED £#error £@ 5.1.8 £: "553 Multiple BOUNCES are not allowed, GO AWAY, (Empty From <> address): " £&s
    dnl OK have not bounced before dnl
    R £*                £: £1.FOUND
    STORE Bounce
    dnl empty address, either a "callback verify" or a real bounce dnl
    R £*    £: £&{Paranoid}
    R 0     £@ 0       Not paranoid
    R 1     £@ 1       slighty
    R 2     £@ 2       mildly
    R 3     £@ 3       paranoid
    dnl any bounce at this level of paranoid must be refused, refuse any further attempts dnl
    REFUSED £#error £@ 5.1.8 £: "553 Domain Mail Probes are not allowed, GO AWAY, (Empty From <> address): " £&s
}MACRO
#
#
dnl now we know FROM sort of makes sense check sender dnl
R £*        £: MACRO{ £1    # checking HELO
    OPTION NOMASH
    TEST SANE(Local_check_relay)
    TEST SANE(Local_check_mail)
    TEST D(smail.bogus.bogus) E(NA)
    TEST D(slocalhost) E(NA)
    TEST D(s80.176.153.184, {client_addr}80.176.153.184) E(NA)
    IS FOUND GoodRelay £@ £1    our own systems are presumed OK
    IS FOUND BadRelay £@ £1     other known systems are presummed OK
    #
    dnl now for everybody else
    R £*            £: £&s      HELO name requires checking
    R £*            £: MACRO{ £1 # Check helo
        OPTION MASH 1
        TEST F(home.localhost, this.is.home.localhost)
        TEST F(80.176.153.184) D({client_addr}80.176.153.184)
        dnl some just use their IP? no way can these be legal? dnl
        R £&{client_addr}   £@ £&{client_addr}.IP.FOUND
        dnl others claiming to be us? dnl
        R £* £&{daemon_addr}    £@ £&{daemon_addr}.MyIP.FOUND
        R £* £=w                £@ £1.Local.FOUND
        R £* £={VirtHost}       £@ £1.VirtHost.FOUND
        R £* £=R                £@ £1.RelayDomain.FOUND
RULE
    if ( $mail8_setup->{'PerlHelpers'} )
    {
        $local_check_mail_rule .= <<RULE;
        R £*                £: £(mail2db £1 £: £1 £)          mail2 DB
        R £+.FOUND          £@ £1.mail2.FOUND
        R £*                £: £(mail1db £1 £: £1 £)          mail1 DB
        R £+.FOUND          £@ £1.mail1.FOUND
RULE
    }
    $local_check_mail_rule .= <<RULE;
        dnl  standard private domains are assumed to be not ok dnl
        R 192.168.£+        £@ £&{MashSelf}.Private.FOUND
        R 172.16.£+         £@ £&{MashSelf}.Private.FOUND
        R 10.£+             £@ £&{MashSelf}.Private.FOUND
    }MACRO
    IS THISFOUND AND REFUSED £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY! " £{mail8ctboood}
    #
    dnl does the senders HELO resolve? dnl
    R £*            £: MACRO{ £1  # check HELO with client_name and then DNS
        OPTION MASH 1
        TEST D({client_resolve}OK, {client_name}bogus.host.bogus, sbogus.host.bogus) F(bogus.host.bogus)
        TEST D({client_resolve}FAIL, {client_addr}192.168.0.1, swww.celmorlauren.com) E(www.celmorlauren.com)
        TEST D({client_resolve}TEMP, {client_addr}192.168.0.1, swww.celmorlauren.com) E(www.celmorlauren.com)
        TEST D({client_resolve}FORGED, {client_addr}192.168.0.1, swww.celmorlauren.com) E(www.celmorlauren.com)
        R £*                    £: £&{client_resolve}
        R OK                    £: OK.£&{MashSelf}
        # HELO could be same as client_name
        R OK.£&{client_name}    £@ £&{client_addr}.FOUND     already known, no need to look up
        #
        R £*            £: £(Rlookup £&{MashSelf} £)      HELO host, DNS lookup needed
        R £+.FOUND      £@ MACRO{ £1    #  HELO resolves
            OPTION MASH 2
            TEST D({client_addr}192.168.0.1, {client_name}NA.192.168.0.1.NA, sNA.NA) F(192.168.0.1) E(10.0.0.1)
            R £&{client_addr}   £@ £&{MashSelf}.FOUND
            REFUSED £#error £@ 5.1.8 £: "550 SPAMMER claimed to be: " £&s " with address:" £&{MashSelf}
        }MACRO
        #
        # HELO Failed to verify
        #
        REFUSED
        #
        R £*            £: £&{client_resolve}
        R TEMP          £#error £@ 4.1.8 £: "450 cannot resolve HELO host: " £&{MashSelf}
        R £*            £#error £@ 5.1.8 £: "550 cannot resolve HELO host: " £&{MashSelf} " From: " £1 " Address"
    }MACRO
    R £+.FOUND      £: £>ScreenDomain £1
}MACRO
RULE

    rule $local_check_mail_rule;

    if ( scalar $mail8_setup->{'PerlHelpers'} )
    {
        dnl <<DNL;
The Blocker, for abusive senders, mail bombers etc
Even if the demon is not running (the demon that writes the files and blocks the IP) this will slow the atack down
DNL

        rule <<RULE;
SScreenMail8blocker
GLOBAL B
TEST D({client_addr}999.888.777.666) E(error message)
REFUSED
dnl Perl Helper args = connected-as, claiming-to-be, optional-error-message
dnl helper will also remove connected-as from mail3 and mail4 databases
R £*        £: £&{client_addr} £&s £&{MashSelf}
R £*        £: £(mail8b £1 £)
R £*        £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!" £1
RULE
        rule <<RULE;
SScreenMail9blocker
GLOBAL B
TEST D({client_addr}999.888.777.666) E(error message)
dnl Perl Helper args = connected-as, claiming-to-be, optional-error-message
R £*        £: £&{client_addr} £&s £&{MashSelf}
R £*        £: £(mail9b £1 £)
R £*        £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!" £1
RULE
    }
    else
    {
        rule <<RULE;
SScreenMail8blocker
GLOBAL B
TEST D({client_addr}999.888.777.666) E(error message)
REFUSED  £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!" £&{MashSelf}
RULE
        rule <<RULE;
SScreenMail9blocker
GLOBAL B
TEST E(error message)
R £*        £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY!" £1
RULE
    }

    inbuilt_rule <<RULE;
check_mail
TEST SANE(Local_check_relay, Local_check_mail)
TEST SANE(Local_check_mail) AUTO(D;OK; s HELO; {client_addr} IP; {client_name} DOMAIN; {client_resolve} RESOLVE; f FROM, F OK FROM)    
TEST SANE(Local_check_mail) AUTO(D;BAD; s HELO; {client_addr} IP; {client_name} DOMAIN; {client_resolve} RESOLVE; f FROM, E BAD FROM)    
RULE
}

=head2 local_check_rcpt     GLOBAL A

=over 4

RCPT

standard sendmail rules do most of the work, however depending on the value {Paranoid} responses will vary in responce to {Bounce} requests.

=back

=cut
push @EXPORT, "local_check_rcpt";
sub local_check_rcpt
{
    dnl <<DNL;
RCPT
normal rules do most of the work, however mail3.db is for one shot bad boys
DNL
    my $local_check_rcpt_rule = <<RULE;
SLocal_check_rcpt
GLOBAL A
TEST SANE(Local_check_relay, Local_check_mail)
R £*            £: MACRO{ £1 # first check wether sender is local
    TEST D({GoodRelay}localhost.FOUND) F(na\@localhost)
    TEST SANE(Local_check_relay)
    TEST D({BadRelay}tt\@localhost.mail3.FOUND,{rcpt_addr}tt\@localhost) V(NA)
    TEST D({BadRelay}tt\@localhost.mail3.FOUND,{rcpt_addr}nott\@localhost) E(NA)
    TEST SANE(Local_check_relay)
    TEST D({Bounce}is.FOUND)
    TEST D({rcpt_host}localhost, {Paranoid}2) O(na\@localhost)
    TEST D({rcpt_host}notlocalhost, {Paranoid}2) E(na\@localhost)
    TEST D({rcpt_host}notlocalhost, {Paranoid}3) O(na\@localhost)
    TEST SANE(Local_check_relay, Local_check_mail)
    IS FOUND GoodRelay £@ £1.FOUND
    FIND BadRelay         relays with problems, more checking needed
    R £+.FOUND      £@ MACRO{ £1
        OPTION NOMASH
        TEST D({rcpt_addr}match.this) V(match.this.mail3) E(not.this.mail3)
        R £*.mail3      £@ MACRO{ £1 # Trouble Ticket user
            OPTION MASH 2
            TEST D({rcpt_addr}bingo.local) V(bingo.local) E(bad.nothing)
            R £&{rcpt_addr}     £@ £&{MashSelf}
            R £*                £@ £>ScreenMail8blocker £{mail3tt}
        }MACRO
    }MACRO
    FIND Bounce
    R £+.FOUND      £@ MACRO{ £1
        OPTION NOMASH
        TEST D({Paranoid}2, {rcpt_host}localhost) O(localhost)
        TEST D({Paranoid}2, {rcpt_host}not.such.host) E(not.such.host)
        TEST D({Paranoid}3, {rcpt_host}localhost) O(localhost)
        TEST D({Paranoid}3, {rcpt_host}not.such.host) O(not.such.host)
        TEST D({Paranoid}1, {rcpt_host}not.such.host) V(not.such.host)
        R £*            £: £&{Paranoid}
        R 2             £: OK2.£&{rcpt_host}
        R OK2.£+        £@ MACRO{ £1
            OPTION NOMASH
            TEST D({rcpt_host}na.auto.na)
            TEST O(localhost)
            TEST AUTO(O OUR HELO, E BAD HELO)
            R £* £=w               £# OK
            R £* £={VirtHost}      £# OK
            R £* £=R               £# OK
RULE
    if ( $mail8_setup->{'PerlHelpers'} )
    {
        $local_check_rcpt_rule .= <<RULE;
            R £*                £: £(mail2db £1 £: £1 £)          mail2 DB
            R £+.FOUND          £# OK
RULE
    }
    $local_check_rcpt_rule .= <<RULE;
            REFUSED £#error £@ 5.1.8 £: "550 SPAMMER, GO AWAY! MAIL REFUSED FOR HOST" £&{rcpt_host}
        }MACRO
        dnl bogus bounces deserve to be treated with bogus replys dnl
        R 3             £# OK
    }MACRO
}MACRO
RULE
    rule $local_check_rcpt_rule;

    inbuilt_rule <<RULE;
check_rcpt
TEST SANE(Local_check_relay, Local_check_mail)
TEST SANE(Local_check_mail) AUTO(D;OK; s HELO; {client_addr} IP; {client_name} DOMAIN; {client_resolve} RESOLVE, V OUR RCPT)    
TEST SANE(Local_check_mail) AUTO(D;OK; s HELO; {client_addr} IP; {client_name} DOMAIN; {client_resolve} RESOLVE, E OK FROM)    
RULE
}

=head2 check_data       GLOBAL A

=over 4

DATA

This bit is for checking for B<callback verify> requests which are a B<fake bounce> with no B<DATA>, action depends on setting of {Paranoid} and {Bounce}

For all values of {Paranoid} other than 0, this will not accept any B<bounces> from any unknown systems.

{Bounce} will not be defined if mail is from permitted systems.

=back

=cut
push @EXPORT, "check_data";
sub check_data
{
    rule <<RULE;
Scheck_data
GLOBAL A
TEST SANE(Local_check_relay, Local_check_mail)
TEST V(NA)
TEST D({Bounce}is.FOUND) 
TEST D({Paranoid}1) E(na)
TEST D({GoodRelay}is.FOUND) F(na)
TEST SANE(Local_check_relay, Local_check_mail)
TEST D({Paranoid}0)
FIND Bounce
R £+.FOUND      £: MACRO{ £1
    TEST D({Paranoid}0, {GoodRelay}is.FOUND) V(NA)
    TEST D({Paranoid}1, {GoodRelay}is.FOUND) F(NA)
    TEST D({Paranoid}0, {GoodRelay}is.not) V(NA)
    TEST D({Paranoid}1, {GoodRelay}is.not) E(NA)
    R £*            £: £&{Paranoid}
    R 0             £@ 0
    IS FOUND GoodRelay £@ £1
    dnl all other values for Paranoid will not accept bounces from strangers dnl
    REFUSED £#error £@ 5.1.8 £: "550 SPAM BOUNCES ARE REFUSED, WE DO NOT KNOW YOU, GO AWAY"
}MACRO
RULE
}

=head2 screen_header(@_)        GLOBAL A

=over 4

HEADER LINES

All this does at the moment is check the following header statements

B<Received:>

=over 4 

=over 24

=item with HTTP

HTTP webmail is so B<insecure> and open to abuse, that we have taken the position that we will no longer accept mail from systems that have received mail from a system that received mail vi HTTP.

Those systems already in the B<mail4> database (relays who fail one or more tests, and who you want to recieve mail from) are excempt from this, and so even if they have received mail with HTTP it will be accepted.

Otherwise this is controlled by the level of {Paranoid} 0 or 1 will accept, otherwise not.

=item by DOMAIN

some spammers pass other tests but show themselves by pretending to send from one of our domains! 

=back

=back

B<From:>

=over 4

B<ALL> users must conform, they must not B<FAKE> their "From:" header to show something other than the B<FROM> used in the mail discussion with the mail host. No exceptions! A considerable amount of SPAM comes from mailers that allow their users to send SPAM. It is in your own intrest to stop your users sending SPAM as you are very likly to be registered as a SPAMMER and be blocked by mail servers the world over.

=back

B<Reply-to:>

=over 4

This uses the standard Sendmail B<access> database to check that the reply is not to to an address that you would not accept mail from.

The entry in the B<access> file would be 

=over 2

From:#####    ERROR:"550 We do not accept mail from you"

=back

Where ##### is tha banned server address. Many spammers are using B<yahoo> addresses, from systems that have nothing todo with B<yahoo>! So B<From:> is not really the best way to stop these.

Where e-mail has been received from a B<{RestrictedHost}> such as yahoo or hotmail, the B<Reply-to:> must be the same as B<f>.

Where a B<Reply-to:> of hotmail or yahoo is used by anyone else it is refused!

=back

Other tests are possible. But on balance we think that these should be left to a 2nd level e-mail system that can take a closer look with both B<anti virus> and something like B<SpamAssassin>, it should be noted that these systems tend to be rather slow, so should never be run on a busy front line e-mail system under constant attack.
If you wish additional rules may be supplied, these will be tacked on the end of the B<SScreenHeader> definition.

=back

=cut
push @EXPORT, "screen_header";
sub screen_header
{
    my $tail = <<RULE;
}MACRO
RULE
    my @extra = (scalar @_)?((@_,$tail)):(($tail));
    my $screen_header = <<RULE;
GLOBAL A
TEST SANE(Local_check_relay,Local_check_mail)
R £*    £: MACRO{ £1
    TEST D({hdr_name}NotReceived) V(NA)
    TEST D({hdr_name}Received,{currHeader}na by localhost na and "not so much") V(NA)
    TEST D({hdr_name}Received,{currHeader}na by your.localhost na yack yack end) V(NA)
    R £*            £: £&{hdr_name}
    R Received      £@ MACRO{ £&{currHeader}
        OPTION NOMASH
        TEST D({currHeader}na by www.celmorlauren.com na) V(anon did not find this,bog standard mailer)
        # internal systems should be ok
        IS FOUND GoodRelay £@ £1
        R £*                £: £(ReceivedBy £&{currHeader} £)    
        # at least "ReceivedBy" seems to return tokens.
        # external systems must be checked
        R £*.FOUND          £: MACRO{ £1 # claiming to be one of our domains?
            OPTION MASH 2
            TEST AUTO(F OUR HELO, V OK HELO)
            # due to could not get regex to do anything usefull,
            # and the external socks stuff not being ready yet, 
            # this mess is to cope with domains with "by" in their names!
            # though if you have 'with' dotted in your domain names it will still fail!
            # celmorlauren do not have any problem named domains
            R £* by. £* by. £* by. £* by. £* by £+.£+ with £+      £: £6.£7
            R £* by. £* by. £* by. £* by £+.£+ with £+        £: £5.£6
            R £* by. £* by. £* by £+.£+ with £+      £: £4.£5
            R £* by. £* by £+.£+ with £+        £: £3.£4
            R £* by £+.£+ with £+          £: £2.£3
            R £*                £: £(SelfMacro {MashTempC} £@ £1 £) £1
            dnl localhost is to be expected, most liky as the first server? dnl
            R localhost         £@ £&{MashSelf}
            R £* localdomain    £@ £&{MashSelf}
            R £* local          £@ £&{MashSelf}
            R £* lan            £@ £&{MashSelf}
            dnl  standard private domains are assumed to be ok dnl
            R 192.168.£+        £@ £&{MashSelf}
            R 172.16.£+         £@ £&{MashSelf}
            R 10.£+             £@ £&{MashSelf}
            dnl now check for our systems
            R £* £=w               £@ £&{MashSelf}.FOUND
            R £* £={VirtHost}      £@ £&{MashSelf}.FOUND
            R £* £=R               £@ £&{MashSelf}.FOUND
RULE
    if ( $mail8_setup->{'PerlHelpers'} )
    {
        $screen_header .= <<RULE;
            R £*                £: £(mail2db £1 £: £1 £)          mail2 DB
            R £+.FOUND          £@ £&{MashSelf}.FOUND
            R £*                £: £(mail1db £1 £: £1 £)          mail1 DB
            R £+.FOUND          £@ £&{MashSelf}.FOUND
RULE
    }
    $screen_header .= <<RULE;
        }MACRO
        IS THISFOUND AND REFUSED £#error £@ 5.1.1 £: "553 SPAM mailing loop? Received: by " £&{MashTempC}
        IS FOUND BadRelay £@ £1
        # Paranoid? then webmail should also be refused
        R £*    £: £&{Paranoid}
        R 0     £@ 0       Not paranoid
        R 1     £@ 1       slighty
        R £*    £: £(ReceivedWithHTTP £&{currHeader} £)    
        IS THISFOUND AND REFUSED £#error £@ 5.1.1 £: "553 SPAM? Web-Mail not accepted here: " £1
    }MACRO
    R From      £@ MACRO{ £&{currHeader}
        OPTION NOMASH
        # everyone using this system must conform, as even our own users may be guilty of trying to send spam
        TEST D({mail_addr}ian, fian\@daisymoo.com, {currHeader}Ian McNulty <ian\@daisymoo.com>) V(NA)
        TEST D({mail_addr}ian\@daisymoo.com, fian\@daisymoo.com, {currHeader}Ian McNulty <ian\@daisy.com>) E(Not Local)
        TEST D({mail_addr}ian, fian\@daisymoo.com, {currHeader}"Ian McNulty"<ian\@daisy.com>) E(Local)
        TEST D({mail_addr}ian, fian\@daisymoo.com, {currHeader}Ian McNulty<ian\@daisy.com>) E(Local)
        TEST D({mail_addr}ian, fian\@daisymoo.com, {currHeader}<ian\@daisy.com>) E(Local)
        TEST D({mail_addr}ian\@daisymoo.com, fian\@daisymoo.com, {currHeader}ian\@daisy.com) E(Not Local)
        TEST D({mail_addr}ian, fian\@daisymoo.com, {currHeader}ian\@daisymoo.com) V(NA)
        TEST D({mail_addr}i.a-n, fi.a-n\@daisy-moo.com, {currHeader}i.a-n\@daisy-moo.com) V(NA)
        TEST D({mail_addr}i.a_n, fi.a_n\@daisy-moo.com, {currHeader}i.a_n\@daisy-moo.com) V(NA)
        # problem systems such as CPAN Pause, which we want to receive mail from
        IS FOUND BadRelay £@ £1
        R £*            £: £(CleanFrom £&{currHeader} £)    
        R £*            £: £(SelfMacro {MashTempC} £@ £1 £) £1
        # if contains From should be ok
        R £&f       £@ £&{MashTempC}
        REFUSED
        # is user external? in which case f & mail_addr will be the same
        R £*        £: £&{mail_addr}
        R £&f       £#error £@ 5.1.1 £: "553 SPAM? From: " £&f " claimed to be " £&{MashTempC} " from header line: (From: " £&{currHeader} " )"
        # internal user, who needs their bottom smacked
        R £*        £#error £@ 5.1.1 £: "553 SPAM? From: INTERNAL USER! " £&{mail_addr} " claimed to be " £&{MashTempC} " from header line: (From: " £&{currHeader} " )"
    }MACRO
    R Reply-to     £@ MACRO{ £&{currHeader}
        OPTION NOMASH
        NOTEST AUTO
        # problem systems such as CPAN Pause, which we want to receive mail from
        IS FOUND BadRelay £@ £1
        R £*            £: £(CleanFrom £&{currHeader} £)    
        R £*            £: £(SelfMacro {MashTempC} £@ £1 £) £1
        R £*            £: From:£1
        R £*            £: £(stdaccessdb £1 £: £1 £)          standard access database
        IS THISFOUND AND REFUSED £#error £@ 5.1.1 £: "553 SPAM REFUSED ! From: " £&f " used a Reply-to: address of " £&{MashTempC} " from header line: (Reply-to: " £&{currHeader} " )"
        R £*            £: £&{MashTempC}
        R £*            £: £(CleanAtHost £1 £)    
        R £*            £: £(CleanHost £1 £)    
        R £*            £: £(SelfMacro {MashTempD} £@ £1 £) £1
        R £*            £: From:£1
        R £*            £: £(stdaccessdb £1 £: £1 £)          standard access database
        IS THISFOUND AND REFUSED £#error £@ 5.1.1 £: "553 SPAM REFUSED ! From: " £&f " used a Reply-to: address of " £&{MashTempD} " from header line: (Reply-to: " £&{currHeader} " )"
        R £*                £: £&{MashTempD}
        R yahoo.£+          £: yahoo.FOUND
        R £+.yahoo.£+       £: yahoo.FOUND
        R hotmail.£+        £: hotmail.FOUND
        R £+.hotmail.£+     £: hotmail.FOUND
        R £+.FOUND          £: MACRO{ £1
            OPTION NOMASH
            TEST D(ftest\@yahoo.com,{RestrictedUser}test\@yahoo.com.FOUND,{currHeader}RestrictedHost)
            TEST D({MashTempC}test\@yahoo.com) V(NA)
            TEST D({MashTempC}notest\@yahoo.com) E(NA)
            TEST D({MashTempC}notest\@hotmail.com) E(NA)
            FIND RestrictedUser
            R £+.FOUND          £: £1
            R £&{MashTempC}     £@ £&{MashTempC}
            REFUSED £#error £@ 5.1.1 £: "553 SPAM REFUSED ! From: " £&f " used a Reply-to: address of " £&{MashTempC} " from header line: (Reply-to: " £&{currHeader} " )"
        }MACRO
RULE

    rule "SScreenHeader", $screen_header,@extra;

# end testing
# HOTMAIL failed too soon, should not have been refused, quite so soon, however sending domain will still be stopped for being too numeric.
    inbuilt_rule <<RULE;
Local_check_relay
TEST SANE(Local_check_relay)
TEST SANE(Local_check_mail) 
TEST D({client_name}bay0-omc2-s32.bay0.hotmail.com, {client_addr}65.54.246.168, {client_resolve}OK)
TEST T(Translate) V(bay0-omc2-s32.bay.hotmail.com 65.54.246.168)
RULE

    inbuilt_rule <<RULE;
Local_check_mail
TEST D(sbay0-omc2-s32.bay0.hotmail.com)
TEST D(fmrjonas_robert75\@hotmail.com) E(NA) 
RULE

}


=head1 HISTORY

B<Versions>

=over 5

=item 0.1

Nov 2006    1st version, pure sendmail M4 hack, using plug-in Perl programs.

=item 0.2

25 August, this 1st CPAN M4 hack script, original script split into, this B<Mail8> and B<Utils> for creation and testing.

21 Sept 2007 Released onto CPAN. 

B<Amendments to release version>

Most changes are recorded in B<Utils> as this really was a messy hack conversion, with many revisions required to get something that worked.

=over 3

=item 22 Sept 2007

added this HISTORY

mail8 DataBase file refrences (apart from B<mail4>) have been removed, and will now only added if the {Perl_Helpers} have been installed, currently these scripts are not available, their future will be decided later.

mail8_zombie now included in distro, install it to get the full benifits

=back

=item 0.21

22 September 2007 CPAN Release

B<Amendments to release version>

=over 3

=item 23 September 2007

B<sendmail> works fine in command line test mode. But complains of "too many long names" when this is installed and run, "sendmail" assigns on the "fly" macro names!????!!!!?.

A limit of 96 (8 Bit limits?) is really too constrictive.

=over 3

=item *

1st try now using {MashTemp} instead of {MashStack}, saves some, so sendmail falls over a little later!

=item *

OPTION NOMASH used where possible, also "OPTION MASH 1" to conserve name space in other places, this and changes to B<Utils> have removed 20 names

=back

=back

=item 0.22

23 September 2007 CPAN Release

B<Amendments to release version>

=over 3

=item 23 Sept 2007

on SuSE 10.1 (remastered) sendmail version 8.13.6, complained of an unbalanced E<gt>, not the fault of the sender but a macro? why did sendmail then decide to 553???, had no problem with the same code on SuSE 9.3 sendmail 8.13.3?

So a single line added and hopefully all will be well, and this system can finally protect celmorlauren, we suffer quite a lot of spam, so we should be able to spot any other weakness in the code.

=back

=item 0.23

23 September 2007 CPAN Release

B<Amendments to release version>

=over 3

=item 24 Sept 2007

it appears we have caused a problem with the changes above, HELO's are failing when they should not.
added failed hosts to test data, to try and ensure it does not happen again.

=back

=item 0.24

24 September 2007 CPAN Release

B<Amendments to release version>

=over 3

=item 24 Sept 2007

Patch required, spammer whose domain matched who they said they were, was not put through the numeric zombie check as expected, a Fix broke the intended logic, test data added to mail8.

=back

=item 0.25

24 September 2007 CPAN Patch Release

B<Amendments to release version>

=over 3

=item 25 Sept 2007

HELO checking for {daemon_addr} added, should have there already (whoops sorry), however numeric addresses will not resolve anyway, so CPAN patch release delayed untill more serious problems encountered.
Develelpment on B<test_cgi> will cause further amendments, so will wait for that before release.

=item 30 Sept 2007

ref to "network associates" changed to "network solutions", just been amending my "domains", so spotted the error, as I tend to look for them using google. Other typo's will be corrected when found.

Noted rather more spam than normal has been arriving at my mail system, all fake MX's have been stopped as expected, but a few from Open Relays get through this (the 1st level filter), only to fail at the 2nd level email system. In an attempt to allow the 2nd level email system to sleep more, and only have to deal with real e-mail.

=over 3

=item 1

Header B<From:> checked is the same as B<f> or at least contains B<f>. Failures are {Refused}, no exceptions all users are checked!

=item 2

Header B<Recieved:> check now sets {Refused} for failures. {GoodRelay} hosts are exempted from this check.

=item 3

Found during testing, that mail only worked once only! corrections made to ensure essential macros are set up again, and others use sendmail macros such as B<f> instead of supplied values, which may be the from address 1st time round, 2nd and more times it is (conneted as HOST & IP)?!

=back

=back

=item 0.26

30 September 2007 CPAN Patch Release

B<Amendments to release version>

=over 3

=item 30 Sept 2007

noted that the B<Pause> upload server falls foul of the just uploaded system, so the B<mail4.db> will now permit those listed to skip all checks, however local users will not be allowed to skip mail FROM checks.

=back

=item 0.27

30 September 2007 CPAN Patch Release

B<Amendments to release version>

=over 3

=item 01 Oct 2007

sendmail needs more free "long names" for its own use, this had been using only 21 "long names", Sendmail::M4::Utils has been modified to provide routines that can use just one "long name" {MashFound}, so this will be recoded as required as the {macros} used before can no longer be direcltly accessed. Total saving minus 5, leaving 16.

Also found 2 other names, that did not need persistance, these now MashTempC & D

=back

=item 0.28

02 October 2007 CPAN Patch Release

B<Amendments to release version>

=over 3

=item 03 Oct 2007

noticed that header line "From:" where email address not included in E<lt> E<gt> brackets, will not match when should.

=back

=item 0.29

03 October 2007 CPAN Patch Release

B<Amendments to release version>

=over 3

=item 03 Oct 2007

the Received: header checking does not work, and currently nothing tried makes it work, fine in test mode. But as headers are not tokenised with sendmail 8.13, can not do anthing usefull with the supplied tools.

So currently does nothing, just returns.

Fix must wait for Sendmail::M4::mail8_daemon and its worker module Sendmail::M4::Mail8_daemon.pm, which will now do more than originally designed to do.

Patch required to remove useless error messages from the logs.

=back

=item 0.30

03 October 2007 CPAN Patch Release

B<Amendments to release version>

=over 3

=item 05 Oct 2007

noted that dots and dashs did not work in From: header checker for names, fixed. However underscores  will still not work

=back

=item 0.31

05 October 2007 CPAN Patch Release

B<Amendments to release version>

=over 3

=item 08 Oct 2007

Noted that lots of SPAM has Reply-to: yahoo or hotmail, system will now check sendmails standard B<access> database for B<From:####> where #### is system we do not accept mail from. SPAMMERS are now concentrating on finding open-relays or other poorly setup and vunerable systems, many of which seem to be B<Exim> servers. These are of course blocked on their third SPAM or sometimes on their first if they are an open-relay. SPAM detection being done by the second level e-mail system, the CPAN version of the interface between the two systems is currently being re-writen, and we will make it available soon.

=back

=item 0.32

08 October 2007 CPAN Patch Release

B<Amendments to release version>

=over 3

=item 10 Oct 2007

Noted that the bulk of spam that has got through to the second level filter, has originated from WEB mail, which will now be refused with a {Paranoid} setting of 2 or more.

Received: DOMAIN name checking for phoney received from # by # now working, at least for us at the 1st level.

=item 12 Oct 2007,

yahoo and hotmail domains are the Reply-to: and From: names of choice for spammers. ALL sending from domains that have nothing to do with yahoo or hotmail claiming to relay their domains, will be now stopped. Hard coded as these are so well known!    

Documentation clean-up. HISTORY moved to end of document.

=back

=item 0.33

12 October 2007 CPAN Patch Release

B<Amendments to release version>

=over 3

=item 14 Oct 2007

Whoops, a hotmail mail was refused too early due to a typo, strung several tests together at the end with the unlucky users connection details, problem fixed.

Corrected version will run on the mail server, before it is uploaded.

=back

=item 0.34

14 October 2007 CPAN Patch Release

B<Amendments to release version>

=over 3

=back

=cut

1;
