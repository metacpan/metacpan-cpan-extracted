
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => ( 4 * 4 ) + ( 4 * 4 );
use strict;
use warnings;

# modules that we need
use String::Lookup;

# initializations
my $foo= 'foo';
my $bar= 'bar';

# all permutations for offset / increment check
foreach (
  [   0, 10,  10,  20, "just increment" ],
  [   1,  5,   6,  11, "simple offset + increment" ],
  [ 100,  0, 101, 102, "high offset, no increment" ],
  [ 314,  1, 315, 316, "high offset, simple increment" ],
) {
    my ( $offset, $increment, $id_foo, $id_bar, $text )= @{$_};

    # set up the hash
    tie my %hash, 'String::Lookup',
      offset    => $offset,
      increment => $increment,
    ;

    # check lookups
    is( $hash{ \$foo }, $id_foo, "simple string lookup: $text" );
    is( $hash{$id_foo}, $foo,    "simple id lookup: $text" );
    is( $hash{ \$bar }, $id_bar, "another simple string lookup: $text" );
    is( $hash{$id_bar}, $bar,    "another simple id lookup: $text" );
}

# all permutations for init / offset check
foreach (
  [  5, 1, 10, 11, "simple offset override by fill" ],
  [ 15, 1, 10, 16, "fill doesn't override offset" ],
  [  2, 5, 10, 17, "fill contains values matching offset / increment" ],
  [  3, 5, 10, 18, "fill contains values not matching offset / increment" ],
) {
    my ( $offset, $increment, $foo_id, $bar_id, $text )= @{$_};

    # set up the hash
    tie my %hash, 'String::Lookup',
      init      => { $foo => $foo_id },
      offset    => $offset,
      increment => $increment,
    ;

    # check lookup
    is( $hash{ \$foo }, $foo_id, "string lookup after init: $text" );
    is( $hash{$foo_id},    $foo, "id lookup after init: $text" );
    is( $hash{ \$bar }, $bar_id, "another string lookup after init: $text" );
    is( $hash{$bar_id},    $bar, "another id lookup after init: $text" );
}
