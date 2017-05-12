#  Copyright (c) 2001 Hewlett-Packard Company. All rights reserved.
#  This program is free software; you can redistribute it
#  and/or modify it under the same terms as Perl itself.

package Perf::ARM;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

# have experienced some problems with 5.004 and previous
# with libarm wanting threads and the ARM.sl link steps dying
use 5.005;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);
$VERSION = '0.04';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Perf::ARM macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Perf::ARM $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Perf::ARM - Perl extension wrapper for the ARM 2.0 implementation

=head1 SYNOPSIS

  use Perf::ARM;

  my ($appl_id,$tran_handle, $tran_id, $rc);

  ($appl_id=Perf::ARM::arm_init( "$0", "*", 0,0,0)) ||
    die "arm_init() failed \n";
  $tran_id=Perf::ARM::arm_getid($appl_id, "simple_tran",
    "detail_$$", 0,0,0);
  $tran_handle=Perf::ARM::arm_start($tran_id, 0,0,0);

  #  do the unit of work to be measured
  &do_my_work(@my_args)

  $rc=Perf::ARM::arm_stop($tran_handle, 0, 0,0,0);

  $rc=Perf::ARM::arm_end($appl_id, 0,0,0);

=head1 DESCRIPTION

This serves as a simple wrapper around the ARM C routines:

arm_init(char *,char *,long ,char *,long );
    [ returns long  ]

arm_getid(long ,char *,char *,long ,char *,long );
    [ returns long  ]

arm_start(long ,long ,char *,long );
    [ returns long  ]

arm_update(long ,long ,char *,long );
    [ returns long  ]

arm_stop(long ,long ,long ,char *,long );
    [ returns long  ]

arm_end(long ,long ,char *,long );
    [ returns long  ]


=head1 Exported functions, with ARM defines

  extern arm_int32_t  arm_init(
    char*        appl_name,
    char*        appl_user_id,
    arm_int32_t  flags,
    char*        data,
    arm_int32_t  data_size);
  extern arm_int32_t  arm_getid(
    arm_int32_t  appl_id,
    char*        tran_name,
    char*        tran_detail,
    arm_int32_t  flags,
    char*        data,
    arm_int32_t  data_size);
  extern arm_int32_t  arm_start(
    arm_int32_t  tran_id,
    arm_int32_t  flags,
    char*        data,
    arm_int32_t  data_size);
  extern arm_int32_t  arm_update(
    arm_int32_t  start_handle,
    arm_int32_t  flags,
    char*        data,
    arm_int32_t  data_size);
  extern arm_int32_t  arm_stop(
    arm_int32_t  start_handle,
    arm_int32_t  tran_status,
    arm_int32_t  flags,
    char*        data,
    arm_int32_t  data_size);
  extern arm_int32_t  arm_end(
    arm_int32_t  appl_id,
    arm_int32_t  flags,
    char*        data,
    arm_int32_t  data_size);

=head1 AUTHOR

bryan_backer@hp.com

=head1 BUGS, LIMITATIONS

The module's tests do not currently pass if the system has the
no-operation (NULL) shared libraries, as they return zero for
all calls.

On some HP-UX builds of perl with the
usemymalloc build flag set to 'y', Perf::ARM dumps core.
The cause of this problem is not fully understood. If the
problem occurs, rebuild the perl with usemymalloc='n'.
Running perl -V will show the usemymalloc setting for your perl.

=head1 TO DO

    - create a useful subset of tests that work with the null libarm
      from the ARM SDK, allowing 'make test' to pass on those systems.
    - integrate David Carter's Inline suggestions
    - integrate David Carter's function name and null parameter
      shortening suggestions
    - build an object interface similar to the ARM 3.0 Java interface
      described at http://regions.cmg.org/regions/cmgarmw/ARM30.html

=head1 SEE ALSO

ARM FAQ at http://www.cmg.org/regions/cmgarmw/armfaq.html

Glance docs at http://www.openview.hp.com/products/

CMG ARM Working Group info page at http://www.cmg.org/regions/cmgarmw/

HP-UX: /opt/perf/include/arm.h or /usr/include/arm.h

=cut
