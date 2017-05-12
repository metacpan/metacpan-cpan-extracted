#!/usr/bin/env perl 
use 5.8.0;
use strict;
use warnings;

use lib '../lib';
use Data::Dumper;

use JSON;
use NetSDS::Const::Message;
use NetSDS::Message;
use NetSDS::Message::SMS;
use NetSDS::Util::String;
use NetSDS::Util::Convert;

my $msg = NetSDS::Message::SMS->new(
	src_addr => '1234',
);

#$msg->header('X-Lite', '00123123');
#$msg->header('Lite', str_encode 'Зюка левая');

$msg = $msg->reply();

$msg->udh( conv_hex_str('050102030405') );
print $msg->errstr;
$msg->ud( 'Z' x 140 );
warn conv_str_hex( $msg->message_body );

#print Dumper($msg->reply);

my $j = JSON->new();
$j->pretty(1);
$j->utf8(1);
#$j->allow_blessed(1);
#$j->convert_blessed(1);

print "Length: " . bytes::length( $j->encode( $msg->unbless ) ) . "\n";

print "ESM: " . $msg->esm_class() . "\n";

$msg->mclass(1);
$msg->coding(COD_UCS2);

print "DCS: " . $msg->dcs() . "\n";

#print Dumper($msg);

my $jmsg = $j->encode( $msg->unbless() );
#print $jmsg;

my $new = bless $j->decode($jmsg), 'NetSDS::Message::SMS';
#print Dumper($new);
print $new->dcs();

$msg->text('Welcome', 2);
print Dumper($msg);
print conv_str_hex($msg->ud());

my @sp = create_long_sm('zuka'x50, 0);

print Dumper(\@sp);
print conv_str_hex($sp[0]->udh);
1;
