package Parse::Extract::Net::MAC48;

use strict;
use warnings;

use re 'eval';

our $VERSION = '0.01';

our $charset = '0-9A-Fa-f';

our $c = '['. $charset .']';   #character
our $cc = $c.$c;               #just shorthand
our $cccc = $cc.$cc;           #again shorthand

#---------- Constructor ----------#
sub new
{
  my ($pkgname) = @_;

  my ($instance) = {};

  bless($instance, "Parse::Extract::Net::MAC48");

return $instance;
}

sub extract
{
  my $instance = shift;
  
  local($/);
  my $data = @_;
  
  my (@results);
  
  if( my @match = (
                   $data =~ /
                                 (?<!$c)
                                 (?:
                                   (?:($cc([:-]) $cc (?:\2$cc){4}){1}) |
                                   (?:($cccc(\.)$cccc\.$cccc){1})
                                 )
                                 (??{ ($4 eq '.') ? '(?<!\..{14})' : '(?<!'.$2.'.{17})' })
                                 (?!(??{ ($4 eq '.') ? '\.' : $2 })|$c) #collapse this to 1 eval
                            /gcxo
            ) )
  {
    my $MAC = '';
    my $delim = '';
    while( scalar(@match) > 0 )
    {
      if( defined($match[0]) )
      {
        my $MAC = shift(@match);
        my $delim = shift(@match);
        splice(@match, 0, 2);
        if( $MAC =~ /[a-f]/ )	#to be configurable
        { 
          $MAC = uc($MAC); #might be faster with a tr instead of m+uc?
        }
         
        if( defined $delim && $delim eq '-' ) #to be configurable
        {
          $MAC =~ tr/-/:/;
        }
        push(@results, $MAC); 
      }
      else
      {
        splice(@match, 0, 2);
        my $MAC = shift(@match);
        my $delim = '.'; #shift(@match);
        shift(@match);
        push(@results, $MAC);
      }
    $MAC = '';
    $delim = '';
    }
  }

return(@results);
}

1;

__END__

=head1 NAME

    Parse::Extract::Net::MAC48 - Parse::Extract extraction template for MAC-48 addresses

=head1 SYNOPSIS

      use Parse::Extract;
      use Parse::Extract::Net::MAC48;

      $myParser = new Parse::Extract(); 
      $myMACTemplate = new Parse::Extract::Net::MAC48();

      $myParser->registerTemplate( \$myMACTemplate );

        #returns list of matched addresses
      @addresses = $myParser->parse( $data );
      
      #-OR-
      
      $myMACTemplate = new Parse::Extract::Net::MAC48();
      @addresses = $myMACTemplate->extract( $data );

=head1 DESCRIPTION

    Parse::Extract::Net::MAC48 - Parse::Extract extraction template for MAC-48 addresses

	MAC48 is a extractor template for use with Parse::Extract. 
        This module should be used whenever a data stream contains
        desired MAC-48 addresses and a correct, efficient parser
        is required. MAC48 has a near zero false negative rate and
        a very low false positive rate. As with any Parse::Extract 
        extraction template, MAC48 may be used in combination
        with other Parse::Extract extraction templates.



=head1 USAGE

    new()
      Constructor.
      Returns new instance of MAC48.
    
    
=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make install

=head1 DEPENDENCIES

  none

=head1 BUGS
  
  This is currently pre-alpha software.
  
  MAC48 is however now passing all test cases.

  Please be aware that it will currently match addresses 
  containing mixed case. This was an intentional design
  decision due to the ambiguity of hexadecimal.
  Unfortunately it also causes a small amount of
  false positives.

  This may change to be configurable in the future.

=head1 AUTHORS, COPYRIGHT, AND LICENCE

Copyright (C) 2009, 2010 Charles A Morris.  All rights reserved.

Additional contributions from:
Irwin Levinstein <ibl@cs.odu.edu>
Minhao Dong <mdong@cs.odu.edu>

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
