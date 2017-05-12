#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

our $opt_v;
getopts('v');

my $trace = shift;

die "Usage: perl tsh2ns2.pl [-v] TRACE [PREFIX]\n"
  unless $trace;

my $ns2_prefix = shift || $trace;

# Open trace file
#
open(INPUT, '<', $trace)
  or die "Cannot open $trace for processing. $!";

binmode INPUT; # Needed for non-UNIX OSes; no harm in UNIX

use constant TSH_RECORD_LENGTH => 44;

my (%ns2_fh, %ns2_previous_timestamp, $record, %ns2_t);

print STDERR "Converting $trace to ns2 Traffic/Trace binary format...\n"
  if $opt_v;

while( read(INPUT, $record, TSH_RECORD_LENGTH) ) {

  # Extract the fields from the TSH record in a platform-independent way
  #
  my ($t_sec,	$if, $t_usec, $version_ihl, $tos, $ip_len ) =
    unpack( "# Time
              N       # timestamp (seconds)
              C B24   # interface, timestamp (microseconds)

              # IP
              C C n   # Version & IHL, Type of Service, Total Length

              # Slurp rest of the record
              N8", $record
	  );

  # Sanity: make absolutely sure that $t_sec is considered an
  # integer in the code below
  #
  $t_sec = int $t_sec;

  # Extract the microseconds part of the timestamp
  #
  $t_usec = oct("0b$t_usec") / 1_000_000;

  # Sanity check
  #
  die 'Microseconds record field exceeds 1,000,000. Processing aborted'
    unless $t_usec < 1;

  my $timestamp = $t_sec + $t_usec;

  unless ( defined $ns2_fh{$if}) {
    open($ns2_fh{$if}, '>', "$ns2_prefix.if-$if.bin")
      or die"Cannot open $ns2_prefix.if-$if.bin. $!";

    binmode $ns2_fh{$if}; # Needed for non-UNIX OSes; no harm in UNIX

    $ns2_previous_timestamp{$if} = $timestamp;
  }

  my $dt = ( $timestamp - $ns2_previous_timestamp{$if} ) * 1_000_000;

  print
    { $ns2_fh{$if} }
      pack( 'NN', # two integers: interpacket time (usec), packet size (B)
	    sprintf("%.0f", $dt), $ip_len
	  );

  $ns2_t{$if} += $dt;
  $ns2_previous_timestamp{$if} = $timestamp;
}

close INPUT;

foreach ( sort keys %ns2_fh ) {
  close $ns2_fh{$_};

  print STDERR
    "Interface $_ traffic stored in $ns2_prefix.if-$_.bin. ",
    "Traffic duration: ", $ns2_t{$_} / 1_000_000, " sec\n"
    if $opt_v;

}
__END__

=head1 NAME

tsh2ns2.pl - Convert a single TSH trace to ns2 Traffic/Trace binary format

=head1 SYNOPSIS

 perl tsh2ns2.pl [-v] TRACE [PREFIX]

=head1 DESCRIPTION

C<tsh2ns2.pl> converts a binary TSH TRACE to ns2 Traffic/Trace binary
files, generating one file per interface observed in the trace.  Use
the C<-v> option to display progress information.  If F<PREFIX> is
provided, C<tsh2ns2.pl> will store the results of the conversion to
F<PREFIX.if-X.bin>, where F<X> is the interface number.

For example, if F<sample.tsh> contains traffic from two interfaces, 1
and 2, the following command

 % perl tsh2ns2.pl -v sample.tsh
 Converting sample.tsh to ns2 Traffic/Trace binary format...
 Interface 1 traffic stored in sample.tsh.if-1.bin. Traffic duration: 0.937443 sec
 Interface 2 traffic stored in sample.tsh.if-2.bin. Traffic duration: 0.9365 sec

will generate two ns2 Traffic/Trace files: F<sample.tsh.if-1.bin> and
F<sample.tsh.if-2.bin>.

C<tsh2ns2.pl> is stand-alone application based on C<Net::Traces::TSH>,
but does not require this module to operate.

=head1 DEPENDENCIES

L<Getopt::Std>

=head1 VERSION

This is C<tsh2ns2.pl> version 0.01.

=head1 SEE ALSO

C<Net::Traces::TSH>

The ns2 website at http://www.isi.edu/nsnam/ns/

=head1 AUTHOR

Kostas Pentikousis, kostas@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Kostas Pentikousis. All Rights Reserved.

This program is free software with ABSOLUTELY NO WARRANTY. You can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
