package Plucene::Utils;

=head1 NAME 

Plucene::Utils - Utility class for Plucene

=head1 SYNOPSIS

	use Plucene::Utils;
	
	do_locked($sub, $lock);

=head1 DESCRIPTION

Utilities to help with Plucene.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp;
use Fcntl qw(O_EXCL O_CREAT O_WRONLY);

use base 'Exporter';
our @EXPORT = qw( do_locked );

=head2 do_locked

	do_locked($sub, $lock);

=cut

sub do_locked (&$) {
	my ($sub, $lock) = @_;
	local *FH;
	for (1 .. 5) {
		sysopen FH, $lock, O_EXCL | O_CREAT | O_WRONLY
			and goto got_lock;
		sleep 1;
		warn "I had to sleep to get a lock on $lock";
	}
	carp "Couldn't get lock $lock: $!";
	got_lock:
	$sub->();
	close *FH;
	unlink $lock;
}

1;
