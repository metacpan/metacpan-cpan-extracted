#!/usr/bin/perl
########################################################################################
#
#    This file was generated using Parse::Eyapp version 1.165.
#
# (c) Parse::Yapp Copyright 1998-2001 Francois Desarmenien.
# (c) Parse::Eyapp Copyright 2006-2008 Casiano Rodriguez-Leon. Universidad de La Laguna.
#        Don't edit this file, use source file 'twostarts.eyp' instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
########################################################################################
package twostarts;
use strict;

push @twostarts::ISA, 'Parse::Eyapp::Driver';




BEGIN {
  # This strange way to load the modules is to guarantee compatibility when
  # using several standalone and non-standalone Eyapp parsers

  require Parse::Eyapp::Driver unless Parse::Eyapp::Driver->can('YYParse');
  require Parse::Eyapp::Node unless Parse::Eyapp::Node->can('hnew'); 
}
  



sub unexpendedInput { defined($_) ? substr($_, (defined(pos $_) ? pos $_ : 0)) : '' }

#line 4 "twostarts.eyp"
__PACKAGE__->YYLexer( 
  sub { # lexical analyzer
    my $self = $_[0]; 
    for (${$self->input()}) {  # contextualize
#line 4 "twostarts.eyp"
      
      m{\G(\s+)}gc and $self->tokenline($1 =~ tr{\n}{});

      /\G([aA])/gc and return ('A', $1);
      /\G(.)/gc and return ($1, $1);

      return ('', undef) if ($_ eq '') || (defined(pos($_)) && (pos($_) >= length($_)));
      /\G\s*(\S+)/;
      my $near = substr($1,0,10); 
      die( "Error inside the lexical analyzer near '". $near
          ."'. Line: ".$self->line()
          .". File: '".$self->YYFilename()."'. No match found.\n");
       
#line 52 ./twostarts.pm
      return ('', undef) if ($_ eq '') || (defined(pos($_)) && (pos($_) >= length($_)));
      die("Error inside the lexical analyzer. Line: 16. File: twostarts.eyp. No regexp matched.\n");
    } 
  } # end lexical analyzer
);

#line 59 ./twostarts.pm

my $warnmessage =<< "EOFWARN";
Warning!: Did you changed the \@twostarts::ISA variable inside the header section of the eyapp program?
EOFWARN

sub new {
  my($class)=shift;
  ref($class) and $class=ref($class);

  warn $warnmessage unless __PACKAGE__->isa('Parse::Eyapp::Driver'); 
  my($self)=$class->SUPER::new( 
    yyversion => '1.165',
    yyGRAMMAR  =>
[
  [ '_SUPERSTART' => '$start', [ 'a', '$end' ], 0 ],
  [ 'a_is_a_A' => 'a', [ 'a', 'A' ], 0 ],
  [ 'a_is_A' => 'a', [ 'A' ], 0 ],
],
    yyTERMS  =>
{ '' => { ISSEMANTIC => 0 },
	A => { ISSEMANTIC => 1 },
	error => { ISSEMANTIC => 0 },
},
    yyFILENAME  => 'twostarts.eyp',
    yystates =>
[
	{#State 0
		ACTIONS => {
			'A' => 1
		},
		GOTOS => {
			'a' => 2
		}
	},
	{#State 1
		DEFAULT => -2
	},
	{#State 2
		ACTIONS => {
			'A' => 3
		},
		DEFAULT => 4
	},
	{#State 3
		DEFAULT => -1
	},
	{#State 4
		DEFAULT => 0
	}
],
    yyrules  =>
[
	[#Rule _SUPERSTART
		 '$start', 2, undef
#line 114 ./twostarts.pm
	],
	[#Rule a_is_a_A
		 'a', 2,
sub {
#line 0 "twostarts.eyp"
 goto &Parse::Eyapp::Driver::YYBuildAST }
#line 121 ./twostarts.pm
	],
	[#Rule a_is_A
		 'a', 1,
sub {
#line 0 "twostarts.eyp"
 goto &Parse::Eyapp::Driver::YYBuildAST }
#line 128 ./twostarts.pm
	]
],
#line 131 ./twostarts.pm
    yybypass       => 0,
    yybuildingtree => 1,
    yyprefix       => '',
    yyaccessors    => {
   },
    yyconflicthandlers => {}
,
    @_,
  );
  bless($self,$class);

  $self->make_node_classes('TERMINAL', '_OPTIONAL', '_STAR_LIST', '_PLUS_LIST', 
         '_SUPERSTART', 
         'a_is_a_A', 
         'a_is_A', );
  $self;
}

#line 29 "twostarts.eyp"



=for None

=cut


#line 159 ./twostarts.pm

unless (caller) {
  exit !__PACKAGE__->main('');
}


1;
