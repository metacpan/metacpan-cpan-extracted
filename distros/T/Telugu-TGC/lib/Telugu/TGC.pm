package Telugu::TGC;

use strict;
use warnings;
use utf8;

our $VERSION = '1.1';

my @dheerga = ("ా", "ి", "ీ", "ు", "ూ", "ృ", "ౄ", "ె", "ే", "ై", "ొ", "ో", "ౌ", "ం", "ఁ", "ః", "ఀ");
my $visarga = "్";
my @consonant = ( "క", "ఖ", "గ", "ఘ", "ఙ", "చ", "ఛ", "జ", "ఝ", "ఞ", "ట", "ఠ",
                  "ణ", "త", "థ", "ధ", "ప", "ఫ", "బ", "భ", "మ", "య",
                  "డ", "ఢ", "ర", "ఱ", "ల", "ళ", "ఴ", "వ", "శ", "ష", "స", "హ" );

my %dheerga = map { $_ => 1 } @dheerga;
my %consonant = map { $_ => 1 } @consonant;

sub new {
  my ($class) = @_;
  return bless {}, $class;
}

sub tgc {
  my ($class, $string) = @_;

  my $counter = 0;
  my @tgc;
  my @temp;

  my @array = split("", $string);

  while($counter <= $#array) {
      my $element = $array[$counter];
      $counter++;

      if(exists($consonant{$element})) {
          @temp = ();
          push @temp, $element;
          $element = $array[$counter];
          if(exists($dheerga{$element})) {
              $counter++;
              push @temp, $element;
              push @tgc, join("", @temp);
              next;
          }
          if($element eq $visarga) {
              push @temp, $element;
              $counter++;
              while(1) {
                  $element = $array[$counter];
                  if(exists($consonant{$element})) {
                      push @temp, $element;
                      $counter++;
                      $element = $array[$counter];
                      if($dheerga{$element}) {
                          push @temp, $element;
                          $counter++;
                          last;
                      }
                      if($element eq $visarga) {
                          push @temp, $element;
                          $counter++;
                          next;
                      }
                      last;
                  }
                  else {
                      last;
                  }
              }
          }
          push @tgc, join("", @temp);
          next;
      }
      else {
          push @tgc, $element;
          next;
      }
  }

  return @tgc;
}

1;
__END__
=encoding utf-8

=head1 NAME

Telugu::TGC - Perl extension for Tailored Grapheme Clusters for Telugu language.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use utf8;
  use Telugu::TGC;
  
  my $tgcObject = Telugu::TGC->new();
  my @array = $tgcObject->tgc("రాజ్కుమార్రెడ్డి");

=head1 DESCRIPTION

This module provides only one function 'tgc', which splits the given string on TGC's.

=head1 AUTHOR

Rajkumar Reddy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
