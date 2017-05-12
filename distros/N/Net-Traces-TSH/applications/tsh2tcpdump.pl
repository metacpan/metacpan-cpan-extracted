#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use Net::Traces::TSH 0.14 qw( configure process_trace);

our $opt_v;
getopts('v');

my $trace = shift;

die "Usage: perl tsh2tcpdump.pl [-v] TRACE [TCPDUMP_FILENAME]\n"
  unless $trace;

my $tcpdump = shift || "$trace.tcpdump";

if ($opt_v) {
  configure(Verbosity => 1, tcpdump => $tcpdump);

  print STDERR <<INFO;
Converting $trace to tcpdump format (Net::Traces::TSH version $Net::Traces::TSH::VERSION)...
INFO
}
else {
  configure(tcpdump => $tcpdump);
}

process_trace $trace;

__END__

=head1 NAME

tsh2tcpdump.pl - Convert a single TSH trace to tcpdump text format

=head1 SYNOPSIS

 perl tsh2tcpdump.pl [-v] TRACE [TCPDUMP_FILENAME]

=head1 DESCRIPTION

C<tsh2tcpdump.pl> is a simple application based on
L<Net::Traces::TSH|Net::Traces::TSH>: It converts the binary TSH
F<TRACE> to tcpdump text format, stored in F<TCPDUMP_FILENAME>.  If
F<TCPDUMP_FILENAME> is ommited, C<tsh2tcpdump> will store the result
of the conversion to F<TRACE.tcpdump>. The text output is similar to
what F<tcpdump> with options C<-n> and C<-S> would have produced.

Use the C<-v> option to display version and progress information.

=head2 Example

 % perl tsh2tcpdump.pl -v BWY-1073954865-1.tsh
 Using Net::Traces::TSH version 0.11
 Processing BWY-1073954865-1.tsh...
 TCP activity stored in text format in BWY-1073954865-1.tsh.tcpdump

 % more BWY-1073954865-1.tsh.tcpdump
 0.000000000 10.0.0.1.1433 > 10.0.0.2.5197: F 728858043:728858043(0) ack 624693062 win 65353
 0.000025988 10.0.0.5.9966 > 10.0.0.6.43327: . 3646667771:3646669219(1448) ack 2533461177 win 5792
 0.000113010 10.0.0.7.2209 > 10.0.0.8.3661: P 3522801148:3522802516(1368) ack 573261995 win 62960
 0.000190020 10.0.0.7.2209 > 10.0.0.8.3661: P 3522802516:3522803196(680) ack 573261995 win 62960
 0.000230074 10.0.0.5.9966 > 10.0.0.6.43327: . 3646669219:3646670667(1448) ack 2533461177 win 5792
 0.000354052 10.0.0.9.2549 > 10.0.0.10.1214: P 2202546388:2202547056(668) ack 185596712 win 64576
 0.000394106 10.0.0.11.3046 > 10.0.0.12.6881: . ack 810894344 win 17520
 0.000396013 10.0.0.5.9966 > 10.0.0.6.43327: . 3646670667:3646672115(1448) ack 2533461177 win 5792
 0.000498056 10.0.0.13.3034 > 10.0.0.14.26212: . ack 1444918162 win 64240
 [...]

=head1 DEPENDENCIES

L<Getopt::Std>, L<Net::Traces::TSH|Net::Traces::TSH>

=head1 VERSION

This is C<tsh2tcpdump.pl> version 0.02.

=head1 AUTHOR

Kostas Pentikousis, kostas@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Kostas Pentikousis. All Rights Reserved.

This program is free software with ABSOLUTELY NO WARRANTY. You can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
