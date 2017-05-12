package TM::MapSphere;

use strict;
use warnings;

use TM;
use TM::PSI;
use TM::Literal;

use Data::Dumper;

use Class::Trait 'base';

our @REQUIRES  = qw(internalize assert retract externalize match);

=pod

=head1 NAME

TM::MapSphere - Topic Maps, trait for a hierarchical TM repository

=head1 SYNOPSIS

    # construct an adhoc-ish map sphere

    use TM;
    my $tm = new TM;                            # create a map

    use Class::Trait;
    Class::Trait->apply ($tm, 'TM::MapSphere'); # make it a sphere

    $tm->mount ('/abc/' => new TM);             # mount a map into location /abc/
    # this creates a topic in the map with a reference to another (empty) map

    # any subclass of TM can used
    $tm->mount ('/def/' => new TM::Materialized::AsTMa (file => 'test.atm'));

    # check a mount point
    warn "damn" unless $tm->is_mounted ('/xxx/');

    # do some sync stuff on any resource-connected map
    $tm->is_mounted ('/def/')->sync_in;

    # get rid of some mount point
    $tm->umount ('/abc/');

    $tm->internalize ('aaa');         # it is a map, so all map methods work
    print $tm->mids ('def');          # this topic exists and should be a map
    # find all child maps
    @maps = $tm->instances  (\ TM::PSI->TOPICMAP);


=head1 DESCRIPTION

This package provides a I<mapspheric> trait, i.e. all functionality to convert any map into a
(hierarchical) Topic Maps database. The basic idea is that one map (the I<root>) contains not only
arbitrary map data, but can also contain references to other maps. On the top level, addressed as
C</> is then the root map. The child maps have addresses such as C</abc/> and
C</internet/web/browsers/>. The idea is also that a map can contain other maps, simply by having
topics which stand for these child maps. In that sense, a map is always a tree of maps (hence
I<MapSphere>).

These trees are not necessarily static. At any point, a new map can be hooked in, or removed. This
process is quite similar to I<mounting> devices into a UNIX file system.

Each of the referenced child maps is represented as a topic of a predefined type C<TM::PSI::TOPICMAP>, 
the subject indicator is interpreted as the URL to the resources for these maps.

The root map can be any subclass of L<TM>. You can therefore choose to have only a shortlived
mapsphere which will be lost on process termination, or alternatively, to take one of the persistent
storages. Also, the individual child maps can be of different provenances. Any subclass of L<TM>
will do, consequently also any which have the trait of L<TM::ResourceAble> or
L<TM::Synchronizable>. This implies that this database can be heterogenuous, in that different maps
can be stored differently, or can even be kept remotely.

Once you have your map sphere, you can write it out via synchronization with the external
resources. You can do this for the whole sphere, or for a particular subtree of maps. Conversely,
you can read in the whole map sphere by starting with the root and letting the system to recursively
bootstrap the whole sphere.

=head2 Tau Objects

Map spheres can only store I<Tau objects>. At the moment, these are only maps. See L<TM::PSI> for
predefined things.

=head2 Namespace

To address a particular object in a repository we follow a convention similar to file system paths:
Every object has a path like

  /something/complete/else/

Note, that all paths for maps should start and end with a C</>, so that maps can be seen as
I<directories>. All other objects (constraints, queries, ...) are represented as topics.

The namespace cannot have I<holes>, so that the following will result in an error:

   $tm->mount ('/something/', ...);
   $tm->mount ('/something/completely/else/', ....);  # we will die here

=cut

use constant EMPTY => { '/' => '/' };

=pod

=head2 Map Meta Data

Since a map sphere behaves like a map, any meta data about child maps should be modelled according
to the TM paradigm.

=head1 INTERFACE

This interface allows to I<mount> and I<unmount> other maps into another.

=head2 Methods

=over

=item B<mount>

I<$tm>->mount (I<$path> => I<$tm2>, [ $force ])

This mounts a map C<$tm2> into the map sphere at the given path. Only maps can be mounted,
everything else results in an error. The root will be always mounted to the map sphere itself.  It
is an error to try to change this.

If the mount point is already taken, an exception will be raised. This can be suppressed when
the C<force> parameter is set:

   $tm->mount ('/xyz/' => $child, 1);

A topic of type C<topicmap> (see L<TM::PSI>) is created in the map above the mount point. The base
URI of the map is used as subject address. If the mounted map has a resource URL that is used as
subject indicator (identifier in TMDM-speak). Additionally, the topic gets asserted characteristics:

=cut

use constant {
    IMPLEMENTATION => 'http://tm.devc.at/mapsphere/implementation',
    MIME           => 'http://tm.devc.at/mapsphere/mime',
    CREATED        => 'http://tm.devc.at/mapsphere/created'
};

=pod

=over

=item mime (default: C<unknown>)

A MIME type occurrence of type C<http://tm.devc.at/mapsphere/mime> which is a string value.

=item created

An occurrence of type C<http://tm.devc.at/mapsphere/created> carrying the UNIX time at mounting
time.

=back

Maps can only be mounted into other maps if these already are also mounted. The following code will
not work:

   my $tm = new SomeMapSphere;
   $tm->mount ('/abc/def/' => ....);   # die here because there is no map mounted to /abc/ yet

=cut

sub _find_longest_match {
    my $p = shift;
    my @ps = sort { length($b) <=> length($a) } @_;

#warn "_find_longest_match  $p ". Dumper \@ps;
    foreach (@ps) {
        return $_ if ($p =~ /^$_/);
    }
    return undef;
}

sub mount {
    my $self  = shift;
       $self->{mounttab} ||= { %{TM::MapSphere->EMPTY} };                                    # just to make sure there is something
    my $path  = shift;
    my $obj   = shift;
    my $force = shift || 0;                                                                  # default is: we do not push it

    delete $self->{mounttab}->{$path} if $force;                                             # but if so, get rid of it first

    $TM::log->logdie (scalar __PACKAGE__ .": cannot mount over root")             if     $path eq '/';
    $TM::log->logdie (scalar __PACKAGE__ .": can only mount map objects")         unless (ref ($obj) && $obj->isa ('TM'));
    $TM::log->logdie (scalar __PACKAGE__ .": mount point '$path' already taken")  if     exists $self->{mounttab}->{$path};

#warn "trying to mount $path";

    my $mounttab = $self->{mounttab};

    my $p = _find_longest_match ($path, keys %{$mounttab});
#warn "found max path $p for new path $path";
    (my $id = $path) =~ s/^$p([\w\.\-\_]+)\/$/$1/
	                          or $TM::log->logdie (scalar __PACKAGE__ .": mount point for '$path' does not yet exist ($p)");
#warn "id now $id";
    { 
#warn "finding map for $p";
	my $map = $self->is_mounted ($p)                                                    # find map above the mount point
                                  or $TM::log->logdie (scalar __PACKAGE__ .": no map above this mount point");
        my $mid = $map->internalize ($id);
#warn "adding baseuri as address ".$obj->baseuri;
	$map->internalize ($mid =>   $obj->baseuri);
	$map->internalize ($mid => \ $obj->url)     if $obj->can ('url');
	$map->assert (Assertion->new (type => 'isa',   roles => [ 'class', 'instance' ], players => [ 'topicmap',                     $mid ]));

	$map->assert (Assertion->new (kind  => TM->OCC, type => $map->internalize (undef, \ MIME),
				      roles => [ 'value', 'thing' ],    players => [ $obj->{mime} || new TM::Literal ('unknown'), $mid ]));
	$map->assert (Assertion->new (kind  => TM->OCC, type => $map->internalize (undef, \ CREATED),
				      roles => [ 'value', 'thing' ],    players => [ new TM::Literal (time),         $mid ]));
	$map->assert (Assertion->new (kind  => TM->OCC, type => $map->internalize (undef, \ IMPLEMENTATION),
				      roles => [ 'value', 'thing' ],    players => [ new TM::Literal (ref ($obj)),   $mid ]));
#warn Dumper $map;
    }

#warn "adding $path to mounttab with ob $obj";
    $mounttab->{$path} = $obj;                                                              # link it into our mounttab
    $self->{mounttab} = $mounttab;
}

=pod

=item B<umount>

I<$tm>->umount (I<$path>)

This unmounts a map from the object map. Obviously, the path must point to an existing topic of type
C<topicmap>. All maps beyond this mount point are removed, i.e. also all children will go down the
drain.

The root cannot be unmounted.

=cut

sub umount {
    my $self = shift;
       $self->{mounttab} ||= { %{TM::MapSphere->EMPTY} };                                   # just to make sure there is something
    my $path = shift;

    $TM::log->logdie (scalar __PACKAGE__ .": cannot unmount root") if $path eq '/';

    my $mounttab = $self->{mounttab};

    map { delete $mounttab->{$_} }                                                          # get rid of all mount entries which have this a prefix
          grep ($_ =~ /^$path/, 
	            keys %$mounttab);

    my $p = _find_longest_match ($path, keys %$mounttab);
#warn "found max path $p for new path $path";
    (my $id = $path) =~ s/^$p([\w\.\-\_]+)\/$/$1/
	                          or $TM::log->logdie (scalar __PACKAGE__ .": mount point for '$path' does not exist");
#warn "id now $id";
    my $map = $self->is_mounted ($p)                                                        # find map above the mount point
	                          or $TM::log->logdie (scalar __PACKAGE__ .": no map above this mount point");
    $map->retract (map { $_->[TM->LID] } $map->match (TM->FORALL, 
						      iplayer => $map->mids ($id)));        # remove all involvements
    $map->externalize ($map->mids ($id));                                                   # remove the midlet and return it

    $self->{mounttab} = $mounttab;
}

=pod

=item B<is_mounted>

I<$child> = I<$tm>->is_mounted (I<$path>)

Simply returns a map object mounted on that given mount point. C<undef> if there is none.

=cut

sub is_mounted {
    my $self = shift;
       $self->{mounttab} ||= { %{TM::MapSphere->EMPTY} };    # just to make sure there is something
    my $path = shift;

    if ($path eq '/') {                               # if we talk about the root, then return the map itself
	return $self;                                 # could store that, but then have cyclic structure, don't like that
    } else {                                          # otherwise arbitrary path
	return $self->{mounttab}->{$path};
    }
}

=pod

=item B<mounttab>

%mt = %{ I<$tm>->mounttab }

I<$tm>->mounttab ( \ I<$%mt> )

This accessor sets/gets the mount table.

B<Note>: You will hardly need access directly to it, normally, and changing it in an uncontrolled
way may corrupt the whole data structure. The reason it exists, though, is that sometimes you
B<have> to indicate that there is a change, such as when using this together with MLDBM.

This, for example, does NOT work:

  {
   my $tm = new ...MapSphericalClassUsingMLDBM...;
   ...
   $tm->is_mounted ('/whatever/')->sync_in;
   # A: now the child is happily sync'ed in
   # but MLDBM did not realize it, so it is not written back into the
   # underlying file
   }
  {
   # regain the MLDBM based MapSphere later
   my $tm = new ...MapSphericalClassUsingMLDBM...;
   # child is not sync'ed in as under A: above
   }

This does work:

  {
   my $tm = new ...MapSphericalClassUsingMLDBM...;
   ...
   my $mt = $tm->mounttab;
   $tm->is_mounted ('/whatever/')->sync_in;
   $tm->mounttab ($mt);
   # now the changes will be written onto the MLDBM file
   }

Of course, more thought can be spent on I<how much> actually has to be written back. Above approach
may be wasteful.

=cut

sub mounttab {
    my $self = shift;
       $self->{mounttab} ||= { %{TM::MapSphere->EMPTY} };                                    # just to make sure there is something
    my $mt   = shift;
    return $mt ? $self->{mounttab} = $mt : $self->{mounttab};
}

=pod

=back

=head1 AUTHOR

Robert Barta, E<lt>drrho@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 200[4-7] by Robert Barta

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself, either Perl version 5.8.4 or, at your option, any later version of Perl 5 you may have
available.

=cut

our $VERSION  = 0.05;
our $REVISION = '$Id: MapSphere.pm,v 1.25 2006/12/13 10:46:58 rho Exp $';

1;

__END__



x=cut

# everything else is routed to the underlying map
# did I mention that OO programming sucks big time?

use vars qw($AUTOLOAD);
sub xxxxAUTOLOAD {
    my($method) = $AUTOLOAD =~ m/([^:]+)$/;
    my $self = shift;

#warn "AUTOLOAD forwarding '$method' to map object";
    no strict 'refs';

    return if $method eq 'DESTROY';
    my $map = $self->{mounttab}->{'/'} or die "mount something to / first";
    return $map->$method (@_);
#
#    *$AUTOLOAD = sub { $self->{map}->$method(@_) };
#    goto &$AUTOLOAD;
}

x=pod




x=item B<sync_in>

I<$ms>->sync_in (I<$path>)

A whole subtree of the repository can be I<sync'ed in>, i.e. synchronized with contents in an
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
   
x=cut

sub xxsync_in {
    my $self = shift;
    my $path = shift;

    my $map = $self->{mounttab}->{$path} or
                        $TM::log->logdie (scalar __PACKAGE__ .": mount point '$path' does not exist");
    _do_sync_recursive ($self, $path, $map);

sub _do_sync_recursive {
    my $ms     = shift;
    my $path   = shift;
    my $parent = shift;

    $parent->sync_in;

    foreach my $m ( $parent->instances ($parent->mids (\ TM::PSI->TOPICMAP)) ) {
        (my $id = $m) =~ s|.+/(.+)|$1|;                                                  # throw away the baseuri stuff
#warn "id $id";
	my $mid = $parent->midlet ($m);                                                  # get the topic itself
#warn Dumper $mid;
	my ($url)            = @{$mid->[TM->INDICATORS]}                        or next; # if there is no subject indicator, we could not load it anyway
	my ($baseuri)        =   $mid->[TM->ADDRESS]                            or next; # if there is no subject address, we could not load it anyway
	my ($implementation) = map { $_->[ TM->PLAYERS ]->[1]->[0] }
                                  $parent->match (TM->FORALL, type    => $parent->mids ('implementation'),
						              iplayer => $m )
                                                                                or next;
	my $child;
#warn "implementation $implementation";
	eval {
	    $child = $implementation->new (url => $url, baseuri => $baseuri );
	}; $TM::log->logdie (scalar __PACKAGE__ .": cannot instantiate '$implementation' (maybe 'use' it?) for URL '$url' ($@)") if $@;

	$ms->mount ($path . "$id/" => $child)                                            # finally mount this thing into the current
	    unless $ms->is_mounted ($path . "$id/");                                     # unless there is already something there
#warn "-------mounted $path  $id/";
	_do_sync_recursive ($ms, $path . "$id/", $child);                                # go down recursively
    }
}
}

x=pod

x=item B<sync_out>

I<$ms>->sync_out (I<$path>)

@@@ TBW @@@

x=cut

sub sync_out {
    die "not implemented yet";
}

x=pod












}

