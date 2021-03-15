
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSL::DIFF;

@EXPORT_OK  = qw( gsldiff PDL::PP diff_central PDL::PP diff_backward PDL::PP diff_forward );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSL::DIFF ;




=head1 NAME

PDL::GSL::DIFF - PDL interface to numerical differentiation routines in GSL

=head1 DESCRIPTION

This is an interface to the numerical differentiation package present in the 
GNU Scientific Library.

=head1 SYNOPSIS

   use PDL;
   use PDL::GSL::DIFF;

   my $x0 = 3.3;

   my @res = gsldiff(\&myfunction,$x0);
   # same as above:
   @res = gsldiff(\&myfunction,$x0,{Method => 'central'});

   # use only values greater than $x0 to get the derivative 
   @res =  gsldiff(\&myfunction,$x0,{Method => 'forward'});
   
   # use only values smaller than $x0 to get the derivative 
   @res = gsldiff(\&myfunction,$x0,{Method => 'backward'});

   sub myfunction{
     my ($x) = @_;
     return $x**2;
   }






=head1 FUNCTIONS



=cut





sub gsldiff{
  my $opt;
  if (ref($_[$#_]) eq 'HASH'){ $opt = pop @_; }
  else{ $opt = {Method => 'central'}; }
  die 'Usage: gsldiff(function_ref, x, {Options} )'
      if $#_<1 || $#_>2;
  my ($f,$x) = @_;  
  my ($res,$abserr);
  if($$opt{Method}=~/cent/i){
   ($res,$abserr) = PDL::GSL::DIFF::diff_central($x,$f);
  }
  elsif($$opt{Method}=~/back/i){
    ($res,$abserr) = PDL::GSL::DIFF::diff_backward($x,$f);
  }
  elsif($$opt{Method}=~/forw/i){
    ($res,$abserr) = PDL::GSL::DIFF::diff_forward($x,$f);
  }
  else{
    barf("Unknown differentiation method $method in gsldiff\n");
  }
  return ($res,$abserr);
}





=head2 diff_central

=for sig

  Signature: (double x(); double [o] res(); double [o] abserr(); SV* function)


=for ref

info not available


=for bad

diff_central does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*diff_central = \&PDL::diff_central;





=head2 diff_backward

=for sig

  Signature: (double x(); double [o] res(); double [o] abserr(); SV* function)


=for ref

info not available


=for bad

diff_backward does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*diff_backward = \&PDL::diff_backward;





=head2 diff_forward

=for sig

  Signature: (double x(); double [o] res(); double [o] abserr(); SV* function)


=for ref

info not available


=for bad

diff_forward does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*diff_forward = \&PDL::diff_forward;



;

=head2 gsldiff

=for ref

This functions serves as an interface to the three differentiation 
functions present in GSL: gsl_diff_central, gsl_diff_backward and 
gsl_diff_forward. To compute the derivative, the central method uses 
values greater and smaller than the point at which the derivative is 
to be evaluated, while backward and forward use only values smaller 
and greater respectively. gsldiff() returns both the derivative 
and an absolute error estimate. The default  method is 'central', 
others can be specified by passing an option.

Please check the GSL documentation for more information.

=for usage

Usage:

  ($d,$abserr) = gsldiff($function_ref,$x,{Method => $method});

=for example

Example:

  #derivative using default method ('central')
  ($d,$abserr) = gsldiff(\&myf,3.3);

  #same as above with method set explicitly
  ($d,$abserr) = gsldiff(\&myf,3.3,{Method => 'central'});

  #using backward & forward methods
  ($d,$abserr) = gsldiff(\&myf,3.3,{Method => 'backward'});
  ($d,$abserr) = gsldiff(\&myf,3.3,{Method => 'forward'});

  sub myf{
    my ($x) = @_;
    return exp($x);
  }

=head1 BUGS

Feedback is welcome. Log bugs in the PDL bug database (the
database is always linked from L<http://pdl.perl.org>).

=head1 SEE ALSO

L<PDL>

The GSL documentation is online at

  http://www.gnu.org/software/gsl/manual/

=head1 AUTHOR

This file copyright (C) 2003 Andres Jordan <andresj@physics.rutgers.edu>
All rights reserved. There is no warranty. You are allowed to redistribute 
this software documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL differentiation routines were written by David Morrison.

=cut





# Exit with OK status

1;

		   