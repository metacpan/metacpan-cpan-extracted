package PkgConfig::LibPkgConf::Client;

use strict;
use warnings;
use PkgConfig::LibPkgConf::XS;
use Scalar::Util ();

our $VERSION = '0.10';

=head1 NAME

PkgConfig::LibPkgConf::Client - Query installed libraries for compiling and linking software

=head1 SYNOPSIS

 use PkgConfig::LibPkgConf::Client;
 
 my $client = PkgConfig::LibPkgConf::Client->new;
 $client->env;
 
 my $pkg = $client->find('libarchive');
 my $cflags = $pkg->cflags;
 my $libs = $pkg->libs;

=head1 DESCRIPTION

The L<PkgConfig::LibPkgConf::Client> objects store all necessary state 
for C<libpkgconf> allowing for multiple instances to run in parallel.

=head1 CONSTRUCTOR

=head2 new

 my $client = PkgConfig::LibPkgConf::Client->new(%opts);
 my $client = PkgConfig::LibPkgConf::Client->new(\%opts);

Creates an instance of L<PkgConfig::LibPkgConf::Client>.  Possible 
options include:

=over 4

=item path

The search path to look for C<.pc> files.  This may be specified
either as a string with the appropriate path separator character,
or as a list reference.  This will override the C<pkgconf> compiled
in defaults and the environment variables for C<PKG_CONFIG_PATH> or
C<PKG_CONFIG_LIBDIR>.

=item filter_lib_dirs

List of directories to filter for libraries.  This overrides the 
C<pkgconf> compiled in default and environment variable for
C<PKG_CONFIG_SYSTEM_LIBRARY_PATH>.

=item filter_include_dirs

List of directories to filter for include.  This overrides the 
C<pkgconf> compiled in default and environment variable for
C<PKG_CONFIG_SYSTEM_INCLUDE_PATH>.

=back

environment variables honored:

=over 4

=item PKG_CONFIG_PATH

=item PKG_CONFIG_LIBDIR

=item PKG_CONFIG_SYSTEM_LIBRARY_PATH

=item PKG_CONFIG_SYSTEM_INCLUDE_PATH

=item PKG_CONFIG_ALLOW_SYSTEM_CFLAGS

=item PKG_CONFIG_ALLOW_SYSTEM_LIBS

=back

=cut

sub new
{
  my $class = shift;
  my $opts = ref $_[0] eq 'HASH' ? { %{$_[0]} } : { @_ };

  my $self = bless {}, $class;

  my $eh = do {
    my $o = $self;
    Scalar::Util::weaken($o);
    sub { $o->error($_[0]) };
  };

  my $path_cvt = sub {
    ref $_[0] ? join(PkgConfig::LibPkgConf::Util::path_sep(), @{$_[0]}) : $_[0];
  };
  
  if($ENV{PKG_CONFIG_ALLOW_SYSTEM_CFLAGS} && !defined $opts->{filter_include_dirs})
  {
    $opts->{filter_include_dirs} = [];
  }
  
  if($ENV{PKG_CONFIG_ALLOW_SYSTEM_LIBS} && !defined $opts->{filter_lib_dirs})
  {
    $opts->{filter_lib_dirs} = [];
  }

  local $ENV{PKG_CONFIG_SYSTEM_LIBRARY_PATH} = $path_cvt->(delete $opts->{filter_lib_dirs}) if defined $opts->{filter_lib_dirs};
  local $ENV{PKG_CONFIG_SYSTEM_INCLUDE_PATH} = $path_cvt->(delete $opts->{filter_include_dirs}) if defined $opts->{filter_include_dirs};

  _init($self, $eh, delete $opts->{maxdepth} || 2000);

  if($opts->{path})
  {
    local $ENV{PKG_CONFIG_PATH} = $path_cvt->(delete $opts->{path});
    $self->_dir_list_build(1);
  }
  else
  {
    $self->_dir_list_build(0);
  }
  
  if(defined $ENV{PKG_CONFIG_TOP_BUILD_DIR})
  {
    $self->buildroot_dir($ENV{PKG_CONFIG_TOP_BUILD_DIR});
  }
  if(defined $ENV{PKG_CONFIG_SYSROOT_DIR})
  {
    $self->sysroot_dir($ENV{PKG_CONFIG_SYSROOT_DIR});
  }

  if(my $global = delete $opts->{global})
  {
    $self->global($_ => $global->{$_}) for keys %$global;
  }

  foreach my $key (sort keys %$opts)
  {
    require Carp;
    Carp::carp("Unused unknown option $key");
  }

  $self;
}

=head1 ATTRIBUTES

=head2 path

 my @path = $client->path;

The search path to look for C<.pc> files.

=head2 filter_lib_dirs

 my @dirs = $client->filter_lib_dirs;

List of directories to filter for libraries.

=head2 filter_include_dirs

 my @dirs = $client->filter_include_dirs;

List of directories to filter for includes.

=head2 sysroot_dir

 my $dir = $client->sysroot_dir;
 $client->sysroot_dir($dir);

Get or set the sysroot directory.

=head2 buildroot_dir

 my $dir = $client->buildroot_dir;
 $client->buildroot_dir($dir);

Get or set the buildroot directory.

=head2 maxdepth

 my $int = $client->maxdepth;
 $client->maxdepth($int);

Get or set the maximum dependency depth.  This is 2000 by default.

=head1 METHODS

=head2 env

 my $client->env;

This method loads settings for the client object from the environment using
the standard C<pkg-config> or C<pkgconf> environment variables.  It honors the
following list of environment variables:

=over 4

=item PKG_CONFIG_LOG

=back

=cut

# PKG_CONFIG_DEBUG_SPEW
# PKG_CONFIG_IGNORE_CONFLICTS
# PKG_CONFIG_PURE_DEPGRAPH
# PKG_CONFIG_DISABLE_UNINSTALLED

sub env
{
  my($self) = @_;
  if($ENV{PKG_CONFIG_LOG})
  {
    $self->audit_set_log($ENV{PKG_CONFIG_LOG}, "w");
  }
  $self;
}

=head2 find

 my $pkg = $client->find($package_name);

Searches the <.pc> file for the package with the given C<$package_name>. 
If found returns an instance of L<PkgConfig::LibPkgConf::Package>.  If 
not found returns C<undef>.

=cut

sub _pkg
{
  my($client, $ptr, @rest) = @_;
  require PkgConfig::LibPkgConf::Package;
  bless {
    client => $client,
    ptr    => $ptr,
    @rest
  }, 'PkgConfig::LibPkgConf::Package';
}

sub find
{
  my($self, $name) = @_;
  my $ptr = _find($self, $name);
  $ptr ? _pkg($self, $ptr, name => $name) : ();
}

=head2 package_from_file

 my $pkg = $client->package_from_file($filename);

Load the specific <.pc> file.

=cut

sub package_from_file
{
  my($self, $filename) = @_;
  my $ptr = _package_from_file($self, $filename);
  $ptr ? _pkg($self, $ptr, filename => $filename) : ();
}

=head2 scan_all

 $client->scan_all(sub {
   my($client, $package) = @_;
   ...
   return $bool;
 });

Iterates through all packages and calls the given subroutine reference
for each package.  C<$package> isa L<PkgConfig::LibPkgConf::Package>.
The scan will continue so long as a non true value is returned
(as C<$bool>).

=cut

sub scan_all
{
  my($self, $callback) = @_;

  my $wrapper = sub {
    my($ptr) = @_;
    my $package = _pkg($self, $ptr);
    $callback->($self, $package);
  };

  $self->_scan_all($wrapper);
}

=head2 global

 $client->global($key => $value);
 my $value = $client->global($key);

Define or get the global variable.

=cut

sub global
{
  my($self, $key, $value) = @_;
  if(defined $value)
  {
    $self->_set_global("$key=$value");
  }
  $self->_get_global($key);
}

=head2 error

 my $client->error($message);

Called when C<libpkgconf> comes across a non-fatal error.  By default 
the error is simply displayed as a warning using L<Carp>.  The intention 
of this method is if you want to override that behavior, you will subclass
L<PkgConfig::LibPkgConf::Client> and implement your own version of the
C<error> method.

=cut

sub error
{
  my($self, $msg) = @_;
  require Carp;
  Carp::carp($msg);
  1;
}

1;

=head2 audit_set_log

 $client->audit_set_log($filename, $mode);

Opens a file with the C C<fopen> style C<$mode>, and uses it for the 
audit log.  The file is managed entirely by the client class and will be
closed when the object falls out of scope.  Examples:

 $client->audit_set_log("audit.log", "a"); # append to existing file
 $client->audit_set_log("audit2.log", "w"); # new or replace file

=head1 SUPPORT

IRC #native on irc.perl.org

Project GitHub tracker:

L<https://github.com/plicease/PkgConfig-LibPkgConf/issues>

If you want to contribute, please open a pull request on GitHub:

L<https://github.com/plicease/PkgConfig-LibPkgConf/pulls>

=head1 SEE ALSO

For additional related modules, see L<PkgConfig::LibPkgConf>

=head1 AUTHOR

Graham Ollis

For additional contributors see L<PkgConfig::LibPkgConf>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 Graham Ollis.

This is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
