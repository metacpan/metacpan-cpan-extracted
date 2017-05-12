####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package TM::AsTMa::Fact;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 1 "yapp/astma-fact.yp"

use Data::Dumper;
use TM;
use TM::Literal;

use constant LEFT  => 'http://psi.tm.bond.edu.au/astma/1.0/#psi-left';
use constant RIGHT => 'http://psi.tm.bond.edu.au/astma/1.0/#psi-right';

my $tracing = 0;



sub new {
    my $class   = shift;
    my %options = @_;
    my $store   = delete $options{store} || new TM;       # the Yapp parser is picky and interprets this :-/

    ref($class) and $class=ref($class);

    my $self = $class->SUPER::new( 
##				   yydebug   => 0x01,
				   yyversion => '1.05',
				   yystates  =>
[
	{#State 0
		DEFAULT => -1,
		GOTOS => {
			'maplet_definitions' => 1
		}
	},
	{#State 1
		ACTIONS => {
			'' => 3,
			'ID' => 2,
			'TRACE' => 4,
			'LPAREN' => 5,
			'LBRACKET' => 6,
			'COMMENT' => 7,
			'CANCEL' => 9,
			'ENCODING' => 13,
			'LOG' => 14,
			'EOL' => 15
		},
		GOTOS => {
			'maplet_definition' => 12,
			'association_definition' => 11,
			'topic_definition' => 8,
			'template_definition' => 10
		}
	},
	{#State 2
		DEFAULT => -18,
		GOTOS => {
			'types' => 16
		}
	},
	{#State 3
		DEFAULT => 0
	},
	{#State 4
		ACTIONS => {
			'EOL' => 17
		}
	},
	{#State 5
		ACTIONS => {
			'ID' => 18
		}
	},
	{#State 6
		DEFAULT => -41,
		GOTOS => {
			'@4-1' => 19
		}
	},
	{#State 7
		ACTIONS => {
			'EOL' => 20
		}
	},
	{#State 8
		DEFAULT => -9
	},
	{#State 9
		ACTIONS => {
			'EOL' => 21
		}
	},
	{#State 10
		ACTIONS => {
			'EOL' => 22
		}
	},
	{#State 11
		DEFAULT => -10
	},
	{#State 12
		DEFAULT => -2
	},
	{#State 13
		ACTIONS => {
			'EOL' => 23
		}
	},
	{#State 14
		ACTIONS => {
			'EOL' => 24
		}
	},
	{#State 15
		DEFAULT => -11
	},
	{#State 16
		ACTIONS => {
			'ISREIFIED' => 26,
			'ISINDICATEDBY' => 27,
			'ISA' => 28,
			'LPAREN' => 25,
			'REIFIES' => 30
		},
		DEFAULT => -14,
		GOTOS => {
			'type' => 29,
			'reification_indication' => 31
		}
	},
	{#State 17
		DEFAULT => -7
	},
	{#State 18
		ACTIONS => {
			'RPAREN' => 32
		}
	},
	{#State 19
		ACTIONS => {
			'LPAREN' => 5
		},
		GOTOS => {
			'association_definition' => 33
		}
	},
	{#State 20
		DEFAULT => -4
	},
	{#State 21
		DEFAULT => -6
	},
	{#State 22
		DEFAULT => -3
	},
	{#State 23
		DEFAULT => -8
	},
	{#State 24
		DEFAULT => -5
	},
	{#State 25
		DEFAULT => -50,
		GOTOS => {
			'ids' => 34
		}
	},
	{#State 26
		ACTIONS => {
			'ID' => 35
		}
	},
	{#State 27
		ACTIONS => {
			'ID' => 36
		}
	},
	{#State 28
		ACTIONS => {
			'ID' => 37
		}
	},
	{#State 29
		DEFAULT => -19
	},
	{#State 30
		ACTIONS => {
			'ID' => 38
		}
	},
	{#State 31
		DEFAULT => -38,
		GOTOS => {
			'inline_assocs' => 39
		}
	},
	{#State 32
		ACTIONS => {
			'AT' => 40
		},
		DEFAULT => -36,
		GOTOS => {
			'scope' => 41
		}
	},
	{#State 33
		DEFAULT => -42
	},
	{#State 34
		ACTIONS => {
			'ID' => 42,
			'RPAREN' => 43
		}
	},
	{#State 35
		DEFAULT => -16
	},
	{#State 36
		DEFAULT => -17
	},
	{#State 37
		DEFAULT => -20
	},
	{#State 38
		DEFAULT => -15
	},
	{#State 39
		ACTIONS => {
			'ID' => 44,
			'EOL' => 46
		},
		GOTOS => {
			'inline_assoc' => 45
		}
	},
	{#State 40
		ACTIONS => {
			'ID' => 47
		}
	},
	{#State 41
		ACTIONS => {
			'ISREIFIED' => 26,
			'ISINDICATEDBY' => 27,
			'REIFIES' => 30
		},
		DEFAULT => -14,
		GOTOS => {
			'reification_indication' => 48
		}
	},
	{#State 42
		DEFAULT => -51
	},
	{#State 43
		DEFAULT => -21
	},
	{#State 44
		ACTIONS => {
			'ID' => 49
		}
	},
	{#State 45
		DEFAULT => -39
	},
	{#State 46
		DEFAULT => -12,
		GOTOS => {
			'@1-5' => 50
		}
	},
	{#State 47
		DEFAULT => -37
	},
	{#State 48
		ACTIONS => {
			'EOL' => 51
		}
	},
	{#State 49
		DEFAULT => -40
	},
	{#State 50
		DEFAULT => -22,
		GOTOS => {
			'characteristics_indication' => 52
		}
	},
	{#State 51
		ACTIONS => {
			'ID' => 53
		},
		GOTOS => {
			'member' => 54,
			'association_members' => 55
		}
	},
	{#State 52
		ACTIONS => {
			'OC' => 57,
			'IN' => 58,
			'BN' => 59,
			'SIN' => 60
		},
		DEFAULT => -13,
		GOTOS => {
			'characteristic_indication' => 56,
			'indication' => 61,
			'class' => 62,
			'characteristic' => 63
		}
	},
	{#State 53
		ACTIONS => {
			'COLON' => 64
		}
	},
	{#State 54
		DEFAULT => -44
	},
	{#State 55
		ACTIONS => {
			'ID' => 53
		},
		DEFAULT => -43,
		GOTOS => {
			'member' => 65
		}
	},
	{#State 56
		DEFAULT => -23
	},
	{#State 57
		DEFAULT => -31
	},
	{#State 58
		DEFAULT => -32
	},
	{#State 59
		DEFAULT => -30
	},
	{#State 60
		DEFAULT => -26,
		GOTOS => {
			'@2-1' => 66
		}
	},
	{#State 61
		DEFAULT => -25
	},
	{#State 62
		DEFAULT => -28,
		GOTOS => {
			'@3-1' => 67
		}
	},
	{#State 63
		DEFAULT => -24
	},
	{#State 64
		DEFAULT => -50,
		GOTOS => {
			'ids' => 68,
			'ids1' => 69
		}
	},
	{#State 65
		DEFAULT => -45
	},
	{#State 66
		ACTIONS => {
			'STRING' => 71
		},
		GOTOS => {
			'string' => 70
		}
	},
	{#State 67
		ACTIONS => {
			'AT' => 40
		},
		DEFAULT => -36,
		GOTOS => {
			'scope' => 72
		}
	},
	{#State 68
		ACTIONS => {
			'ID' => 73
		}
	},
	{#State 69
		ACTIONS => {
			'RBRACKET' => 74,
			'EOL' => 76
		},
		GOTOS => {
			'eom' => 75
		}
	},
	{#State 70
		DEFAULT => -27
	},
	{#State 71
		ACTIONS => {
			'EOL' => 77
		}
	},
	{#State 72
		ACTIONS => {
			'LPAREN' => 78
		},
		DEFAULT => -33,
		GOTOS => {
			'char_type' => 79,
			'assoc_type' => 80
		}
	},
	{#State 73
		ACTIONS => {
			'ID' => -51
		},
		DEFAULT => -49
	},
	{#State 74
		ACTIONS => {
			'EOL' => 81
		}
	},
	{#State 75
		DEFAULT => -46
	},
	{#State 76
		DEFAULT => -47
	},
	{#State 77
		DEFAULT => -52
	},
	{#State 78
		ACTIONS => {
			'ID' => 82
		}
	},
	{#State 79
		ACTIONS => {
			'STRING' => 71
		},
		GOTOS => {
			'string' => 83
		}
	},
	{#State 80
		DEFAULT => -34
	},
	{#State 81
		DEFAULT => -48
	},
	{#State 82
		ACTIONS => {
			'RPAREN' => 84
		}
	},
	{#State 83
		DEFAULT => -29
	},
	{#State 84
		DEFAULT => -35
	}
],
				   yyrules   =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'maplet_definitions', 0, undef
	],
	[#Rule 2
		 'maplet_definitions', 2, undef
	],
	[#Rule 3
		 'maplet_definitions', 3, undef
	],
	[#Rule 4
		 'maplet_definitions', 3, undef
	],
	[#Rule 5
		 'maplet_definitions', 3,
sub
#line 42 "yapp/astma-fact.yp"
{ warn "Logging $_[2]"; }
	],
	[#Rule 6
		 'maplet_definitions', 3,
sub
#line 43 "yapp/astma-fact.yp"
{ die  "Cancelled"; }
	],
	[#Rule 7
		 'maplet_definitions', 3,
sub
#line 44 "yapp/astma-fact.yp"
{ $tracing = $_[2]; warn "# start tracing: level $tracing"; }
	],
	[#Rule 8
		 'maplet_definitions', 3,
sub
#line 45 "yapp/astma-fact.yp"
{
		                                              use Encode;
							      Encode::from_to ($_[0]->YYData->{INPUT}, "iso-8859-1", $_[2]);
							     }
	],
	[#Rule 9
		 'maplet_definition', 1, undef
	],
	[#Rule 10
		 'maplet_definition', 1, undef
	],
	[#Rule 11
		 'maplet_definition', 1, undef
	],
	[#Rule 12
		 '@1-5', 0,
sub
#line 57 "yapp/astma-fact.yp"
{
			$_[1] = $_[0]->{USER}->{store}->internalize ($_[1]);

			if (ref $_[3]) {                                                   # we have reification info
			    if (     $_[3]->[0] == 1) {                                    # 1 = REIFIES, means current ID is a shorthand for the other
				$_[0]->{USER}->{store}->internalize ($_[1] => $_[3]->[1]); 
			    } elsif ($_[3]->[0] == 0) {                                    # 0 = IS-REIFIED, this must be the other way round
				$_[0]->{USER}->{store}->internalize ($_[3]->[1] => $_[1]);
			    } elsif ($_[3]->[0] == 2) {                                    # 2 = ISINDICATEDBY, add the subject indicators
				$_[0]->{USER}->{store}->internalize ($_[1] => \ $_[3]->[1]);
			    } else {
				die "internal fu**up";
			    }
			}
			# assert instance/class
                        if (@{$_[2]}) {
			    $_[0]->{USER}->{store}->assert ( map { bless
								       [ undef, 
									 undef, 
									 'isa', 
									 undef,
									 [ 'class', 'instance' ], 
									 [ $_, $_[1] ], 
									 ], 'Assertion' }  
							     @{$_[2]} );
			}
			{                                                                     # memorize the types should be a 'topic'
                                                                                              # at the end (see end of parse)
			    my $implicits = $_[0]->{USER}->{implicits};
			    map { $implicits->{'isa-thing'}->{$_}++ } 
			             (@{$_[2]}, $_[1]);                                       # the types and the ID are declared implicitely
			}
			
			if (ref $_[4]) {                                                      # there are inline assocs
			    foreach (@{$_[4]}) {
				my $type      = $_->[0];
				my $player    = $_->[1];
				my $store     = $_[0]->{USER}->{store};
				my $templates = $_[0]->{USER}->{templates};
				if ($type eq 'is-subclass-of' || $type eq 'subclasses') {
				    $store->assert (bless [ undef,                            # LID
							    undef,                            # SCOPE
							    'is-subclass-of',                 # TYPE
							    TM->ASSOC,                        # KIND
							    [ 'subclass',  'superclass' ],    # ROLES
							    [ $_[1],       $player ],         # PLAYERS
							    undef ], 'Assertion' );
				} elsif ($type eq 'is-a') {
				    $store->assert (bless [ undef,                   	      # LID
							    undef,                   	      # SCOPE
							    'isa',                  	      # TYPE
							    TM->ASSOC,        	              # KIND
							    [ 'instance', 'class' ], 	      # ROLES
							    [ $_[1],       $player ],	      # PLAYERS
							    undef ], 'Assertion' );
				} elsif ($type eq 'has-a') {                                  # same, but other way round
				    $store->assert (bless [ undef,                   	      # LID
							    undef,                   	      # SCOPE
							    'isa',               	      # TYPE
							    TM->ASSOC,        	              # KIND
							    [ 'instance', 'class' ], 	      # ROLES
							    [ $player,     $_[1] ],	      # PLAYERS
							    undef ], 'Assertion' );
				} elsif ($templates->tids ( $type ) &&
					 (my @ts    = $templates->match (TM->FORALL, type => $templates->tids ( $type )  ))) {
				    warn "duplicate template for '$type' found (maybe typo?), taking one" if @ts > 1;
				    my $t = $ts[0];                                           # I choose one
				    $store->assert (bless [ undef,                   	      # LID
							    undef,                   	      # SCOPE
							    $type,               	      # TYPE
							    TM->ASSOC,              	      # KIND
							    [  	                              # ROLES
							      map {
								  my $l = $templates->toplet ($_)->[TM->ADDRESS];
								  ($l && $l eq LEFT ?
							                 $_[1]
								   :
							           ($l && $l eq RIGHT ?
                                                                         $player
                                                                   :
								         $_)
							          )
							          } @{$t->[TM->ROLES]} 
						            ],
						            [                       	      # PLAYERS
							      map {
							         my $l = $templates->toplet ($_)->[TM->ADDRESS];
							         ($l && $l eq LEFT ?
							                $_[1]
							          :
							          ($l && $l eq RIGHT ?
                                                                        $player
                                                                  :
								        $_)
							          )
							          } @{$t->[TM->PLAYERS]} 
						           ],
							    undef ], 'Assertion' );
				} else {
				    die "unknown association type '$type' in inlined association";
				}
			    }
			}
			warn "added toplet $_[1]" if $tracing;
		     }
	],
	[#Rule 13
		 'topic_definition', 7,
sub
#line 163 "yapp/astma-fact.yp"
{
#warn "char/ind in topic: ".Dumper $_[7];
                        my $id = $_[1];
                        # add assertions for every characteristic
                        $_[0]->{USER}->{store}->assert ( map {bless [ undef,                                          # LID
								       $_->[1],                                       # SCOPE
								       $_->[2] ||                                     # TYPE
								       ($_->[0] == TM->NAME ? 'name' : 'occurrence'),
								       $_->[0],                                       # KIND
								       [ 'thing', 'value' ],                          # ROLES
								       [ $id,             $_->[3] ],                  # PLAYERS
								       undef ], 'Assertion' }
							  @{$_[7]->[0]} );

                        map { $store->internalize ($id => \ $_ ) } @{$_[7]->[1]};       # add the subject indicators

			{                                                               # memorize basename types and scopes as implicitely defined
			    my $implicits = $_[0]->{USER}->{implicits};
			    map { $implicits->{'isa-scope'}->{$_}++ }
                            map { $_->[1] }
                            grep ($_->[1], @{$_[7]->[0]});                              # get the bloody scopes and tuck them away

			    map { $implicits->{'subclasses'}->{ $_->[0] == TM->NAME ? 'name' : 'occurrence' }->{$_->[2]}++ }
                            grep ($_->[2], @{$_[7]->[0]});                              # get all the characteristics with types
			}
			warn "added ".(scalar @{$_[7]->[0]})."characteristics for $_[1]" if $tracing > 1;
		    }
	],
	[#Rule 14
		 'reification_indication', 0, undef
	],
	[#Rule 15
		 'reification_indication', 2,
sub
#line 193 "yapp/astma-fact.yp"
{ [ 1, $_[2] ] }
	],
	[#Rule 16
		 'reification_indication', 2,
sub
#line 194 "yapp/astma-fact.yp"
{ [ 0, $_[2] ] }
	],
	[#Rule 17
		 'reification_indication', 2,
sub
#line 195 "yapp/astma-fact.yp"
{ [ 2, $_[2] ] }
	],
	[#Rule 18
		 'types', 0,
sub
#line 198 "yapp/astma-fact.yp"
{ [] }
	],
	[#Rule 19
		 'types', 2,
sub
#line 199 "yapp/astma-fact.yp"
{ push @{$_[1]}, @{$_[2]}; $_[1] }
	],
	[#Rule 20
		 'type', 2,
sub
#line 202 "yapp/astma-fact.yp"
{ [ $_[2] ] }
	],
	[#Rule 21
		 'type', 3,
sub
#line 203 "yapp/astma-fact.yp"
{   $_[2]   }
	],
	[#Rule 22
		 'characteristics_indication', 0, undef
	],
	[#Rule 23
		 'characteristics_indication', 2,
sub
#line 208 "yapp/astma-fact.yp"
{ push @{$_[1]->[ ref($_[2]) eq 'ARRAY' ? 0 : 1 ]}, $_[2]; $_[1] }
	],
	[#Rule 24
		 'characteristic_indication', 1, undef
	],
	[#Rule 25
		 'characteristic_indication', 1, undef
	],
	[#Rule 26
		 '@2-1', 0,
sub
#line 216 "yapp/astma-fact.yp"
{ $_[0]->{USER}->{string} ||= "\n" }
	],
	[#Rule 27
		 'indication', 3,
sub
#line 217 "yapp/astma-fact.yp"
{ $_[3] }
	],
	[#Rule 28
		 '@3-1', 0,
sub
#line 220 "yapp/astma-fact.yp"
{ $_[0]->{USER}->{string} ||= "\n" }
	],
	[#Rule 29
		 'characteristic', 5,
sub
#line 221 "yapp/astma-fact.yp"
{                           # check whether we are dealing with URIs or strings
				                                       if ($_[1] == TM->NAME) {  # names are always strings
									   $_[5] = new TM::Literal  ($_[5], TM::Literal->STRING);
								       } elsif ($_[5] =~ /^\w+:\S+$/) { # can only be OCC, but is it URI?
									   $_[5] = new TM::Literal  ($_[5], TM::Literal->URI);
								       } else {                  # occurrence and not a URI -> string
									   $_[5] = new TM::Literal  ($_[5], TM::Literal->STRING);
								       }
## warn "char ".Dumper [ $_[1], $_[3], $_[4], $_[5] ];
								      [ $_[1], $_[3], $_[4], $_[5] ]
								      }
	],
	[#Rule 30
		 'class', 1,
sub
#line 234 "yapp/astma-fact.yp"
{ TM->NAME  }
	],
	[#Rule 31
		 'class', 1,
sub
#line 235 "yapp/astma-fact.yp"
{ TM->OCC  }
	],
	[#Rule 32
		 'class', 1,
sub
#line 236 "yapp/astma-fact.yp"
{ TM->OCC  }
	],
	[#Rule 33
		 'char_type', 0, undef
	],
	[#Rule 34
		 'char_type', 1, undef
	],
	[#Rule 35
		 'assoc_type', 3,
sub
#line 243 "yapp/astma-fact.yp"
{   $_[2]   }
	],
	[#Rule 36
		 'scope', 0, undef
	],
	[#Rule 37
		 'scope', 2,
sub
#line 247 "yapp/astma-fact.yp"
{ $_[2] }
	],
	[#Rule 38
		 'inline_assocs', 0, undef
	],
	[#Rule 39
		 'inline_assocs', 2,
sub
#line 252 "yapp/astma-fact.yp"
{ push @{$_[1]}, $_[2]; $_[1] }
	],
	[#Rule 40
		 'inline_assoc', 2,
sub
#line 255 "yapp/astma-fact.yp"
{ [ $_[1], $_[2] ] }
	],
	[#Rule 41
		 '@4-1', 0,
sub
#line 259 "yapp/astma-fact.yp"
{ ($_[0]->{USER}->{templates}, $_[0]->{USER}->{store}) = ($_[0]->{USER}->{store}, $_[0]->{USER}->{templates}); }
	],
	[#Rule 42
		 'template_definition', 3,
sub
#line 262 "yapp/astma-fact.yp"
{ ($_[0]->{USER}->{templates}, $_[0]->{USER}->{store}) = ($_[0]->{USER}->{store}, $_[0]->{USER}->{templates}); }
	],
	[#Rule 43
		 'association_definition', 7,
sub
#line 268 "yapp/astma-fact.yp"
{
##warn "members ".Dumper $_[5];
## ??? TODO SCOPE ????
			       my (@roles, @players);
			       foreach my $m (@{$_[7]}) {                 # one member
				   my $role = shift @$m;                  # first is role
				   
				   while (@$m) {
				       push @roles, $role;                # roles repeat for every player
				       my $player = shift @$m;
				       push @players, $player;
				   }
			       }
			       my ($a) = $_[0]->{USER}->{store}->assert (bless [ undef, $_[4], $_[2], TM->ASSOC, \@roles, \@players, undef ], 'Assertion');
##warn "templates" .Dumper $_[0]->{USER}->{store};
                              { # reification
				  my $ms = $_[0]->{USER}->{store};
				  if (ref $_[5]) {
				      if ($_[5]->[0] == 1) {                   # 1 = REIFIES, 0 = IS-REIFIED
					  # (assoc) reifies http://.... means
					  #     1) the assoc will be addes as thing (is done already)
					  #     2) the http:// will be used as one subject indicator
					  die "reifier of association must be a URI" unless $_[5]->[1] =~ /^\w+:.+/;
					  $ms->internalize ($a->[TM::LID], $_[5]->[1]);
				      } elsif ($_[5]->[0] == 0) {              # something reifies this assoc
					  # (assoc) is-reified-by xxx   means
					  #     1) assoc is added as thing (is done already)
					  #     2) the local identifier is added as thing with the abs URL of the assoc as subject address
					  die "reifier must be local identifier" unless $_[5]->[1] =~ /^[A-Za-z][A-Za-z0-9_\.-]+$/;
					  $ms->internalize ($_[5]->[1] => $a);
				      } else { # this would be 'indication' but we do not want that here
					  die "indication for associations are undefined";
				      }
				  }
			      }

			       { # memorize that association type subclasses association
#				   my $implicits = $_[0]->{USER}->{implicits};

# implicit			   $implicits->{'subclasses'}->{'association'}->{$_[2]}++;
				   $_[0]->{USER}->{implicits}->{'isa-scope'}->{$_[4]}++ if $_[4];
			       }
			       warn "added assertion $_[2]" if $tracing;
			   }
	],
	[#Rule 44
		 'association_members', 1,
sub
#line 314 "yapp/astma-fact.yp"
{                       [ $_[1] ] }
	],
	[#Rule 45
		 'association_members', 2,
sub
#line 315 "yapp/astma-fact.yp"
{ push @{$_[1]}, $_[2];   $_[1]  }
	],
	[#Rule 46
		 'member', 4,
sub
#line 318 "yapp/astma-fact.yp"
{ [ $_[1], @{$_[3]} ] }
	],
	[#Rule 47
		 'eom', 1, undef
	],
	[#Rule 48
		 'eom', 2, undef
	],
	[#Rule 49
		 'ids1', 2,
sub
#line 325 "yapp/astma-fact.yp"
{ push @{$_[1]}, $_[2]; $_[1] }
	],
	[#Rule 50
		 'ids', 0,
sub
#line 328 "yapp/astma-fact.yp"
{ [] }
	],
	[#Rule 51
		 'ids', 2,
sub
#line 329 "yapp/astma-fact.yp"
{ push @{$_[1]}, $_[2]; $_[1] }
	],
	[#Rule 52
		 'string', 2,
sub
#line 332 "yapp/astma-fact.yp"
{ die "empty string in characteristics" unless $_[1]; $_[1] }
	]
],
				   %options);
    $self->{USER}->{store}         = $store;
    return bless $self, $class;
}

#line 335 "yapp/astma-fact.yp"


sub _Error {
    die "Syntax error: Found ".$_[0]->YYCurtok." but expected ".join (' or ', $_[0]->YYExpect);
}

use constant CHUNK_SIZE => 32000;

sub _Lexer {
    my $parser = shift;
    my $yydata = $parser->YYData;

    if (length ($yydata->{INPUT}) < 1024 && $yydata->{OFFSET} < $yydata->{TOTAL}) { 
	$yydata->{INPUT}  .= substr ($yydata->{RESERVE}, $yydata->{OFFSET}, CHUNK_SIZE);
	$yydata->{OFFSET} += CHUNK_SIZE;
    }
    my $refINPUT = \$yydata->{INPUT};

    my $aux;                                                                           # need this to store identifier/uri prefix for optimization

    $$refINPUT                                        or  return ('',          undef);
    $$refINPUT =~ s/^[ \t]+//so;

#warn "lexer ($parser->{USER}->{string}):>>>".$parser->YYData->{INPUT}."<<<";

    $$refINPUT =~ s/^\n//so                           and return ('EOL',       	   undef);
    $$refINPUT =~ s/^in\b(?![\.-])//o                 and return ('IN',        	   undef);
    $$refINPUT =~ s/^rd\b(?![\.-])//o                 and return ('IN',        	   undef);
    $$refINPUT =~ s/^oc\b(?![\.-])//o                 and return ('OC',        	   undef);
    $$refINPUT =~ s/^ex\b(?![\.-])//o                 and return ('OC',        	   undef);
    $$refINPUT =~ s/^bn\b(?![\.-])//o                 and return ('BN',        	   undef);

    $$refINPUT =~ s/^sin\b(?![\.-])//o                and return ('SIN',       	   undef);
    $$refINPUT =~ s/^is-a\b(?![\.-])//o               and return ('ISA',       	   undef);
    $$refINPUT =~ s/^reifies\b(?![\.-])//o            and return ('REIFIES',   	   undef);
    $$refINPUT =~ s/^=//o                             and return ('REIFIES',   	   undef);
    $$refINPUT =~ s/^is-reified-by\b(?![\.-])//o      and return ('ISREIFIED', 	   undef);
    $$refINPUT =~ s/^~//o                             and return ('ISINDICATEDBY', undef);

    if (my $t = $parser->{USER}->{string}) {                                           # parser said we should expect a string now, defaults terminator to \n
##warn "scanning for string (..$t..) in ...". $$refINPUT . "....";
	$$refINPUT =~ s/^:\s*<<<\n/:/o                and                              # we know it better, it is <<<
	    $t = "\n<<<\n";

	$$refINPUT =~ s/^:\s*<<(\w+)\n/:/o            and                              # we know it better, it is <<SOMETHING
	    $t = "\n<<$1\n";

##warn "try finding string ..$t..  " ;
	$$refINPUT =~ s/^:\s*(.*?)\s*$t/\n/s          and 
##            (warn "returning $1" or 1) and
	    (undef $parser->{USER}->{string}          or  return ('STRING',    $1));
##warn "no string";
    }

    $$refINPUT =~ s/^://o                             and return ('COLON',     undef);

## unfortunately, this does not what I want
##  $$refINPUT =~ s/^([A-Za-z][A-Za-z0-9_-]*)(?!:)//o and return ('ID',        $1); # negative look-ahead
## tricky optimization: don't ask
    $$refINPUT =~ s/^([A-Za-z][.A-Za-z0-9_-]*)//o     and $aux = $1                 # save this for later
	                                              and $$refINPUT !~ /^:[\w\/]/
                                                      and return ('ID',        $aux);

    $$refINPUT =~ s/^\(//so                           and return ('LPAREN',    undef);
    $$refINPUT =~ s/^\)//so                           and return ('RPAREN',    undef);
    $$refINPUT =~ s/^@//so                            and return ('AT',        undef);

    $$refINPUT =~ s/^(:[^\s\)\(\]\[]+)//o             and return ('ID',        $aux.$1); # is a URL/URN actually

    $$refINPUT =~ s/^(\d{4}-\d{1,2}-\d{1,2})(\s+(\d{1,2}):(\d{2}))?//o
                                                      and return ('ID',        sprintf "urn:x-date:%s:%02d:%02d", $1, $3 || 0, $4 || 0); # is a date

    $$refINPUT =~ s/^%log\s+(.*?)(?=\n)//so           and return ('LOG',       $1); # positive look-ahead
    $$refINPUT =~ s/^%cancel\s*(?=\n)//so             and return ('CANCEL',    $1); # positive look-ahead
    $$refINPUT =~ s/^%trace\s+(.*?)(?=\n)//so         and return ('TRACE',     $1); # positive look-ahead
    $$refINPUT =~ s/^%encoding\s+(.*?)(?=\n)//so      and return ('ENCODING',  $1); # positive look-ahead

    $$refINPUT =~ s/^\*//o                            and return ('ID',        sprintf "uuid-%010d", $TM::toplet_ctr++); ## $parser->{USER}->{topic_count}++);

    $$refINPUT =~ s/^\[//so                           and return ('LBRACKET',  undef);
    $$refINPUT =~ s/^\]//so                           and return ('RBRACKET',  undef);
    # should not be an issue except on error
    $$refINPUT =~ s/^(.)//so                          and return ($1,          $1);

}

sub parse {
    my $self  = shift;
    $_        = shift;

    s/\r\n/\n/sg;
    s/\r/\n/sg;
    s/(?<!\\)\\\n//sg;       						# a \, but not a \\
    s/ \~ /\n/g;             						# replace _~_ with \n
    s/ \~\~ / \~ /g;         						# stuffed ~~ cleanout
    s/^\#.*?\n/\n/mg;        						# # at the start of every line -> gone
    s/\s\#.*?\n/\n/mg;       						# anything which starts with <blank># -> gone
    s/(?<!\\)\\\#/\#/g;      						# but # can be escaped with a single \, as in \#
    s/\n\n\n+/\n\n/sg;       						# canonicalize line break (line count is gone already)

    # we not only capture what is said EXPLICITELY in the map, we also collect implicit knowledge
    # we could add this immediately into the map at parsing, but it would slow the process down and
    # it would probably duplicate/complicate things
    $self->{USER}->{implicits} = {
	'isa-thing'  => undef,                                          # just let them spring into existence
	'isa-scope'  => undef,                                          # just let them spring into existence
	'subclasses' => undef
	};
                                                                        # clone a pseudo map into which to store templates as assocs temporarily
    $self->{USER}->{templates} = new TM (baseuri => $self->{USER}->{store}->baseuri);

    $self->YYData->{INPUT}   = '';
    $self->YYData->{RESERVE} = $_;                                      # here we park the whole string
    $self->YYData->{TOTAL}   = length ($_);                             # this is how much we have in the reserve
    $self->YYData->{OFFSET}  = 0;                                       # and we start at index 0

    eval {
	$self->YYParse ( yylex => \&_Lexer, yyerror => \&_Error );
    }; if ($@ =~ /^Cancelled/) {
	warn $@;                                                        # de-escalate Cancelling to warning
    } elsif ($@) {
	die $@;                                                         # otherwise re-raise the exception
    }


    { # resolving implicit stuff
	my $implicits = $self->{USER}->{implicits};
	my $store     = $self->{USER}->{store};

	{ # all super/subclasses
	    foreach my $superclass (keys %{$implicits->{'subclasses'}}) {
		$store->assert ( map {
		    bless [ undef, undef, 'is-subclass-of', TM->ASSOC, [ 'superclass', 'subclass' ], [ $superclass, $_ ] ], 'Assertion' 
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
                                 bless [ undef, undef, 'isa', TM->ASSOC, [ 'class', 'instance' ], [ 'scope', $_ ] ], 'Assertion' 
				 } keys %{$implicits->{'isa-scope'}});
	}
    }

    return $self->{USER}->{store};
}

#my $f = new TM::AsTMa::Fact;
#$f->Run;


1;
