use lib 't';
# vim: ts=8 et sw=4 sts=4
use ExtUtils::testlib;
use Storable::AMF0 qw(ref_lost_memory ref_clear);
use Scalar::Util qw(refaddr);
use GrianUtils;
use strict;
no warnings 'once';
if ($] > 5.020){
    eval 'use Test::More skip_all => "This perl version is too modern( >= 5.020 )"';
    exit;
}
eval 'use Test::More tests => 6+6;';
use warnings;
no warnings 'once';
our $msg;
sub tt(&);
sub tt(&){
    my $sub = shift;
    my $s = ref_mem_safe( $sub );
    $msg = $s;
    return ($s)if $s;
    return undef;
}

my $a1 = [];
ok(! ref_lost_memory([]));
ok(! ref_lost_memory([[]]));
ok(! ref_lost_memory([{}]));
ok(! ref_lost_memory([$a1, $a1]));

my $a2 = []; @$a2=$a2;

ok( ref_lost_memory($a2));

my $addr;
my %c;
for (1..20)
{
    my $a3 = [];
    @$a3= $a3;
    $addr = refaddr $a3;
    ref_clear($a3);
    #say STDERR refaddr($a3) unless $c{refaddr $a3}++;
}

{
    my $a3 = [];
    @$a3= $a3;
    is($addr, refaddr $a3);
    $addr = refaddr $a3;
}

use GrianUtils qw(ref_mem_safe);

ok(tt {}     , "a $msg " );
ok(tt { {};} , "a $msg "  );
ok(tt { [];} , "a $msg " );
ok(tt { [{a=>1}, [123, qw(123)]];} , "a $msg " );
ok(tt { my $a = { bbb=>123, adf=>[], }; } , "a $msg " );
SKIP: {
    skip("Never works fine", 1);
    #ok(! tt { my @a; @a=(\@a, \@a, \(my $a='asdfa'), {}, ['asdfasd'], {asdf=>1}); 0} , "self ref $msg");
}
#ok(tt { my $a = { bbb=>123, adf=>[], }; return [{a=>1}, [123, qw(123), $a], a=>$a];},  );
