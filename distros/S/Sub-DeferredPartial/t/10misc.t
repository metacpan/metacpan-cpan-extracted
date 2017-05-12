
use strict;
use warnings;
use Test::More tests => 12;

BEGIN { use_ok 'Sub::DeferredPartial','def' }

my $S = def sub : P1 P2 P3 { %_=@_; join '', @_{qw(P1 P2 P3)} };
ok( $S,'def');

is( $S->( P1 => 1, P2 => 2, P3 => 3 )->(), 123,'application');

my $A = $S->( P3 => 1 );
ok( $A,'partial application');

my $B = $S->( P3 => 2 );
ok( $B,'partial application');

my $C = $A + $B;
ok( $C,'deferred evaluation');

my $D = $C->( P2 => 3 );
my $E = $D->( P1 => 4 );

is( $E->(), 863,'force evaluation');

my $F = $E - $D;

my $G = $F->( P1 => 0 ) / 2;

is( $G->(), 400,'force evaluation');

like( $G, qr(CODE),'describe');

eval { $F->() };
like( $@, qr(^Free parameter: P1),'Error: Free parameter');

eval { $A->( P3 => 7 ) };
like( $@, qr(^Bound parameter: P3),'Error: Bound parameter');

eval { $A->( P4 => 7 ) };
like( $@, qr(^Wrong parameter: P4),'Error: Wrong parameter');
