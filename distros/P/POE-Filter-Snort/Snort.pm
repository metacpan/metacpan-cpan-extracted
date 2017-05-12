=head1 NAME

POE::Filter::Snort - a POE stream filter that parses Snort logs into hashes

=head1 SYNOPSIS

	#!/usr/bin/env perl

	use warnings; use strict;
	use POE qw(Filter::Snort Wheel::FollowTail);

	POE::Session->create(
		inline_states => {
			_start  => \&start_log,
			got_rec => \&display_record,
		},
	);

	POE::Kernel->run();
	exit;

	sub start_log {
		$_[HEAP]->{watcher} = POE::Wheel::FollowTail->new(
			Filename   => "/var/log/snort/alert",
			Filter     => POE::Filter::Snort->new(),
			InputEvent => "got_rec",
		);
	}

	sub display_record {
		my $rec = $_[ARG0];

		print "Got a snort record:\n";
		print "\tComment: $rec->{comment}\n"  if exists $rec->{comment};
		print "\tClass  : $rec->{class}\n"    if exists $rec->{class};
		print "\tPrio   : $rec->{priority}\n" if exists $rec->{priority};
		if (exists $rec->{src_ip}) {
			if (exists $rec->{src_port}) {
				print "\tSource : $rec->{src_ip} $rec->{src_port}\n";
				print "\tDest   : $rec->{dst_ip} $rec->{dst_port}\n";
			}
			else {
				print "\tSource : $rec->{src_ip}\n";
				print "\tDest   : $rec->{dst_ip}\n";
			}

			foreach my $xref (@{$rec->{xref}}) {
				print "\tXref   : $xref\n";
			}
		} 
	}

=head1 DESCRIPTION

POE::Filter::Snort parses streams containing Snort alerts.  Each alert
is returned as a hash containing the following fields: comment, class,
priority, src_ip, dst_ip, src_port, dst_port, xref, raw.

Most fields are optional.  For example, some snort alerts don't
contain a source and destination IP address.  Those that do aren't
always accompanied by a source and destination port.

The xref field refers to an array of URLs describing the alert in more
detail.  It will always exist, but it may be empty if no URLs appear
in snort's configuration file.

The raw field is an arrayref containing each original line of the
snort alert.

=cut

package POE::Filter::Snort;

use warnings;
use strict;

use vars qw($VERSION @ISA);
$VERSION = '0.031';
@ISA = qw(POE::Filter);

use Carp qw(carp croak);
use POE::Filter::Line;

sub FRAMING_BUFFER   () { 0 }
sub PARSER_STATE     () { 1 }
sub PARSED_RECORD    () { 2 }
sub LINE_FILTER      () { 3 }

sub STATE_OUTSIDE    () { 0x02 }
sub STATE_INSIDE     () { 0x04 }

sub new {
	my $class = shift;

	# We use a POE::Filter::Line internally.
	my $line_filter = POE::Filter::Line->new();

	my $self = bless [
		"",                 # FRAMING_BUFFER
		STATE_OUTSIDE,      # PARSER_STATE
		{ },                # PARSED_RECORD
		$line_filter,       # LINE_FILTER
	], $class;
}

sub get_one_start {
	my ($self, $stream) = @_;
	$self->[LINE_FILTER]->get_one_start($stream);
}

sub get_one {
	my $self = shift;

	while (1) {
		my $line = $self->[LINE_FILTER]->get_one();
		return [ ] unless @$line;

		$line = $line->[0];

		if ($self->[PARSER_STATE] & STATE_OUTSIDE) {
			next unless $line =~
                        /^\[\*\*\]\s*\[(\d+):(\d+):(\d+)\]\s*(.*?)\s*\[\*\*\]/;
			$self->[PARSED_RECORD] = {
				sid			=> $2,
				rev			=> $3,
				comment => $4,
				xref    => [ ],
				raw     => [ $line ],
			};
			$self->[PARSER_STATE]  = STATE_INSIDE;
			next;
		}

		push @{ $self->[PARSED_RECORD]{raw} }, $line;

		if ($line =~ /^\s*$/) {
			$self->[PARSER_STATE] = STATE_OUTSIDE;
			return [ $self->[PARSED_RECORD] ];
		}

		if ($line =~ /\[Classification:\s*(.+?)\s*\]/) {
			$self->[PARSED_RECORD]{class} = $1;
		}

		if ($line =~ /\[Priority:\s*(.+?)\s*\]/) {
			$self->[PARSED_RECORD]{priority} = $1;
		}

		if (
			$line =~ m{
				^\d+\/\d+-\d+:\d+:\d+\.\d+\s*
				(\d+\.\d+\.\d+\.\d+):(\d+)      # src ipv4 : port
				\s*->\s*
				(\d+\.\d+\.\d+\.\d+):(\d+)      # dst ipv4 : port
			}x
		) {
			$self->[PARSED_RECORD]{src_ip}   = $1;
			$self->[PARSED_RECORD]{src_port} = $2;
			$self->[PARSED_RECORD]{dst_ip}   = $3;
			$self->[PARSED_RECORD]{dst_port} = $4;
		}
		elsif (
			$line =~ m{
				^\d+\/\d+-\d+:\d+:\d+\.\d+\s*
				(\d+\.\d+\.\d+\.\d+)          # src ipv4
				\s*->\s*
				(\d+\.\d+\.\d+\.\d+)          # dst ipv4
			}x
		) {
			$self->[PARSED_RECORD]{src_ip}   = $1;
			$self->[PARSED_RECORD]{dst_ip}   = $2;
		}

		while ($line =~ /\[Xref\s*=>\s*(.*?)\s*\]/g) {
			push @{$self->[PARSED_RECORD]{xref}}, $1;
		}

		die $line if $line =~ /<-/;
	}
}

sub put {
	my $self = shift;
	croak ref($self) . " doesn't implement put()";
}

sub get_pending {
	my $self = shift;
	return $self->[LINE_FILTER]->get_pending();
}

sub get {
	my ($self, $stream) = @_;
	my @return;

	$self->get_one_start($stream);
	while (1) {
		my $next = $self->get_one();
		last unless @$next;
		push @return, @$next;
	}

	return \@return;
}

1;

=head1 SEE ALSO

Snort - "the de facto standard for intrusion detection/prevention"
http://www.snort.org/

L<POE>

=head1 BUG TRACKER

https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=POE-Filter-Snort

=head1 REPOSITORY

http://github.com/rcaputo/poe-filter-snort
http://gitorious.org/poe-filter-snort

=head1 OTHER RESOURCES

http://search.cpan.org/dist/POE-Filter-Snort/

=head1 COPYRIGHT

Copyright 2005-2010, Rocco Caputo.  All rights are reserved.

POE::Filter::Snort is free software; you may use, redistribute, and/or
modify it under the same terms as Perl itself.

=cut
