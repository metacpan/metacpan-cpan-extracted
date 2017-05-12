package _MockMyClass;

use strict;
use warnings;
use Test::Most;

BEGIN { use_ok('Sub::Versions'); }

sub new {
    return bless( {}, shift );
}

sub out : v11 {
    return "out v11 $_[-1]";
}

sub out : v12 {
    return "out v12 $_[-1]";
}

sub in : v12 {
    return 'in v12 $_[-1]';
}

sub out : v10 {
    return "out v10 $_[-1]";
}

sub unversioned {
    return "unversioned $_[-1]";
}

package _MockMySubClass;

use strict;
use warnings;

use base '_MockMyClass';

sub out : v12 {
    return "out +v12+ $_[-1]";
}

sub out : v13 {
    return "out !v13! $_[-1]";
}

package main;

use strict;
use warnings;
use Test::Most;

my $obj = _MockMyClass->new;

is( $obj->out(1),      'out v12 1', '$obj->out(1)'      );
is( $obj->out_v10(2),  'out v10 2', '$obj->out_v10(2)'  );
is( $obj->out_v11(3),  'out v11 3', '$obj->out_v11(2)'  );
is( $obj->out_v12(4),  'out v12 4', '$obj->out_v12(3)'  );
is( $obj->v10->out(6), 'out v10 6', '$obj->v10->out(6)' );
is( $obj->v11->out(7), 'out v11 7', '$obj->v11->out(7)' );
is( $obj->v12->out(8), 'out v12 8', '$obj->v12->out(8)' );

my $subobj = _MockMySubClass->new;

is( $subobj->out(1),      'out !v13! 1', '$obj->out(1)'      );
is( $subobj->out_v10(2),  'out v10 2',   '$obj->out_v10(2)'  );
is( $subobj->out_v11(3),  'out v11 3',   '$obj->out_v11(2)'  );
is( $subobj->out_v12(4),  'out +v12+ 4', '$obj->out_v12(3)'  );
is( $subobj->v10->out(6), 'out v10 6',   '$obj->v10->out(6)' );
is( $subobj->v11->out(7), 'out v11 7',   '$obj->v11->out(7)' );
is( $subobj->v12->out(8), 'out +v12+ 8', '$obj->v12->out(8)' );
is( $subobj->out_v13(5),  'out !v13! 5', '$obj->out_v13(5)'  );
is( $subobj->v13->out(9), 'out !v13! 9', '$obj->v13->out(9)' );

is( $subobj->subver( '>11', 'out' )->(1138), 'out !v13! 1138', '$subobj->subver( ">11", "out" )->(1138)' );
is( $subobj->subver( '<11', 'out' )->(1138), 'out v10 1138', '$subobj->subver( "<11", "out" )->(1138)' );
is( $subobj->subver( '>=11', 'out' )->(1138), 'out !v13! 1138', '$subobj->subver( ">=11", "out" )->(1138)' );
is( $subobj->subver( '<=11', 'out' )->(1138), 'out v11 1138', '$subobj->subver( "<=11", "out" )->(1138)' );
is( $subobj->subver( '=11', 'out' )->(1138), 'out v11 1138', '$subobj->subver( "=11", "out" )->(1138)' );
is( $subobj->subver( '11', 'out' )->(1138), 'out v11 1138', '$subobj->subver( "11", "out" )->(1138)' );

is(
    $subobj->subver( '>=11', 'unversioned' )->(1138),
    'unversioned 1138',
    '$subobj->subver( ">=11", "unversioned" )->(1138)',
);

done_testing;
