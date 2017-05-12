#!/usr/bin/perl

use strict;
use warnings;
use Pod::Help 0.99 qw();

if ($ARGV[0] and $ARGV[0] eq '--wrongparam') {
	Pod::Help->help();
} else {
	print 'program output';
}

exit(0);

=head1

pod text

=cut
