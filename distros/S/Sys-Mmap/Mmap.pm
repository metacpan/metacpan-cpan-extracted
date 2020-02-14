package Sys::Mmap;

=head1 NAME

Sys::Mmap - uses mmap to map in a file as a Perl variable

=head1 SYNOPSIS

    use Sys::Mmap;

    Sys::Mmap->new( my $str, 8192, 'structtest2.pl' ) or die $!;
    Sys::Mmap->new( $var, 8192 ) or die $!;

    mmap( $foo, 0, PROT_READ, MAP_SHARED, FILEHANDLE ) or die "mmap: $!";
    @tags = $foo =~ /<(.*?)>/g;
    munmap($foo) or die "munmap: $!";

    mmap( $bar, 8192, PROT_READ | PROT_WRITE, MAP_SHARED, FILEHANDLE );
    substr( $bar, 1024, 11 ) = "Hello world";

    mmap( $baz, 8192, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANON, STDOUT );

    $addr = mmap( $baz, 8192, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANON, STDOUT );
    Sys::Mmap::hardwire( $qux, $addr, 8192 );

=head1 DESCRIPTION

The Sys::Mmap module uses the POSIX L<mmap|https://en.wikipedia.org/wiki/Mmap> call
to map in a file as a Perl variable.  Memory access by mmap may be shared
between threads or forked processes, and may be a disc file that has been
mapped into memory.  L<Sys::Mmap> depends on your operating system supporting
UNIX or POSIX.1b mmap, of course.

B<Note> that L<PerlIO> now defines a C<:mmap> tag and presents mmap'd files as
regular files, if that is your cup of joe.

Several processes may share one copy of the file or string, saving memory, and
concurrently making changes to portions of the file or string. When not used
with a file, it is an alternative to SysV shared memory. Unlike SysV shared
memory, there are no arbitrary size limits on the shared memory area, and
sparse memory usage is handled optimally on most modern UNIX implementations.

Using the C<new()> method provides a C<tie()>'d interface to C<mmap()> that
allows you to use the variable as a normal variable. If a filename is provided,
the file is opened and mapped in. If the file is smaller than the length
provided, the file is grown to that length.  If no filename is provided,
anonymous shared inheritable memory is used. Assigning to the variable will
replace a section in the file corresponding to the length of the variable,
leaving the remainder of the file intact and unmodified. Using C<substr()>
allows you to access the file at an offset, and does not place any requirements
on the length argument to C<substr()> or the length of the variable being
inserted, provided it does not exceed the length of the memory region. This
protects you from the pathological cases involved in using C<mmap()> directly,
documented below.

When calling C<mmap()> or C<hardwire()> directly, you need to be careful how
you use the variable. Some programming constructs may create copies of a string
which, while unimportant for smallish strings, are far less welcome if you're
mapping in a file which is a few gigabytes big. If you use C<PROT_WRITE> and
attempt to write to the file via the variable you need to be even more careful.
One of the few ways in which you can safely write to the string in-place is by
using C<substr()> as an lvalue and ensuring that the part of the string that
you replace is exactly the same length.  Other functions will allocate other
storage for the variable, and it will no longer overlay the mapped in file.

=over 4

=item Sys::Mmap->new( C<VARIABLE>, C<LENGTH>, C<OPTIONALFILENAME> )

Maps C<LENGTH> bytes of (the contents of) C<OPTIONALFILENAME> if
C<OPTIONALFILENAME> is provided, otherwise uses anonymous, shared inheritable
memory. This memory region is inherited by any C<fork()>ed children.
C<VARIABLE> will now refer to the contents of that file.  Any change to
C<VARIABLE> will make an identical change to the file.  If C<LENGTH> is zero
and a file is specified, the current length of the file will be used.  If
C<LENGTH> is larger then the file, and C<OPTIONALFILENAME> is provided, the
file is grown to that length before being mapped.  This is the preferred
interface, as it requires much less caution in handling the variable.
C<VARIABLE> will be tied into the "Sys::Mmap" package, and C<mmap()> will be
called for you.

Assigning to C<VARIABLE> will overwrite the beginning of the file for a length
of the value being assigned in. The rest of the file or memory region after
that point will be left intact.  You may use C<substr()> to assign at a given
position:

    substr(VARIABLE, POSITION, LENGTH) = NEWVALUE

=item mmap(VARIABLE, LENGTH, PROTECTION, FLAGS, FILEHANDLE, OFFSET)

Maps C<LENGTH> bytes of (the underlying contents of) C<FILEHANDLE> into your
address space, starting at offset C<OFFSET> and makes C<VARIABLE> refer to that
memory. The C<OFFSET> argument can be omitted in which case it defaults to
zero. The C<LENGTH> argument can be zero in which case a stat is done on
C<FILEHANDLE> and the size of the underlying file is used instead.

The C<PROTECTION> argument should be some ORed combination of the constants
C<PROT_READ>, C<PROT_WRITE> and C<PROT_EXEC>, or else C<PROT_NONE>. The
constants C<PROT_EXEC> and C<PROT_NONE> are unlikely to be useful here but are
included for completeness.

The C<FLAGS> argument must include either C<MAP_SHARED> or C<MAP_PRIVATE> (the
latter is unlikely to be useful here).  If your platform supports it, you may
also use C<MAP_ANON> or C<MAP_ANONYMOUS>.  If your platform supplies
C<MAP_FILE> as a non-zero constant (necessarily non-POSIX) then you should also
include that in C<FLAGS>.  POSIX.1b does not specify C<MAP_FILE> as a C<FLAG>
argument and most if not all versions of Unix have C<MAP_FILE> as zero.

mmap returns C<undef> on failure, and the address in memory where the variable
was mapped to on success.

=item munmap(VARIABLE)

Unmaps the part of your address space which was previously mapped in with a
call to C<mmap(VARIABLE, ...)> and makes VARIABLE become undefined.

munmap returns 1 on success and undef on failure.

=item hardwire(VARIABLE, ADDRESS, LENGTH)

Specifies the address in memory of a variable, possibly within a region you've
C<mmap()>ed another variable to. You must use the same precautions to keep the
variable from being reallocated, and use C<substr()> with an exact length. If
you C<munmap()> a region that a C<hardwire()>ed variable lives in, the
C<hardwire()>ed variable will not automatically be C<undef>ed. You must do this
manually.

=item Constants

The Sys::Mmap module exports the following constants into your namespace:

    MAP_SHARED MAP_PRIVATE MAP_ANON MAP_ANONYMOUS MAP_FILE
    MAP_NORESERVE MAP_POPULATE
    MAP_HUGETLB MAP_HUGE_2MB MAP_HUGE_1GB 
    PROT_EXEC PROT_NONE PROT_READ PROT_WRITE

Of the constants beginning with C<MAP_>, only C<MAP_SHARED> and C<MAP_PRIVATE>
are defined in POSIX.1b and only C<MAP_SHARED> is likely to be useful.

=back

=head1 BUGS

Scott Walters doesn't know XS, and is just winging it. There must be a better
way to tell Perl not to reallocate a variable in memory...

The C<tie()> interface makes writing to a substring of the variable much less
efficient.  One user cited his application running 10-20 times slower when C<<
Sys::Mmap->new() >> is used than when C<mmap()> is called directly.

Malcolm Beattie has not reviewed Scott's work and is not responsible for any
bugs, errors, omissions, stylistic failings, importabilities, or design flaws
in this version of the code.

There should be a tied interface to C<hardwire()> as well.

Scott Walter's spelling is awful.

C<hardwire()> will segfault Perl if the C<mmap()> area it was referring to is
C<munmap()>'d out from under it.

C<munmap()> will segfault Perl if the variable was not successfully C<mmap()>'d
previously, or if it has since been reallocated by Perl.

=head1 AUTHOR

CowboyTim added support for MAP_NORESERVE, MAP_HUGETLB, MAP_HUGE_2MB, and MAP_HUGE_1GB.
Thanks CowboyTim!

Todd Rinaldo cleaned up code, modernized again, and merged in many fixes,
2010-2011.

Scott Walters updated for Perl 5.6.x, additions, 2002.

Malcolm Beattie, 21 June 1996.

=cut

use strict;
use warnings;

our $VERSION = '0.20';

our $AUTOLOAD; # For sub AUTOLOAD

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(mmap munmap
	     MAP_ANON MAP_ANONYMOUS MAP_FILE MAP_LOCKED MAP_PRIVATE MAP_SHARED MAP_NORESERVE
    MAP_POPULATE
    MAP_HUGETLB
    MAP_HUGE_2MB
    MAP_HUGE_1GB
	     PROT_EXEC PROT_NONE PROT_READ PROT_WRITE);


sub new {

  if(scalar @_ < 3) {
    warn 'Usage: Sys::Mmap->new( $var, $desiredSize, $optFile );';
    return undef;
  }

  my $type = $_[0];
  my $leng = $_[2];

  tie $_[1], $_[0], @_[2 .. scalar(@_)-1 ];
  # tie $_[1], $type, $leng;

}

sub TIESCALAR {

  if(scalar @_ < 2) {
    # print "debug: got args: ", join ', ', @_, "\n";
    warn 'Usage: tie $var, "Sys::Mmap", $desiredSize, $optionalFile;';
    return undef;
  }

  my $me;
  my $fh;

  my $type = shift;
  my $leng = shift;
  my $file = shift;

  my $flags = constant('MAP_INHERIT',0)|
              constant('MAP_SHARED',0);

  if($file) {
    open $fh, '+>>', $file or do {
      warn "mmap: could not open file '$file' for append r/w";
      return undef;
    };
    # if we dont pad the file out to the specified length, we coredump
    my $fhsize = -s $fh;
    if($leng > $fhsize) {
      $fhsize = $leng - $fhsize;
      print $fh ("\000" x $fhsize) or die $!;
      # print $fh pack("a$fhsize", '') or die $!;
      # while($fhsize) { print $fh "\000"; $fhsize--; }
    }
    $flags |= constant('MAP_FILE',0);
  } else {
    $flags |= constant('MAP_ANON',0);
  }

  my $addr = mmap(
      $me,
      $leng,
      constant('PROT_READ',0)|constant('PROT_WRITE',0),
      $flags,
      $file ? $fh : *main::STDOUT
  ) or die $!;

  bless \$me, $type;

  # XXX return $addr somehow...
}

sub STORE {
  my $me = shift;
  my $newval = shift;
  substr($$me, 0, length($newval), $newval);
  $$me;
}

sub FETCH {
  my $me = shift;
  $$me;
}

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    if ($AUTOLOAD =~ /::(_?[a-z])/) {
        $AutoLoader::AUTOLOAD = $AUTOLOAD;
        goto &AutoLoader::AUTOLOAD;
    }

    local $! = 0;
    my $constname = $AUTOLOAD;
    $constname =~ s/.*:://;
    return if $constname eq 'DESTROY';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! == 0) {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    else {
        require Carp;
        Carp::croak("Your vendor has not defined Sys::Mmap macro $constname");
    }

    goto &$AUTOLOAD;
}

eval {
       require XSLoader;
       XSLoader::load( 'Sys::Mmap', $VERSION );
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    bootstrap Sys::Mmap $VERSION;
};

1;

__END__

