package POE::Component::Resolver::Sidecar;
{
  $POE::Component::Resolver::Sidecar::VERSION = '0.921';
}

use warnings;
use strict;

use Storable qw(nfreeze thaw);

use Socket qw(getaddrinfo);

sub main {
	my $buffer = "";
	my $read_length;

	binmode(STDIN);
	binmode(STDOUT);
	select STDOUT; $| = 1;

	use bytes;

	while (1) {
		if (defined $read_length) {
			if (length($buffer) >= $read_length) {
				my $request = thaw(substr($buffer, 0, $read_length, ""));
				$read_length = undef;

				my ($request_id, $host, $service, $hints) = @$request;
				my ($err, @addrs) = getaddrinfo($host, $service, $hints);

				my $streamable = nfreeze( [ $request_id, $err, \@addrs ] );
				my $stream = length($streamable) . chr(0) . $streamable;

				my $octets_wrote = syswrite(STDOUT, $stream);
				die $! unless $octets_wrote == length($stream);

				next;
			}
		}
		elsif ($buffer =~ s/^(\d+)\0//) {
			$read_length = $1;
			next;
		}

		my $octets_read = sysread(STDIN, $buffer, 4096, length($buffer));
		last unless $octets_read;
	}

	exit 0;
}

1;

__END__

=head1 NAME

POE::Component::Resolver::Sidecar - delegate subprocess to call getaddrinfo()

=head1 VERSION

version 0.921

=head1 SYNOPSIS

Used internally by POE::Component::Resolver.

=head1 DESCRIPTION

POE::Component::Resolver creates subprocesses to call getaddrinfo() so
that the main program doesn't block during that time.

The actual getaddrinfo() calling code is abstracted into this module
so it can be run in a separate executable program.  This reduces the
memory footprint of forking the entire main process for just
getaddrinfo().

It's a strong, useful pattern that other POE::Components have
implemented before.  POE::Quickie does it generically.
POE::Component::SimpleDBI and POE::Component::EasyDBI do it so their
DBI subprocesses are relatively lightweight.

=head2 main

The main code to read POE::Component::Resolver requests from STDIN and
write getaddrinfo() responses to STDOUT.

=head1 SEE ALSO

L<POE::Component::Generic> is one generic implementation of this
pattern.

L<POE::Quickie> is another generic implementation of this pattern.

=head1 BUGS

None known.

=head1 LICENSE

Except where otherwise noted, this distribution is Copyright 2011 by
Rocco Caputo.  All rights reserved.  This distribution is free
software; you may redistribute it and/or modify it under the same
terms as Perl itself.

=cut
