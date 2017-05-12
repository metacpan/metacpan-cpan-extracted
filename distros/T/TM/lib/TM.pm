package TM;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);

our $VERSION  = '1.56';

use Data::Dumper;
# !!! HACK to suppress an annoying warning about Data::Dumper's VERSION not being numerical
$Data::Dumper::VERSION = '2.12108';
# !!! END of HACK

use Class::Struct;
use Time::HiRes;
use TM::PSI;

use Log::Log4perl;
Log::Log4perl::init( \ q(

log4perl.rootLogger=DEBUG, Screen

log4perl.appender.Screen=Log::Log4perl::Appender::Screen
log4perl.appender.Screen.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern=[%r] %F %L %c - %m%n

#log4perl.rootLogger=DEBUG, LOGFILE

#log4perl.appender.LOGFILE=Log::Log4perl::Appender::File
#log4perl.appender.LOGFILE.filename=/tmp/tm.log
#log4perl.appender.LOGFILE.mode=append

#log4perl.appender.LOGFILE.layout=PatternLayout
#log4perl.appender.LOGFILE.layout.ConversionPattern=[%r] %F %L %c - %m%n
		       ) );

our $log = Log::Log4perl->get_logger("TM");

our $infrastructure;                                                                    # default set = core + topicmaps_inc + astma_inc

=pod

=head1 NAME

TM - Topic Maps, Base Class

=head1 SYNOPSIS

    my $tm = new TM (baseuri => 'tm://whatever/');   # empty map

    # add a toplet (= minimal topic, only identification, no characteristics)
    # by specifying an internal ID
    $tm->internalize ('aaa');                        # only internal identifier
    $tm->internalize ('bbb' =>   'http://bbb/');     # with a subject address
    $tm->internalize ('ccc' => \ 'http://ccc/');     # with a subject indicator

    # without specifying an internal ID (will be auto-generated)
    $tm->internalize (undef =>   'http://ccc/');     # with a subject address
    $tm->internalize (undef => \ 'http://ccc/');     # with a subject indicator

    # get rid of toplet(s)
    $tm->externalize ('tm://whatever/aaa', ...);

    # find full URI of a toplet
    my $tid  = $tm->tids ('person');                     # returns tm://whatever/person
    my @tids = $tm->tids ('person', ...)                 # for a whole list

    my $tid  = $tm->tids (  'http://bbb/');              # with subject address
    my $tid  = $tm->tids (\ 'http://ccc/');              # with subject indicator

    my @ts   = $tm->toplets;                             # get all toplets
    my @ts   = $tm->toplets (\ '+all -infrastructure');  # only those you added

    my @as   = $tm->asserts (\ '+all -infrastructure');  # only those you added

    my @as   = $tm->retrieve;                            # all assertions
    my $a    = $tm->retrieve ('23ac4637....345');        # returns only that one assertion
    my @as   = $tm->retrieve ('23ac4637....345', '...'); # returns all these assertions

    # create standalone assertion
    my $a = Assertion->new (type    => 'is-subclass-of',
                            roles   => [ 'subclass', 'superclass' ],
                            players => [ 'rumsti', 'ramsti' ]);
    $tm->assert ($a);                                    # add that to map

    # create a name
    my $n = Assertion->new (kind    => TM->NAME,
                            type    => 'name',
                            scope   => 'us', 
                            roles   => [ 'thing', 'value' ],
                            players => [ 'rumsti', new TM::Literal ('AAA') ])
    # create an occurrence
    my $o = Assertion->new (kind    => TM->OCC,
                            type    => 'occurrence',
                            scope   => 'us',
                            roles   => [ 'thing', 'value' ],
                            players => [ 'rumsti', new TM::Literal ('http://whatever/') ])

    $tm->assert ($n, $o);                                # throw them in

    $tm->retract ($a->[TM->LID], ...);                   # get rid of assertion(s)

    my @as = $tm->retrieve ('id..of...assertion');       # extract particular assertions

    # find particular assertions
    # generic search patterns
    my @as = $tm->match_forall (scope   => 'tm://whatever/sss');

    my @bs = $tm->match_forall (type    => 'tm://whatever/ttt',
                                roles   => [ 'tm://whatever/aaa', 'tm://whatever/bbb' ]);

    # specialized search patterns (see TM::Axes)
    my @cs = $tm->match_forall (type    => 'is-subclass-of', 
			        arole   => 'superclass', 
			        aplayer => 'tm://whatever/rumsti', 
			        brole   => 'subclass');

    my @ds = $tm->match_forall (type    => 'isa',
                                class   => 'tm://whatever/person');

    # perform merging, cleanup, etc.
    $tm->consolidate;

    # check internal consistency of the data structure
    die "panic" if $tm->insane;

    # taxonomy stuff
    warn "what a subtle joke" if $tm->is_a ($tm->tids ('gw_bush', 'moron'));

    die "what a subtle joke"
        unless $tm->is_subclass ($tm->tids ('politician', 'moron'));

    # returns Mr. Spock if Volcans are subclassing Aliens
    warn "my best friends: ". Dumper [ $tm->instancesT ($tm->tids ('alien')) ];


=head1 ABSTRACT

This class provides read/write access to a data structure according to the Topic Maps paradigm. As
it stands, this class implements directly so-called I<materialized> maps, i.e. those maps which
completely reside in memory. Implementations for non-materialized maps can be derived from it.

=head1 DESCRIPTION

This class implements directly so-called I<materialized> topic maps, i.e. those maps which
completely reside in memory. Non-materialized and non-materializable maps can be implemented by
deriving from this class by overloading one or all of the sub-interfaces. If this is done cleverly,
then any application, even a TMQL query processor can operate on non-materialized (virtual) maps in
the same way as on materialized ones.

=head2 Data Structures

The Topic Maps paradigm knows two abstractions

=over

=item I<TMDM>, Topic Maps Data Model 

L<http://www.isotopicmaps.org/sam/sam-model/>

=item I<TMRM>, Topic Maps Reference Model 

L<http://www.isotopicmaps.org/tmrm/>

=back

For historical reasons, this package adopts an abstraction which is in between these
two. Accordingly, there are only following types of data structures

=over

=item Toplets:

These are like TMDM topics, but only contain addressing information (subject identifiers and subject
addresses) along with an internal identifier.

=item Assertions:

These are like TMDM associations, but are generalized to host also occurrences and names. Also
associations using predefined association types, such as C<isa> (I<instance-class>) and C<iko>
(I<subtype-supertype>) are represented as assertions.

=item Variants:

No idea what they are good for. They can be probably safely ignored.

=back

The data manipulation interface is very low-level and B<directly> exposes internal data structures.
As long as you do not mess with the information you get and you follow the API rules, this can
provide a convenient, fast, albeit not overly comfortable interface. If you prefer more a TMDM-like
style of accessing a map then have a look at L<TM::DM>.


=head2 Identifiers

Of course, L<TM> supports the subject locator and the subject indicator mechanism as mandated
by the Topic Maps standards.

Additionally, this package also uses I<internal> identifiers to address everything which looks and
smells like a topic, also associations, names and occurrences. For topics the application (or
author) of the topic map will most likely provide these internal identifiers. For the others the
identifiers are generated.

Since v1.31 this package distinguishes between 3 kinds of internal identifiers:

=over

=item I<canonicalized> toplet identifiers

These identifiers are always interpreted local to a map, in that the C<baseuri> of the map is used
as prefix. So, a local identifier

  chinese-working-conditions

will become

  tm://nirvana/chinese-working-conditions

if the base URI of the map were

  tm://nirvana/

So if you want to use identifiers such as these, then you should either use the absolut version
(including the base URI) or use the method C<tids> to find the absolute version.

=item I<sacrosanct> toplet identifiers

All toplets from the infrastructure are declared I<sacrosanct>, i.e. untouchable. Examples are
C<isa>, C<class> or C<us> (universal scope).

These identifiers are always the same in all maps this package system manages. That implies that if
you use such an identifier, then you cannot attach a local meaning to it. And it implies that at
merging time, toplets with these identifiers will merge. Even if there were no subject indicators or
addresses involved.

It is probably a good idea to leave such toplets alone as the software is relying on the stability
of the sacrosanct identifiers.

=item assertion identifiers

Each assertion also has an (internal) identifier. It is a function from the content, so it
is characteristic for the assertion.

=back

=head2 Consistency

An application using a map may expect that a map is I<consolidated>, i.e. that the following
consistency conditions are met:

=over

=item B<A1> (fixed on)

Every identifier appearing in some assertion as type, scope, role or player is also registered as
toplet.

=item B<Indicator_based_Merging> (default: on)

Two (or more) toplets sharing the same I<subject identifier> are treated as one toplet.

=item B<Subject_based_Merging> (default: on)

Two (or more) toplets sharing the same I<subject locator> are treated as one toplet.

=item B<TNC_based_Merging> (default: off)

Two (or more) toplet sharing the same name in the same scope are treated as one toplet.

=back

=cut

use constant {
    Subject_based_Merging   => 1,
    Indicator_based_Merging => 2,
    TNC_based_Merging       => 3,
};

=pod

While A1 is related with the internal consistency of the data structure (see C<insane>), the others
are a choice the application can make (see C<consistency>).

I<Consistency> is not automatically provided when a map is modified by the application. It is the
applications responsibility to trigger the process to consolidate the map. As that may be
potentially expensive, the control remains at the application.

When an IO driver is consuming a map from a resource, say, loading from an XTM file, then that
driver will ensure that the map is consolidated according to the current settings before it hands it
to the application. The application is then in full control of the map as it can change, add and
delete toplets and assertions. The map can become unconsolidated in this process. The method
C<consolidate> reinstates consistency again.

You can change these defaults by (a) providing an additional option to the constructor

   new TM (....,
           consistency => [ TM->Subject_based_Merging,
                            TM->Indicator_based_Merging ]);

or (b) by later using the accessor C<consistency> (see below).

=head1 MAP INTERFACE

=head2 Constructor

I<$tm> = new TM (...)

The constructor will create an empty map, or, to be more exact, it will fill the map with the
taxonomy from L<TM::PSI> which covers basic Topic Maps concepts such as I<topic> or I<associations>.

The constructor understands a number of key/value pair parameters:

=over

=item C<baseuri> (default: C<tm://nirvana/>)

Every toplet in the map has an unique local identifier (e.g. C<shoesize>). The C<baseuri> parameter
controls how an absolute URI is built from this identifier.

=item C<consistency> (default: [ Subject_based_Merging, Indicator_based_Merging ])

This controls the consistency settings. They can be changed later with the C<consistency> method.

=back

=cut

sub new {
  my $class = shift;
  my %self  = @_;

  $self{consistency} ||= [ Subject_based_Merging, Indicator_based_Merging ];
  $self{baseuri}     ||= 'tm://nirvana/';
  $self{baseuri}      .= '#' unless $self{baseuri} =~ m|[/\#:]$|;

  my $self = bless \%self, $class;

  unless ($self->{mid2iid}) {                                                          # we need to do fast cloning of basic vocabulary
      %{ $self->{mid2iid} }    = %{ $infrastructure->{mid2iid} };                      # shallow clone
      %{ $self->{assertions} } = %{ $infrastructure->{assertions} };                   # shallow clone
  }
  $self->{last_mod} = 0;                                                               # book keeping
  $self->{created}  = Time::HiRes::time;

  return $self;
}

sub DESTROY {}                                                                    # not much to do here

=pod

=head2 Methods

=over

=item B<baseuri>

I<$bu> = I<$tm>->baseuri

This methods retrieves the base URI component of the map. This is a read-only method. The base URI
is B<always> defined.

=cut

sub baseuri {
    my $self = shift;
    return $self->{baseuri};
}

=pod

=item B<consistency>

I<@merging_constraints> = I<$tm>->consistency

I<$tm>->consistency (I<@list_of_consistency_constants>)

This method provides read/write access to the consistency settings.

If no parameters are provided, then the current list of consistency settings is returned. If
parameters are provided, that list must consist of the constants defined under L</Consistency>.

B<NOTE>: Changing the consistency does B<NOT> automatically trigger C<consolidate>.

=cut

sub consistency {
  my $self   = shift;
  my @params = @_;

  $self->{consistency} = [ @params ] if @params;
  return @{$self->{consistency}};
}

=pod

=item B<last_mod>

Returns the L<Time::HiRes> date of last time the map has been modified (content-wise).

=cut

sub last_mod {
    my $self = shift;
    return $self->{last_mod};
}

=pod

=item B<consolidate>

I<$tm>->consolidate

I<$tm>->consolidate (I<@list_of_consistency_constants>)

This method I<consolidates> a map by performing the following actions:

=over

=item * 

perform merging based on subject address (see TMDM section 5.3.2)

=item * 

perform merging based on subject indicators (see TMDM section 5.3.2)

=item * 

remove all superfluous toplets (those which do not take part in any assertion)

B<NOTE>: Not implemented yet!

=back

This method will normally use the map's consistency settings. These settings can be overridden by
adding consistency settings as parameters (see L</Consistency>). In that case the map's settings are
B<not> modified, so use this carefully.

B<NOTE>: In all cases the map will be modified.

B<NOTE>: After merging some of the I<lids> might not be reliably point to a topic.

=cut

# NOTE: Below there much is done regarding speed. First the toplets are swept detecting which have
# to be merged. This is not done immediately (as this is an expensive operation), instead a 'merger' hash
# is built. Note how merging information A -> B and A -> C is morphed into A -> B and B -> C using
# the _find_free function.

# That merger hash is then consolidated by following edges until their end, so that there are no
# cycles.

sub consolidate {
  my $self = shift;
  my $cons = @_ ? [ @_ ] : $self->{consistency};                           # override
  my $indi = grep ($_ == Indicator_based_Merging, @{$self->{consistency}});
  my $subj = grep ($_ == Subject_based_Merging,   @{$self->{consistency}});
  my $tnc  = grep ($_ == TNC_based_Merging,       @{$self->{consistency}});

#warn "cond indi $indi subj $subj tnc $tnc";

  my %SIDs; # holds subject addresses found
  my %SINs; # holds subject indicators found
  my %BNs;  # holds basename + scope found

#warn Dumper $cons;

#== find merging points and memorize this in mergers =======================================================================
  my %mergers;                                                             # will contain the merging edges
  my $mid2iid = $self->{mid2iid};                                          # shortcut
  my $asserts = $self->{assertions};                                       # shortcut
  my $baseuri = $self->{baseuri};                                          # shortcut

MERGE:
  foreach my $this (keys %{$mid2iid}) {
#warn "looking at $this";
      my $thism = $mid2iid->{$this};
#warn "SIDs: ". Dumper \%SIDs;
#warn "SINs: ". Dumper \%SINs;
#-- based on subject indication ------------------------------------------------------------------------------------------
      if ($indi) {
	  foreach my $sin (@{$thism->[TM->INDICATORS]}) {                  # walk over the subject indicators
	      if (my $that  = $SINs{$sin}) {                               # $that is now a key pointing to a merging partner
#warn "merging (IND) $this >> $that"; #. Dumper $thism, $thatm;
		  _add_merge (\%mergers, $baseuri, $this, $that);

              } else {                                                     # no merging, so enter the sins
                  $SINs{$sin} = $this;
	      }
	  }
      }

sub _add_merge {
    my $mergers = shift;
    my $bu      = shift;
    my $this    = shift;
    my $that    = shift;

    ($this, $that) = ($that, $this) if $this =~ /^$bu/;                    # we swap them to favor that which resembles the baseURI
    $mergers->{_find_free ($this, $mergers)} = $that;                      # find a free place to make that mapping
}

sub _find_free {
    my $this = shift;
    my $mergers = shift;
    
    my $this2 = $this;
    my $this3;
    while ($this3 = $mergers->{$this2}) {
	if ($this3 eq $this || $this3 eq $this2) {       # loop, we do not need it
	    return $this3;
	} else {
	    $this2 = $this3;                             # we follow the trail
	}
    }
    return $this2;                                       # this2 was the end of the trail
}

#-- based on subject address ---------------------------------------------------------------------------------------------
      if ($subj) {
	  if (my $sid = $thism->[TM->ADDRESS]) {
	      if (my $that = $SIDs{$sid}) {                                # found partner => should be merged
#warn "merging (ADDR) $this >> $that";
		  _add_merge (\%mergers, $baseuri, $this, $that);
###### old		  $mergers{_find_free ($this, \%mergers)} = $that;
		  # must obviously both have the same subject address, so, no reason to touch this
	      } else {                                                     # there is no partner, first one with this subject address
		  $SIDs{$sid} = $this;
	      }
	  }
      }
#warn "after 1 on '$this' ";#.Dumper $mid2iid;
  }
#-- based on TNC ---------------------------------------------------------------------------------------------
   if ($tnc) {
      my ($THING, $VALUE) = ('thing', 'value');
      foreach my $a (values %$asserts) {
	  next unless $a->[TM->KIND] == TM->NAME;                          # we are only interested in basenames
#warn "checking assertion ".Dumper $a;
	  my ($v) = get_x_players ($self, $a, $VALUE);                     # if we get back a longer list, bad luck
	  my $bn_plus_scope = $v->[0] .                                    # the basename is a string reference
                              $a->[TM->SCOPE];                             # relative to the scope
	  my ($this) = get_x_players ($self, $a, $THING);                  # thing which plays 'topic'
#warn "    --> player is $this";
	  if (my $that = $BNs{$bn_plus_scope}) {                           # if we have seen it before
#warn "  -> SEEN";
	      _add_merge (\%mergers, $baseuri, $this, $that);
#### old      $mergers{_find_free ($this, \%mergers)} = $that;
	  } else {                                                         # it is new to use, we store it into %BNs
#warn "  -> NOT SEEN";
	      $BNs{$bn_plus_scope} = $this;
#warn "BNs ".Dumper \%BNs;
	  }
      }
  }
#== consolidate mergers: no cycles, trail followed through ======================================================
#warn "mergers ".Dumper \%mergers;

  for (2..2) { # at most 2, theoretical only one should be sufficient
      my $changes = 0;
      foreach my $h (keys %mergers) {
#warn "working on $h";
	  if ($mergers{$h} eq $h) { # micro loop
	      delete $mergers{$h};
	  } elsif (defined $mergers{$mergers{$h}} && $mergers{$mergers{$h}} eq $h) {
	      delete $mergers{$h};
	  } else {
	      my $h2 = $mergers{$h};
	      my %seen = ($h => 1,  $h2 => 1); # loop avoidance
#warn "seeen start".Dumper \%seen;
	      while ($mergers{$h2} and !$seen{$mergers{$h2}}++) { $h2 = $mergers{$h} = $mergers{$h2}; $changes++;}
#warn "half consolidated (chagens $changes)" .Dumper $H;
	  }
      }
#      warn "consoli loop $_: changes: $changes";
#      warn "early finish" if $_ == 1 and $changes == 0;
      last if $changes == 0;
#      die "not clean" if $_ == 2 and $changes > 0;
  }

#warn "consolidated mergers ".Dumper \%mergers;


#== actual merging ========================================================================================

  # recanonicalize affected assertions
  {
      my $changed = _relabel (\%mergers, $self->baseuri, values %$asserts );
      while (my ($k, $a) = each %$changed) {
	  delete $asserts->{ $k };
#	  delete $mid2iid->{ $k };
#	  $mid2iid->{ $a->[TM->LID] } = [ $a->[TM->LID], undef, [] ];
	  $asserts->{ $a->[TM->LID] } = $a;
      }
  }

  foreach my $that (keys %mergers) {
      my $this  = $mergers{$that};
      my $thism = $mid2iid->{$this};
      my $thatm = $mid2iid->{$that};                           # shorthand
      next if $thatm == $thism;                  # we already have merged

      $log->logdie ("two different subject addresses for two topics to be merged ($this, $that)")
	  if $thism->[TM->ADDRESS] and $thatm->[TM->ADDRESS] and 
	     $thism->[TM->ADDRESS] ne  $thatm->[TM->ADDRESS];

#warn "merge now $that > $this";
             $thism->[TM->ADDRESS]  ||=   $thatm->[TM->ADDRESS];                 # first subject address
      {                                                                          # then indicators
	  my $Is = $thism->[TM->INDICATORS];                                     # reference to thism indicators
	  push @$Is, @{$thatm->[TM->INDICATORS]};                                # add the others to it
	  { my %X; map { $X{$_}++ } @$Is; @$Is = keys %X; }                      # make that unique
      }
      $mid2iid->{$that} = $thism;                                                # finally
  }
#warn "after post-merger ". Dumper $mid2iid;

  $self->{mid2iid}  = $mid2iid;                                                  # this makes tie happy, in the case the map is tied
  $self->{last_mod} = Time::HiRes::time;
}

=pod

=item B<clear>

I<$tm>->clear

This method removes all toplets and assertions (except the infrastructure). Everything else remains.

=cut

sub clear {
    my $self    = shift;

    my %mid2iid    = %{ $infrastructure->{mid2iid} };                            # shallow clone
    my %assertions = %{ $infrastructure->{assertions} };                         # shallow clone

    $self->{mid2iid}    = \%mid2iid;                                             # making it explicit keeps MLDBM happy
    $self->{assertions} = \%assertions;                                          # ditto
    $self->{last_mod}   = Time::HiRes::time;                                     # book keeping
    return $self;                                                                # convenience for chaining
}

=pod

=item B<add>

I<$tm>->add (I<$tm2>, ...)

This method accepts a list of L<TM> objects and adds all content from these maps to the current
object.

B<NOTE>: There is B<NO> merging done for user-supplied toplets. Use explicitly method C<consolidate>
for it. Merging is done for all sacrosanct toplets, i.e. those from the infrastructure.

From v1.31 onwards this method tries to favour the I<internal> identifiers (LIDs) of B<this> map
over LIDs of the added maps. This means, firstly, that internal identifiers of B<this> map are
B<not> touched (or re-generated) in any way and that any shorthands (without a baseuri prefix) will
remain valid when using C<tids>. Secondly, LIDs in the added map will be attempted to blend into
B<this> map by changing simply their prefix. If that newly generated LID is already taken by
something in B<this> map, then the original LID will be used. That allows many added LIDs be used
together with C<tids> without (much) change in code. Of course, the only reliable way to reach a
topic is a subject locator or an indicator. This is all about convenience.

B<NOTE>: This procedure implies that some assertions are recomputed, so that also their LID will
change!


=cut

sub add {
    my $self    = shift;
    my $baseuri = $self->{baseuri};
    my $mid2iid = $self->{mid2iid};                                            # shorthand
    my $asserts = $self->{assertions};

    foreach (@_) {                                                             # deal with one store after the other
	my $baseuri2 = $_->{baseuri};

	my %changes;                                                           # will contain old -> new internal identifier mappings
	while (my ($k, $v) = each %{$_->{mid2iid}}) {

	    if ($infrastructure->{mid2iid}->{$k}) {                            # infrastructure toplets are sacrosanct
	    } else {
		(my $k2 = $k) =~ s/^$baseuri2/$baseuri/;                       # replace baseuri2 prefix

		$k2  = $k if $mid2iid->{$k2};                                  # if there is a collision, bounce back to original
		$k2 .= '1' while $mid2iid->{$k2};                              # while there is still a collision ... (this only in case of same baseuris)
#		$k2 = $baseuri.sprintf ("uuid-%010d", $TM::toplet_ctr++)
#		    if $mid2iid->{$k2};                                        # if there is a collision, create generic one

		$changes{$k}    = $k2;
		$v->[TM->LID]   = $k2;                                         # use that key as canonical one
		$mid2iid->{$k2} = $v;                                          # ...add what the other has
	    }
	}
#warn Dumper \%changes;
	my $changed = _relabel (\%changes, $baseuri, values %{ $_->{assertions} } );
#warn Dumper $changed;
	while (my ($k, $a) = each %$changed) {
#	    delete $mid2iid->{ $k };
#	    $mid2iid->{ $a->[TM->LID] } = [ $a->[TM->LID], undef, [] ]; # put the new one in here
	    $asserts->{ $a->[TM->LID] } = $a;                                  # and also in the assertions part
	}
    }
    $self->{mid2iid}    = $mid2iid;                                            # make MLDBM happy
    $self->{assertions} = $asserts;                                            # ditto
    $self->{last_mod}   = Time::HiRes::time;
}


sub _relabel {
    my $changes = shift;
    my $baseuri = shift;

    my %changed;                                                                          # we record here old LID -> newly relabelled assertion
    foreach my $a (@_) {
	my ($this, $that);
#warn "working on ".Dumper $a;
        $a->[TM->SCOPE]  = $that if $that = $changes->{ $a->[TM->SCOPE] }; $this ||= $that;
	$a->[TM->TYPE]   = $that if $that = $changes->{ $a->[TM->TYPE]  }; $this ||= $that;
	
	map { $_ = $this = $that if $that = $changes->{ $_ } } @{ $a->[TM->ROLES]   };
	map { $_ = $this = $that if $that = $changes->{ $_ } } @{ $a->[TM->PLAYERS] };
#warn "$this for ".Dumper $a;
	$changed{ $a->[TM->LID] } = $a if $this;                                          # something has changed

	$a->[TM->CANON] = 0; canonicalize (undef, $a);
	$a->[TM->LID]   = mklabel ($a);
	
    }
    return \%changed;
}

=pod

=item B<diff>

I<$diff> = I<$new_tm>->diff (I<$old_tm>)

I<$diff> = TM::diff (I<$new_tm>, I<$old_tm>)

I<$diff> = TM::diff (I<$new_tm>, I<$old_tm>, 
                     {consistency => \ @list_of_consistency_consts,
                      include_changes => 1})

C<diff> compares two topic maps and returns their differences as a hash reference. While it works on
any two maps, it is most useful after one map (the I<old map>) is modified into a I<new map>.

If C<diff> is used in OO-style, the current map is interpreted as the I<new> map and the map in the
arguments as I<the old one>.

By default, the toplet and assertion identifiers for any changes are returned; the option
C<include_changes> causes the return of the actual toplets and assertions themselves. This option
makes C<diff>'s output more self-contained: enabled, one can fully (re)create the new map from the
old one using the diff (or vice versa).

The C<consistency> option uses the same format as the TM constructor (see L</Constructor>) and
describes how corresponding toplets in the two maps are to be identified.  Toplets with the same
internal ids are always considered equal. If I<subject based consistency> is active, toplets with
the same I<subject locator> are considered equal (overriding the topic identities).  If I<indicator
based consistency> is active, toplets with a matching I<subject indicator> are considered equal
(overriding the previous identities).

B<NOTE>: This overriding of previous conditions for identity is necessary to keep the equality
relationship unique and one-to-one.  As an example, consider the following scenario: a toplet I<a>
in the old map is split into multiple new toplets I<a> and I<b> in the new map. If I<a> had a
locator or identifier that is moved to I<b> (and if consistency options were active), then the
identity detector will consider I<b> to be equal to I<a>, and B<not> I<a> in the new map to
correspond to I<a> in the old map.  However, this will never lead to loss of information: I<a> in
the new map is flagged as completely new toplet.

The differences between old and new map are returned underneath the keys I<plus>, I<minus>,
I<identities> and I<modified>. If C<include_changes> is on, the extra keys I<plus_midlets>,
I<minus_midlets> and I<assertions> are populated. The values of all these keys are hash references
themselves.

=over

=item I<plus>, I<minus>

The C<plus> and C<minus> hashes list new or removed toplets, respectively (with their identifiers as
keys).  For each toplet, the value of the hash is an array of associated assertion ids. The array is
empty but defined if there are no associated assertions.

For toplets the attached assertions are the usual ones (names, occurrences) and class-instance
relationships (attached to the instance toplet).

For associations, the assertions are attached to the I<type> toplet.

=item I<identities>

This hash consists of the non-trivial toplet identities that were found. If neither Subject- nor
Indicator-based merging is active, then this hash is empty. Otherwise, the keys are toplet
identifiers in the old map, with the corresponding topic identifier in the new map as value. This 
includes standalone topics as well as assertions and associations that were renamed due to 
changed player or role identities.

=item I<modified>

The I<modified> hash contains the changes for matched toplets. The key is the toplet identifier in
the old map (which is potentially different from the one in the new map; see the note about
identities above). The value is a hash with three keys: I<plus>, I<minus> and I<identities>.  The
value for the C<identities> key is defined if and only if the toplet associated with this toplet has
changed (i.e. Subject Locator or Indicators have changed).  The values for the C<plus> and C<minus>
keys are arrays with the new or removed assertions that are attached to this toplet. These arrays are
defined but empty where no applicable information is present.

=item I<plus_midlets>, I<minus_midlets>

These hashes hold the actual new or removed toplets if the option C<include_changes> is active.
Keys are the toplet ids, values are references to the actual toplet data structures.

=item I<assertions>

This hash holds the actual assertions where the maps differ; it exists only if the option
C<include_changes> is active. Keys are the assertion identifiers, values the references to the
actual assertion data structure. Note that assertion ids uniquely identify the assertion contents,
therefore this hash can hold assertions from both new and old map.

=back

=cut 

sub diff {
    my ($newmap,$oldmap,$options)=@_;
    return undef if (!$oldmap || !$newmap);

    my ($base)=$oldmap->baseuri;
    $log->logdie ("comparison of maps with different bases not supported yet!")
	if ($newmap->baseuri ne $base);

    my (%plus,%minus,%modified);
    # a lot of comparison/translation can be skipped if tids are the only identity
    my $xlatneeded= grep($_==TM->Subject_based_Merging || 
			 $_==TM->Indicator_based_Merging,@{$options->{consistency}});

    # first walk the maps to match old and new items
    my (%seen,%locators,%indicators);
    for my $map ($oldmap,$newmap) {
	my $key   = ($map eq $oldmap ? "old":"new");
	my $value = ($map eq $oldmap ? 1:2);

	for my $m (map { $_->[TM->LID] } ($map->toplets(\ '+all'))) {
	    # get the topic-aspects (tid, locators and identifiers)
	    # for finding unchanged/new/old topics
	    my $midlet=$map->toplet($m);
	    $locators{$key}->{$midlet->[TM->ADDRESS]}=$m
		if ($midlet->[TM->ADDRESS]);
	    map { $indicators{$key}->{$_}=$m } (@{$midlet->[TM->INDICATORS]});
	    $seen{$m}|=$value;
	}
	for my $a (map { $_->[TM->LID] } $map->asserts (\ '+all')) {
	    $seen{$a}|=$value;
	}
    }

    # identify same topics
    # first identity: same topic ids 
    my %old2new = map { ($_,$_) } grep { $seen{$_} == 3 } keys %seen;
    my $foundxlat;
    if (grep($_==TM->Subject_based_Merging,@{$options->{consistency}}))
    {
	# second: same locators
	# note that this overwrites topic identitites!
	# scenario: old has topica/loc x; new has topica/no loc and topicb/loc x
	map { $foundxlat||=($locators{old}->{$_} ne $locators{new}->{$_});
	      $old2new{$locators{old}->{$_}}=$locators{new}->{$_}; 
              } 
	(grep(exists $locators{new}->{$_}, keys %{$locators{old}}));
    }
    if (grep($_==TM->Indicator_based_Merging,@{$options->{consistency}}))
    {
	# final: matching indicators
	# note that this overwrites topic and locator identitites, similar scenario as above
	map { $foundxlat||=($indicators{old}->{$_} ne $indicators{new}->{$_});
	      $old2new{$indicators{old}->{$_}}=$indicators{new}->{$_}; } 
	(grep(exists $indicators{new}->{$_}, keys %{$indicators{old}}));
    }
    # no need to bother with translating assertions if there are no changed-tid identities
    $xlatneeded=0 if ($xlatneeded && !$foundxlat); 

    # produce list of missing/new topics
    my %new2old=($xlatneeded?(reverse %old2new):%old2new);
    my (%checkmidlet,%plusass,%minusass);
    for my $t (keys %seen)
    {
	if ($seen{$t}==2 && !$new2old{$t})
	{
	    # identical assertions with new lids are not detected here
	    # but later (via minusass)
	    # new assertion-lids happen with identified renamed players (lid is computed over values!)
	    $newmap->retrieve($t)?$plusass{$t}=1:$plus{$t}=[];
	}
	elsif ($seen{$t}==1 && !$old2new{$t}) 
	{
	    $oldmap->retrieve($t)?$minusass{$t}=1:$minus{$t}=[];
	}
	else
	{
	    # we work along the old tids (when not the same)
	    $checkmidlet{$seen{$t}==2?$new2old{$t}:$t}=1;
	}
    }
    undef %seen; undef %locators; undef %indicators;

#warn "check midlets ".Dumper \ %checkmidlet;

    # weed out the topics/midlets that are unchanged
    # and all the identical assertions
    my @checkassertion;
    for my $t (keys %checkmidlet) {

	if ($t =~ /^[A-F0-9]{32}$/i) {
	    my $oa=$oldmap->retrieve($t);
	    my $on=$newmap->retrieve($old2new{$t});
	    
	    if ($oa && $on && $oa->[TM->LID] ne $on->[TM->LID]) {
		push @checkassertion,$t;
	    }
	} else {
	    my $ot = $oldmap->toplet($t);
	    my $nt = $newmap->toplet($old2new{$t});

	    unless (_toplets_eq ($ot, $nt)) {
		$modified{$t}->{identities}=1;
		$modified{$t}->{plus}||=[];
		$modified{$t}->{minus}||=[];
	    }

	    # note: new toplet() returns internal id as well, which we DON'T want to check on here!
	    sub _toplets_eq 
	    {
		my ($a,$b)=@_;
		
		my ($A, $B) = ($a->[TM->ADDRESS] ||'', $b->[TM->ADDRESS] ||'');       # just convert undef into ''
		return 0 unless $A eq $B;                                             # different subject address?
		my %SIDS;
		map { ++$SIDS{$_} } @{$a->[TM->INDICATORS]}, @{$b->[TM->INDICATORS]};   # we KNOW that the lists are UNIQUE, do we?
		return 0 if grep { $_ != 2 } values %SIDS;                            # if it is not exactly 2 (one from a, one from b), then not equal
		return 1; # we're happy: different LIDs don't interest us here
	    }
	    
	}
    }

#warn "modified ".Dumper \%modified;

    my %old2newid;    
    my %identities; 
    if ($xlatneeded)
    {
	# now do the translation for assertions: rebuild old assertions
	# into new namespace and compute the id
	# don't waste time: do this only on the assertions that may be required
	# minusass (or plusass) must be checked to find assertions with renamed-but-identical players
	for my $t (@checkassertion,keys %minusass)
	{
	    my $m=$oldmap->retrieve($t);
	    my ($lid,$scope,$kind,$type,$roles,$players)=
		@{$m}[TM->LID,TM->SCOPE,TM->KIND,TM->TYPE,TM->ROLES,TM->PLAYERS];

	    # if any of the topics is untranslatable, then skip the remaining work
	    # as it can't successfully compare anyway...
	    $scope=$old2new{$scope} || next;
	    $type=$old2new{$type} || next;
	    my @newroles = map { ref($_)?$_:$old2new{$_} || next; } (@{$roles});
	    my @newplayers = map { ref($_)?$_:$old2new{$_} || next; } (@{$players});

	    my $n=Assertion->new(scope=>$scope,
				 kind=>$kind,
				 type=>$type,
				 roles=>\@newroles,players=>\@newplayers);
	    $newmap->canonicalize($n);
	    my $newid=TM::mklabel($n);
	    $old2newid{$t}=$newid;

	    if ($plusass{$newid}) # we found a matching assertion, wohee!
	    {
		delete $plusass{$newid};
		delete $minusass{$t};
		# remember that this assertion was re-id'd (directly or indirectly via players)
		# this is done for standalone assocs just the same as for bn/oc characteristics
		$identities{$t}=$newid;
	    }
	}
    }

    # finally, find and attach the modified assertions to their topics
    # attributes: to the topic
    # associations: to the type-topic

    for my $key ("plus","minus")
    {
	my ($unmodified,$map,$candidates);
	if ($key eq "plus")
	{
	    $unmodified=\%plus; $map=$newmap; $candidates=\%plusass;
	}
	else
	{
	    $unmodified=\%minus; $map=$oldmap; $candidates=\%minusass;
	}
	
	for my $t (keys %{$candidates})
	{
	    my $m=$map->retrieve($t);
	    my ($oldwho,$who,$what);
	    if ($m->[TM->KIND] ne TM->ASSOC)
	    {
		# bn or oc: attach to referenced topic
		$who=($map->get_x_players($m,"thing"))[0];
		$what=$t;
	    }
	    elsif ($m->[TM->TYPE] eq "isa")
	    {
		# isa associations get attached to the instance topic
		$who=($map->get_x_players($m,"instance"))[0];
		$what=$t;
	    }
	    else 
	    {			
		# general assoc: gets attached to type topic
		$who=$m->[TM->TYPE];
		$what=$t;
	    }

	    # if this assertion belongs to a topic that is marked gone/new, we save it with that topic
	    if ($unmodified->{$who})
	    {
		push @{$unmodified->{$who}},$what;
	    }
	    else # if this belongs to a modified topic: more details please (new/old ass)
	    {
		# we access things along the old id axis...
		if ($key eq "plus")
		{
		    $who=$new2old{$who};
		}
		$modified{$who}->{$key}||=[];
		push @{$modified{$who}->{$key}},$what;
	    }
	}
    }

    map { $identities{$_}=$old2new{$_} if ($_ ne $old2new{$_}); } (keys %old2new);

    my $returnvalue={
	    'identities'=>\%identities,
	    'plus'=>\%plus,
	    'minus'=>\%minus,
	    'modified'=>\%modified,
	};

    # pull in the midlets and assertions that have been affected,
    # so that the resulting datastructure can be frozen and used together with oldmap
    # to (re)create newmap
    if ($options->{include_changes})
    {
	# one problem, though is naming: midlets can have changed but their name doesn't
	# reflect that: we need two midlet datastructures here.
	# (assertions are fine, their names always reflect their content uniquely)

	my (%plusm,%minusm,%ass,$a);
	map { $plusm{$_} = $newmap->toplet($_) } keys %plus;
	map { $ass{ $_->[TM->LID] } = $_ }
  	   map { $newmap->retrieve($_) }
           map { @$_ }
           values %plus;
	map { $minusm{$_} = $oldmap->toplet($_) } keys %minus;
	map { $ass{ $_->[TM->LID] } = $_ }
  	   map { $oldmap->retrieve($_) }
           map { @$_ }
           values %minus;

	for my $k (keys %modified)
	{
	    # these are corresponding topics with differing midlet (contents)
	    if ($modified{$k}->{identities})
	    {
		$plusm{$k}  = $newmap->toplet($old2new{$k});
		$minusm{$k} = $oldmap->toplet($k);
	    }
	    map { $plusm{$_} =$newmap->toplet($_); $a=$newmap->retrieve($_) and $ass{$_}=$a; } (@{$modified{$k}->{plus}}); 
	    map { $minusm{$_}=$oldmap->toplet($_); $a=$oldmap->retrieve($_) and $ass{$_}=$a; } (@{$modified{$k}->{minus}}); 
	}

	$returnvalue->{plus_midlets}  =\%plusm;
	$returnvalue->{minus_midlets} =\%minusm;
	$returnvalue->{assertions}    =\%ass;
    }

    return $returnvalue;
}

=pod

=item B<melt> (DEPRECATED)

I<$tm>->melt (I<$tm2>)

This - probably more auxiliary - function copies relevant aspect of a second map into the object.

=cut

our @ESSENTIALS = qw(mid2iid assertions baseuri variants);

sub melt {
    my $self = shift;
    my $tm2  = shift;

    @{$self}{@ESSENTIALS} = @{$tm2}{@ESSENTIALS};
    $self->{last_mod} = Time::HiRes::time;
}

=pod

=item B<insane>

warn "topic map broken" if I<$tm>->insane

This method tests invariant conditions inside the TM structure of that map. Specifically,

=over

=item *

each toplet has a LID which points to a toplet with the same address

=back

It returns a string with a message or C<undef> if everything seems fine.

TODO: add test whether all variant entries have a proper LID (and toplet)


=cut

sub insane {
    my $self = shift;

    my $mid2iid = $self->{mid2iid};
    my $asserts = $self->{assertions};

# Test 1: all toplet LIDs point to something in mid2iid which refers to themselves
    foreach my $k (keys %$mid2iid) {
	my $t = $mid2iid->{$k};
	return "toplet LID $k not in mid2iid" 
	    unless $mid2iid->{ $t->[TM->LID] };
	return "LID $k inconsistent with toplet LID"
	    unless $mid2iid->{ $t->[TM->LID] } == $t;
	return "key $k looks like assertion, but has not assertions entry" 
	    if $k =~ /[[:xdigit:]]{16}/ and !$asserts->{$k};
    }
## Test 2: all assertions are toplets
#    foreach my $k (keys %$asserts) {
#	return "assertion $k has no toplet entry"
#	    unless $mid2iid->{ $asserts->{$k}->[TM->LID] };
#	return "assertion $k toplet entry has a different LID"
#	    unless $mid2iid->{ $asserts->{$k}->[TM->LID] }->[TM->LID] eq $k;
#    }
    return undef; # pass all tests
}

=pod

=back

=head1 TOPLET INTERFACE

I<Toplets> are light-weight versions of TMDM topics. They only carry addressing information and are
represented by an array (struct) with the following fields:

=cut

struct 'Toplet' => [
    lid         => '$',
    saddr       => '$',
    sinds       => '$',
];

=pod

=over

=item C<lid> (index: C<LID>)

The internal identifier. Mostly it repeats the key in the toplet hash, but also aliased identifiers
may exist.

=item C<saddr> (index: C<ADDRESS>)

It contains the B<subject locator> (address) URI, if known. Otherwise C<undef>.

=item C<sinds> (index: C<INDICATORS>)

This is a reference to a list containing B<subject identifiers> (indicators). The list can be empty,
no duplicate removal is attempted at this stage.

=back

You can create this structure manually, but mostly you would leave it to C<internalize> to do the
work.

Example:

   # dogmatic way to produce it
   my $to = Toplet->new (lid   => $baseuri . 'my-lovely-cat',
                         saddr => 'http://subject-address.com/',
                         sinds => []);

   # also good and well
   my $to = [ $baseuri . 'my-lovely-cat', 
              'http://subject-address.com/',
               [] ];

   # better
   my $to = $tm->internalize ('my-lovely-cat' => 'http://subject-address.com/');

To access the individual fields, you can either use the struct accessors C<saddr> and C<sinds>, or
use the constants defined above for indices into the array:

=cut

use constant {
#   LID        => 0,
    ADDRESS    => 1,
    INDICATORS => 2
};

=pod

Example:

   warn "indicators: ", join (", ", @{$to->sinds});

   warn "locator:    ", $to->[TM->ADDRESS];

=head2 Methods

=over

=item B<internalize>

I<$iid>  = I<$tm>->internalize (I<$some_id>)

I<$iid>  = I<$tm>->internalize (I<$some_id> => I<$some_id>)

I<@iids> = I<$tm>->internalize (I<$some_id> => I<$some_id>, ...)

This method does some trickery when a new toplet should be added to the map, depending on how
parameters are passed into it. The general scheme is that pairs of identifiers are passed in.  The
first is usually the internal identifier, the second a subject identifier or the subject
locator. The convention is that subject identifier URIs are passed in as string references, whereas
subject locator URIs are passed in as strings.

The following cases are covered:

=over

=item C<ID =E<gt> undef>

If the ID is already an absolute URI and contains the C<baseuri> of the map as prefix, then this URI
is used as internal toplet identifier. If the ID is some other URI, then a toplet with that URI as
subject locator is searched in the map. If such a toplet already exists, then nothing special needs
to happen.  If no such toplet existed, a new URI, based on the C<baseuri> and a random number will
be created for the internal identifier and the original URI is used as subject address.

B<NOTE>: Using C<URI =E<gt> URI> implies that you use two different URIs as subject addresses. This
will result in an error.

=item C<ID =E<gt> URI>

Like above, only that the URI is directly interpreted as subject address.

=item C<ID =E<gt> \ URI> (reference to string)

Like above, only that the URI is interpreted as another subject identifier. If the toplet already existed,
then this subject identifier is simply added. Duplicates are suppressed (since v1.31).

=item C<undef =E<gt> URI>

Like above, only that the internal identifier is auto-created if there is no toplet with the URI
as subject address.

Attention: If you call internalize like this

  $tm->internalize(undef => $whatever) 

then perl will (un)helpfully replace the required undef with the string "undef" and wreck the operation. 
Using either a variable to hold the undef or replacing the (syntactic sugar) arrow with a comma works around this issue.

=item C<undef =E<gt> \ URI>

Like above, only that the URI us used as subject identifier.

=item C<undef =E<gt> undef>

A toplet with an auto-generated ID will be inserted.

=back

In any case, the internal identifier(s) of all inserted (or existing) toplets are returned for
convenience.

=cut

our $toplet_ctr = 0;

sub internalize {
    my $self    = shift;
    my $baseuri = $self->{baseuri};

#warn "internalize base: $baseuri";

    my @mids;
    my $mid2iid = $self->{mid2iid};
    while (@_) {
	my ($k, $v) = (shift, shift);                              # assume to get here undef => URI   or   ID => URI   or ID => \ URI   or ID => undef
#warn "internalize $k, $v"; # if ! defined $k;
	# make sure that $k contains a mid

	$k = undef if defined $k && $k eq 'undef';                 # perl 5.10 will stringify undef => ....

	if (defined $k) {
	    if ($mid2iid->{$k}) {                                  # this identifier is already in the map
                # null
	    } elsif ($k =~ /^$baseuri/) {                          # ha, perfect, another identifier already in form
		# null                                             # keep it as it is
	    } elsif ($k =~ /^\w+:/) {                              # some other absURL
		if (my $k2 = $self->tids ($k)) {                   # we already had it
		    ($k, $v) = ($k2, $k);
		} else {                                           # it is unknown so far
		    ($k, $v) = ($baseuri.sprintf ("uuid-%010d", $toplet_ctr++), $k);
		}
	    } elsif (my $k2 = $self->tids ($k)) {
		$k = $k2;                                          # then we already have it, maybe under a different mid, take that

	    } else {                                               # this means we have a relURI and it is not from that map
		$k = $baseuri.$k;                                  # but now it is
	    }

	} elsif (ref ($v) eq 'Assertion') {                        # k is not defined, lets look at v, but if that is an assertion
	    $k = $baseuri.sprintf ("uuid-%010d", $toplet_ctr++);   # generate a new one
	} elsif (my $k2 = $self->tids ($v)) {                      # k is not defined, lets look at v; we already had it
	    $k = $k2;                                              # this will be k then
	} else {                                                   # it is unknown so far
	    $k = $baseuri.sprintf ("uuid-%010d", $toplet_ctr++);   # generate a new one
	}

#warn "really internalizing '$k' '$v'";
	push @mids, $k;

	$v = $v->[TM->LID] if ref ($v) eq 'Assertion';             # for internal reification we use the assertion's LID

	$mid2iid->{$k} ||= [ $k, undef, [] ];                      # now see that we have an entry in the mid2iid table
	my $kentry = $mid2iid->{$k};                               # keep this as a shortcut

	if ($v) {
	    if (ref($v)) {                                         # being a reference means that we have a subject indication
		push @{$kentry->[TM->INDICATORS]}, $$v             # append it to the list
		    unless grep {$$v eq $_} @{$kentry->[TM->INDICATORS]};   # if not yet there
	    } elsif ($kentry->[TM->ADDRESS]) {                     # this is a subject address and, oh, there is already a subject address, not good
		$log->logdie ("duplicate subject address '$v' for '$k'") unless $v eq $kentry->[TM->ADDRESS];
	    } else {                                               # everything is fine, we can set it
		$kentry->[TM->ADDRESS] = $v;                 
	    }
	}
	$mid2iid->{$k} = $kentry;                                  # necessary if mid2iid is tied itself
    }
    $self->{mid2iid}  = $mid2iid;                                  #!! needed for Berkeley DBM recognize changes on deeper levels
    $self->{last_mod} = Time::HiRes::time;
    return wantarray ? @mids : $mids[0];
}

=pod

=item B<toplet> (old name B<midlet>)

I<$t>  = I<$tm>->toplet (I<$mid>)

I<@ts> = I<$tm>->toplet (I<$mid>, ....)

This function returns a reference to a toplet structure. It can be used in scalar and list context.

=cut

sub midlet {
    return toplet (@_);
}

sub toplet {
    my $self = shift;
    my $mid2iid = $self->{mid2iid};

    if (wantarray) {
	return (map { defined $_ ? $mid2iid->{$_} : $_ } @_);
    } else {
	return $mid2iid->{$_[0]};
    }
}

=pod

=item B<toplets> (old name B<midlets>)

I<@mids> = I<$tm>->toplets

I<@mids> = I<$tm>->toplets (I<@list_of_ids>)

I<@mids> = I<$tm>->toplets (I<$selection_spec>)

This function returns toplet structures from the map. B<NOTE>: This has changed from v 1.13. Before
you got ids.

If no parameter is provided, all toplets are returned. This includes really everything also
infrastructure toplets. If an explicit list is provided as parameter, then all toplets with these
identifiers are returned.

If a search specification is used, it has to be passed in as string reference. That string contains
the selection specification using the following simple language (curly brackets mean repetition,
round bracket grouping, vertical bar alternatives):

    specification -> { ( '+' | '-' ) group }

whereby I<group> is one of the following:

=over

=item C<all>

refers to B<all> toplets in the map. This includes those supplied by the application. The list also
includes all infrastructure topics which the software maintains for completeness.

=item C<infrastructure>

refers to all toplets the infrastructure has provided. This implies that

   all - infrastructure

is everything the user (application) has supplied.

=back

Examples:

     # all toplets except those from TM::PSI
     $tm->toplets (\ '+all -infrastructure')

B<NOTE>: No attempt is made to make this list unique.

B<NOTE>: The specifications are not commutative, but are interpreted from left-to-right. So C<all
-infrastructure +infrastructure> is not the same as C<all +infrastructure -infrastructure>. In the
latter case the infrastructure toplets have been added twice, and are then deducted completely with
C<-infrastructure>.

=cut

sub midlets {
    return toplets (@_);
}

sub toplets {
    my $self = shift;
    my $mid2iid = $self->{mid2iid};

    if ($_[0]) {                                                # if there is some parameter
	if (ref ($_[0]) ) {                                     # whoohie, a search spec
            my $spec = ${$_[0]};
            my $l = []; # will be list
            while ($spec =~ s/([+-])(\w+)//) {
                if ($2 eq 'all') {
                    $l = _mod_list ($1 eq '+', $l, keys %$mid2iid);
                } elsif ($2 eq 'infrastructure') {
                    $l = _mod_list ($1 eq '+', $l, keys %{$infrastructure->{mid2iid}});
                } else {
                    $log->logdie (scalar __PACKAGE__ .": specification '$2' unknown");
                }
            }
            $log->logdie (scalar __PACKAGE__ .": unhandled specification '$spec' left") if $spec =~ /\S/;
            return map { $mid2iid->{$_} } @$l;
	} else {
	    my $m = $mid2iid;
	    return @$m{$self->tids (@_)};                        # make all these fu**ing identifiers map-absolute
	}
    } else {                                                     # if the list was empty, we assume every thing in the map
	return values %$mid2iid;
    }

sub _mod_list {
    my $pm = shift; # non-zero for +
    my $l  = shift;
    if ($pm) {
	return [ @$l, @_ ];
    } else {
	my %minus;
	@minus{ @_ } = (1) x @_;
        return [ grep { !$minus{$_} } @$l ];
    }
}
sub _mk_uniq {
    my %uniq;
    @uniq {@_} = (1) x @_;
    return keys %uniq;
}

}

=pod

=item B<tids> (old name B<mids>)

I<$mid>  = I<$tm>->tids (I<$some_id>)

I<@mids> = I<$tm>->tids (I<$some_id>, ...)

This function tries to build absolute versions of the identifiers passed in. C<undef> will be
returned if no such can be constructed. Can be used in scalar and list context.

=over

=item *

If the passed-in identifier is a relative URI, so it is made absolute by prefixing it with the map
C<baseuri> and then we look for a toplet with that internal identifier.

=item *

If the passed-in identifier is an absolute URI, where the C<baseuri> is a prefix, then that URI will
be used as internal identifier to look for a toplet.

=item *

If the passed-in identifier is an absolute URI, where the C<baseuri> is B<NOT> a prefix, then that
URI will be used as subject locator and such a toplet will be looked for.

=item *

If the passed-in identifier is a reference to an absolute URI, then that URI will be used as subject
identifier and such a toplet will be looked for.

=back

=cut

sub mids {
    return tids (@_);
}

sub tids {
    my $self    = shift;
    my $mid2iid = $self->{mid2iid};                                    # shorthand

    my @ks;
  MID:
    foreach my $k (@_) {
	if (! defined $k) {                                            # someone put in undef
	    push @ks, undef;

	} elsif (ref ($k)) {                                           # would be subject indicator ref
	    my $kk = $$k;
	    foreach my $k2 (keys %{$mid2iid}) {
		if (grep ($_ eq $kk, 
			  @{$mid2iid->{$k2}->[TM->INDICATORS]}
			  )) {
		    push @ks, $mid2iid->{$k2}->[TM->LID];              # LID points to 'canonical' internal identifier
		    next MID;
		}
	    }
	    push @ks, undef;

	} elsif (my $kk = $mid2iid->{$k}) {                            # we already have something which looks like a tid
	    push @ks, $kk->[TM->LID];                                  # give back the 'canonical' one

	} elsif ($k =~ /(^\w+:)|(^[A-F0-9]{32}$)/i) {                  # must be some other uri or assoc id, must be subject address
	    no warnings;
	    my @k2 = grep ($mid2iid->{$_}->[TM->ADDRESS] eq $k, keys %{$mid2iid});
	    push @ks,  @k2 ? $mid2iid->{$k2[0]}->[TM->LID] : undef;    # we take the first we find

	} else {                                                       # only a string, like 'aaa'
	    my $k2 = $self->{baseuri}.$k;                              # make it absolute, and...
	    push @ks, $mid2iid->{$k2}                                  # see whether there is something
                        ? $mid2iid->{$k2}->[TM->LID] : undef;          # and then take canonical LID
	}
    }
#warn "mids ".Dumper (\@_)." returning ".Dumper (\@ks);
    return wantarray ? @ks : $ks[0];
}

=pod

=item B<externalize>

I<$tm>->externalize (I<$some_id>, ...)

This function simply deletes the toplet entry for the given internal identifier(s). The function
returns all deleted toplet entries.

B<NOTE>: Assertions in which this topic is involved will B<not> be removed. Use C<consolidate> to
clean up all assertion where non-existing toplets still exist.

=cut

sub externalize {
    my $self = shift;

    my $mid2iid = $self->{mid2iid};
    my @doomed = map { delete $mid2iid->{$_} } @_;
    $self->{mid2iid} = $mid2iid; ## !! needed for Berkeley DBM recognize changes on deeper levels
    $self->{last_mod} = Time::HiRes::time;
    return @doomed;
}

=pod

=back

=head1 ASSERTIONS INTERFACE

One assertion is a record containing its own identifier, the scope, the type of the assocation, an
field whether this is an association, an occurrence or a name and then all roles and all players,
both in separate lists.

=cut

struct 'Assertion' => [
    lid         => '$',
    scope       => '$',
    type        => '$',
    kind        => '$', # redundant, but very useful
    roles       => '$',
    players     => '$',
    canon       => '$',
];

use constant {
    LID     => 0,
    SCOPE   => 1,
    TYPE    => 2,
    KIND    => 3,
    ROLES   => 4,
    PLAYERS => 5,
    CANON   => 6
};

=pod

Assertions consist of the following components:

=over

=item I<lid> (index C<LID>):

Every assertion has an identifier. It is a unique identifier generated from a canonicalized form of
the assertion itself.

=item I<scope> (index: C<SCOPE>)

This component holds the scope of the assertion.

=item I<kind> (index: C<KIND>, redundant information):

For technical reasons (read: it is faster) we distinguish between full associations (C<ASSOC>),
names (C<NAME>) and occurrences (C<OCC>).

=cut

# values for 'kind'
use constant {
    ASSOC    => 0,
    NAME     => 1,
    OCC      => 2,
};

=pod

=item I<type> (index: C<TYPE>):

The toplet id of the type of this assertion.

=item I<roles> (index: C<ROLES>):

A list reference which holds a list of toplet ids for the roles.

=item I<players> (index: C<PLAYERS>):

A list reference which holds a list of toplet IDs for the players.

=item I<canon> (index: C<CANON>):

Either C<1> or C<undef> to signal whether this assertion has been (already) canonicalized (see
L</canonicalize>). If an assertion is canonicalized, then the players and roles lists are sorted
(somehow), so that assertions can be easily compared.

=back

Obviously the lists for roles and players B<always> have the same length, so that every player
corresponds to exactly one role. If one role is played by several players, the role appears multiple
times.

As a special case, names and occurrences are mapped into assertions, by

=over

=item *

setting the I<roles> to C<thing> and C<value>,

=item *

setting the I<players> to the toplet id in question and using a L<TM::Literal> as the player for
C<value>,

=item *

using the I<type> component to store the name/occurrence type,

=item *

using as I<kind> either C<NAME> or C<OCC>

=back

Example:

   # general association
   $a = Assertion->new (type => 'is-subclass-of', 
                        roles   => [ 'subclass', 'superclass' ], 
                        players => [ 'rumsti',   'ramsti' ])


   warn $a->scope . " is the same as " . $a->[TM->SCOPE];

   # create a name
   use TM::Literal;
   $n = Assertion->new (kind    => TM->NAME,
                        type    => 'name',
                        scope   => 'us', 
                        roles   => [ 'thing', 'value' ],
                        players => [ 'rumsti', 
                                     new TM::Literal ('AAA') ]);

   # create an occurrence
   use TM::Literal;
   $n = Assertion->new (kind    => TM->OCC,
                        type    => 'occurrence',
                        scope   => 'us',
                        roles   => [ 'thing', 'value' ],
                        players => [ 'rumsti', 
                                     new TM::Literal ('http://whatever/') ]);

=head2 Special Assertions

This package adopts the following conventions to store certain assertions:

=over

=item C<is-subclass-of>

Associations of this type should have one role C<subclass> and another C<superclass>. The scope
should always be C<us>.

=item C<isa>

Associations of this type should have one role C<instance> and another C<class>. The scope should
always be C<us>.

=item C<NAME>

Assertions for names should have the C<KIND> component set to it and use the C<TYPE> component to
store the name type. The two roles to use are C<value> for the value and C<thing> for the toplet
carrying the name.

=item C<OCC>

Assertions for occurrences should have the C<KIND> component set to it and use the C<TYPE> component
to store the occurrence type. The two roles to use are C<value> for the value and C<thing> for the
toplet carrying the name.

=back

=head2 Methods

=over

=item B<assert>

I<@as> = I<$tm>->assert (I<@list-of-assertions>)

This method takes a list of assertions, canonicalizes them and then injects them into the map. If
one of the newly added assertions already existed in the map, it will be ignored.

In this process, all assertions will be completed (if fields are missing). 

=over

=item If an assertion does not have a type, it will default to C<$TM::PSI::THING>.

=item If an assertion does not have a scope, it defaults to C<$TM::PSI::US>.

=back

Then the assertion will be canonicalized (unless it already was). This implies that
non-canonicalized assertions will be modified, in that the role/player lists change.  Any assertion
not having an LID will get one.

The method returns a list of all asserted assertions.

Example:

  my $a = Assertion->new (type => 'rumsti');
  $tm->assert ($a);

B<NOTE>: Maybe the type will default to I<association> in the future.

=cut

sub assert {
    my $self = shift;
    my ($THING, $US) = ('thing', 'us');

#warn "sub $THING assert $self".ref ($self);

    my @tids;                                                  # first collect all emerging tids from the assertions
    foreach (@_) {
	unless ($_->[CANON]) {
	    push @tids, $_->[TYPE]  || $THING;
	    push @tids, $_->[SCOPE] || $US;
	    push @tids, @{$_->[ROLES]};
	    push @tids, grep { ! ref ($_) } @{$_->[PLAYERS]};
	}
    }
    @tids = $self->internalize ( map { $_ => undef } @tids);   # then convert them into proper usable tids

    my $asserts = $self->{assertions};                         # load (MLDBM kicker)
    foreach (@_) {                                             # only now use all the information to complete the assertions
	unless ($_->[CANON]) {
	    $_->[KIND]  ||= ASSOC;
	    $_->[TYPE]    = shift @tids;
	    $_->[SCOPE]   = shift @tids;
	    $_->[ROLES]   = [ map { shift @tids } @{$_->[ROLES]} ];
	    $_->[PLAYERS] = [ map { $_ = ref ($_) ? $_ : shift @tids } @{$_->[PLAYERS]}  ];

	    canonicalize (undef, $_);

	    $_->[LID]   ||= mklabel ($_);
	}
	$asserts->{$_->[LID]} = $_;
    }
    $self->{assertions} = $asserts;                            ### HACK ALERT: needed for Berkeley DBM recognize changes on deeper levels
    $self->{last_mod} = Time::HiRes::time;
    return @_;
}

=pod

=item B<retrieve>

I<$assertion>  = I<$tm>->retrieve (I<$some_assertion_id>)

I<@assertions> = I<$tm>->retrieve (I<$some_assertion_id>, ...)

This method takes a list of assertion IDs and returns the assertion(s) with the given (subject)
ID(s). If the assertion is not identifiable, C<undef> will be returned in its place. Called in list
context, it will return a list of assertion references.

=cut

sub retrieve {
    my $self    = shift;
    my $asserts = $self->{assertions};

    if (wantarray()) {
	return map { $asserts->{$_} } @_;
    } else {
	return $asserts->{$_[0]};
    }
}

=pod

=item B<asserts>

I<@assertions> = I<$tm>->asserts (I<$selection_spec>)

If a search specification is used, it has to be passed in as string reference. That string contains
the selection specification using the following simple language (curly brackets mean repetition,
round bracket grouping, vertical bar alternatives):

    specification -> { ( '+' | '-' ) group }

whereby I<group> is one of the following:

=over

=item C<all>

refers to B<all> assertions in the map. This includes those supplied by the application, but also
all predefined associations, names and occurrences.

=item C<associations>

refers to all assertions which are actually associations

=item C<names>

refers to all assertions which are actually name characteristics

=item C<occurrences>

refers to all assertions which are actually occurrences

=item C<infrastructure>

refers to all assertions the infrastructure has provided. This implies that

   all - infrastructure

is everything the user (application) has supplied.

=back

Examples:

     # all toplets except those from TM::PSI
     $tm->asserts (\ '+all -infrastructure')

     # like above, without assocs, so with names and occurrences
     $tm->asserts (\ '+all -associations')

B<NOTE>: No attempt is made to make this list unique.

B<NOTE>: The specifications are not commutative, but are interpreted from left-to-right. So C<all
-associations +associations> is not the same as C<all +associations -associations>.
C<-infrastructure>.

=cut

sub asserts {
    my $self = shift;
    my $asserts = $self->{assertions};

    if ($_[0]) {
	if (ref ($_[0])) {
	    my $spec = ${$_[0]};
	    my $l = []; # will be list
	    while ($spec =~ s/([+-])(\w+)//) {
		if ($2 eq 'all') {
		    $l = _mod_list ($1 eq '+', $l,                                      keys %$asserts);

		} elsif ($2 eq 'associations') {
		    $l = _mod_list ($1 eq '+', $l, map  { $_->[TM->LID] } 
                                                   grep { $_->[TM->KIND] == TM->ASSOC } values %$asserts);
		} elsif ($2 eq 'names') {
		    $l = _mod_list ($1 eq '+', $l, map  { $_->[TM->LID] }
                                                   grep { $_->[TM->KIND] == TM->NAME }  values %$asserts);
		} elsif ($2 eq 'occurrences') {
		    $l = _mod_list ($1 eq '+', $l, map  { $_->[TM->LID] }
                                                   grep { $_->[TM->KIND] == TM->OCC }   values %$asserts);
		} elsif ($2 eq 'infrastructure') {
		    $l = _mod_list ($1 eq '+', $l,                                      keys %{$TM::infrastructure->{assertions}} );
		} else {
		    $log->logdie (scalar __PACKAGE__ .": specification '$2' unknown");
		}
	    }
	    $log->logdie (scalar __PACKAGE__ .": unhandled specification '$spec' left") if $spec =~ /\S/;
	    return map { $asserts->{$_} } @$l;
	} else {
	    return $asserts->{@_};
	}
    } else {
	return values %$asserts;
    }
}

=pod

=item B<is_asserted>

I<$bool> = I<$tm>->is_asserted (I<$a>)

This method will return C<1> if the passed-in assertion exists in the store. The assertion will be
canonicalized before checking, but no defaults will be added if parts are missing.

=cut

sub is_asserted {
    my $self  = shift;
    my $a     = shift;

    unless ($a->[CANON]) {
	absolutize   ($self, $a);
	canonicalize (undef, $a);
	$a->[TM->LID] = mklabel ($a);
    }
    return $self->{assertions}->{ $a->[TM->LID] };
}

=pod

=item B<retract>

I<$tm>->retract (I<@list_of_assertion_ids>)

This methods expects a list of assertion IDs and will remove the assertions from the map. If an ID
is bogus, it will be ignored.

B<NOTE>: Only these particular assertions will be deleted. Any toplets mentioned in these assertions
will remain. Use C<consolidate> to remove unnecessary toplets.

=cut

sub retract {
  my $self = shift;

# TODO: does delete $self->{assertions}->{@_} work?
  my $assertions = $self->{assertions};
  map { 
      delete $assertions->{$_} # delete them from the primary store
  } @_; 
  $self->{assertions} = $assertions; ##!! needed for Berkeley DBM recognize changes on deeper levels
  $self->{last_mod} = Time::HiRes::time;
}

=pod

=item B<match>, B<match_forall>, B<match_exists>

I<@assertions> = I<$tm>->match (TM->FORALL [ , I<search-spec> ] );

I<@assertions> = I<$tm>->match (TM->EXISTS [ , I<search-spec> ] );

I<@assertions> = I<$tm>->match_forall ( [ I<search-spec> ] );

I<@assertions> = I<$tm>->match_exists ( [ I<search-spec> ] );

These methods take a search specification and return matching assertions. The result list contains
references to the assertions themselves, not to copies. You can change the assertions themselves on
your own risk (read: better not do it).

For C<match>, if the constant C<FORALL> is used as first parameter, this method returns a list of
B<all> assertions in the store following the search specification. If the constant C<EXISTS> is
used, the method will return a non-empty value if B<at least one> can be found. Calling the more
specific C<match_forall> is the same as calling C<match> with C<FORALL>. Similar for
C<match_exists>.

B<NOTE>: C<EXISTS> is not yet implemented.

For I<search specifications> there are two alternatives:

=over

=item Generic Search

Here the search specification is a hash with the same fields as for the constructor of an assertion:

Example:

   $tm->match (TM->FORALL, type    => '...',
                           scope   => '...,
                           roles   => [ ...., ....],
                           players => [ ...., ....]);

Any combination of assertion components can be used, all are optional, with the only constraint that
the number of roles must match that for the players. All involved IDs should be absolutized before
matching. If you use C<undef> for a role or a player, then this is interpreted as I<dont-care>
(wildcard). 

=item Specialized Search

The implementation also understands a number of specialized search specifications. These are
listed in L<TM::Axes>.

=back

B<NOTE>: Some combinations will be very fast, while others quite slow. If you experience
problems, then it might be time to think about indexing (see L<TM::Index>).

B<NOTE>: For the assertion type and the role subclassing is honored.

=cut

use constant {
    EXISTS => 1,
    FORALL => 0
    };

our %exists_handlers = (); # they should be written at some point

our %forall_handlers = (
			'' => {
			    code => sub { # no params => want all of them
				my $self   = shift;
				return values %{$self->{assertions}};
			    },
			    desc => 'returns all assertions',
			    params => {},
			},

			'nochar' => {
			    code => sub {
				my $self   = shift;
				return
				    grep ($_->[KIND] <= ASSOC,
					  values %{$self->{assertions}});
			    },
			    desc   => 'returns all associations (so no names or occurrences)',
			    params => { 'nochar' => '1'}
			},
#-- taxos ---------------------------------------------------------------------------------------------
			'subclass.type' => {
			    code => sub {
				my $self   = shift;
				my $st     = shift;
				my ($ISSC, $SUBCLASS) = ('is-subclass-of', 'subclass');
				return () unless shift eq $ISSC;
				return
				    grep ( $self->is_x_player   ($_, $st, $SUBCLASS),
 				    grep ( $_->[TYPE] eq $ISSC,
				    values %{$self->{assertions}}));
			    },
			    desc => 'returns all assertions where there are subclasses of a given toplet',
			    params => { 'type' => 'is-subclass-of', subclass => 'which toplet should be the superclass'},
			    key => sub {
				my $self = shift;
				my $a    = shift;
				my ($ISSC, $SUBCLASS) = ('is-subclass-of', 'subclass');
				return "subclass.type:". ($self->get_x_players   ($a, $SUBCLASS))[0] . '.' . $ISSC;
			    },
			    enum => sub {
				my $self = shift;
				my ($ISSC) = ('is-subclass-of');
				return
 				    grep { $_->[TYPE] eq $ISSC }
				    values %{$self->{assertions}};
			    }
			},
			
			'superclass.type' => {
			    code => sub {
				my $self   = shift;
				my $st     = shift;
				my ($ISSC, $SUPERCLASS) = ('is-subclass-of', 'superclass');
				return () unless shift eq $ISSC;
				return
				    grep ( $self->is_x_player   ($_, $st, $SUPERCLASS),
				    grep ( $_->[TYPE] eq $ISSC,
				    values %{$self->{assertions}}));
			    },
			    desc => 'returns all assertions where there are superclasses of a given toplet',
			    params => { 'type' => 'is-subclass-of', superclass => 'which toplet should be the subclass'},
			    key => sub {
				my $self = shift;
				my $a    = shift;
				my ($ISSC, $SUPERCLASS) = ('is-subclass-of', 'superclass');
				return "superclass.type:". ($self->get_x_players   ($a, $SUPERCLASS))[0] . '.' . $ISSC;
			    },
			    enum => sub {
				my $self = shift;
				my ($ISSC) = ('is-subclass-of');
				return
 				    grep { $_->[TYPE] eq $ISSC }
				    values %{$self->{assertions}};
			    }
			},

			'class.type' => {
			    code => sub {
				my $self   = shift;
				my $t      = shift;
				my ($ISA, $CLASS) = ('isa', 'class');
				return () unless shift eq $ISA;
				return
				    grep ( $self->is_x_player   ($_, $t, $CLASS),
				    grep ( $_->[TYPE] eq $ISA,
				    values %{$self->{assertions}}));
			    },
			    desc => 'returns all assertions where there are instances of a given toplet',
			    params => { type => 'isa', class => 'which toplet should be the class'},
			    key => sub {
				my $self = shift;
				my $a    = shift;
				my ($ISA, $CLASS) = ('isa', 'class');
				return "class.type:". ($self->get_x_players   ($a, $CLASS))[0] . '.' . $ISA;
			    },
			    enum => sub {
				my $self = shift;
				my ($ISA) = ('isa');
				return
 				    grep { $_->[TYPE] eq $ISA }
				    values %{$self->{assertions}};
			    }
			},

			'instance.type' => {
			    code => sub {
				my $self   = shift;
				my $i      = shift;
				my ($ISA, $INSTANCE) = ('isa', 'instance');
				return () unless shift eq $ISA;
				return
				    grep ( $self->is_x_player   ($_, $i, $INSTANCE),
				    grep ( $_->[TYPE] eq $ISA,
				    values %{$self->{assertions}}));
			    },
			    desc => 'returns all assertions where there are classes of a given toplet',
			    params => { type => 'isa', instance => 'which toplet should be the instance'},
			    key => sub {
				my $self = shift;
				my $a    = shift;
				my ($ISA, $INSTANCE) = ('isa', 'instance');
				return "instance.type:". ($self->get_x_players   ($a, $INSTANCE))[0] . '.' . $ISA;
			    },
			    enum => sub {
				my $self = shift;
				my ($ISA) = ('isa');
				return
 				    grep { $_->[TYPE] eq $ISA }
				    values %{$self->{assertions}};
			    }
			},
#--
			'char.irole' => {
			    code => sub {
				warn "char.irole is deprecated. use char.topic instead";
				my $self   = shift;
				my $topic  = $_[1];
				return undef unless $topic;
				return
				    grep ($self->is_player ($_, $topic) &&                              # TODO: optimize this grep away (getting chars is expensive)
				          NAME <= $_->[KIND] && $_->[KIND] <= OCC,
				    values %{$self->{assertions}});
			    },
			    desc => 'deprecated: return all assertions which are characteristics for a given toplet',
			    params => { char => '1', irole => 'the toplet for which characteristics are sought'}
			},

			'char.topic' => {
			    code => sub {
				my $self   = shift;
				my $topic  = $_[1];
				return
				    grep (NAME <= $_->[KIND] && $_->[KIND] <= OCC &&
				          $_->[PLAYERS]->[0] eq $topic,                                   # first role is always the 'thing'
				    values %{$self->{assertions}});
			    },
			    desc => 'return all assertions which are characteristics for a given toplet',
			    params => { char => '1', topic => 'the toplet for which characteristics are sought'},
			    key => sub {
				my $self = shift;
				my $a    = shift;
				return "char.topic:1.". $a->[PLAYERS]->[0];
			    },
			    enum => sub {
				my $self = shift;
				return
				    grep { $_->[KIND] != ASSOC }
				    values %{ $self->{assertions} };
			    }
			},

			'char.value' => {
			    code => sub {
				my $self   = shift;
				my $value  = $_[1];
				return
				    grep (NAME <= $_->[KIND] && $_->[KIND] <= OCC &&
					  $_->[PLAYERS]->[1]->[0] eq $value->[0] &&                       # second role is always the value
					  $_->[PLAYERS]->[1]->[1] eq $value->[1],                         # test value AND type
				    values %{$self->{assertions}});
			    },
			    desc => 'return all assertions which are characteristics for some topic of a given value',
			    params => { char => '1', value => 'the value for which all characteristics are sought'},
			    key => sub {
                                my $self = shift;
                                my $a    = shift;
                                return "char.value:1.". $a->[PLAYERS]->[1]->[0] . '.' . $a->[PLAYERS]->[1]->[1];
                            },
                            enum => sub {
                                my $self = shift;
                                return
                                    grep { $_->[KIND] != ASSOC }
				    values %{ $self->{assertions} };
                            }
			},

			'char.type' => {
			    code => sub {
				my $self   = shift;
				my $type   = $_[1];
				return
				    grep { $self->is_subclass ($_->[TYPE], $type ) }
				    grep { $_->[KIND] != ASSOC }
				    values %{$self->{assertions}};
			    },
			    desc => 'return all assertions which are characteristics for some given type',
			    params => { char => '1', type => 'the characteristic type'},
			    key => sub {
                                my $self = shift;
                                my $a    = shift;
                                return "char.type:1.". $a->[TYPE];
                            },
                            enum => sub {
                                my $self = shift;
                                return
                                    grep { $_->[KIND] != ASSOC }
				    values %{ $self->{assertions} };
                            }
			},

			'char.type.value' => {
			    code => sub {
				my $self   = shift;
				my $type   = $_[1];
				my $value  = $_[2];
				return
				    grep { $self->is_subclass ($_->[TYPE], $type ) }
				    grep (NAME <= $_->[KIND] && $_->[KIND] <= OCC &&
					  $_->[PLAYERS]->[1]->[0] eq $value->[0] &&                       # second role is always the value
					  $_->[PLAYERS]->[1]->[1] eq $value->[1],                         # test value AND type
				    values %{$self->{assertions}});
			    },
			    desc => 'return all assertions which are characteristics for some topic of a given value for some given type',
			    params => { char => '1', type => 'the characteristic type', value => 'the value for which all characteristics are sought'},
			    key => sub {
                                my $self = shift;
                                my $a    = shift;
                                return "char.type.value:1.". $a->[TYPE] . '.' . $a->[PLAYERS]->[1]->[0] . '.' . $a->[PLAYERS]->[1]->[1];
                            },
                            enum => sub {
                                my $self = shift;
                                return
                                    grep { $_->[KIND] != ASSOC }
				    values %{ $self->{assertions} };
                            }
			},

			'char.topic.type' => {
			    code => sub {
				my $self   = shift;
				my $topic  = $_[1];
				my $type   = $_[2];
				return
				    grep ($self->is_subclass ($_->[TYPE], $type),
				    grep ($_->[PLAYERS]->[0] eq $topic &&                         # first role is always the 'thing'
					  NAME <= $_->[KIND] && $_->[KIND] <= OCC,
				    values %{$self->{assertions}}));
			    },
			    desc => 'return all assertions which are a characteristic of a given type for a given topic',
			    params => { char => '1', topic => 'the toplet for which these characteristics are sought', type => 'type of characteristic' },
			    key => sub {
                                my $self = shift;
                                my $a    = shift;
                                return "char.topic.type:1.". $a->[PLAYERS]->[0] . '.' . $a->[TYPE] ;
                            },
                            enum => sub {
                                my $self = shift;
                                return
                                    grep { $_->[KIND] != ASSOC }
				    values %{ $self->{assertions} };
                            }
			},

			'lid' => {
			    code => sub {
				my $self   = shift;
				my $lid    = $_[1];
				return
				    $self->{assertions}->{$lid} || ();
			    },
			    desc => 'return one particular assertions with a given ID',
			    params => { lid => 'the ID of the assertion' }
			},

			'type' => {
			    code => sub {
				my $self   = shift;
				my $type   = $_[0];
				return 
				    grep ($self->is_subclass ($_->[TYPE], $type),
				    values %{$self->{assertions}});
			    },
			    desc => 'return all assertions with a given type',
			    params => { type => 'the type of the assertion' }
			},
			
			'iplayer' => {
			    code => sub {
				my $self   = shift;
				my $ip     = $_[0];
				return 
				    grep ($self->is_player ($_, $ip), 
				    values %{$self->{assertions}});
			    },
			    desc => 'return all assertions where a given toplet is a player',
			    params => { iplayer => 'the player toplet' }
			},

			'iplayer.type' => {
			    code => sub {
				my $self      = shift;
				my ($ip, $ty) = @_;
				return 
				    grep ($self->is_player ($_, $ip)          &&
					  $self->is_subclass ($_->[TYPE], $ty),
				    values %{$self->{assertions}});
			    },
			    desc => 'return all assertions of a given type where a given toplet is a player',
			    params => { iplayer => 'the player toplet', type => 'the type of the assertion' }
			},

			'iplayer.irole' => {
			    code => sub {
				my $self      = shift;
				my ($ip, $ir) = @_;
				return 
				    grep ($self->is_player ($_, $ip, $ir), 
				    values %{$self->{assertions}});
			    },
			    desc => 'return all assertions where a given toplet is a player of a given role',
			    params => { iplayer => 'the player toplet', irole => 'the role toplet (incl subclasses)' },
			},

			'iplayer.irole.type' => {
			    code => sub {
				my $self           = shift;
				my ($ip, $ir, $ty) = @_;
				return 
				    grep ($self->is_subclass ($_->[TYPE], $ty) && 
					  $self->is_player ($_, $ip, $ir), 
				    values %{$self->{assertions}});
			    },
			    desc => 'return all assertions of a given type where a given toplet is a player of a given role',
			    params => { iplayer => 'the player toplet', 
					irole => 'the role toplet (incl subclasses)',
					type => 'the type of the assertion' }
			},

			'irole.type' => {
			    code => sub {
				my $self      = shift;
				my ($ir, $ty) = @_;
				return
				    grep ($self->is_role ($_, $ir)             &&
					  $self->is_subclass ($_->[TYPE], $ty),
				    values %{$self->{assertions}});
			    },
			    desc => 'return all assertions of a given type where there is a given role',
			    params => { irole => 'the role toplet (incl subclasses)', type => 'the type of the assertion' }
			},

			'irole' => {
			    code => sub {
				my $self      = shift;
				my ($ir)      = @_;
				return
				    grep ($self->is_role ($_, $ir),
				    values %{$self->{assertions}});
			    },
			    desc => 'return all assertions where there is a given role',
			    params => { irole => 'the role toplet (incl subclasses)' }
			},

			'aplayer.arole.brole.type' => {
			    code => sub {
				my $self   = shift;
				my ($ap, $ar, $br, $ty) = @_;
				return
				    grep ( $self->is_role     ($_, $br),
				    grep ( $self->is_player   ($_, $ap, $ar),
				    grep ( $self->is_subclass ($_->[TYPE], $ty),
				    values %{$self->{assertions}})));
			    },
			    desc => 'return all assertions of a given type where a given toplet plays a given role and there exist another given role',
			    params => { aplayer => 'the player toplet for the arole', 
					arole => 'the role toplet (incl subclasses) for the aplayer',
					brole => 'the other role toplet (incl subclasses)',
					type => 'the type of the assertion'
					}
			},
			
			'aplayer.arole.bplayer.brole.type' => {
			    code => sub {
				my $self  = shift;
				my ($ap, $ar, $bp, $br, $ty) = @_;
				return
				    grep ( $self->is_player ($_, $bp, $br),
			            grep ( $self->is_player ($_, $ap, $ar),
			            grep ( $self->is_subclass ($_->[TYPE], $ty),
				    values %{$self->{assertions}})));
			    },
			    desc => 'return all assertions of a given type where a given toplet plays a given role and there exist another given role with another given toplet as player',
			    params => { aplayer => 'the player toplet for the arole', 
					arole => 'the role toplet (incl subclasses) for the aplayer',
					brole => 'the other role toplet (incl subclasses)',
					bplayer => 'the player for the brole',
					type => 'the type of the assertion'
					}
			},

			'anyid' => {
			    code => sub {
				my $self   = shift;
				my $lid    = shift;
				return
				    grep (
				     $self->is_subclass ($_->[TYPE], $lid) ||   # probably not a good idea
					  $_->[TYPE]  eq         $lid           ||   # this seems a bit safer
					  $_->[SCOPE] eq         $lid           ||
					  $self->is_player ($_, $lid)           ||
					  $self->is_role   ($_, $lid)           ,
				    values %{$self->{assertions}});
			    },
			    desc => 'return all assertions where a given toplet appears somehow',
			    params => { anyid => 'the toplet' }
			}
		    
			);

sub _allinone {
    my $self     = shift;
    my $exists   = shift;
    my $template = Assertion->new (@_);                              # we create an assertion on the fly
#warn "allinone ".Dumper $template;
    $self->absolutize   ($template);  
#warn "allinone2".Dumper $template;
    $self->canonicalize ($template);                                # of course, need to be canonicalized
#warn "allinone3".Dumper $template;

#warn "in store match template ".Dumper $template;
    my @mads;
  ASSERTION:
    foreach my $m (values %{$self->{assertions}}) {                 # arbitrary AsTMa! queries TBD, can be faster as well
	
	next if defined $template->[KIND]  &&                       # is kind defined
                $m->[KIND]  ne $template->[KIND];                   #    and does it match?
#warn "after kind";
	next if defined $template->[SCOPE] && 
                $m->[SCOPE] ne $self->tids ($template->[SCOPE]);    # does scope match?
#warn "after scope";
	next if defined $template->[TYPE]  &&                       
                !$self->is_subclass ($m->[TYPE], $self->tids ($template->[TYPE]));         # does type match (including subclassing)?
#warn "after type";
			       
	my ($rm, $rc) = ($m->[ROLES],   $template->[ROLES]);
	push @mads, $m and next ASSERTION             if ! @$rc;     # match ok, if we have no roles
#warn "after push roles";
	next ASSERTION if @$rm != @$rc;                              # quick check: roles must be of equal length
#warn "after roles";
	my ($pm, $pc) = ($m->[PLAYERS], $template->[PLAYERS]);
	push @mads, $m and next ASSERTION             if ! @$pc;     # match ok, if we have no players
	next if @$pm != @$pc;                                        # quick check: roles and players must be of equal length
#warn "after players equal length ".Dumper ($pm, $pc);

#######	$pm = [ $self->tids (@$pm) ];                                
	for (my $i = 0; $i < @{$rm}; $i++) {                         # order is canonicalized, would not want to test all permutations
#warn "before role tests : is $rm->[$i] subclass of $rc->[$i]?";
	    next ASSERTION if defined $rc->[$i] && !$self->is_subclass ($rm->[$i], $rc->[$i]);              # go to next assertion if that does not match
#warn "after role ok";
	    next ASSERTION if defined $pc->[$i] && $pm->[$i] ne $pc->[$i];
	}
#warn "after players  roles";
	return (1) if $exists;                                       # with exists that's it
	push @mads, $m;                                              # with forall we do continue to collect
    }
#warn "we return ".Dumper \@mads;
    return @mads;                                                    # and return what we got
}

#sub _fat_mama {
#    use Proc::ProcessTable;
#    my $t = new Proc::ProcessTable;
##warn Dumper [ $t->fields ]; exit;
#    my ($me) = grep {$_->pid == $$ }  @{ $t->table };
##warn "size: ".  $me->size;
#    return $me->size / 1024.0 / 1024.0;
#}



sub match_forall {
    my $self   = shift;
    my %query  = @_;
#warn "forall ".Dumper \%query;

    my @skeys = sort keys %query;                                                           # all fields make up the key
    my $skeys = join ('.', @skeys);
    my @svals = map { $query{$_} } @skeys;

    if (my $idxs = $self->{indices}) {                                                      # there are indices to help me
	my $key   = "$skeys:" . join ('.', @svals);
	foreach my $idx (@$idxs) {
	    if (my $lids  = $idx->is_cached ($key)) {                                       # if result was cached, lets take the list of lids
#		warn "using cached for $key". Dumper $lids;
		return map { $self->{assertions}->{$_} } @$lids;                            # and return fully fledged
	    }
	}
	# obviously we have not found it                                                    # not defined means not cache => recompute
	my @as = _dispatch_forall ($self, \%query, $skeys, @svals);                         # do it the hard way
	$idxs->[0]->do_cache ($key, [ map { $_->[LID] } @as ]);                             # save it for later, simply use the first [0]
	return @as;
    } else {                                                                                # no cache, let's do the ochsentour
	return _dispatch_forall ($self, \%query, $skeys, @svals);
    }

sub _dispatch_forall {
    my $self  = shift;
    my $query = shift;
    my $skeys = shift;

    if (my $handler = $forall_handlers{$skeys}) {                                           # there is a constraint and we have a handler
	return &{$handler->{code}} ($self, @_); 
    } else {                                                                                # otherwise
	return _allinone ($self, 0, %$query);                                               # we use a generic handler, slow but should do the trick
    }
}

}

sub match_exists {
    my $self   = shift;
    my %query  = @_;

#warn "exists ".Dumper $query;

    my @skeys = sort keys %query;                                                           # all fields make up the key
    my $skeys = join ('.', @skeys);

#warn "keys for this $skeys";
    if (my $handler = $exists_handlers{$skeys}) {                                           # there is a constraint and we have a handler
	return &{$handler->{code}} ($self, map { $query{$_} } @skeys); 
    } else {                                                                                # otherwise
	return _allinone ($self, 1, %query);                                                # we use a generic handler, slow but should do the trick
    }
}

sub match {
    my $self   = shift;
    my $exists = shift; # FORALL or EXIST, DOES NOT work yet

    return $exists ? match_exists ($self, @_) : match_forall ($self, @_);
}


=pod

=back

=head2 Role Retrieval

=over

=item B<is_player>, B<is_x_player>

I<$bool> = is_player   (I<$tm>, I<$assertion>, I<$player_id>, [ I<$role_id> ])

I<$bool> = is_x_player (I<$tm>, I<$assertion>, I<$player_id>, [ I<$role_id> ])

This function returns C<1> if the identifier specified by the C<player_id> parameter plays any role
in the assertion provided as C<assertion> parameter.

If the C<role_id> is provided as third parameter then it must be exactly this role (or any subclass
thereof) that is played. The 'x'-version is using equality instead of 'subclassing' ('x' for
"exact").

=cut

sub is_player {
    my $self = shift;
    my $m    = shift;

#    warn "is_player ".Dumper \@_;
#    warn "caller: ". Dumper [ caller ];
#    foreach (0..0) {
#	warn "  ".join (' ---- ', caller($_));
#    }

    my $p = shift;# or die "must specify valid player: ".Dumper ([ $m ])." and role is ".shift;
#
#    warn "after shifting player '$p'";
    my $r = shift; # may be undefined

    $log->logdie ("must specify a player '$p' for role '$r'") unless $p;

    if ($r) {
	my ($ps, $rs) = ($m->[PLAYERS], $m->[ROLES]);

	for (my $i = 0; $i < @$ps; $i++) {
	    next unless $ps->[$i] eq $p;
	    next unless $self->is_subclass ($rs->[$i], $r);
	    return 1;
	}
    } else {
	return 1 if grep ($_ eq $p, @{$m->[PLAYERS]});
    }
    return 0;
}

sub is_x_player {
    my $self = shift;
    my $m = shift;
    my $p = shift or $log->logdie ("must specify x-player: ".Dumper ([ $m ]));
    my $r = shift; # may be undefined

    if ($r) {
	my ($ps, $rs) = ($m->[PLAYERS], $m->[ROLES]);

	for (my $i = 0; $i < @$ps; $i++) {
	    next unless $ps->[$i] eq $p;
	    next unless $rs->[$i] eq $r;
	    return 1;
	}
    } else {
	return 1 if grep ($_ eq $p, @{$m->[PLAYERS]});
    }
    return 0;
}

=pod

=item B<get_players>, B<get_x_players>

I<@player_ids> = get_players   (I<$tm>, I<$assertion>, [ I<$role_id> ])

I<@player_ids> = get_x_players (I<$tm>, I<$assertion>, I<$role_id>)

This function returns the player(s) for the given role. If the role is not provided all players are
returned.

The "x" version does not honor subclassing.

=cut

sub get_players {
    my $self = shift;
    my $a = shift;
    my $r = shift;
    
    return @{ $a->[PLAYERS] } unless $r;
    my ($ps, $rs) = ($a->[PLAYERS], $a->[ROLES]);
    
    my @ps;
    for (my $i = 0; $i < @$ps; $i++) {
	next unless $self->is_subclass ($rs->[$i], $r);
	push @ps, $ps->[$i];
    }
    return @ps;
}

sub get_x_players {
    my $self = shift;
    my $a = shift;
    my $r = shift;

    my ($ps, $rs) = ($a->[PLAYERS], $a->[ROLES]);
    
    my @ps;
    for (my $i = 0; $i < @$ps; $i++) {
	next unless $rs->[$i] eq $r;
	push @ps, $ps->[$i];
    }
    return @ps;
}

=pod

=item B<is_role>, B<is_x_role>

I<$bool> = is_role   (I<$tm>, I<$assertion>, I<$role_id>)

I<$bool> = is_x_role (I<$tm>, I<$assertion>, I<$role_id>)

This function returns C<1> if the C<role_id> is a role in the assertion provided. The "x" version of
this function does not honor subclassing.

=cut

sub is_role {
    my $self = shift;
    my $m    = shift;
    my $r    = shift or $log->logdie ("must specify role: ".Dumper ([ $m ]));

    return 1 if grep ($self->is_subclass ($_, $r), @{$m->[ROLES]});
}

sub is_x_role {
    my $self = shift;
    my $m    = shift;
    my $r    = shift or $log->logdie ("must specify role: ".Dumper ([ $m ]));

    return 1 if grep ($_ eq $r, @{$m->[ROLES]});
}

=pod

=item B<get_roles>

I<@role_ids> = get_roles (I<$tm>, I<$assertion>, I<$player>)

This function returns a list of roles a particular player plays in a given assertion.

=cut

sub get_roles {
    my $self = shift;
    my $a = shift;
    my $p = shift; # the player

    my ($ps, $rs) = ($a->[PLAYERS], $a->[ROLES]);
    
    my @rs;
    for (my $i = 0; $i < @$ps; $i++) {
	next unless $ps->[$i] eq $p;
	push @rs, $rs->[$i];
    }
    return @rs;
}

=pod

=item B<get_role_s>

I<@role_ids> = @{ get_role_s (I<$tm>, I<$assertion>) }

This function extracts a reference to the list of role identifiers.

=cut

sub get_role_s {
    my $self = shift;
    my $a = shift;
    return $a->[ROLES];
}

=pod

=back


=head2 Auxiliary Functions

=over

=item B<absolutize>

I<$assertion> = absolutize (I<$tm>, I<$assertion>)

This method takes one assertion and makes sure that all identifiers in it (for the type, the scope
and all the role and players) are made absolute for the context map. It returns this very assertion.
It will not touch canonicalized assertions.

=cut

sub absolutize {
    my $self = shift;
    my $a    = shift;

    return $a if $a->[CANON];                                                                 # skip it if we are already canonicalized
#warn "in abosl ".Dumper $a;
    $a->[TYPE]    =            tids ($self,         $a->[TYPE])    if $a->[TYPE];
    $a->[SCOPE]   =            tids ($self,         $a->[SCOPE])   if $a->[SCOPE];

    map { $_ =                 tids ($self, $_) } @{$a->[ROLES]}   if $a->[ROLES];            # things which are references, we will keep
    map { $_ = ref ($_) ? $_ : tids ($self, $_) } @{$a->[PLAYERS]} if $a->[PLAYERS];          # the others are treated as ids (could be literal references!)
#warn "after abosl ".Dumper $a;
    return $a;
}

=pod

=item B<canonicalize>

I<$assertion> = canonicalize (I<$tm>, I<$assertion>)

This method takes an assertion and reorders the roles (together with their respective players) in a
consistent way. It also makes sure that the KIND is defined (defaults to C<ASSOC>), that the type is
defined (defaults to C<THING>) and that all references are made absolute LIDs. Finally, the field
C<CANON> is set to 1 to indicate that the assertion is canonicalized.

The function will not do anything if the assertion is already canonicalized.  The component C<CANON>
is set to C<1> if the assertion has been canonicalized.

Conveniently, the function returns the same assertion, albeit a maybe modified one.

TODO: remove map parameter, it is no longer necessary

=cut

sub canonicalize {
    my $self = shift;
    my $s    = shift;
#warn "in canon ".Dumper $s;
#warn "using LIDs ".Dumper $LIDs;

    return $s if $s->[CANON];                                  # skip it if we are already canonicalized

# reorder role/players canonically
    my $rs = $s->[ROLES];
    my $ps = $s->[PLAYERS];
    my @reorder = (0..$#$ps);                                  # create 0, 1, 2, ..., how many roles
#warn @reorder;
    # sort according to roles (alphanum) and at ties according to players on position $a, $b
    @reorder = sort { $rs->[$a] cmp $rs->[$b] || $ps->[$a] cmp $ps->[$b] } @reorder;
#warn @reorder;
    $s->[ROLES]   = [ map { $rs->[$_] } @reorder ];
    $s->[PLAYERS] = [ map { $ps->[$_] } @reorder ];
# we are done (almost)
    $s->[CANON]   = 1;

#warn "in canon return ".Dumper $s;
    return $s;
}

# =pod

# =item B<mklabel>

# I<$hash> = mklabel (I<$assertion>);

# For internal optimization all characteristics have an additional HASH component which can be used to
# maintain indices. This function takes a assertion and computes an MD5 hash and sets the C<HASH>
# component if that is not yet defined.

# Such a hash only makes sense if the assertion is canonicalized, otherwise an exception is raised.

# Example:

#     my $a = Assertion->new (lid => 'urn:x-rho:important');
#     print "this uniquely (well) identifies the assertion ". mklabel ($a);

# =cut

sub mklabel {
  my $a = shift;
  $log->logdie ("refuse to hash non canonicalized assertion") unless $a->[CANON];
  use Digest::MD5 qw(md5_hex);
  return md5_hex ($a->[SCOPE], $a->[TYPE], @{$a->[ROLES]}, map { ref ($_) ? join ("", @$_) : $_ } @{$a->[PLAYERS]});  # recompute the hash if necessary
#                                                                           ^^^^^^^^^^^^^^                            # this is a literal value
#                                                                                            ^^                       # this is for a normal identifier
}

=pod

=back

=head1 TAXONOMICS AND SUBSUMPTION

The following methods provide useful basic, ontological functionality around transitive subclassing
between classes and instance/type relationships.

B<NOTE>: Everything is a subclass of C<thing> (changed in v1.35).

B<NOTE>: Everything is an instance of C<thing>.

B<NOTE>: See L<TM::PSI> for predefined things.

=head2 Boolean Methods

=over

=item B<is_subclass>

I<$bool> = I<$tm>->is_subclass (I<$superclass_id>, I<$subclass_id>)

This function returns C<1> if the first parameter is a (transitive) superclass of the second,
i.e. there is an assertion of type I<is-subclass-of> in the context map. It also returns C<1> if the
superclass is a $TM::PSI::THING or if subclass and superclass are the same (reflexive).

=cut

sub is_subclass {
    my $self  = shift;
    my $class = shift;
    my $super = shift;

    return 1 if $class eq $super;                                            # we always assume that A subclasses A

    my ($ISA, $US, $THING, $SUBCLASSES, $SUBCLASS, $SUPERCLASS, $INSTANCE, $CLASS) =
	('isa', 'us', 'thing', 'is-subclass-of', 'subclass', 'superclass', 'instance', 'class');

#warn "is_subclass?: class $class   super $super , thing $THING, $SUBCLASSES, $SUPERCLASS";
    return 1 if $super eq $THING;                                            # everything subclasses thing
# but not if the class is one of the predefined things, yes, there is a method to this madness
    return 0 if $class eq $ISA;
    return 0 if $class eq $US;
    return 0 if $class eq $THING;                                            # thing would only subclass itself and that is covered above
    return 0 if $class eq $SUBCLASSES;
    return 0 if $class eq $SUBCLASS;
    return 0 if $class eq $SUPERCLASS;
    return 0 if $class eq $INSTANCE;
    return 0 if $class eq $CLASS;
#    # see whether there is an assertion that we have a direct subclasses relationship between the two

# This would be an optimization, but this does not go through match
#    return 1 if $self->is_asserted (Assertion->new (scope   => $US,                          # TODO OPTIMIZE
#						    type    => $SUBCLASSES, 
#						    roles   => [ $SUBCLASS, $SUPERCLASS ],
#						    players => [ $class,    $super ])
#				    );
    # if we still do not have a decision, we will check all super types of $class and see (recursively) whether we can establish is-subclass-of
    return 1 if grep ($self->is_subclass ($_, $super),                       # check all of the intermediate type whether there is a transitive relation
		      map { $self->get_x_players ($_, $SUPERCLASS) }         # find the superclass player there => intermediate type
		      $self->match_forall (type       => $SUBCLASSES,
					   subclass   => $class)
		      );
    return 0;                                                                # ok, we give up now
}

=pod

=item B<is_a>

I<$bool> = I<$tm>->is_a (I<$something_lid>, I<$class_lid>)

This method returns C<1> if the thing referenced by the first parameter is an instance of the class
referenced by the second. The method honors transitive subclassing.

=cut

sub is_a {
    my $self    = shift;
    my $thingie = shift;
    my $type    = shift;                                                         # ok, what class are looking at?

    my ($ISA, $CLASS, $THING) = ('isa', 'class', 'thing');

#warn "isa thingie $thingie class $type";

    return 1 if $type eq $THING and                                              # is the class == 'thing' and
                $self->{mid2iid}->{$thingie};                                    # and does the thingie exist?

    my ($m) = $self->retrieve ($thingie);
    return 1 if $m and                                                           # is it an assertion ? and...
	        $self->is_subclass ($m->[TYPE], $type);                          # is the assertion type a subclass?

    return 1 if grep ($self->is_subclass ($_, $type),                            # check all of the intermediate type whether there is a transitive relation
		         map { $self->get_players ($_, $CLASS) }                 # find the class player there => intermediate type
		             $self->match_forall (type => $ISA, instance => $thingie)
		      );
    return 0;
}

=pod

=back

=head2 List Methods

=over

=item B<subclasses>, B<subclassesT>

I<@lids> = I<$tm>->subclasses  (I<$lid>, ...)

I<@lids> = I<$tm>->subclassesT (I<$lid>, ...)

C<subclasses> returns all B<direct> subclasses of the toplet identified by C<$lid>. If the toplet does
not exist, the list will be empty. C<subclassesT> is a variant which honors the transitive
subclassing (so if A is a subclass of B and B is a subclass of C, then A is also a subclass of C).

Duplicates are suppressed.

=cut

sub subclasses {
    my $self = shift;

    my ($SUBCLASSES) = ('is-subclass-of');
    my @sc = map { $_->[PLAYERS]->[0] }
             map { $self->match_forall (type => $SUBCLASSES, superclass => $_) }
             @_;
    my %dup;
    return map { $dup{$_}++ ? () : $_ } @sc;
}

sub subclassesT {
    my $self = shift;

    my @sc = map { $self->subclasses ($_) } @_;
    push @sc, @_, map { $self->subclassesT ($_) } @sc; # laziness equals recursion
    my %dup;
    return map { $dup{$_}++ ? () : $_ } @sc; 
}

=pod

=item B<superclasses>, B<superclassesT>

I<@lids> = I<$tm>->superclasses  (I<$lid>, ...)

I<@lids> = I<$tm>->superclassesT (I<$lid>, ...)

The method C<superclasses> returns all direct superclasses of the toplet identified by C<$lid>. If
the toplet does not exist, the list will be empty. C<superclassesT> is a variant which honors
transitive subclassing.

Duplicates are suppressed.

=cut

sub superclasses {
    my $self = shift;

    my ($SUBCLASSES) = ('is-subclass-of');
    my @sc = map { $_->[PLAYERS]->[1] }
             map { $self->match_forall (type => $SUBCLASSES, subclass => $_) }
             @_;
    my %dup;
    return map { $dup{$_}++ ? () : $_ } @sc;
}

sub superclassesT {
    my $self = shift;

    my @sc = map { $self->superclasses ($_) } @_;
    push @sc, @_, map { $self->superclassesT ($_) } @sc; # laziness equals recursion
    my %dup;
    return map { $dup{$_}++ ? () : $_ } @sc; 
}

=pod

=item B<types>, B<typesT>

I<@lids> = I<$tm>->types  (I<$lid>, ...)

I<@lids> = I<$tm>->typesT (I<$lid>, ...)

The method C<types> returns all direct classes of the toplet identified by C<$lid>. If the toplet does
not exist, the list will be empty. C<typesT> is a variant which honors transitive subclassing (so if
I<a> is an instance of type I<A> and I<A> is a subclass of I<B>, then I<a> is also an instance of
I<B>).

Duplicates will be suppressed.

=cut

sub types {
    my $self = shift;
    my $ISA  = ('isa');
    my $a;
    my @types = map { ($a = $self->retrieve ($_))
		      ? $a->[TYPE]
		      : ( map { $_->[PLAYERS]->[0] }  $self->match_forall (type => $ISA, instance => $_) )
		     }
                @_;
    my %dup;
    return map { $dup{$_}++ ? () : $_ } @types;
}

sub typesT {
    my $self = shift;

    my @types = map { $self->types ($_) } @_;
    push @types, map { $self->superclassesT ($_) } @types;
    my %dup;
    return map { $dup{$_}++ ? () : $_ } @types;
}


=pod

=item B<instances>, B<instancesT>

I<@lids> = I<$tm>->instances  (I<$lid>, ...)

I<@lids> = I<$tm>->instancesT (I<$lid>, ...)

These methods return the direct (C<instances>) and also indirect (C<instancesT>) instances of the
toplet identified by C<$lid>.

Duplicates are suppressed.

=cut

sub instances {
    my $self = shift;

#    warn Dumper [ caller ] unless @_;

    my ($ISA, $THING) = ('isa', 'thing');

    my @instances = map {
	           $_ eq $THING
		       ? map { $_->[TM->LID] } $self->toplets
		       : 
		       (map { $_->[LID ] }         $self->match_forall (type => $_)),                 # all assocs of this type
		       (map { $_->[PLAYERS]->[1] } $self->match_forall (type => $ISA, class => $_))   # all direct instances
                  } @_;
}

sub instancesT {
    my $self = shift;

    my @instances = map { $self->instances ($_) }
                    map { $self->subclassesT ($_) } 
                    @_;
    my %dup;
    return map { $dup{$_}++ ? () : $_ } @instances;
}

=pod

=back

=head2 Filters

Quite often one needs to walk through a list of things to determine whether they are instances (or
types, subtypes or supertypes) of some concept. This list of functions lets you do that: you pass in
a list (reference) and the function behaves as filter, returning a list reference.

=over

=item B<are_instances>

I<@id> = I<$tm>->are_instances (I<$class_id>, I<@list_of_ids>)

Returns all those ids where the topic is an instance of the class provided.

=cut

sub are_instances {
    my $self  = shift;
    my $class = shift;                                                           # ok, what class are we looking at?

    my ($THING, $ISA, $CLASS) = ('thing', 'isa', 'class');

    my @rs;
    foreach my $thing (@_) {                                                     # we work through all the things we got
#warn "checking $thing";
	push @rs, $thing and next                                                # we happily take one if
	    if $class eq $THING and                                              #     is the class = 'thing' ? and
               $self->midlet ($thing);                                           #     then does the thing exist in the map ?

	my $m = $self->retrieve ($thing);
	push @rs, $thing and next                                                # we happily take one if
	    if $m and                                                            #    it is an assertion ? and...
	       ($class eq $THING                                                 #    either it is the class a THING (we did not explicitly store _that_)
                or
                $self->is_subclass ($m->[TYPE], $class)                          #    or is the assertion type a subclass?
	        );

	push @rs, $thing and next                                                # we happily take one if
	    if grep ($self->is_subclass ($_, $class),                            # finall we check all of the intermediate type whether there is a transitive relation
		     map { $self->get_players ($_, $CLASS) }                     # then we find the 'class' value
                           $self->match_forall (type => $ISA, instance => $thing));
        # nothing                                                                # otherwise we do not push
    }
    return @rs;
}

=pod

=item B<are_types> (Warning: placeholder only)

I<@ids> = I<$tm>->are_types (I<$instance_id>, I<@list_of_ids>)

Returns all those ids where the topic is a type of the instance provided.

=cut

sub are_types {
    $log->logwarn ("# not implemented function");
    return 0;
}

=pod

=item B<are_supertypes> (Warning: placeholder only)

I<@ids> = I<$tm>->are_supertypes (I<$class_id>, I<@list_of_ids>)

Returns all those ids where the topic is a supertype of the class provided.

=cut

sub are_supertypes {
    $log->logwarn ("# not implemented function");
    return 0;
}

=pod

=item B<are_subtypes> (Warning: placeholder only)

I<@ids> = I<$tm>->are_subtypes (I<$class_id>, I<@list_of_ids>)

Returns all those ids where the topic is a subtype of the class provided.

=cut

sub are_subtypes {
    $log->logwarn ("# not implemented function");
    return 0;
}

=pod

=back

=head1 REIFICATION

=over

=item B<is_reified>

(I<$tid>) = I<$tm>->is_reified (I<$assertion>)

(I<$tid>) = I<$tm>->is_reified (I<$url>)

In the case that the handed-in assertion is internally reified in the map, this method will return
the internal identifier of the reifying toplet. Or C<undef> if there is none.

In the case that the handed-in URL is used as subject address of a toplet, this method will return
the internal identifier of the reifying toplet. Or C<undef> if there is none.

=cut

sub _is_reified {
    my $self = shift;
    my $a    = shift;

    my $mid2iid = $self->{mid2iid};                                                               # shortcut
    $a = $a->[TM->LID] if ref ($a) eq 'Assertion';                                                # for assertions we take the LID

    return grep { $mid2iid->{$_}->[TM->ADDRESS] eq $a }                                           # brute force
           grep { $mid2iid->{$_}->[TM->ADDRESS] }
           keys %{$mid2iid};
}

sub is_reified {
    return _is_reified (@_);
}

=pod

=item B<reifies>

I<$url>       = I<$tm>->reifies (I<$tid>)

I<$assertion> = I<$tm>->reifies (I<$tid>)

Given a toplet identifier, this method returns either the internally reified assertion, an
externally reified object via its URL, or C<undef> if that toplet does not reify at all.

=cut

sub reifies {
    my $self = shift;
    my $tid  = shift;

    my $add = $self->{mid2iid}->{$tid}->[TM->ADDRESS] if $self->{mid2iid}->{$tid};
    return undef unless $add;
    return $add =~ /^[A-F0-9]{32}$/i ? $self->{assertions}->{$add} : $add;
}

=pod

=back

=head1 VARIANTS (aka "The Warts")

No comment.

=over

=item B<variants>

I<$tm>->variants (I<$id>, I<$variant>)

I<$tm>->variants (I<$id>)

With this method you can get/set a variant tree for B<any> topic. According to the standard only
basenames (aka topic names) can have variants, but, hey, this is such an ugly beast (I am
digressing). According to this data model you can have variants for B<all> toplets/maplets. You only
need their id.

The structure is like this:

  $VAR1 = {
    'tm:param1' => {
      'variants' => {
        'tm:param3' => {
          'variants' => undef,
          'value' => 'name for param3'
        }
      },
      'value' => 'name for param1'
    },
    'tm:param2' => {
      'variants' => undef,
      'value' => 'name for param2'
    }
  };

The parameters are the keys (there can only be one, which is a useful, cough, restriction of the
standard) and the data is the value. Obviously, one key value (i.e. parameter) can only exists once.

Caveat: This is not very well tested (read: not tested at all).

=cut

sub variants {
    my $self = shift;
    my $id   = shift;
    my $var  = shift;

    $self->{last_mod} = Time::HiRes::time if $var;
    return $var ? $self->{variants}->{$id} = $var : $self->{variants}->{$id};
}


=pod 

=back

=head1 LOGGING

The L<TM> module hosts (since 1.29) the Log4Perl object C<$TM::log>. It is initialized with some
reasonable defaults, but an using application can access it, tweak it, or overwrite it completely.

=head1 SEE ALSO

L<TM::PSI>, L<Log::Log4perl>

=head1 COPYRIGHT AND LICENSE

Copyright 200[1-8] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

#-- this we do when all structures have been defined
_prime_infrastructure();                                                                # initialize
# NOTE: BEGIN does not work, because we have to define all 

sub _prime_infrastructure {                                                             # generate a fragmentary TM structure for the infrastructure
    foreach my $h ($TM::PSI::core,
		   $TM::PSI::topicmaps_inc,
		   $TM::PSI::tmql_inc,
		   $TM::PSI::astma_inc) {
	foreach my $k (keys %{ $h->{mid2iid} }) {
	    $infrastructure->{mid2iid}->{$k} = [ $k, undef, $h->{mid2iid}->{$k} ];      # and manifest them as toplets
	}

	map { $infrastructure->{assertions}->{ $_->[TM->LID] } = $_ }                   # manifest assertions
	map { $_->[TM->LID] = mklabel ($_);                                             #   after computing the hash LID
	      $_ }
	map { canonicalize ( undef, $_ ) }                                              #   after canonicalizing them
	map { $_->[TM->KIND]  = TM->ASSOC;                                              #   adding defaults
	      $_->[TM->SCOPE] = TM::PSI::US; 
	      $_ }
	map { Assertion->new (type    => $_->[0],                                       #   which is built here
			      roles   => $_->[1],                                       #     with the roles list
			      players => $_->[2])}                                      #     with the players list
	@{ $h->{assertions} };
    }
}


1;

__END__

	    if (! $mid2iid->{$k2}) {                                           # we had no entry here => simply...
		$mid2iid->{$k2} = $v;                                          # ...add what the other has
	    } else {                                                           # same internal identifier? danger lurking...
#warn Dumper $v, $mid2iid->{$k};
		if (!$v->[1]) {                                      # new had undef there, leave what we have
		} elsif (!$mid2iid->{$k2}->[1]) {                    # old had nothing, =>
		    $mid2iid->{$k2}->[1] = $v->[1];        # copy it
		} elsif ($mid2iid->{$k}->[1] eq $v->[1]) { # old had something and new has something and they are the same
		    # leave it
		} else {                                   # not good, subject addresses differ
		    $log->logdie ("using the same internal identifier (including baseuri) '$k', but having different subject addresses (".$mid2iid->{$k}->[1].",".$v->[TM->ADDRESS].") is just weird");
		}
		push @{$mid2iid->{$k}->[TM->INDICATORS]}, 
		     @{$v->[TM->INDICATORS]};              # simply add all the subject indication stuff
	    }

#     if (my $index = $self->{indices}->{match}) {                                            # there exists a dedicated index
# 	my $key   = "$skeys:" . join ('.', @svals);
# 	if (my $lids  = $index->is_cached ($key)) {                                         # if result was cached, lets take the list of lids
# 	    return map { $self->{assertions}->{$_} } @$lids;                                # and return fully fledged
# 	} else {                                                                            # not defined means not cache => recompute
# 	    my @as = _dispatch_forall ($self, \%query, $skeys, @svals);                     # do it the hard way
# 	    $index->do_cache ($key, [ map { $_->[LID] } @as ]);                             # save it for later
# 	    return @as;
# 	}
#     } else {                                                                                # no cache, let's do the ochsentour
# 	return _dispatch_forall ($self, \%query, $skeys, @svals);
#     }

