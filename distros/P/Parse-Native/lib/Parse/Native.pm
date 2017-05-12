

package Parse::Native;

use 5.008002;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = '0.02';



##########################################################################
##########################################################################
##########################################################################
use Filter::Simple;
##########################################################################
##########################################################################
##########################################################################

my $grammarname='unknown';
my $grammarpkg ='unknown';
my $rulename='unknown';
my $rulepkg='unknown';

FILTER 
{
	my @caller = caller(0);
	print Dumper \@caller;

	my @lines = split(/\n/, $_);

	foreach my $line (@lines)
		{

		if ($line =~  s	{^Grammar\s+([\w:]+)\s*;}{})
			{
			$grammarname=$1;
			$grammarpkg = 'Parse::Native::Grammar::'.$grammarname;
			$line =  "package $grammarpkg;"
				.' BEGIN{Parse::Native::ExportGrammar;} ';
			}
	
		elsif($line=~ s	{^Rule\s+([\w:]+)\s*;}{})
			{
			$rulename=$1;
			$rulepkg = $grammarpkg.'::Rule::'.$rulename;
			$line =  "package $rulepkg;"
				.' BEGIN{Parse::Native::ExportRule;} our ($skip); ';
			}
	
		elsif($line =~ s{^EndGrammar\s*;}{})
			{
			
			}

		else
			{

			}
		}



	$_ = join("\n", @lines);

	# warn "$_ here";	# uncomment this to dump out final source text
	
};

##########################################################################
##########################################################################
##########################################################################
##########################################################################
##########################################################################
##########################################################################
# given a string with templates, search and replace templates
# and then evaluate the result.
##########################################################################
sub Evaluator
##########################################################################
{
	my ($string)=@_;

	$string =~ s{GRAMMARNAME}{$grammarname}g;
	$string =~ s{GRAMMARPKG}{$grammarpkg}g;
	$string =~ s{RULENAME}{$rulename}g;
	$string =~ s{RULEPKG}{$rulepkg}g;

	#warn "string is '$string'";

	eval($string);

	if($@)
		{
		warn "ERROR: could not evaluate '$string'";
		die $@;
		}

}


##########################################################################
##########################################################################
##########################################################################
##########################################################################
##########################################################################
##########################################################################



##########################################################################
sub ExportGrammar
##########################################################################
{

	my $string = <<'EVALGRAMMARSTR' ;

	
		# define references that point to current mode subroutines
		# initialize them to stubs
		$GRAMMARPKG::regx_ref	= sub{};
		$GRAMMARPKG::lit_ref	= sub{};
		$GRAMMARPKG::rule_ref	= sub{};

		# define subs that all rules point to
		sub GRAMMARPKG::regx
		{
			&$GRAMMARPKG::regx_ref;
		}

		sub GRAMMARPKG::lit
		{
			&$GRAMMARPKG::lit_ref;
		}

		sub GRAMMARPKG::rule
		{
			&$GRAMMARPKG::rule_ref;
		}

		# use this to keep list of all rules under this grammar
		@GRAMMARPKG::Rules = ();

		# call this to switch "mode".
		# this will redefine which regx,lit,rule subroutine
		# will be called when a rule calls the subroutine
		sub GRAMMARPKG::Mode
		{
			&Parse::Native::Mode('GRAMMARPKG',@_);
		}		

		&Parse::Native::Mode('GRAMMARPKG','Startup');
EVALGRAMMARSTR
;
	Evaluator($string);
}


##########################################################################
sub ExportRule
##########################################################################
{
	my $string = <<'EVALRULESTR' ;

		# each rule gets to define its "skip" value.
		$RULEPKG::Skip = '\s+';

		# each rule can invoke a mode switch
		sub RULEPKG::Mode
		{
			&GRAMMARPKG::Mode;
		}		

		# every rule will need these three subroutines 
		# to do its actual parsing: regx, lit, rule.
		# call the reference in the Grammar package.
		# that way, all rules can switch to a new mode
		# by changing the reference.		
		sub RULEPKG::regx
		{
			&GRAMMARPKG::regx($RULEPKG::skip,@_);
		}		
	
		sub RULEPKG::lit
		{
			&GRAMMARPKG::lit($RULEPKG::skip,@_);
		}

		sub RULEPKG::rule
		{
			&GRAMMARPKG::rule($RULEPKG::skip,@_);
		}

		# keep track of all the rules for this grammar here.
		push(@GRAMMARPKG::Rules, 'RULEPKG');

EVALRULESTR
;
	#warn "rule string is '$string'";
	Evaluator($string);
}

##########################################################################
sub Mode
##########################################################################
{
	my @caller=caller(0); print Dumper \@caller; print Dumper \@_;

	my ($grammarpkg,$mode) = @_;

	my $string="\n\nuse Parse::Native::Mode::$mode;\n";

	foreach my $type qw(regx lit rule)
		{
		$string .= '$'.$grammarpkg.'::'.$type.'_ref = \&Parse::Native::Mode::'.$mode.'::'.$type.";\n";
		}

	$string .= "\n\n\n";

	eval($string);

	if($@)
		{
		warn "Error: unable to eval '$string'";
		die $@;
		}




}


##########################################################################
##########################################################################
##########################################################################
##########################################################################
##########################################################################

1;
__END__
=head1 NAME

Parse::Native - Perl extension for parsing in your native language (perl!)

=head1 SYNOPSIS

	use Parse::Native;

	Grammar NameOfMyGrammar;	

	Rule NameOfMyRule;		

	sub Parse
	{
		lit 'Hello';
		lit ',';
		rule 'identifier';
		lit '!'
		
	}

	EndGrammar;			


=head1 DESCRIPTION

Parse::Native is yet another parser that you can use to write grammars for parsing some arbitrary input. However, Parse::Native allows you to write your grammar as pure perl code. This provides some advantages over parsers that use intermediate languages to define their grammars.

When a parser uses an intermediary language to define its grammar, the grammar goes through some translation and is converted into perl code. Design errors in the intermediate grammar cause run time errors in the final perl code. But these run time errors are reported in reference to the generated perl code. This leaves the task of determining what part of the intermediate grammar caused the run time error in the generated perl code. This is especially troublesome when the intermediate grammar allows users to embed perl code within their grammar (actions). This embedded code is cut and pasted into the generated code by the parser. If a run time error occurs while running the user-written code within the generated code, perl will report an error using filenames and line numbers that refer to the generated code, leaving it to the user to determine where the error occurred within the intermediate grammar.



=head2 SOURCE CODE FILTERING

The Parse::Native module performs source code filtering on any file that performs a 'use Parse::Native' statement. This filtering allows grammars to be written as perl with a shorthand notation for repetitive features. The source code filtering is a simple one-for-one substitution that does not add or delete lines, so any errors reported by perl will reference the correct line number in the grammar.

The keywords that undergo source code filtering are 'Grammar', 'Rule', and 'EndGrammar'. These keywords must occur at the beginning of a line to undergo filter translation. If you need to use these words within your grammar without being translated, place them in the middle of a line with text or whitespace in front of them.

The 'Grammar' keyword translates into a package declaration under the Parse::Native namespace. It also stores the name of the grammar internally so that it can be used later.

The 'Rule' keyword translates into a package declaration under the grammar namespace, using the stored grammar name to get the full package name.

The 'EndGrammar' keyword indicates the end of scope for the current grammar. 


	# use the module, start source code filtering.
	use Parse::Native;		

	# package Parse::Native::Grammar::Spock;
	Grammar Spock;	

	# package Parse::Native::Grammar::Spock::Rule::Lifeform;
	Rule Lifeform;		

	sub Parse
	{
		lit "It's";
		lit "life";
		rule 'Name';
		lit ',';
		lit 'but';
		lit 'not'
		lit 'as';
		lit 'we';
		lit 'know';
		lit 'it';
		regx '[.!]';
		
	}

	# end of declaration for grammar 'NameOfMyGrammar'
	EndGrammar;			

=head2 RULE NAMESPACE

Each rule gets its own package namespace. Inside that namespace, you declare a subroutine called 'Parse' that parses that rule. Parsing is accomplished using Parse::Native subroutines that are imported into the rule namespace.

=head2 EXPORT

Parse::Native exports a number of subroutines to the user. These subroutines allow a user to write a grammar as a series of subroutine calls. The subroutines exported include:

	Mode()
	regx()
	lit()
	rule()

=head3 MODE SUBROUTINE

The Mode() subroutine is used to change the "mode" of the parser midparse. This might be used to turn on debugging, or to show the parsing in a GUI, or something similar. The Mode() subroutine takes one argument, the mode to switch to. This mode should correspond to a module that exists in the Parse::Native::Mode::thismode namespace. Each mode module will define regx, lit, and rule subroutines which will become the current subs used for parsing in this grammar.

=head3 REGX SUBROUTINE

The regx() subroutine is used to define a regular expression pattern to match at the current location in the text being parsed. The first parameter to the regx() subroutine is a perl regular expression, either as a regular string or as a qr string. The full regular expression syntax is available with the following exceptions:

The \G anchor is unavailable. It is used by the parser to keep track of the position within the text being parsed. 

The $1, $2, $3 variables are not available for pattern capturing. Any matches will be returned in list form by the rule() subroutine.

This call to regx() will match a base defined number Length'BaseChar.Value and return it as three scalars. For example "32'h0f0f" will return ('32', 'h', '0f0f') from the regx call.

	my ($len,$base,$val)=regx('(\d+)`([bdhoBDHO])(\w+)');

=head3 LIT SUBROUTINE

The lit() subroutine is similar to the regx() subroutine in that it declares what next to extract from the source text, except it declares literal values only. Calling lit('\w+') will only match a '\' followed by a 'w' followed by a '+'. The intent of lit() is to speed up parsing when a full regular expression pattern is not needed.

=head3 RULE SUBROUTINE

The rule() subroutine is used to define a point in a rule where another rule must be called. 




=head1 SEE ALSO

None

=head1 AUTHOR

Greg London, E<lt>DELETEALLCAPSemail@greglondon.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Greg London

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

