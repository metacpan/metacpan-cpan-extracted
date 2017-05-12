# vim: ts=8 et sw=4 sts=4
use lib 't';
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw ref_lost_memory ref_clear);
use Scalar::Util qw(refaddr);
use GrianUtils qw(ref_mem_safe);
use strict;
use warnings;
no warnings 'once';
eval "use Test::More tests=>3;";

our $msg = '
08 00000003 0006 6c656e677468 00 4008000000000000
0001 30 02 0003 6e6574 0001 31 0200056c6f67696e0001
320300067469636b65740200204c614a6d7a586e6945
666f5167476b66706e566c5672647964745372534d50
4200046d61696c020009796140746f682e7275 000009
000009
';
$msg=~s/\W+//g;
our $VAR1 = [
          'net',
          'login',
          {
            'mail' => 'ya@toh.ru',
            'ticket' => 'LaJmzXniEfoQgGkfpnVlVrdydtSrSMPB'
          }
        ];


my $comp =  thaw( pack "H*", $msg);
is_deeply( $comp, $VAR1 , "Bug in Flash 9.0 (1)");

$msg = '
08 0000 0000 0006 6c656e677468 00 4008 0000 0000 0000
000009
';
$msg=~s/\W+//g;
$VAR1 = [
        ];


$comp =  thaw( pack "H*", $msg);
is_deeply( $comp, $VAR1 , "Bug in Flash 9.0 (2)");

$msg = '
08 0000 0001 0006 6c656e677468 00 4008 0000 0000 0000
0001 30 02 0003 6e6574 000009
';
$msg=~s/\W+//g;
$VAR1 = [
            'net'
        ];


$comp =  thaw( pack "H*", $msg);
is_deeply( $comp, $VAR1 , "Bug in Flash 9.0 (3)");

my $s = {};
$$s{a} = $s;

$msg = '
08 0000 0001 0006 6c656e677468 00 4008 0000 0000 0000
0001 30 07 0000 000009
';
$msg=~s/\W+//g;
print Dumper($comp =  thaw( pack( "H*", $msg), 1));
