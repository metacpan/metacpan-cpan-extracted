use strict;
use warnings;

use Test::More;
use Test::Exception;

use Scalar::Util qw(
  refaddr
  weaken
);

BEGIN {
  require_ok 'TUI::StdDlg::FindFirstRec';
  use_ok 'TUI::StdDlg::Dos', qw(
    _dos_findfirst
    _dos_findnext
  );
}

BEGIN {
  package Local::Rec;
  use parent 'TUI::StdDlg::FindFirstRec';
  our $DESTROY_COUNT = 0;
  sub DESTROY {
    $DESTROY_COUNT++;
    shift->SUPER::DESTROY;
  }
  $INC{"Local/Rec.pm"} = 1;
}

subtest 'fieldhash cleans up when $finfo goes out of scope' => sub {
  use_ok 'Local::Rec';
  local $Local::Rec::DESTROY_COUNT = 0;
  my ( $weak_finfo, $weak_rec );

  {
    my $finfo = find_t->new();
    my $rec   = Local::Rec->allocate( $finfo, 0, '.\\*' );
    isa_ok( $rec, 'TUI::StdDlg::FindFirstRec' );

    ok( $rec, 'Rec was created' );
    is( Local::Rec->get( $finfo ), $rec, 'Mapping exists' );
    is(
      refaddr( $rec->{finfo} ), 
      refaddr( $finfo ), 
      'FindFirstRec is associated with fileinfo'
    );
    is(
      refaddr( $rec ), 
      $finfo->reserved, 
      'fileinfo is associated with FindFirstRec'
    );

    $weak_finfo = $finfo;
    weaken( $weak_finfo );

    $weak_rec = $rec;
    weaken( $weak_rec );
  }

  ok( !defined $weak_finfo, '$finfo has been released' );
  ok( !defined $weak_rec,   '$rec has been released' );
  is( $Local::Rec::DESTROY_COUNT, 1, 'DESTROY ran and close() was executed' );
};

# Test _dos_findfirst and _dos_findnext
subtest '_dos_findfirst and _dos_findnext' => sub {
  my $finfo = find_t->new();
  my $result = _dos_findfirst( '.\\*', 0x00, $finfo );    # Find all files
  is( $result, 0, '_dos_findfirst should succeed' );

  if ( $result == 0 ) {
    ok( defined $finfo->name, 'File name should be defined' );
    note( 'Found file: ' . $finfo->name );

    # Test _dos_findnext
    while ( _dos_findnext( $finfo ) == 0 ) {
      ok( defined $finfo->name, 'Next file name should be defined' );
      note( 'Next file: ' . $finfo->name );
      last if $finfo->name =~ /^\.\.?$/;  # Avoid infinite loop in test
    }
  }
};

done_testing();
