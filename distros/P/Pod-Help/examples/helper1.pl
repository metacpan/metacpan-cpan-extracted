#!/usr/bin/perl

use strict;
use warnings;
use Pod::Help 0.99 qw(-h --help);

if ($ARGV[0] and $ARGV[0] eq '--wrongparam') {
	Pod::Help->help();
} elsif ($ARGV[0] and $ARGV[0] eq '-h') {
	print 'error';
} elsif ($ARGV[0] and $ARGV[0] eq '--help') {
	print 'error';
} else {
	print 'program output';
}

exit(0);

=head1

pod text

=cut
