package TUI::StdDlg::FindFirstRec::Win32;
# ABSTRACT: A class implementing the behavior of findfirst/findnext for Win32

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

require bytes;
use Hash::Util::FieldHash qw( fieldhash );
use Scalar::Util qw(
  refaddr
  weaken
);
use TUI::toolkit qw(
  :boolean
  :utils
);
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);
use Win32::API;
use Win32API::File qw( INVALID_HANDLE_VALUE );

use TUI::StdDlg::Const qw(
  MAXPATH
  :_A_
);

# We use variables to avoid polluting the namespace when importing Win32 API 
# functions. 
my (
  $FindFirstFileW,
  $FindNextFileW,
  $FindClose,
  $FileTimeToLocalFileTime,
  $FileTimeToDosDateTime,
  $MultiByteToWideChar,
  $WideCharToMultiByte,
);

# Load required Windows API functions
BEGIN {
  $FindFirstFileW = Win32::API::More->new( 'kernel32', 
    'HANDLE FindFirstFileW(
      LPCWSTR lpFileName, 
      LPVOID  lpFindFileData
    )',
  ) or die "Import FindFirstFileW failed: $^E";

  $FindNextFileW = Win32::API::More->new( 'kernel32', 
    'BOOL FindNextFileW(
      HANDLE hFindFile,
      LPVOID lpFindFileData
    )',
  ) or die "Import FindNextFileW failed: $^E";

  $FindClose = Win32::API::More->new( 'kernel32', 
    'BOOL FindClose(
      HANDLE hFindFile
    )',
  ) or die "Import FindClose failed: $^E";

  $FileTimeToLocalFileTime = Win32::API::More->new( 'kernel32', 
    'BOOL FileTimeToLocalFileTime(
      LPVOID lpFileTime,
      LPVOID lpLocalFileTime
    )',
  ) or die "Import FileTimeToLocalFileTime failed: $^E";

  $FileTimeToDosDateTime = Win32::API::More->new( 'kernel32', 
    'BOOL FileTimeToDosDateTime(
      LPVOID lpFileTime,
      LPWORD lpFatDate,
      LPWORD lpFatTime
    )',
  ) or die "Import FileTimeToDosDateTime failed: $^E";

  $MultiByteToWideChar = Win32::API::More->new( 'kernel32', 
    'int MultiByteToWideChar(
      UINT   CodePage,
      DWORD  dwFlags,
      LPCSTR lpMultiByteStr,
      int    cbMultiByte,
      LPWSTR lpWideCharStr,
      int    cchWideChar
    )'
  ) or die "Import MultiByteToWideChar: $^E";

  $WideCharToMultiByte = Win32::API::More->new( 'kernel32', 
    'int WideCharToMultiByte(
      UINT    CodePage,
      DWORD   dwFlags,
      LPCWSTR lpWideCharStr,
      int     cchWideChar,
      LPSTR   lpMultiByteStr,
      int     cbMultiByte,
      LPCSTR  lpDefaultChar,
      LPBOOL  lpUsedDefaultChar
    )'
  ) or die "Import WideCharToMultiByte: $^E";
}

PRIVATE: {
  namespace::sweep->import( -also => [qw(
    CP_UTF8
    SPECIAL_BITS

    DWORD_SIZE
    FILETIME_SIZE
    WCHAR_SIZE
    FILENAME_SIZE
    WIN32_FIND_DATAW_SIZE

    dwFileAttributes
    ftCreationTime
    ftLastAccessTime
    ftLastWriteTime
    nFileSizeHigh
    nFileSizeLow
    dwReserved0
    dwReserved1
    cFileName
    cAlternateFileName

    reserved
    size
    attrib
    wr_time
    wr_date
    name
  )] ) if eval { require namespace::sweep };

  use constant CP_UTF8      => 65001;
  use constant SPECIAL_BITS => _A_SUBDIR | _A_HIDDEN | _A_SYSTEM;

  # WIN32_FIND_DATAW structure
  # https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-win32_find_dataw
  use constant DWORD_SIZE            => 4;
  use constant FILETIME_SIZE         => 2 * DWORD_SIZE;
  use constant WCHAR_SIZE            => 2;
  use constant FILENAME_SIZE         => MAXPATH * WCHAR_SIZE;
  use constant WIN32_FIND_DATAW_SIZE => DWORD_SIZE
                                      + 3 * FILETIME_SIZE
                                      + 4 * DWORD_SIZE
                                      + FILENAME_SIZE
                                      + 14 * WCHAR_SIZE;

  # WIN32_FIND_DATAW_SIZE offsets
  use constant {
    dwFileAttributes   => 0,
    ftCreationTime     => 4,
    ftLastAccessTime   => 12,
    ftLastWriteTime    => 20,
    nFileSizeHigh      => 28,
    nFileSizeLow       => 32,
    dwReserved0        => 36,
    dwReserved1        => 40,
    cFileName          => 44,
    cAlternateFileName => 564,
  };

  # find_t offsets
  use constant {
    reserved => 0,
    size     => 1,
    attrib   => 2,
    wr_time  => 3,
    wr_date  => 4,
    name     => 5,
  };
}

# declare global variables
fieldhash my %REC_LIST;

# private attributes
our %HAS; BEGIN {
  %HAS = (
    finfo      => sub { die 'required' },   # weak_ref => 1
    searchAttr => sub { 0 },
    hFindFile  => sub { INVALID_HANDLE_VALUE },
    fileName   => sub { '' },
  )
}

# predeclare private methods
my (
  $open,
  $close,
  $setParameters,
  $attrMatch,
  $cvtAttr,
  $cvtTime,
);

sub allocate {    # $rec|undef ($fileinfo, $attrib, $pathname)
  state $sig = signature(
    method => 1,
    pos => [
      Maybe[ArrayLike], 
      PositiveOrZeroInt, 
      Str,
    ],
  );
  my ( $class, $fileinfo, $attrib, $pathname ) = $sig->( @_ );

  # The findfirst interface based on DOS call 0x4E doesn't provide a
  # findclose function. The strategy here is the same as in Borland's RTL:
  # a new object is created and stored internally in %REC_LIST, unless 
  # $fileinfo has already been passed to us before.
  return undef
    unless $fileinfo;

  my $r = $REC_LIST{ $fileinfo };
  # If $r is defined, we need to close the search handle and reset the 
  # parameters. If $r is undef, we need to create a new FindFirstRec and store 
  # it in the field hash %REC_LIST and the global registry for retrieval.
  if ( $r ) {
    $r->$close();
  }
  else {
    $r = bless {
      finfo      => $fileinfo // $HAS{finfo}->(),
      searchAttr => $HAS{searchAttr}->(),
      hFindFile  => $HAS{hFindFile}->(),
      fileName   => $HAS{fileName}->(),
    }, $class;
    $REC_LIST{ $fileinfo } = $r;
    weaken $r->{finfo};
  }
  # If pathname is a valid directory, make fileinfo point to the allocated
  # FindFirstRec. Otherwise, return undef.
  if ( $r->$setParameters( $attrib, $pathname ) ) {
    # Connect fileinfo to FindFirstRec for compatibility with the original 
    # findfirst interface. This allows the caller to identify the corresponding 
    # FindFirstRec object using the fileinfo structure.
    $fileinfo->[reserved] = refaddr $r;
    return $r;
  }
  return undef;
} #/ sub allocate

sub DESTROY {
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  $self->$close();
  return;
}

sub get {    # $rec|undef ($fileinfo)
  state $sig = signature(
    method => 1,
    pos => [
      Maybe[ArrayLike],
    ],
  );
  my ( $class, $fileinfo ) = $sig->( @_ );

  return undef 
    unless $fileinfo;
  return $REC_LIST{ $fileinfo };
}

sub next {    # $bool ()
  state $sig = signature(
    method => Object,
    pos => [],
  );
  my ( $self ) = $sig->( @_ );

  my $findData = "\0" x WIN32_FIND_DATAW_SIZE;
  while ( 1 ) {
    if ( $self->{hFindFile} == INVALID_HANDLE_VALUE ) {
      my $cFileName = "\0" x FILENAME_SIZE;
      $MultiByteToWideChar->Call( CP_UTF8, 0,
        $self->{fileName}, -1,
        $cFileName, MAXPATH );
      $self->{hFindFile} = $FindFirstFileW->Call( $cFileName, $findData );
    }
    elsif ( !$FindNextFileW->Call( $self->{hFindFile}, $findData ) ) {
      $self->$close();
      return false;
    }

    if ( $self->{hFindFile} != INVALID_HANDLE_VALUE ) {
      my $cFileName = bytes::substr( $findData, cFileName, FILENAME_SIZE );
      my $attr = $self->$cvtAttr( $findData, $cFileName );
      if ( $self->$attrMatch( $attr ) ) {
        # Match found, fill finfo.
        my $size = unpack 'V' 
          => bytes::substr( $findData, nFileSizeLow, DWORD_SIZE );
        $self->{finfo}->[size] = $size;
        $self->{finfo}->[attrib] = $attr;
        $self->$cvtTime( $findData, $self->{finfo} );
        my $name = "\0" x MAXPATH;
        $WideCharToMultiByte->Call( CP_UTF8, 0,
          $cFileName, -1,
          $name, MAXPATH,
          undef, undef );
        $name =~ s/\0+\z//;
        $self->{finfo}->[name] = $name;
        return true;
      }
    }
    else {
      return false;
    }
  }
}

$open = sub {    # $bool ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  return true;
};

$close = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  assert ( is_Int $self->{hFindFile} );
  if ( $self->{hFindFile} != INVALID_HANDLE_VALUE ) {
    $FindClose->Call( $self->{hFindFile} );
  }
  $self->{hFindFile} = INVALID_HANDLE_VALUE;
  return;
};

$setParameters = sub {    # $rec|undef ($attrib, $pathname)
  my ( $self, $attrib, $pathname ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $attrib );
  assert ( is_Str $pathname );
  if ( $self->{hFindFile} != INVALID_HANDLE_VALUE ) {
    $self->$close();
  }
  $self->{fileName}   = $pathname;
  $self->{searchAttr} = $attrib;

  return $self->$open();
};

$attrMatch = sub {    # $bool ($attrib)
  my ( $self, $attrib ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $attrib );
  assert ( is_Int $self->{searchAttr} );
  return ( ( $self->{searchAttr} & _A_VOLID ) && ( $attrib & _A_VOLID ) )
      || !( $attrib & SPECIAL_BITS )
      || ( $self->{searchAttr} & $attrib & SPECIAL_BITS );
};

$cvtAttr = sub {    # $attr ($findData, $filename)
  my ( $self, $findData, $filename ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Str $findData );
  assert ( is_Str $filename );
  my $attr = unpack 'V' => bytes::substr( $findData, 0, DWORD_SIZE );
  if ( $filename && substr( $filename, 0, 1 ) eq '.' ) {
    $attr |= _A_HIDDEN;
  }
  return $attr;
};

$cvtTime = sub {    # void ($findData, $fileinfo)
  my ( $self, $findData, $fileinfo ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Str $findData );
  assert ( is_ArrayLike $fileinfo );
  my $fileTime = bytes::substr( $findData, ftLastWriteTime, FILETIME_SIZE );
  my $localTime = "\0" x FILETIME_SIZE;
  $FileTimeToLocalFileTime->Call( $fileTime, $localTime );
  my $lpFatDate = pack 'S' => 0;
  my $lpFatTime = pack 'S' => 0;
  $FileTimeToDosDateTime->Call( $localTime, $lpFatDate, $lpFatTime );
  $fileinfo->[wr_date] = unpack 'S' => $lpFatDate;
  $fileinfo->[wr_time] = unpack 'S' => $lpFatTime;
  return;
};

1

__END__

=pod

=head1 NAME

TUI::StdDlg::FindFirstRec::Win32 - Win32 implementation of FindFirstRec

=head1 DESCRIPTION

C<TUI::StdDlg::FindFirstRec::Win32> provides the Windows-specific implementation
of the C<FindFirstRec> directory search interface.

The implementation maps the generic search operations to the Win32
C<FindFirstFile> and C<FindNextFile> APIs and updates the associated C<find_t>
record accordingly.

=head1 METHODS

=head2 allocate

Win32-specific initialization of a directory search.

=head2 get

Retrieves the search context associated with a C<find_t> record.

=head2 next

Advances the search using the Win32 filesystem APIs.

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

=over

=item * magiblot <magiblot@hotmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2019-2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
