#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 13;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;

#########################
my $WIDTH = 35;

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
my @tests;

push @tests, [ 'keys1 | val1 # key2 | val2 # Keys3 | val3 # Keys4 | val4 #,1,2,SLSLICE',                                                                                                                                                                                                    '# key2 | val2 # Keys3 | val3 #',  'SLSLICE' ];
push @tests, [ 'keys1 | val1 # key2 | val2 # Keys3 | val3 #,1,SLITEM',                                                                                                                                                                                                                      '# key2 | val2 #',                 'SLITEM' ];
push @tests, [ 'keys1 | val1 # key2 | val2 # Keys3 | val3 #,Keys,SLGREP',                                                                                                                                                                                                                   '# Keys3 | val3 #',                'SLGREP' ];
push @tests, [ 'keys1 | val1 # key2 | val2 # Keys3 | val3 #,Keys,SLGREPI',                                                                                                                                                                                                                  '# keys1 | val1 # Keys3 | val3 #', 'SLGREPI' ];
push @tests, [ ' key1 | a | key2 | b # keys3 | c # Keys4 | A # other | aa # misc | d #,^a$,SLSEARCHALL',                                                                                                                                                                                    'key1',                            'SLSEARCHALL' ];
push @tests, [ '# key1 | a | key2 | b # keys3 | c # Keys4 | A # other | aa # misc | d #,a,SLSEARCHALL',                                                                                                                                                                                     'key1 other',                      'SLSEARCHALL' ];
push @tests, [ 'key1 | a | key2 | b # keys3 | c # Keys4 | A # other | aa # misc | d #,a,SLSEARCHALLI',                                                                                                                                                                                      'key1 Keys4 other',                'SLSEARCHALLI' ];
push @tests, [ '# key1 | val1 # key2 | val2 # Key12 | VAL12 #,key,SLSEARCHALLKEYS',                                                                                                                                                                                                         'val1 val2',                       'SLSEARCHALLKEYS' ];
push @tests, [ '# key1 | val1 # key2 | val2 # Key12 | VAL12 #,key,SLSEARCHALLKEYSI',                                                                                                                                                                                                        'val1 val2 VAL12',                 'SLSEARCHALLKEYSI' ];
push @tests, [ '# .1.3.6.1.2.1.25.4.2.1.2.488 | "termsrv.exe" # .1.3.6.1.2.1.25.4.2.1.2.688 | "Apache.exe" # .1.3.6.1.2.1.25.4.2.1.2.5384 | "aimsserver.exe" # .1.3.6.1.2.1.25.4.2.1.2.2392 | "Apache.exe" # .1.3.6.1.2.1.25.4.2.1.2.2600 | "cpqnimgt.exe" #,Apache\.exe,OIDSEARCHALLVAL',  '688 2392',                        'OIDSEARCHALLVAL' ];
push @tests, [ '# .1.3.6.1.2.1.25.4.2.1.2.488 | "termsrv.exe" # .1.3.6.1.2.1.25.4.2.1.2.688 | "Apache.exe" # .1.3.6.1.2.1.25.4.2.1.2.5384 | "aimsserver.exe" # .1.3.6.1.2.1.25.4.2.1.2.2392 | "apache.exe" # .1.3.6.1.2.1.25.4.2.1.2.2600 | "cpqnimgt.exe" #,Apache\.exe,OIDSEARCHALLVALI', '688 2392',                        'OIDSEARCHALLVALI' ];
push @tests, [ '# .1.3.6.1.2.1.25.4.2.1.7.384 | running # .1.3.6.1.2.1.25.4.2.1.7.688 | running # .1.3.6.1.2.1.25.4.2.1.7.2384 | invalid #,688,2384,2,OIDSEARCHLEAF',                                                                                                                       'running invalid',                 'OIDSEARCHLEAF' ];
push @tests, [ '# leaf.Test0 | running # leaf.test1 | running # Leaf.test | invalid #,Test0,test,2,OIDSEARCHLEAFI',                                                                                                                                                                         'running invalid',                 'OIDSEARCHLEAFI' ];

foreach (@tests) {
    my ( $test, $result, $type ) = @{$_};
    my $ret = rpn($test);
    ok( $ret eq $result, " \t" . t_format( $type, 20 ) . "\t=>\t" . t_format( $test, 70 ) . " = " . ($ret) );
}

sub t_format {
    my $val = shift;
    my $nbr = () = ( $val =~ /#/g );
    my $w   = shift // $WIDTH;
    my $tmp = ' ' x $w;
    substr( $tmp, 0, length($val) + $nbr, $val );
    return $tmp;
}
