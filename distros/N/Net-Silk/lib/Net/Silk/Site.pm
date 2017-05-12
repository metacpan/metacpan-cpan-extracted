# Use of the Net-Silk library and related source code is subject to the
# terms of the following licenses:
# 
# GNU Public License (GPL) Rights pursuant to Version 2, June 1991
# Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013
# 
# NO WARRANTY
# 
# ANY INFORMATION, MATERIALS, SERVICES, INTELLECTUAL PROPERTY OR OTHER 
# PROPERTY OR RIGHTS GRANTED OR PROVIDED BY CARNEGIE MELLON UNIVERSITY 
# PURSUANT TO THIS LICENSE (HEREINAFTER THE "DELIVERABLES") ARE ON AN 
# "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY 
# KIND, EITHER EXPRESS OR IMPLIED AS TO ANY MATTER INCLUDING, BUT NOT 
# LIMITED TO, WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE, 
# MERCHANTABILITY, INFORMATIONAL CONTENT, NONINFRINGEMENT, OR ERROR-FREE 
# OPERATION. CARNEGIE MELLON UNIVERSITY SHALL NOT BE LIABLE FOR INDIRECT, 
# SPECIAL OR CONSEQUENTIAL DAMAGES, SUCH AS LOSS OF PROFITS OR INABILITY 
# TO USE SAID INTELLECTUAL PROPERTY, UNDER THIS LICENSE, REGARDLESS OF 
# WHETHER SUCH PARTY WAS AWARE OF THE POSSIBILITY OF SUCH DAMAGES. 
# LICENSEE AGREES THAT IT WILL NOT MAKE ANY WARRANTY ON BEHALF OF 
# CARNEGIE MELLON UNIVERSITY, EXPRESS OR IMPLIED, TO ANY PERSON 
# CONCERNING THE APPLICATION OF OR THE RESULTS TO BE OBTAINED WITH THE 
# DELIVERABLES UNDER THIS LICENSE.
# 
# Licensee hereby agrees to defend, indemnify, and hold harmless Carnegie 
# Mellon University, its trustees, officers, employees, and agents from 
# all claims or demands made against them (and any related losses, 
# expenses, or attorney's fees) arising out of, or relating to Licensee's 
# and/or its sub licensees' negligent use or willful misuse of or 
# negligent conduct or willful misconduct regarding the Software, 
# facilities, or other rights or assistance granted by Carnegie Mellon 
# University under this License, including, but not limited to, any 
# claims of product liability, personal injury, death, damage to 
# property, or violation of any laws or regulations.
# 
# Carnegie Mellon University Software Engineering Institute authored 
# documents are sponsored by the U.S. Department of Defense under 
# Contract FA8721-05-C-0003. Carnegie Mellon University retains 
# copyrights in all material produced under this contract. The U.S. 
# Government retains a non-exclusive, royalty-free license to publish or 
# reproduce these documents, or allow others to do so, for U.S. 
# Government purposes only pursuant to the copyright license under the 
# contract clause at 252.227.7013.

package Net::Silk::Site;

use strict;
use warnings;
use Carp;

use vars qw( @EXPORT_OK %EXPORT_TAGS );

use base qw(Exporter);

use Net::Silk qw( :basic );

use Math::Int64 qw( uint64 );

our $INITIALIZED     = 0;
our $SITE_CONFIGURED = 0;
our $SITE_CONFIG_OK  = 0;

our %SENSORS_BY_ID;
our %CLASSES_BY_ID;
our %FLOWTYPES_BY_ID;

our %SENSORS;
our %CLASSES;
our %FLOWTYPES;
our %CLASSTYPES;

sub init_maps {
  return 1 if $INITIALIZED;
  load_site();
  return 0 unless $SITE_CONFIG_OK;
  %SENSORS_BY_ID   = _sensors_by_id();
  %CLASSES_BY_ID   = _classes_by_id();
  %FLOWTYPES_BY_ID = _flowtypes_by_id();
  for my $id (keys %SENSORS_BY_ID) {
    my $id_desc = $SENSORS_BY_ID{$id};
    my $desc = $SENSORS{$id_desc->{name}} = {%$id_desc};
    my @classes;
    for my $cid (@{$id_desc->{classes}}) {
      push(@classes, $CLASSES_BY_ID{$cid}{name});
    }
    $desc->{classes} = \@classes;
  }
  for my $id (keys %CLASSES_BY_ID) {
    my $id_desc = $CLASSES_BY_ID{$id};
    my $desc = $CLASSES{$id_desc->{name}} = {%$id_desc};
    my @sensors;
    for my $sid (@{$id_desc->{sensors}}) {
      push(@sensors, $SENSORS_BY_ID{$sid}{name});
    }
    $desc->{sensors} = \@sensors;
    my @flowtypes;
    for my $fid (@{$id_desc->{flowtypes}}) {
      push(@flowtypes, $FLOWTYPES_BY_ID{$fid}{name});
    }
    $desc->{flowtypes} = \@flowtypes;
    my @dflowtypes;
    for my $fid (@{$id_desc->{default_flowtypes}}) {
      push(@dflowtypes, $FLOWTYPES_BY_ID{$fid}{name});
    }
    $desc->{default_flowtypes} = \@dflowtypes;
  }
  for my $id (keys %FLOWTYPES_BY_ID) {
    my $id_desc = $FLOWTYPES_BY_ID{$id};
    my $desc = $FLOWTYPES{$id_desc->{name}} = {%$id_desc};
    $desc->{class} = $CLASSES_BY_ID{$id_desc->{class}}{name};
    $CLASSTYPES{$desc->{class}}{$desc->{type}} = $desc;
  }
  $INITIALIZED = 1;
}

sub init_site {
  # this only runs if invoked manually by the user since it sets
  # values subsequently used by the silk library in load_site();
  # otherwise the defaults are used (from env vars, etc)
  my %kv = @_;
  my $site_conf = $kv{siteconf};
  my $root_dir  = $kv{rootdir};

  if ($SITE_CONFIGURED) {
    warn "site already initialized";
    return 1;
  }
  if ($site_conf) {
    if (! -e $site_conf) {
      warn("site config file does not exist: $site_conf");
      return 0;
    }
    if (! set_site_config($site_conf)) {
      warn "problem setting site config: $site_conf";
      return 0;
    }
  }
  if ($root_dir) {
    if (! -d $root_dir) {
      warn "silk root directory does not exist: $root_dir";
      return 0;
    }
    if (! set_data_rootdir($root_dir)) {
      warn("illegal root directory: $root_dir");
      return 0;
    }
  }
  load_site();
  # These are needed for subprocess calls to silk
  silk_init_set_envvar($site_conf, SILK_CONFIG_FILE_ENVAR) if $site_conf;
  silk_init_set_envvar($root_dir, SILK_DATA_ROOTDIR_ENVAR) if $root_dir;
  $SITE_CONFIG_OK;
}

sub load_site {
  return 1 if $SITE_CONFIGURED;
  $SITE_CONFIG_OK = 0;
  my $site_conf = get_site_config();
  if (!$site_conf) {
    warn "no site file defined";
  }
  elsif (! -e $site_conf) {
    warn "site file does not exist: $site_conf";
  }
  else {
    my $site_res = _site_configure(0);
    if (!$site_res) {
      $SITE_CONFIG_OK = 1;
    }
    elsif ($site_res == -2) {
      warn("could not read site file: $site_conf");
    }
    else {
      warn("error parsing site configuration file: $site_conf");
    }
  }
  $SITE_CONFIGURED = 1;
}

sub HAVE_SITE_CONFIG { load_site(); $SITE_CONFIG_OK }

sub HAVE_SITE_CONFIG_SILENT {
  *SAVERR = *STDERR;
  open(STDERR, ">/dev/null");
  my $res = HAVE_SITE_CONFIG();
  *STDERR = *SAVERR;
  $res;
}

sub _sensors_by_id {
  my %sensors;
  for my $id (sensor_ids()) {
    my $desc = $sensors{$id} = {};
    $desc->{id}          = $id;
    $desc->{name}        = sensor_name($id);
    $desc->{description} = sensor_description_by_id($id);
    $desc->{classes}     = [sensor_classes_by_id($id)];
  }
  %sensors;
}

sub _classes_by_id {
  my %classes;
  for my $id (class_ids()) {
    my $desc = $classes{$id} = {};
    $desc->{id}                = $id;
    $desc->{name}              = class_name($id);
    $desc->{sensors}           = [class_sensors_by_id($id)];
    $desc->{flowtypes}         = [class_flowtypes_by_id($id)];
    $desc->{default_flowtypes} = [class_default_flowtypes_by_id($id)];
  }
  %classes;
}

sub _flowtypes_by_id {
  my %flowtypes;
  for my $id (flowtype_ids()) {
    my $desc = $flowtypes{$id} = {};
    $desc->{id}    = $id;
    $desc->{name}  = flowtype_name($id);
    $desc->{type}  = flowtype_type($id);
    $desc->{class} = flowtype_class($id);
  }
  %flowtypes;
}

###

sub sensors {
  init_maps();
  sort keys %SENSORS;
}

sub classes {
  init_maps();
  sort keys %CLASSES;
}

sub classtypes {
  init_maps();
  my @ctypes;
  #for my $flowtype (keys %FLOWTYPES) {
  #  push(@ctypes, [$FLOWTYPES{$flowtype}{class}, $flowtype]);
  #}
  for my $class (sort keys %CLASSTYPES) {
    for my $flowtype (sort keys %{$CLASSTYPES{$class}}) {
      push(@ctypes, [$class, $flowtype]);
    }
  }
  @ctypes;
}

sub types {
  init_maps();
  my $class = shift;
  my $c = $CLASSES{$class} || return ();
  my @types;
  for my $type (@{$c->{flowtypes}}) {
    push(@types, $FLOWTYPES{$type}{type});
  }
  @types;
}

sub default_types {
  init_maps();
  my $class = shift;
  my $c = $CLASSES{$class} || return ();
  my @types;
  for my $type (@{$c->{default_flowtypes}}) {
    push(@types, $FLOWTYPES{$type}{type});
  }
  @types;
}

sub default_class {
  init_maps();
  class_name(default_class_id());
}

sub class_sensors {
  init_maps();
  my $class = shift;
  my $c = $CLASSES{$class} || return ();
  @{$c->{sensors}};
}

sub sensor_classes {
  init_maps();
  my $sensor = shift;
  my $s = $SENSORS{$sensor} || return ();
  @{$s->{classes}};
}

sub sensor_id {
  init_maps();
  my $sensor = shift;
  my $s = $SENSORS{$sensor} || return;
  $s->{id};
}

sub sensor_description {
  init_maps();
  my $sensor = shift;
  my $s = $SENSORS{$sensor} || return;
  $s->{description};
}

sub classtype_id {
  init_maps();
  my($class, $type) = @_;
  my $ctype = $CLASSTYPES{$class} || return;
  $ctype = $ctype->{$type} || return;
  $ctype->{id};
}

sub classtype_from_id {
  init_maps();
  my $id = shift;
  my $ftype = $FLOWTYPES_BY_ID{$id} || return;
  return $CLASSES_BY_ID{$ftype->{class}}{name}, $ftype->{type};
}

sub sensor_from_id {
  init_maps();
  my $id = shift;
  my $s = $SENSORS_BY_ID{$id} || return;
  $s->{name};
}

###

sub repo_iter {
  init_maps();
  my %opt = @_;
  my $stime = $opt{start} || croak("stime required");
  if (! UNIVERSAL::isa($stime, "DateTime")) {
    $stime = DateTime->from_epoch(epoch => $stime);
  }
  my $start_epoch = $stime->epoch;
  $start_epoch -= $start_epoch % 3600;
  my $start_hour = $start_epoch % 86400;
  $stime = DateTime->from_epoch(epoch => $start_epoch);
  my $etime = $opt{end};
  if (! $etime) {
    if ($start_hour) {
      # no etime and hour present, just query that hour
      $etime = $stime;
    }
    else {
      # no etime and no hour specified, query the day
      $etime = $stime + DateTime::Duration->new(hours => 23);
    }
  }
  else {
    if (! UNIVERSAL::isa($etime, "DateTime")) {
      $etime = DateTime->from_epoch(epoch => $stime);
    }
    my $end_epoch = $etime->epoch;
    $end_epoch -= $end_epoch % 3600;
    $etime = DateTime->from_epoch(epoch => $end_epoch);
  }
  # to milliseconds
  $stime = uint64($stime->epoch * 1000);
  $etime = uint64($etime->epoch * 1000);
  my @sensors;
  if ($opt{sensors}) {
    my %s;
    for my $sensor (@{$opt{sensors}}) {
      ++$s{$sensor};
    }
    @sensors = sort keys %s;
  }
  my %flowtypes = %{$opt{flowtypes} || {}};
  my $iter = SILK_SITE_REPO_ITER_CLASS->new(
    \%flowtypes,
    \@sensors,
    $stime,
    $etime,
    $opt{missing},
  );
  sub {
    return unless $iter;
    if (wantarray) {
      my @files;
      while (my $f = $iter->next) {
        push(@files, $f);
      }
      $iter = undef;
      return @files;
    }
    my $f = $iter->next;
    $iter = undef unless $f;
    $f;
  };
}

###

my @ALL;

BEGIN {
  @ALL = qw(
    sensors
    classes
    classtypes
    types
    default_types
    default_class
    class_sensors
    sensor_classes
    sensor_id
    sensor_description
    classtype_id
    classtype_from_id
    sensor_from_id
    init_site
    load_site
    HAVE_SITE_CONFIG
    HAVE_SITE_CONFIG_SILENT
    get_site_config
    get_data_rootdir
    set_data_rootdir
    repo_iter
  );

  @EXPORT_OK = @ALL;

  %EXPORT_TAGS = (
    all => \@ALL,
  );
}

###

1;

__END__


=head1 NAME

Net::Silk::Site - SiLK site repository configuration

=head1 DESCRIPTION

C<Net::Silk::Site> is the interface to the local repository
configuration. It can be used to make queries about sensor and class
types, as well as find flow files present in the repository.

=head1 EXPORTS

The following are available via the C<:all> export tag.

=head2 CONSTANTS

=over

=item HAVE_SITE_CONFIG

True if the repository site configuration file is present and has been
successfully loaded.

=back

=head2 FUNCTIONS

=over

=item init_site(rootdir => $path, siteconf => $file)

Initializes site configuration to a different root data directory and/or
site config file in order to override the values determined by
environment variables or the default. Must be called prior to invoking
any query functions. Site initialization will be invoked automatically,
if it hasn't yet been invoked, when any query functions are called.

=item get_data_rootdir()

Returns the currently defined repository data directory.

=item get_site_config()

Returns the currently defined site configuration file.

=item default_class()

Returns the default flow class.

=item default_types()

Returns the default flow types.

=item sensors()

Return a list of defined sensor names.

=item classes()

Return a list of defined class names.

=item types()

Return a list of defined type names.

=item classtypes()

Return a list of class/flowtype pairs.

=item sensor_classes($sensor)

Return a list of classes for the given sensor name.

=item class_sensors($class)

Return a list of sensors pertaining to the given class name.

=item sensor_id($sensor)

Return the numeric sensor id for the given sensor name.

=item sensor_from_id($id)

Return the sensor name for the given numeric sensor id.

=item sensor_description($sensor)

Return the sensor description, if any, for the given sensor name.

=item classtype_id($class, $type)

Return the numeric id for the given class/flowtype name pair.

=item classtype_from_id($id)

Return the class and flowtype names, as a list, given the numeric
classtype id.

=item repo_iter(...)

Return a subroutine reference representing an interator over repository
files matching the given criteria. The function takes the following
keyword arguments:

=over

=item start

The starting time of interest, given either as a DateTime object or as
seconds since the epoch. If I<only> a start time is given and it has a
resolution to the day, that entire day is queried. Otherwise, the given
hour is queried.

=item end

The end time of interest, given either as a L<DateTime> object or as
seconds since the epoch.

=item sensors

An array ref containing a list of sensors over which to limit the query.

=item flowtypes

A hash ref containing class/type pairs over which to limit the query.

=item missing

A flag indicating whether to include files missing from the repository
in query results.

=back

=back

=head1 SEE ALSO

L<Net::Silk>, L<Net::Silk::RWRec>, L<Net::Silk::IPSet>, L<Net::Silk::Bag>, L<Net::Silk::Pmap>, L<Net::Silk::IPWildcard>, L<Net::Silk::Range>, L<Net::Silk::CIDR>, L<Net::Silk::IPAddr>, L<Net::Silk::TCPFlags>, L<Net::Silk::ProtoPort>, L<Net::Silk::File>, L<sensor.conf(5)>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
