#===============================================================================
#  DESCRIPTION:  test for Net::IP::Identifier::Binode.pm
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  11/11/2014 04:46:22 PM
#===============================================================================

use 5.008;
use strict;
use warnings;


use Test::More
    tests => 16;

# VERSION

my $NIIB = 'Net::IP::Identifier::Binode';
use_ok $NIIB;   # the module under test
my $n0 = $NIIB->new;

isa_ok $n0, $NIIB,                        'create top node';
is $n0->zero, undef,                      'no zero subnode';
is $n0->one,  undef,                      'no one subnode';

my @return;
sub path_payloads {   # callback to collect payloads along path
    push @return, $_[0] if ($_[0]->payload);
    return 0;   # always continue
}

my $node = $n0->construct('00');
isa_ok $node, $NIIB,                     'constructed a Binode at 00';
isa_ok $n0->zero, $NIIB,                 'level one child node(1) set';
is     $n0->one, undef,                  'level one child node(0) not set';
isa_ok $n0->zero->zero, $NIIB,           'level two child node(1)';
$node->payload('abc');
is_deeply $n0->zero->zero->payload, ('abc'), 'level two child node payload';

$node = $n0->construct('011');
isa_ok $node, $NIIB,                     'constructed a Binode at 011';
$node->payload('XyZ');
is_deeply $n0->zero->one->one->payload, ('XyZ'), 'level three child node payload';

@return = ();
$n0->follow('00', \&path_payloads);
is        $return[0]->payload, 'abc', 'level 2 child intact';
@return = ();
$n0->follow( '011', \&path_payloads);
is        $return[0]->payload, 'XyZ', 'level 3 child intact';
$node = $n0->construct('0001');
$node->payload('987');
@return = ();
$n0->follow('0001', \&path_payloads);
is scalar @return, 2,                  '2 return items';
is        $return[0]->payload, 'abc',  '   item 1 correct';
is        $return[1]->payload, '987',  '   item 2 correct';


