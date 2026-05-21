use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::StdDlg::FileCollection';
}

# Import FA_DIREC for attribute bit tests.
use TUI::StdDlg::Const qw(FA_DIREC);

# Helper to build a TSearchRec instance used as "key" objects.
sub mk_rec {
  my ( %opt ) = @_;
  my $rec = TSearchRec->new();
  $rec->name( defined $opt{name} ? $opt{name} : '' );
  $rec->attr( defined $opt{attr} ? $opt{attr} : 0 );
  $rec->time( defined $opt{time} ? $opt{time} : 0 );
  $rec->size( defined $opt{size} ? $opt{size} : 0 );
  return $rec;
}

# Create a minimal object to call compare() as a method.
my $self = TFileCollection->new( limit => 0, delta => 0 );
isa_ok( $self, TFileCollection );

subtest 'compare: same names' => sub {
  my $a1 = mk_rec( name => 'alpha', attr => 0 );
  my $a2 = mk_rec( name => 'alpha', attr => FA_DIREC );

  is( $self->compare( $a1, $a2 ), 0,
    'Same name => compare returns 0 (attr ignored)' );
  is( $self->compare( $a2, $a1 ), 0, 'Same name => symmetric zero result' );
};

subtest 'compare: ".." special case' => sub {
  my $dotdot = mk_rec( name => '..',    attr => FA_DIREC );
  my $file   = mk_rec( name => 'a.txt', attr => 0 );
  my $dir    = mk_rec( name => 'adir',  attr => FA_DIREC );

  is( $self->compare( $dotdot, $file ),    1, '".." as key1 => returns 1' );
  is( $self->compare( $file,   $dotdot ), -1, '".." as key2 => returns -1' );

  is( $self->compare( $dotdot, $dir ), 1,
    '".." as key1 beats directory rule => returns 1' );
  is( $self->compare( $dir, $dotdot ), -1,
    '".." as key2 beats directory rule => returns -1' );
};

subtest 'compare: directory vs file precedence' => sub {
  my $dir  = mk_rec( name => 'zzz', attr => FA_DIREC );
  my $file = mk_rec( name => 'aaa', attr => 0 );

  is( $self->compare( $dir,  $file ),  1, 'dir vs file => returns 1' );
  is( $self->compare( $file, $dir ),  -1, 'file vs dir => returns -1' );
};

subtest 'compare: lexicographic fallback' => sub {
  my $a = mk_rec( name => 'alpha', attr => 0 );
  my $b = mk_rec( name => 'beta',  attr => 0 );

  is( $self->compare( $a, $b ), -1, 'alpha cmp beta => -1' );
  is( $self->compare( $b, $a ),  1, 'beta cmp alpha => 1' );

  my $c = mk_rec( name => 'alpha', attr => FA_DIREC );
  is(
    $self->compare( $c, $b ), 1,
    'dir/file precedence applies before lexicographic compare'
  );
  is(
    $self->compare( $b, $c ), -1,
    'dir/file precedence is symmetric when operands are swapped'
  );
};

subtest 'compare: antisymmetry sanity checks' => sub {
  my @pairs = (
    [ 
      mk_rec( name => 'x', attr => 0 ), 
      mk_rec( name => 'y', attr => 0 ) 
    ],
    [ 
      mk_rec( name => 'dir', attr => FA_DIREC ), 
      mk_rec( name => 'file', attr => 0 )
    ],
    [ 
      mk_rec( name => '..', attr => 0 ), 
      mk_rec( name => 'a', attr => 0 ) 
    ],
  );

  for my $p ( @pairs ) {
    my ( $k1, $k2 ) = @$p;
    my $c12 = $self->compare( $k1, $k2 );
    my $c21 = $self->compare( $k2, $k1 );

    # If compare returns 0 both ways, fine. Otherwise it should flip sign.
    if ( $c12 == 0 ) {
      is( $c21, 0, '0 result is symmetric' );
    }
    else {
      is( $c21, -$c12, 'Non-zero result flips sign when operands are swapped' );
    }
  }
}; #/ 'compare: antisymmetry sanity checks' => sub

done_testing;
