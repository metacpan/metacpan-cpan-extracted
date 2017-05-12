package TM::LTM::Parser;

our $ltm_grammar = q {
                      {
			  my $store;
			  my $log;
			  my $implicits;
			  use Data::Dumper;
			  use TM;
			  use TM::Literal;

			  my %prefixes;
		      }

                      # comment is handled outside

		      startrule : { $store = $arg[0]; $log = $arg[1]; $implicits = $arg[2] }  # set TM store and log once
                                  topic_map

		      topic_map : encoding(?) directive(s?) component(s)

		      component: topic | assoc | occur

		      encoding : '@' string  # not analyzed here, but capture in the calling program
		                             # no good here if we would have to translate the encoding

		      directive : version_directive    |
                                  topicmapid_directive |
		                  mergemap_directive   |
		                  prefix_directive     |
				  baseuri_directive
                      # INCLUDE is handled outside

                      prefix_directive : '#PREFIX' /\w+/ '@' uri
		      {
			  my $uri = $item[4];
#			  $uri =~ s/^\"//; $uri =~ s/\"$//;
			  $prefixes{$item[2]} = $uri;
#warn "prefixes ".Dumper \%prefixes;
		      }

		      version_directive : '#VERSION' string
		      {
			  my $version = $item[2];
			  $log->logdie (__PACKAGE__ . ": VERSION not supported '$version'") unless $version =~ /^1\.[23]$/;
		      }

		      topicmapid_directive : '#TOPICMAP' ( name | reify )
		      {
			  $log->logdie (__PACKAGE__ . ": TOPICMAP directive ignored (use proper means)");
		      }

		      mergemap_directive : '#MERGEMAP' uri tm_format(?)
		      {
			  my $uri = $item[2];
#warn "uri is $uri";
			  my $format = $item[3]->[0] ? $item[3]->[0] : 'ltm';
			  my $tm;
			  if ($format =~ /^ltm$/i) {
			      $tm = new TM::Materialized::LTM (url => $uri);
			  } elsif ($format =~ /^xtm$/i) {
			      $tm = new TM::Materialized::XTM (url => $uri);
			  } elsif ($format =~ /^astma$/i) {
			      $tm = new TM::Materialized::AsTMa (url => $uri);
			  } else {
			      $log->logdie (__PACKAGE__ . ": unsupported TM format '$format'");
			  }
			  $tm->sync_in;
			  $store->add ($tm);
#warn "after merged in".Dumper $store;
			  $return = $uri;
		      }

		      tm_format : string

		      baseuri_directive : '#BASEURI' uri

		      topic : '[' name types(?) topname(?) reify(?) subject(?) indicator(s?) ']'
		      {
#warn "topic ".Dumper \@item;
			  my $id = $store->internalize ($item[2] => $item[6]->[0]); # maybe there is a subject addr, maybe not

			  # add the subject indicators
			  map { $store->internalize ($id => $_ ) } @{$item[7]};


			  if ($item[3] and $item[3]->[0]) {
			      $store->assert ( map {
                                                       [ undef, 
							 undef, 
							 'isa', 
							 undef,
							 [ 'class', 'instance' ], 
							 [ $_,       $id ],
							 ] }  
						         @{$item[3]->[0]} );
			      map { $implicits->{'isa-thing'}->{$_}++ } @{$item[3]->[0]};   # the types and the ID are declared implicitely
			  }
#warn "item 4".Dumper $item[4];
			  if ($item[4] and @{$item[4]}) {
			      my $topnames = $item[4]->[0];
#warn "topnames ".Dumper $topnames;
			      my ($a) = $store->assert ( map {[ undef,                                            # LID
								   $topnames->{scope}->[0],                       # SCOPE
								   'name',                                        # TYPE
								   TM->NAME,                                      # KIND
								   [ 'thing', 'value' ],                          # ROLES
								   [ $id,     $_ ],                               # PLAYERS
								   undef ] }
							    @{$topnames->{names}}[0] );       # use the first for a name
			      $return = $a;
# TODO (2..3) for the variants

#warn "basename reify ".Dumper $item[5];
			      # reification of the basename
			      $store->internalize ($item[5]->[0], $a->[TM->LID]) if $item[5]->[0];

			      {
				  map { $implicits->{'isa-scope'}->{ $_ }++ } @{$topnames->{scope}};
			      }
			  }

			  $return = $id;
		      }

		      types : ':' name(s)      { $return = $item[2]; }

		      subject : '%' uri        { $return = $item[2]; }     # for subject addrs the encoding is 'no-reference'

		      indicator : '@' uri      { $return = \ $item[2]; }   # for indicators it is 'send as string reference'

		      topname : '=' basesortdispname scope(?)
		      {
#warn "basenames".Dumper \@item;
			  $return = {
			      scope    => $item[3],
			      names    => $item[2],
			  };
		      }

		      basesortdispname: <leftop: basename ';' basename>

		      basename : string { $return = new TM::Literal ($item[1], 'xsd:string'); }

		      scope : '/' name { $return = $item[2]; }

		      assoc : name '(' assocroles  ')' scope(?) reify(?)
		      {
#warn "assoc item " . Dumper \@item;
			  { # memorize that association type subclasses association
			      $implicits->{'isa-scope'}->{ $item[5]->[0] }++ if $item[5]->[0];
			  }
			  my ($a) = $store->assert ([ undef,                                            # LID
							 $item[5] && $item[5]->[0],                     # SCOPE
							 $item[1],                                      # TYPE
							 TM->ASSOC,                                     # KIND
							 [ map { $_->[1] } @{$item[3]} ],               # ROLES
							 [ map { $_->[0] } @{$item[3]} ],               # PLAYERS
							 undef ]);
			  $return = $a;
#warn "reify ".Dumper $item[6];
			  $store->internalize ($item[6]->[0], $a->[TM->LID]) if $item[6]->[0];
		      }

                      assocroles : assocrole(s /,/)

		      assocrole : ( topic | name ) role(?)
		      {
                          $return = [ $item[1], $item[2]->[0] || 'thing' ];
		      }

		      role : ':' name

		      occur : '{' occ_topic ',' occ_type ',' resource '}' scope(?) reify(?)
		      {
			  my $id = $store->internalize ($item[2]);
			  my ($a) = $store->assert ([ undef,                                         # LID
						      $item[8]->[0],                                 # SCOPE
						      $item[4],                                      # TYPE (MUST BE DEFINED!)
						      TM->OCC,                                       # KIND
						      [ 'thing', 'value' ],                          # ROLES
						      [ $id,     $item[6] ],                         # PLAYERS
						      undef ]);

			 { # memorize basename types and scopes as implicitely defined
			     $implicits->{'isa-scope'}-> { $item[8]->[0] }++ if $item[8]->[0];       # get the bloody scopes and tuck them away
			     $implicits->{'subclasses'}->{ 'occurrence' }->{ $item[4] }++;
			 }

#warn "reify ".Dumper $item[9];
			  $store->internalize ($item[9]->[0], $a->[TM->LID]) if $item[9]->[0];

			  $return = $a;
		      }

		      occ_topic: name

		      occ_type : name

                      reify    : '~' name

		      resource : uri  { $return = new TM::Literal ($item[1], 'xsd:uri') }
                                 |
                                 DATA { $return = new TM::Literal ($item[1], 'xsd:string') }

		      DATA     : '[[' /.*(?=\]\])/sx ']]' { $return = $item[2]; }

		      uri      : string

		      comment  : '/*' /.+?/s '*/'

		      string   : '"' /[^\"]*/ '"'       { $return = $item[2]; }

		      name     : /^\w[:\-\w]*/
		      {
			  my $name = $item[1];
			  if ($name =~ /^(\w+):/) {
			      my $prefix = $1;
			      if ($prefixes{$prefix}) {
				  $name =~ s/^$prefix:/$prefixes{$prefix}/;
				  $return = $name;
			      } else {
				  $return = undef;
			      }
			  } else {
			      $return = $name;
			  }
		      }
		      <reject: ! $return>
		            | /^\w[-\w]*/
		      {
			  $return = $item[1];
		      }

};

sub new {
  my $class = shift;
  my %options = @_;
  my $self = bless \%options, $class;

  $::RD_HINT = 1;
  eval {
    require TM::LTM::CParser;
    $self->{parser} = TM::LTM::CParser->new();
  }; if ($@) {
    warn "could not find CParser ($@)";
    use Parse::RecDescent;
    $self->{parser} = new Parse::RecDescent ($ltm_grammar) or $TM::log->logdie (scalar __PACKAGE__ .": problem in grammar ($@)");
  };
  return $self;
}

sub parse {
    my $self = shift;
    my $text = shift;
    
    # we not only capture what is said EXPLICITELY in the map, we also collect implicit knowledge
    # we could add this immediately into the map at parsing, but it would slow the process down and
    # it would probably duplicate/complicate things
    my $implicits = {
	'isa-thing'  => undef,                                          # just let them spring into existence
	'isa-scope'  => undef,                                          # just let them spring into existence
	'subclasses' => undef
	};

    while ($text =~ /\#INCLUDE\s+\"(.+)\"/s) {          # find first
	my $src = $1;
	my $include; # we are trying to figure that one out
	if ($src =~ /^inline:(.*)/s) {
	    $include = $1;
	} else { # we try our luck with LWP
	    use LWP::Simple;
	    $include = get($1) || die "unable to load '$1'\n";
	}
#	use TM::Utils;
#	my $include = TM::Utils::get_content ($1);
	$text =~ s/\#INCLUDE\s+\"(.+)\"/\n$include\n/s; # replace first to find
    }

    # encoding
    # NOTE: currently ignored

    # remove comment
    # NOTE: LTM comments are extremely complex as they may appear anywhere
    # I ignored this and get rid of them on a syntactic level, even risking to throw away /* */ within string. So what.
    $text =~ s|/\*.*?\*/||sg; # global multiline


    $self->{parser}->startrule (\$text, 1, $self->{store}, $TM::log, $implicits);
    $TM::log->logdie ( scalar __PACKAGE__ . ": Found unparseable '".substr($text,0,40)."....'" ) unless $text =~ /^\s*$/s;

    { # resolving implicit stuff
	my $store     = $self->{store};

	{ # all super/subclasses
	    foreach my $superclass (keys %{$implicits->{'subclasses'}}) {
		$store->assert ( map {
		    [ undef, undef, 'is-subclass-of', TM->ASSOC, [ 'superclass', 'subclass' ], [ $superclass, $_ ] ] 
		    }  keys %{$implicits->{'subclasses'}->{$superclass}});
	    }
#warn "done with subclasses";
	}
	{ # all things in isa-things are THINGS, simply add them
##warn "isa things ".Dumper [keys %{$implicits->{'isa-thing'}}];
	    $store->internalize (map { $_ => undef } keys %{$implicits->{'isa-thing'}});
	}
	{ # establishing the scoping topics
	    $store->assert (map {
                                 [ undef, undef, 'isa', TM->ASSOC, [ 'class', 'instance' ], [ 'scope', $_ ] ] 
				 } keys %{$implicits->{'isa-scope'}});
	}
    }
}


=pod

=head1 SEE ALSO

L<TM>

=head1 AUTHOR INFORMATION

Copyright 200[1-6], Robert Barta <rho@bigpond.net.au>, All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.4';
our $REVISION = '$Id: Parser.pm,v 1.8 2006/11/23 10:02:55 rho Exp $';

1;

__END__
