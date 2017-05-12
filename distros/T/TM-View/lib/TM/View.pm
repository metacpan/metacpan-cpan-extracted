package TM::View;
# $Id: View.pm,v 1.9 2009-11-27 01:32:55 az Exp $ 

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = qw(('$Revision: 1.9 $'))[1];

require Exporter;
require AutoLoader;

use TM 1.43;
use TM::Literal;
use base qw(TM);
use Data::Dumper;
use XML::Writer;
use IO::String;
use UNIVERSAL qw(isa);

=pod

=head1 NAME

TM::View - Topic Maps, Views and Listlets

=head1 SYNOPSIS

 use TM;
 use TM::View;

 my $map;
 # map is created/synced somehow

 # do not change the map afterwards or pass the constructor
 # a deep copy (e.g. using dclone from Storable).
 my $view=TM::View->new($map);	

 $view->sequence_add("tm://sometopic");  # added with default style info
 $view->sequence_add("tm://othertopic",0); # add at the beginning
 my $length=$view->sequence_length;
 my $whogoesthere=$view->who(0);	# which topic is shown first?

 # retrieve the style describing the topic's midlet by location
 my ($who,%style)=$view->style(1,0); 
 ($who,%style)=$view->style("tm://sometopic",0); # or by topic
 $style{bullet}=1;		#  modify it
 $style{emphasize}=0;
 $style{custom_attrib}="what you want!";
 $view->style("tm://sometopic",0,%style); # and write it back

 my $xml=$view->make_listlet;

=head1 DESCRIPTION

This package provides sequencing and styling mechanisms for Topic Map slide shows or other
serialized presentations.

=head1 CONCEPTS

A view consists of an extract of a map together with
rendering information which presents a linear sequence of topics and their 
interesting aspects. The main use of views is for using topicmaps as source
for slides or similar linear presentation mechanisms. 

A view contains information about which topics are shown in what sequence, and what
of the available information related to a topic is presented and how. 
TM::View manages this information in data structures called I<styles>.

Every topic in a map can have sundry attributes associated with it, e.g. basenames,
occurrences and class/instance information. None of these have any implicit ordering.
From a view perspective, these 
attributes belong to the topic and their display is controlled by the topic's
style. A topic can also be involved in associations as member, role being played or 
type of the association. Associations are thus not directly associated with a single
topic but instead are deemed to be interesting for every involved topic. 
A view thus includes information about a particular association multiple times
in each involved topic's style.

In TM::View a style element consists of two components: an identifier of the topicmap object 
being controlled, and a reference to a hash of attribute/value pairs. The attributes
describe the formatting of the object but do not include the object content. 
Besides certain attributes with predefined meanings (see topic_as_listlet below), there are no
restrictions on the attributes.

TM::View uses the data structures and identification concepts described in L<TM(3)>, which separate 
the world into Midlets (without assertions) and Assertions (with midlets).
(Everything in a map is a midlet. "Real" topics are only present as midlets, whereas
implicit topics have a midlet and an assertion with the same identifier.)
Midlets contain only topic id and reification information,
whereas assertions carry everything else: topic attributes and associations.

A single style element controls the display of a single assertion. In practice that means
that a basename has its style element, separate from an occurrence even if they both belong
to the same topic.

The style elements for all displayable aspects of a single topic are collected in a list: 
this is called the I<styles of a topic>. Position in this list controls display position,
and this style list contains all information to create a slide or page about this topic.
Note that the style of a topic is always I<complete> and contains I<all> the topic's aspects: 
Aspects that should not be displayed are flagged thus by a specific 
attribute (see topic_as_listlet).

Any midlet in a map can have such a style list (but of course not all midlets are worth displaying: 
for example, a topic that was implicitely defined by specifying a scope for some other attribute
hardly contains interesting information).

Multiple topic styles describe a linear journey through the map, and this is represented in 
TM::View as the I<sequence>. A view contains exactly one sequence, which lists the topics that 
are to be displayed (and their order). The sequence usually is only a subset of all available
topics (or more precisely midlets).

=head1 RELATIONSHIP BETWEEN MAP AND VIEW

A TM::View object embeds a topicmap upon its creation, after which this map object must not be 
modified anymore. (To be precise, adding elements to the map might be mostly safe, but 
modification or removal of existing map content is definitely unsafe.)
It is suggested that the programmer use dclone (see L<Storable(3)>) or something similar to create 
a deep copy of the map object for the constructor, if modification of the map object is expected 
at a later stage.

As maps change over time, one-shot discardable views would be of little use for serious 
knowledge management: specifying a display sequence and extracting the appropriate information from
a map is time-consuming. One would have to recreate the display sequence with a new view that applies to
the new map, and manually copy over all transferrable attributes. Obviously this is tedious and
inefficient, and TM::View provides automation for as much of this process as possible.

A TM::View object can be "applied" to a modified version of the respective map using
the method I<reconcile>. 

I<reconcile> resolves the differences between the old (embedded) and updated map and
migrates the view information into the context of the updated map. This is done minimizing the loss 
of style information:
the styles for unmodified elements are copied over, styles applying to removed elements are removed 
and new elements are added where appropriate
(e.g. a new occurrence is added to the styles of the topic it applies to, with default display attributes).
Modified (and renamed) topics and associations are identified and their styles are transported over, 
but style information for modified assertions is lost (the assertion will show up as new). 
Topics and assertions affected by these changes are flagged and upon completion, the map embedded 
in the old view is discarded and the new map is snapshotted in. 

=head1 INTERFACE

The methods provided by TM::View fall into three categories: managing the overall sequence of topics, 
managing the styles (of assertions) of a particular topic and creating output.

The methods commonly use two different identifiers: a I<topic identifier> and 
an I<assertion identifier>, both of which are I<internal identifiers> as described in L<TM(3)>.
The I<tid> applies to the sequence, whereas the I<aid> 
applies to the aspects related to a particular topic. The sequence-related methods obviously 
do not require aid parameters.

Most methods allow to specify topics by either I<tid> or position in the sequence.
Similar mechanisms apply to selecting assertions by their I<aid> or by position in the sequence 
of styles.

=head2 Constructor

 $view=TM::View->new($tmobj);

The constructor requires a TM map object as sole argument, which is the map the view 
applies to. The map object is attached to the view and must not be modified afterwards.
It is highly suggested to use dclone (see L<Storable(3)>) or similar to create a deep copy 
of the map for the view:

 $safeview=TM::View->new(dclone($tmobj));

=cut

# makes a new blank view
# arguments: a TM map
sub new 
{
    my ($class,$map,%opts)=@_;
    die "map MUST be provided\n" if (!$map);
    
    my $self=
    {
	tm=>$map,
	sequence=>[],
    };
    return bless $self, $class;   # reblessing
}

=pod

=head2 Methods

=over

=item B<map:>

 $tmobj=$view->map;

This method returns the map object associated with the view. The map object can be used
for retrieval purposes but must not be modified.

=cut

sub map 
{
    my ($self)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);

    return $self->{tm};
}

# want basenames first, occurrences next, then assocs but assoc kind is zero.
# occurrences and assocs sorted by their types
sub _sort_elems
{
    my $ak=($a->[TM->KIND]||3).$a->[TM->TYPE]; 
    my $bk=($b->[TM->KIND]||3).$b->[TM->TYPE]; 
    return $ak cmp $bk;
}

=pod

=item B<sequence_add:>

$length=$view->sequence_add(I<tid> [,I<position>]);

This method adds the topic I<tid> to the view. If no position argument
is given (or if it is invalid), the topic is added at the end of the sequence. 
The position argument is a number, with zero being the start of the sequence.
The sequence can not have holes. 

The style information for the topic is a built-in default, which can be modified
using the B<style> method.

The new length of the sequence is returned on success, or undef if the
topic is already sequenced or non-existent.

=cut

# adds a topic at index
# parameters: topic (midlet) id, position (end if not present)
# returns new length of the sequence, undef if topic already present
sub sequence_add 
{
    my ($self,$tid,$location)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);
    my $lastindex=$#{$self->{sequence}};

    return undef if (grep($_->[0]->[0] eq $tid,@{$self->{sequence}}));
    return undef if (!$self->{tm}->midlet($tid));

    my $compat=(exists($self->{tm}->{usual_suspects})?$self->{tm}->{baseuri}:"");   

    # find the right spot to put things and make space
    if (!defined($location) || $location<0 || $location>$lastindex)
    {
	$location=$lastindex+1;
    }
    else
    {
	my @newa;
	@newa=(@{$self->{sequence}}[0..$location-1],undef,
	       @{$self->{sequence}}[$location..$lastindex]);
	$self->{sequence}=\@newa if ($location<=$lastindex);
    }

    # now collect the displayed elements for this topic
    # and create the default order
    # first the topic itself; then all the other stuff
    my @how=([$tid,$self->_default_style($tid,$tid)]);

    # anyid is too extensive: returns occs,bns,ins of scope=this or of type=this, too!
    # but those are not interesting for this topic...
    my @allelem=$self->{tm}->match(TM->FORALL,anyid=>$tid);
    my @interesting=grep { $_->[TM->KIND]==TM->ASSOC # assocs are fine
			       || $self->{tm}->is_x_player($_,$tid,$compat."thing") # as are names/occs where we are directly involved
			   } (@allelem);
    map { push @how,[$_->[TM->LID],
		     $self->_default_style($tid,$_->[TM->LID])] } (sort { _sort_elems() } @interesting);
    $self->{sequence}->[$location]=\@how;
    return $lastindex+2;
}

=pod

=item B<sequence_remove:>

$length=$view->sequence_remove(I<tid or index>);

 $length=$view->sequence_remove("tm://sometopic");
 $length=$view->sequence_remove(12);

This method removes a topic from the sequence. The topic can be identified either
by its topic id or by its position in the sequence. 

The method returns the new length of the sequence or undef on an unsequenced or 
nonexistent topic.

=cut

# removes topic with id or whatever at some index
# returns new length of sequence or undef if bad index/no such topic
sub sequence_remove
{
    my ($self,$tidorindex)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);
    
    my $loc=$self->_find_tidindex($tidorindex,$self->{sequence});
    return undef if (!defined $loc);
    
    splice(@{$self->{sequence}},$loc,1);
    return scalar @{$self->{sequence}};
}

=pod

=item B<sequence_length:>

 $howmany=$view->sequence_length;

The method returns the number of currently sequenced topics.

=cut

# how many topics in the sequence?
sub sequence_length
{
    my ($self)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);
    return scalar @{$self->{sequence}};
}

=pod

=item B<clear:>

 $view->clear;

This method clears the list of sequenced topics and returns nothing.

=cut

# nuke the sequence, effectively clearing the whole profile
sub clear
{
    my ($self)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);
    $self->{sequence}=[];
}

=pod

=item B<sequence_move:>

$newpos=$view->sequence_move(I<tid or index>,I<delta>);

 $newpos=$view->sequence_move(10,-1); # up one
 $newpos=$view->sequence_move('tm://sometopic',2); # down two slots

This method moves a sequenced topic to a different slot in the sequence. The topic 
can be identified by its id or its position. The movement is controlled by the 
I<delta> argument which indicates how many slots the topic is to move.

The method returns the effective new position or undef on bad arguments.

=cut

# lookup topic x (or index) and move it by delta slots, 
# shifting the sequence around as necessary. 
# returns the effective new position  of the moved element or undef on bad args
sub sequence_move
{
    my ($self,$tidorindex,$delta)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);
    my $oldindex=$self->_find_tidindex($tidorindex,$self->{sequence});
    return undef if (!defined $oldindex);

    my $newseq=_move($oldindex,$delta,@{$self->{sequence}});
    return undef if (!defined $newseq);
    $self->{sequence}=$newseq;
    return $oldindex+$delta;
}

=pod

=item B<where:>

($topicindex,$aidindex)=$view->where(I<tid or index> [,I<aid or index>]);

 print "happy!" if ($view->where("tm://joy")); # is sequenced
 ($shakespeare,$bnidx)=$view->where("tm://frailty","tm://woman");

This method looks up a topic (or one of its attached assertions) in the sequence and
returns the position in the sequence (and within this topic's information) or undef
if no match was identified.

If no aid argument is given, the topic is looked up and aidindex=0 is returned. 
With an aid, first the topic is looked up and then the given aid is looked up in
the style list for this topic. If either lookup fails, undef is returned.

=cut

# lookup where a topic is sequenced
# returns index,mindex or undef
sub where
{
    my ($self,$tidorindex,$midorindex)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);
    my $index=$self->_find_tidindex($tidorindex,$self->{sequence});
    return undef if (!defined $index);
    my $mindex=0;
    if (defined $midorindex)
    {
	$mindex=$self->_find_tidindex($midorindex,$self->{sequence}->[$index]);
	return undef if (!defined $mindex);
    }
    return ($index,$mindex);
}

=pod

=item B<who:>

$tid=$view->who(I<topic index> [,I<assertion index>]);

This method performs the inverse of who: given an index into the sequence,
it returns the I<tid> of the topic in that slot.
With the optional assertion index, the I<aid> of the assertion in that place 
(within the styles of the topic) is returned. 

If either index is invalid, undef is returned.

=cut

# lookup who is at sequence loc and optionally style location
# if midorindex given: returns assertion id, otherwise returns the topic id, 
# returns undef if garbled args
sub who
{
    my ($self,$tidorindex,$midorindex)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);
    my $index=$self->_find_tidindex($tidorindex,$self->{sequence});
    return undef if (!defined $index);
    $midorindex||=0;		# the topic itself
    my $mindex=$self->_find_tidindex($midorindex,$self->{sequence}->[$index]);
    return undef if (!defined $mindex);
    return $self->{sequence}->[$index]->[$mindex]->[0];	# the id
}


=pod

=item B<style_length>

$nr_aspects=$view->style_length(I<tid or index>);

Returns the number of assertions that the style of this topic contains.
The topic is identified by its tid or index in the sequence, and if the
argument is invalid, undef is returned.

=cut

# returns the number of style elements for this topic
# undef if bad index/tid
sub style_length
{
    my ($self,$tidorindex)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);
    my $index=$self->_find_tidindex($tidorindex,$self->{sequence});
    return undef if (!defined $index);

    return scalar @{$self->{sequence}->[$index]};
}

=pod

=item B<style:>

($id,%stylehash)=$view->style(I<tid or index>,I<aid or index> [,%newstyle]);

This method gets (and optionally sets) a style. The sequence is searched for 
a topic matching the first argument, and within the list of styles for this topic,
the requested assertion is looked up. If either lookup fails, undef is returned.

On success, the aid of the found assertion and a copy of the display attributes hash 
is returned. If the optional newstyle argument is given, then the display attributes
hash is replaced with a copy of newstyle. Note that when setting newstyle the I<previous>
display attributes are returned.

The contents of the stylehash are unrestricted, but certain attributes have specific 
meanings for TM::View's output methods which are discussed below, with topic_as_listlet.

The style at index 0 is a dummy style which contains no display attributes (except the _is_changed
flag) and only identifies the topic in question. The dummy style cannot be modified.

=cut


# returns the node id and style hash that was identified, and sets a new style if given
# both topic and element id can be given as indices or full base-prefixed identifiers
# if a new style is given, then it is set but the the old one is returned.
# returns undef if tid/mid not found
# style() returns ($id,%style), with the data being a full copy of the style
sub style
{
    my ($self,$tidorindex,$midorindex,%newstyle)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);
    my $index=$self->_find_tidindex($tidorindex,$self->{sequence});
    return undef if (!defined $index);
    my $mindex=$self->_find_tidindex($midorindex,$self->{sequence}->[$index]);
    return undef if (!defined $mindex);

    my @oldinfo=($self->{sequence}->[$index]->[$mindex]->[0],
		 %{$self->{sequence}->[$index]->[$mindex]->[1]});
    $self->{sequence}->[$index]->[$mindex]->[1]={%newstyle}
	if (%newstyle && $mindex>0);
    return @oldinfo;
}

=pod

=item B<style_move:>

$newpos=$view->style_move(I<tid or index>,I<aid or index>,I<delta>);

Identifies the style for the given assertion in the context of the given topic 
and moves it by delta slots.  The dummy style at index 0 cannot be moved, nor
can any other assertion be moved into slot 0.

On success, the new position is returned. If either topic or assertion lookup fails,
or if the delta argument results in an invalid position, undef is returned.

=cut

# moves a style entry by +/-delta in the list of styles
# returns new position or undef if args broken
sub style_move
{
    my ($self,$tidorindex,$midorindex,$delta)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);

    my $index=$self->_find_tidindex($tidorindex,$self->{sequence});
    return undef if (!defined $index);

    my $mindex=$self->_find_tidindex($midorindex,$self->{sequence}->[$index]);
    return undef if (!defined $mindex);
    
    # the first style elem (the topic midlet itself) can't be moved around!
    return undef if ($mindex==0 || $mindex+$delta==0);

    my $newstyleseq=_move($mindex,$delta,@{$self->{sequence}->[$index]});
    return undef if (!defined $newstyleseq);
    $self->{sequence}->[$index]=$newstyleseq;

    return $mindex+$delta;
}
 
# move element in list from oldspot to +/-delta
# returns undef if the args are bad or ref of new list
sub _move
{
    my ($oldindex,$delta,@list)=@_;
    my $lastindex=$#list;
    my $newindex=$oldindex+$delta;
    
    return undef if (!$delta || $newindex<0 || $newindex>$lastindex);

    my ($which)=splice(@list,$oldindex,1);
    my @newseq=(@list[0..$newindex-1],
		$which,@list[$newindex..$lastindex-1]);
    die "_move broken\n" if ($#newseq != $lastindex);
    return \@newseq;
}
    
# find a topic or index in an array of (tid,something)
# needs ref of array, returns index or undef 
sub _find_tidindex
{
    my ($self,$tidorindex,$where)=@_;
    my $index;

    # topic or index? SOME tids start with baseuri, but all indices are numeric
    if ($tidorindex!~/^[0-9]+$/)
    {
	# tid
	for (0..$#{$where})
	{
	    # are we searching in the sequence or the style list of a sequenced topic?
	    if ($where==$self->{sequence})
	    {
		# searching in the sequence list, look at the first style node's first elem
		# (which is the tid)
		($index=$_,last) if ($where->[$_]->[0]->[0] eq $tidorindex);
	    }
	    else
	    {
		# otherwise: one level less indirection
		($index=$_,last) if ($where->[$_]->[0] eq $tidorindex);
	    }
	}
    }
    else
    {
	$index=$tidorindex;
    }
    return undef if (!defined $index || $index<0 || $index>$#{$where});
    return $index;
}

# returns a list of [tindex,mindex] pairs where the listed tid was present
sub _find_tid_anywhere
{
    my ($self,$tid)=@_;
    my @where;
    for my $ti (0..$#{$self->{sequence}})
    {
	for my $mi (0..$#{$self->{sequence}->[$ti]})
	{
	    push @where,[$ti,$mi] if ($self->{sequence}->[$ti]->[$mi]->[0] eq $tid);
	}
    }
    return @where;
}

# returns list of *sequenced* topics (their indices) that 
# a given assertion applies to 
# applies to: basename, oc -> type and topic in question; isa -> both topics 
# association -> all role, type and player topics
# uses whichmap to control where to get the assertion info from
# returns a list of sequence indices or an empty list 
sub _find_applicable
{
    my ($self,$map,$aid)=@_;

    my @found=();
    my @lookfor;

    my $ass=$map->retrieve($aid);
    return @found if (!$ass);	# this is just a new midlet, not an assoc; uninteresting

    my $compat=(exists($map->{usual_suspects})?$map->{baseuri}:"");
    my ($lid,$scope,$kind,$type,$players,$roles)=
	@{$ass}[TM->LID,TM->SCOPE,TM->KIND,TM->TYPE,TM->PLAYERS,TM->ROLES];

    if ($kind == TM->NAME || $kind == TM->OCC)
    {
	push @lookfor,$type,$map->get_x_players($ass,$compat."thing");
    }
    else
    {
	# assocs: all players, all roles and the type topic are always involved
	push @lookfor, @{$players},@{$roles},$type;
    }
    my $where;
    map { defined($where=$self->_find_tidindex($_,$self->{sequence})) 
	      && push @found,$where; } (@lookfor);
    return @found;
}

=pod

=item B<reconcile:>

$mapdiff=$view->reconcile(I<map object>);

The reconcile method transfers style information from the current, snapshotted map
over to the (newer) map given as argument. On completion, the new map replaces the 
old map. The new map must not be modified after the reconcile operation, and it is highly
suggested to pass a deep copy (e.g. using dclone from L<Storable(3)>) of the map object.

The method returns the output of TM::diff() for convenience.

Reconcile identifies unchanged or renamed-but-identical topics and migrates their
style settings over. For changed topics or changed aspects of topics, all I<precisely>
identifyable information is migrated: identical occurrence data, associations
whose membership has not changed and so on. 

Where this identification is not possible (because the topic/aspect is gone/was added in the new map),
reconcile will flag the change. Every sequenced topic whose aspects were modified receives the attribute
I<_is_changed> with a true value. This attribute is also set for aspects of a topic that have changed.
This attribute can be cleared using the method clear_changed.

After reconcile has completed, the view is consistent with the argument map.

=cut

# takes a newer version of the map and merges it into the current view/profile,
# while retaining all the applicable style information from the profile.
# changed and new elements get an extra style element _is_changed=>1.
# note that the view is modified!
# returns the actual map diff
sub reconcile
{
    my ($self,$newmap)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);

    # gimme the diff but don't link in the topics: i have both maps a/v
    my $diff=TM::diff($newmap,$self->{tm},
		      {consistency=>[TM->Subject_based_Merging,TM->Indicator_based_Merging],
		       include_changes=>0});
    my $oldmap=$self->{tm};

    # deleted stuff: topics/midlets we nuke if they were sequenced.
    # for assertions we remove all styles where mentioned
    my @cand= map { @$_ } (values %{$diff->{minus}});     # keys are topics, values are array of mids where involved
    map { push @cand,@{$diff->{modified}->{$_}->{minus}} if ($diff->{modified}->{$_}->{minus}) } 
    (keys %{$diff->{modified}});
    for my $goner (@cand)
    {
	for ($self->_find_tid_anywhere($goner))
	{
	    my ($t,$m)=@$_;
	    if ($m==0)		
	    {
		# topic itself sequenced, remove the whole sequenced thing
		$self->sequence_remove($t);
	    }
	    else
	    {
		# remove this style element
		splice(@{$self->{sequence}->[$t]},$m,1);
		# record the change in the toplevel style
		$self->{sequence}->[$t]->[0]->[1]->{_is_changed}=1;
	    }
	}
    }

    # next step is to rename stuff where topics changed names. update the names 
    # everywhere in our view: topic midlet ids themselves, but also association assertions 
    # this must happen before the stage of adding new/updated stuff in,
    # because that requires finding affected players for assocs, and the map diff
    # returns new assocs from the new map (hence using its namespace).
    for my $oldname (keys %{$diff->{identities}})
    {
	my $newname=$diff->{identities}->{$oldname};
	
	for my $t (@{$self->{sequence}})
	{
	    map { $_->[0]=$newname if ($_->[0] eq $oldname) } (@{$t});
	}
    }

    # new stuff: from a view perspective, new topics are uninteresting as 
    # they can't be present in the old view, so there's nothing to do.
    # new associations and assertions must be attached to previously sequenced topics 
    # which are involved (player/role/type/topic with name,occ,scope...)
    @cand=map { @$_ } (values %{$diff->{plus}}); # diff plus key is topic, value is array of mids..which we need
    map { push @cand,@{$diff->{modified}->{$_}->{plus}} if ($diff->{modified}->{$_}->{plus}) } 
    (keys %{$diff->{modified}});

    for my $newbie (@cand)
    {
	my @where=$self->_find_applicable($newmap,$newbie);
	for my $loc (@where)
	{
	    my $style=$self->_default_style($self->{sequence}->[$loc]->[0]->[0], # the id of the context topic
					    $newbie,$newmap); # the new assertion, but info from the new map
	    $style->{_is_changed}=1;

	    push @{$self->{sequence}->[$loc]},[$newbie,$style];
	    # remember the changed state for both the topic as well as the element
	    $self->{sequence}->[$loc]->[0]->[1]->{_is_changed}=1;
	}
    }

    # finally, save the new map with the view
    $self->{tm}=$newmap;
    return $diff;
}

=pod

=item B<clear_changed:>

$view->clear_changed([I<tid or index>]);

This method removes the _is_changed flag wholesale from all topics in the sequence
if no argument is given. Alternatively, it can clear the flag from a specific sequenced
topic only. Returns nothing.

=cut

# removes the _changed flag from one selected topic or all elements of the view
# returns nothing
sub clear_changed
{
    my ($self,$tidorindex)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);
    my $tindex;
    $tindex=$self->_find_tidindex($tidorindex,$self->{sequence}) if (defined $tidorindex);

    for my $t (defined($tindex)?$self->{sequence}->[$tindex]:@{$self->{sequence}})
    {
	for my $s (@{$t})
	{			
	    # s is id+style, second element is the style 
	    delete $s->[1]->{_is_changed};
	}
    }
}

=pod

=item B<topic_as_listlet:>

$xml=$view->topic_as_listlet(I<tid or index>, [I<xml::writer obj>,I<io::string obj>]);

This method produces a Listlet for a particular topic. Without the optional arguments,
the method creates and uses a temporary XML::Writer object for creating the output;
With writer and ios arguments given, these will be used instead.

A Listlet is a very simple XML representation of a topic's slide/page as described by
the topic's style. Basic listlets conform to the following DTD:

    <!ELEMENT listlet (PCDATA? listlet*)>
    <!ATTLIST listlet	title  CDATA #IMPLIED
    			url    URL #IMPLIED>

Every listlet has a header with the slide title, and recursively embedded further listlets for
the topic's displayed aspects. The textual content is either in the title attribute or in the
text data. For listlets dealing with addressable resources, a url attribute can be present as well.

The title attribute of a listlet is chosen using find_nicename (see below) to provide context-sensitive
titles.

However, topic_as_listlet does not limit the user to said (minimal) DTD: any scalar-valued style attribute whose
name does not start with an underscore will be transformed into an XML attribute of the same name in 
the listlet output. (This obviously imposes XML attribute naming restrictions to style attributes.)

Attributes with a leading underscore in their name are considered internal and are not printed at all:
such attributes may be useful if one needs to store hashes or arrays in a style but still uses topic_as_listlet.

Certain style attributes have special meaning for topic_as_listlet and are not printed 
directly as well: 

=over

=item _on:

Controls whether this aspect is shown or not.

=item _type_on:

Controls whether a typed occurrence should be shown with an I<enclosing> listlet 
that displays the occurrence's type. With this option, the AsTMa fragment

 reference
 bn: reference text:

 in(reference): some book

is rendered as

 <listlet title="reference text:">
    <listlet>some book</listlet>
 </listlet>

Without the attribute, only 

 <listlet>some book</listlet>

would be output.

=item _player_order

Controls the display ordering of players for I<this> particular display of an association. This is an array reference, 
the values correspond to the TM-native ordering of players as present in the assertion and the position
describes the intended display position.

_player_order and _player_style are present wherever an association can be shown (= in the styles 
of all involved topics). Each of these displays has separate _player_style and _player_order attributes.
_player_order must be kept consistent (ie. list all players exactly once).

=item _player_styles

This controls the display of individual players within an association. This is an array reference,
with position corresponding to the TM-native ordering of players in the assertion. Each array cell
is a hashref with style attributes applicable to this particular player.

Within these individual player styles, two attributes are special:

=over

=item _on

controls whether this player is shown.

=item _role_on

controls whether the role the player is playing should be shown parenthesized after the player.

=back

For every player a (possibly empty) _player_styles element must always be present.

=back

=cut

# returns the unadorned listlet for a single sequenced topic
# returns undef if no matching topic is found
# if writer and ios are given, they will be used to generate the output
# if not, a new writer is created an an appropriate xml decl is produced.
sub topic_as_listlet
{
    my ($self,$tidorindex,$writer,$ios)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);

    my $index=$self->_find_tidindex($tidorindex,$self->{sequence});
    return undef if (!defined $index);

    my $compat=(exists($self->{tm}->{usual_suspects})?$self->{tm}->{baseuri}:"");

    if (!$ios || !$writer)
    {
	$ios = IO::String->new;
	$writer = new XML::Writer(OUTPUT=>$ios);
	$writer->xmlDecl("iso-8859-1");
    }

    my $t=$self->{sequence}->[$index];
    # first is the midlet, for which we'll use the first active basename as title
    # ...or the topic id without the base
    my $tid=$t->[0]->[0];
    my ($tindex,$title)=$self->find_nicename($tid,$t,undef);
    $writer->startTag("listlet","title"=>$title);

    my $map=$self->{tm};
    
    my ($typed_oc,$typed_ass,$typed_bn)=("","","");
    # rest are bns, ocs, sundry associations
    for my $i (1..$#$t)
    {
	my ($id,$style)=@{$t->[$i]};
	next if (!$style->{_on} || $i==$tindex); # uninteresting or already consumed
	
	# clean styles of the internal _xxx keys
	my @cls = map { ($_,$style->{$_}) } (grep(!/^_/ && defined $style->{$_}, keys %{$style}));
	my $a=$map->retrieve($id);
	my $type=$a->[TM->TYPE];
	
	# deal with typed occurrence combining: if typed_oc is set and this one is 
	# not an occurrence or one with a different type or one where no type info is desired
	# then close the dangling grouping listlet.
	if ($typed_oc && ( $a->[TM->KIND]!=TM->OCC || $type ne $typed_oc || !$style->{_type_on}))
	{
	    $typed_oc="";
	    $writer->endTag("listlet");
	}
	# ditto assoc
	if ($typed_ass && ( $a->[TM->KIND]!=TM->ASSOC || $typed_ass ne join(' ',$type,sort $map->get_roles($a,$tid))))
	{
	    $typed_ass="";
	    $writer->endTag("listlet");
	}
	# ditto basename
	if ($typed_bn && ( $a->[TM->KIND]!=TM->NAME || $type ne $typed_oc || !$style->{_type_on}))
	{
	    $typed_bn="";
	    $writer->endTag("listlet");
	}
	
	# what is this thing? 
	if ($a->[TM->KIND]==TM->NAME)
	{
	    # (extra) basename: type-prefixed listlet entry
	    if ($type ne $compat."name" && !$typed_bn && $style->{_type_on})
	    {
		$writer->startTag("listlet",
				  title=>($self->find_nicename($type,undef,undef))[1],
				  ("bullet"=>1));
		$typed_bn=$type;
	    }
	    $writer->dataElement("listlet","",
				 title=>($map->get_x_players($a,$compat."value"))[0]->[0],@cls);
	}
	elsif ($a->[TM->KIND]==TM->OCC)
	{
	    # occurrence: inline text or hyperlink, with extra type-wrapper if nontrivially typed
	    # and if wanted
	    my $extra;
	    if ($type ne $compat."occurrence" && !$typed_oc && $style->{_type_on})
	    {
		# extra indentation/wrapping using the type's basename
		# which we leave open and dangling...
		$writer->startTag("listlet",
				  title=>($self->find_nicename($type,undef,undef))[1],
				  # style of the wrapper: only bullet 
				  # fixme: i have not real good answer as to what style such 
				  # an extra element should have: none? bulleted? common of children? 
				  # first child? all ugly...
				  ("bullet"=>1));
		# ...because we remember this type for subsequent occs of the same type
		# where we don't make indentation/wrapping listlets
		$typed_oc=$type;
	    }
	    my $value=($map->get_x_players($a,$compat."value"))[0];
	    if ($value->[1] eq TM::Literal->URI)
	    {
		$writer->dataElement('listlet','','url'=>$value->[0],@cls);		    
	    }
	    else
	    {
		$writer->dataElement('listlet',$value->[0],@cls);		    
	    }    
	}
	else
	{
	    # general association: walk the sequenced role/player combos
	    # collate assocs of the same type, IFF our roles are the same
	    # FIXME: good idea for non-isa/instances? dunno
	    
	    # find the name of the role the current topic plays in this assoc
	    # (if any!) and find a name that is scoped with the played role if possible
	    my @roles=$map->get_roles($a,$tid);
	    $writer->startTag("listlet",
			      title=>($self->find_nicename($type,undef,$roles[0]))[1],	# undef fine if not player
			      @cls) if ($typed_ass ne join(' ',$type,sort @roles));
	    $typed_ass=join(' ',$type,sort @roles);
	    
	    # walk through the player-role elements of this assoc
	    for my $pi (@{$style->{_player_order}})
	    {
		my $thisstyle=$style->{_player_styles}->[$pi];
		next if (!$thisstyle || !$thisstyle->{_on}); # disabled p/r combo
		
		my $player=$a->[TM->PLAYERS]->[$pi];
		my $role=$a->[TM->ROLES]->[$pi];
		my @thiscls=map { ($_,$thisstyle->{$_}) } (grep(!/^_/,keys %{$thisstyle}));
		$writer->dataElement("listlet","",
				     title=>(($self->find_nicename($player,undef,undef))[1]
					     .($thisstyle->{_role_on}?
					       (" [".$self->find_nicename($role,undef,undef)."]"):"")),
				     @thiscls);
	    }
	}
    }
    # if a typed occurrence was the last scheduled element, then we need
    # to close the dangling container
    $writer->endTag("listlet") if ($typed_oc || $typed_ass || $typed_bn); 
    $writer->endTag("listlet"); # the "page" listlet
    return ${$ios->string_ref};   
}    


=pod

=item B<make_listlet:>

$xml=$view->make_listlet([I<metadata hash>]);

This method runs topic_as_listlet on all sequenced topics, and optionally adds a
metadata node to the toplevel listlet:

 <!ELEMENT metadata    title author*>
 <!ELEMENT title       PCDATA>
 <!ELEMENT author      PCDATA email? affiliation?>
 <!ELEMENT email       PCDATA>
 <!ELEMENT affiliation PCDATA>
 <!ATTLIST affiliation url URL>

The metadata argument is optional, and the hash keys directly correspond to the attributes 
of the resulting metadata node - with a possible exception for authorship:

If the author value is scalar, then email, affiliation and url are expected to be scalar, too, 
and a single author node is created. If author is an array-ref, then all other attributes (except title)
are expected to be array-refs as well and matching array values will be used to construct multiple author
nodes.

make_listlet returns the listlet xml or undef if the arguments are inconsistent.

=cut

# options: known keys are title, author, email, affiliation, url
# if author is a scalar, then all others are expected to be scalars, too
# if author is ref to array, then so must the others.
# returns undef if the arguments make no sense or the listlet xml

# title and author are empty if not given; affiliation, email and url 
# are not present in this case.
sub make_listlet
{
    my ($self,%opt)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);

    my $listletns = "http://topicmaps.bond.edu.au/listlet/1.1/";

    my $ios = IO::String->new;
    my $writer = new XML::Writer(OUTPUT=>$ios);
    $writer->xmlDecl("iso-8859-1");
    $writer->startTag("listlet","xmlns" => $listletns);

    $writer->startTag("metadata");
    $opt{title} && $writer->dataElement("title",$opt{title});

    my $bad=0;
    $bad++ if UNIVERSAL::isa($opt{author},"ARRAY");
    $bad++ if UNIVERSAL::isa($opt{email},"ARRAY");
    $bad++ if UNIVERSAL::isa($opt{affiliation},"ARRAY"); 
    $bad++ if UNIVERSAL::isa($opt{url},"ARRAY");
    return undef if ($bad!=0 && $bad!=4); # all or none must be arrays

    # serialise the metadata and print it out
    my @md;
    if (!ref($opt{author}))
    {
	push @md,[@opt{"author","email","affiliation","url"}];
    }
    else
    {
	map { push @md,[$opt{"author"}->[$_],$opt{"email"}->[$_],
			$opt{"affiliation"}->[$_],$opt{"url"}->[$_] ] } (0..@{$opt{"author"}});
    }
    for (@md)
    {
	my ($a,$e,$af,$url)=@$_;
	
	next if (!$a);
	$writer->startTag("author");$writer->characters($a);
	
	$writer->dataElement("email",$e) if ($e);
	$writer->dataElement("affiliation",$af,$url?("url"=>$url):()) if ($af);
	$writer->endTag("author");
    }	
    $writer->endTag("metadata");
    
    
    # main part: walk through sequence and print every active style element
    my $map=$self->{tm};

    for my $i (0..$#{$self->{sequence}})
    {
	$self->topic_as_listlet($i,$writer,$ios);
    }
    
    $writer->endTag("listlet");	# the top listlet
    $writer->end();
    return ${$ios->string_ref};   
}

# returns a default style appropriate for the element
# this depends on the thing (assoc/occ/bn) and on the context (the topic in the sequence)
# may need to run with a temp. new map (during reconcile), map otherwise taken from self
# returns ref of style hash 
sub _default_style
{
    my ($self,$context,$thing,$map)=@_;
    my %style=(_on=>1);
    $map||=$self->{tm};

    # a topic itself -> on and be done with it.
    return \%style if ($context eq $thing);	

    my $compat=(exists($self->{tm}->{usual_suspects})?$self->{tm}->{baseuri}:"");

    # what's the nature of this thing?
    my $a=$map->retrieve($thing);
    die "$thing is not an assertion!\n" if (!$a);
    
    # occs and basenames: type display
    if ($a->[TM->KIND]==TM->OCC)
    {
	# non-trivially typed -> _type_on
	$style{_type_on}=1 if ($a->[TM->TYPE] ne $compat."occurrence");
    }
    elsif ($a->[TM->KIND]==TM->NAME)
    {
	# non-trivially typed -> _type_on
	$style{_type_on}=1 if ($a->[TM->TYPE] ne $compat."name");
    }
    elsif ($a->[TM->KIND]==TM->ASSOC)
    {
	# if this is isa/class/instance, then no _role_on please!
	my $roleon=$a->[TM->TYPE] eq $compat."isa"?0:1;
	# prime the _player_order and _player_styles
	my @players=@{$a->[TM->PLAYERS]};
	$style{_player_order}=[0..$#players];
	$style{_player_styles}=[ map {  {_on=>1,_role_on=>$roleon,bullet=>1} } (@players)];

	# but disable the roles which the context topic plays (if any, it could be the role instead)
	map { delete $style{_player_styles}->[$_]->{_on}; } grep($context eq $players[$_], 0..$#players);
    }
    
    # everthing is bulleted by default
    $style{bullet}=1;
    
    return \%style;
}

=pod

=item B<find_nicename:>

($source,$displayname)=$view->find_nicename(I<tid or index> [,$ownstyles,$context]);

This method adds some context-sensitivity to choosing names for the display of 
a topic. If only the tid/index argument is given, then the first basename of this topic 
with source=0 is returned. 
If the ownstyles restriction is set, then the first I<displayed> basename of this topic 
and its style list index is returned. If the restriction is not set, but context is given,
then the basename that is scoped with the context is returned, or the first unscoped basename.

In any case, if nothing matching was found, the tid without baseuri is returned.

As an example, consider this AsTMa map fragment:
  vienna (city)
  bn: Vindobona
  bn@austria: Wien
  bn@oepest: A-1xxx
  in: Wien ist anders.

find_nicename("tm://vienna") will return any of the three basenames, depending on how the TM backend orders
assertions. find_nicename("tm://vienna",0,"tm://murkin") will return (0,"Vindobona") because there is 
no basename with the requested scope. find_nicename("tm://vienna",0,"tm://oepest") will return (0,"A-1xxx"). 

This comes especially handy for associations, where the best name often depends on 
the perspective; for this find_nicename works best when given some help like in the following map fragment:

 (is-part-of)
 whole: a_thing
 part: some_other_thing

 is-part-of
 bn@whole: has components:
 bn@part: is a component of:

=cut

# returns (index,text) of a suitable basename to display 
# if no restriction given or scope is requested: returns (0,basename-with-scope) from the whole map
# otherwise: only checks the listed styles for the first active basename
# returns (0,tid-without-base) if nothing suitable found 
sub find_nicename
{
    my ($self,$tid,$ownstyle,$scope)=@_;
    die "argument is not a TM::View object\n" if (!$self || ref($self) ne __PACKAGE__);

    my $map=$self->{tm};
    my $nice;

    my $compat=(exists($self->{tm}->{usual_suspects})?$self->{tm}->{baseuri}:"");

    if (!$ownstyle || $scope)
    {
	# a minor hack for class/instance relationships: if the map user hasn't given
	# a nice setup, we use "instances:" and "is a:", rsp.
	if ($tid eq $compat."isa")
	{
	    return (0,$scope eq $compat."class"?"instances:":"is a:");
	}

	# this is for association titles and typed-occurrence titling
	# we look in the map for a basename assertion for this
	# topic with the proper scope (if given)
	my @bns=$map->match(TM->FORALL,topic=>$tid,char=>1,type=>$compat."name");

	# if not scoped: return first bn or tid without base, 
	# if scoped: first bn with matching scope, unscoped basename, or tid without base
	my ($firstbn,$usbn);
	for my $a (@bns)
	{
	    my $this=($map->get_x_players($a,$compat."value"))[0]->[0];
	    $firstbn||=$this;
	    return (0,$this) if (!$scope || $a->[TM->SCOPE] eq $scope);
	    $usbn=$this if ($a->[TM->SCOPE] eq $compat."us");
	}
	return (0,$usbn) if ($usbn && $scope);
	return (0,$firstbn) if ($firstbn && !$scope);
    }
    else
    {
	# walk through our own styles and check each assertion for basename and active 
	# zeroth style is irrelevant: midlet itself

	my $index=$self->_find_tidindex($tid,$self->{sequence});
	if (defined $index)
	{
	    my $styles=$self->{sequence}->[$index]; 
	    for my $i (1..$#{$styles})
	    {
		next if (!$styles->[$i]->[1]->{_on});
		my $a=$map->retrieve($styles->[$i]->[0]);
		next if ($a->[TM->KIND]!=TM->NAME);
		return ($i,($map->get_x_players($a,$compat."value"))[0]->[0]);
	    }
	}
    }

    # nothing found? tid without basename, then
    $nice=$tid;
    my $base=$self->{tm}->{baseuri};
    $nice=~s/^$base//;
    return (0,$nice);
}

=pod 

=back

=head1 SEE ALSO

L<TM(3)>

=head1 AUTHOR

Alexander Zangerl, <alphazulu@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007, 2008 Alexander Zangerl

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;

__END__
# data structure: {sequence} is array of nodes
# this holds the topics that are currently listed in the view and their position
# accessor functions: sequence_add, sequence_remove, sequence_move, sequence_length, clear
 
# each and every such sequenced node itself is an array of styles
# styles being elements that list what is to be displayed for this topic, in which order
# and with what visual attributes

# style [0] is always the one for the topic midlet itself and can not be moved
# the subsequent styles list all applicable info: basenames, occurrences and all associations
# the topic is involved in.

# styles always list all available information for a topic; things that are not to be displayed
# are simply switched off via their style info.
# styles apply to midlets and assertions, which means that associations (which are shown with
# involved topics) need extra help (see _player*)
# midlets can be sequenced in one spot only, assertions are often visible in 
# multiple places (think assocs).

# style accessor: style, which returns what is sequenced (midlet/assoc id) and how (style), and which
# also sets new style info
# further accessors: style_move to change the sequences and clear_changed 

# the style info is a hash, with some keys having special meaning for topic_as_listlet():
# _on is 1 if the element is to be shown
# _is_changed is 1 if the element was modified during the last reconciliation run
# _type_on for occurrences toggles display of type information in listlet
# _player_order determines in which order association players are shown (array of indices)
# _player_styles determines how association players are shown.
# within _player_styles, _on and _role_on are special: _on toggles display of this player,
# _role_on toggles display of the role with the player (if the player is on)

# the following style keys are reserved (as used elsewhere):
# "title", "origin", "url" and anything with leading _

# all other style keys are passed through as xml attributes by as_listlet().













