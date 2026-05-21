#!/usr/bin/perl
# vim: ts=2 sw=2 ft=perl
package Nobody::Util;
our (@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS,%EXP);
BEGIN {
  @ISA = qw(Exporter);
};
BEGIN { STDOUT->autoflush(1); }
use common::sense;
use Path::Tiny;
use Nobody::PP;
use Import::Into;
my(%use);
use Carp;
use Carp @Carp::EXPORT_OK;
sub serdate;
my($count);
BEGIN { $count=100 };
sub find {
  local(@_)=@_;
  my(@r);
  my(@d)=grep { -d $_[$_] } keys @_;
  my(@f)=grep { !-d $_[$_] } keys @_;
  @_=@_[@d,@f];
  while(@_ and -d $_[0]){
    local($_)=path(shift);
    if(-d) {
      my(@tmp)=$_->children();
      unshift(@_,grep { -d } @tmp);
      push(@_,grep { !-d } @tmp);
    } else {
      push(@_,$_);
    };
  };
  @_;
};
sub add_use {
  die "usage: add_use(str,str)" unless @_==2;
  my($pkg)=shift;
  die "$pkg done" if defined $use{$pkg};
  $use{$pkg}=shift;
  eval "use $pkg";
  my(@arr)=eval "$use{$pkg}";
  push(@EXPORT,@arr);
  for( "use $pkg $use{$pkg};" ) {
    eval;
    warn "($_)\n$@" if "$@";
  };
};
BEGIN {
  no strict 'subs';
  add_use( Fcntl        =>   '@Fcntl::EXPORT_OK' );
  add_use( File::stat   =>   '@File::stat::EXPORT_OK' );
  add_use( FindBin  =>    'qw( $Bin $RealBin $Script $RealScript $Dir )' );
  add_use( Import::Into => '@Import::Into::EXPORT_OK' );
  add_use( List::Util   => '@List::Util::EXPORT_OK' );
  add_use( Nobody::PP => '@Nobody::PP::EXPORT_OK' );
  add_use( POSIX        =>   'qw( strftime mktime ) ' );
  add_use( Path::Tiny   =>   'qw( path ) ' );
  add_use( Scalar::Util => '@Scalar::Util::EXPORT_OK' );
  add_use( Sub::Util    => '( grep { $_ ne "set_prototype" } @Sub::Util::EXPORT_OK )' );
  add_use( common::sense=> '' );
  add_use( strict=>'' );
  add_use( warnings=>'' );
};
BEGIN {
  if ($] >= 5.036) {
    warnings->unimport('experimental::builtin');
  }
}

our $VERSION = '0.01';

# ---------------------------------------------------------------------------
# Exporter setup
# ---------------------------------------------------------------------------
require Exporter;
BEGIN {
  push(@EXPORT , qw(
    avg         basename    child_wait  class
    deparse     dirname     file_id     flatten
    getcwd      getfds      getfl       lcmp
    lsort       max         maybeRef    methods
    methods_via min         mkref       nonblock
    open_fds    pad         pasteLines  safe_blessed
    safe_can    safe_isa    serdate     serial_maker
    setfl       sum         uniq        uri
    vcmp        vsort exports
    path pp ppx dd ddx ee eex
    ));
}

# Re-export everything available from these modules.
# The @Module::EXPORT_OK pattern is self-maintaining: if upstream adds
# a new function, it automatically becomes available here.
sub exports {
  return { exports(@_) } unless wantarray;
  my($pkg)=shift;
  unless(defined($pkg)) {
    my(@inc);
    @inc=grep { s{/}{::}g and s{.pm$}{}; } keys %INC;
    exports($_) for @inc;
  };
  die "usage: exports('pkg_name')" unless !@_;
  no strict 'refs';
  $EXP{$pkg}={
    EXPORT=>\@{${$pkg.'::'}{EXPORT}},
    EXPORT_OK=>\@{${$pkg.'::'}{EXPORT_OK}},
    EXPORT_TAGS=>\%{${$pkg.'::'}{EXPORT_TAGS}}
  };
  return defined($pkg)?($pkg=>$EXP{$pkg}):(%EXP);
};
BEGIN {
  @EXPORT_OK=@EXPORT;
  %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );
  require Exporter;
};
sub import {
  use Import::Into;
  shift->export_to_level(1);
  common::sense->import::into(1);
};


# ---------------------------------------------------------------------------
# File descriptor utilities
# ---------------------------------------------------------------------------

sub open_fds(;$) {
  my $dn = "/proc/self/fd/";
  if (@_ && $_[0]) {
    map { $_, readlink "$dn$_" } &open_fds();
  } else {
    opendir(my $dir, $dn);
    my $no = fileno($dir);
    grep { $_ ne '.' && $_ ne '..' && ($no - $_) } readdir($dir);
  }
}

sub getfds() {
  opendir(my $dir, "/proc/self/fd");
  my $no = fileno($dir);
  my @fds;
  while (readdir($dir)) {
    push @fds, $_;
  }
  closedir($dir);
  return grep { $_ != $no } @fds;
}

sub getcwd {
  return readlink("/proc/self/cwd");
}

sub getfl(*) {
  my ($fh) = shift;
  return fcntl($fh, F_GETFL, 0);
}

sub setfl(*$) {
  my ($fh)  = shift;
  my ($val) = shift;
  fcntl($fh, F_SETFL, $val);
}
sub bits {
  my($v)=int(shift);
  local(@_)=$v;
  while($v) {
    push(@_,($v&1));
    $v>>=1;
  };
  reverse @_;
};
sub nonblock(*;$) {
  my ($fh) = shift;
  my ($o)=getfl($fh);
  my ($v)=O_NONBLOCK;
  my ($n)=$o;
  if(@_ and !$_[0]){
    $v=~$v;
    $n=$n&(~$v);
  } else {
    $n=$n|$v;
  };
  setfl($fh,$n);
}

# ---------------------------------------------------------------------------
# Object / reference utilities
# ---------------------------------------------------------------------------

sub class($) {
  return ref || $_ || 'undef' for shift;
}

sub safe_isa {
  my ($self)  = shift;
  my ($class) = shift;
  return undef unless ref($self);
  return undef unless blessed($self);
  return $self->isa($class);
}

sub safe_blessed {
  my ($self) = shift;
  return undef unless ref($self);
  return blessed($self);
}

sub safe_can {
  my ($self) = shift;
  my ($meth) = shift;
  return undef unless safe_blessed($self);
  return $self->can($meth);
}

sub mkref {
  return ref($_[0]) ? $_[0] : \$_[0];
}

sub maybeRef($) {
  die "use class, not maybeRef";
  goto \&class;
}

sub flatten(@) {
  return map { &flatten($_) } @_ unless @_ == 1;
  local ($_) = shift;
  return &flatten(@$_) if ref($_) && reftype($_) eq 'ARRAY';
  return &flatten(%$_) if ref($_) && reftype($_) eq 'HASH';
  return $_;
}

# ---------------------------------------------------------------------------
# String / list utilities
# ---------------------------------------------------------------------------

sub pad {
  local (@_) = @_;
  my ($max) = List::Util::max(map { length } @_);
  for (@_) {
    $_ = join("", $_, '.' x ($max - length));
  }
  @_;
}

sub pasteLines(@) {
  for (join("", @_)) {
    s{\\\n?$}{}sm;
  }
  return join("\n", @_) unless wantarray;
  return @_;
}

sub lsort {
  return sort { length($a) <=> length($b) || $a cmp $b } @_;
}

sub lcmp {
  return length($a) <=> length($b) || $a cmp $b;
}

# ---------------------------------------------------------------------------
# Version comparison
# ---------------------------------------------------------------------------

sub vcmp {
  my ($a, $b) = (
    @_ == 2 ? (shift, shift) :
    @_       ? do { warn "Warning: vcmp wants 2 args or none"; (undef, undef) } :
               ($a, $b)
  );
  my @a = split m{(\D+)}, $a;
  my @b = split m{(\D+)}, $b;
  no warnings;
  while (@a and @b and $a[0] eq $b[0]) {
    shift @a;
    shift @b;
  }
  return 0 unless @a or @b;
  return @a <=> @b unless @a and @b;
  return $a[0] <=> $b[0] || $a[0] cmp $b[0];
}

sub vsort {
  return sort { vcmp($a, $b) } @_;
}

# ---------------------------------------------------------------------------
# Date / time
# ---------------------------------------------------------------------------

sub serdate(;$) {
  my $time = @_ ? $_[0] : time;
  return strftime("%Y%m%d-%H%M%S", gmtime($time));
}

# ---------------------------------------------------------------------------
# Process utilities
# ---------------------------------------------------------------------------

sub child_wait {
  my $kid;
  do {
    $kid = waitpid(0, 0);
    warn "$kid returned $?" if $kid > 1 and $?;
  } while ($kid > 1);
}

# ---------------------------------------------------------------------------
# File utilities
# ---------------------------------------------------------------------------

sub file_id {
  die "useless use of file_id in void context" unless defined wantarray;
  local ($_) = shift;
  return undef unless defined;
  $_ = path($_) unless ref($_);
  return undef unless $_->exists;
  $_->stat;
  return sprintf("%016x:%016x", $st_dev, $st_ino);
}

sub uri {
  eval 'require URI';
  die "$@" if "$@";
  return URI->new($_[0]);
}

# ---------------------------------------------------------------------------
# Serial file/directory maker
# ---------------------------------------------------------------------------

sub serial_maker(%) {
  my (%arg) = %{ $_[0] };
  my ($fmt) = $arg{fmt} // die "format is required";
  my ($max) = $arg{max} // 1000;
  my ($min) = $arg{min} // 0;
  my ($dir) = !!$arg{dir};
  my ($num) = $min;
  return sub {
    local ($_);
    my %res = (fh => undef, fn => undef);
    for (;;) {
      return undef if ($num >= $max);
      $res{fn} = path(sprintf($fmt, $num));
      $res{fn}->parent->mkpath;
      no autodie qw(sysopen mkdir);
      if ($dir) {
        if (mkdir($res{fn})) {
          return \%res;
        } elsif ($!{EEXIST}) {
          ++$num;
        } else {
          die "mkdir:$res{fn}:$!";
        }
      } else {
        if (sysopen($res{fh}, $res{fn}, Fcntl::O_CREAT | Fcntl::O_EXCL())) {
          return \%res;
        } elsif ($!{EEXIST}) {
          ++$num;
        } else {
          die "sysopen:$res{fn}:$!";
        }
      }
    }
  };
}

# ---------------------------------------------------------------------------
# Introspection
# ---------------------------------------------------------------------------

sub deparse {
  require B::Deparse;
  my $coderef = shift // die "deparse: coderef required";
  my $dp = B::Deparse->new("-p", "-sC");
  return join(' ', 'sub{', $dp->coderef2text($coderef), '}');
}

our %seen;

sub methods {
  my $class = class(shift);
  local %seen;
  methods_via($class, '', 1);
  methods_via('UNIVERSAL', 'UNIVERSAL', 0);
}

sub methods_via {
  my $class = class(shift);
  return if $seen{$class}++;
  my $prefix  = shift;
  my $prepend = $prefix ? "via $prefix: " : '';
  my @to_print;
  my $class_ref = do { no strict "refs"; \%{$class . '::'} };
  while (my ($name, $glob) = each %$class_ref) {
    if (
      (ref $glob || ($glob && ref \$glob eq 'GLOB' && defined &$glob))
      && !$seen{$name}++
    ) {
      push @to_print, "$prepend$name\n";
    }
  }
  {
    local $\ = '';
    local $, = '';
    print $_ foreach sort @to_print;
  }
  return unless shift;
  my $class_ISA_ref = do { no strict "refs"; \@{"${class}::ISA"} };
  for my $name (@$class_ISA_ref) {
    $prepend = $prefix ? $prefix . " -> $name" : $name;
    methods_via($name, $prepend, 1);
  }
}

sub print_methods {
  require mro;
  ddx(methods(ref($_[0])));
}

1;

=head1 NAME

Nobody::Util - Utilities Nobody Uses

=head1 SYNOPSIS

  use Nobody::Util;

  my $id   = file_id("/etc/passwd");
  my $date = serdate();
  my @vers = vsort(qw( 1.10 1.9 2.0 1.1 ));
  my $cwd  = getcwd();

=head1 DESCRIPTION

C<Nobody::Util> is a collection of utility functions accumulated over years
of Perl development by Rich Paul (CPAN: NOBODY).  It is, as the name
suggests, full of things that nobody else does — but that save time.

The module re-exports commonly needed symbols from C<Carp>, C<List::Util>,
C<Scalar::Util>, C<Sub::Util>, C<POSIX>, C<Fcntl>, C<Path::Tiny>, and
C<FindBin> so that most scripts need only C<use Nobody::Util> to get a
useful working environment.

=head1 EXPORTED BY DEFAULT

All functions listed under L</FUNCTIONS> are exported by default.

=head1 EXPORT_OK / EXPORT_TAGS

  use Nobody::Util qw( :all );   # everything, including re-exports

=head1 FUNCTIONS

=head2 File Descriptor Utilities

=over 4

=item open_fds( [$resolve] )

Returns a list of open file descriptor numbers for the current process.
If C<$resolve> is true, returns a flat list of C<fd =E<gt> path> pairs.

=item getfds()

Like C<open_fds> but includes the directory fd used internally.

=item getcwd()

Returns the current working directory by reading C</proc/self/cwd>.

=item getfl( $fh )

Returns the file status flags for C<$fh> via C<fcntl(F_GETFL)>.

=item setfl( $fh, $flags )

Sets the file status flags for C<$fh> via C<fcntl(F_SETFL)>.

=item nonblock( $fh )

Sets C<O_NONBLOCK> on C<$fh>.

=back

=head2 Object / Reference Utilities

=over 4

=item class( $thing )

Returns C<ref($thing)> if it is a reference, C<$thing> itself if it is a
plain string (class name), or C<'undef'> if it is undefined.

=item safe_isa( $obj, $class )

Returns true if C<$obj> is a blessed reference that C<isa> C<$class>.
Returns C<undef> rather than dying if C<$obj> is not a reference.

=item safe_blessed( $obj )

Returns the class name if C<$obj> is blessed, C<undef> otherwise.

=item safe_can( $obj, $method )

Returns the method coderef if C<$obj> is blessed and can C<$method>,
C<undef> otherwise.

=item mkref( $thing )

Returns C<$thing> if it is already a reference, otherwise C<\$thing>.

=item flatten( @list )

Recursively flattens arrays and hashes in C<@list> into a flat list.

=back

=head2 String / List Utilities

=over 4

=item pad( @strings )

Right-pads all strings to the length of the longest, using C<.> as fill.

=item pasteLines( @strings )

Joins strings, removing line-continuation backslashes.

=item lsort( @list )

Sorts by length first, then lexicographically.

=item lcmp

Sort comparator for C<lsort> (length then lex).

=back

=head2 Version Comparison

=over 4

=item vcmp( $a, $b )

Compares two version strings numerically segment by segment.

=item vsort( @versions )

Sorts a list of version strings using C<vcmp>.

=back

=head2 Date / Time

=over 4

=item serdate( [$time] )

Returns a sortable timestamp string in C<YYYYMMDD-HHMMSS> format (UTC).
Defaults to the current time.

=back

=head2 Process Utilities

=over 4

=item child_wait()

Waits for all child processes to exit, warning on non-zero exit status.

=back

=head2 File Utilities

=over 4

=item file_id( $path )

Returns a unique string identifier for a file based on its device and
inode numbers, suitable for detecting hard links.

=item uri( $string )

Constructs and returns a C<URI> object.  C<URI> is loaded on demand.

=item serial_maker( %args )

Returns a closure that generates sequentially-numbered unique files or
directories.  Arguments: C<fmt> (sprintf format, required), C<min>
(default 0), C<max> (default 1000), C<dir> (make directories if true).

=back

=head2 Introspection

=over 4

=item deparse( $coderef )

Returns a string representation of C<$coderef> using C<B::Deparse>.

=item methods( $obj_or_class )

Prints all methods available to C<$obj_or_class>, including inherited ones.

=item methods_via( $class, $prefix, $crawl_upward )

Worker for C<methods()>; crawls the C<@ISA> tree.

=item print_methods( $obj_or_class )

Like C<methods()> but pretty-prints via C<ddx>.

=back

=head1 AUTHOR

Rich Paul, C<< <nobody at cpan.org> >>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
