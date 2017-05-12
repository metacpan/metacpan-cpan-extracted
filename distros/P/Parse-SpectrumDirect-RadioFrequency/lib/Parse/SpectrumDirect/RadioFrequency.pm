package Parse::SpectrumDirect::RadioFrequency;
use warnings;
use strict;
use 5.008;

=head1 NAME

Parse::SpectrumDirect::RadioFrequency - Parse Industry Canada "Spectrum Direct" radio frequency search output

=head1 VERSION

Version 0.100

=cut

our $VERSION = '0.100';

=head1 DESCRIPTION

This module provides a parser for the "Radio Frequency Search" text-format
output from Industry Canada's Spectrum Direct service.  This service provides
information on the location of RF spectrum licensing, transmitter locations,
etc.

The service is available at http://www.ic.gc.ca/eic/site/sd-sd.nsf/eng/home

The text export is a series of fixed-width fields, with field locations and
descriptions present in a legend at the end of the data file.

=head1 SYNOPSIS

    my $parser = Parse::SpectrumDirect::RadioFrequency->new();

    $parser->parse( $prefetched_output );

    my $legend_hash = $parser->get_legend();

    my $stations = $parser->get_stations();

=head1 METHODS

=over 4

=item new ( )

Creates a new parser.

=cut

sub new
{
	my ($class) = @_;
	return bless({},$class);
}

=item parse ( $raw )

Parses the raw data provided.  Returns a true value if successful, a false if
not.

Parsed data can be obtained with get_legend() and get_stations() (see below).

=cut

sub parse
{
	my ($self, $raw) = @_;
	delete $self->{legend};
	delete $self->{stations};

	return undef unless $raw;

	if( ! $self->_extract_legend( $raw ) ) {
		delete $self->{legend};
		return undef;
	}
	if( ! $self->_extract_stations( $raw ) ) {
		delete $self->{legend};
		delete $self->{stations};
		return undef;
	}

	return 1;
}

=item get_legend ()

Returns the description of fields as parsed from the input data.

Return value is an array reference containing one hash reference per field. 

Each hashref contains:

=over 4

=item name

As in source legend, stripped of trailing spaces

=item units

Units for data value, if determinable from legend.

=item key

Key used in station hashes.  Generated from name stripped of unit information, and whitespaces converted to _.

=item start

Column index to start extracting data value

=item len

Column width, used for data extraction.

=back

=cut

sub get_legend
{
	my ($self) = @_;
	return $self->{legend};
}

=item get_stations ()

Returns station information as parsed from the input data.

=back

=cut

sub get_stations
{
	my ($self) = @_;
	return $self->{stations};
}

# Extract legend as an arrayref of hashrefs.
sub _extract_legend
{
	my ($self, $raw) = @_;

	my ($raw_legend) = $raw =~ m/Field Position Legend(.*)/sm;
	return undef unless $raw_legend;

	$self->{legend} = [];
	foreach my $line (split(/\n/, $raw_legend)) {

		# Lines are in the format of:
		# 	name    start - end
		# with the columns starting at 1.

		my ($name, $start, $end) = $line =~ m/(.*?)\s+(\d+) - (\d+)/;
		next unless $name;
		$name =~ s/\s+$//;

		# Pull off units
		my $units = undef;
		if( $name =~ m/\((.*?)\)$/ ) {
			$units = $1;
		}

		my $key = $name;
		$key =~ s/\(.*?\)//g;
		$key =~ s/\s+$//;
		$key =~ s/\s+/_/g;

		my $col = {
			key   => $key,
			units => $units,
			name  => $name,
			start => $start - 1,
			len   => $end - $start + 1,
		};
		push @{$self->{legend}},$col;

	}

	return $self->{legend};
}

# Return station data as an arrayref of hashrefs, one per row.
sub _extract_stations
{
	my ($self, $raw) = @_;

	my ($data)   = $raw =~ m/\[DATA\](.*)\[\/DATA\]/sm;
	return undef unless $data;

	my $regex   = join('\s', map { "(.{$_->{len},$_->{len}})" } @{$self->{legend}} );
	my @key_ary = map { $_->{key} } @{$self->{legend}};

	$self->{stations} = [];
	foreach my $line (split(/\n/,$data)) {
		my (@tmprow) = $line =~ /$regex/o;

		my %row;
		@row{@key_ary} = map { s/^\s+|\s+$//g; $_ } @tmprow;
		push @{$self->{stations}}, \%row;
	}
	$self->_fixup_station_data();

	return $self->{stations};
}

# Fix some common stupidity with station data
sub _fixup_station_data
{
	my ($self) = @_;


	# Convert to decimal degrees from ddmmss.  Also, force
	# longitude to west (negative), since this is Canada we're
	# dealing with.
	foreach my $s (@{$self->{stations}}) {
		$s->{Latitude}  = _dd_from_dms( $s->{Latitude} ) if exists $s->{Latitude};
		$s->{Longitude} = 0 - _dd_from_dms( $s->{Longitude} ) if exists $s->{Longitude};
	}

	# Change units in legend, too
	foreach my $l (@{$self->{legend}}) {
		if( $l->{key} =~ /^(?:Latitude|Longitude)$/ ) {
			$l->{units} = 'decimal degrees';
		}
	}
}

sub _dd_from_dms
{
	my ($dms) = @_;

	return 0.0 unless $dms;

	my $ss = substr( $dms, -2, 2, '');
	my $mm = substr( $dms, -2, 2, '');
	my $dd = $dms;

	return sprintf('%.6f', $dd + ($mm * 60 + $ss)/3600);
}


1;
__END__

=head1 AUTHOR

Dave O'Neill, C<< <dmo at dmo.ca> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-spectrumdirect at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-SpectrumDirect-RadioFrequency>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::SpectrumDirect::RadioFrequency

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-SpectrumDirect-RadioFrequency>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-SpectrumDirect-RadioFrequency>

=item * Github

L<http://github.com/dave0/Parse-SpectrumDirect-RadioFrequency>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Dave O'Neill, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
