package TM::IndexAble;

use strict;
use warnings;

use Data::Dumper;
use Class::Trait 'base';

=pod

=head1 NAME

TM::IndexAble - Topic Maps, Trait to provide lazy and eager indices

=head1 SYNOPSIS

      my $tm = new TM...                           # get any map
      use Class::Trait;
      Class::Trait->apply ($tm, "TM::IndexAble");  # apply the trait

      # add a lazy cache for subclassing and instanceOf
      $tm->index ({ axis => 'taxo' });
      $tm->index ({ axis => 'taxo', closed => 0}); # the same, lazy is NOT closed

      # add eager cache (= index) for taxonometrics
      $tm->index ({ axis => 'taxo', closed => 1}); # eager is closed, will take some time

      # add index for characteristics
      $tm->index ({ axis => 'char'});
      $tm->index ({ axis => 'char', closed => 1}); # can be closed as well

      # ditto for reification
      $tm->index ({ axis => 'reify'});
      $tm->index ({ axis => 'reify', closed => 1});

      # create index/caches, but separate from map itself
      $tm->index ({ axis => 'reify', closed => 0, detached => {} });


      my %stats = $tm->index;                      # get current indices + statistics

=head1 DESCRIPTION

Like L<TM::Index>, this package also adds index/caching capabilities to any topic map stored via
L<TM> (or any of its subclasses). The difference, though, is that the index/caching functionality
is added as a trait, and not via an explicit attachment. The indices are - by default - part of
the map, and not standalone objects as with L<TM::Index>.

When you add an index/cache then you simply use precomputed navigation results for the TM methods
C<match_forall> and C<is_reified> (but not used for C<reifies>).

As with L<TM::Index> you can create caching (lazy indexing) and full indices (eager precaching).

=head2 Map Attachment

To enrich a map with an index/cache, you call the method C<index> provided here. The index/cache
will by default be stored I<inside> the map. That may be convenient in most cases.

If not - as with some storage techniques - you can detach the index to live within your scope. For
that purpose you simply pass in an empty hash reference. It is then your responsibility to get rid
of it afterwards.

Having the index detached also opens the way for you to make the index persistent.

=head1 INTERFACE

=head2 Methods

Following methods are mixed into the class/object:

=over

=item B<index>

I<$tm>->index ({ %spec }, ...)

This method establishes one or more indices/caches to the topic map. Each cache/index is described
with its own hash reference.

Which navigation axes should be covered by a single cache/index is specified with the C<axis> field. It
can have as value one of the axes in L<TM::Axes>, or one of the following values:

=over

=item C<taxo>

Shortcut for the axes: C<subclass.type> C<superclass.type> C<class.type> C<instance.type>

=item C<char>

Shortcut for the axes: C<char.topic> C<char.value> C<char.type> C<char.type.value> C<char.topic.type>

=item C<reify>

=back

To control whether a cache (lazy indexing) or a full index (eager caching) should be
used, the field C<closed> can have two values (default is C<0>):

=over

=item C<0>:

The default is to keep the index I<lazy>. In this mode the index is empty at the start and it will
learn more and more on its own. In this sense, the index lives under an I<open world assumption>
(hence the name), as the absence of information does not mean that there is no result.

=item C<1>:

A I<closed world> index has to be populated to be useful. If a query is launched and the result is
stored in the index, then it will be used, like for an open index. If no result in the index is
found for a query, the empty result will be assumed.

=back

Additionally, a field C<detached> can be passed in for one cache/index. It MUST contain a hash
reference.

Example:

   $tm->index (
           { axis => 'reify', closed => 0, detached => {} },
           { axis => 'char',  closed => 1 }
   );


The method returns a hash with some statistical information for every axis:

=over

=item C<requests>

Number of requests since inception of the index.

=item C<hits>

Number of cache hits since inception. For an eager cache (i.e. index) this number
should be the same as C<requests>

=back


=cut

#    map
#   +---+
#   |   |
#   |   |                                cache
#   |   | index  +-----+ <axis>_data   +-------+                                         <axis>_data     # can be local or detached
#   |   |------->|     |-------------->|       | key = query                             <axis>_hits     # integer
#   +---+        |     | <axis>        |       | value = array ref of LIDs               <axis>_requests # integer
#                |     |-->HASH(0x123) |       |
#                +-----+               |       |
#                                      +-------+

our %cachesets;   # here the detached ones go

#   +---+                 index (detached)                                               # provided by caller
#   |   |  HASH(0x123)  +-------+         cache
#   |   |-------------->|       |       +-------+
#   |   |               |       |------>|       |
#   |   |               |       |       |       |

sub index {
    my $self = shift;

    my $index = ($self->{index} || {});                                                  # local handle on all things indexed

    foreach my $idx (@_) {                                                               # whatever we are given by the user
	my @a = _expand_axes ($idx->{axis});


	my $index2;  # could be detached or local
	if (my $detached  = $idx->{detached}) {                                          # if user provided a detachable index, we take that
	    $cachesets{"$detached"} = $detached;                                         # register that locally (as key this will be stringified)
	    $index->{$_}  = "$detached" foreach @a;                                      # and memorize that the real information is in a detached one, not inside the map
	    $index2       = $detached;                                                   # from now on we work with that
	} else {
	    $index2       = $index;
	}

	foreach my $a (@a) {                                                             # walk over all axes now

#warn "indexable index $a";
	    $index2->{"${a}_hits"}     //= 0;                                            # initialize stats
	    $index2->{"${a}_requests"} //= 0;

	    next if $index2->{"${a}_closed"};                                            # if we already got a closed one, we do not touch it
#warn "AFTER CLOSED!";

	    $index2->{"${a}_data"} //= {}; # we need to have a place for data

	    next unless $idx->{closed};                                                  # only continue here when we want to close it
	    my $data = $index2->{"${a}_data"};                                           # this is a potentially expensive operation

	    if ($a eq 'reify') {                                                         # this is a special case
		my $mid2iid = $self->{mid2iid};                                          # not necessarily cheap
		
		%$data = map  { $mid2iid->{$_}->[TM->ADDRESS] => $_ }                    # invert the index
		         grep { $mid2iid->{$_}->[TM->ADDRESS] }                          # only those which "reify" something survive
		         keys %{$mid2iid};                                               # all toplet tids
		    
	    } else {
		my $enum = $TM::forall_handlers{$a}->{enum}                              # how to generate all assertions of that axes
		           or die "unsupported index axes $a";                           # complain if enumeration is not yet supported
		my $key  = $TM::forall_handlers{$a}->{key};                              # how to derive a full cache key from one assertion
		    
		my %as;                                                                  # collect the assertions for that axis $a
		map { push @{ $as{ &$key ($self, $_) } } , $_->[TM->LID] }               # sort them according to the key
		    &$enum ($self) ;                                                     # generate all assertions fitting this axis
		    
		map { $data->{$_} = $as{$_} }                                            # store the corresponding lists into the cache
		    keys %as;                                                            # walk through keys
	    }
#warn "after axis $a ". Dumper $data;
	    $index2->{"${a}_data"}   = $data;                                            # this is only for MLDBM backed indices (yes, I know a PITA)
	    $index2->{"${a}_closed"} = 1;
	}

    }
    $self->{index} = $index;                                                             # kick MLDBM in the ...
#    warn Dumper ($self->{index}, \%cachesets);

    return _collect_stats ($index) if (wantarray);

sub _collect_stats {
    my $index = shift;
    my %s;
    map { 
	$s{ $1 }->{$2} = $index->{$_} if $_ =~ /(.+)_(.+)/
        }
        keys %{$index};

    %s = (%s , map { _collect_stats ($_) } # and compute the stats from there
	       map { $cachesets{ $index->{$_} } }  # these are detached ones, get them
	       grep { $_ !~ /_/ }         # but only look for those without a _
	       keys %{$index}                       # go back to all indices
	);
    return %s;
    }
}

sub _expand_axes {
    my $a = shift;
    use feature 'switch';
    given ( $a ) {
	when ('taxo') {                                                              # "taxo" shortcuts some axes
	    return qw(subclass.type superclass.type class.type instance.type);
	}
	when ('char') {                                                              # char shortcut
	    return qw(char.topic char.value char.type char.type.value char.topic.type);
	}
	when ('reify') {                                                             # this is a special one
	    return qw(reify);
	}
	default {                                                                    # take that as-is
	    return ( $a );
	}
    }
}


=pod

=item B<deindex>

I<$tm>->deindex (I<$axis>, ....)

I<$tm>->deindex (I<$index>, ....)

This method gets rid of certain indices/caches, as specified by their axes.

Since v1.55: You can also pass in the hash reference of the index (in the detached
case).

Since v1.55: Also the expansion of axes (like for C<index>) works now.

=cut

sub deindex {
    my $self = shift;

    my $index = $self->{index};
#warn "deindex cacheset keys before ".Dumper [ keys %cachesets ];
#warn Dumper $index;
    foreach my $a (map { _expand_axes ($_) } @_) {
#warn "deleting " . $a;
	if (ref ($a)) {                                                        # this is a hash ref, obviously the index
	    delete $cachesets{ "$a" };
            map { delete $index->{$_} }                                        # delete those index entries
                grep { $index->{$_} eq "$a" }                                  # which carry data from the {} we passed in
                keys %$index;
	} elsif (ref ($index->{$a})) {                                         # not detached
	    delete $index->{$a};                                               # so we simply get rid of it
	} else {                                                               # this is also a detached one, but this time via an axis (not the index itself)
	    my $h = delete $index->{$a};                                       # get the hash (stringified) and in one go delete it
	    delete $cachesets{$h};
	}
    }
#warn "deindex cacheset keys before ".Dumper [ keys %cachesets ];
#warn Dumper $index;
    $self->{index} = $index;
}

=pod

=cut

#-- trait mixins

sub match_forall {
    my $self   = shift;
    my %query  = @_;
#warn "forall ".Dumper \%query;

    my @skeys = sort keys %query;                                              # all fields make up the key
    my $skeys = join ('.', @skeys);
    my @svals = map { $query{$_} }                                             # lookup that key in the incoming query
                @skeys;                                                        # take these query keys
    my $key   = "$skeys:" . join ('.', 
				  map { ref ($_) ? @$_ : $_ }                  # if we have a value, take that and its datatype
				  @svals);

#warn "i match ".$skeys;
#warn "i match whole key >>$key<<";
    my $index = $self->{index};                                                # just a handle

    if (my $detached = $index->{$skeys}) {                                     # axis is pointing to a detached
	$index = $cachesets{ $index->{$skeys} };
    }
#warn Dumper $index;
    unless ( my $data = $index->{"${skeys}_data"} ) {
#warn "no index";
	return TM::_dispatch_forall ($self, \%query, $skeys, @svals);

    } else {
#warn "-> using index! $data";
	$index->{"${skeys}_requests"}++;
#warn "DATA keys ".scalar keys %$data;
#warn "DATA ".Dumper $data;	
	if (my $lids = $data->{ $key }) {
#warn "and HIT";
	    $index->{"${skeys}_hits"}++;

	    my $asserts = $self->{assertions};                                 # just in case we have a tied hash ... we create a handle
	    return map { $asserts->{$_} } @$lids;                              # and return fully fledged assocs
	}
	return () if $index->{"${skeys}_closed"};                              # the end of wisdom     ?????????????????????????? SUSPICIOUS
	my @as = TM::_dispatch_forall ($self, \%query, $skeys, @svals);
	$data->{ $key } = [ map { $_->[TM->LID] } @as ];
	return @as;
    }
}



sub is_reified {
    my $self = shift;                                                          # the map
    my $a    = shift;                                                          # the thing (assertion or otherwise)

    my $index = $self->{index};
    if (my $detached = $index->{'reify'}) {                                     # axis is pointing to a detached
	$index = $cachesets{ $index->{'reify'} };
    }

    unless ( my $data = $index->{'reify_data'} ) {                             # if an index over reify has NOT been activated
	return $self->_is_reified ($a);                                        # we look only at the source map

    } else {                                                                   # we have an index!
	$index->{'reify_requests'}++;                                          # bookkeeping

	my $k = ref ($a) ? $a->[TM->LID] : $a;
	if (my $tid = $data->{ $k }) {                                         # cache always holds list references
	    $index->{'reify_hits'}++;                                          # bookkeeping
	    return ($tid);
	}
	return () if $index->{'reify_closed'};                                 # the end of wisdom
#	warn "no hit!";
	my @tids = $self->_is_reified ($a);                                    # returns a list (strangely)
	$data->{ $k } = $tids[0];                                              # tuck it into the cache
	return @tids;                                                          # and give it back to the caller
    }
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::Index>

=head1 COPYRIGHT AND LICENSE

Copyright 20(10) by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = 0.7;

1;

__END__

