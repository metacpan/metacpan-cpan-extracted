package POE::Filter::EPPTCP;

use 5.024;
use utf8;
use strictures 2;

use English qw(-no_match_vars);

#ABSTRACT: EPP Frame parsing for POE

use Moose qw(has extends);
use MooseX::NonMoose;

our $VERSION = '1.001';

extends 'Moose::Object', 'POE::Filter';

has 'buffer' => (
	'is'      => 'ro',
	'traits'  => ['Array'],
	'isa'     => 'ArrayRef',
	'lazy'    => 1,
	'clearer' => '_clear_buffer',
	'default' => sub { [] },
	'handles' => {
		'has_buffer'     => 'count',
		'all_buffer'     => 'elements',
		'push_buffer'    => 'push',
		'shift_buffer'   => 'shift',
		'unshift_buffer' => 'unshift',
		'join_buffer'    => 'join',
	},
);

sub get_one_start {
	my ($self, $raw) = @_;

	if (defined $raw) {
		foreach my $raw_data (@{$raw}) {
			$self->push_buffer($raw_data);
		}
	}

	return;
} ## end sub get_one_start

sub get_one {

	my ($self) = @_;

	my $buf = q{};

	my $frames = [];

	while ($self->has_buffer) {
		my ($len, $eppframe) = (0, undef);

		$buf .= $self->shift_buffer;

	      BUFFER_LOOP: while (4 < length $buf) {
			my $lenbuf = substr $buf, 0, 4;
			($len) = unpack 'N', $lenbuf;

			if ($len <= length $buf) {

				# Get the whole frame, and remove it from $buf
				$eppframe = substr $buf, 0, $len, q{};

				# Remove the header from the frame.
				substr $eppframe, 0, 4, q{};
				push @{$frames}, $eppframe;
			} else {
				last BUFFER_LOOP;
			}
		} ## end BUFFER_LOOP: while (4 < length $buf)
	} ## end while ($self->has_buffer)

	# If we have some remaining buffer, put it back into the buffer ring, at the beginning.
	if (length $buf > 0) {
		$self->unshift_buffer($buf);
	}

	return $frames;
} ## end sub get_one

sub put {
	my ($self, $frames) = @_;
	my $output = [];

	foreach my $frame (@{$frames}) {
		push @{$output}, pack('N', 4 + length $frame) . $frame;
	}

	return $output;
} ## end sub put

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=pod
=encoding utf8

=head1 NAME

POE::Filter::EPPTCP - Parsing EPP-TCP Frames for the POE framework

=head1 VERSION

version 1.140700

=head1 SYNOPSIS

 use POE::Filter::EPPTCP;
 my $filter = POE::Filter::EPPTCP->new();

 my $wheel = POE::Wheel:ReadWrite->new(
 	Filter		=> $filter,
	InputEvent	=> 'input_event',
 );

=head1 DESCRIPTION

POE::Filter::EPPTCP provides POE with a completely encapsulated EPP over TCP
parsing strategy for POE::Wheels that will be dealing with EPP over TCP streams.

It returns complete frames, which should be XML, but the parsing of the XML
is left to the consumer.

=head1 PRIVATE_ATTRIBUTES

=head2 buffer

    is: ro, isa: ArrayRef, traits: Array

buffer holds the raw data to be parsed. Raw data should be split on network
new lines before being added to the buffer. Access to this attribute is
provided by the following methods:

    handles =>
    {
        has_buffer => 'count',
        all_buffer => 'elements',
        push_buffer => 'push',
        shift_buffer => 'shift',
        unshift_buffer => 'unshift',
        join_buffer => 'join',
    }

=head1 PUBLIC_METHODS

=head2 get_one_start

    (ArrayRef $raw?)

This method is part of the POE::Filter API. See L<POE::Filter/get_one_start>
for an explanation of its usage.

=head2 get_one

    returns (ArrayRef)

This method is part of the POE::Filter API. See L<POE::Filter/get_one> for an
explanation of its usage.

=head2 put

    (ArrayRef $nodes) returns (ArrayRef)

This method is part of the POE::Filter API. See L<POE::Filter/put> for an
explanation of its usage.

=head1 AUTHOR

Mathieu Arnold <mat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Mathieu Arnold <mat@cpan.org>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

