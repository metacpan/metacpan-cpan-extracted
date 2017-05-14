use strict;
use warnings;
use Test::More;
use Ref::Util::XS qw<is_hashref is_plain_hashref is_blessed_hashref>;

eval { require Readonly; Readonly->import; 1; }
or plan 'skip_all' => 'Readonly is required for this test';

plan 'tests' => 3;

Readonly::Scalar( my $rh2 => { a => { b => 2 } } );

ok( is_hashref($rh2), 'Readonly objects work!' );
ok( is_plain_hashref($rh2), 'They are not plain!' );
ok( !is_blessed_hashref($rh2), 'They are blessed!' );
