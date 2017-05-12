package TM::Serializable::XTM;

use strict;
use warnings;

use Class::Trait 'base';
use Class::Trait 'TM::Serializable';

use Data::Dumper;
use TM::Literal;

use constant {
    XTM10_NS => 'http://www.topicmaps.org/xtm/1.0/',
    XLINK_NS => 'http://www.w3.org/1999/xlink',
    XTM_NS   => 'http://www.topicmaps.org/xtm/',
    XSD_NS   => 'http://www.w3.org/2001/XMLSchema-datatypes',
};

=pod

=head1 NAME

TM::Serializable::XTM - Topic Maps, trait for parsing and dumping XTM instances.

=head1 SYNOPSIS

  # this is not an end-user package
  # see the source in TM::Materialized::XTM how this can be used

=head1 DESCRIPTION

This trait provides parsing and dumping functionality for XTM instances. 

=over

=item Version 1.0 : L<http://www.topicmaps.org/xtm/index.html>

=item Version 1.1 : L<http://www.jtc1sc34.org/repository/0495.htm>

=item Version 2.0 : L<http://www.isotopicmaps.org/sam/sam-xtm/>

=back

=head2 Limitations

=over

=item

only a single <topicMap> is allowed in one instance, there is no support for multiple maps per
document

=item

only a B<single> scope is allowed for (base)names, occurrences and associations.

=item

In XTM 1.1 you cannot host XML content in occurrences.

=item

No reification support in 1.0 or 1.1.

=item

This package does not make any use of I<item identifiers>.

=item

Relative URIs are NOT made absolute via the I<base URI> where the map is loaded from. This may NOT
be what a user ultimately wants. Also all URI canonicalization is skipped.

=item

The C<xlink:type> attribute is completely ignored.

=back

=head2 TODOs

=over

=item

E<lt>mergeMapE<gt> is handled in 1.0, 1.1, but any scoping topic is ignored. This is related to the
above.

=item

At this stage, you can only include other XTM instances with E<lt>mergeMapE<gt>, not AsTMa= or
LTM. This may be fixed in the future.

=item

No variants are serialized or deserialized.

=item

Reification of topic map item is NOT supported.

=item

C<isa> and C<is-subclass-of> associations which are scoped (or reified) are not handled special yet.

=item

Suppress trivia might also suppress homepage << occurrence assertions.

=item

Relative URLs in C<mergeMap> are not made absolute.

=back


=head1 INTERFACE

=head2 Methods

=over

=item B<deserialize>

This method takes an XTM string and tries to parse it. It will raise an exception on parse error.
The if a C<version> attribute exists, then the value 

=cut

sub deserialize {
    my $self = shift;
    my $content = shift;

    if ($content =~  /<(\w+:)?topicMap[^>]+version\s*=\s*["'](.+?)['"]/s) {       # this is a version 2.0 or 1.1 map
	if ($2 eq '2.0') {
	    return _deserialize_20 ($self, $content);
	} elsif ($2 eq '1.1') {
	    return _deserialize_10 ($self, $content);
	} elsif ($2 eq '1.0') {
	    return _deserialize_10 ($self, $content);

	} else {
	    $TM::log->logdie (__PACKAGE__ .": unsupported version '$2'");
	}
    } elsif ($content =~ m|(\w+:)?topicMap[^>]+xmlns:xlink|) {
	return _deserialize_10 ($self, $content);

    } else {                                                                    # otherwise we have to assume XTM 1.0
	$TM::log->logdie (__PACKAGE__ .": unsupported version");
    }

sub _deserialize_20 {
    my $self = shift;
    my $content = shift;

    my $xtmns = XTM_NS;
    $content  =~ s/xmlns\s*=\s*[\'"]$xtmns[\'"]//g;                             # remove all default namespacing with XTM 1.0
#    warn $content;

    use XML::LibXML;
    my $xp   = XML::LibXML->new();
    my $doc  = $xp->parse_string($content);

    my $root = $doc->documentElement();
    my $px   = $root->lookupNamespacePrefix( $xtmns ) || '';  $px .= ':' if $px;
#    warn "px >>$px<<";
    $doc->findnodes("/${px}topicMap") or $TM::log->logdie (__PACKAGE__ . ": no <topicMap> element found (namespace $xtmns)");

    #-- topics
    foreach my $t ($doc->findnodes("/${px}topicMap/${px}topic")) {
	my $id   = $t->findvalue('@id')                           or die "missing topic id";
	$self->internalize ($id);                                               # register topic in any case
        #-- identification
	map { $self->internalize( $id => \ $_ ); } 
             map { $_->findvalue('@href') }                                     # the href attribute
             $t->findnodes("${px}subjectIdentifier");                           # find subject indicators

	map { $self->internalize( $id => $_ ); }                                # if there are multiple, it will make kabooom
             map { $_->findvalue('./@href') }                                   # the href attribute
             $t->findnodes("${px}subjectLocator");                              # find subject addresses
	#-- topic types
	map {                                                                   # create class/instance for every instanceOf we find
	    $self->assert(Assertion->new (kind    => TM->ASSOC,
					  type    => 'isa',
					  roles   => [qw(class instance)],
					  players => [$_, $id]));
	}
	    map { s/^\#// && $_ }                                               # clean leading #
	    map { $_->nodeValue }                                               # find the id
	    $t->findnodes("${px}instanceOf/${px}topicRef/\@href"); 
	#-- names
	foreach my $bn ($t->findnodes("${px}name")) {                           # find names
	    (my $type  = $bn->findvalue ("${px}type/${px}topicRef/\@href"))  =~s/^\#//;  # could be empty, too
	    (my $scope = $bn->findvalue ("${px}scope/${px}topicRef/\@href")) =~s/^\#//;
	    my ($a) = $self->assert(Assertion->new(kind    => TM->NAME,
						   type    => $type || 'name',
						   roles   => [ qw(thing value) ],
						   players => [ $id, 
								TM::Literal->new($bn->findvalue("${px}value/text()"),
										 TM::Literal->STRING)],
						   scope   => $scope));
	    $self->assert(Assertion->new(kind    => TM->ASSOC,
					 type    => 'is-subclass-of',
					 roles   => [ qw(subclass superclass) ],
					 players => [ $type, 'name' ],
					 scope   => undef)) if $type && $type ne 'name';
	    $self->assert(Assertion->new(kind    => TM->ASSOC,
					 type    => 'isa',
					 roles   => [ qw(instance class) ],
					 players => [ $scope, 'scope' ],
					 scope   => undef)) if $scope && $scope ne 'us';
	    (my $reifier  = $bn->findvalue('@reifier')) =~ s/^\#//;
	    $self->internalize ($reifier => $a->[TM->LID]) if $reifier;
	}
	#-- occs
	foreach my $oc ($t->findnodes ("${px}occurrence")) {                    # find occurrences
	    (my $scope = $oc->findvalue ("${px}scope/${px}topicRef/\@href")) =~s/^\#//;  # could be empty
	    (my $type  = $oc->findvalue ("${px}type/${px}topicRef/\@href"))  =~s/^\#//;  # could be empty, too

	    my $value;
	    if (my ($rr) = $oc->findnodes ("${px}resourceRef")) {
		$value = new TM::Literal ( $rr->findvalue("\@href"), TM::Literal->URI );
	    } elsif (my ($rd) = $oc->findnodes ("${px}resourceData")) {
		my $dtype = $rd->findvalue('@datatype') || TM::Literal->STRING;
		if ($dtype eq TM::Literal->URI) {
		    $value = new TM::Literal ( $rd->findvalue("text()"), TM::Literal->URI );
		} else {
		    my $s = $rd->toString;
		    $s =~ s|^<.*?resourceData.*?>(.*)</.*?resourceData>$|$1|s;
		    $value = new TM::Literal ($s, $dtype);
		}
	    }
	    my ($a) = $self->assert(Assertion->new (kind    => TM->OCC,
						    type    => $type || 'occurrence',
						    roles   => [qw(thing value)],
						    players => [$id, $value ],
						    scope   => $scope));
	    $self->assert(Assertion->new(kind    => TM->ASSOC,
					 type    => 'is-subclass-of',
					 roles   => [ qw(subclass superclass) ],
					 players => [ $type, 'occurrence' ],
					 scope   => undef)) if $type && $type ne 'occurrence';
	    $self->assert(Assertion->new(kind    => TM->ASSOC,
					 type    => 'isa',
					 roles   => [ qw(instance class) ],
					 players => [ $scope, 'scope' ],
					 scope   => undef)) if $scope && $scope ne 'us';
	    (my $reifier  = $oc->findvalue('@reifier')) =~ s/^\#//;
	    $self->internalize ($reifier => $a->[TM->LID]) if $reifier;
	}
    }   
    #-- association
    for my $a ($doc->findnodes("/${px}topicMap/${px}association")) {
#	my $aid    = $a->findvalue('itemIdentity/@href');
	(my $type  = $a->findvalue("${px}type/${px}topicRef/\@href"))  =~ s/^\#//;
	(my $scope = $a->findvalue("${px}scope/${px}topicRef/\@href")) =~ s/^\#//;

	my (@roles,@players);

	foreach my $r ($a->findnodes("${px}role")) {
	    (my $role   = $r->findvalue("${px}type/${px}topicRef/\@href")) =~ s/^\#//;
	    (my $player = $r->findvalue("${px}topicRef/\@href"))           =~ s/^\#//;
	    push @roles,   $role;
	    push @players, $player;
	}
	my ($s) = $self->assert(Assertion->new(kind    => TM->ASSOC,
					       type    => $type,
					       scope   => $scope,
					       roles   => \@roles,
					       players => \@players));

	(my $reifier  = $a->findvalue('@reifier')) =~ s/^\#//;
	$self->internalize ($reifier => $s->[TM->LID]) if $reifier;
    }
    #-- mergeMap
    foreach my $mm ($doc->findnodes("/${px}topicMap/${px}mergeMap")) {
	my $h = $mm->findvalue ("\@href") 
	    or $TM::log->logdie ( __PACKAGE__ .": conformance error in 'mergeMap': 4.21, required attribute 'href' missing" );
	my $tm2 = new TM (baseuri => $self->{baseuri});
	Class::Trait->apply ($tm2, "TM::Serializable::XTM");
	$tm2->url ($h);
	$tm2->source_in;
#warn "store2 is ".Dumper $tm2;
	$self->add ($tm2);
    }

    return $self;
}

sub _find_topic_references {
    my $n = shift; # the node
    my $p = shift; # path
    my $x = shift; # prefix
# topic-reference = topicRef | resourceRef | subjectIndicatorRef
    my @ts;
    foreach my $m ($n->findnodes ("${x}${p}*")) {
	my $h = $m->findvalue ("\@xlink:href");
	if ($m->nodeName eq 'topicRef') {
	    $h =~ s/^\#//;
	    push @ts, $h;
	} elsif ($m->nodeName eq 'resourceRef') {                     # TODO: make absolute
	    push @ts, $h;
	} elsif ($m->nodeName eq 'subjectIndicatorRef') {             # TODO: make absolute
	    push @ts, \ $h;
	}
    }
#    warn "find trs ".Dumper \@ts;
    return @ts;
}

sub _deserialize_10 {
    my $self = shift;
    my $content = shift;

    my $xtmns = XTM10_NS;
    $content =~ s/xmlns\s*=\s*[\'"]$xtmns[\'"]//g;                              # remove all default namespacing with XTM 1.0
                                                                                # http://search.cpan.org/~pajas/XML-LibXML-1.65/lib/XML/LibXML/Node.pod
    use XML::LibXML;
    my $xp   = XML::LibXML->new();
    my $doc  = $xp->parse_string ($content);

    my $root = $doc->documentElement();
    my $px   = $root->lookupNamespacePrefix( $xtmns ) || '';  $px .= ':' if $px;

    $doc->findnodes("/${px}topicMap") or $TM::log->logdie (__PACKAGE__ . ": no <topicMap> element found (namespace $xtmns)");

#    warn "10 >>$px<<";
    if (my $baseuri = $doc->findvalue ("/${px}topicMap/\@xml:base")) {
	$self->{baseuri} = $baseuri;
    }

    my %reifiedby;                                                              # what by whom, for assocs
    foreach my $t ($doc->findnodes("/${px}topicMap/${px}topic")) {
	my $id   = $t->findvalue('@id')                           or die "missing topic id";
	$self->internalize ($id);                                               # register topic in any case

	map { $self->internalize( $id => \ $_ ); } 
             map { $_->findvalue('./@xlink:href') }                             # the href attribute
             $t->findnodes("${px}subjectIdentity/${px}subjectIndicatorRef");    # find subject indicators

	map { $self->internalize( $id => $_ ); }                                # if there are multiple, it will make kabooom
             map { $_->findvalue('./@xlink:href') }                             # the href attribute
             $t->findnodes("${px}subjectIdentity/${px}resourceRef");            # find subject indicators

	(my $reified = $t->findvalue ("${px}subjectIdentity/${px}topicRef/\@xlink:href")) =~ s/^\#//;
	$reifiedby{ $id } = $reified if $reified;                               # this will have to wait until we cover the assoc

	foreach my $bn ($t->findnodes("${px}baseName")) {                       # find base names
	    my ($scope) = _find_topic_references ($bn, "scope/", $px);          # could be empty
	    my ($type)  = _find_topic_references ($bn, "instanceOf/", $px);     # could be empty, too

	    $self->assert(Assertion->new(kind    => TM->NAME,
					 type    => $type || 'name',
					 roles   => [ qw(thing value) ],
					 players => [ $id, 
						      TM::Literal->new($bn->findvalue("${px}baseNameString/text()"),
								       TM::Literal->STRING)],
					 scope   => $scope));
	    $self->assert(Assertion->new(kind    => TM->ASSOC,
					 type    => 'is-subclass-of',
					 roles   => [ qw(subclass superclass) ],
					 players => [ $type, 'name' ],
					 scope   => undef)) if $type && $type ne 'name';
	    $self->assert(Assertion->new(kind    => TM->ASSOC,
					 type    => 'isa',
					 roles   => [ qw(instance class) ],
					 players => [ $scope, 'scope' ],
					 scope   => undef)) if $scope && $scope ne 'us';
	}

	foreach my $oc ($t->findnodes ("${px}occurrence")) {                    # find occurrences
	    my ($scope) = _find_topic_references ($oc, "scope/", $px);          # could be empty
	    my ($type)  = _find_topic_references ($oc, "instanceOf/", $px);     # could be empty, too

	    my $value = $oc->findvalue("${px}resourceData/text()")              # what kind of occurrence?
                              ? new TM::Literal ( $oc->findvalue("${px}resourceData/text()"),
						  TM::Literal->STRING )
                              : new TM::Literal ( $oc->findvalue("${px}resourceRef/\@xlink:href"),
						  TM::Literal->URI );
	    $self->assert(Assertion->new (kind    => TM->OCC,
					  type    => $type || 'occurrence',
					  roles   => [qw(thing value)],
					  players => [$id, $value ],
					  scope   => $scope));
	    $self->assert(Assertion->new(kind    => TM->ASSOC,
					 type    => 'is-subclass-of',
					 roles   => [ qw(subclass superclass) ],
					 players => [ $type, 'occurrence' ],
					 scope   => undef)) if $type && $type ne 'name';
	    $self->assert(Assertion->new(kind    => TM->ASSOC,
					 type    => 'isa',
					 roles   => [ qw(instance class) ],
					 players => [ $scope, 'scope' ],
					 scope   => undef)) if $scope && $scope ne 'us';
	}
	    
	map {                                                                   # create class/instance for every instanceOf we find
	    $self->assert(Assertion->new (kind    => TM->ASSOC,
					  type    => 'isa',
					  roles   => [qw(class instance)],
					  players => [$_, $id]));
	}
	    _find_topic_references ($t, "instanceOf/", $px); 
    }

    foreach my $a ($doc->findnodes("/${px}topicMap/${px}association")) {
	my $aid    = $a->findvalue('@id');
	my ($scope) = _find_topic_references ($a, "scope/", $px);          # could be empty
	my ($type)  = _find_topic_references ($a, "instanceOf/", $px);     # could be empty, too

	my (@roles,@players);
	foreach my $m ($a->findnodes("member")) {
	    my ($role) = _find_topic_references ($m, "roleSpec/", $px);
	    $role ||= 'thing';                                                  # we default to thing
	    foreach my $player (_find_topic_references ($m, "", $px)) {
		push @roles,   $role;
		push @players, $player;
	    }
	}
	my ($a) = $self->assert(Assertion->new(kind    => TM->ASSOC,
					       type    => $type,
					       scope   => $scope,
					       roles   => \@roles,
					       players => \@players));
	map { $self->internalize ( $_ => $a->[TM->LID]) }                       # and for those we register the topic as reifying one for our assoc
            grep { $reifiedby{$_} eq $aid }                                     # find those which point to this assoc
	    keys %reifiedby;                                                    # find all topics which reify something internally

	$self->assert(Assertion->new(kind    => TM->ASSOC,
				     type    => 'isa',
				     roles   => [ qw(instance class) ],
				     players => [ $scope, 'scope' ],
				     scope   => undef)) if $scope && $scope ne 'us';
    }

    foreach my $mm ($doc->findnodes("/${px}topicMap/${px}mergeMap")) {
	$TM::log->warn (__PACKAGE__ .": scoping topics at mergeMap ignored") if $mm->findvalue ("topicRef");
	my $h = $mm->findvalue ("\@xlink:href") 
	    or $TM::log->logdie ( __PACKAGE__ .": conformance error in 'mergeMap': 4.21, required attribute 'xlink:href' missing" );
	my $tm2 = new TM (baseuri => $self->{baseuri});
	Class::Trait->apply ($tm2, "TM::Serializable::XTM");
	$tm2->url ($h);
	$tm2->source_in;
#warn "store2 is ".Dumper $tm2;
	$self->add ($tm2);
    }
    return $self;
}
}

=pod

=item B<serialize>

This method serializes the map object into XTM notation and returns the resulting string.  It will
raise an exception if the object contains constructs that XTM cannot represent.  The result is a
standard Perl string, so you may need to force it into a particular encoding.

The method understands a number of key/value pair parameters:

=over

=item C<omit_trivia> (default: C<0>)

This option suppresses the output of topics without any characteristics.

=item C<version> (default: C<2.0>)

This option controls whether XTM 1.0 or XTM 2.0 (default) is generated.

=back

=cut


sub serialize {
    my $self = shift;
    my %opts = @_;

    $opts{version} ||= '2.0';

    if ($opts{version} eq '1.0') {
	return _serialize_10 ($self, %opts);
    } elsif ($opts{version} eq '1.1') {
	return _serialize_10 ($self, %opts);
    } elsif ($opts{version} eq '2.0') {
        return _serialize_20 ($self, %opts);
    } else {
	$TM::log->logdie ("unsupported version '".$opts{version}."'");
    }
    
sub _chars {
    my $self = shift;

    my %chars;                                                          # collect chars
    map  { push @{ $chars{ $_->[TM->PLAYERS]->[0] } }, $_ }             # take the thing player and collect there the characteristic
    grep { $_->[TM->KIND] != TM->ASSOC }                                # throw away assoc
         $self->asserts (\ '+all -infrastructure');                     # find all assertions

    map  { push @{ $chars{ $_->[TM->PLAYERS]->[1] } }, $_ }             # take the instance player and collect there the isa
    grep { $_->[TM->KIND] == TM->ASSOC && $_->[TM->TYPE] eq 'isa' }     # find isa assocs
         $self->asserts (\ '+all -infrastructure');                     # find all assertions
    return \%chars;
}

sub _serialize_20 {
    my $self = shift;
    my %opts = @_;

    my $baseuri = $self->{baseuri};
    my $debase  = sub {                                                 # closure!
	local $_ = $_[0];
	s/^$baseuri//;
	return $_;
    };

    use IO::String;
    my $ios    = IO::String->new;
    use XML::Writer;
    my ($xtm)  = (XTM_NS);
    my $writer = new XML::Writer(OUTPUT     => $ios,
                                 NAMESPACES => 1,
				 PREFIX_MAP => {$xtm   => ''},
				 FORCED_NS_DECLS => [XTM_NS],
				 NEWLINES   => 1);
    $writer->xmlDecl("utf-8");
    $writer->startTag("topicMap", 'version' => '2.0');

    my %chars = %{ _chars ($self) };

    #-- analyze reification
    my %reified;                                                                # collect information what topics reify (internally)
    map { $reified{ $_->[TM->ADDRESS] } = &$debase ( $_->[TM->LID] ) }          # register that
        grep { $_->[TM->ADDRESS] && $_->[TM->ADDRESS] =~ /^[0-9a-f]{32}$/ }     # internal reification
        $self->toplets;                                                         # all toplets
    #-- deserialize topics
    foreach my $t (sort { $a->[TM->LID] cmp $b->[TM->LID] } $self->toplets ( \ '+all -infrastructure' ) ) {
	next if $opts{omit_trivia}                                              # omit that topic if
                && ! $chars{ $t->[TM->LID] }                                    # no characteristics
                && ! @{ $t->[TM->INDICATORS] }                                  # no indicators
                && ! $t->[TM->ADDRESS];                                         # no subject address

	my @chars = $chars{ $t->[TM->LID] } ? @{ $chars{$t->[TM->LID]} } : ();  # hold the characteristics, shorthand
	$writer->startTag('topic', id => &$debase ($t->[TM->LID]));
	#-- deserialize subject locator
	if ($t->[TM->ADDRESS] && $t->[TM->ADDRESS] !~ /^[0-9a-f]{32}$/) {       # external reification, spit it out
		$writer->emptyTag('subjectLocator', 'href' => $t->[TM->ADDRESS]); 
	}
	#-- subject indicators
	map {
	    $writer->emptyTag("subjectIdentifier", "href" => $_);
	} @{ $t->[TM->INDICATORS] };
	#-- deserialize types
	{
	    my @types = map  { $_->[TM->PLAYERS]->[0] }                                     # find the classes
                        sort { $a->[TM->LID] cmp $b->[TM->LID] }                            # just for reproducability
	                grep { $_->[TM->TYPE] eq 'isa' }                                    # only those with instance/class
	                @chars;                                                             # all chars
	    if (@types) {
		$writer->startTag("instanceOf");
		map {                                                                       # for all classes
		    $writer->emptyTag("topicRef", 'href' => '#'.&$debase ($_));
		} @types;
		$writer->endTag;
	    }
	}
	#-- deserialize names
	map {                                                                   # find all names
	    $writer->startTag("name", $reified{ $_->[TM->LID] } 
			                         ? ('reifier' => $reified{ $_->[TM->LID] })
			                         : ());
#	    $writer->emptyTag ('itemIdentity', 'href' => &$debase ($_->[TM->LID]));
	    unless ($_->[TM->TYPE] eq 'name') {
		$writer->startTag("type");
		$writer->emptyTag("topicRef", 'href' => "#".&$debase ($_->[TM->TYPE]));
		$writer->endTag;
	    }
	    unless ($_->[TM->SCOPE] eq 'us') {
		$writer->startTag("scope");
		$writer->emptyTag("topicRef", 'href' => "#".&$debase ($_->[TM->SCOPE]));
		$writer->endTag;
	    }
	    $writer->dataElement("value",$_->[TM->PLAYERS]->[1]->[0]);
	    $writer->endTag;
	}
            sort { $a->[TM->LID] cmp $b->[TM->LID] }                            # just for reproducability
            grep { $_->[TM->KIND] == TM->NAME }
            @chars;
	#-- deserialize occs
	map {                                                                   # find all occurrences
	    $writer->startTag("occurrence", $reified{ $_->[TM->LID] } 
			                         ? ('reifier' => $reified{ $_->[TM->LID] })
			                         : ());
#	    $writer->emptyTag ('itemIdentity', 'href' => &$debase ($_->[TM->LID]));

	    $writer->startTag("type");
	    $writer->emptyTag("topicRef", 'href' => "#".&$debase ($_->[TM->TYPE]));
	    $writer->endTag;

	    unless ($_->[TM->SCOPE] eq 'us') {
		$writer->startTag("scope");
		$writer->emptyTag("topicRef", 'href' => "#".&$debase ($_->[TM->SCOPE]));
		$writer->endTag;
	    }
	    my $v = $_->[TM->PLAYERS]->[1];
	    if ($v->[1] eq TM::Literal->URI) {
		$writer->emptyTag    ("resourceRef", 'href' => $v->[0]);
	    } else {
		$writer->dataElement ("resourceData", $v->[0], 'datatype' => $v->[1]);
	    }
	    $writer->endTag;
	}
            sort { $a->[TM->LID] cmp $b->[TM->LID] }                            # just for reproducability
            grep { $_->[TM->KIND] == TM->OCC }
            @chars;

	$writer->endTag;
    }

    foreach my $a (sort { $a->[TM->LID] cmp $b->[TM->LID] }                           # this is only to guarantee some order for the user
		   grep { $_->[TM->KIND] == TM->ASSOC && $_->[TM->TYPE] ne 'isa'}     # but only assocs and not isa (as we have handled this)
		   $self->asserts (\ '+all -infrastructure')) {                       # find all non-infra assertions
	$writer->startTag("association", $reified{ $a->[TM->LID] } 
			                         ? ('reifier' => $reified{ $a->[TM->LID] })
			                         : ());
	$writer->emptyTag ('itemIdentity', 'href' => &$debase ($a->[TM->LID]));

	$writer->startTag("type");
	$writer->emptyTag("topicRef", 'href' => '#'.&$debase ($a->[TM->TYPE]));
	$writer->endTag;

	unless ($a->[TM->SCOPE] eq 'us') {
	    $writer->startTag("scope");
	    $writer->emptyTag("topicRef", 'href' => '#'.&$debase ($a->[TM->SCOPE]));
	    $writer->endTag;
	}

	my ($rs, $ps) = ($a->[TM->ROLES], $a->[TM->PLAYERS]);
	for (my $i = 0; $i <= $#$rs; $i++) {
	    $writer->startTag("role");
	    $writer->startTag("type");
	    $writer->emptyTag("topicRef", 'href' => '#'. &$debase ( $rs->[$i] ));
	    $writer->endTag;	    
	    $writer->emptyTag("topicRef", 'href' => '#'. &$debase ( $ps->[$i] ));
	    $writer->endTag;
	}
	$writer->endTag;
    }

    $writer->endTag;
    $writer->end();
    return ${$ios->string_ref}; 
}

sub _serialize_10 {
    my $self = shift;
    my %opts = @_;

    my $baseuri = $self->{baseuri};
    my $debase  = sub {                                                 # closure!
	local $_ = $_[0];
	s/^$baseuri//;
	return $_;
    };

    use IO::String;
    my $ios    = IO::String->new;
    use XML::Writer;
    my ($xlink, $xtm)  = (XLINK_NS, XTM10_NS);
    my $writer = new XML::Writer(OUTPUT     => $ios,
                                 NAMESPACES => 1,
				 PREFIX_MAP => {$xtm    => '',                  # this stupid thing does not like constants
						$xlink  => 'xlink'},
				 FORCED_NS_DECLS => [XLINK_NS],
				 NEWLINES   => 1);
    $writer->xmlDecl("iso-8859-1");
    $writer->startTag("topicMap", $opts{version} eq '1.1' ? ('version' => '1.1') : ());

    my %chars = %{ _chars ($self) };

    foreach my $t (sort { $a->[TM->LID] cmp $b->[TM->LID] } $self->toplets ( \ '+all -infrastructure' ) ) {
#	warn $t->[TM->LID];
	next if $opts{omit_trivia}                                              # omit that topic if
                && ! $chars{ $t->[TM->LID] }                                    # no characteristics
                && ! @{ $t->[TM->INDICATORS] }                                  # no indicators
                && ! $t->[TM->ADDRESS];                                         # no subject address

	my @chars = $chars{ $t->[TM->LID] } ? @{ $chars{$t->[TM->LID]} } : ();  # hold the characteristics, shorthand
#	warn Dumper \@chars;
	$writer->startTag("topic","id" => &$debase ($t->[TM->LID]));

	# find all types
	map {                                                                   # for all classes
	    $writer->startTag("instanceOf");
	    $writer->emptyTag("topicRef",[XLINK_NS,"href"]=>'#'.&$debase ($_));
	    $writer->endTag;
	}
            map  { $_->[TM->PLAYERS]->[0] }                                     # find the classes
            sort { $a->[TM->LID] cmp $b->[TM->LID] }                            # just for reproducability
	    grep { $_->[TM->TYPE] eq 'isa' }                                    # only those with instance/class
	    @chars;                                                             # all chars

	if (@{ $t->[TM->INDICATORS] } || $t->[TM->ADDRESS]) {
	    $writer->startTag("subjectIdentity");

	    if ($t->[TM->ADDRESS] =~ /^[0-9a-f]{32}$/) {                        # internal reification
		$writer->emptyTag('topicRef', [XLINK_NS,"href"] => '#a'.$t->[TM->ADDRESS] ); 
	    } else {                                                            # just a subject address
		$writer->emptyTag('resourceRef', [XLINK_NS,"href"] => $t->[TM->ADDRESS]); 
	    }
	    map {
		$writer->emptyTag("subjectIndicatorRef",[XLINK_NS,"href"]=>$_);
	    } @{ $t->[TM->INDICATORS] };
	    $writer->endTag;
	}

	map {                                                                   # find all basenames
	    $writer->startTag("baseName");
	    unless ($_->[TM->SCOPE] eq 'us') {
		$writer->startTag("scope");
		$writer->emptyTag("topicRef",[XLINK_NS,"href"]=>"#".&$debase ($_->[TM->SCOPE]));
		$writer->endTag;
	    }
	    $writer->dataElement("baseNameString",$_->[TM->PLAYERS]->[1]->[0]);
	    $writer->endTag;
	}
            sort { $a->[TM->LID] cmp $b->[TM->LID] }                            # just for reproducability
            grep { $_->[TM->KIND] == TM->NAME }
            @chars;

	map {                                                                   # find all occurrences
	    $writer->startTag("occurrence");
	    unless ($_->[TM->TYPE] eq 'occurrence') {
		$writer->startTag("instanceOf");
		$writer->emptyTag("topicRef",[XLINK_NS,"href"]=>"#".&$debase ($_->[TM->TYPE]));
		$writer->endTag;
	    }
	    unless ($_->[TM->SCOPE] eq 'us') {
		$writer->startTag("scope");
		$writer->emptyTag("topicRef",[XLINK_NS,"href"]=>"#".&$debase ($_->[TM->SCOPE]));
		$writer->endTag;
	    }
	    my $v = $_->[TM->PLAYERS]->[1];
	    if ($v->[1] eq TM::Literal->URI) {
		$writer->emptyTag    ("resourceRef",[XLINK_NS,"href"] => $v->[0]);
	    } else {
		$writer->dataElement ("resourceData", $v->[0]);
	    }
	    $writer->endTag;
	}
            sort { $a->[TM->LID] cmp $b->[TM->LID] }                            # just for reproducability
            grep { $_->[TM->KIND] == TM->OCC }
            @chars;

	$writer->endTag;
    }

    foreach my $a (sort { $a->[TM->LID] cmp $b->[TM->LID] }                           # this is only to guarantee some order for the user
		   grep { $_->[TM->KIND] == TM->ASSOC && $_->[TM->TYPE] ne 'isa'}     # but only assocs and not isa (as we have handled this)
		   $self->asserts (\ '+all -infrastructure')) {                       # find all non-infra assertions
	$writer->startTag("association", id => 'a'.$a->[TM->LID]);                    # the id attribute is required for reification in xtm 1.0

	$writer->startTag("instanceOf");
	$writer->emptyTag("topicRef",[XLINK_NS,"href"] => '#'.&$debase ($a->[TM->TYPE]));
	$writer->endTag;

	unless ($a->[TM->SCOPE] eq 'us') {
	    $writer->startTag("scope");
	    $writer->emptyTag("topicRef", [XLINK_NS,"href"] => '#'.&$debase ($a->[TM->SCOPE]));
	    $writer->endTag;
	}

	my ($rs, $ps) = ($a->[TM->ROLES], $a->[TM->PLAYERS]);
	my %ms;                                                  # here we have to collect all roles
	for (my $i = 0; $i <= $#$rs; $i++) {
	    push @{ $ms{ $rs->[$i] } }, $ps->[$i];               # and every role has a list of players
	}
	foreach my $r (keys %ms) {                               # that's the way XTM wants it
	    $writer->startTag("member");
	    $writer->startTag("roleSpec");
	    $writer->emptyTag("topicRef",[XLINK_NS,"href"] => '#'.&$debase ( $r ));
	    $writer->endTag;	    
	    
	    map {                                                # all players now
		$writer->emptyTag("topicRef",[XLINK_NS,"href"] => '#'. &$debase ( $_ )) 
		}
                @{ $ms{ $r } };
	    $writer->endTag;
	}

	$writer->endTag;
    }
    
    $writer->endTag;
    $writer->end();
    return ${$ios->string_ref}; 
}
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::Serializable>

=head1 AUTHOR INFORMATION

Copyright 200[78] Alexander Zangerl, Robert Barta.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION = 0.03;

1;

__END__

    # the work starts: collect info from the assertions.
    my (%topics,%assocs);
    for my $m ($self->match(TM->FORALL)) {
	my $kind  = $m->[TM->KIND];
	my $type  = $m->[TM->TYPE];
	my $scope = $m->[TM->SCOPE];
	my $lid   = $m->[TM->LID];

	if ($kind == TM->NAME) {
	    my ($thing, $value) = @{ $m->[TM->PLAYERS] };
	    
#	    die "XTM 1.0 does not offer reification of basenames (topic $name)\n"
#		if ($self->toplet($lid)->[TM->ADDRESS]);
	    
	    push @{$topics{$thing}->{bn}}, [ $value->[0], $type, $scope ];

	} elsif ($kind == TM->OCC) {
	    my ($thing, $value) = @{ $m->[TM->PLAYERS] };
	    
#	    die "XTM 1.x does not offer reification of occurrences (topic $name)\n"
#		if ($self->toplet($lid)->[TM->ADDRESS]);
	    
		push @{$topics{$thing}->{
		                         $value->[1] eq TM::Literal->URI ? 'oc' : 'in'
					 }}, [ $value->[0], $type, $scope ];
	    }
	} elsif ($kind == TM->ASSOC) {
	    if ($type eq "isa") {
		my ($p, $c) = @{ $m->[TM->PLAYERS] };
#		push @{$topics{$p}->{children}},$c;
		push @{$topics{$c}->{parents}}, $p;

# 	    } else {
# 		my %thisa;
# 		$thisa{type}=$type;
# 		$thisa{scope}=$scope;
# #		die "XTM 1.x does not offer reification by associations\n"
# #		    if ($thisa{reifies});
		
# 		for my $role (@{$self->get_role_s($m)})
# 		{
# 		    my $rolename=$role;
# 		    $rolename=~s/^$base//;
# 		    # must prime the array...
# 		    $thisa{roles}->{$rolename}=[];
		    
# 		    for my $player ($self->get_x_players($m,$role))
# 		    {
# 			$player=~s/^$base//;
# 			push @{$thisa{roles}->{$rolename}}, $player;
# 		    }
# 		}
# 		$assocs{$lid}=\%thisa;
	    }
	}
    }
    


    # then from the topics
    # we also need to run this part because of all the reification-crap...
    # uuuggly distinction between topics and assertions
    for my $t (grep(!$self->retrieve($_), $self->toplets))
    {
	my $tn=$t;
	$tn=~s/^$baseuri//; 
	$topics{$tn}||={}; 
	
	die "variants are not implemented (topic $tn)\n"
	    if ($self->variants($t));
	
	my $reifies=$self->toplet($t)->[TM->ADDRESS];
	if ($reifies)
	{
	    # xtm 1.0: reification is always attached to the active topic
	    if ($self->retrieve($reifies))	
	    {
		# assocs: we need to give them xml-compliant ids and point to them
		$reifies=~s/^$baseuri/\#_/;
	    }
	    elsif ($reifies=~/^$base(.+)$/)
	    {
		$reifies="#".$1;
	    }
	    $topics{$tn}->{reifies}=$reifies; 
	}
	my $sin=$self->toplet($t)->[TM->INDICATORS];
	if ($sin && @$sin)
	{
	    $topics{$tn}->{sin}=$sin;
	}
    } 
    

# 	if ($locretar) {	                                            # reifies a char or assoc
# 	    $locretar = ~s/^\#//;
# 	    if ($doc->findnodes("/topicMap/topic[\@id='$locretar']"))
# 	    {
# 		$sloc=$base.$locretar;
# 	    }
# 	    elsif ($doc->findnodes("/topicMap/association[\@id='$locretar']"))
# 	    {
# 		# we don't know the final association id until we handle them,
# 		# so resolution of this reification must wait until then.
# 		$reifiedby{$locretar}=$id; 
# 	    }
# 	    else
# 	    {
# 		die "topic $id: reifies nonexistent other topic ($locretar)\n";
# 	    }
# 	}
#	$self->internalize($base.$id => $sloc);
