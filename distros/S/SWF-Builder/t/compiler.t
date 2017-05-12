use Test;
use strict;

BEGIN { plan tests => 9 }

use SWF::Builder::ActionScript::Compiler;
use SWF::BinStream;
use SWF::Element;

ok(1);

my $BE = (CORE::pack('s',1) eq CORE::pack('n',1));
my $INF  = "\x00\x00\x00\x00\x00\x00\xf0\x7f";
my $NINF = "\x00\x00\x00\x00\x00\x00\xf0\xff";
if ($BE) {
    $INF  = reverse $INF;
    $NINF = reverse $NINF;
}
my $MANTISSA  = ~$NINF;
my $INFINITY = unpack('d', $INF);
ok($INFINITY+1, $INFINITY);
ok(pack('d', -$INFINITY), $NINF);
ok((pack('d', $INFINITY-$INFINITY) & $INF) eq $INF and (pack('d', $INFINITY-$INFINITY) & $MANTISSA) ne "\x00" x 8);

my $c;
my $actions;

$c = SWF::Builder::ActionScript::Compiler->new('this.test(1)');
actionchk($c->compile);
ok($c->{stat}{code}[0], "Push Number '1' Number '1' String 'this'");
ok($c->{stat}{code}[-2], "CallMethod");

$c = SWF::Builder::ActionScript::Compiler->new('a=1/0');
actionchk($c->compile);
ok($c->{stat}{code}[0], "Push String 'a' Number 'Infinity'");

sub actionchk {
    my $action1 = shift;
    my $w_s = SWF::BinStream::Write->new;
    $action1->pack($w_s);
    my $r_s = SWF::BinStream::Read->new($w_s->flush_stream);
    my $action2 = SWF::Element::Array::ACTIONRECORDARRAY->new;
    $action2->unpack($r_s);

    my ($a1dump, $a2dump);

    $action1->dumper(sub{$a1dump.=shift});
    $action2->dumper(sub{$a2dump.=shift});

    ok($a2dump, $a1dump);
}
