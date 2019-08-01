package Telugu::AsciiMap;

use strict;
use warnings;
use utf8;

our $VERSION = '0.06';


# soon an updated version of this module will be uploaded to cpan.

my $eng = "\, \- \. \/ 0 1 2 3 4 5 6 7 8 9 \: \; \< \= \> \? \@ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \[ \\ \] \^ \_ \` a b c d e f g h i j k l m n o p q r s t u v w x y z \{ \| ";
my $tel = "అ ఆ ఇ ఈ ఉ ఊ ఋ ౠ ఌ ౡ ఎ ఏ ఐ ఒ ఓ ఔ ం ః ఁ ్ క ఖ గ ఘ ఙ చ ఛ జ ఝ ఞ ట ఠ డ ఢ ణ త థ ద ధ న ప ఫ బ భ మ య ర ల వ శ ష స హ ళ ా ి ీ ు ూ ృ ౄ ౢ ౣ ె ే ై ొ ో ౌ ౦ ౧ ౨ ౩ ౪ ౫ ౬ ౭ ౮ ౯ ఓం";
my %hashente;
my %hashteen;
my @telugu = split(" ", $tel);
my @english = split(" ", $eng );
@hashente{@english} = @telugu;
@hashteen{@telugu} = @english;

#%hashteen = ('అ' => ',', 'ఆ' => '-', 'ఇ' => '.', 'ఈ' => '/', 'ఉ' => '0', 'ఊ' => '1', 'ఋ' => '2', 'ౠ' => '3', 'ఌ' => '4', 'ౡ' => '5', 'ఎ' => '6', 'ఏ' => '7', 'ఐ' => '8', 'ఒ' => '9', 'ఓ' => ':', 'ఔ' => ';', 'ం' => '<', 'ః' => '=', 'ఁ' => '>', '్' => '?', 'క' => '@', 'ఖ' => 'A', 'గ' => 'B', 'ఘ' => 'C', 'ఙ' => 'D', 'చ' => 'E', 'ఛ' => 'F', 'జ' => 'G', 'ఝ' => 'H', 'ఞ' => 'I', 'ట' => 'J', 'ఠ' => 'K', 'డ' => 'L', 'ఢ' => 'M', 'ణ' => 'N', 'త' => 'O', 'థ' => 'P', 'ద' => 'Q', 'ధ' => 'R', 'న' => 'S', 'ప' => 'T', 'ఫ' => 'U', 'బ' => 'V', 'భ' => 'W', 'మ' => 'X', 'య' => 'Y', 'ర' => 'Z', 'ల' => '[', 'వ' => '\', 'శ' => ']', 'ష' => '^', 'స' => '_', 'హ' => '`', 'ళ' => 'a', 'ా' => 'b', 'ి' => 'c', 'ీ' => 'd', 'ు' => 'e', 'ూ' => 'f', 'ృ' => 'g', 'ౄ' => 'h', 'ౢ' => 'i', 'ౣ' => 'j', 'ె' => 'k', 'ే' => 'l', 'ై' => 'm', 'ొ' => 'n', 'ో' => 'o', 'ౌ' => 'p', '౦' => 'q', '౧' => 'r', '౨' => 's', '౩' => 't', '౪' => 'u', '౫' => 'v', '౬' => 'w', '౭' => 'x', '౮' => 'y', '౯' => 'z', 'ఓం' => '{');

#%hashente = (',' => 'అ', '-' => 'ఆ', '.' => 'ఇ', '/' => 'ఈ', '0' => 'ఉ', '1' => 'ఊ', '2' => 'ఋ', '3' => 'ౠ', '4' => 'ఌ', '5' => 'ౡ', '6' => 'ఎ', '7' => 'ఏ', '8' => 'ఐ', '9' => 'ఒ', ':' => 'ఓ', ';' => 'ఔ', '<' => 'ం', '=' => 'ః', '>' => 'ఁ', '?' => '్', '@' => 'క', 'A' => 'ఖ', 'B' => 'గ', 'C' => 'ఘ', 'D' => 'ఙ', 'E' => 'చ', 'F' => 'ఛ', 'G' => 'జ', 'H' => 'ఝ', 'I' => 'ఞ', 'J' => 'ట', 'K' => 'ఠ', 'L' => 'డ', 'M' => 'ఢ', 'N' => 'ణ', 'O' => 'త', 'P' => 'థ', 'Q' => 'ద', 'R' => 'ధ', 'S' => 'న', 'T' => 'ప', 'U' => 'ఫ', 'V' => 'బ', 'W' => 'భ', 'X' => 'మ', 'Y' => 'య', 'Z' => 'ర', '[' => 'ల', '\' => 'వ', ']' => 'శ', '^' => 'ష', '_' => 'స', '`' => 'హ', 'a' => 'ళ', 'b' => 'ా', 'c' => 'ి', 'd' => 'ీ', 'e' => 'ు', 'f' => 'ూ', 'g' => 'ృ', 'h' => 'ౄ', 'i' => 'ౢ', 'j' => 'ౣ', 'k' => 'ె', 'l' => 'ే', 'm' => 'ై', 'n' => 'ొ', 'o' => 'ో', 'p' => 'ౌ', 'q' => '౦', 'r' => '౧', 's' => '౨', 't' => '౩', 'u' => '౪', 'v' => '౫', 'w' => '౬', 'x' => '౭', 'y' => '౮', 'z' => '౯', '{' => 'ఓం');


sub new {
	my $class = shift;
	return bless {}, $class;
}


sub convert {
	my $self = shift;
    my $string = shift;

    my @convertedout;
    my %checkval = map { $_ => 1 } @telugu;
    my @stringsplit = split('', $string);
    for my $cv (0..$#stringsplit) {
        my $ordvalue = ord($stringsplit[$cv]);
        if ($ordvalue <= 3199 && $ordvalue >= 3072 ) {
            if(exists($checkval{$stringsplit[$cv]})) {
                push @convertedout, $hashteen{$stringsplit[$cv]};
            }
            else {
                push @convertedout, $stringsplit[$cv];
            }
        }
        elsif ($ordvalue <= 124 && $ordvalue >= 44 ){
            push @convertedout, $hashente{$stringsplit[$cv]};
        }
        else {
            push @convertedout, $stringsplit[$cv];
        }
    }
    return join("", @convertedout);
}


sub deconvert {
	my $self = shift;
    my $string = shift;

    my @convertedout;
    my @stringsplit = split('', $string);
    for my $cv (0..$#stringsplit) {
           my $ordvalue = ord($stringsplit[$cv]);
           if ($ordvalue <= 124 && $ordvalue >= 44 ) {
               push @convertedout, $hashente{$stringsplit[$cv]};
           }
           elsif ($ordvalue <= 3199 && $ordvalue >= 3072 ){
               push @convertedout, $hashteen{$stringsplit[$cv]};
           }
           else {
               push @convertedout, $stringsplit[$cv];
           }
     }
    return join("", @convertedout);
}

1;
__END__
=encoding utf-8

=head1 NAME

Telugu::AsciiMap - Map Telugu chars to ascii chars to save space

=head1 SYNOPSIS

  use Telugu::AsciiMap;
  use utf8;
  binmode STDOUT, ":encoding(UTF-8)";

  my $map = Telugu::AsciiMap->new();
  my $asciistring = $map->convert('రాజ్కుమార్రెడ్డి');
  my $telugustring = $map->deconvert($asciistring);
  print $asciistring, "\n", $telugustring, "\n";


=head1 DESCRIPTION

Each Telugu char uses four times the space required for an ascii char.
This module provides two functions to convert Telugu text to ascii text and to convert back that ascii text to Telugu.


=head1 AUTHOR

Rajkumar Reddy, mesg.raj@outlook.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
