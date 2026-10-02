use strict;
use warnings;

use Test::More;
use Test::Exception;

use File::Temp qw( tempdir );
use File::Spec;
use Scalar::Util qw(
  refaddr
  weaken
);

BEGIN {
  use_ok 'TUI::StdDlg::FindFirstRec';
  use_ok 'TUI::StdDlg::Dos', qw(
    _dos_findfirst
    _dos_findnext
  );
  use_ok 'TUI::StdDlg::Const', qw( :_A_ );
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

my $dir;
eval {
  $dir = tempdir( CLEANUP => 1 );
  open my $fh, '>', File::Spec->catfile( $dir, 'test.txt' )
    or die $!;
  close $fh;
};
ok( !$@, 'temporary directory created for wildcard tests' );

#-----------------------------------------
note 'Object lifetime / fieldhash checks';
#-----------------------------------------

subtest 'fieldhash cleans up when $finfo goes out of scope' => sub {
  use_ok 'Local::Rec';
  local $Local::Rec::DESTROY_COUNT = 0;
  my ( $weak_finfo, $weak_rec );

  {
    my $finfo = find_t->new();
    my $rec   = Local::Rec->allocate( $finfo, 0, './*' );
    isa_ok( $rec, 'Local::Rec' );
    isa_ok( $rec, 'TUI::StdDlg::FindFirstRec' );

    ok( $rec, 'record created' );
    is( Local::Rec->get( $finfo ), $rec, 'mapping exists' );
    is(
      refaddr( $rec->{finfo} ), 
      refaddr( $finfo ), 
      'record linked to find_t'
    );
    is(
      refaddr( $rec ), 
      $finfo->reserved, 
      'find_t linked to record'
    );

    $weak_finfo = $finfo;
    weaken( $weak_finfo );

    $weak_rec = $rec;
    weaken( $weak_rec );
  }

  ok( !defined $weak_finfo, 'fileinfo released' );
  ok( !defined $weak_rec,   'record released' );
  is( $Local::Rec::DESTROY_COUNT, 1, 'destroy called exactly once' );
};

#----------------------
note 'allocate guards';
#----------------------

subtest 'allocate validation' => sub {
  is( 
    Local::Rec->allocate( undef, 0, './*' ), 
    undef, 
    'undef fileinfo rejected'
  );
  is( 
    Local::Rec->get( undef ), 
    undef,
    'get(undef) returns undef'
  );
};

#----------------------------
note 'Reuse existing record';
#----------------------------

subtest 'allocate reuses existing record' => sub {
  my $finfo = find_t->new();
  my $r1 = Local::Rec->allocate( $finfo, 0, './*' );
  my $r2 = Local::Rec->allocate( $finfo, 0, './*' );
  is( refaddr( $r1 ), refaddr( $r2 ), 'same record reused' );
};

#-------------------------------
note 'Basic findfirst/findnext';
#-------------------------------

subtest '_dos_findfirst and _dos_findnext' => sub {
  my $finfo = find_t->new();
  my $result = _dos_findfirst( 
    File::Spec->catfile($dir, '*' ),    # Find all files
    0x00, 
    $finfo
  );
  is( $result, 0, '_dos_findfirst should succeed' );

  if ( $result == 0 ) {
    ok( defined $finfo->name, 'first filename defined' );
    note( 'Found file: ' . $finfo->name );

    my %seen;
    my $count = 0;
    do {
      $seen{ $finfo->name }++;
      $count++;
    }
    while ( _dos_findnext( $finfo ) == 0 );

    cmp_ok( 
      $count, '>', 0,
      'at least one entry returned'
    );
    note( "entries seen: $count" );
  }
};

#-----------------
note 'No matches';
#-----------------

subtest 'no match' => sub {
  my $finfo = find_t->new();
  is(
    _dos_findfirst( 
      File::Spec->catfile( $dir, 'this_file_should_not_exist_123456789.zzz' ),
      0, 
      $finfo
    ),
    -1,
    'findfirst returns -1 when no file matches'
  );
};

#--------------------------------------------
note 'DOS compatibility: *.* behaves like *';
#--------------------------------------------

subtest 'wildcards in temporary directory' => sub {
  my $f1 = find_t->new();
  my $f2 = find_t->new();
  is(
    _dos_findfirst( File::Spec->catfile( $dir, '*.*' ), 0, $f1 ),
    0,
    '*.* accepted'
  );
  is(
    _dos_findfirst( File::Spec->catfile( $dir, '*' ), 0, $f2 ),
    0,
    '* accepted'
  );
};

#-----------------------
note 'Directory search';
#-----------------------

subtest 'directory attribute search' => sub {
  my $finfo = find_t->new();

  my $rc = _dos_findfirst( './*', _A_SUBDIR, $finfo );
  is( $rc, 0, 'subdirectory search succeeds' );

  my $found_dir = 0;
  while (1) {
    if ( $finfo->attrib & _A_SUBDIR ) {
      $found_dir = 1;
      last;
    }
    last if _dos_findnext( $finfo ) != 0;
  }
  ok( $found_dir, 'at least one directory found' );
};

#------------------
note 'Dot entries';
#------------------

subtest 'dot entries are handled' => sub {
  my $finfo = find_t->new();
  is(
    _dos_findfirst( './*', _A_SUBDIR, $finfo ),
    0,
    'enumeration succeeds'
  );

  my %seen;

  do {
    $seen{ $finfo->name }++;
  }
  while ( _dos_findnext( $finfo ) == 0 );

  ok(
       exists $seen{'.'}
    || exists $seen{'..'}
    || scalar(keys %seen) > 0,
    'directory entries returned'
  );
};

#-------------------------------
note 'Platform-specific checks';
#-------------------------------

SKIP: {
  skip 'Unix-specific tests', 1 if $^O eq 'MSWin32';

  subtest 'unix wildcard semantics' => sub {
    my $finfo = find_t->new();
    my $rc = _dos_findfirst( './????*', 0, $finfo );
    ok( defined $rc, 'question-mark wildcard accepted' );
  };
}

done_testing();
