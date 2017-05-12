package TM::Synchronizable::MapSphere;

use strict;
use warnings;

use TM;

use Data::Dumper;

use Class::Trait 'base';
use Class::Trait 'TM::ResourceAble';
use TM::MapSphere;

#our @REQUIRES = qw(source_in source_out);

# provides sync_in/out

=pod

=head1 NAME

TM::Synchronizable::MapSphere - Topic Maps, trait for a syncing a hierarchical TM repository

=head1 SYNOPSIS

   use TM;
   use base qw(TM);
   use Class::Trait ('TM::MapSphere',
                     'TM::Synchronizable::MLDBM' => {
   		         exclude => [ "sync_in", "sync_out" ]
   		     },
                     'TM::Synchronizable::MapSphere');

=head1 DESCRIPTION

This trait adds C<sync_in> and C<sync_out> functionality to a map sphere. The
point here is that embedded child maps are also synced out or in.

=head2 Map Meta Data

=head1 INTERFACE

=head2 Methods

=over

=item B<sync_in>

I<$ms>->sync_in (I<$path>)

A whole subtree of the map repository can be I<sync'ed in>, i.e. synchronized with contents in an
associated resource. If this method is triggered with a particular path, then the map there will be
(a) synced in, (b) queried for sub-maps and (c) these sub-maps will be instantiated.  Recursively,
these submaps will be sync'ed in, etc. All these sub maps will be mounted under this branch of the
tree.

When a map is instantiated, its implementation package will be extracted from the parent map using a
C<implementation> characteristic. The resource URL will be determined from one of the subject
indicators, the base URI will be determined from the subject address of the map topic. If any of
these are missing, this particular sub-map is ignored.

B<Example>: Let us assume that a map has a C<baseuri> C<http://whatever/> and a resource URL
C<http://example.org/here.xtm>. It is a materialized map using the XTM driver. If this map is
mounted into a root map under C</foo/>, then the entry will take the form (using AsTMa= 2.0 as
notation):

   foo isa topicmap
   ~ http://example.org/here.xtm
   = http://whatever/
   implementation: TM::Materialized::XTM

@@@ TODO: no path @@@@?   

=cut

use constant MAX_DEPTH => 99;

sub sync_in {
    my $self  = shift;
    my $pref  = shift || '/';                                                            # prefix determines from where we would want to start to sync
    my $depth = shift || MAX_DEPTH;

#warn "sync in mapsphere last mod : ".$self->last_mod;
#warn "sync in mapsphere mtime    : ".$self->mtime;
    $self->source_in if $pref eq '/'                                                     # but only if we start at the top
                     && $self->last_mod < $self->mtime + 1;                              # and the usual exercise + benefit of doubt

    _sync_in_children ($self, $self, '/', $pref, $depth - 1);                            # now we find all children, sync_in them and mount them

sub _sync_in_children {
    my $top   = shift; 									 # will be passed through all recursivel leves
    my $map   = shift; 									 # current map whose children we seek
    my $path  = shift; 									 # the current path for mounting
    my $pref  = shift;                                                                   # the prefix, only under it we seriously do something
    my $depth = shift;

#warn "_sync_in_children $top $map $path $pref ($depth)";

    return unless $depth;                                                                # if we have reached our limit, we stop

    foreach my $m ( $map->instances ($map->mids (\ TM::PSI->TOPICMAP)) ) {
        (my $id = $m) =~ s|.+/(.+)|$1|;                                                  # throw away the baseuri stuff
#warn "id $id";
	my $newpath = $path . "$id/";                                                    # child will have this path
#warn "consider $newpath, compare it with $pref";
	if ($newpath =~ /^$pref/) {                                                      # only if the prefix is matched we seriously do something
#warn "--- $newpath within prefix $pref";

	    my $mid = $map->midlet ($m);                                                     # get the topic itself
#warn Dumper $mid;
	    my ($url)            = @{$mid->[TM->INDICATORS]}                        or next; # if there is no subject indicator, we could not load it anyway
	    my ($baseuri)        =   $mid->[TM->ADDRESS]                            or next; # if there is no subject address, we could not load it anyway

	    my ($implementation) = map { $_->[ TM->PLAYERS ]->[1]->[0] }
	                           $map->match (TM->FORALL, char => 1, topic => $m, type => $map->mids (\ TM::MapSphere->IMPLEMENTATION))
		or next;
	    
	    my $child;
#warn "-- implementation $implementation";
	    eval {
		$child = $implementation->new (url => $url, baseuri => $baseuri );
	    }; $TM::log->logdie (scalar __PACKAGE__ .": cannot instantiate '$implementation' (maybe 'use' it?) for URL '$url' ($@)") if $@;
	    
	    $child->sync_in;
#warn "---- synced in";
	    $top->mount ($newpath => $child, 1);                                          # finally mount this thing into the current, force it in case
#warn "-------mounted $newpath";
	    _sync_in_children ($top, $child, $newpath, $pref, $depth-1);                  # go down recursively (depth TTL included)
#warn "---- back from children";
	}
    }
#warn "children done";
}
}

=pod

=item B<sync_out>

I<$ms>->sync_out ([ I<$path> ], [ I<$depth> ])

This method syncs out not only the root map sphere object (at least if the resource C<mtime> is
earlier that any change on the map sphere). The method also consults the mount tab to find child
maps and will sync them out as well.

The optional C<path> parameter controls which subtree should be synced out. It defaults to C</>.

The optional C<$depth> controls how deep the subtree should be followed downwards. Default is
C<MAX_DEPTH> (see the source).

=cut

sub sync_out {
    my $self  = shift;
    my $pref  = shift || '/';
    my $depth = shift || MAX_DEPTH;

# warn __PACKAGE__ . "sync_out";
# warn "calling $self source out";

#warn "sync out mapsphere last mod : ".$self->last_mod;
#warn "sync out mapsphere mtime    : ".$self->mtime;
    if (   $pref eq '/'
	&& $self->mtime < $self->last_mod) {                                             # there was a change internally
#warn "really sync out mapspheric root";
	my $mt = delete $self->{mounttab};                                               # this make sure that only the map is source'd out (MLDBM would take EVERYTHING)
	$self->source_out if $self->last_mod > $self->mtime;
	$self->{mounttab} = $mt;                                                         # reinstate mount table
    }

    my $mt = $self->{mounttab};
    foreach my $path (grep ($_ ne '/', keys %$mt)) {                                     # all children (not the root)
#warn "--- considering $path for sync_out";	
	next unless $path =~ /^$pref/;
	my @segs = $path =~ /(\/)/g;
	next if scalar @segs > $depth;
#warn "--- really chosen $path for sync_out";	
	$mt->{$path}->sync_out;
    }
}

=pod

=back

=head1 AUTHOR

Robert Barta, E<lt>drrho@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 200[67] by Robert Barta

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself, either Perl version 5.8.4 or, at your option, any later version of Perl 5 you may have
available.

=cut

our $VERSION  = 0.02;
our $REVISION = '$Id: MapSphere.pm,v 1.3 2006/11/25 08:46:59 rho Exp $';

1;

__END__
