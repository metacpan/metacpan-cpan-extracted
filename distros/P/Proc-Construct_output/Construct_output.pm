package Proc::Construct_output;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = (qw(run));
our @EXPORT = qw();

our $VERSION = '0.01';


sub run{
   my($code,$debug)=@_;
   local $_=$code;
   
   while(

      #################
      # if, else, elsif

      s/
         (\W)
         (
            if\s*
               \([^)(}{]*?\)\s*
                  \{[^}{]*?\}\s*
            (?:
               (
                  else|
                  elsif\s*\([^)(}{]*?\)
               )\s*
               {[^}{]*?}\s*
            )*
         )
      /
         my $temp=$1."do___SB___$2"."___FB___";
         $temp =~ s#([{])#___SB___#g;
         $temp =~ s#([}])#___FB___#g;
         $temp =~ s#([(])#___SP___#g;
         $temp =~ s#([)])#___FP___#g;
         $temp
      /sgxe

      || 

      ############
      #output_last

      s/
         (\W)
         output_last\s
            (.*?);
      /$1
         push \@temp,$2;
         last;
      /sgx

      ||

      ########
      #output

      s/
         (\W)
         output\s
            (.*?);
      /$1 push \@temp,$2;/sgx 

      ||

      #####################
      # foreach, while

      s/
         (\W)
         (
            (?:
               (foreach|while)
            )\s*
               \(
                  [^)(}{]*?
               \)\s*
               \{
                  [^}{]*?
               \}
         )
      /
         my $temp=$1."do___SB___my \@temp=();$2;\@temp"."___FB___";
         $temp =~ s#([{])#___SB___#g;
         $temp =~ s#([}])#___FB___#g;
         $temp =~ s#([(])#___SP___#g;
         $temp =~ s#([)])#___FP___#g;
         $temp;
      /sxeg

   ){
      if($debug){
         print;
      }
   }

   s/___SB___/\{/g;
   s/___FB___/\}/g;
   s/___SP___/\(/g;
   s/___FP___/\)/g;

   if($debug){
      print;
   }
   my(@error)=eval $_;
   print @error if $error[0] != 1;
}

1;
__END__

=head1 NAME

Proc::Construct_output - Perl extension to output values from while, foreach and if-elsif-else -constructs.

=head1 SYNOPSIS

use Proc::Construct_output qw(run);

run("# write Your Perl code here");
  
=head1 DESCRIPTION

Lets You to use output values from while, foreach and if-then-else -constructs.

Value from the construct is output when the commands described below are used. If-then-else constructs output their default exit-value as well.

Commands are

- "output" outputs value(s) from a construct

- "output_last" outputs value(s) from a construct and exits the construct (using built-in "last"-command)

=head1 SEE ALSO

Be sure to get examples.pl -file from 

http://www.kolumbus.fi/vilmak/examples.pl

=head1 AUTHOR

Ville Jungman

<ville_jungman@hotmail.com> <ville.jungman@frakkipalvelunam.fi>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Ville Jungman

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
