package VerilogGrammar;

=for

    VerilogGrammar - Parsing HUGE gate level verilog files a little bit at a time.
    Copyright (C) 2001  Greg London

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


## See POD after __END__


require 5.005_62;

use strict;
use warnings;

our @ISA = qw( Parse::Nibbler );

use Data::Dumper;


use Parse::Nibbler;

our $VERSION = '1.08';


package Parse::Nibbler;

my $handle;


sub dumper
{
  my $var = 
    "\n"
  . "line number is $Parse::Nibbler::line_number \n"
  . "current line is $Parse::Nibbler::current_line \n"
  . "length of current line is $Parse::Nibbler::length_of_current_line \n"
  . "handle is $handle \n"
  . "filename is $Parse::Nibbler::filename \n";

  $var .= "list_of_rules_in_progress is \n";
  $var .= Dumper $Parse::Nibbler::list_of_rules_in_progress;
  $var .= "lexical_boneyard is \n";
  $var .= Dumper \@Parse::Nibbler::lexical_boneyard;

  $var .= "done \n";

  return $var;
}


#############################################################################
#############################################################################
# create a new parser with:  my $obj = Pkg->new($filename);
# Where 'Pkg' is a package that defines the grammar you wish to use
# to parse the text in question.
# The constructor must be given a filename to start parsing.
# new is a class method.
#############################################################################
#############################################################################
sub new	
#############################################################################
{
	$Parse::Nibbler::filename = shift;

	open(my $fh, $Parse::Nibbler::filename) or confess "Error opening $Parse::Nibbler::filename \n";
	$handle = $fh;

	$Parse::Nibbler::length_of_current_line = 0;
	$Parse::Nibbler::current_line = '';
	pos($Parse::Nibbler::current_line)=0;
	$Parse::Nibbler::line_number = 0;
	@Parse::Nibbler::lexical_boneyard=();

	my $start_rule = [];
	$Parse::Nibbler::list_of_rules_in_progress = [ $start_rule ];

}


#############################################################################
# Lexer
#############################################################################
#############################################################################
sub Lexer
#############################################################################
{
  while(1)
    {

      # if at end of line
      if (
	  $Parse::Nibbler::length_of_current_line ==
	  pos($Parse::Nibbler::current_line)
	 )
	{
	  $Parse::Nibbler::line_number ++;
	  # print "line ". $Parse::Nibbler::line_number."\n";
	  my $string =  <$handle>;

	  unless(defined($string))
	    {
	      return bless [ '!EOF!', '!EOF!', 
			     $Parse::Nibbler::line_number , 0 ], 'Lexical';
	    }

	  chomp($string);
	  $Parse::Nibbler::current_line = $string;
	  pos($Parse::Nibbler::current_line) = 0;
	  $Parse::Nibbler::length_of_current_line=length($string);
	  redo;
	}

      # look for leading whitespace and possible comment to end of line
      if($Parse::Nibbler::current_line =~ /\G\s+(?:\/\/.*)?/gco)
	{
	  redo;
	}


      # look for possible identifiers
      if($Parse::Nibbler::current_line =~ 
	 /\G(
	       \$?[a-z_][a-z0-9_\$]*(?:\.[a-z_][a-z0-9_\$]*)*
	     | \$?(?:\\[^\s]+)\s
	    )
	 /igcxo
	)
	{
	  return bless ['Identifier', $1, $Parse::Nibbler::line_number, 
			 pos($Parse::Nibbler::current_line)], 'Lexical';
	}


      # look for a 'Number' in Verilog style of number
      #  [unsigned_number] 'd unsigned_number
      #  [unsigned_number] 'o octal_number
      #  [unsigned_number] 'b binary_number
      #  [unsigned_number] 'h hex_number
      #   unsigned_number [ . unsigned_number ] [ e [+-] unsigned_number ]
      if($Parse::Nibbler::current_line =~ 
	 /\G(
	       (?:\d+)?\'
	          (?:
		     d[0-9xz]+
		   | o[0-7xz]+
		   | b[01xz]+
		   | h[0-9a-fxz]
		  )

	     | \d+(?:\.\d+)?(?:e[+-]?\d+)?
	    )
	 /igcxo
	)
	{
	  return bless ['Number', $1, $Parse::Nibbler::line_number, 
			pos($Parse::Nibbler::current_line) ], 'Lexical';
	}

      # else get a single character and return it.
      $Parse::Nibbler::current_line =~ /\G(.)/gco;
      return bless [$1, $1, $Parse::Nibbler::line_number, 
		    pos($Parse::Nibbler::current_line) ], 'Lexical';

    }
}







###############################################################################
###############################################################################
###############################################################################
###############################################################################
###############################################################################
###############################################################################
###############################################################################

###############################################################################
Register 
( 'SourceText', sub 
###############################################################################
  {
    Description('*');
  }
);

###############################################################################
Register 
( 'Description', sub 
###############################################################################
  {
    ModuleDeclaration();
  }
);



###############################################################################
Register 
( 'ModuleDeclaration', sub 
###############################################################################
  {
    ValueIs('module');
    TypeIs('Identifier');
    ListOfPorts()  if (PeekValue() eq '(');
    ValueIs(';');
    ModuleItem('*');
    ValueIs('endmodule');
  }
);

###############################################################################
Register 
( 'ListOfPorts', sub 
###############################################################################
  {
    ValueIs('(');
    PortList();
    ValueIs(')');
  }
);

###############################################################################
Register
( 'PortList', sub
###############################################################################
  {
    AlternateRules( 'AnonPortExpressionList', 'NamedPortExpressionList' );
  }
);


###############################################################################
Register 
( 'NamedPortExpressionList', sub 
###############################################################################
  {
    NamedPortExpression('+',',');
  }
);

###############################################################################
Register 
( 'AnonPortExpressionList', sub 
###############################################################################
  {
    AnonPortExpression('+',',');
  }
);


###############################################################################
Register 
( 'NamedPortExpression', sub 
###############################################################################
  {
    ValueIs('.');
    TypeIs('Identifier');
    ValueIs('(');
    AnonPortExpression('?');
    ValueIs(')');
  }
);


###############################################################################
Register 
( 'AnonPortExpression', sub 
###############################################################################
  {
    if (PeekValue() eq '{')
      {
	ConcatenatedPortReference();
      }
    else
      {
	PortReference();
      }
  }
);

###############################################################################
Register 
( 'PortReference', sub 
###############################################################################
  {
    if (PeekType() eq 'Identifier')
      {
	IdentifierWithPossibleBitSpecifier();
      }
    else
      {
	TypeIs('Number');
      }
  }
);


###############################################################################
Register 
( 'IdentifierWithPossibleBitSpecifier', sub 
###############################################################################
  {
    TypeIs('Identifier');
    BitSpecifier()  if (PeekValue() eq '[');
  }
);



###############################################################################
Register 
( 'BitSpecifier', sub 
###############################################################################
  {
    ValueIs('[');
    TypeIs('Number');
    ColonNumber()  if (PeekValue() eq ':');
    ValueIs(']');
  }
);

###############################################################################
Register 
( 'ColonNumber', sub 
###############################################################################
  {
    ValueIs(':');
    TypeIs('Number');
  }
);

###############################################################################
Register 
( 'ConcatenatedPortReference', sub 
###############################################################################
  {
    ValueIs('{');
    PortReference('+',',');
    ValueIs('}');
  }
);

###############################################################################
Register 
( 'ModuleItem', sub 
###############################################################################
  {
    if (PeekValue() =~ /input|output|inout/o)
      {
	DirectionDeclaration();
      }
    else
      {
       ModuleInstantiation();
      };
  }
);


###############################################################################
Register 
( 'DirectionDeclaration', sub 
###############################################################################
  {
    AlternateValues('input', 'output', 'inout');
    Range() if (PeekValue() eq '[');
    PortIdentifier('+');
    ValueIs(';');
  }
);


###############################################################################
Register 
( 'PortIdentifier', sub 
###############################################################################
  {
    TypeIs('Identifier');
  }
);

###############################################################################
Register 
( 'Range', sub 
###############################################################################
  {
    ValueIs('[');
    TypeIs('Number');
    ValueIs(':');
    TypeIs('Number');
    ValueIs(']');
  }
);


###############################################################################
Register 
( 'ModuleInstantiation', sub 
###############################################################################
  {
    TypeIs('Identifier');
    ParameterValueAssignment()  if (PeekValue() eq '#');
    ModuleInstance('+',',');
    ValueIs(';');
  }
);

###############################################################################
Register 
( 'ParameterValueAssignment', sub 
###############################################################################
  {
    ValueIs('#');
    ValueIs('(');
    PortList('?');
    ValueIs(')');

  }
);

###############################################################################
Register 
( 'ModuleInstance', sub 
###############################################################################
  {
    TypeIs('Identifier');
    ValueIs('(');
    PortList('?');
    ValueIs(')');

  }
);






###############################################################################
###############################################################################
###############################################################################

1;
__END__

=head1 NAME

VerilogGrammar - Parsing HUGE gate level verilog files a little bit at a time.

=head1 SYNOPSIS

	use VerilogGrammar;
	my $p = VerilogGrammar->new('filename.v');
	SourceText;

=head1 DESCRIPTION


This module is intended to be an example module that uses Parse::Nibbler.


=head2 EXPORT

None.


=head1 AUTHOR

    VerilogGrammar - Parsing HUGE gate level verilog files a little bit at a time.
    Copyright (C) 2001  Greg London

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    contact the author via http://www.greglondon.com


=head1 SEE ALSO

Parse::Nibbler

=cut
