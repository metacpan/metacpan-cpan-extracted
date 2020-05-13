#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Net::Prometheus::ProcessCollector::linux;

use strict;
use warnings;
use base qw( Net::Prometheus::ProcessCollector );

our $VERSION = '0.11';

use constant {
   TICKS_PER_SEC  => 100,
   BYTES_PER_PAGE => 4096,
};

=head1 NAME

C<Net::Prometheus::ProcessCollector::linux> - Process Collector for F<linux> OS

=head1 SYNOPSIS

   use Net::Prometheus;
   use Net::Prometheus::ProcessCollector::linux;

   my $prometheus = Net::Prometheus->new;

   $prometheus->register( Net::Prometheus::ProcessCollector::linux->new );

=head1 DESCRIPTION

This class provides a L<Net::Prometheus> collector instance to provide
process-wide metrics for a process running on the F<linux> operating system.

At collection time, if the requested process does not exist, no metrics are
returned.

=head2 Other Process Collection

The C<pid> argument allows the collector to collect from processes other than
the one actually running the code.

Note also that scraping processes owned by other users may not be possible for
non-root users. In particular, most systems do not let non-root users see the
L</proc/self/fd> directory of processes they don't own. In this case, the
C<process_open_fds> metric will not be returned.

=cut

=head1 CONSTRUCTOR

=head2 new

   $collector = Net::Prometheus::ProcessCollector::linux->new( %args )

As well as the default arguments supported by
L<Net::Prometheus::ProcessCollector>, the following extra named arguments are
recognised:

=over

=item pid => STR

The numerical PID to collect information about; defaults to the string
C<"self"> allowing the exporter to collect information about itself, even over
fork calls.

If the collector is collecting from C<"self"> or from a numerical PID that
matches its own PID, then it will subtract 1 from the count of open file
handles, to account for the C<readdir()> handle being used to collect that
count. If it is collecting a different process, it will not.

=back

=cut

my $BOOTTIME;

sub new
{
   my $class = shift;
   my %args = @_;

   # To report process_start_time_seconds correctly, we need the machine boot
   # time
   if( !defined $BOOTTIME ) {
      foreach my $line ( do { open my $fh, "<", "/proc/stat"; <$fh> } ) {
         next unless $line =~ m/^btime /;
         $BOOTTIME = +( split m/\s+/, $line )[1];
         last;
      }
   }

   my $self = $class->__new( %args );

   $self->{pid} = $args{pid} || "self";

   return $self;
}

sub _read_procfile
{
   my $self = shift;
   my ( $path ) = @_;

   open my $fh, "<", "/proc/$self->{pid}/$path" or return;
   return <$fh>;
}

sub _open_fds
{
   my $self = shift;

   my $pid = $self->{pid};

   opendir my $dirh, "/proc/$pid/fd" or return undef;
   my $count = ( () = readdir $dirh );

   $count -= 1 if $pid eq "self" or $pid == $$; # subtract 1 for $dirh itself

   return $count;
}

sub _limit_fds
{
   my $self = shift;
   my $line = ( grep m/^Max open files/, $self->_read_procfile( "limits" ) )[0];
   defined $line or return undef;

   # Max open files  $SOFT  $HARD
   return +( split m/\s+/, $line )[3];
}

sub collect
{
   my $self = shift;

   my $statline = $self->_read_procfile( "stat" );
   defined $statline or return; # process missing

   # /proc/PID/stat contains PID (COMM) more fields here
   my @statfields = split( m/\s+/,
      ( $statline =~ m/\)\s+(.*)/ )[0]
   );

   my $utime     = $statfields[11] / TICKS_PER_SEC;
   my $stime     = $statfields[12] / TICKS_PER_SEC;
   my $starttime = $statfields[19] / TICKS_PER_SEC;
   my $vsize     = $statfields[20];
   my $rss       = $statfields[21] * BYTES_PER_PAGE;

   my $open_fds = $self->_open_fds;

   my $limit_fds = $self->_limit_fds;

   return
      $self->_make_metric( cpu_user_seconds_total => $utime,
         "counter", "Total user CPU time spent in seconds" ),
      $self->_make_metric( cpu_system_seconds_total => $stime,
         "counter", "Total system CPU time spent in seconds" ),
      $self->_make_metric( cpu_seconds_total => $utime + $stime,
         "counter", "Total user and system CPU time spent in seconds" ),

      $self->_make_metric( virtual_memory_bytes => $vsize,
         "gauge", "Virtual memory size in bytes" ),
      $self->_make_metric( resident_memory_bytes => $rss,
         "gauge", "Resident memory size in bytes" ),

      ( defined $open_fds ?
         $self->_make_metric( open_fds => $open_fds,
            "gauge", "Number of open file handles" ) :
         () ),
      ( defined $limit_fds ?
         $self->_make_metric( max_fds => $limit_fds,
            "gauge", "Maximum number of allowed file handles" ) :
         () ),

      $self->_make_metric( start_time_seconds => $BOOTTIME + $starttime,
         "gauge", "Unix epoch time the process started at" ),

      # TODO: consider some stats out of /proc/PID/io
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
