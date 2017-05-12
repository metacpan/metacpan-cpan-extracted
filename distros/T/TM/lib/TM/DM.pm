package TM::DM::TopicMap;

use TM;
use Data::Dumper;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub id {
    my $self  = shift;
    my $map   = $self->{tmdm}->{map};
    return $map->baseuri;
}

sub topics {
    my $self  = shift;
    my $map   = $self->{tmdm}->{map};

    return map { 
	         TM::DM::Topic->new (
				     tmdm  => $self->{tmdm},
				     sad   =>      $_->[TM->ADDRESS],
				     sids  => [ @{ $_->[TM->INDICATORS] } ],
				     mid   => $_->[TM->LID]
				     )
		 } $map->toplets (@_);
}

sub associations {
    my $self = shift;
    my $map  = $self->{tmdm}->{map};
    my %search = @_;
    foreach my $k (keys %search) {
	$search{$k} = $map->tids ($search{$k}) if $k =~ /role|type|player/;
    }

    return map { TM::DM::Association->new (lid  => $_->[TM->LID],
					   tmdm => $self->{tmdm}) }
           grep ($_->[TM->KIND] == TM->ASSOC,
                 $map->match (TM->FORALL, %search)
		 );
}

sub reifier {
    my $self  = shift;
    my $map   = $self->{tmdm}->{map};

    my ($mid) = $map->is_reified ($map->baseuri)             # find a topic which has as subject address the baseuri
	or return undef;
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $mid);
}

sub topic {
    my $self = shift;
    my $id   = shift;
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $self->{tmdm}->{map}->tids ($id));
}

1;

package TM::DM::Topic;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub _mk_topic {
    my $tmdm   = shift,
    my $mid    = shift;
    my $map    = $tmdm->{map};
    my $midlet = $map->midlet ($mid);

    return TM::DM::Topic->new (tmdm => $tmdm,
                               mid  => $mid,
                               sad  =>     $midlet->[TM->ADDRESS],
                               sids => [ @{$midlet->[TM->INDICATORS]} ]);
}

sub subjectLocators {
    my $self = shift;
    return ($self->{sad});
}

sub subjectIdentifiers {
    my $self = shift;
    return @{ $self->{sids} };
}

sub id {
    my $self = shift;
    return $self->{mid};
}

sub parent {
    my $self = shift;
    return TM::DM::TopicMap->new (tmdm => $self->{tmdm});
}

sub names {
    my $self = shift;
    my $map  = $self->{tmdm}->{map};

    return
	map { TM::DM::Name->new (
                                 tmdm  => $self->{tmdm},
				 lid   => $_->[TM->LID],
				 ) }
             grep ($_->[TM->KIND] == TM->NAME,
                   $map->match (TM->FORALL, char    => 1,
                                            topic   => $self->{mid} ));
}

sub occurrences {
    my $self = shift;
    my $map  = $self->{tmdm}->{map};

    return
	map { TM::DM::Occurrence->new (
                                       tmdm  => $self->{tmdm},
				       lid   => $_->[TM->LID],
				       ) }
             grep ($_->[TM->KIND] == TM->OCC,
                 $map->match (TM->FORALL, char    => 1,
                                          topic   => $self->{mid} ));

}

sub roles {
    my $self = shift;
    my $map  = $self->{tmdm}->{map};
    my $mid  = $self->{mid};

    my @rs;
    foreach my $a (   grep ($_->[TM->KIND] == TM->ASSOC,
			    $map->match (TM->FORALL, iplayer => $self->{mid} ))) {
	push @rs, map {
	               TM::DM::Role->new (
					  tmdm   => $self->{tmdm},
					  lid    => $a->[TM->LID],
					  player => $mid,
					  type   => $_
					  )
		       } $map->get_roles ($a, $mid);
    }
    return @rs;
}

1;

package TM::DM::Association;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub id {
    my $self   = shift;
    return $self->{lid};
}

sub type {
    my $self   = shift;
    my $map    = $self->{tmdm}->{map};
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $map->retrieve ($self->{lid})->[TM->TYPE]);
}

sub scope {
    my $self   = shift;
    my $map    = $self->{tmdm}->{map};
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $map->retrieve ($self->{lid})->[TM->SCOPE]);
}

sub roles {
    my $self = shift;
    my $map  = $self->{tmdm}->{map};
    my $a    = $map->retrieve ($self->{lid});

    my ($ps, $rs) = ($a->[TM->PLAYERS], $a->[TM->ROLES]);

    return map { TM::DM::Role->new (                         # make a role from it
				    tmdm   => $self->{tmdm},
				    lid    => $a->[TM->LID],
				    player => $_->[1],
				    type   => $_->[0]
				    ) }
           map { [ $rs->[$_], $ps->[$_] ] }                  # get the role and the player, $_ is index
           (0 .. $#$ps)                                      # get all indices for all roles
	       ;
}

sub parent {
    my $self = shift;
    return TM::DM::TopicMap->new (tmdm => $self->{tmdm});
}

sub reifier {
    my $self  = shift;
    my $map   = $self->{tmdm}->{map};
    my $a    = $map->retrieve ($self->{lid});

    my ($mid) = $map->is_reified ($a)
	or return undef;
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $mid);
}

1;

package TM::DM::Occurrence;

#### datatype INSIDE the value


sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub id {
    my $self   = shift;
    return $self->{lid};
}

# non-TMDM: bring back value + data type

sub value {
    my $self = shift;
    my $map  = $self->{tmdm}->{map};
    my $a    = $map->retrieve ($self->{lid});
    return ref ($a->[TM->PLAYERS]->[0]) ? # it can only be one of them
	        $a->[TM->PLAYERS]->[0] :
		$a->[TM->PLAYERS]->[1];   # we keep the datatype
}

sub type {
    my $self = shift;
    my $map  = $self->{tmdm}->{map};
    my $a    = $map->retrieve ($self->{lid});
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $a->[TM->TYPE]);
}

# only one scope!!!

sub scope {
    my $self   = shift;
    my $map  = $self->{tmdm}->{map};
    my $a    = $map->retrieve ($self->{lid});
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $a->[TM->SCOPE]);
}

sub reifier {
    my $self  = shift;
    my $map   = $self->{tmdm}->{map};
    my $a     = $map->retrieve ($self->{lid});

    my ($mid) = $map->is_reified ($a)
	or return undef;
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $mid);
}

sub parent {
    my $self = shift;
    my $map  = $self->{tmdm}->{map};
    my $a    = $map->retrieve ($self->{lid});
    my $mid  = ref ($a->[TM->PLAYERS]->[0]) ? 
	            $a->[TM->PLAYERS]->[1]  :
		    $a->[TM->PLAYERS]->[0];
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $mid);
}

1;

package TM::DM::Name;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub id {
    my $self   = shift;
    return $self->{lid};
}

sub value {
    my $self = shift;
    my $map  = $self->{tmdm}->{map};
    my $a    = $map->retrieve ($self->{lid});
    my $v    = ref ($a->[TM->PLAYERS]->[0]) ? # it can only be one of them
	            $a->[TM->PLAYERS]->[0] :
		    $a->[TM->PLAYERS]->[1];
    return $v->[0]; # the data type is always a string, boring
}

sub type {
    my $self = shift;
    my $map  = $self->{tmdm}->{map};
    my $a    = $map->retrieve ($self->{lid});
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $a->[TM->TYPE]);
}

sub scope {
    my $self   = shift;
    my $map  = $self->{tmdm}->{map};
    my $a    = $map->retrieve ($self->{lid});
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $a->[TM->SCOPE]);
}

sub reifier {
    my $self  = shift;
    my $map   = $self->{tmdm}->{map};
    my $a     = $map->retrieve ($self->{lid});
    my ($mid) = $map->is_reified ($a)
	or return undef;
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $mid);
}

sub parent {
    my $self = shift;
    my $map  = $self->{tmdm}->{map};
    my $a    = $map->retrieve ($self->{lid});
    my $mid  = ref ($a->[TM->PLAYERS]->[0]) ? 
	            $a->[TM->PLAYERS]->[1]  :
		    $a->[TM->PLAYERS]->[0];
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $mid);
}

1;

package TM::DM::Role;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}



sub player {
    my $self = shift;
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $self->{player});
}

sub type {
    my $self = shift;
    return TM::DM::Topic::_mk_topic ($self->{tmdm}, $self->{type});
}

sub parent {
    my $self = shift;
    return TM::DM::Association->new (tmdm => $self->{tmdm}, lid => $self->{lid});
}

1;

package TM::DM;

require Exporter;
use base qw(Exporter);

use Data::Dumper;

=pod

=head1 NAME

TM::DM - Topic Maps, read-only TMDM layer

=head1 SYNOPSIS

   # somehow acquire a map (see TM and its subclasses)
   my $tm = ....

   # put a TMDM layer on top of it
   use TM::DM;
   my $tmdm = new TM::DM (map => $tm);

   # get the TMDM topic map item
   my $topicmap = $tmdm->topicmap;

   # ask for all topics
   my @topics = $topicmap->topics;
   # for all associations
   my @assocs = $topicmap->associations;

   # get a particular topic
   my $adam = $topicmap->topic ('adam');

   # get some of its properties
   $adam->id;
   $adam->subjectLocators;
   $adam->subjectIdentifiers;
   $adam->parent;
   my @ns = $adam->names;
   my @os = $adam->occurrences;

   # similar for assocs
   my @as = $topicmap->associations (iplayer => 'adam');
   $as[0]->type;
   $as[0]->parent;
   my @rs = $as[0]->roles;

=head1 ABSTRACT

This package provides a TMDM-ish (read-only) view on an existing topic map.

=head1 DESCRIPTION

TMDM, the Topic Maps Data Model

   http://www.isotopicmaps.org/sam/sam-model/

is the ISO standard for the I<high-level> model for Topic Maps. 


=head2 TMDM Concepts

TMDM's main concepts are the

=over

=item I<topic map item>

containing any number of topic and association items

=item I<topic item>

containing any number of names, occurrence items, subject
locators and subject identifiers

=item I<association item>

containing a type, a scope and any number of role items

=item I<name item>

containing a string, a type and a scope

=item I<occurrence item>

containing a data value (together with its data type), a type
and a scope

=item I<role item>

containing a type and a player

=back

All items have an I<item id> and all (except the map) have a parent
which links back to where the item belongs.

This package implements for each of the above a class and access methods to retrieve actual
structure and values from an existing map. Nota bene, there are some deviations from TMDM:

=over

=item

only ONE identifier per item is supported

=item

at most ONE subject locator per topic is supported

=item

no variants are supported (might be added at some stage, poke me)

=item

a scope consists only of a single topic

=item

role items do not have an identity, so they also cannot be reified

=back

=head2 Modus Operandi

Before you can use the TMDM layer, you need TM information in the form of a L<TM> object. Any
subclass should do, materialized and non-materialized maps should both be fine. Only with such
a map you can instantiate a TMDM layer:

  use TM::Materialized::AsTMa;
  my $tm = new TM::Materialized::AsTMa (file => 'test.atm');

  use TM::DM;
  my $tmdm = new TM::DM (map => $tm);

Probably the first thing you need to do is to get a handle on the whole topic map:

  my $topicmap = $tmdm->topicmap;

That is delivered as an instance of TM::DM::TopicMap as described below. From there you start to
extract topics and associations and that way you then further drill down.

=head2 Implementation Notes

This implementation only supports B<reading> map information, not changing it or modifying the
structure of the map. Not that it is impossible to do, but many applications get their map content
from elsewhere and a read/write interface is an overkill in these cases.

All objects generated here are B<ephemeral>, i.e. they are only instantiated because you wanted the
map information embedded into them. This implies that if you ask for one and the same topic twice,
you are getting two copies of the topic information. The following will not work as expected:

   my $t0 = $topicmap->topic ('adam');
   my $t1 = $topicmap->topic ('adam');

   warn "have the same topic!" if $t0 == $t1;

This will work:

   warn "have the same topic!" if $t0->id eq $t1->id;

=head1 INTERFACES

=head2 TM::DM

The TM::DM class itself does not offer much functionality itself. It only keeps the connection to the
background map.

=head3 Constructor

The constructor expects exactly one parameter, namely the background map.

I<$tmdm> = new TM::DM (map => I<$tm>)

=cut

sub new {
    my $class   = shift;
    my %options = @_;
    $TM::log->logdie (scalar __PACKAGE__ .": map parameter is not really a TM instance")     unless ref ($options{map}) && $options{map}->isa ('TM');
    
    return bless { %options }, $class;
}

=pod

=head3 Methods

=over

=item B<topicmap>

I<$topicmap> = I<$tmdm>->topicmap

This method generates a Topic Map item. See L<TM::DM::TopicMap|/TM::DM::TopicMap> .

=cut

sub topicmap {
    my $self = shift;
    return new TM::DM::TopicMap (tmdm => $self);
}


=pod

=back

=head2 TM::DM::TopicMap

This class provides access to all TMDM properties:

=over

=item B<id>

This returns the item identifier.

=item B<topics>

I<@topics> = I<$topicmap>->topics (I<@list-of-ids>)

I<@topics> = I<$topicmap>->topics

I<@topics> = I<$topicmap>->topics (I<$selection-spec>)

This method expects a list containing topic valid identifiers and returns for each of the topics a
C<TM::DM::Topic> reference. If any of the input identifiers do not denote a valid topic in the map,
undef will be returned in its place. If the parameter list is empty, B<all> topics will be
returned. Have fun, I mean, use with care.

Examples:

    # round tripping topic ids
    print map { $_->id } $topicmap->topics ('abel', 'cain' );

    print "he again" if $topicmap->topics ('god');

If a selection is specified then the same language as in L<TM> (method C<toplets>) can be used.

=item B<associations>

I<@as> = I<$topicmap>->associations

I<@as> = I<$topicmap>->associations (I<%search_spec>);

This method retrieves the list of ALL associations when it is invoked without a search
specification. See L<TM> for that.

=item B<reifier>

This returns the topic item which reifies the association. C<undef> is returned if there is none.

=item B<topic>

This returns a topic item with that id. This method will die if the id is invalid. Note that
always new copies are made.

=back

=head2 TM::DM::Topic

=over

=item B<subjectLocators>

Returns the (only) subject locator (URI string) in the topic item or C<undef> if there is none.

=item B<subjectIdentifiers>

Returns a list of URI strings. Might be empty.

=item B<id>

Returns the item id.

=item B<parent>

Returns a TM::DM::TopicMap item in which this topic is embedded.

=item B<names>

I<@names> = I<$topic>->names

Returns a list of TMDM name items.

=item B<occurrences>

I<@occurrences> = I<$topic>->occurrences

Returns a list of TMDM occurrences items.

=item B<roles>

I<@roles> = I<$topic>->roles

Returns a list of TM::DM::Role items where this topic plays any role.

=back

=head2 TM::DM::Association

=over

=item B<id>

Returns the item id.

=item B<type>

Returns a TM::DM::Topic item which is the type of the association.
This is always defined.

=item B<scope>

Returns the scope of the association in the form of a single TM::DM::Topic item. This is always
defined as for the I<unconstrained scope> the topic C<us> is used (see L<TM::PSI>).

=item B<roles>

I<@roles> = I<$assoc>->roles

Returns a list of roles of the association. Each role is a TM::DM::Role item.

=item B<parent>

Returns a TM::DM::TopicMap item for the embedding map.

=item B<reifier>

Returns a TM::DM::Topic item if this association is reified. C<undef> otherwise.

=back

=head2 TM::DM::Occurrence

=over

=item B<id>

Returns the item id.

=item B<value>

Returns the value (together with the data type) in the form of a L<TM::Literal>
object.

=item B<type>

Returns a TM::DM::Topic item which is the type of the occurrence.  This is always defined.

=item B<scope>

Returns the scope of the occurrence in the form of a single TM::DM::Topic
item. This is always defined.

=item B<reifier>

Returns a TM::DM::Topic item if this occurrence is reified. C<undef> otherwise.

=item B<parent>

Returns the TM::DM::Topic item of the topic where this occurrence is part of.

=back

=head2 TM::DM::Name

=over

=item B<id>

Returns the item id.

=item B<value>

Returns the string value of the name.

=item B<type>

Returns a TM::DM::Topic item which is the type of the name.
This is always defined.

=item B<scope>

Returns the scope of the name in the form of a single TM::DM::Topic
item. This is always defined.

=item B<reifier>

Returns a TM::DM::Topic item if this name is reified. C<undef> otherwise.

=item B<parent>

Returns the TM::DM::Topic item of the topic where this name is part of.

=back

=head2 TM::DM::Role

=over

=item B<player>

Returns a TM::DM::Topic item for the topic which is the player in this role.

=item B<type>

Returns a TM::DM::Topic item for the topic which is the type of this role.

=item B<parent>

Returns a TM::DM::Association item of the association where this role is in.

=back

=head1 SEE ALSO

L<TM>, L<TM::Easy>

=head1 COPYRIGHT AND LICENSE

Copyright 200[68] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION  = '0.04';
our $REVISION = '$Id$';

1;

__END__

