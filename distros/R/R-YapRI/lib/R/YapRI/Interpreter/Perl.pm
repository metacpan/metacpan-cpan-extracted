
package R::YapRI::Interpreter::Perl;

use strict;
use warnings;
use autodie;

use Carp qw( carp croak cluck );
use Math::BigFloat;

## To export some functions

use Exporter qw( import );

our @EXPORT_OK = qw( r_var );

###############
### PERLDOC ###
###############

=head1 NAME

R::YapRI::Interpreter.pm

A module to transform perl variables into R command lines to define simple objs.

=cut

our $VERSION = '0.04';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  use R::YapRI::Base;
  use R::YapRI::Interpreter::Perl qw/r_var/;

  my $perl_var = [1, 2, 3];
  my $r_var = r_var($perl_var);  


=head1 DESCRIPTION

A interpreter to translate Perl variables into R commands for L<R::YapRI::Base>

 +==================+==============+===============================+
 |  PERL VARIABLE   |  R VARIABLE  | Example                       |
 +==================+==============+===============+===============+
 | undef            | NULL         | $px = undef   | rx <- NULL    |
 +------------------+--------------+---------------+---------------+
 | empty ('' or "") | NA           | $px = ''      | rx <- NA      |
 +------------------+--------------+---------------+---------------+
 | integer          | numeric      | $px = 12      | rx <- 12      |
 +------------------+--------------+---------------+---------------+
 | bigint,bigfloat  | numeric      | $px = '-1.2'  | rx <- -1.2    |
 +------------------+--------------+---------------+---------------+
 | word 'TRUE'      | TRUE         | $px = 'TRUE'  | rx <- TRUE    |
 +------------------+--------------+---------------+---------------+
 | word 'FALSE'     | FALSE        | $px = 'FALSE' | rx <- FALSE   |
 +------------------+--------------+---------------+---------------+
 | any other word   | character    | $px = "sun"   | rx <- "sun"   |
 +------------------+--------------+---------------+---------------+
 | ARRAY REF.       | vector       | $px = [1, 2]  | rx <- c(1, 2) |
 +------------------+--------------+---------------+---------------+
 | HASH REF.        | object       | see below (*)                 |
 +------------------+--------------+-------------------------------+
        
* R object or R function without arguments

  $px = { a => undef }, will be just 'a'  
  $px = { mass => '' }, will be just 'mass'

* R simple object with arguments

  $px = { '' => { x => 2 }}, will be 'x = 2'
  $px = { '' => { x => [2, 4] }}, will be 'x = c(2, 4)

* R functions with arguments 

  $px = { log  => 2  }, will be 'log(2)'
  $px = { log  => [2, { base => 10 }] }, will be 'log(2, base = 10 )'
  $px = { t    => {x => ''} }, will be 't(x)'
  $px = { plot => [{ x => ''}, { main => "TEST"} ]}, will be:
         plot(x, main = "TEST")

Use array ref. to order the arguments in a function.

Use hash ref keys to define an argument in an R function 

For more complex data structures, use L<R::YapRI::Data::Matrix>.
     

=head1 AUTHOR

Aureliano Bombarely <aurebg@vt.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 


#################################
## VARIABLE CONVERSION METHODS ##
#################################


=head2 _rvar_noref

  Usage: my $r_string = _r_var_noref($perl_var); 

  Desc: Internal function to parse a single non-reference perl variable
        (scalar). Equivalence table:
        
        +==================+==============+=============================+
        |  PERL VARIABLE   |  R VARIABLE  | Example                     |
        +==================+==============+===============+=============+
        | undef            | NULL         | $px = undef   | rx <- NULL  |
        +------------------+--------------+---------------+-------------+
        | empty ('' or "") | NA           | $px = ''      | rx <- NA    |
        +------------------+--------------+---------------+-------------+
        | integer          | numeric      | $px = 12      | rx <- 12    |
        +------------------+--------------+---------------+-------------+
        | bigint,bigfloat  | numeric      | $px = '-1.2'  | rx <- -1.2  |
        +------------------+--------------+---------------+-------------+
        | word 'TRUE'      | TRUE         | $px = 'TRUE'  | rx <- TRUE  |
        +------------------+--------------+---------------+-------------+
        | word 'FALSE'     | FALSE        | $px = 'FALSE' | rx <- FALSE |
        +------------------+--------------+---------------+-------------+
        | any other word   | character    | $px = "sun"   | rx <- "sun" |
        +------------------+--------------+---------------+-------------+

  Ret: $r_string, a scalar with the perl2R variable translation

  Args: $perl_var, could be, a scalar or an array reference

  Side_Effects: Die if is used a perl reference.

  Example: my $rvar = _rvar_noref(12);

=cut

sub _rvar_noref {
    my $pvar = shift;

    my $rvar;
    
    if (defined $pvar) {
	if (ref($pvar)) {
	    croak("ERROR: $pvar is a perl reference, unable to convert to R.");
	}
	else {
	    if ($pvar =~ m/./) {
		my $mbf = Math::BigFloat->new($pvar);
		if ($mbf->is_nan()) {
		    if ($pvar =~ m/^(TRUE|FALSE)$/) {
			$rvar = $pvar;
		    }
		    else {
			$rvar = '"' . $pvar .'"';
		    }
		}
		else {
		    $rvar = $mbf->bstr();
		}
	    }
	    else {
		$rvar = 'NA';
	    }
	}
    }
    else {
	$rvar = 'NULL';
    }
    return $rvar;
}

=head2 _rvar_vector

  Usage: my $r_arg = _rvar_vector($arrayref); 

  Desc: Internal function to convert an perl array into a R vector

  Ret: $r_arg, a scalar with the perl2R variable translation

  Args: $arrayref, with the argument list

  Side_Effects: Die if the argument is not an arrayref.

  Example: my $r_vector = _rvar_vector($arrayref);

=cut

sub _rvar_vector {
    my $aref = shift ||
	croak("ERROR: No array ref. was supplied to _rvar_vector");

    my $rvect;
    if (ref($aref) eq 'ARRAY') {
	my @list = ();
	foreach my $el (@{$aref}) {
	    push @list, _rvar_noref($el);
	}
	$rvect = 'c(' . join(', ', @list) . ')';
    }
    else {
	croak("ERROR: $aref supplied to _rvar_vector isnt an array ref.")
    }
    return $rvect;
}



=head2 _rvar_arg

  Usage: my $r_arg = _rvar_arg($hashref); 

  Desc: Internal function to convert an argument in a function in the following
        way:
         2                              ===> '2'
         'YES'                          ===> '"YES"'
         [2, 3]                         ===> 'c(2, 3)'
         { x      => undef }            ===> 'x'
         { type   => "p"   }            ===> 'type = "p"'
         { col    => ["blue", "green"]} ===> 'col = c("blue", "green")'
         { labels => { x => undef } }   ===> 'labels = x'

        Something different from that, will die.

  Ret: $r_arg, a scalar with the perl2R variable translation

  Args: $hashref, with the argument list

  Side_Effects: Die if the argument is not: scalar, array ref or a hash 
                reference.

  Example: my $arg = _rvar_arg({ type => "p" });

=cut

sub _rvar_arg {
    my $parg = shift;

    my $rarg;
    if (defined $parg) {
	if (ref($parg)) {
	    if (ref($parg) eq 'ARRAY') {
		$rarg = _rvar_vector($parg);
	    }
	    elsif (ref($parg) eq 'HASH') {
		my @list = ();
		foreach my $k (sort keys %{$parg}) {
		    if (defined $parg->{$k} && $parg->{$k} =~ m/./) {
			my $sarg = $k . ' = ';
			if (ref($parg->{$k}) eq 'HASH') {
			    $sarg .= join(',', keys %{$parg->{$k}});
			}
			elsif (ref($parg->{$k}) eq 'ARRAY') {
			    $sarg .= _rvar_vector($parg->{$k});
			}
			else {
			    if (ref($parg->{$k})) {
				croak("ERROR: No permited value for R arg.");
			    }
			    $sarg .= _rvar_noref($parg->{$k});
			}
			push @list, $sarg;
		    }
		    else {
			push @list, $k;
		    }
		}
		$rarg = join(', ', @list);
	    }
	}
	else {
	    $rarg = _rvar_noref($parg);
	}
    }
    else {
	$rarg = 'NULL';
    }
    return $rarg
}



=head2 r_var

  Usage: my $r_string = r_var($perl_var); 

  Desc: Parse a perl variable and return a string with the r variable format, 
        For perl-non reference variables, see _rvar_noref

        +==================+=================+==============================+
        |  PERL VARIABLE   |  R VARIABLE     | Example                      |
        +==================+=================+==============+===============+
        | ARRAY REF.       | vector          | $px = [1, 2] | rx <- c(1, 2) |
        +------------------+-----------------+--------------+---------------+
        | HASH REF.        | object/function | see below                    |
        +------------------+-----------------+------------------------------+
        
        * R object or R function without arguments

        $px = { a => undef }, will be just 'a'  
        $px = { mass => '' }, will be just 'mass'

        * R simple object with arguments

        $px = { '' => { x => 2 }}, will be 'x = 2'
        $px = { '' => { x => [2, 4] }}, will be 'x = c(2, 4)

        * R functions with arguments 

        $px = { log  => 2  }, will be 'log(2)'
        $px = { log  => [2, { base => 10 }] }, will be 'log(2, base = 10 )'
        $px = { t    => {x => ''} }, will be 't(x)'
        $px = { plot => [{ x => ''}, { main => "TEST"} ]}, will be:
                plot(x, main = "TEST")

        Use array ref. to order the arguments in a function.
        Use hash ref keys to define an argument in an R function      


  Ret: $r_string, a scalar with the perl2R variable translation

  Args: $perl_var, could be, a scalar or an array reference

  Side_Effects: Die if the reference used is not a ARRAY REF or HASH REF.

  Example: my $rvar = r_var([1, 2, 3, "TRUE", "last word"]);

=cut

sub r_var {
    my $pvar = shift;

    my $rvar;

    my $err = "isnt a scalar, ARRAYEF or HASHREF. Unable to convert to R.";
    if (defined $pvar) {
	unless (ref($pvar)) {
	    $rvar = _rvar_noref($pvar);
	}
	else {
	    if (ref($pvar) eq 'ARRAY') {
		$rvar = _rvar_vector($pvar);
	    }
	    elsif (ref($pvar) eq 'HASH') {  ## First level objects or functions
		
		my @list = ();
		foreach my $obj (sort keys %{$pvar}) {
		    my $subvar = $obj;
		    my $args = $pvar->{$obj};        ## Second level, arguments
		
		    if (defined $args && $args =~ m/./) {

			if ($obj =~ m/./) {
			    $subvar .= '(';
			}

			unless (ref($args)) {       ## Just numeric, char...
			    $subvar .= _rvar_noref($args);
			}			
			else {			    			
			    my @arglist = ();

			    if (ref($args) eq 'ARRAY') { ## Ordered by user
			      
				foreach my $arg (@{$args}) {
				    my $targ = _rvar_arg($arg);
				    if (defined $targ && $targ =~ m/./) {
					push @arglist, $targ;
				    }
				}
			    }
			    elsif (ref($args) eq 'HASH') { ## No ordered
				my $targs = _rvar_arg($args);
				if (defined $targs && $targs =~ m/./) {
				    push @arglist, $targs;	
				}
			    }
			    else {
				croak("ERROR: $args $err");
			    }
			    $subvar .= join(', ', @arglist);
			}
			
			if ($obj =~ m/./) {
			    $subvar .= ')'; ## Close list of arguments
			}
		    }
		    push @list, $subvar;
		    
		    ## If there are more than one function or object

		    $rvar = join('; ', @list);
		}
	    }
	    else {
		croak("ERROR: $pvar $err");
	    }
	}
    }
    else {  ## Perl variable undef will be R variable 'NULL'
	$rvar = 'NULL';
    }

    return $rvar;
}


=head1 ACKNOWLEDGEMENTS

Lukas Mueller

Robert Buels

Naama Menda

Jonathan "Duke" Leto

=head1 COPYRIGHT AND LICENCE

Copyright 2011 Boyce Thompson Institute for Plant Research

Copyright 2011 Sol Genomics Network (solgenomics.net)

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut


####
1; #
####
