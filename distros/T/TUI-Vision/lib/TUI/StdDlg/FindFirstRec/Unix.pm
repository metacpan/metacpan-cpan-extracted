package TUI::StdDlg::FindFirstRec::Unix;
# ABSTRACT: A class implementing the behavior of findfirst/findnext for Unix

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Hash::Util::FieldHash qw( fieldhash );
use Scalar::Util qw(
  refaddr
  weaken
);
use Fcntl qw(
  :mode
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

use TUI::StdDlg::Const qw(
  MAXPATH
  :_A_
);

PRIVATE: {
  namespace::sweep->import( -also => [qw(
    SPECIAL_BITS

    reserved
    size
    attrib
    wr_time
    wr_date
    name
  )] ) if eval { require namespace::sweep };

  use constant SPECIAL_BITS => _A_SUBDIR | _A_HIDDEN | _A_SYSTEM;

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
    dirStream  => sub { undef },
    searchDir  => sub { './' },
    wildcard   => sub { '*' },
  )
}

# predeclare private methods
my (
  $open,
  $close,
  $setParameters,
  $setPath,
  $matchEntry,
  $attrMatch,
  $wildcardMatch,
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

  # If $r is defined, we need to close the directory stream and reset the
  # parameters. If $r is undef, we need to create a new FindFirstRec and store
  # it in the field hash %REC_LIST and the global registry for retrieval.
  if ( $r ) {
    $r->$close();
  }
  else {
    $r = bless {
      finfo      => $fileinfo // $HAS{finfo}->(),
      searchAttr => $HAS{searchAttr}->(),
      dirStream  => $HAS{dirStream}->(),
      searchDir  => $HAS{searchDir}->(),
      wildcard   => $HAS{wildcard}->(),
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

  while ( defined( my $entry = readdir $self->{dirStream} ) ) {
    return true
      if $self->$matchEntry( $entry );
  }

  $self->$close();
  return false;
}

$open = sub {    # $bool ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  assert ( !defined $self->{dirStream} );

  my $dh;
  return false
    unless opendir $dh, $self->{searchDir};

  $self->{dirStream} = $dh;
  return true;
};

$close = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );

  if ( defined $self->{dirStream} ) {
    closedir $self->{dirStream};
    $self->{dirStream} = undef;
  }

  return;
};

$setParameters = sub {    # $bool ($attrib, $pathname)
  my ( $self, $attrib, $pathname ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $attrib );
  assert ( is_Str $pathname );

  return false
    if defined $self->{dirStream};

  $self->{searchAttr} = $attrib;

  return $self->$setPath( $pathname )
      && $self->$open();
};

$setPath = sub {    # $bool ($pathname)
  my ( $self, $pathname ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Str $pathname );

  return false
    unless length $pathname;

  my $searchDir = $pathname;

  # Accept DOS separators on Unix, matching the intent of path_dos2unix().
  $searchDir =~ tr{\\}{\/};

  # Win32's FindFirst rejects paths ending with a separator. Legacy code may
  # still pass such paths, so handle them gracefully by matching ".".
  if ( substr( $searchDir, -1 ) eq '/' ) {
    $self->{searchDir} = $searchDir;
    $self->{wildcard}  = '.';
    return true;
  }

  my $lastSlash = rindex $searchDir, '/';

  if ( $lastSlash < 0 ) {
    $self->{wildcard}  = $searchDir;
    $self->{searchDir} = './';
  }
  else {
    $self->{wildcard}  = substr $searchDir, $lastSlash + 1;
    $self->{searchDir} = substr $searchDir, 0, $lastSlash + 1;
  }

  # '*.*' means any name, any extension in the 32-bit Borland-compatible model.
  $self->{wildcard} = '*'
    if $self->{wildcard} eq '*.*';

  return true;
};

$matchEntry = sub {    # $bool ($entry)
  my ( $self, $entry ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Str $entry );

  return false
    unless $self->$wildcardMatch( $self->{wildcard}, $entry );

  my $path = $self->{searchDir} . $entry;
  my @st = stat $path;
  return false
    unless @st;

  my $fileAttr = $self->$cvtAttr( \@st, $entry );
  return false
    unless $self->$attrMatch( $fileAttr );

  # Match found, fill finfo.
  my $finfo = $self->{finfo};
  $finfo->[size]   = $st[7];
  $finfo->[attrib] = $fileAttr;
  $self->$cvtTime( \@st, $finfo );

  my $name = substr $entry, 0, MAXPATH - 1;
  $finfo->[name] = $name;

  return true;
};

$attrMatch = sub {    # $bool ($attrib)
  my ( $self, $attrib ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $attrib );
  assert ( is_Int $self->{searchAttr} );

  # Behaviour from the original _dos_findnext: if requested attribute word
  # includes hidden, system, or subdirectory bits, return normal files and
  # those with any of the requested attributes.
  return !( $attrib & SPECIAL_BITS )
      || ( $self->{searchAttr} & $attrib & SPECIAL_BITS );
};

$wildcardMatch = sub {    # $bool ($wildcard, $filename)
  my ( $self, $wildcard, $filename ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Str $wildcard );
  assert ( is_Str $filename );

  pos $wildcard = 0;

  # https://stackoverflow.com/a/3300547
  while ( pos( $wildcard ) < length $wildcard ) {
    my $wc = substr $wildcard, pos( $wildcard ), 1;
    pos( $wildcard )++;

    SWITCH: for ( $wc ) {
      $_ eq '?' and do {
        return false
          if $filename eq '';
        substr $filename, 0, 1, '';
        last;
      };
      $_ eq '*' and do {
        return true
          if pos( $wildcard ) == length $wildcard;

        my $rest = substr $wildcard, pos( $wildcard );
        for ( my $i = 0; $i < length $filename; ++$i ) {
          return true
            if $self->$wildcardMatch( $rest, substr( $filename, $i ) );
        }

        return false;
      };
      DEFAULT: {
        return false
          if $filename eq '';
        return false
          if substr( $filename, 0, 1 ) ne $wc;
        substr $filename, 0, 1, '';
      }
    }
  }

  return $filename eq '';
};

$cvtAttr = sub {    # $attr ($stat, $filename)
  my ( $self, $st, $filename ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_ArrayLike $st );
  assert ( is_Str $filename );

  # Returns file attributes in find_t format.
  my $mode = $st->[2];
  my $attr = 0; # _A_NORMAL

  if ( substr( $filename, 0, 1 ) eq '.' ) {
    $attr |= _A_HIDDEN;
  }
  if ( S_ISDIR( $mode ) ) {
    $attr |= _A_SUBDIR;
  }
  elsif ( !S_ISREG( $mode ) ) {       # If not a regular file
    $attr |= _A_SYSTEM;
  }
  elsif ( !( $mode & S_IWUSR ) ) {    # If no write access, innacurate.
    $attr |= _A_RDONLY;
  }
  return $attr;
};

$cvtTime = sub {    # void ($stat, $fileinfo)
  my ( $self, $st, $fileinfo ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_ArrayLike $st );
  assert ( is_ArrayLike $fileinfo );

  # Updates fileinfo with the times in st.
  my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime $st->[9];

  my $fatDate = ( ( $year - 80 ) << 9 )    # Year-1980
              | ( ( $mon + 1 )   << 5 )    # Month (1-12)
              |     $mday;                 # Day of the month (1–31)

  my $fatTime = ( $hour << 11 )            # Hour (0-23)
              | ( $min  << 5  )            # Minutes (0-59)
              | int( $sec / 2 );           # Seconds divided by 2

  $fileinfo->[wr_date] = $fatDate;
  $fileinfo->[wr_time] = $fatTime;

  return;
};

1

__END__

=head1 NAME

TUI::StdDlg::FindFirstRec::Unix - Unix implementation of FindFirstRec

=head1 DESCRIPTION

C<TUI::StdDlg::FindFirstRec::Unix> provides the Unix-specific implementation of 
the C<FindFirstRec> directory search interface.

The implementation maps the generic search operations to native Unix directory 
handling using directory streams and file status information.

Path names are split into a search directory and a wildcard pattern. Directory 
entries are matched against the wildcard and converted into I<Turbo Vision> 
compatible C<find_t> records.

=head1 CONSTRUCTOR

=head2 allocate

Creates or reinitializes a directory search associated with a C<find_t>
record.

=head1 METHODS

=head2 get

Retrieves the search context associated with a C<find_t> record.

=head2 next

Advances the search and updates the associated C<find_t> structure with
information about the next matching filesystem entry.

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
