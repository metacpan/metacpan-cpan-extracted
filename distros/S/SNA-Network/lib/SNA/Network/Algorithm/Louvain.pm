package SNA::Network::Algorithm::Louvain;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(identify_communities_with_louvain);

use SNA::Network::Community;
use SNA::Network::CommunityStructure;

use List::Util qw(sum);
use List::MoreUtils qw(uniq notall);


=head1 NAME

SNA::Network::Algorithm::Louvain - identifies communities with the Louvain-method developed by Blondel and Guillaume and Lamboitte and Lefebvre


=head1 SYNOPSIS

    use SNA::Network;

    my $net = SNA::Network->new();
    $net->load_from_pajek_net($filename);
    ...
    my $num_communities = $net->identify_communities_with_louvain;


=head1 METHODS

The following methods are added to L<SNA::Network>.

=head2 identify_communities_with_louvain

Performs the community identification algorithm and returns the number of communities it identified. The corresponding L<SNA::Network::Community> objects can be accessed with the C<communities> method of L<SNA::Network>.

=cut

sub identify_communities_with_louvain {
	my ($self, $level) = @_;
	$level ||= 0;
	$self->{louvain_levels} = $level;
	
	$self->{total_weight} = $self->total_weight;
	
	# initialize communities
	foreach ($self->nodes) {
		$_->{community} = $_->index;
		$_->{_k_i} = $_->weighted_summed_degree;
	}
	my @communities = map {
		SNA::Network::Community->new(
			network     => $self,
			level       => $level,
			index       => $_->index,
			members_ref => [$_],
			w_in        => $level > 0 ? $_->loop->weight : 0,
			w_tot       => $_->{_k_i} - ($level > 0 ? $_->loop->weight : 0),
		)
	} $self->nodes;

	$self->{communities_ref} = \@communities;
	
	my $has_changed = 0;
	my $has_improved;
	
	PHASE_ONE_ITERATIONS:
	do {
		$has_improved = 0;
		
		foreach my $node_i ($self->nodes) {
			my $max_gain = 0;
			my $best_community_id;

			$node_i->{_k_i_in} = sum(
				$level > 0 ? - $node_i->loop->weight : 0,
				map {
					$_->weight
				} grep {
					$_->source->community == $_->target->community
				} $node_i->edges
			);
			
			my $current_community = @communities[ $node_i->community ];
			
			# gain in current community on removal
			my $current_community_module = _module_value(
				$current_community->w_in,
				$current_community->w_tot,
				$self->{total_weight},
			);
	
			my $new_current_community_module = _module_value(
				$current_community->w_in - $node_i->{_k_i_in},
				$current_community->w_tot - $node_i->{_k_i} + $node_i->{_k_i_in},
				$self->{total_weight},
			);
			
			my $gain_on_removal = $new_current_community_module - $current_community_module;
			
			# pre-calculate k_i_new values for all neighbour communities
			foreach ($node_i->outgoing_edges) {
				$node_i->{_k_i_new}->{ $_->target->community } += $_->weight
			}

			foreach ($node_i->incoming_edges) {
				$node_i->{_k_i_new}->{ $_->source->community } += $_->weight
			}

			if ($level > 0) {
				my $loop_weight = $node_i->loop->weight;

				foreach ( values %{ $node_i->{_k_i_new} } ) {
					$_ += $loop_weight;
				}
			}

			my @neighbour_community_ids = uniq grep {
				$_ != $node_i->community
			} map {
				$_->community
			} $node_i->related_nodes;
			
			foreach my $neighbour_community_id (@neighbour_community_ids) {
				# calculate modularity changes
				my $gain_on_addition = _modularity_gain($self, $node_i, $neighbour_community_id);
				my $gain = $gain_on_removal + $gain_on_addition;
				
				if ( $gain > $max_gain ) {
					$max_gain = $gain;
					$best_community_id = $neighbour_community_id;
				}
			}
			
			if ( $max_gain > 0.0000001 ) {
				# merge node to best community
				
				_switch_community($self, $node_i, $best_community_id);
				$has_improved = 1;
				$has_changed = 1;
			}
			
			undef $node_i->{_k_i_in};
			undef $node_i->{_k_i_new};
		}
	} while ($has_improved);

	_consolidate_community_structure($self);

	return map { $_->subcommunities } @communities unless $has_changed;

	$self->{louvain_levels} += 1;
		
	
	PHASE_TWO:

	# merge communities to new nodes in a new network
	my $next_level_network = _create_next_level_network($self);
	
	# apply the algorithm recursively to the new network
	my @new_community_structure = $next_level_network->identify_communities_with_louvain($level + 1);
	
	$self->{louvain_levels} = $next_level_network->{louvain_levels};
	return @new_community_structure if $level > 0;

	# build the hierarchical community structure
	my @community_levels = _build_hierarchy(@new_community_structure);

	$self->{community_levels} = \@community_levels;
	$self->{communities_ref} = \@new_community_structure;
	return int $self->communities;
}


sub _modularity_gain {
	my ($net, $node_i, $new_community_id) = @_;
	my $new_community = $net->{communities_ref}->[$new_community_id];

	my $k_i_new = $node_i->{_k_i_new}->{ $new_community_id };

	my $neighbour_community_module = _module_value(
		$new_community->w_in,
		$new_community->w_tot,
		$net->{total_weight},
	);
		
	my $new_neighbour_community_module = _module_value(
		$new_community->w_in + $k_i_new,
		$new_community->w_tot + $node_i->{_k_i} - $k_i_new,
			$net->{total_weight},
	);

	return $new_neighbour_community_module - $neighbour_community_module;
}


sub _module_value {
	my ($w_in, $w_tot, $w_net) = @_;
	return $w_in / $w_net - ( ( $w_in + $w_tot ) / ( 2 * $w_net ) ) ** 2;
}


sub _switch_community {
	my ($net, $node, $new_community_id) = @_;
	my $current_community = $net->{communities_ref}->[ $node->community ];
	my $new_community = $net->{communities_ref}->[$new_community_id];
	
	@{ $current_community->members_ref } = grep {
		$_ != $node
	} $current_community->members;

	push @{ $new_community->{members_ref} }, $node;

	$node->{community} = $new_community_id;
	
	$current_community->{w_in}  -= $node->{_k_i_in};
	$current_community->{w_tot} -= $node->{_k_i} - $node->{_k_i_in};
	
	$new_community->{w_in}  += $node->{_k_i_new}->{ $new_community_id };
	$new_community->{w_tot} += $node->{_k_i} - $node->{_k_i_new}->{ $new_community_id };
}


sub _consolidate_community_structure {
	my ($self) = @_;

	@{$self->{communities_ref}} = grep {
		int $_->members > 0
	} $self->communities;


	my $index = 0;
	foreach my $community ($self->communities) {
		$community->{index} = $index;

		foreach my $member ($self->{communities_ref}->[$index]->members) {
			$member->{community} = $index;
		}

		$index += 1;

		next if $self->{louvain_levels} == 0;

		my @subcommunities = map {
			$_->{subcommunity}
		} $community->members;
				
		$community->{subcommunities} = \@subcommunities;
		undef $community->{members_ref};
	}
	
#	for my $index (0 .. int($self->communities) - 1) {
#		$self->{communities_ref}->[$index]->{index} = $index;
#		foreach my $member ($self->{communities_ref}->[$index]->members) {
#			$member->{community} = $index;
#		}
#	}
}


sub _create_next_level_network {
	my ($net) = @_;
	
	my $next_level_network = SNA::Network->new;
	foreach my $community ($net->communities) {
		my $new_node = $next_level_network->create_node(
			community    => $community->index,
			subcommunity => $community,
		);
		$next_level_network->create_edge(
			source_index => $new_node->index,
			target_index => $new_node->index,
			weight       => $community->w_in,
		);
	}
	
	my $nc = int $net->communities;
	my @edge_weights = map { {} } 1 .. $nc;
	foreach my $edge ($net->edges) {
		$edge_weights[ $edge->source->community ]->{ $edge->target->community } += $edge->weight;
	}
	
	foreach my $meta_node ($next_level_network->nodes) {
		PEERS:
		foreach my $peer_node ($next_level_network->nodes) {
			next PEERS if $meta_node == $peer_node;
			my $weight = $edge_weights[ $meta_node->index ]->{ $peer_node->index };
			
			if ($weight) {
				$next_level_network->create_edge(
					source_index => $meta_node->index,
					target_index => $peer_node->index,
					weight       => $weight,
				);
			}
		}
	}
	
	return $next_level_network;
}


sub _build_hierarchy {
	my (@communities) = @_;

	return SNA::Network::CommunityStructure->new(@communities) if $communities[0]->level == 0;

	my @subcommunities = map {
		$_->subcommunities
	} @communities;

	return _build_hierarchy(@subcommunities), SNA::Network::CommunityStructure->new(@communities);
}


=head1 AUTHOR

Darko Obradovic, C<< <dobradovic at gmx.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sna-network-node at rt.cpan.org>, or through
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


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2012 Darko Obradovic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;

