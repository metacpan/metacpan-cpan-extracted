#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use Net::Traces::TSH qw( :traffic_analysis );

our $opt_v;
getopts('v');

if ($opt_v) {
  verbose;

  print STDERR "Using Net::Traces::TSH version $Net::Traces::TSH::VERSION\n";
}

my $trace = shift;

die "No TRACE to process.\nUsage: perl pt.pl [-v] TRACE\n"
  unless $trace;

process_trace $trace;

write_trace_summary;

__END__

=head1 NAME

pt.pl - Process a single TSH trace using L<Net::Traces::TSH|Net::Traces::TSH>

=head1 SYNOPSIS

 perl pt.pl [-v] TRACE

=head1 DESCRIPTION

C<pt.pl> is a simple application based on
L<Net::Traces::TSH|Net::Traces::TSH>: It processes F<TRACE> and
generates the overall trace summary. Use the C<-v> option to display
version and progress information.

=head2 Performance Evaluation

Processing large traces can be resource consuming, and you may wonder
how C<pt.pl> (essentially, L<Net::Traces::TSH|Net::Traces::TSH>)
fares. I did sample runs and measured the time needed to process TSH
traces ranging from 275 KB to 571 MB on L<four different
systems|"System Specifications">.

=head3 System Specifications

=over

=item Laptop

Mandrake Linux 9.1, Intel Pentium III at 750 MHz, 256 MB RAM, running
perl 5.8.0 (i386-linux-thread-multi).

=item Big Iron

Solaris 2.6, dual Sun Ultra SPARC II at 340 MHz, 3 GB RAM, running
perl 5.6.1 (sun4-solaris).

=item Linux Server

Red Hat Linux 7.3, dual Intel Xeon at 1.8 GHz with Hyper-threading, 4
GB RAM, running perl 5.6.1 (i386-linux).

=item Sun Fire

Solaris 9, Sun Fire V880 with 8 Ultra Sparc III at 750 MHz  (w/8
MB cache each), 32 GB RAM, running perl 5.8.0 (sun4-solaris).

=back

=head3 Test Results

The test results below were obtained with the following command

  % time perl pt.pl trace.tsh

All runs were performed on L<non-dedicated systems|"System
Specifications"> during off hours. Each system was under extremely
light load. Results are shown here for illustrative purposes only. If
you use C<Net::Traces::TSH>, I will be happy to hear about any
performance measurements.

The following table shows the median of three sample runs, in elapsed
real time, as reported by L<time>, rounded up to the closest second
(L<time> on Solaris rounds up elapsed time, anyway) for the systems
mentioned above and different TSH trace sizes.

              +-----------------------------------+
              |           Time (min:sec)          |
 +------------+--------+--------+--------+--------+
 | Trace Size | Laptop |  Big   | Linux  |  Sun   |
 | Gziped/Raw |        |  Iron  | Server |  Fire  |
 +------------+--------+--------+--------+--------+
 |  50/275 KB | <0:01  |  0:01  | <0:01  | <0:01  |
 +------------+--------+--------+--------+--------+
 |   1/2.7 MB |  0:07  |  0:17  |  0:04  |  0:07  |
 +------------+--------+--------+--------+--------+
 |   2/6.8 MB |  0:19  |  0:45  |  0:10  |  0:18  |
 +------------+--------+--------+--------+--------+
 |   4/ 13 MB |  0:36  |  1:27  |  0:18  |  0:35  |
 +------------+--------+--------+--------+--------+
 |  10/ 27 MB |  1:25  |  3:00  |  0:38  |  1:14  |
 +------------+--------+--------+--------+--------+
 |  20/ 50 MB |  2:30  |  5:18  |  1:08  |  2:10  |
 +------------+--------+--------+--------+--------+
 |  25/ 67 MB |  3:51  |  7:22  |  1:34  |  3:02  |
 +------------+--------+--------+--------+--------+
 |  50/126 MB |  5.54  | 12:48  |  2:42  |  5:10  |
 +------------+--------+--------+--------+--------+
 | 102/206 MB | 10:45  | 23:05  |  4:54  |  9:22  |
 +------------+--------+--------+--------+--------+
 | 280/571 MB | 30:34  | 64:29  | 13:24  | 26:16  |
 +------------+--------+--------+--------+--------+


=head1 DEPENDENCIES

L<Getopt::Std>, L<Net::Traces::TSH|Net::Traces::TSH>

=head1 VERSION

This is C<pt.pl> version 0.03.

=head1 AUTHOR

Kostas Pentikousis, kostas@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 by Kostas Pentikousis. All Rights Reserved.

This program is free software with ABSOLUTELY NO WARRANTY. You can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
