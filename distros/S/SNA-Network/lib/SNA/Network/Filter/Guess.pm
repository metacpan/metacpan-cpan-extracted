package SNA::Network::Filter::Guess;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(load_from_gdf new_from_gdf save_to_gdf);

use Carp;
use English;
use List::MoreUtils qw(pairwise);


=head1 NAME

SNA::Network::Filter::Guess - load and save networks from/to Guess .gdf files


=head1 SYNOPSIS

    use SNA::Network;

    my $net = SNA::Network->new();
    $net->load_from_gdf($filename);
    ...
    # shortcut
    my $net = SNA::Network->new_from_gdf($filename);
    ...
    $net->save_to_gdf(filename => $filename, edge_fields => ['weight']);


=head1 DESCRIPTION

This enables import/export to the GUESS data format.
See L<http://guess.wikispot.org/The_GUESS_.gdf_format> for details about the format.


=head1 METHODS

The following methods are added to L<SNA::Network>.

=head2 load_from_gdf

load a network from a passed filename.
Nodes and edges are created with the fields specified in the file.
They are accessible as hash entries of the objects.

=cut

sub load_from_gdf {
	my ($self, $filename) = @_;
	open my $GDF_FILE, '<', $filename or croak "cannot open '$filename': $OS_ERROR\n";
	
	my $line;
	
	# search start of node definitions
	START:
	while (defined($line = <$GDF_FILE>)) {
		last START if $line =~ m/^nodedef>/;
	}
	$line =~ m/^nodedef> (.+)$/;
	my ($name, $label, @fields) = split /,/, $1;
	foreach (@fields) {
		s/\s*(\w+).*/$1/
	}
	
	# read nodes and create graph nodes
	NODES:
	while (defined($line = <$GDF_FILE>)) {
		last NODES if $line =~ m/^edgedef> (.+)$/;

		#chomp $line;
		$line =~ s/\s//g;
		my ($node_number, $node_name, @field_values) = split ',', $line;
		
		$self->create_node_at_index(
			index => _extract_index($node_number),
			name  => $node_name,
			(pairwise { ($a, $b) } @fields, @field_values)
		);
	}
	
	# read arcs and create graph edges
	$line =~ m/^edgedef> (.+)$/;
	my ($node1, $node2);
	($node1, $node2, @fields) = split /,/, $1;
	foreach (@fields) {
		s/\s*(\w+).*/$1/
	}
	
	EDGES:
	while (defined($line = <$GDF_FILE>)) {
		last EDGES unless $line =~ m/\s*\w+,\s*\w+/;
		
		$line =~ s/\s//g;
		my ($source, $target, @field_values) = split ',', $line;
		$self->create_edge(
			source_index => _extract_index($source),
			target_index => _extract_index($target),
			(pairwise { ($a, $b) } @fields, @field_values)
		);
	}

	close $GDF_FILE or croak "cannot close '$filename': $OS_ERROR\n";
}


=head2 new_from_gdf

Returns a newly created network from a passed filename.
Nodes and edges are created with the fields specified in the file.
They are accessible as hash entries of the objects.

=cut

sub new_from_gdf {
	my ($package, $filename) = @_;
	my $net = $package->new;
	$net->load_from_gdf($filename);
	return $net;
}



=head2 save_to_gdf

Saves the current network to a GDF file.
The named parameters are B<filename>,
and optionally array references in B<node_fields> and B<edge_fields>,
that will write the corresponding hash entries of the objects into the file.

=cut

sub save_to_gdf {
	my ($self, %params) = @_;
	croak "no filename passed to save_to_gdf!" unless $params{filename};
	$params{node_fields} ||= [];
	$params{edge_fields} ||= [];

	open my $GDF_FILE, '>', $params{filename} or croak "cannot open '$params{filename}': $OS_ERROR\n";

	# process nodes
	printf $GDF_FILE "nodedef> %s\n", join ',', ('name', 'label', @{ $params{node_fields} });

	foreach my $node ($self->nodes()) {
		printf $GDF_FILE "%s\n", join(',',
			'n' . ($node->index() + 1),
			$node->{name},
			map { $node->{$_} } @{ $params{node_fields} }
		);
	}

	# process edges
	printf $GDF_FILE "edgedef> %s\n", join ',', qw(node1 node2 directed), @{ $params{edge_fields} };

	foreach my $edge ($self->edges()) {
		printf $GDF_FILE "%s\n", join(',',
			( map { 'n' . ($_->index() + 1) } ($edge->source(), $edge->target()) ),
			'true',
			( map { $edge->{$_} } @{ $params{edge_fields} } )
		);
	}
	
	close $GDF_FILE or croak "cannot close '$params{filename}': $OS_ERROR\n";
}


sub _extract_index {
	my ($node_name) = @_;
	$node_name =~ m/\D+(\d+)/;
	return $1 - 1;
}


=head1 AUTHOR

Darko Obradovic, C<< <dobradovic at gmx.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sna-network-filter-pajek at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNA-Network>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SNA::Network


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SNA-Network>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNA-Network>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNA-Network>

=item * Search CPAN

L<http://search.cpan.org/dist/SNA-Network>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Darko Obradovic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of SNA::Network::Filter::Guess

