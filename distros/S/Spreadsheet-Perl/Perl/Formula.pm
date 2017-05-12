
package Spreadsheet::Perl;

use 5.006 ;

use Carp ;
use strict ;
use warnings ;

require Exporter ;

our %EXPORT_TAGS = 
	(
	'all' => [ qw() ]
	) ;

our @EXPORT ;
push @EXPORT, qw( Formula AddBuiltin GetBuiltin SetBuiltin) ;

our $VERSION = '0.03' ;

#-------------------------------------------------------------------------------

# The following code was contributed to Spreadsheet::Perl by Steffen Müller <SMUELLER>. 

#-------------------------------------------------------------------------------

my @builtin = qw() ;

#-------------------------------------------------------------------------------

use vars qw/$RD_HINT $RD_TRACE/;
use vars qw/$RD_ERRORS $RD_WARN/;
($RD_ERRORS, $RD_WARN) = (undef, undef);
#($RD_HINT, $RD_TRACE) = (1,0);

my $original_grammar = <<'GRAMMAR' ;

parse:          addition /^\Z/
                { $item[1] }

                | <error>



addition:       <leftop:multiplication ('+' | '-') multiplication>
                {
                        if (@{$item[1]} > 1) {
                                $return = '('
                                        . join(' ', @{$item[1]})
                                        . ')';
                        }
                        else {
                                $return = $item[1][0];
                        }
                }


multiplication: <leftop:exp ('*' | '/') exp>
                {
                        if (@{$item[1]} > 1) {
                                $return = '('
                                        . join(' ', @{$item[1]})
                                        . ')';
                        }
                        else {
                                $return = $item[1][0];
                        }
                }


exp:            <rightop:factor '^' factor>
                {
                        if (@{$item[1]} > 1) {
                                my @args = @{$item[1]};
                                my $str = "($args[-2] ** $args[-1])";
                                pop @args; pop @args;
                                while (@args) {
                                        $str = '(' . pop(@args)
                                                . ' ** ' . $str . ')';
                                }
                                $return = $str;
                        }
                        else {
                                $return = $item[1][0];
                        }
                }


factor:         unary
                { $item[1] }

                | '(' addition ')'

                { "($item[2])" }


unary:          unary_op factor
                { "$item[1]($item[2])" }

                | number

                { $item[1] }

                | function

                { $item[1] }

                | variable

                { $item[1] }


unary_op:       '+' | '-'
                { $item[1] }


number:         /\d+(\.\d+)?/
                { $item[1] }


function:       builtin_function_name '(' expr_list ')'
                {
			"$item[1](" . join(', ', @{$item[3]}) . ")" ;
                }

                | /[A-Za-z_][A-Za-z0-9]*(?=\()/ custom_function_args

                {
                        $return = '$ss->' . $item[1] . "(" . $item[2] . ")";
                }


custom_function_args:   '(' literal_range_list ')'
                {
                  "'" . join("', '", @{$item[2]}) . "'"
                }

                | '(' expr_list ')'

                {
                  join ', ', @{$item[2]}
                }
                

builtin_function_name: /__BUILT_IN_PLACEHOLDER__/
                { $item[1] }


expr_list:      <leftop:addition ',' addition>
                { [@{$item[1]}] }


spreadsheet:    /[A-Z][A-Z0-9_]*(?!\()/
                { $item[1] }


cell:           /[a-zA-Z]{1,4}\d+|[A-Z]+(?![a-z]|\()/
                { $item[1] }


literal_range_list: <leftop:literal_range ',' literal_range>
                { [@{$item[1]}] }


literal_range:  spreadsheet '!' cell (':' cell)(?)
                {
                        join(
                                '', @item[1..3], (
                                        @{$item[4]}
                                        ? ':' . $item[4][0]
                                        : ''
                                )
                        )
                }

                | cell (':' cell)(?)

                { $item[1] . (@{$item[2]}?':'.$item[2][0]:'') }

                | /[A-Z]+(?![a-z]|\()/ # named range

                { $item[1] }


variable:       spreadsheet '!' cell (':' cell)(?)
                {
                        '$ss'
                        . "{'$item[1]!$item[3]"
                        . (
                                @{$item[4]}
                                ? ':' . $item[4][0]
                                : ''
                        )
                        . "'}"
                }

                | cell (':' cell)(?)

                {
                        '$ss'
                        . "{'$item[1]"
                        . (
                                @{$item[2]}
                                ? ':' . $item[2][0]
                                : ''
                        )
                        . "'}"
                }

                | /[A-Z]+(?![a-z]|\()/ # named range

                { '$ss' . "{'$item[1]'}" }


GRAMMAR

my $parser ;

#-------------------------------------------------------------------------------

sub AddBuiltin
{
push @builtin, @_ ;
undef $parser ;
}

#-------------------------------------------------------------------------------

sub GetBuiltin
{
return(@builtin) ;
}


#-------------------------------------------------------------------------------

sub SetBuiltin
{
@builtin =  @_ ;
undef $parser ;
}

#-------------------------------------------------------------------------------

sub Formula
{
my $self = shift ;

if(defined $self && __PACKAGE__ eq ref $self)
	{
	my %formulas= @_ ;
	
	while(my ($address, $formula) = each %formulas)
		{
		$self->Set
			(
			  $address
			, bless [\&GenerateFormulaSub, $formula], "Spreadsheet::Perl::Formula"
			) ;
		}
	}
else	
	{
	unshift @_, $self ;
	return bless [\&GenerateFormulaSub, @_], "Spreadsheet::Perl::Formula" ;
	}
}


#-------------------------------------------------------------------------------

sub GenerateFormulaSub
{
my ($ss, $current_cell_address, $anchor, $formula) = @_ ;


unless(defined $parser)
	{
	eval "use Parse::RecDescent;" ;
	die $@ if $@ ;

	my $grammar = $original_grammar ;
	$grammar =~ s[__BUILT_IN_PLACEHOLDER__]{join('|', @builtin)}eg ;
	$parser = Parse::RecDescent->new($grammar);
	}

my $perl_formula = $parser->parse($formula) ;

if(defined $perl_formula)
	{
	return(Spreadsheet::Perl::GeneratePerlFormulaSub($ss, $current_cell_address, $anchor, $perl_formula)) ;
	}
else
	{
	die "Invalid Formula '$formula'!\n" ;
	}
}

#-------------------------------------------------------------------------------

{
no warnings ; # keep perl silent about override.

sub SerializeBuiltin
{
my $serialized_data = "use Spreadsheet::Perl::Formula ;\n" ;

$serialized_data .= 'SetBuiltin qw(' . join(' ', @builtin) . ") ;\n\n" if @builtin ;

return($serialized_data) ;
}

}

#------------------------------------------------------------------------------

1 ;

__END__

=head1 NAME

Spreadsheet::Perl::Formula - Formula support for Spreadsheet::Perl

=head1 SYNOPSIS

  $ss{A1} = Formula('B1 + Sum(A1:A6)') ;
  
=head1 DESCRIPTION

Part of Spreadsheet::Perl.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. <nadim@khemir.net>

  Copyright (c) 2004 Nadim Ibn Hamouda el Khemir. All rights
  reserved.  This program is free software; you can redis-
  tribute it and/or modify it under the same terms as Perl
  itself.
  
If you find any value in this module, mail me!  All hints, tips, flames and wishes
are welcome at <nadim@khemir.net>.

=cut

