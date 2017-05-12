########################################################################################
#
#    This file was generated using Parse::Eyapp version 1.182.
#
# (c) Parse::Yapp Copyright 1998-2001 Francois Desarmenien.
# (c) Parse::Eyapp Copyright 2006-2008 Casiano Rodriguez-Leon. Universidad de La Laguna.
#        Don't edit this file, use source file 'lib/Parse/Eyapp/Treeregexp.yp' instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
########################################################################################
package Parse::Eyapp::Treeregparser;
use strict;

push @Parse::Eyapp::Treeregparser::ISA, 'Parse::Eyapp::Driver';




BEGIN {
  # This strange way to load the modules is to guarantee compatibility when
  # using several standalone and non-standalone Eyapp parsers

  require Parse::Eyapp::Driver unless Parse::Eyapp::Driver->can('YYParse');
  require Parse::Eyapp::Node unless Parse::Eyapp::Node->can('hnew'); 
}
  

sub unexpendedInput { defined($_) ? substr($_, (defined(pos $_) ? pos $_ : 0)) : '' }


use Carp;
use Data::Dumper;

our $VERSION = $Parse::Eyapp::Driver::VERSION;

my $debug = 0; # comment
$Data::Dumper::Indent = 1;

# %times: Hash indexed in the variables: stores the number of 
# appearances in the treereg formula
my %times = ();   
my ($tokenbegin, $tokenend);
my $filename; # Name of the input file

{ # closure for $numstar: support code for * treeregexes

  my $numstar = -1; # Number of stars in treereg formula

  sub new_star {
    $numstar++;
    return "W_$numstar";
  }

  sub reset_times {
    %times = ();
    $numstar = -1; # New formula
  }
}

# treereg: IDENT '(' childlist ')' ('and' CODE)? 
sub new_ident_inner { 
  my ($id, $line) = @{$_[1]}; 
  my ($semantic) = $_[5]->children;
  my $node = $_[3];

  $times{$id}++; 

  $node->{id} = $id;
  $node->{line} = $line;
  $node->{semantic} = $semantic? $semantic->{attr} : undef;
  return (bless $node, 'Parse::Eyapp::Treeregexp::IDENT_INNER');
}

# treereg: REGEXP (':' IDENT)? '(' childlist ')' ('and' CODE)? 
sub new_regexp_inner { 
   my $node = $_[4];
   my $line = $_[1][1];

   my $id;

   # $W and @W are default variables for REGEXPs
   if ( $_[2]->children) {
     $id = $_[2]->child(0)->{attr}[0]; 
   }
   else  {
     $id = 'W';
   }
   $times{$id}++;

   $node->{id} = $id;
   $node->{line} = $line;
   $node->{regexp} = $_[1][0]; 
   $node->{options} = $_[1][2];

   my ($semantic) = $_[6]->children;
   $node->{semantic} = $semantic? $semantic->{attr} : undef;
   return bless $node, 'Parse::Eyapp::Treeregexp::REGEXP_INNER';
}

# treereg: SCALAR '(' childlist ')' ('and' CODE)?  
sub new_scalar_inner { 
   my $node = $_[3];
   my ($var, $line) = @{$_[1]};
   $var =~ s/\$//;

   $times{$var}++; 
   _SyntaxError('Repeated scalar in treereg', $_[1][1]) if $times{$var} > 1;
   _SyntaxError(q{Can't use $W to identify an scalar treeregexp}, $_[1][1]) if $var eq 'W'; 

   $node->{id} = $var;
   $node->{line} = $line;
   my ($semantic) = $_[5]->children;
   $node->{semantic} = $semantic? $semantic->{attr} : undef;
   return (bless $node, 'Parse::Eyapp::Treeregexp::SCALAR_INNER');
} 

# treereg: : '.' '(' childlist ')' ('and' CODE)? 
sub new_dot_inner { 
   my $node = $_[3];
   my $line = $_[1][1];
   my $var = 'W';

   $times{$var}++; 

   $node->{id} = $var;
   $node->{line} = $line;
   my ($semantic) = $_[5]->children;
   $node->{semantic} = $semantic? $semantic->{attr} : undef;

   return (bless $node, 'Parse::Eyapp::Treeregexp::SCALAR_INNER');
} 

# treereg: IDENT ('and' CODE)? 
sub new_ident_terminal { 
  my $id = $_[1][0];
  $times{$id}++; 
  
  my ($semantic) = $_[2]->children;
  $semantic = $semantic? $semantic->{attr} : undef;
  
  return (
    bless { children => [], attr => $id, semantic => $semantic }, 'Parse::Eyapp::Treeregexp::IDENT_TERMINAL'
         );
}

# treereg: REGEXP (':' IDENT)? ('and' CODE)? 
sub new_regexp_terminal { 
  # $regexp and @regexp are default variables for REGEXPs
  my $id;
  if ($_[2]->children) {
    $id = {$_[2]->child(0)}->{attr}[0];
  }
  else  {
    $id = 'W';
  }
  $times{$id}++; 

  my ($semantic) = $_[3]->children;
  $semantic = $semantic? $semantic->{attr} : undef;

  return bless { 
    children => [],
    regexp   => $_[1][0], 
    options  => $_[1][2],
    attr     => $id, 
    semantic => $semantic
  }, 'Parse::Eyapp::Treeregexp::REGEXP_TERMINAL' 
}

# treereg: SCALAR ('and' CODE)? 
sub new_scalar_terminal { 
  my $var = $_[1][0];
  $var =~ s/\$//;
  $times{$var}++; 
  _SyntaxError('Repeated scalar in treereg', $_[1][1]) if $times{$var} > 1;
   _SyntaxError(q{Can't use $W to identify an scalar treeregexp}, $_[1][1]) if $var eq 'W'; 

  my ($semantic) = $_[2]->children;
  $semantic = $semantic? $semantic->{attr} : undef;

  return bless {
    children => [],
    attr => $var,
    semantic => $semantic
  }, 'Parse::Eyapp::Treeregexp::SCALAR_TERMINAL'; 
}

# treereg: '.' ('and' CODE)? 
sub new_dot_terminal { 
  # $W and @W are implicit variables for dots "."
  $times{'W'}++; 

  my ($semantic) = $_[2]->children;
  $semantic = $semantic? $semantic->{attr} : undef;

  return bless { 
    children => [], 
    attr => 'W',
    semantic => $semantic
  }, 'Parse::Eyapp::Treeregexp::SCALAR_TERMINAL'; 
}

# treereg: ARRAY 
sub new_array_terminal { 
  my $var = $_[1][0];
  $var =~ s/\@//;

  $times{$var} += 2; # awful trick so that fill_declarations works 
  _SyntaxError( 'Repeated array in treereg', $_[1][1]) if $times{$var} > 2;
  _SyntaxError("Can't use $var to identify an array treeregexp", $_[1][1]) if $var =~ /^W(_\d+)?$/; 

  return bless {
    children => [],
    attr => $var,
  }, 'Parse::Eyapp::Treeregexp::ARRAY_TERMINAL'; 
}

# treereg: '*' 
sub new_array_star { 
  # $wathever_#number and @wathever_#number are reserved for "*"
  my $var = new_star();
  $times{$var} += 2; 

  return bless {
    children => [],
    attr => $var,
  }, 'Parse::Eyapp::Treeregexp::ARRAY_TERMINAL'; 
}




################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################

my $warnmessage =<< "EOFWARN";
Warning!: Did you changed the \@Parse::Eyapp::Treeregparser::ISA variable inside the header section of the eyapp program?
EOFWARN

sub new {
  my($class)=shift;
  ref($class) and $class=ref($class);

  warn $warnmessage unless __PACKAGE__->isa('Parse::Eyapp::Driver'); 
  my($self)=$class->SUPER::new( 
    yyversion => '1.182',
    yyGRAMMAR  =>
[#[productionNameAndLabel => lhs, [ rhs], bypass]]
  [ '_SUPERSTART' => '$start', [ 'treeregexplist', '$end' ], 0 ],
  [ '_STAR_LIST' => 'STAR-1', [ 'STAR-1', 'treeregexp' ], 0 ],
  [ '_STAR_LIST' => 'STAR-1', [  ], 0 ],
  [ 'treeregexplist_3' => 'treeregexplist', [ 'STAR-1' ], 0 ],
  [ '_PAREN' => 'PAREN-2', [ '=>', 'CODE' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-3', [ 'PAREN-2' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-3', [  ], 0 ],
  [ '_PLUS_LIST' => 'PLUS-4', [ 'PLUS-4', 'IDENT' ], 0 ],
  [ '_PLUS_LIST' => 'PLUS-4', [ 'IDENT' ], 0 ],
  [ 'treeregexp_9' => 'treeregexp', [ 'IDENT', ':', 'treereg', 'OPTIONAL-3' ], 0 ],
  [ 'treeregexp_10' => 'treeregexp', [ 'CODE' ], 0 ],
  [ 'treeregexp_11' => 'treeregexp', [ 'IDENT', '=', 'PLUS-4', ';' ], 0 ],
  [ 'treeregexp_12' => 'treeregexp', [ 'REGEXP' ], 0 ],
  [ '_PAREN' => 'PAREN-5', [ 'and', 'CODE' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-6', [ 'PAREN-5' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-6', [  ], 0 ],
  [ '_PAREN' => 'PAREN-7', [ ':', 'IDENT' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-8', [ 'PAREN-7' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-8', [  ], 0 ],
  [ '_PAREN' => 'PAREN-9', [ 'and', 'CODE' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-10', [ 'PAREN-9' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-10', [  ], 0 ],
  [ '_PAREN' => 'PAREN-11', [ 'and', 'CODE' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-12', [ 'PAREN-11' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-12', [  ], 0 ],
  [ '_PAREN' => 'PAREN-13', [ 'and', 'CODE' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-14', [ 'PAREN-13' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-14', [  ], 0 ],
  [ '_PAREN' => 'PAREN-15', [ 'and', 'CODE' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-16', [ 'PAREN-15' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-16', [  ], 0 ],
  [ '_PAREN' => 'PAREN-17', [ ':', 'IDENT' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-18', [ 'PAREN-17' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-18', [  ], 0 ],
  [ '_PAREN' => 'PAREN-19', [ 'and', 'CODE' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-20', [ 'PAREN-19' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-20', [  ], 0 ],
  [ '_PAREN' => 'PAREN-21', [ 'and', 'CODE' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-22', [ 'PAREN-21' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-22', [  ], 0 ],
  [ '_PAREN' => 'PAREN-23', [ 'and', 'CODE' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-24', [ 'PAREN-23' ], 0 ],
  [ '_OPTIONAL' => 'OPTIONAL-24', [  ], 0 ],
  [ 'treereg_43' => 'treereg', [ 'IDENT', '(', 'childlist', ')', 'OPTIONAL-6' ], 0 ],
  [ 'treereg_44' => 'treereg', [ 'REGEXP', 'OPTIONAL-8', '(', 'childlist', ')', 'OPTIONAL-10' ], 0 ],
  [ 'treereg_45' => 'treereg', [ 'SCALAR', '(', 'childlist', ')', 'OPTIONAL-12' ], 0 ],
  [ 'treereg_46' => 'treereg', [ '.', '(', 'childlist', ')', 'OPTIONAL-14' ], 0 ],
  [ 'treereg_47' => 'treereg', [ 'IDENT', 'OPTIONAL-16' ], 0 ],
  [ 'treereg_48' => 'treereg', [ 'REGEXP', 'OPTIONAL-18', 'OPTIONAL-20' ], 0 ],
  [ 'treereg_49' => 'treereg', [ 'SCALAR', 'OPTIONAL-22' ], 0 ],
  [ 'treereg_50' => 'treereg', [ '.', 'OPTIONAL-24' ], 0 ],
  [ 'treereg_51' => 'treereg', [ 'ARRAY' ], 0 ],
  [ 'treereg_52' => 'treereg', [ '*' ], 0 ],
  [ '_STAR_LIST' => 'STAR-25', [ 'STAR-25', ',', 'treereg' ], 0 ],
  [ '_STAR_LIST' => 'STAR-25', [ 'treereg' ], 0 ],
  [ '_STAR_LIST' => 'STAR-26', [ 'STAR-25' ], 0 ],
  [ '_STAR_LIST' => 'STAR-26', [  ], 0 ],
  [ 'childlist_57' => 'childlist', [ 'STAR-26' ], 0 ],
],
    yyLABELS  =>
{
  '_SUPERSTART' => 0,
  '_STAR_LIST' => 1,
  '_STAR_LIST' => 2,
  'treeregexplist_3' => 3,
  '_PAREN' => 4,
  '_OPTIONAL' => 5,
  '_OPTIONAL' => 6,
  '_PLUS_LIST' => 7,
  '_PLUS_LIST' => 8,
  'treeregexp_9' => 9,
  'treeregexp_10' => 10,
  'treeregexp_11' => 11,
  'treeregexp_12' => 12,
  '_PAREN' => 13,
  '_OPTIONAL' => 14,
  '_OPTIONAL' => 15,
  '_PAREN' => 16,
  '_OPTIONAL' => 17,
  '_OPTIONAL' => 18,
  '_PAREN' => 19,
  '_OPTIONAL' => 20,
  '_OPTIONAL' => 21,
  '_PAREN' => 22,
  '_OPTIONAL' => 23,
  '_OPTIONAL' => 24,
  '_PAREN' => 25,
  '_OPTIONAL' => 26,
  '_OPTIONAL' => 27,
  '_PAREN' => 28,
  '_OPTIONAL' => 29,
  '_OPTIONAL' => 30,
  '_PAREN' => 31,
  '_OPTIONAL' => 32,
  '_OPTIONAL' => 33,
  '_PAREN' => 34,
  '_OPTIONAL' => 35,
  '_OPTIONAL' => 36,
  '_PAREN' => 37,
  '_OPTIONAL' => 38,
  '_OPTIONAL' => 39,
  '_PAREN' => 40,
  '_OPTIONAL' => 41,
  '_OPTIONAL' => 42,
  'treereg_43' => 43,
  'treereg_44' => 44,
  'treereg_45' => 45,
  'treereg_46' => 46,
  'treereg_47' => 47,
  'treereg_48' => 48,
  'treereg_49' => 49,
  'treereg_50' => 50,
  'treereg_51' => 51,
  'treereg_52' => 52,
  '_STAR_LIST' => 53,
  '_STAR_LIST' => 54,
  '_STAR_LIST' => 55,
  '_STAR_LIST' => 56,
  'childlist_57' => 57,
},
    yyTERMS  =>
{ '' => { ISSEMANTIC => 0 },
	'(' => { ISSEMANTIC => 0 },
	')' => { ISSEMANTIC => 0 },
	'*' => { ISSEMANTIC => 0 },
	',' => { ISSEMANTIC => 0 },
	'.' => { ISSEMANTIC => 0 },
	':' => { ISSEMANTIC => 0 },
	';' => { ISSEMANTIC => 0 },
	'=' => { ISSEMANTIC => 0 },
	'=>' => { ISSEMANTIC => 0 },
	'and' => { ISSEMANTIC => 0 },
	ARRAY => { ISSEMANTIC => 1 },
	CODE => { ISSEMANTIC => 1 },
	IDENT => { ISSEMANTIC => 1 },
	REGEXP => { ISSEMANTIC => 1 },
	SCALAR => { ISSEMANTIC => 1 },
	error => { ISSEMANTIC => 0 },
},
    yyFILENAME  => 'lib/Parse/Eyapp/Treeregexp.yp',
    yystates =>
[
	{#State 0
		DEFAULT => -2,
		GOTOS => {
			'STAR-1' => 1,
			'treeregexplist' => 2
		}
	},
	{#State 1
		ACTIONS => {
			'REGEXP' => 3,
			'IDENT' => 6,
			'CODE' => 5
		},
		DEFAULT => -3,
		GOTOS => {
			'treeregexp' => 4
		}
	},
	{#State 2
		ACTIONS => {
			'' => 7
		}
	},
	{#State 3
		DEFAULT => -12
	},
	{#State 4
		DEFAULT => -1
	},
	{#State 5
		DEFAULT => -10
	},
	{#State 6
		ACTIONS => {
			":" => 8,
			"=" => 9
		}
	},
	{#State 7
		DEFAULT => 0
	},
	{#State 8
		ACTIONS => {
			'REGEXP' => 10,
			"*" => 11,
			'IDENT' => 12,
			"." => 14,
			'ARRAY' => 13,
			'SCALAR' => 15
		},
		GOTOS => {
			'treereg' => 16
		}
	},
	{#State 9
		ACTIONS => {
			'IDENT' => 17
		},
		GOTOS => {
			'PLUS-4' => 18
		}
	},
	{#State 10
		ACTIONS => {
			":" => 19,
			"(" => -18
		},
		DEFAULT => -33,
		GOTOS => {
			'OPTIONAL-18' => 21,
			'PAREN-17' => 20,
			'OPTIONAL-8' => 22,
			'PAREN-7' => 23
		}
	},
	{#State 11
		DEFAULT => -52
	},
	{#State 12
		ACTIONS => {
			"(" => 25,
			"and" => 26
		},
		DEFAULT => -30,
		GOTOS => {
			'PAREN-15' => 24,
			'OPTIONAL-16' => 27
		}
	},
	{#State 13
		DEFAULT => -51
	},
	{#State 14
		ACTIONS => {
			"(" => 28,
			"and" => 29
		},
		DEFAULT => -42,
		GOTOS => {
			'OPTIONAL-24' => 30,
			'PAREN-23' => 31
		}
	},
	{#State 15
		ACTIONS => {
			"(" => 33,
			"and" => 35
		},
		DEFAULT => -39,
		GOTOS => {
			'OPTIONAL-22' => 32,
			'PAREN-21' => 34
		}
	},
	{#State 16
		ACTIONS => {
			"=>" => 36
		},
		DEFAULT => -6,
		GOTOS => {
			'OPTIONAL-3' => 38,
			'PAREN-2' => 37
		}
	},
	{#State 17
		DEFAULT => -8
	},
	{#State 18
		ACTIONS => {
			";" => 39,
			'IDENT' => 40
		}
	},
	{#State 19
		ACTIONS => {
			'IDENT' => 41
		}
	},
	{#State 20
		DEFAULT => -32
	},
	{#State 21
		ACTIONS => {
			"and" => 44
		},
		DEFAULT => -36,
		GOTOS => {
			'PAREN-19' => 42,
			'OPTIONAL-20' => 43
		}
	},
	{#State 22
		ACTIONS => {
			"(" => 45
		}
	},
	{#State 23
		DEFAULT => -17
	},
	{#State 24
		DEFAULT => -29
	},
	{#State 25
		ACTIONS => {
			'IDENT' => 12,
			'ARRAY' => 13,
			'REGEXP' => 10,
			"*" => 11,
			"." => 14,
			'SCALAR' => 15
		},
		DEFAULT => -56,
		GOTOS => {
			'STAR-26' => 46,
			'STAR-25' => 48,
			'childlist' => 47,
			'treereg' => 49
		}
	},
	{#State 26
		ACTIONS => {
			'CODE' => 50
		}
	},
	{#State 27
		DEFAULT => -47
	},
	{#State 28
		ACTIONS => {
			'IDENT' => 12,
			'ARRAY' => 13,
			'REGEXP' => 10,
			"*" => 11,
			"." => 14,
			'SCALAR' => 15
		},
		DEFAULT => -56,
		GOTOS => {
			'STAR-26' => 46,
			'STAR-25' => 48,
			'childlist' => 51,
			'treereg' => 49
		}
	},
	{#State 29
		ACTIONS => {
			'CODE' => 52
		}
	},
	{#State 30
		DEFAULT => -50
	},
	{#State 31
		DEFAULT => -41
	},
	{#State 32
		DEFAULT => -49
	},
	{#State 33
		ACTIONS => {
			'IDENT' => 12,
			'ARRAY' => 13,
			'REGEXP' => 10,
			"*" => 11,
			"." => 14,
			'SCALAR' => 15
		},
		DEFAULT => -56,
		GOTOS => {
			'STAR-26' => 46,
			'STAR-25' => 48,
			'childlist' => 53,
			'treereg' => 49
		}
	},
	{#State 34
		DEFAULT => -38
	},
	{#State 35
		ACTIONS => {
			'CODE' => 54
		}
	},
	{#State 36
		ACTIONS => {
			'CODE' => 55
		}
	},
	{#State 37
		DEFAULT => -5
	},
	{#State 38
		DEFAULT => -9
	},
	{#State 39
		DEFAULT => -11
	},
	{#State 40
		DEFAULT => -7
	},
	{#State 41
		ACTIONS => {
			"(" => -16
		},
		DEFAULT => -31
	},
	{#State 42
		DEFAULT => -35
	},
	{#State 43
		DEFAULT => -48
	},
	{#State 44
		ACTIONS => {
			'CODE' => 56
		}
	},
	{#State 45
		ACTIONS => {
			'IDENT' => 12,
			'ARRAY' => 13,
			'REGEXP' => 10,
			"*" => 11,
			"." => 14,
			'SCALAR' => 15
		},
		DEFAULT => -56,
		GOTOS => {
			'STAR-26' => 46,
			'STAR-25' => 48,
			'childlist' => 57,
			'treereg' => 49
		}
	},
	{#State 46
		DEFAULT => -57
	},
	{#State 47
		ACTIONS => {
			")" => 58
		}
	},
	{#State 48
		ACTIONS => {
			"," => 59
		},
		DEFAULT => -55
	},
	{#State 49
		DEFAULT => -54
	},
	{#State 50
		DEFAULT => -28
	},
	{#State 51
		ACTIONS => {
			")" => 60
		}
	},
	{#State 52
		DEFAULT => -40
	},
	{#State 53
		ACTIONS => {
			")" => 61
		}
	},
	{#State 54
		DEFAULT => -37
	},
	{#State 55
		DEFAULT => -4
	},
	{#State 56
		DEFAULT => -34
	},
	{#State 57
		ACTIONS => {
			")" => 62
		}
	},
	{#State 58
		ACTIONS => {
			"and" => 65
		},
		DEFAULT => -15,
		GOTOS => {
			'PAREN-5' => 63,
			'OPTIONAL-6' => 64
		}
	},
	{#State 59
		ACTIONS => {
			'REGEXP' => 10,
			"*" => 11,
			'IDENT' => 12,
			"." => 14,
			'ARRAY' => 13,
			'SCALAR' => 15
		},
		GOTOS => {
			'treereg' => 66
		}
	},
	{#State 60
		ACTIONS => {
			"and" => 69
		},
		DEFAULT => -27,
		GOTOS => {
			'PAREN-13' => 67,
			'OPTIONAL-14' => 68
		}
	},
	{#State 61
		ACTIONS => {
			"and" => 71
		},
		DEFAULT => -24,
		GOTOS => {
			'OPTIONAL-12' => 70,
			'PAREN-11' => 72
		}
	},
	{#State 62
		ACTIONS => {
			"and" => 75
		},
		DEFAULT => -21,
		GOTOS => {
			'OPTIONAL-10' => 73,
			'PAREN-9' => 74
		}
	},
	{#State 63
		DEFAULT => -14
	},
	{#State 64
		DEFAULT => -43
	},
	{#State 65
		ACTIONS => {
			'CODE' => 76
		}
	},
	{#State 66
		DEFAULT => -53
	},
	{#State 67
		DEFAULT => -26
	},
	{#State 68
		DEFAULT => -46
	},
	{#State 69
		ACTIONS => {
			'CODE' => 77
		}
	},
	{#State 70
		DEFAULT => -45
	},
	{#State 71
		ACTIONS => {
			'CODE' => 78
		}
	},
	{#State 72
		DEFAULT => -23
	},
	{#State 73
		DEFAULT => -44
	},
	{#State 74
		DEFAULT => -20
	},
	{#State 75
		ACTIONS => {
			'CODE' => 79
		}
	},
	{#State 76
		DEFAULT => -13
	},
	{#State 77
		DEFAULT => -25
	},
	{#State 78
		DEFAULT => -22
	},
	{#State 79
		DEFAULT => -19
	}
],
    yyrules  =>
[
	[#Rule _SUPERSTART
		 '$start', 2, undef
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _STAR_LIST
		 'STAR-1', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _STAR_LIST
		 'STAR-1', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treeregexplist_3
		 'treeregexplist', 1,
sub {  $_[1]->{children} }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PAREN
		 'PAREN-2', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforParenthesis}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-3', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-3', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PLUS_LIST
		 'PLUS-4', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PLUS_LIST
		 'PLUS-4', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treeregexp_9
		 'treeregexp', 4,
sub {  
        my $name = $_[1][0];
        my $tree = $_[3];
        my ($action) = $_[4]->children;
        my $self = bless { 
                     name => $name, 
                     times => [ %times ], 
                     children => [$tree, $action->{attr} ]
                   }, 'Parse::Eyapp::Treeregexp::TREEREGEXP'; 
        reset_times();
        print Dumper($self) if $debug;
        $self;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treeregexp_10
		 'treeregexp', 1,
sub {  bless $_[1], 'Parse::Eyapp::Treeregexp::GLOBALCODE';  }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treeregexp_11
		 'treeregexp', 4,
sub {  bless { name => $_[1], members => $_[3] }, 'Parse::Eyapp::Treeregexp::FAMILY'; }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treeregexp_12
		 'treeregexp', 1,
sub {  
        _SyntaxError("Expected an Identifier for the treeregexp",  $tokenend); 
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PAREN
		 'PAREN-5', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforParenthesis}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-6', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-6', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PAREN
		 'PAREN-7', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforParenthesis}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-8', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-8', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PAREN
		 'PAREN-9', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforParenthesis}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-10', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-10', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PAREN
		 'PAREN-11', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforParenthesis}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-12', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-12', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PAREN
		 'PAREN-13', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforParenthesis}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-14', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-14', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PAREN
		 'PAREN-15', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforParenthesis}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-16', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-16', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PAREN
		 'PAREN-17', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforParenthesis}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-18', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-18', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PAREN
		 'PAREN-19', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforParenthesis}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-20', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-20', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PAREN
		 'PAREN-21', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforParenthesis}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-22', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-22', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _PAREN
		 'PAREN-23', 2,
sub {  goto &Parse::Eyapp::Driver::YYActionforParenthesis}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-24', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _OPTIONAL
		 'OPTIONAL-24', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treereg_43
		 'treereg', 5,
sub {  
        goto &new_ident_inner;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treereg_44
		 'treereg', 6,
sub {  
         goto &new_regexp_inner;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treereg_45
		 'treereg', 5,
sub {  
         goto &new_scalar_inner;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treereg_46
		 'treereg', 5,
sub {  
         goto &new_dot_inner;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treereg_47
		 'treereg', 2,
sub {  
        goto &new_ident_terminal;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treereg_48
		 'treereg', 3,
sub {  
        goto &new_regexp_terminal;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treereg_49
		 'treereg', 2,
sub {  
        goto &new_scalar_terminal;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treereg_50
		 'treereg', 2,
sub {  
        goto &new_dot_terminal;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treereg_51
		 'treereg', 1,
sub {  
        goto &new_array_terminal;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule treereg_52
		 'treereg', 1,
sub {  
        goto &new_array_star;
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _STAR_LIST
		 'STAR-25', 3,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_TX1X2 }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _STAR_LIST
		 'STAR-25', 1,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_single }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _STAR_LIST
		 'STAR-26', 1,
sub {  { $_[1] } # optimize 
}
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule _STAR_LIST
		 'STAR-26', 0,
sub {  goto &Parse::Eyapp::Driver::YYActionforT_empty }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	],
	[#Rule childlist_57
		 'childlist', 1,
sub {  
        my @list = $_[1]->children(); 
        my @New = ();
        my ($r, $b);
        my $numarrays = 0;

        # Merge array prefixes with its successors
        local $_;
        while (@list) {
          $_ = shift @list;
          if ($_->isa('Parse::Eyapp::Treeregexp::ARRAY_TERMINAL')) {
            $numarrays++;
            $r = shift @list;
            if (defined($r)) {
              croak "Error. Two consecutive lists are not allowed!" if $r->isa('Parse::Eyapp::Treeregexp::ARRAY_TERMINAL');
              $r->{arrayprefix} = $_->{attr};
              $_ = $r;
            }
          }
          push @New, $_;
        }
        $_[1]->{numarrays} = $numarrays;
        $_[1]->{children} = \@New;
        $_[1];
      }
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
	]
],
################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################
    yybypass       => 0,
    yybuildingtree => 0,
    yyprefix       => '',
    yyaccessors    => {
   },
    yyconflicthandlers => {}
,
    yystateconflict => {  },
    @_,
  );
  bless($self,$class);

  $self->make_node_classes('TERMINAL', '_OPTIONAL', '_STAR_LIST', '_PLUS_LIST', 
         '_SUPERSTART', 
         '_STAR_LIST', 
         '_STAR_LIST', 
         'treeregexplist_3', 
         '_PAREN', 
         '_OPTIONAL', 
         '_OPTIONAL', 
         '_PLUS_LIST', 
         '_PLUS_LIST', 
         'treeregexp_9', 
         'treeregexp_10', 
         'treeregexp_11', 
         'treeregexp_12', 
         '_PAREN', 
         '_OPTIONAL', 
         '_OPTIONAL', 
         '_PAREN', 
         '_OPTIONAL', 
         '_OPTIONAL', 
         '_PAREN', 
         '_OPTIONAL', 
         '_OPTIONAL', 
         '_PAREN', 
         '_OPTIONAL', 
         '_OPTIONAL', 
         '_PAREN', 
         '_OPTIONAL', 
         '_OPTIONAL', 
         '_PAREN', 
         '_OPTIONAL', 
         '_OPTIONAL', 
         '_PAREN', 
         '_OPTIONAL', 
         '_OPTIONAL', 
         '_PAREN', 
         '_OPTIONAL', 
         '_OPTIONAL', 
         '_PAREN', 
         '_OPTIONAL', 
         '_OPTIONAL', 
         '_PAREN', 
         '_OPTIONAL', 
         '_OPTIONAL', 
         'treereg_43', 
         'treereg_44', 
         'treereg_45', 
         'treereg_46', 
         'treereg_47', 
         'treereg_48', 
         'treereg_49', 
         'treereg_50', 
         'treereg_51', 
         'treereg_52', 
         '_STAR_LIST', 
         '_STAR_LIST', 
         '_STAR_LIST', 
         '_STAR_LIST', 
         'childlist_57', );
  $self;
}



my $input;

sub _Lexer {

  return('', undef) unless defined($input);

  #Skip blanks
  $input=~m{\G((?:
          \s+       # any white space char
      |   \#[^\n]*  # Perl like comments
      |   /\*.*?\*/ # C like comments
      )+)}xsgc
    and do {
        my($blanks)=$1;

        #Maybe At EOF
            pos($input) >= length($input)
        and return('', undef);
        $tokenend += $blanks =~ tr/\n//;
    };
    
    $tokenbegin = $tokenend;

        $input=~/\G(and)/gc
    and return($1, [$1, $tokenbegin]);

        $input=~/\G([A-Za-z_][A-Za-z0-9_]*)/gc
    and do {
      return('IDENT', [$1, $tokenbegin]);
    };

        $input=~/\G(\$[A-Za-z_][A-Za-z0-9_]*)/gc
    and do {
      return('SCALAR', [$1, $tokenbegin]);
    };

        $input=~/\G(\@[A-Za-z_][A-Za-z0-9_]*)/gc
    and do {
      return('ARRAY', [$1, $tokenbegin]);
    };
        $input=~m{\G/(
                      (?:[^/\\]| # no escape or slash
                           \\\\| # escaped escape
                            \\/| # escaped slash
                             \\  # escape
                      )+?
                    )
                   /([Begiomxsc]*)}xgc
    and do {
        # $x=~ s/((?:[a-zA_Z_]\w*::)*(?:[a-zA_Z_]\w*))/\\b$1\\b/g
        my $string = $1;
        my $options = $2? $2 : '';
        $tokenend += $string =~ tr/\n//;

        # Default behavior: Each perl identifier is surrounded by \b boundaries
        # Use "B" option to negate this behavior
          $string =~ s/((?:[a-zA-Z_][a-zA-Z_0-9]*::)*(?:[a-zA-Z_][a-zA-Z_0-9]*))/\\b$1\\b/g
        unless $options =~ s{B}{};

        # Default behavior: make "x" default option
        # Use X option to negate this behavior
        $options .= "x" unless ($options =~ m{x} or $options =~ s{X}{});

        return('REGEXP', [$string, $tokenbegin, $options]);
    };
        $input=~/\G%{/gc
    and do {
        my($code);

            $input=~/\G(.*?)%}/sgc
        or  _SyntaxError( "Unmatched %{", $tokenbegin);

        $code=$1;
        $tokenend+= $code=~tr/\n//;
        return('Parse::Eyapp::Treeregexp::GLOBALCODE', [$code, $tokenbegin]);
    };

        $input=~/\G{/gc
    and do {
        my($level,$from,$code);

        $from=pos($input);

        $level=1;
        while($input=~/([{}])/gc) {
                substr($input,pos($input)-1,1) eq '\\' #Quoted
            and next;
                $level += ($1 eq '{' ? 1 : -1)
            or last;
        }
            $level
        and  _SyntaxError("Not closed open curly bracket { at $tokenbegin");
        $code = substr($input,$from,pos($input)-$from-1);
        $tokenend+= $code=~tr/\n//;
        return('CODE', [$code, $tokenbegin]);
    };

        $input=~/\G(=>)/gc
    and return($1, $1);

    #Always return something
      $input=~/\G(.)/sg
    and do {
      $1 eq "\n" and ++$tokenend;
      return ($1, [$1, $tokenbegin]);
    };
    #At EOF
    return('', undef);
}

sub _Error {
  my($value)=$_[0]->YYCurval;

  die "Syntax Error at end of file\n" unless (defined($value) and ref($value) eq 'ARRAY');
  my($what)= "input: '$$value[0]'";

  _SyntaxError("Unexpected $what",$$value[1]);
}

sub _SyntaxError {
   my($message,$lineno)=@_;

   $message= "Error in file $filename: $message, at ".
             ($lineno < 0 ? "eof" : "line $lineno").
             ".\n";

   die $message;
}

####################################################################
# Purpose    : Treeregexp compiler bottom end. Code generation.

package Parse::Eyapp::Treeregexp;
use Carp;
use List::Util qw(first);
use Parse::Eyapp::Base qw(compute_lines slurp_file valid_keys invalid_keys write_file);

my %index;    # Index of each ocurrence of a variable
my $prefix;   # Assume each AST node name /class is prefixed by $prefix
my $severity = 0; # 0 = Don't  check arity. 1 = Check arity. 2 = Check and give a warning 3 = ... croak
my $allowlinenumbers = 1; # Enable/Disable line number directives
#my $warninfo = "Line numbers in error messages are relative to the line where new is called.\n";
my %methods; # $method{$treeclass} = [ array of YATW objects or transformations ]
my $ouputlinepattern = '##line NUM FILE # line in code by treeregexp';

sub compute_var_name {
  my $var = shift;

  my $nodename;
  if ($times{$var} > 1) { # node is array
    $nodename = $index{$var}++;
    $nodename = '$'."$var\[$nodename]";
  }
  else {
    $nodename = '$'.$var;
  }
  return $nodename;
}

####################################################################
# Usage      :    
#   my $transform = Parse::Eyapp::Treeregexp->new( STRING => q{
#      zero_times: TIMES(NUM($x), ., .) and { $x->{attr} == 0 } => { $_[0] = $NUM }
#      times_zero: TIMES(., ., NUM($x)) and { $x->{attr} == 0 } => { $_[0] = $NUM }
#    },
#    PACKAGE => 'Transformations',
#    OUTPUTFILE => 'main.pm',
#    SEVERITY => 0,
#    NUMBERS => 0,
# ) ;
# Returns    : A Parse::Eyapp::Treeregexp object
# Throws     : croak  if STRING and INFILE are defined or if no input is provided
#              also if the PACKAGE isrg does not contain a valid identifier
# Parameters : 
my %_Trnew = (
  PACKAGE => 'STRING',    # The package where the module will reside
  PREFIX => 'STRING',     # prefix for all the node classes
  OUTPUTFILE => 'STRING', # If specified the package will be dumped to such file
  SYNTAX => 'BOOL',       # Check perl actions syntax after generating the package
  SEVERITY => 'INT',      # Controls the level of checking matching the number of childrens
  PERL5LIB => 'ARRAY',    # Search path
  INFILE => 'STRING',     # Input file containing the grammar
  STRING => 'STRING',     # Input string containing the grammar. Incompatible with INFILE
  NUMBERS => 'BOOL',      # Generate (or not) #line directives
  FIRSTLINE => 'INT',     # Use it only with STRING. The linenumber where the string
                          # containing the grammar begins
);
my $validkeys = valid_keys(%_Trnew);

sub new {
  my $class = shift;
  croak "Error in new_package: Use named arguments" if (@_ %2);
  my %arg = @_;

  if (defined($a = invalid_keys(\%_Trnew, \%arg))) {
    croak( "Parse::Eyapp::Treeregexp::new Error!: unknown argument $a. "
          ."Valid arguments are: $validkeys")
  }
  my $checksyntax = 1;
  $checksyntax = $arg{SYNTAX} if exists($arg{SYNTAX});

  my ($packagename, $outputfile) = ($arg{PACKAGE}, $arg{OUTPUTFILE});

  # file scope variables
  $filename = $arg{INFILE};
  
  my $perl5lib = $arg{PERL5LIB} || [];

  #package scope variables
  $severity = $arg{SEVERITY};
  $prefix = $arg{PREFIX} || '';
  $allowlinenumbers = defined($arg{NUMBERS})?$arg{NUMBERS}:1 ;

  my $input_from_file = 0;
  $tokenbegin = $tokenend = 1;

  $input = $arg{STRING};
  if (defined($filename)) {
    $input_from_file = 1;
    croak "STRING and INFILE parameters are mutually exclusive " if defined($input);
    $input = slurp_file($filename, 'trg');
  }
  elsif (defined($input)) { # input from string
    my ($callerpackagename);
    ($callerpackagename, $filename, $tokenend) = caller;

      $packagename = $callerpackagename 
    unless defined($packagename)  # Perl identifier regexp
           and $packagename =~ /(?:[A-Za-z_][A-Za-z0-9_]*::)*[A-Za-z_][A-Za-z0-9_]*/;

  }
  else { 
    croak "Undefined input.";
  }
  ($packagename) = $filename =~ m{(^[a-zA-Z_]\w*)} if !defined($packagename);
  $tokenend = $arg{FIRSTLINE} if exists($arg{FIRSTLINE}) and $arg{FIRSTLINE} =~ m{^\s*\d+};
  $tokenbegin = $tokenend;
    croak "Bad formed package name" 
  unless $packagename =~ m{^(?:[A-Za-z_][A-Za-z0-9_]*::)* # Perl identifier: prefix
                            (?:[A-Za-z_][A-Za-z0-9_]*)$}x;


  #my ($basename) = $packagename =~ m{([a-zA-Z]\w*$)};
  #$outputfile = "$basename.pm" unless defined($outputfile);

  my $object = bless {
           'INPUT_FROM_FILE' => $input_from_file,
           'PACKAGENAME'     => $packagename, 
           'OUTPUTFILE'      => $outputfile, 
           'CHECKSYNTAX'     => $checksyntax, 
           'PERL5LIB'        => $perl5lib,
         }, $class;
  return $object;
}

sub has_array_prefix {
  my $self = shift;

  return defined($self->{arrayprefix})
}

{ # closure with $formula $declarations and $text

  my $formula;
  my $declarations;
  my $text = '';

  sub _generate_treereg_code {
    my $treereg = shift; # the node
    my $father = shift;  
    my $source = shift; # Perl code describing how access this node
    my $order = shift;  # my index in the array of children

    my $name = ref($treereg) || $treereg;
    my $aux;
    my $nodename;
    my $is_array = has_array_prefix($treereg);

    ($nodename, $aux) = $treereg->translate($father, $source, $order);
    $formula .= $aux;
    return if (ref($treereg) =~ m{TERMINAL$} or $is_array);

    # $j : index of the child in the treeregexp formula not counting arrays
    my $j = 0;
    for (@{$treereg->{children}}) {

      # Saving $is_array has to be done before the call to
      #_generate_treereg_code, since 
      # we delete the array_prefix entry after processing node $_
      # (See sub translate_array_prefix)
      $is_array = has_array_prefix($_); 
      _generate_treereg_code($_, $nodename, "$nodename->child($j+\$child_index)", $j);
      $j++ unless $is_array;
    }
    if (my $pat = $treereg->{semantic}) {
      my $pattern = process_pattern($pat, $filename);
      $formula .= $pattern;
    }
  }

  sub generate_treereg_code {
    my $treereg = shift;

    $formula = '';
    _generate_treereg_code($treereg, '', '$_[$child_index]', undef);
  }
    
  # Parameters:
  # $checksyntax: controls whether or not to check Perl code for syntax errors
  sub generate {
    my $self = shift;
      croak "Error at ".__PACKAGE__."::generate. Expected a ".__PACKAGE__." object." 
    unless $self->isa(__PACKAGE__);
    my $checksyntax =  $self->{'CHECKSYNTAX'} || 1;
    my ($input_from_file, $packagename, $outputfile) 
      = @$self{'INPUT_FROM_FILE', 'PACKAGENAME', 'OUTPUTFILE',};

    my $parser = Parse::Eyapp::Treeregparser->new();
    my $t = $parser->YYParse( yylex => \&Parse::Eyapp::Treeregparser::_Lexer, 
                              yyerror => \&Parse::Eyapp::Treeregparser::_Error,
                              yybuildingtree => 1);

    # Traverse the tree generating the pattern-action subroutine
    my ($names, @names, %family); # Names of the generated subroutines
    my @Transformations = @$t;
    for my $transform (@Transformations) {
      $transform->isa('Parse::Eyapp::Treeregexp::GLOBALCODE')
        and do { 
          $text .= $transform->translate();
          next; # iteration done 
        };

      $transform->isa('Parse::Eyapp::Treeregexp::FAMILY') 
        and do  {
          my ($name, @members) = ($transform->{name}[0], @{$transform->{members}{children}});
          push @{$family{$name}}, @members;
          next;
        };
      my ($treereg, $action)  = @{$transform->{children}}; 

      %times = @{$transform->{times}}; # global scope visible. Weakness
      %index = ();
      &fill_declarations(\$declarations);

      my $name = $transform->{name};

      $action ||= ""; # To Do
      $names .= "$name ";
      generate_treereg_code($treereg);
      my @classes = $treereg->classes;
      push @{$methods{$_}}, $name for @classes;

      $text .= fill_translation_sub($name, \$declarations, \$formula, $action, $filename);
    } # for my $transform ...

    $text = fill_translation_package($filename, $packagename, \$text, $names, \%family);

    if ($input_from_file or defined($outputfile)) {
      compute_lines(\$text, $outputfile, $ouputlinepattern) if $self->{NUMBERS};
      write_file($outputfile, \$text);
      if ($self->{CHECKSYNTAX}) {
        push @INC, @{$self->{PERL5LIB}};
        require $outputfile;
      }
    }
    else {
      print $text if $debug;
      if ($self->{CHECKSYNTAX}) {
        push @INC, @{$self->{PERL5LIB}};
        croak $@ unless eval $text;
      }
    }

    undef %times;
    undef %index;
    undef $tokenbegin;
    undef $tokenend;
    undef $prefix;
    undef $input;
    undef $declarations;
    undef $text;
    undef $filename;
    return 1;
  }

  sub translate_array_prefix {
    my ($self, $father, $order) = @_;

    my $localformula = $formula;
    
    my $arrname = $self->{arrayprefix};
    delete($self->{arrayprefix});
    generate_treereg_code($self);
    my $aux = fill_translation_array_sub($self, $arrname, $order, \$formula, $father);
    
    $formula = $localformula;

    return $aux;
  }

} # closure with $formula $declarations and $text

sub make_references_to_subs {
  $_[0] =~ s/\b([a-z_A-Z]\w*)\b/$1 => \\\&$1,/g;
}

sub unique {
  my %saw = ();
  my @out = grep(!$saw{$_}++, @_);
  return @out;
}

# Checks that all the transformation rules in the list have been defined
sub check_existence {
  my $familyname = shift;
  my $names = shift;
  my $line = shift;

  for (@_) {
    croak "Error! treereg rule '$_' not defined (family '$familyname' at line $line)." 
      unless $names =~ m/\b$_\b/;
  }
}

sub translate {
  my ($self, $father, $order, $translation) = @_;

  $translation = translate_array_prefix($self, $father, $order) if has_array_prefix($self);
  return $translation;
}

######### Fill subroutines ##########

sub linenumber {
  my ($linenumber, $filename) = @_;

  return "#line $linenumber \"$filename\"" if $allowlinenumbers;
  return '';
 }

####################################################################
# Usage      : fill_translation_array_sub($self, $arrname, $order, \$formula, $father);
# Purpose    : translation of array atoms in treeregexps like  ABC(@a, B, @c)
# Returns    : the text containing the sub handler and the loop
# Parameters : $name:    gives the name to the array and to the sub handler
#              $order:   index of the array formula as child
#              $formula: declarations
#              $father:  the father node of the array tree pattern

sub fill_translation_array_sub {
   my ($self, $name, $order, $formula, $father, $line) = @_;
 
   chomp($$formula);
   my $sname = '$'.$name; # var referencing the sub 
   my $aname = '@'.$name; # the array that will hold the nodes
   $line = '' unless defined($line);

   return <<"END_TRANSLATION_STAR_SUB";
      my $sname = sub {
      my \$child_index = 0;
  $$formula
$line
      return 1;
      }; # end anonymous sub $sname

      return 0 unless until_first_match(
                      $father, $order, $sname, \\$aname);
      \$child_index += 1+$aname;
END_TRANSLATION_STAR_SUB
} # sub fill_translation_array_sub

sub process_pattern {
  my ($pat, $filename) = @_;
  
  my $linenodirective = linenumber($pat->[1], $filename);
  my ($pattern);
  if (defined($pat)) { 
    $pattern =<<"ENDOFPATTERN"; 
    return 0 unless do 
$linenodirective 
      {$pat->[0]};
ENDOFPATTERN
  }
  else {
    $pattern = '';
    #chomp($formula);
  }
  return $pattern;
}

sub process_action {
  my ($action, $filename) = @_;

  my ($actiontext);

  if ($action) {
    my $line_directive = linenumber($action->[1], $filename);
    $actiontext = "$line_directive\n".
                  "  { $action->[0]}";
    }
  else {
    $actiontext = "      1;"
  }
  return $actiontext;
}

sub fill_translation_sub {
  my ($name, $declarations, $formula, $action, $filename, $line) = @_;
  my ($actiontext);

  $line = '' unless defined($line);
  $actiontext = process_action($action, $filename);

  return <<"END_TREEREG_TRANSLATIONS";

  sub $name { 
    my \$$name = \$_[3]; # reference to the YATW pattern object
$$declarations
    {
      my \$child_index = 0;

  $$formula
    } # end block of child_index
$actiontext

  } # end of $name 
$line
END_TREEREG_TRANSLATIONS
} # end sub fill_translation_sub

sub fill_declarations {
  my $declarations = shift;

  $$declarations = '';
  for (keys(%times)) {
    $$declarations .= "    my \$$_;\n", next if ($times{$_} == 1);
    $$declarations .= "    my \@$_;\n"
  }
}

sub fill_translation_package {
  my ($filename, $packagename, $code, $names, $family) = @_;
  my $familiesdecl = '';

   for (keys %$family) {
     my $t;
     my @members = map { $t = $_->{attr}; $t->[0] } @{$family->{$_}};
     @members = unique(@members);
     my $line = $family->{$_}[0]{attr}[1];
     check_existence($_, $names, $line, @members);
     $t = "@members";
     &make_references_to_subs($t);
     my $line_directive = linenumber($line, $filename);
     $familiesdecl .= "$line_directive\n".
               "our \@$_ = Parse::Eyapp::YATW->buildpatterns($t);\n"; # TODO lines, etc.
   }

  my $scalar_names;
  ($scalar_names = $names) =~ s/\b([a-z_A-Z]\w*)\b/our \$$1,/g;;
  &make_references_to_subs($names);
  $familiesdecl .= "our \@all = ( $scalar_names) = Parse::Eyapp::YATW->buildpatterns($names);\n";

  return <<"END_PACKAGE_TRANSLATIONS";
package $packagename;

# This module has been generated using Parse::Eyapp::Treereg
# from file $filename. Don't modify it.
# Change $filename instead.
# Copyright (c) Casiano Rodriguez-Leon 2006. Universidad de La Laguna.
# You may use it and distribute it under the terms of either
# the GNU General Public License or the Artistic License,
# as specified in the Perl README file.

use strict;
use warnings;
use Carp;
use Parse::Eyapp::_TreeregexpSupport qw(until_first_match checknumchildren);

$familiesdecl
$$code
1;

END_PACKAGE_TRANSLATIONS
} # end of sub fill_translation_package

######## TERMINAL classes #########
sub code_translation {
  my $self = shift;

  my $pat = $self->{semantic};
  return process_pattern($pat, $filename) if $pat;
  return '';
}

######## Parse::Eyapp::Treeregexp::REGEXP_TERMINAL  #########

sub Parse::Eyapp::Treeregexp::REGEXP_TERMINAL::translate {
  my ($self, $father, $source, $order) = @_;

  # nodename is the variable associated with the tree node i.e.
  # for a node NUM it may be $NUM[0] or similar
  my ($nodename, $aux);
  $nodename = '$'.$self->{attr};
  
  my ($regexp, $options) = ($self->{regexp}, $self->{options});
  $aux = translate($self, $father, $order, 
                   "    return 0 unless ref($nodename = $source) =~ m{$regexp}$options;\n");
  $aux .= code_translation($self);
  return ($nodename, $aux);
}

sub Parse::Eyapp::Treeregexp::REGEXP_TERMINAL::classes {
  my $treereg = shift;

  my $regexp = $treereg->{regexp};

  # what if option "B" is used?
  my @classes;
  @classes = $regexp =~ m/\\b|((?:[a-zA-Z_][a-zA-Z_0-9]*::)*(?:[a-zA-Z_][a-zA-Z_0-9]*))/g;
  return grep {defined($_) } @classes;
}

######## Parse::Eyapp::Treeregexp::SCALAR_TERMINAL  #########

sub Parse::Eyapp::Treeregexp::SCALAR_TERMINAL::translate {
  my ($self, $father, $source, $order) = @_;

  my ($nodename, $aux);

  # Warning! not needed for scalars but for Ws (see alias)
  $nodename = Parse::Eyapp::Treeregexp::compute_var_name($self->{attr});
  $aux = translate($self, $father, $order, 
                   "    return 0 unless defined($nodename = $source);\n");

  $aux .= code_translation($self);
  return ($nodename, $aux);
}

sub Parse::Eyapp::Treeregexp::SCALAR_TERMINAL::classes {
  my $self = shift;

  return ('*');
}

######## Parse::Eyapp::Treeregexp::IDENT_TERMINAL  #########
sub Parse::Eyapp::Treeregexp::IDENT_TERMINAL::translate {
  my ($self, $father, $source, $order) = @_;

  my ($nodename, $aux);
  my $name = $self->{attr};
  $nodename = Parse::Eyapp::Treeregexp::compute_var_name($self->{attr});
  $aux = translate($self, $father, $order, 
                   "    return 0 unless ref($nodename = $source) eq '$prefix$name';\n");
  $aux .= code_translation($self);
  return ($nodename, $aux);
}

sub Parse::Eyapp::Treeregexp::IDENT_TERMINAL::classes {
  my $treereg = shift;

  my @classes = ($treereg->{attr});
  return @classes;
}

######## Parse::Eyapp::Treeregexp::ARRAY_TERMINAL  #########
sub Parse::Eyapp::Treeregexp::ARRAY_TERMINAL::translate {
  my ($self, $father, $source, $order) = @_;

  my ($nodename, $aux);
  my $id = $self->{attr};
  $nodename = '@'.$id;
  $aux = translate($self, $father, $order, 
                   "    $nodename = ($father->children);\n".
                   "    $nodename = $nodename\[\$child_index+$order..\$#$id];\n"
                  ); 
  return ($nodename, $aux);
}

sub Parse::Eyapp::Treeregexp::ARRAY_TERMINAL::classes {
  croak "Fatal error: Parse::Eyapp::Treeregexp::ARRAY_TERMINAL::classes called from the root of a tree";
}

############### INNER classes ###############
sub generate_check_numchildren {
  my ($self, $nodename, $severity) = @_;

  return '' unless $severity;

  my $name = $self->{id};
  my $numexpected = @{$self->{children}};
  my $line = $self->{line};

  my $warning = "    return 0 unless checknumchildren($nodename, $numexpected, $line, ".
                      "'$filename', $self->{numarrays}, $severity);\n";
  return $warning;
}

############### Parse::Eyapp::Treeregexp::REGEXP_INNER ###############

sub Parse::Eyapp::Treeregexp::REGEXP_INNER::translate {
  my ($self, $father, $source, $order) = @_;

  my ($nodename, $aux);

  my $name = $self->{id};
  $nodename = Parse::Eyapp::Treeregexp::compute_var_name($name);

  my $warning = generate_check_numchildren($self, $nodename, $severity);

  my ($regexp, $options) = ($self->{regexp}, $self->{options});

  # TODO #line goes here
  my $template = "    return 0 unless ref($nodename = $source) =~ m{$regexp}$options;\n"
                 .    $warning;
  $aux = translate($self, $father, $order, $template);
  return ($nodename, $aux);
}

*Parse::Eyapp::Treeregexp::REGEXP_INNER::classes = \&Parse::Eyapp::Treeregexp::REGEXP_TERMINAL::classes;
  
############### Parse::Eyapp::Treeregexp::IDENT_INNER ###############

sub Parse::Eyapp::Treeregexp::IDENT_INNER::translate {
   my ($self, $father, $source, $order) = @_;

  my ($nodename, $aux);

  my $name = $self->{id};
  $nodename = Parse::Eyapp::Treeregexp::compute_var_name($name);

  my $warning = generate_check_numchildren($self, $nodename, $severity);

  my $template = "    return 0 unless (ref($nodename = $source) eq '$prefix$name');\n"
                       .    $warning;
  $aux = translate($self, $father, $order, $template);
  return ($nodename, $aux);
}

sub Parse::Eyapp::Treeregexp::IDENT_INNER::classes {
  my $treereg = shift;

  my @classes = ( $treereg->{id} );
  return @classes;
}

############### Parse::Eyapp::Treeregexp::SCALAR_INNER ###############

sub Parse::Eyapp::Treeregexp::SCALAR_INNER::translate {
   my ($self, $father, $source, $order) = @_;

  my ($nodename, $aux);

  my $name = $self->{id};

  # Warning! not needed for scalars but for Ws 
  $nodename = Parse::Eyapp::Treeregexp::compute_var_name($name);

  my $warning = generate_check_numchildren($self, $nodename, $severity);

  my $template = "    return 0 unless defined($nodename = $source);\n"
                 .    $warning;
  $aux = translate($self, $father, $order, $template);
  return ($nodename, $aux);
}

*Parse::Eyapp::Treeregexp::SCALAR_INNER::classes = \&Parse::Eyapp::Treeregexp::SCALAR_TERMINAL::classes;

########## Parse::Eyapp::Treeregexp::GLOBALCODE #############

sub Parse::Eyapp::Treeregexp::GLOBALCODE::translate {
  my $transform = shift;

  my $line_directive = linenumber($transform->[1], $filename);
  return "$line_directive\n".
         "$transform->[0]\n";
};



=for None

=cut


################ @@@@@@@@@ End of User Code @@@@@@@@@ ###################



1;
