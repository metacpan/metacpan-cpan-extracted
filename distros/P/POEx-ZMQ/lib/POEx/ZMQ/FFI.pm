package POEx::ZMQ::FFI;
$POEx::ZMQ::FFI::VERSION = '0.005007';
use v5.10;
use Carp;
use strictures 2;

use FFI::Raw;

use List::Objects::WithUtils;

use Math::Int64 qw/
  int64_to_native uint64_to_native
  native_to_int64 native_to_uint64
/;

use Try::Tiny;


sub find_soname {
  my ($class) = @_;

  state $search = array( qw/
    libzmq.so.4
    libzmq.so.4.0.0
    libzmq.so.3
    libzmq.so
    
    libzmq.4.dylib
    libzmq.3.dylib
    libzmq.dylib
  / );

  my $soname;
  SEARCH: for my $maybe ($search->all) {
    try {
      FFI::Raw->new(
        $maybe, zmq_version =>
          FFI::Raw::void,
          FFI::Raw::ptr,
          FFI::Raw::ptr,
          FFI::Raw::ptr,
      );
      $soname = $maybe;
    };
    last SEARCH if defined $soname
  }

  croak "Failed to locate a suitable libzmq in your linker's search path"
    unless defined $soname;

  my $vers = $class->get_version($soname);
  croak "This library requires ZeroMQ 3+ but you only have ".$vers->string
    unless $vers->major >= 3;
  
  $soname
}

sub get_version {
  my ($class, $soname) = @_;
  $soname //= $class->find_soname;

  my $zmq_vers = FFI::Raw->new(
    $soname, zmq_version =>
      FFI::Raw::void,
      FFI::Raw::ptr,  # -> major
      FFI::Raw::ptr,  # -> minor 
      FFI::Raw::ptr,  # -> patch
  );
  my ($maj, $min, $pat) = map {; pack 'i!', $_ } (0, 0, 0);
  $zmq_vers->(
    map {; unpack 'L!', pack 'P', $_ } ($maj, $min, $pat)
  );
  ($maj, $min, $pat) = map {; unpack 'i!', $_ } ($maj, $min, $pat);
  hash(
    major  => $maj,
    minor  => $min,
    patch  => $pat,
    string => join('.', $maj, $min, $pat)
  )->inflate
}


=for Pod::Coverage z(?:un)?pack

=cut

sub _begins { ! index $_[0], $_[1] }

sub zpack {
  my (undef, $type, $val) = @_;

  # See zmq_getsockopt(3) for more on types ->
  if ($type eq 'int') {
    return pack 'i!', $val
  }

  if ( _begins($type => 'int64') ) {
    return int64_to_native($val)
  }

  if ( _begins($type => 'uint64') ) {
    return uint64_to_native($val)
  }

  confess "Unknown type: $type"
}

sub zunpack {
  my (undef, $type, $val, $ptr, $len) = @_;

  if ($type eq 'int') {
    return unpack 'i!', $val
  }

  if ($type eq 'binary') {
    $len = unpack 'L!', $len;
    return if $len == 0;
    return $ptr->tostr($len)
  }

  if ($type eq 'string') {
    return $ptr->tostr
  }

  if ( _begins($type => 'int64') ) {
    return native_to_int64($val)
  }

  if ( _begins($type => 'uint64') ) {
    return native_to_uint64($val)
  }

  confess "Unknown type: $type"
}


1;

=pod

=head1 NAME

POEx::ZMQ::FFI - libzmq3+ FFI wrapper for POEx::ZMQ

=head1 SYNOPSIS

  # Used internally by POEx::ZMQ.

=head1 DESCRIPTION

This is a minimalist L<FFI::Raw> interface to L<ZeroMQ|http://www.zeromq.org>
version 3+, derived from Dylan Cali's L<ZMQ::FFI> (which is where you likely
want to look if you're not using L<POEx::ZMQ>).

=head2 CLASS METHODS

=head3 find_soname

  my $soname = POEx::ZMQ::FFI->find_soname;

Attempts to find an appropriate C<libzmq> dynamic library, with a preference
for the newest known version; croaks on failure.

=head3 get_version

  my $vstruct = POEx::ZMQ::FFI->get_version;
  my $version = $vstruct->string;   # 3.2.1
  my $major = $vstruct->major;      # 3
  my $minor = $vstruct->minor;      # 2
  my $patch = $vstruct->patch;      # 1

Returns a struct-like object containing the L<zmq_version(3)> version
information.

The dynamic library name can be supplied:

  my $vstruct = POEx::ZMQ::FFI->get_version($soname);

... otherwise the library found by L</find_soname> is used.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Significant portions of the FFI backend are derived from L<ZMQ::FFI> by Dylan Cali
(CPAN: CALID).

Licensed under the same terms as Perl.

=cut
