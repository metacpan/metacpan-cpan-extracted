package POE::Filter::LZW::Progressive;

use strict;
use warnings;

use Compress::LZW::Progressive;
use base qw(POE::Filter);

our $VERSION = '0.1';

sub new {
	my ($class, %args) = @_;
	# Filter passthru args to just those that are pertinent
	my %passthru_args = map { $_ => $args{$_} } grep { /^(bits)$/ } keys %args;
	$args{codec} ||= Compress::LZW::Progressive->new(%passthru_args);

	$args{buffer} = '';
	return bless \%args, ref $class ? ref $class : $class;
}

sub reset {
	my $self = shift;
	$self->{codec}->reset();
}

sub clone {
	my $self = shift;
	return $self->new();
}

##

sub get {
	my ($self, $raw_lines) = @_;

	my @records;
	foreach my $line (@$raw_lines) {
		my $decompressed = $self->{codec}->decompress($line);
		push @records, $decompressed;
		printf STDERR "POE::Filter::LZW::Progressive get():  decompressed %d B to %d B\n",
			length($line), length($decompressed) if $self->{debug};
	}
	printf STDERR "POE::Filter::LZW::Progressive get(): returning %d records\n", int(@records) if $self->{debug};
	return \@records;
}

sub get_one_start {
	my ($self, $raw_lines) = @_;

	$self->{buffer} .= join '', @$raw_lines;
	printf STDERR "POE::Filter::LZW::Progressive get_one_start(): buffer now %d\n", length($self->{buffer}) if $self->{debug} > 1;
}

sub get_one {
	my $self = shift;
	return [] unless length $self->{buffer};

	my $return = [ $self->{codec}->decompress( $self->{buffer} ) ];
	printf STDERR "POE::Filter::LZW::Progressive get_one():  decompressed %d B to %d B (%s)\n",
		length($self->{buffer}), length($return->[0]), $self->{codec}->stats('decompress') if $self->{debug};

	$self->{buffer} = '';
	return $return;
}

# Same as get_one() but doesn't clear the buffer
sub get_pending {
	my $self = shift;
	printf STDERR "POE::Filter::LZW::Progressive get_pending()\n" if $self->{debug} > 1;
	return undef unless length $self->{buffer};
	return [ $self->{codec}->decompress( $self->{buffer} ) ];
}

sub put {
	my ($self, $records) = @_;

	my @raw_lines;
	foreach my $record (@$records) {
		my $compressed = $self->{codec}->compress($record);
		push @raw_lines, $compressed;
		print STDERR "POE::Filter::LZW::Progressive put(): ".$self->{codec}->stats('compress')."\n" if $self->{debug};
	}
	return \@raw_lines;
}

1;

__END__

=head1 NAME

POE::Filter::LZW::Progressive -- A POE filter wrapped around Compress::LZW::Progressive

=head1 SEE ALSO

L<POE|POE>
L<Compress::LZW::Progressive|Compress::LZW>

=head1 COPYRIGHT

Copyright (c) 2006 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@uarc.com>

=cut

