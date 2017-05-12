#!/usr/bin/perl -w
# $File: //depot/libOurNet/BBS/t/6-MailBox.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 1 $ $DateTime: 2002/06/11 15:35:12 $

use strict;
use Test::More tests => 3;

require_ok('OurNet::BBS');
my $BBS = OurNet::BBS->new({
    backend => 'MailBox',
    bbsroot => '.'
});

isa_ok($BBS, 'OurNet::BBS');
is(ref($BBS), $BBS->module('BBS'), 'constructor');

__END__
