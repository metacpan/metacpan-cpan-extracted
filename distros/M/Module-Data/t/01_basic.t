use strict;
use warnings;

use Test::More 0.96;
use Module::Data;
use Test::Fatal;

my $md;
my $data;

use Data::Dump qw( pp );

is(
  exception {
    $md = Module::Data->new('Test::Fatal');
  },
  undef,
  'Creating a new object for Test::Fatal introspection works'
);

is( $md->root->child( 'Test', 'Fatal.pm' )->absolute->stringify, $md->path->absolute->stringify, "root contains package" );

is(
  exception {
    $data = {
      _notional_name => $md->_notional_name,
      path           => $md->path->stringify,
      package        => $md->package,
      root           => $md->root->stringify,
    };
  },
  undef,
  'All methods work without failing'
);

note pp($data);
note pp($md);

# FILENAME: 01_basic.t
# CREATED: 22/03/12 14:13:34 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Basic module load and decode tests

done_testing;

