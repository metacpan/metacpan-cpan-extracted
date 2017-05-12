package SNA::Network::Filter::Pajek;

use warnings;
use strict;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(load_from_pajek_net new_from_pajek_net save_to_pajek_net);

use Carp;
use English;


=head1 NAME

SNA::Network::Filter::Pajek - load and save networks from/to Pajek .net files


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use SNA::Network;

    my $net = SNA::Network->new();
    $net->load_from_pajek_net($filename);
    ...
    # shortcut
    my $net = SNA::Network->new_from_pajek_net($filename);
    ...
    $net->save_to_pajek_net($filename);


=head1 DESCRIPTION

This enables import/export to the Pajek data format.
See L<http://vlado.fmf.uni-lj.si/pub/networks/pajek/> for details about the format.


=head1 METHODS

The following methods are added to L<SNA::Network>.

=head2 load_from_pajek_net

load a network from a passed filename.
Nodes and edges are created as specified in the file, with the vertex name in the I<name> field of the created nodes.

=cut

sub load_from_pajek_net {
	my ($self, $filename) = @_;
	open my $PAJEK_FILE, '<', $filename or croak "cannot open '$filename': $OS_ERROR\n";
	
	my $line;
	
	# search start of vertex definitions
	START:
	while (defined($line = <$PAJEK_FILE>)) {
		last START if $line =~ m/\*Vertices/;
	}
	
	# read vertices and create graph nodes
	VERTICES:
	while (defined($line = <$PAJEK_FILE>)) {
		last VERTICES if $line =~ m/\*Arcs/;

		$line =~ m/\s*(\d+)\s*(.*)/ or next VERTICES;
		my ($node_number, $node_name) = ($1, $2);
		
		$self->create_node_at_index(index => $node_number - 1, name => $node_name);
	}
	
	# read arcs and create graph edges
	EDGES:
	while (defined($line = <$PAJEK_FILE>)) {
		last EDGES unless $line =~ m/\s*(\d+)\s*(\d+)\s*(\d+)/;
		my ($source_index, $target_index, $weight) = ($1 - 1, $2 - 1, $3);
		$self->create_edge(
			source_index => $source_index,
			target_index => $target_index,
			weight       => $weight,
		);
	}

	close $PAJEK_FILE or croak "cannot close '$filename': $OS_ERROR\n";
}



=head2 new_from_pajek_net

Returns a newly created network from a passed filename.
Nodes and edges are created as specified in the file, with the vertex name in the I<name> field of the created nodes.

=cut

sub new_from_pajek_net {
	my ($package, $filename) = @_;
	my $net = $package->new;
	$net->load_from_pajek_net($filename);
	return $net;
}



=head2 save_to_pajek_net

=cut

sub save_to_pajek_net {
	my ($self, $filename) = @_;

	open my $PAJEK_FILE, '>', $filename or croak "cannot open '$filename': $OS_ERROR\n";

	# process vertices
	printf $PAJEK_FILE "*Vertices %d\n", int $self->nodes();
	foreach my $node ($self->nodes()) {
		printf $PAJEK_FILE "%d %s\n", $node->{index} + 1, $node->{name} || 'none';
	}

	printf $PAJEK_FILE "*Arcs\n";
	foreach my $arc ($self->edges()) {
		printf $PAJEK_FILE "%d %d %d\n",
			$arc->source()->index() + 1, $arc->target()->index() + 1, $arc->weight();
	}
	
	close $PAJEK_FILE or croak "cannot close '$filename': $OS_ERROR\n";
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

1; # End of SNA::Network::Filter::Pajek
