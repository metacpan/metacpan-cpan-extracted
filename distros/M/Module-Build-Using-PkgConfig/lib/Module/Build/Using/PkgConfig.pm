#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Module::Build::Using::PkgConfig;

use strict;
use warnings;
use 5.010;  # //
use base qw( Module::Build );

use ExtUtils::PkgConfig;

our $VERSION = '0.03';

=head1 NAME

C<Module::Build::Using::PkgConfig> - extend C<Module::Build> to more easily use platform libraries provided by F<pkg-config>

=head1 SYNOPSIS

In F<Build.PL>:

   use Module::Build::Using::PkgConfig;

   my $build = Module::Build::Using::PkgConfig->new(
      module_name => "Module::Here",
      ... # other arguments as per Module::Build
   );

   # A platform library provided by pkg-config
   $build->use_pkgconfig( "libfoo" );

   # We need at least a given version
   $build->use_pkgconfig( "libbar",
      atleast_version => "0.5",
   );

   # A platform librariy that's also wrapped as an Alien module
   $build->use_pkgconfig( "libsplot",
      atleast_version => "1.0",
      alien           => "Alien::libsplot",
      alien_version   => "0.05", # Alien::libsplot 0.05 provides libsplot v1.0
   );

   $build->create_build_script;

=head1 DESCRIPTION

This subclass of L<Module::Build> provides some handy methods to assist the
F<Build.PL> script of XS-based module distributions that make use of platform
libraries managed by F<pkg-config>.

As well as supporting libraries installed on a platform-wide basis and thus
visible to F<pkg-config> itself, this subclass also assists with
C<Alien::>-based wrappers of these system libraries, allowing them to be
dynamically installed at build time if the platform does not provide them.

=head2 RPATH generation

This module also provides some helper code to generate the required C<RPATH>
arguments needed to link against the libraries found by inspecting the
C<extra_linker_flags>. This attempts to duplicate the same logic performed
by F<libtool> when it would link a C program or library, as we don't get to
use its code when linking dynamic libraries for Perl.

=head1 PROPERTIES

=over 4

=item no_late_aliens => BOOL

If true, applies the C<no_late_alien> option to every use of C<use_pkgconfig>
that specifies an Alien module.

=back

=cut

=head1 METHODS

=cut

__PACKAGE__->add_property( 'no_late_aliens' );

sub new
{
   my $class = shift;
   my $self = $class->SUPER::new( @_ );

   $self->configure_requires->{ +__PACKAGE__ } //= 0;
   $self->configure_requires->{ $_ } //= 0 for our @ISA;

   if( $self->notes( 'late_aliens' ) ) {
      $self->notes( 'late_aliens' => undef );
   }

   return $self;
}

=head2 use_pkgconfig

   $build->use_pkgconfig( $modname, ... )

Requires the given F<pkg-config> module of the given version, and extends
the compiler and linker arguments sufficient to build from it.

Takes the following named options:

=over 4

=item atleast_version => $modver

If given, the F<pkg-config> module is required to be at least the given
version. If unspecified, then any version is considered sufficient.

=item alien => $alien

If given and the F<pkg-config> module does not exist, try to use the given
C<Alien::> module to provide it instead.

If this module is not yet available and the C<no_late_alien> option is not
true, the Alien module is added to the C<requires> dynamic dependencies and
checked again at C<build> action time.

=item no_late_alien => BOOL

If true, suppresses the dynamic C<requires> feature of Alien modules
described above.

=item alien_version => $version

If the C<Alien::> module is not available, gives the module version of it that
will be required to provide the F<pkg-config> module of the required version.
This gets added to C<requires>.

=back

If neither the F<pkg-config> module and no C<Alien::> module was requested (or
none was found and C<no_late_alien> was set), this method dies with an
C<OS unsupported> message, which is usually what is required for a F<Build.PL>
script.

=head2 try_pkconfig

   $ok = $build->try_pkconfig( $modname, ... )

Boolean-returning version of L</use_pkgconfig>. If successful, returns true.
If it fails it returns false rather than dying, allowing the F<Build.PL>
script to take alternative action.

=cut

sub try_pkgconfig
{
   my $self = shift;
   my ( $modname, %args ) = @_;

   my $atleast_version = $args{atleast_version} // 0;

   if( $self->pkgconfig_atleast_version( $modname, $atleast_version ) ) {
      print "Using $modname from pkg-config\n";
      $self->add_cflags_libs_from_pkgconfig( $modname );
      return 1;
   }

   if( defined( my $alien = $args{alien} ) ) {
      if( $self->alien_atleast_version( $alien, $atleast_version ) ) {
         print "Using $modname from $alien\n";
         $self->add_cflags_libs_from_alien( $alien );
         return 1;
      }

      return 0 if $args{no_late_alien} or $self->no_late_aliens;

      return $self->use_late_alien( $alien, %args );
   }

   return 0;
}

sub use_pkgconfig
{
   my $self = shift;
   my ( $modname ) = @_;

   $self->try_pkgconfig( @_ ) or
      die "OS unsupported - $modname unavailable in pkg-config\n";
}

=head2 pkgconfig_atleast_version

   $ok = $build->pkgconfig_atleast_version( $modname, $modver )

Returns true if the F<pkg-config> module name exists and has at least the
given version.

=cut

sub pkgconfig_atleast_version
{
   my $self = shift;
   my ( $modname, $modver ) = @_;

   # Silence its scary errors
   local *STDERR;
   open STDERR, ">>", "/dev/null" or die "Cannot reopen STDERR - $!";

   print "Checking pkg-config $modname ",
      ( $modver ? "--atleast_version $modver" : "" ),
      "... ";

   my $ret = eval { ExtUtils::PkgConfig->atleast_version( $modname, $modver ) };

   print $ret ? "yes\n" : "no\n";

   return $ret;
}

=head2 add_cflags_libs_from_pkgconfig

   $build->add_cflags_libs_from_pkgconfig( $modname )

Extend the C<extra_compiler_flags> and C<extra_linker_flags> arguments from
the C<--cflags> and C<--libs> from the given F<pkg-config> module name.

=cut

sub add_cflags_libs_from_pkgconfig
{
   my $self = shift;
   my ( $modname ) = @_;

   my $cflags = ExtUtils::PkgConfig->cflags( $modname );
   my $libs   = ExtUtils::PkgConfig->libs( $modname );

   $self->push_extra_compiler_flags( split( m/ +/, $cflags // '' ) );

   $self->push_extra_linker_flags( split( m/ +/, $libs // '' ) );
}

=head2 alien_atleast_version

   $ok = $build->alien_atleast_version( $alien, $modver )

Returns true if the given C<Alien::> module provides a F<pkg-config> module
version at least the given version.

=cut

sub alien_atleast_version
{
   my $self = shift;
   my ( $alien, $modver ) = @_;

   print "Checking $alien ",
      ( $modver ? "atleast-version $modver" : "" ),
      "... ";

   ( my $file = "$alien.pm" ) =~ s{::}{/}g;

   my $ret = eval { require $file and $alien->atleast_version( $modver ) };

   print $ret ? "yes\n" : "no\n";

   return $ret;
}

=head2 add_cflags_libs_from_alien

   $build->add_cflags_libs_from_alien( $alien )

Extend the C<extra_compiler_flags> and C<extra_linker_flags> arguments from
the C<--cflags> and C<--libs> from the given C<Alien::> module name.

=cut

sub add_cflags_libs_from_alien
{
   my $self = shift;
   my ( $alien ) = @_;

   $self->push_extra_compiler_flags( split( m/ +/, $alien->cflags // '' ) );

   $self->push_extra_linker_flags( split( m/ +/, $alien->libs // '' ) );
}

=head2 use_late_alien

   $ok = $build->use_late_alien( $alien, ... )

Adds an Alien module directly to the C<requires> hash, and makes a note to use
its cflags and libraries later at build time.

Normally this method would not be necessary as it is automatically called from
L<use_pkgconfig> if required, but one use-case may be to provide a final
last-ditch attempt after trying some other possible attempts, after an earlier
call to C<use_pkgconfig> with C<no_late_alien> set.

=cut

sub use_late_alien
{
   my $self = shift;
   my ( $alien, %args ) = @_;

   # No Alien module yet
   print "Adding $alien to build_depends\n";

   # Order might matter
   my $late_aliens = $self->notes( 'late_aliens' ) // [];

   push @$late_aliens, { alien => $alien, atleast_version => $args{atleast_version} };
   $self->requires->{$alien} = $args{alien_version} // 0;

   $self->notes( 'late_aliens' => $late_aliens );

   return 1;
}

=head2 push_extra_compiler_flags

   $build->push_extra_compiler_flags( @flags )

Appends more values onto the C<extra_compiler_flags>.

=cut

sub push_extra_compiler_flags
{
   my $self = shift;

   # Eugh; M::B's API here takes lists to set, but returns ARRAYrefs
   $self->extra_compiler_flags( @{ $self->extra_compiler_flags }, @_ );
}

=head2 push_extra_linker_flags

   $build->push_extra_linker_flags( @flags )

Appends more values onto the C<extra_linker_flags>.

=cut

sub push_extra_linker_flags
{
   my $self = shift;

   # Eugh; M::B's API here takes lists to set, but returns ARRAYrefs
   $self->extra_linker_flags( @{ $self->extra_linker_flags }, @_ );
}

sub ACTION_build
{
   my $self = shift;
   my @args = @_;

   if( my $late_aliens = $self->notes( 'late_aliens' ) ) {
      foreach ( @$late_aliens ) {
         my ( $alien, $modver ) = delete @{$_}{qw( alien atleast_version )};

         $self->alien_atleast_version( $alien, $modver ) or
            die "Unable to find $alien providing pkg-config version $modver\n";

         $self->add_cflags_libs_from_alien( $alien );
      }
   }

   if( @{ $self->extra_linker_flags } ) {
      $self->_generate_rpaths;
   }

   $self->SUPER::ACTION_build( @args );
}

sub _generate_rpaths
{
   my $self = shift;

   # This is all a bit of a mess.
   # In general, if we're being asked to link against libraries that aren't on
   # the system search path, we'll have to invent extra -rpath arguments to
   # pass to the linker to set RPATH in the resultant library.
   #
   # To work out what we need, we'll have to recreate the linker's search
   # strategy, looking for actual libFOO.so.NUM files, and accumulate what
   # paths they live in. Subtract from that any standard system locations, and
   # whatever we've got left gets added as RUNPATH
   #
   # Also, none of this is specific to using pkg-config, and could apply
   # equally to any C-library-using code. This probably wants moving to a more
   # generic "Module::Build::Using::C" or somesuch if one ever gets built.
   #
   # Further, this is very GNU/ELF-specific. Likely different logic would
   # apply on Mac OSX, Windows or other platforms.

   # TODO: Hunt /etc/ld.so.conf for more of these
   my @system_libdirs = qw(
      /lib
      /usr/lib
   );

   my @libdirs = @system_libdirs;
   my @rpaths;

   my @ldflags = @{ $self->extra_linker_flags };
   my @extra_linker_flags;

   FLAG: while( @ldflags ) {
      my $flag = shift @ldflags;

      if( $flag =~ m/^-L(.*)$/ ) {
         # Another -LDIR to search in
         push @extra_linker_flags, $flag;

         push @libdirs, $1;
         next FLAG;
      }

      if( $flag =~ m/^-l(.*)$/ ) {
         # Another libFOO.so to hunt for
         push @extra_linker_flags, $flag;

         my $soname = "lib$1.so";
         my $libdir;
         -f "$_/$soname" and $libdir = $_ and last for @libdirs;
         defined $libdir or next FLAG;

         # Skip if it's a system one, or already known
         $_ eq $libdir and next FLAG for @system_libdirs, @rpaths;

         push @rpaths, $libdir;
         next FLAG;
      }

      if( $flag =~ m/^-Wl,-R(.+)$/ or
          $flag =~ m/^-Wl,-rpath[=,](.*)$/ or
          $flag =~ m/^-Wl,-rpath$/ && $ldflags[0] =~ m/^-Wl,(.*)$/ && shift @ldflags ) {
         # Another RPATH is specified. Don't necessarily add it to
         # @extra_linker_flags yet in case it's a duplicate
         my $libdir = $1;

         # Don't try to validate if it's needed though; presume the linker
         # flags generally know best.

         # Skip if it's a system one, or already known
         $_ eq $libdir and next FLAG for @system_libdirs, @rpaths;

         push @rpaths, $libdir;
         next FLAG;
      }

      push @extra_linker_flags, $flag;
   }

   foreach my $rpath ( @rpaths ) {
      push @extra_linker_flags, "-Wl,-rpath=$rpath";
   }

   # Reset the flags to remove any duplicates
   $self->extra_linker_flags( @extra_linker_flags );
}

=head1 TODO

=over 4

=item *

Consider a C<quiet> option to suppress verbose printing

=item *

Consider defining a constructor argument, perhaps C<build_requires_pkgconfig>,
to neaten the common case of simple requirements.

=item *

Consider further stealing the various helper methods from L<ExtUtils::CChecker>
and possibly splitting this class into a lower "C-using XS modules" and
higher-level F<pkg-config>+Alien layer.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
