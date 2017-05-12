package Perl6::Slurp::Interpret;
our $VERSION = '0.15';
use 5.008008;

package main;   # main so that the function evalues in the caller's name space.
# use strict ;  # strict is disabled to allow global variables
use warnings;
use Perl6::Slurp;
use Inline::Files;

require Exporter;
# use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Perl6::Slurp::Interpret ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( eval_slurp quote_slurp) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( eval_slurp quote_slurp );
	



# Preloaded methods go here.
sub eval_slurp {

    # use Perl6::Say;

    return( 
       eval( 
           quote_slurp( @_ ) 
           )
    );

}


sub quote_slurp {

    my $slurp = &slurp( @_ );
    $slurp =~ s/\\/\\/g;

    return( '"' .  $slurp  . '"' );

}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Perl6::Slurp::Interpret - Interpret slurped files  


=head1 SYNOPSIS

  use Perl6::Slurp::Interpret;
  
  my $colums = "Name, Birthdate";
  my $table  = "Customer";

  #### Use with regular file ... ####
      my $interpreted = eval_slurp( $filename );


  #### Use e.g. with Inline::Files ####
    use Inline::Files;
    my $sql = eval_slurp( \*SQL );     # Or any other token name

    # Now do something useful with $sql 

  __SQL__
  SELECT $columns
  FROM $table


=head1 DESCRIPTION

B<WARNING: This module allows code injection.  Use with Caution>

B<Perl6::Slurp::Interpret>

Perl6::Slurp::Interpret exports two functions, B<eval_slurp> and 
B<quote_slurp>.  Both functions slurp in a file and quote them. 
B<eval_slurp> takes the additional step of eval'ing in the caller's
namespace, e.g. global symbols will be interpolated.   

    
The module was predominantly designed with Inline::Files in mind.  
It can be used as seperatng content from code but not at the expense  
multiple external files.  It is a more elegant approach to the 
<<"HEREDOC" practice commonly found in Perl programs.  

The power of such an approach should be striking to anyone who has
written scripts that interact to any number of external programs 
or processes.  eval_slurp'd files can be passed to function or system
calls.


B<eval_slurp> passes all it's arguments to Perl6::Slurp.  So it is 
possible to slurp anything that Perl6::Slurp slurps.  Perl6::Slurp's
magic works...and the result is eval'd in the current scope.

It's a one line function.  That's it.


=head1 WARNING

This modules presents a serious security risk since it evals an 
external, possibly user supplied file.  Do not use this module if you:

* Do not know what you are doing.

* Cannot insure that friendliness of the slurped file or environment.


=head2 EXPORT

eval_slurp

quote_slurp


=head1 TODO

* Create a quoted and an unquoted version?

** eval_slurp_quoted ... evals Perl code.

* Make the eval in the namespace more robust.


=head1 SEE ALSO

Inline::Files, Perl6::Slurp, Inline::TT


=head1 AUTHOR

Brown, E<lt>ctbrown@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Christopher Brown

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

