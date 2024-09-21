#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;
use Test2::IPC;

use Object::Pad 0.800;

eval { require Config && $Config::Config{useithreads} } or
   plan skip_all => "This perl does not support threads";

require threads;

class Cnative :repr(native) {
   field $x :param;
   method x { return $x }
}

class CHASH :repr(HASH) {
   field $x :param;
   method x { return $x }
}

package CmagicBase { sub new { return bless {}, shift } }
class Cmagic :isa(CmagicBase) :repr(magic) {
   field $x :param;
   method x { return $x }
}

{
   my $ret = threads->create(sub {
      pass( "Created dummy thread" );
      return 1;
   })->join;
   is( $ret, 1, "Returned from dummy thread" );
}

foreach my $repr (qw( native HASH magic )) {
    my $class = "C$repr";

    subtest "Class using :repr($repr)" => sub {
        {
           my $obj = $class->new( x => 10 );
           threads->create(sub {
              is( $obj->x, 10, '$obj->x inside thread created before' );
           })->join;
        }

        threads->create(sub {
           my $obj = $class->new( x => 20 );
           is( $obj->x, 20, '$obj->x created inside thread' );
        })->join;
    }
}

done_testing;
