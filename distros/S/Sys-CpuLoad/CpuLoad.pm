package Sys::CpuLoad;

# Copyright (c) 1999-2002 Clinton Wong. All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself. 

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);

@EXPORT = qw();
@EXPORT_OK = qw(load);
$VERSION = '0.02';

bootstrap Sys::CpuLoad $VERSION;

=head1 NAME

Sys::CpuLoad - a module to retrieve system load averages.

=head1 DESCRIPTION

This module retrieves the 1 minute, 5 minute, and 15 minute load average
of a machine.

=head1 SYNOPSIS

 use Sys::CpuLoad;
 print '1 min, 5 min, 15 min load average: ',
       join(',', Sys::CpuLoad::load()), "\n";

=head1 AUTHOR

 Clinton Wong
 Contact info:
 http://search.cpan.org/search?mode=author&query=CLINTDW

=head1 COPYRIGHT

 Copyright (c) 1999-2002 Clinton Wong. All rights reserved.
 This program is free software; you can redistribute it
 and/or modify it under the same terms as Perl itself.

=cut

use IO::File;

my $cache = 'unknown';

sub load {

  # handle bsd getloadavg().  Read the README about why it is freebsd/openbsd.
  if ($cache eq 'getloadavg()' or lc $^O eq 'freebsd' or lc $^O eq 'openbsd' ) {
    $cache = 'getloadavg()';
    return getbsdload()
  }

  # handle linux proc filesystem
  if ($cache eq 'unknown' or $cache eq 'linux') {
    my $fh = new IO::File('/proc/loadavg', 'r');
    if (defined $fh) {
      my $line = <$fh>;
      $fh->close();
      if ($line =~ /^(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/) {
        $cache = 'linux';
        return ($1, $2, $3);
      }              # if we can parse /proc/loadavg contents
    }                # if we could load /proc/loadavg 
  }                  # if linux or not cached
   
  # last resort...

  $cache = 'uptimepipe';
  local %ENV = %ENV;
  $ENV{'LC_NUMERIC'}='POSIX';    # ensure that decimal separator is a dot

  my $fh=new IO::File('/usr/bin/uptime|');
  if (defined $fh) {
    my $line = <$fh>;
    $fh->close();
    if ($line =~ /(\d+\.\d+)\s*,\s+(\d+\.\d+)\s*,\s+(\d+\.\d+)\s*$/) {
      return ($1, $2, $3);
    }                # if we can parse the output of /usr/bin/uptime
  }                  # if we could run /usr/bin/uptime
    
  return (undef, undef, undef);
}

1;
__END__

