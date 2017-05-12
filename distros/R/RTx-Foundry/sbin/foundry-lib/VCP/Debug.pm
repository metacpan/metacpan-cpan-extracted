package VCP::Debug ;

=head1 NAME

VCP::Debug - debugging support for VCP

=head1 SYNOPSIS

=head1 DESCRIPTION

Debugging support for VCP.  Enabled by setting the environment variable
VCPDEBUG=1.

=over

=cut

use VCP::Logger qw( lg pr log_file_name start_time );

use constant debugging => $ENV{VCPDEBUG}   || 0;
use constant profiling => $ENV{VCPPROFILE} || 0;

BEGIN {
   pr "debugging enabled, see ", log_file_name if debugging;
   if ( profiling ) {
      pr "profiling enabled, see ", log_file_name;
      eval "use Time::HiRes qw( time ); 1"
         or pr "Time::HiRes must be loaded for accurate profiling";
   }
}

sub _secs($) { sprintf "%.6f secs", $_[0] }
sub _pct($$)  {
   $_[1] ? sprintf " (%5.2f%%)", 100 * $_[0] / $_[1] : "";
}

my %profile;
my %count;
my %groups;

END {
   if ( profiling ) {
      my $end_time = time;
      my $elapsed = $end_time - start_time;
      my $vcp_total = $elapsed;

      my $non_vcp_total;
      for my $group ( keys %groups ) {
         for ( keys %profile ) {
            if ( 0 == index $_, $group ) {
               $profile{"${group}TOTAL"} += $profile{$_};
               $vcp_total -= $profile{$_};
               $count{"${group}TOTAL"} += $count{$_};
            }
         }
      }

      my @rows;
      push @rows, [ "total time", "", _secs $elapsed, "" ];
      push @rows, [ "VCP time", "", _secs $vcp_total, _pct $vcp_total, $elapsed ];
      push @rows, [ $_, $count{$_} . " calls", _secs $profile{$_}, _pct $profile{$_}, $elapsed ]
         for sort keys %profile;

      my @w;
      for ( @rows ) {
         for my $i ( 0..$#$_ ) {
            $w[$i] = length $_->[$i] if length $_->[$i] > ($w[$i] || 0);
         }
      }

      my $f = "   " . join "  ", "%-$w[0]s:", map "%${_}s", @w[1..$#w];
      lg "profiling report:";
      lg sprintf $f, @$_ for @rows;
   }
}

@ISA = qw( Exporter ) ;
my @DEBUG_EXPORTS = qw( debug debugging );
my @PROFILE_EXPORTS = qw( profile_end profile_start profile_group profiling );
@EXPORT_OK = ( @DEBUG_EXPORTS, @PROFILE_EXPORTS );
%EXPORT_TAGS = (
   'all'     => \@EXPORT_OK,
   'debug'   => \@DEBUG_EXPORTS,
   'profile' => \@PROFILE_EXPORTS,
) ;

$VERSION = 0.1 ;

use strict ;
use vars qw( $profile_category );
use Exporter ;

# TODO:
#=item use
#=item import
#
#In addition to all of the routines and tags that C<use> and C<import> normally
#take (see above), you may also pass in pairwise debugging definitions like
#so:
#
#   use VCP::debug (
#      ":all",
#      DEBUGGING_FOO => "foo,bar",
#   ) ;
#
#Any all caps export import requests are created as subroutines that may well be
#optimized away at compile time if "enable_debugging" has not been called. This
#requires a conspiracy between the author of a module and the author of the main
#program to call enable_debugging I<before> C<use>ing any modules that leverage
#this feature, otherwise compile-time optimizations won't occur.
#

=item debug

   debug $foo if debugging $self ;

Emits a line of debugging (a "\n" will be appended).  Use
to avoid the "\n".  Any undefined parameters will be displayed as
C<E<lt>undefE<gt>>.

=cut

sub debug {
   goto &lg;
}


=item debugging

   debug "blah" if debugging ;

Returns TRUE if the caller's module is being debugged

   debug "blah" if debugging $self ;
   debug "blah" if debugging $other, $self ; ## ORs the arguments together

Returns TRUE if any of the arguments are being debugged.  Plain
strings can be passed or blessed references.

=cut

=item profiling

Returns true if VCP is profiling itself compared to shell command
performance.

This is different from using perl's profilers (-d:DProf and the like); 
this profiling tracks the operation of some of VCP's internals and
also how long is spent waiting for child processes to complete.

=cut

=item $VCP::Debug::profile_category

Sets the category for the next profile_start and profile_end
pair of calls:

   local $VCP::Debug::profile_category = "p4 files" if profiling;

=cut

=item profile_start

Notes the current time as the start of a profiling interval.

Defaults to the category $profile_category if none passed.

=cut

my %start_times;

sub profile_start {
   my $key = @_ ? shift : $profile_category;
   ++$count{$key};
   $start_times{$key} = time;
}

=item profile_end

Notes the current time as the end of a profiling interval.

Defaults to the category $profile_category if none passed.

=cut

sub profile_end {
   my $time = time;
   my $key = @_ ? shift : $profile_category;
   my $elapsed = $time - delete $start_times{$key};
   $profile{$key} += $elapsed;

   ## Make all times exclusive
   $_ += $elapsed for values %start_times;
}

=item profile_group

Called with the prefix of a set of profile categories to sum up and
emit subtotals for.

=cut

sub profile_group {
   $groups{$_[0]} = 1;
}

=back

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1
