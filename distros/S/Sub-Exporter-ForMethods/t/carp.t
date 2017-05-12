#!perl
use strict;
use warnings;

use Test::More;

use Scalar::Util 'blessed';

use lib 't/lib';

{
  package Class;
  use TestMexp
    foo => { -as => 'bar' },
    foo => { -as => 'baz' },
    blessed_method => { -as => 'lost_bless' };

  use TestMexp
    {
      installer => Sub::Exporter::ForMethods::method_installer({rebless => 1})
    },
    blessed_method => { -as => 'kept_bless' };

  use TestDexp
    foo => { -as => 'quux' };

  sub new { bless {} }
}

{
  my $mess = eval { Class->new->bar };
  like($mess, qr{Class::bar}, "bar method appears under its own name");
}

{
  my $mess = eval { Class->new->baz };
  like($mess, qr{Class::baz}, "baz method appears under its own name");
}

{
  my $mess = eval { Class->new->quux };
  unlike($mess, qr{Class::quuz}, "quuz method doesn't have its own name");
}

is( blessed(Class->can('lost_bless')), undef, "we normally do not rebless");

is( blessed(Class->can('kept_bless')), 'TestMexp', "...but we can");

done_testing;
