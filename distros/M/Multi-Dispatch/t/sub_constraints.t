use 5.022;
use warnings;
use strict;

use Test::More;
use lib qw< tlib t/tlib >;

use Multi::Dispatch;

my $exception;
BEGIN { ok !eval{ require Where_Num   }; $exception = $@; }
BEGIN { like $exception, qr/Can't use a literal value or regex or classname there/, 'Where_Num exception' }

BEGIN { ok !eval{ require Where_Str   }; $exception = $@; }
BEGIN { like $exception, qr/Can't use a literal value or regex or classname there/, 'Where_Str exception' }

BEGIN { ok !eval{ require Where_Pat   }; $exception = $@; }
BEGIN { like $exception, qr/Can't use a literal value or regex or classname there/, 'Where_Pat exception' }

BEGIN { ok !eval{ require Where_Undef }; $exception = $@; }
BEGIN { like $exception, qr/Can't use a literal value or regex or classname there/, 'Where_Undef exception' }

BEGIN { ok !eval{ require Where_ClassName }; $exception = $@; }
BEGIN { like $exception, qr/Can't use a literal value or regex or classname there/, 'Where_ClassName exception' }

my $debugging;
multi foo :where({$debugging}) () { 'debugging' }
multi foo                      () { 'non-debugging' }

is foo(), 'non-debugging' => 'non-debugging';
$debugging = 1;
is foo(), 'debugging'     => 'debugging';

sub tracking { state $tracking; $tracking = shift if @_; $tracking; }

multi bar :where({tracking}) () { 'tracking' }
multi bar                    () { 'non-tracking' }

is bar(), 'non-tracking' => 'non-tracking';
tracking(1);
is bar(), 'tracking'     => 'tracking';


my $void;
multi context :where(VOID)   () { $void = 1 }
multi context :where(SCALAR) () { 0         }
multi context :where(LIST)   () { 1..3      }

is_deeply [       context()], [1..3]  => 'LIST context';
is_deeply [scalar context()], [0]     => 'SCALAR context';

context();
ok $void => 'VOID context';


$void = undef;
multi manual_context () {
              wantarray  ?  1..3
    : defined wantarray  ?  0
    :                       ($void = 1)
}

is_deeply [       manual_context()], [1..3]  => 'manual LIST context';
is_deeply [scalar manual_context()], [0]     => 'manual SCALAR context';

manual_context();
ok $void => 'manual VOID context';


sub list {}

my $is_void;
multi is_void :where(   VOID)  ($result_ref)  { ${$result_ref} = 1 }
multi is_void :where(NONVOID)  ($result_ref)  { ${$result_ref} = 0 }

$is_void = 0;          is_void(\$is_void);   ok  $is_void => 'void   is_void()';
$is_void = 1;   scalar is_void(\$is_void);   ok !$is_void => 'scalar is_void()';
$is_void = 1;   list   is_void(\$is_void);   ok !$is_void => 'list   is_void()';


my $is_scalar;
multi is_scalar :where(   SCALAR)  ($result_ref)  { ${$result_ref} = 1 }
multi is_scalar :where(NONSCALAR)  ($result_ref)  { ${$result_ref} = 0 }

$is_scalar = 1;          is_scalar(\$is_scalar);   ok !$is_scalar => 'void   is_scalar()';
$is_scalar = 0;   scalar is_scalar(\$is_scalar);   ok  $is_scalar => 'scalar is_scalar()';
$is_scalar = 1;   list   is_scalar(\$is_scalar);   ok !$is_scalar => 'list   is_scalar()';


my $is_list;
multi is_list :where(   LIST)  ($result_ref)  { ${$result_ref} = 1 }
multi is_list :where(NONLIST)  ($result_ref)  { ${$result_ref} = 0 }

$is_list = 1;          is_list(\$is_list);   ok !$is_list => 'void   is_list()';
$is_list = 1;   scalar is_list(\$is_list);   ok !$is_list => 'scalar is_list()';
$is_list = 0;   list   is_list(\$is_list);   ok  $is_list => 'list   is_list()';


done_testing();

