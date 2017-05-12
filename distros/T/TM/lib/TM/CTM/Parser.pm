package TM::CTM::Parser;

use TM::Literal;

our $ctm_grammar = q {
                      {
			  my $store;
			  my $log;
			  my $implicits;
			  use Data::Dumper;
			  use TM;
			  use TM::Literal;
			  my %prefixes;
			  my %prefixes_backup;
			  my %wildcards;
			  my %wildcards_backup;
			  my %templates;

			  my $lid; 
		      }

  # comments are handled outside

  startrule                   :                                       {  $store     = $arg[0]; 
									 $log       = $arg[1];
									 $implicits = $arg[2];
									 %prefixes  = ('xsd' => TM::Literal->XSD);
									 %templates = ();
									 %wildcards = ();
 								       }
                                topicmap

  topicmap                    : prolog directive(s?)
                              ( directive
                              | template
                              | template_invocation
                              | topic
                              | association
                              )(s?)

  prolog                      : encoding(?) version(?)

  directive                   : prefix_directive
                              | restore_directive
                              | backup_directive
			      | include_directive
                             #| version_directive    |
                             #topicmapid_directive |
#		                  mergemap_directive   |
#				  baseuri_directive
#                      # INCLUDE is handled outside

  # this is NOT visible from the outside
  backup_directive            : '%backup'                             {
									%prefixes_backup  = %prefixes;
									%wildcards_backup = %wildcards;
                                                                        %wildcards = ();
							  	      }
  restore_directive           : '%restore'                           {
                                                                        %prefixes  = %prefixes_backup;
									%wildcards = %wildcards_backup;
							  	      }

  prefix_directive            : '%prefix' identifier reference	      {
                                                                         my $uri = $item[3];
									 $prefixes{$item[2]} = $uri;
								      }
  reference                   : iri
                              | /\S+/

  include_directive           : '%include' ( /^inline:.*?\n/ | iri )  {
                                                                         my $src = $item[2];
									 my $include;                      # we are trying to figure that one out
									 if ($src =~ /^inline:(.*)/s) {
									     $include = $1;
									 } else {                          # we try our luck with LWP
									     use LWP::Simple;
									     $include = get($1) or
										 $TM::log->logdie (__PACKAGE__ .": unable to load '$1'\n");
									 }
									 $text = $include . $text;
								      }


  encoding : 'TODO' '@' string  # not analyzed here, but capture in the calling program
		                             # no good here if we would have to translate the encoding

  version : 'TODO'

#-- template ------------------------------------------------------------------------------------------------

  template: 'def' identifier parameters /(.*?)(?=\bend\n)/s 'end'    {
                                                                       my $return = {
									   name   => $item[2],
									   params => $item[3],
									   body   => $item[4],
								       };
								       $templates{$return->{name}} 
								          and die "template '".$return->{name}."' already defined";
								       $templates{$return->{name}} = $return;
								      }

  parameters : '(' variable(s? /,/) ')'                               { $return = $item[2]; }

  variable   : /\$\w[\w-]*/

  topic_template_invocation:
	       identifier                                             { $templates{$item[1]} }
               '(' argument(s /,/) ')'                                {
									my $tmpl = $templates{$item[1]};
#		                                                        warn Dumper $templates{$item[1]};
#									warn Dumper $item[4];

									my $bu = $store->baseuri;
									$arg[0] =~ s/^$bu//;                   # pretend internal identifier
									unshift @{ $item[4] }, $arg[0];        # add topic as first param

									$text .= "\n\n%backup\n\n" . _expand_tmpl ($tmpl, $item[4]) . "\n\n%restore\n\n";
									$return = 1;

									sub _expand_tmpl {
									    my $tmpl   = shift;
									    my $name   = $tmpl->{name};
									    my $body   = $tmpl->{body};
									    my $params = $tmpl->{params};
									    my $args   = shift;
									    my %P;                             # formal -> actual 
									    foreach my $fp (@$params) {
										$P{$fp} = shift @$args  
										          or die "too few arguments for '$name'";
									    }
									    die "too many arguments for '$name'" if @$args;

									    foreach my $p (keys %P) {
										$p =~ s/\$//;                 # remove $, so that regexp below works
										$body =~ s/\$$p/$P{'$'.$p}/g;
									    }
									    return "\n" . $body . "\n";     # extend the text at the end;
									}
	                                                              }

  template_invocation:
	       identifier                                             { $templates{$item[1]} }
               '(' argument(s? /,/) ')'                               {
									my $tmpl = $templates{$item[1]};  # we know we have something
									$text .= "\n\n%backup\n\n" . _expand_tmpl ($tmpl, $item[4]) . "\n\n%restore\n\n";
									$return = 1;
								      }

  argument                    : literal                               {  $return = $item[1]->[0]; # get only the string value
								      }
                              | topic_ref                             {
                                                                         my $bu = $store->baseuri;
									 ($return = $item[1]) =~ s/^$bu//;  # pretend internal identifier
								      }

#-- association ---------------------------------------------------------------------------------------------

  association                 : topic_identity '(' roles ')' scope(?) reifier(?)
                                                                      {
									  my $scope = $item[5]->[0] ? $item[5]->[0] : 'us';
									  my ($a) = $store->assert (bless [ undef,     # LID
												      $scope,          # SCOPE
												      $item[1],        # TYPE
												      TM->ASSOC,       # KIND
												      [ map { $_->[0] } @{$item[3]} ], # ROLES
												      [ map { $_->[1] } @{$item[3]} ], # PLAYERS
												      undef ], 'Assertion');
									  $return = $a;
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => 'isa',
													roles   => [ qw(instance class) ],
													players => [ $scope, 'scope' ],
													scope   => undef)) if $scope ne 'us';
									  $store->internalize ($item[6]->[0], $a->[TM->LID]) if $item[6]->[0];
									  $return;
								      }
  roles                       : role(s /,/)

  role                        : typing player                         { $return = [ $item[1], $item[2] ];  }       # reifier(?)

  player                      : topic_ref

#-- topic ---------------------------------------------------------------------------------------------------

  topic                       : topic_identity                        { $lid = $item[1]; }
                                topic_tail[$lid](s?)
                                '.'

  topic_identity              : subject_identifier                    { $return = $store->internalize (undef, $item[1]); }
                              | identifier                            { $return = $store->internalize ($item[1]); }
                              | subject_locator                       { $return = $store->internalize (undef, $item[1]); }
                             #| item_identifier
                              | wildcard
                             #| variable

  wildcard                    : named_wildcard
                              | anonymous_wildcard

  anonymous_wildcard          : '?'                                   { $return = $store->internalize (sprintf "uuid-%010d", $TM::toplet_ctr++); }

  named_wildcard              : /\?(\w[\w-]*)/                        {
                                                                        my $id = $1;
									$wildcards{$id} ||=
									    $store->internalize (sprintf "uuid-%010d", $TM::toplet_ctr++);
									$return = $wildcards{$id};
								      }

  identifier                  : /\w[\w-]*/

  topic_ref                   : topic_identity                        { $return = ref ($item[1]) ? $store->internalize (undef, $item[1]) : $item[1]; }
                              | embedded_topic

  embedded_topic              :  <rulevar: $llid>

  embedded_topic              : '['                                   { $llid = sprintf "uuid-%010d", $TM::toplet_ctr++; }
                                topic_tail[$llid]
                                ']'                                   { $return = $llid; }

  subject_identifier          : iri                                   { $return = \ $item[1]; }

  subject_locator             : '=' iri                               { $return = $item[2]; }

  qname                       :  /(\w[\w-]+):(\w[\w-]+)/              {
  #                               ^^^^^^^^^^ ^^^^^^^^^^
  #                               identifier:identifier , but wo blanks
                                                                         die "undefined prefix '$item[1]'" unless $prefixes{$1};
									 $return = $prefixes{$1}.$2;
								       }
  topic_tail                  : 
                              ( instance_of[$arg[0]]
                              | kind_of[$arg[0]]
                              | topic_template_invocation[$arg[0]]    # must be before assignment, otherwise would auto-register
                             #| identity[$arg[0]]
                              | subject_identifier                    { $return = undef if $text =~ /^\s*:/s } # a : in front ?
                                                                      { $store->internalize ($arg[0], $item[1]); }
			      | subject_locator                       { $return = undef if $text =~ /^\s*:/s }
				                                      { $store->internalize ($arg[0], $item[1]); }
                             #| item_identifier
                              | assignment[$arg[0]]
	                      ) /;?/


  assignment                  : name[$arg[0]]
                              | occurrence[$arg[0]]

#-- name -------------------------------------------------------------------------------------------------------------

  name                        : '-' typing(?) string scope(?) reifier(?) #variant(s?)
                                                                      {
									  my $type  = $item[2]->[0] ? $item[2]->[0] : 'name';
									  my $scope = $item[4]->[0] ? $item[4]->[0] : 'us';

									  my ($a) = $store->assert ( bless [ undef,         # LID
												       $scope,               # SCOPE
												       $type,                # TYPE
												       TM->NAME,             # KIND
												       [ 'thing', 'value' ], # ROLES
												       [ $arg[0], $item[3] ],# PLAYERS
												       undef ], 'Assertion' );
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => 'is-subclass-of',
													roles   => [ qw(subclass superclass) ],
													players => [ $type, 'name' ],
													scope   => undef)) if $type ne 'name';
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => 'isa',
													roles   => [ qw(instance class) ],
													players => [ $scope, 'scope' ],
													scope   => undef)) if $scope ne 'us';
									  $store->internalize ($item[5]->[0], $a->[TM->LID]) if $item[5]->[0];
									  $return = $a;
								      }

   occurrence                 : type ':' iri_literal scope(?) reifier(?)
                                                                      {
									  my $type  = $item[1];
									  my $scope = $item[4]->[0] ? $item[4]->[0] : 'us';

									  my ($a) = $store->assert ( bless [ undef,          # LID
												       $scope,               # SCOPE
												       $type,                # TYPE
												       TM->OCC,              # KIND
												       [ 'thing', 'value' ], # ROLES
												       [ $arg[0], $item[3] ],# PLAYERS
												       undef ], 'Assertion' );
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => 'is-subclass-of',
													roles   => [ qw(subclass superclass) ],
													players => [ $type, 'occurrence' ],
													scope   => undef)) if $type ne 'occurrence';
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => 'isa',
													roles   => [ qw(instance class) ],
													players => [ $scope, 'scope' ],
													scope   => undef)) if $scope ne 'us';
									  $store->internalize ($item[5]->[0], $a->[TM->LID]) if $item[5]->[0];
									  $return = $a;
								      }

   typing                     : type ':'                              { $return = $item[1]; }

   iri_literal                : literal 
                              | iri                                   { $return = new TM::Literal ($item[1], TM::Literal->URI); }

   type                       : topic_ref

   scope                      : '@' topic_ref                         { $return = $item[2]; }

   reifier                    : '~' topic_ref                         { $return = $item[2]; }

#-- isa and ako ---------------------------------------------------------------------------------------------

   instance_of                : 'isa' topic_ref                       { $store->assert ( [ undef, 
											   undef, 
											   'isa', 
											   undef,
											   [ 'class', 'instance' ], 
											   [ $item[2], $arg[0] ],
											   ] ); }
   kind_of                    : 'ako' topic_ref                       {  $store->assert ( [ undef, 
											   undef, 
											   'is-subclass-of', 
											   undef,
											   [ qw(subclass superclass) ], 
											   [ $arg[0], $item[2] ],
											   ] ); }
		      





#-- old junk to be deleted

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

		      xtopic : '[' name types(?) topname(?) reify(?) subject(?) indicator(s?) ']'
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


		      xname     : /^\w[:\-\w]*/
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
    require TM::CTM::CParser;
    $self->{parser} = TM::CTM::CParser->new();
  }; if ($@) {
    warn "could not find CParser ($@)";
    use Parse::RecDescent;
    $self->{parser} = new Parse::RecDescent ($ctm_grammar . $TM::Literal::grammar) or $TM::log->logdie (scalar __PACKAGE__ .": problem in grammar ($@)");
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


#    while ($text =~ /\#INCLUDE\s+\"(.+)\"/s) {          # find first
#	my $src = $1;
#	my $include; # we are trying to figure that one out
#	if ($src =~ /^inline:(.*)/s) {
#	    $include = $1;
#	} else { # we try our luck with LWP
#	    use LWP::Simple;
#	    $include = get($1) || die "unable to load '$1'\n";
#	}
##	use TM::Utils;
##	my $include = TM::Utils::get_content ($1);
#	$text =~ s/\#INCLUDE\s+\"(.+)\"/\n$include\n/s; # replace first to find
#    }

    # encoding
    # NOTE: currently ignored

    # remove comment
    # NOTE: LTM comments are extremely complex as they may appear anywhere
    # I ignored this and get rid of them on a syntactic level, even risking to throw away /* */ within string. So what.
#    $text =~ s|/\*.*?\*/||sg; # global multiline

#    $::RD_TRACE = 1;
    $self->{parser}->startrule (\$text, 1, $self->{store}, $TM::log, $implicits);
    $TM::log->logdie ( scalar __PACKAGE__ . ": Found unparseable '".substr($text,0,40)."....'" ) unless $text =~ /^\s*$/s;

#     { # resolving implicit stuff
# 	my $store     = $self->{store};

# 	{ # all super/subclasses
# 	    foreach my $superclass (keys %{$implicits->{'subclasses'}}) {
# 		$store->assert ( map {
# 		    [ undef, undef, 'is-subclass-of', TM->ASSOC, [ 'superclass', 'subclass' ], [ $superclass, $_ ] ] 
# 		    }  keys %{$implicits->{'subclasses'}->{$superclass}});
# 	    }
# #warn "done with subclasses";
# 	}
# 	{ # all things in isa-things are THINGS, simply add them
# ##warn "isa things ".Dumper [keys %{$implicits->{'isa-thing'}}];
# 	    $store->internalize (map { $_ => undef } keys %{$implicits->{'isa-thing'}});
# 	}
# 	{ # establishing the scoping topics
# 	    $store->assert (map {
#                                  [ undef, undef, 'isa', TM->ASSOC, [ 'class', 'instance' ], [ 'scope', $_ ] ] 
# 				 } keys %{$implicits->{'isa-scope'}});
# 	}
#     }
}


=pod

=head1 SEE ALSO

L<TM>

=head1 AUTHOR INFORMATION

Copyright 200[8], Robert Barta <rho@devc.at>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.2';

1;

__END__
