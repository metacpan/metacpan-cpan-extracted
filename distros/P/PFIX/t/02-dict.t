#!/usr/bin/perl -I../lib

use Test::More tests => 34;
use Data::Dumper;
diag("Testing PFIX Dictionary methods.");

use_ok('PFIX::Dictionary') || print "Bail out!\n";

ok( PFIX::Dictionary::load('FIX44'), "PFIX::Dictionary::load('FIX44')" );

my $d = PFIX::Dictionary->new();

ok( $d->getMessageName('D')              eq 'NewOrderSingle', "getMessageName(D) return NewOrderSingle" );
ok( $d->getMessageName('NewOrderSingle') eq 'NewOrderSingle', "getMessageName(NewOrderSingle) return NewOrderSingle" );
ok( !defined $d->getMessageName('BooBoo'), "getMessageName(booboo) is undef" );

ok( $d->getMessageMsgType('D')              eq 'D', "getMessageMsgType(D) return D" );
ok( $d->getMessageMsgType('NewOrderSingle') eq 'D', "getMessageMsgType(NewOrderSingle) return D" );
ok( !defined $d->getMessageMsgType('BooBooBoo'), "getMessageMsgType(boobooboo) is undef" );
ok( $d->isFieldInHeader('MsgSeqNum') == 1,       "isFieldInHeader(MsgSeqNum) returns 1" );
ok( $d->isFieldInHeader('ClOrdID') == 0,         "isFieldInHeader(ClOrdId) returns 0" );
ok( $d->isFieldInHeader(34) == 1,                "isFieldInHeader(34) returns 1" );
ok( $d->isFieldInHeader(11) == 0,                "isFieldInHeader(11) returns 0" );
ok( $d->isFieldInHeader('HopCompID') == 1, "isFieldInHeader(HopCompID) returns 1 (it's in the NoHops group in the header)" );

ok( $d->isFieldInMessage( 'D',              'ClOrdID' ) == 1,          "isFieldInMessage(D,ClOrdID) returns 1" );
ok( $d->isFieldInMessage( 'D',              'Commission' ) == 1,       "isFieldInMessage(D,Commission) returns 1" );
ok( $d->isFieldInMessage( 'D',              'NoAllocs' ) == 1,         "isFieldInMessage(D,NoAllocs) returns 1" );
ok( $d->isFieldInMessage( 'D',              'NestedPartyID' ) == 1,    "isFieldInMessage(D,NestedPartyID) returns 1" );
ok( $d->isFieldInMessage( 'D',              'NestedPartySubID' ) == 1, "isFieldInMessage(D,NestedPartySubID) returns 1" );
ok( $d->isFieldInMessage( 'D',              'xyxyxy' ) == 0,           "isFieldInMessage(D,xyxyxy) returns 0" );
ok( $d->isFieldInMessage( 'D',              'NoLegs' ) == 0,           "isFieldInMessage(D,NoLegs) returns 0" );
ok( $d->isFieldInMessage( 'NewOrderSingle', 11 ) == 1,                 "isFieldInMessage(NewOrderSingle,11) returns 1" );


ok ($d->isGroup( 'NoAllocs') == 1, 'isGroup(NoAllocs) returns 1');
ok ($d->isGroup( 'Symbol') == 0, 'isGroup(Symbol) returns 0');

ok ($d->isFieldInGroup('NewOrderSingle','NoAllocs','AllocAccount')==1, 'isFieldInGroup(NewOrderSingle,NoAllocs,AllocAccount) returns 1');
ok ($d->isFieldInGroup('D',78, 79)==1, 'isFieldInGroup(D,78,79) returns 1');
ok ($d->isFieldInGroup('D',78, 78)==0, 'isFieldInGroup(D,78,78) returns 0');
ok ($d->isFieldInGroup('NewOrderSingle','NoAllocs','NestedPartyID')==1, 'isFieldInGroup(NewOrderSingle,NoAllocs,NestedPartyID) returns 1');
ok ($d->isFieldInGroup('NoSuchMessage','NoAllocs','NestedPartyID')==0, 'isFieldInGroup(NoSuchMessage,NoAllocs,NestedPartyID) returns 0');
ok ($d->isFieldInGroup('NewOrderSingle','NoSuchGroup','NestedPartyID')==0, 'isFieldInGroup(NewOrderSingle,NoSuchGroup,NestedPartyID) returns 0');
ok ($d->isFieldInGroup('NewOrderSingle','NoAllocs','NoSuchField')==0, 'isFieldInGroup(NewOrderSingle,NoAllocs,NoSuchField) returns 0');
ok ($d->isFieldInGroup('NewOrderSingle','NoAllocs','ClOrdID')==0, 'isFieldInGroup(NewOrderSingle,NoAllocs,ClOrdID) returns 0');
ok ($d->isFieldInGroup('NewOrderSingle','NoPartyIDs','PartyID')==1, 'isFieldInGroup(NewOrderSingle,NoPartyIDs,PartyID) returns 1');
ok ($d->isFieldInGroup('NewOrderSingle','NoPartySubIDs','PartySubID')==1, 'isFieldInGroup(NewOrderSingle,NoPartySubIDs,PartySubID) returns 1');
ok ($d->isFieldInGroup('NewOrderSingle','NoPartySubIDs','PartyID')==0, 'isFieldInGroup(NewOrderSingle,NoPartySubIDs,PartyID) returns 0');

my %a;
#@a=$d->getMessageOrder('Logon');
%a=$d->getMessageOrder('Advertisement');
#@a=$d->getMessageOrder('Advertisementttt');
print Dumper(\%a);

print "The end!\n";
1;