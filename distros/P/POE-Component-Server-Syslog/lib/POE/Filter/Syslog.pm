# $Id: Syslog.pm 579 2005-11-20 22:52:26Z sungo $
package POE::Filter::Syslog;
$POE::Filter::Syslog::VERSION = '1.22';
#ABSTRACT: syslog parser

use warnings;
use strict;

use POE;
use Time::ParseDate;

our $SYSLOG_REGEXP = q|
^<(\d+)>                       # priority -- 1
	(?:
		(\S{3})\s+(\d+)        # month day -- 2, 3
		\s
		(\d+):(\d+):(\d+)      # time  -- 4, 5, 6
	)?
	\s*
	(.*)                       # text  --  7
$
|;

sub new {
	return bless {
		buffer => '',
	}, shift;
}

sub get_one_start {
	my $self = shift;
	my $input = shift;
	$self->{buffer} .= join("",@$input);
}

sub get {
	my $self = shift;
	my $incoming = shift;
	return [] unless $incoming and @$incoming;
	my $stream = join ("", @$incoming);

	my @found;
	if($stream and length $stream) {

		while ( $stream =~ s/$SYSLOG_REGEXP//sx ) {
			my $time = $2 && parsedate("$2 $3 $4:$5:$6");
			$time ||= time();

			my $msg  = {
				time     => $time,
				pri      => $1,
				facility => int($1/8),
				severity => int($1%8),
				msg      => $7,
			};
			push @found, $msg;
		}
	}
	return \@found;
}


sub get_one {
	my $self = shift;
	my $found = 0;
	if($self->{buffer} and length $self->{buffer}) {
		if ( $self->{buffer} =~ s/$SYSLOG_REGEXP//sx ) {
			my $time = $2 && parsedate("$2 $3 $4:$5:$6");
			my $msg  = {
				time     => $time,
				pri      => $1,
				facility => int($1/8),
				severity => int($1%8),
				msg      => $7,
			};
			$found = $msg;
		}
	}
	if($found) {
		return [ $found ];
	} else {
		return [];
	}
}

sub put {} # XXX

1;


# sungo // vim: ts=4 sw=4 noexpandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Filter::Syslog - syslog parser

=head1 VERSION

version 1.22

=head1 SYNOPSIS

  my $filter = POE::Filter::Syslog->new();
  $filter->get_one_start($buffer);
  while( my $record = $filter->get_one() ) {

  }

=head1 DESCRIPTION

This module follows the POE::Filter specification. Actually, it
technically supports both the older specification (C<get>) and the newer
specification (C<get_one>). If, at some point, POE deprecates the older
specification, this module will drop support for it. As such, only use
of the newer specification is recommended.

=head1 CONSTRUCTOR

=over

=item new

Creates a new filter object.

=back

=head1 METHODS

=over

=item get

=item get_one_start

=item get_one

C<get_one> returns a list of records with the following fields:

=over 4

=item * time

The time of the datagram (as specified by the datagram itself)

=item * pri

The priority of message.

=item * facility

The "facility" number decoded from the pri.

=item * severity

The "severity" number decoded from the pri.

=item * host

The host that sent the message.

=item * msg

The message itself. This often includes a process name, pid number, and
user name.

=back

=back

=head1 BUGS / CAVEATS

=over

=item * C<put> is not supported yet.

=back

=head1 AUTHOR

Matt Cashner (sungo@pobox.com)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Matt Cashner (sungo@pobox.com).

This is free software, licensed under:

  The (three-clause) BSD License

=cut
