package TM::Index::Match;

use strict;
use warnings;
use Data::Dumper;

use base qw(TM::Index);

=pod

=head1 NAME

TM::Index::Match - Topic Maps, Indexing support (match layer)

=head1 SYNOPSIS

    # somehow get a map (any subclass of TM will do)
    my $tm = ... 

    # one option: create a lazy index which learns as you go
    use TM::Index::Match;
    my $idx = new TM::Index::Match ($tm);
    
    # for most operations which involve match_forall to be called
    # reading and querying the map should be much faster

    # learn about some statistics, what keys are most likely to be useful
    my @optimized_keys = @{ $stats->{proposed_keys} };

    # another option: create an eager index
    my $idx = new TM::Index::Match ($tm, closed => 1);

    # pre-populate it, use the proposed keys
    $idx->populate (@optimized_keys);
    # this may be a lengthy operation if the map is big
    # but then the index is 'complete'

    # query map now, should also be faster

    # getting rid of an index explicitly
    $idx->detach;

    # cleaning an index
    $idx->discard;

=head1 DESCRIPTION

This index implements a generic query cache which can capture all queries not handled by more
specific indices. This class inherits directly from L<TM::Index>.

=head1 INTERFACE

=head2 Constructor

The constructor/destructors are the same as that described in L<TM::Index>.

=head2 Methods

=over

=item B<populate>

I<$idx>->populate (I<@list_of_keys>)

To populate the index with canned results this method can be invoked. At this stage it is not very
clever and may take quite some time to work its way through a larger map. This is most likely
something to be done in the background.

The list of keys to be passed in is a bit black magic. Your current best bet is to look at the
index statistics method, and retrieve a proposed list from there:

   @optimized_keys = @{ $stats->{proposed_keys} };

   $idx->populate (@optimized_keys[0..2]); # only take the first few

If this list is empty, nothing clever will happen.

=cut

sub populate {
    my $self = shift;
    my @halfkeys = @_ or return;
    my $map  = $self->{map};

    my $indices = delete $map->{indices}; # detach temporarily

    my @mids = map { $_->[TM->LID] } $map->toplets;
    foreach my $halfkey (@halfkeys) {
	my @keys = split /\./, $halfkey;
#warn "keys ".(join "    ", @keys);
	_combinatorial (\@mids, [], scalar @keys - 1, \@keys, $self->{closed}, $map, $self->{cache});
    }
    $map->{indices} = $indices; # re-attach

sub _combinatorial {
    my $mids   = shift; # will be passed through
    my $idxs   = shift; # will be accumulated in every recursion
    my $depth  = shift; # will be decremented at every recursion
    my $keys   = shift; # just pass them through
    my $closed = shift; # pass through
    my $map    = shift;
    my $cache  = shift;

    for (my $i = 0; $i <= $#$mids; $i++) {                                     # iterate over all indices of mids
        my $l = [ @$idxs, $i ];                                                # build an uptodate index list
        if ($depth) {                                                            # we are still not at the bottom of things
            _combinatorial ($mids, $l, $depth - 1, $keys, $closed, $map, $cache);      # recurse
        } else {                                                               # we reached the correct length
#warn "have indices ".join ("..", @$l);
	    my @vals  = map { $mids->[$_] } @$l;                               # the values are all mids, taking from the mids list
	    my %query = map { $_ => shift @vals } @$keys;                      # build a match query
#warn "query ".Dumper \%query;
	    my @as    = $map->match_forall (%query);                           # compute the results
#warn "got back ".Dumper \ @as;
	    my @skeys = sort keys %query;                                      # recompute the total key (including the values)
	    my $skeys = join ('.', @skeys);
	    my @svals = map { $query{$_} } @skeys;
	    my $key   = "$skeys:" . join ('.', @svals);
#warn "computed key '$key'";

	    if (@as) {                                                         # if the match list is not empty
		$cache->{$key} = [ map { $_->[TM->LID] } @as ];                # memorize it
	    } elsif ($closed) {                                                # otherwise, if empty, check on close
		# don't do nothing, dude                                       # that's exactly the meaning of 'closed'
	    } else {
		$cache->{$key} = [];                                           # in an open world record the result
	    }
        }
    }
}
}

=pod

=item B<statistics>

I<$hashref> = I<$idx>->statistics

This returns a hash containing statistical information about certain keys, how much data is behind
them, how often they are used when adding information to the index, how often data is read out
successfully. The C<cost> component can give you an estimated about the cost/benefit.

=cut

sub statistics {
    my $self = shift;

    my %stats;
    foreach my $q (keys %{ $self->{cache} }) {
	$q =~ /([^:]+)/;
	my $ki;
	$ki->{writes}++;
	$ki->{reads} += $self->{reads}->{$q};
	$ki->{size}  += scalar @{ $self->{cache}->{$q} };

        $ki->{cost}              = $ki->{writes} / $ki->{reads};  # it is impossible that reads == 0
        $ki->{avg_size_of_read}  = $ki->{size}   / $ki->{reads};
        $ki->{avg_size_of_write} = $ki->{size}   / $ki->{writes};
        $stats{keys}->{$1} = $ki;
    }
    $stats{proposed_keys} = [ sort { $stats{keys}->{$a}->{cost} <=> $stats{keys}->{$b}->{cost} } keys %{$stats{keys}} ];
    return \%stats;
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::Index>

=head1 COPYRIGHT AND LICENSE

Copyright 200[6] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = 0.3;
our $REVISION = '$Id: Match.pm,v 1.2 2006/12/01 08:01:00 rho Exp $';

1;

__END__
