package PDL::NamedArgs;

use 5.006;
#use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PDL::NamedArgs ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	parseArgs
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	parseArgs
);
our $VERSION = '0.12';

sub parseArgs
{
   my($funcDef)=shift;
   my(%named,@unnamed,@arg_names);
   my($status,$i)=(0);

   # Build up the arg_names array and the arg_defaults hash
   for $i (split(/[ ,]+/,$funcDef))
   {
     if ($i =~ m/^([a-zA-Z]\w*)=(.*)$/)
        { push(@arg_names,lc($1)); $arg_defaults{lc($1)}=$2; }
     else
        { push(@arg_names,lc($i)); }
   }

   # Walk thru the arguments passed and separate into %named & @unnamed arguments
   while ($#_>=0)
   {
      $i=shift;
      if (!ref($i) && grep(/^$i$/i,@arg_names))    # Named argument
       { 
         if (exists($named{$i}))
           { return ("Error: Argument $i multiple definitions"); }   # Whoops, somebody went overboard...
         $named{$i}=shift; 
       } 
     else                    # Unnamed argument
       { push @unnamed,$i; }
   }

   # Walk thru the argument names & make sure they are set, if not use the default if defined
   for $i (@arg_names)
   {
     if (exists($named{$i}))               # Argument already defined via named argument (Priority #1)
       { next; }

     # Argument is not defined
     if (@unnamed) 
       { $named{$i}=shift(@unnamed); }    # Grab one of the unnamed list if available (Priority #2)
     elsif (exists($arg_defaults{$i}))
       { $named{$i}=$arg_defaults{$i}; }  # Set to the default value if defined (Priority #3)
     else
       { return ("Error: Missing $i argument"); }  # Whoops, somebody forgot something...
   }
   if (@unnamed)
     { return ("Error: Too many arguments"); }     # Whoops, somebody went overboard...

   return ($status,%named);
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

 PDL::NamedArgs - Perl extension for named & unamed arguments 
                  with optional default values

=head1 SYNOPSIS

  use PDL::NamedArgs;

=head1 OVERVIEW

PDL::NamedArgs (currently) exports one main function which 
aids in the processing of function arguments. The key 
differentiators with this module in comparison to others 
on CPAN is that it allows any combination of named & unnamed 
arguments while also providing optional support for
default values. I like to think of it as varargs on steroids...

=head1 DETAILED DESCRIPTION

=head2 parseArgs Synopsis

 parseArgs($funcDef,@_)
     $funcDef - Function definition that lists all arguments 
                (In order!!) with default values, separated 
                by either space or comma.   
                Examples "x min max" or "x,min=0,max=10"
           @_ - Arguments to parse, subject to $funcDef

 Returns ($result,%named)
     $status - Result of parsing.  0 if ok, otherwise set 
               to error message
      %named - Hash of argument names set to appropriate 
               values after argument parsing

=head2 parseArgs Description

The goal of this utility function is to allow more 
flexibility with how passed arguments are handled 
when calling a function. I guess the best way to 
describe this is to give an example.

Consider a function with following abstract prototype 
pbinom(q, size, prob, lower_tail=1, log_p=0)

In a language such as R you could call this function 
in any of the following formats and receive the exact 
same result.

 pbinom(.5, 50, 3,1,1)          # All arguments specified
 pbinom(.5,size=50,3,log_p=1)   # lower_tail set to default value 
                                # and using named values
 pbinom(prob=3,q=.5,size=50)    # Using default values, named values 
                                # & mixing up the order

We can achieve almost the same capabilties of R in perl 
by using the parseArgs function for parsing arguments and 
by changing the named variable syntax to name=>value.

The $funcDef for pbinom function would be 
'q, size, prob, lower_tail=1, log_p=0' and an example 
implementation of pbinom using parseArgs might look like

  sub pbinom
  {
   my($status,%argHash)=
            parseArgs('q, size, prob, lower_tail=1, log_p=0'
                      ,@_);
  
   die ("pbinom error\n$status\n") if $status;

   print "(q, size, prob, lower_tail, log_p) = ";
   print "($argHash{q}, $argHash{size}, $argHash{prob}, 
          $argHash{lower_tail}, $argHash{log_p})\n";
  
  }

We could then call pbinom in perl by any of the following 
equivalent methods

  pbinom(.5, 50, 3,1,0);          # All arguments specified
  pbinom(.5,size=>50,3,log_p=>0); # lower_tail set to default value 
                                  # and using named values
  pbinom(prob=>3,q=>.5,size=>50); # Using default values, named values 
                                  # & mixing up the order

=head2 Misc Notes

All argument names are set to lowercase as a way to allow 
case insensitivity, thus pbinom(PROB=>3,q=>.5,SiZe=>50) 
would also work, but the returned hash would only have 
keys that are lowercase

 Priority of argument assignment
     1. Named argument
     2. Unnamed ordered argument
     3. Default argument values

=head1 AUTHOR

John Cavanaugh, E<lt>cavanaug@users.sourceforge.netE<gt>

=head1 SEE ALSO

L<perl>.

=cut
