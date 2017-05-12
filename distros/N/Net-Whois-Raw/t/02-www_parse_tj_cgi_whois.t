#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;
use Net::Whois::Raw::Common;
my $string = do { local $/; <DATA> };

ok !utf8::is_utf8( $string ), 'make sure it\'s bytes';

use Data::Dumper;

my $got = Net::Whois::Raw::Common::parse_www_content( $string, 'tj', 'http://www.nic.tj/cgi/whois?domain=get', 1 );
my $expected = qq{
domain name get.tj
description \x{420}\x{435}\x{433}\x{438}\x{441}\x{442}\x{440}\x{430}\x{446}\x{438}\x{44f} \x{434}\x{43e}\x{43c}\x{435}\x{43d}\x{43d}\x{44b}\x{445} \x{438}\x{43c}\x{435}\x{43d}
submitted by
company \x{41e}\x{41e}\x{41e} \"\x{410}\x{440}\x{437}\x{43e}\x{43d}\", Alpha Dimension Group
address 734000, \x{433}. \x{414}\x{443}\x{448}\x{430}\x{43d}\x{431}\x{435}, \x{43f}\x{440}. \x{420}\x{443}\x{434}\x{430}\x{43a}\x{438} 90, \x{43e}\x{444}\x{438}\x{441} 2
phone (992 48) 7016444
e-mail corp\@get.tj
domain owner
name \x{41e}\x{41e}\x{41e} \"\x{410}\x{440}\x{437}\x{43e}\x{43d}\", Alpha Dimension Group
address:
street \x{43f}\x{440}. \x{420}\x{443}\x{434}\x{430}\x{43a}\x{438} 90, \x{43e}\x{444}\x{438}\x{441} 2
city \x{414}\x{443}\x{448}\x{430}\x{43d}\x{431}\x{435}
state \x{422}\x{430}\x{434}\x{436}\x{438}\x{43a}\x{438}\x{441}\x{442}\x{430}\x{43d}
administrative contact
name \x{41e}\x{41e}\x{41e} \"\x{410}\x{440}\x{437}\x{43e}\x{43d}\", Alpha Dimension Group
address:
street \x{43f}\x{440}. \x{420}\x{443}\x{434}\x{430}\x{43a}\x{438} 90, \x{43e}\x{444}\x{438}\x{441} 2
city \x{414}\x{443}\x{448}\x{430}\x{43d}\x{431}\x{435}
postal code 734000
state \x{422}\x{430}\x{434}\x{436}\x{438}\x{43a}\x{438}\x{441}\x{442}\x{430}\x{43d}
phone (992 48) 7016444
fax (992 48) 7016444
e-mail corp\@get.tj
technical contact
name \x{41e}\x{41e}\x{41e} \"\x{410}\x{440}\x{437}\x{43e}\x{43d}\", Alpha Dimension Group
address:
street \x{43f}\x{440}. \x{420}\x{443}\x{434}\x{430}\x{43a}\x{438} 90, \x{43e}\x{444}\x{438}\x{441} 2
city \x{414}\x{443}\x{448}\x{430}\x{43d}\x{431}\x{435}
postal code 734000
state \x{422}\x{430}\x{434}\x{436}\x{438}\x{43a}\x{438}\x{441}\x{442}\x{430}\x{43d}
phone (992 48) 7016444
fax (992 48) 7016444
e-mail corp\@get.tj
dns-servers for domain
primary DNS-server:
hostname ns1.ht-systems.ru
ip-address 78.110.50.60
secondary DNS-server:
hostname ns2.ht-systems.ru
ip-address 195.128.51.62
registration data
registrar  GET.TJ
registration date 12 Jul 2007
};

is $got, $expected, 'should match the fixture';

__DATA__
<html>
<head>
<META http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>get.tj</title>
<style type="text/css">
          body       {  }
          td         { vertical-align: text-top;
                       font-family: Arial, Helvetica, sans-serif; font-size: 12px;
                       border-bottom: solid 1px #aaaaaa; }
          .field     { text-transform: capitalize; }
          .subfield  { text-indent: 2ex; }
          .section   { font-weight: bold; text-align: center; text-transform: uppercase;
                       padding-top: 0.2em;  }
          .names     { width: 20ex; }
          .values    { width: 40ex; }
       </style>
</head>
<body>
<div align="center">
<table cellpadding="0" cellspacing="0">
<colgroup>
<col class="names">
<col class="values">
</colgroup>


<tr>
<td class="field">domain name</td><td>get.tj</td>
</tr>

<tr>
<td class="field">description</td><td>Регистрация доменных имен</td>
</tr>


<tr>
<td class="section" colspan="2">submitted by</td>
</tr>

<tr>
<td class="field">company</td><td>ООО &laquo;Арзон&raquo;, Alpha Dimension Group</td>
</tr>

<tr>
<td class="field">address</td><td>734000, г. Душанбе, пр. Рудаки 90, офис 2</td>
</tr>

<tr>
<td class="field">phone</td><td>(992 48) 7016444</td>
</tr>

<tr>
<td class="field">e-mail</td><td>corp@get.tj</td>
</tr>



<tr>
<td class="section" colspan="2">domain owner</td>
</tr>

<tr>
<td class="field">name</td><td>ООО &laquo;Арзон&raquo;, Alpha Dimension Group</td>
</tr>

<tr>
<td class="field">address:</td><td>&nbsp;</td>
</tr>

<tr>
<td class="subfield">street</td><td>пр. Рудаки 90, офис 2</td>
</tr>

<tr>
<td class="subfield">city</td><td>Душанбе</td>
</tr>

<tr>
<td class="subfield">state</td><td>Таджикистан</td>
</tr>




<tr>
<td class="section" colspan="2">administrative contact</td>
</tr>

<tr>
<td class="field">name</td><td>ООО &laquo;Арзон&raquo;, Alpha Dimension Group</td>
</tr>

<tr>
<td class="field">address:</td><td>&nbsp;</td>
</tr>

<tr>
<td class="subfield">street</td><td>пр. Рудаки 90, офис 2</td>
</tr>

<tr>
<td class="subfield">city</td><td>Душанбе</td>
</tr>

<tr>
<td class="subfield">postal code</td><td>734000</td>
</tr>

<tr>
<td class="subfield">state</td><td>Таджикистан</td>
</tr>


<tr>
<td class="field">phone</td><td>(992 48) 7016444</td>
</tr>

<tr>
<td class="field">fax</td><td>(992 48) 7016444</td>
</tr>

<tr>
<td class="field">e-mail</td><td>corp@get.tj</td>
</tr>



<tr>
<td class="section" colspan="2">technical contact</td>
</tr>

<tr>
<td class="field">name</td><td>ООО &laquo;Арзон&raquo;, Alpha Dimension Group</td>
</tr>

<tr>
<td class="field">address:</td><td>&nbsp;</td>
</tr>

<tr>
<td class="subfield">street</td><td>пр. Рудаки 90, офис 2</td>
</tr>

<tr>
<td class="subfield">city</td><td>Душанбе</td>
</tr>

<tr>
<td class="subfield">postal code</td><td>734000</td>
</tr>

<tr>
<td class="subfield">state</td><td>Таджикистан</td>
</tr>


<tr>
<td class="field">phone</td><td>(992 48) 7016444</td>
</tr>

<tr>
<td class="field">fax</td><td>(992 48) 7016444</td>
</tr>

<tr>
<td class="field">e-mail</td><td>corp@get.tj</td>
</tr>



<tr>
<td class="section" colspan="2">dns-servers for domain</td>
</tr>

<tr>
<td class="field">primary DNS-server:</td><td>&nbsp;</td>
</tr>

<tr>
<td class="subfield">hostname</td><td>ns1.ht-systems.ru</td>
</tr>

<tr>
<td class="subfield">ip-address</td><td>78.110.50.60</td>
</tr>


<tr>
<td class="field">secondary DNS-server:</td><td>&nbsp;</td>
</tr>

<tr>
<td class="subfield">hostname</td><td>ns2.ht-systems.ru</td>
</tr>

<tr>
<td class="subfield">ip-address</td><td>195.128.51.62</td>
</tr>




<tr>
<td class="section" colspan="2">registration data</td>
</tr>
<tr>
<td class="field">registrar</td><td> GET.TJ </td>
</tr>



<tr>
<td class="field">registration date</td><td>12 Jul 2007</td>
</tr>



</table>
<br>
<br>
</div>
</body>
</html>
