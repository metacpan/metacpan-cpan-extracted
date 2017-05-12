#!perl

use strict;
use warnings;
use Test::More tests => 5;

use Passwd::Keyring::OSXKeychain;

is(
    Passwd::Keyring::OSXKeychain::_parse_password_from_find_output(<<'END'),
keychain: "/Users/myUser/Library/Keychains/login.keychain"
class: "genp"
attributes:
    0x00000007 <blob>="server.com"
    0x00000008 <blob>=<NULL>
    "acct"<blob>="userIDtoServer.com"
    "cdat"<timedate>=0x33313024C53131693134253345315F00  "20041201142351A\123"
    "crtr"<uint32>=<NULL>
    "cusi"<sint32>=<NULL>
    "desc"<blob>=<NULL>
    "gena"<blob>=<NULL>
    "icmt"<blob>=<NULL>
    "invi"<sint32>=<NULL>
    "mdat"<timedate>=0x33313024C53131693134253345315F00  "20041201142351A\123"
    "nega"<sint32>=<NULL>
    "prot"<blob>=<NULL>
    "scrp"<sint32>=<NULL>
    "svce"<blob>="server.com"
    "type"<uint32>=<NULL>
password: "myPassword"
END
    "myPassword",
    "simple password parse");
        
is(
    Passwd::Keyring::OSXKeychain::_parse_password_from_find_output(<<'END'),
keychain: "/Users/User/Library/Keychains/login.keychain"
class: "inet"
attributes:
0x00000007 <blob>="192.168.x.x"
0x00000008 <blob>=<NULL>
"acct"<blob>="User"
"atyp"<blob>=<NULL>
"cdat"<timedate>=0x32303131304356876580313734375A0 0 "20110129201747Z\000"
"crtr"<uint32>=<NULL>
"cusi"<sint32>=<NULL>
"desc"<blob>="Netzwerkkennwort"
"icmt"<blob>=<NULL>
"invi"<sint32>=<NULL>
"mdat"<timedate>=0x32303131308970393230123430305A0 0 "20110209203400Z\000"
"nega"<sint32>=<NULL>
"path"<blob>="User"
"port"<uint32>=0x00000000
"prot"<blob>=<NULL>
"ptcl"<uint32>="smb "
"scrp"<sint32>=<NULL>
"sdmn"<blob>=<NULL>
"srvr"<blob>="192.168.x.x"
"type"<uint32>=<NULL>
password: "passwort"
END
    "passwort",
    "simple password parse");

is(
    Passwd::Keyring::OSXKeychain::_parse_password_from_find_output(<<'END'),
keychain: "/Users/myUser/Library/Keychains/login.keychain"
class: "genp"
attributes:
    0x00000007 <blob>="server.com"
    0x00000008 <blob>=<NULL>
    "acct"<blob>="userIDtoServer.com"
    "cdat"<timedate>=0x33313024C53131693134253345315F00  "20041201142351A\123"
    "crtr"<uint32>=<NULL>
    "cusi"<sint32>=<NULL>
    "desc"<blob>=<NULL>
    "gena"<blob>=<NULL>
    "icmt"<blob>=<NULL>
    "invi"<sint32>=<NULL>
    "mdat"<timedate>=0x33313024C53131693134253345315F00  "20041201142351A\123"
    "nega"<sint32>=<NULL>
    "prot"<blob>=<NULL>
    "scrp"<sint32>=<NULL>
    "svce"<blob>="server.com"
    "type"<uint32>=<NULL>
password: 
END
    "",
    "empty password parse");

is(
    Passwd::Keyring::OSXKeychain::_parse_password_from_find_output(<<'END'),
keychain: "/Users/myUser/Library/Keychains/login.keychain"
class: "genp"
attributes:
    0x00000007 <blob>="server.com"
    0x00000008 <blob>=<NULL>
    "acct"<blob>="userIDtoServer.com"
    "cdat"<timedate>=0x33313024C53131693134253345315F00  "20041201142351A\123"
    "crtr"<uint32>=<NULL>
    "cusi"<sint32>=<NULL>
    "desc"<blob>=<NULL>
    "gena"<blob>=<NULL>
    "icmt"<blob>=<NULL>
    "invi"<sint32>=<NULL>
    "mdat"<timedate>=0x33313024C53131693134253345315F00  "20041201142351A\123"
    "nega"<sint32>=<NULL>
    "prot"<blob>=<NULL>
    "scrp"<sint32>=<NULL>
    "svce"<blob>="server.com"
    "type"<uint32>=<NULL>
password: $4AC3BC7267C485"lalala"
END
    "Jürgą",
    "hexified password parse");

is(
    Passwd::Keyring::OSXKeychain::_parse_password_from_find_output(<<'END'),
keychain: "/Users/myUser/Library/Keychains/login.keychain"
class: "genp"
attributes:
    0x00000007 <blob>="server.com"
    0x00000008 <blob>=<NULL>
    "acct"<blob>="userIDtoServer.com"
    "cdat"<timedate>=0x33313024C53131693134253345315F00  "20041201142351A\123"
    "crtr"<uint32>=<NULL>
    "cusi"<sint32>=<NULL>
    "desc"<blob>=<NULL>
    "gena"<blob>=<NULL>
    "icmt"<blob>=<NULL>
    "invi"<sint32>=<NULL>
    "mdat"<timedate>=0x33313024C53131693134253345315F00  "20041201142351A\123"
    "nega"<sint32>=<NULL>
    "prot"<blob>=<NULL>
    "scrp"<sint32>=<NULL>
    "svce"<blob>="server.com"
    "type"<uint32>=<NULL>
password: $616c61206d61206b6f7461
END
    "ala ma kota",
    "hexified password parse");

