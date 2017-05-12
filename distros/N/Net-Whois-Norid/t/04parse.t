use Test::More tests => 8;
use Net::Whois::Norid;
use strict;

my $entry = do { local $/; <DATA> };

my $whois=Net::Whois::Norid->new();
$whois->_parse($entry);
is($whois->get('country'),'NORWAY', 'normal');
is($whois->get('CoUnTry'),'NORWAY', 'mixed case');
is($whois->CoUnTry,'NORWAY', 'mixed case function');
is($whois->get('domain_name'),'thefeed.no','spaces');
is($whois->get('norid_handle'),'GSRL1O-NORID','uppercase');
is($whois->get('zone_c_handle'),'ROLE122R-NORID','-');
is($whois->get('nameserver_handle'),"DNS151H-NORID\nDNS106H-NORID",'duplicates');
is($whois->get('created'),undef, 'dont parse created/last_updated');


__DATA__

% Kopibeskyttet, se http://www.norid.no/domenenavnbaser/whois/kopirett.html
% Rights restricted by copyright. See http://www.norid.no/domenenavnbaser/whois/kopirett.en.html

Domain Information

Domain Name................: thefeed.no
Organization Handle........: GSRL1O-NORID
Registrar Handle...........: REG64-NORID
Legal-c Handle.............: MR258P-NORID
Tech-c Handle..............: ROLE122R-NORID
Zone-c Handle..............: ROLE122R-NORID
Nameserver Handle..........: DNS151H-NORID
Nameserver Handle..........: DNS106H-NORID

Additional information:
Created:         2002-10-30
Last updated:    2005-05-03

NORID Handle...............: GSRL1O-NORID
Organization Name..........: GEIR SIGMUND RAMBERG LILLEHAMMER
Organization Number........: 981809270
Post Address...............: Storgaten 86
Postal Code................: N-2615
Postal Area................: Lillehammer
Country....................: NORWAY
Phone Number...............: +47 61 25 78 57
Fax Number.................: 
Email Address..............: m@songsolutions.no

Additional information:
Last update:     2002-10-30
