use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::StdDlg::Const', qw( :DIR );
  use_ok 'TUI::StdDlg::Dir', qw(
    fnmerge
    fnsplit
    getdisk
    setdisk
    getcurdir
  );
}

#--------------
note 'fnmerge';
#--------------
subtest 'fnmerge basic behaviour' => sub {
  my $path;

  fnmerge( $path, 'C', 'foo', 'bar', 'txt' );

  if ( $^O eq 'MSWin32' ) {
    is( $path, 'C:foo\\bar.txt', 'Windows: drive + dir + name + ext' );
  }
  else {
    is( $path, 'foo/bar.txt', 'Unix: drive ignored, unix separators' );
  }

  fnmerge( $path, undef, 'foo/', 'bar', '.txt' );
  is(
    $path,
    'foo/bar.txt',
    'Existing directory separator preserved, no duplication'
  );
}; #/ 'fnmerge basic behaviour' => sub

#--------------
note 'fnsplit';
#--------------
subtest 'fnsplit components' => sub {
  my ( $d, $dir, $n, $e );

  my $flags = fnsplit( 'C:\\foo\\bar.txt', $d, $dir, $n, $e );

  is( $d,   'C:',      'drive extracted' );
  is( $dir, '\\foo\\', 'dir extracted with trailing separator' );
  is( $n,   'bar',     'filename extracted' );
  is( $e,   '.txt',    'extension extracted with dot' );

  ok( $flags & DRIVE(),     'DRIVE() flag set' );
  ok( $flags & DIRECTORY(), 'DIRECTORY() flag set' );
  ok( $flags & FILENAME(),  'FILENAME() flag set' );
  ok( $flags & EXTENSION(), 'EXTENSION() flag set' );
};

subtest 'fnsplit special dot cases' => sub {
  my ( $d, $dir, $n, $e );

  my $flags = fnsplit( 'foo\\.', undef, $dir, $n, $e );

  is( $dir, 'foo\\.', 'dot directory treated as directory' );
  is( $n,   '',       'no filename for trailing dot' );
  is( $e,   '',       'no extension for trailing dot' );
};

subtest 'fnsplit wildcards' => sub {
  my $flags = fnsplit( 'foo\\*.txt', undef, undef, undef, undef );

  ok( $flags & WILDCARDS(), 'wildcards detected in filename part' );

  $flags = fnsplit( 'foo*\\bar.txt', undef, undef, undef, undef );

  ok( !( $flags & WILDCARDS() ), 'wildcards ignored in directory part' );
};

#--------------
note 'getdisk';
#--------------
subtest 'getdisk' => sub {
  my $d = getdisk();

  ok( defined $d,          'getdisk returns a value' );
  ok( $d >= 0 && $d <= 25, 'getdisk returns valid drive index' );
};

#----------------
note 'getcurdir';
#----------------
subtest 'getcurdir' => sub {
  my $dir;
  my $rc = getcurdir( 0, $dir );

  is( $rc, 0, 'getcurdir returns success for default drive' );
  ok( defined $dir, 'directory string returned' );
  ok( $dir !~ /^[A-Za-z]:/, 'no drive letter in result' );
  ok( $dir !~ m{^[/\\]},    'no leading slash or backslash' );
};

#--------------
note 'setdisk';
#--------------
subtest 'setdisk' => sub {
  my $cur = getdisk();

  my $rc = setdisk( $cur + 1 );
  ok( $rc >= 0, 'setdisk succeeds for current drive' );
  is( getdisk(), $cur, 'current drive unchanged or restored' );
};

#-------------------------
note 'findfirst/findnext';
#-------------------------
subtest 'findfirst/findnext' => sub {
  can_ok( 'TUI::StdDlg::Dir', 'findfirst' );
  can_ok( 'TUI::StdDlg::Dir', 'findnext' );
};

done_testing();
