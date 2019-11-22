package Telugu::AsciiMap;

use Mouse;
use utf8;
use Kavorka -all;

our $VERSION = '0.08';


has 'TeMap' => (
	is => 'ro',
	isa => 'HashRef',
	default => sub {
		return {'అ' => ',', 'ఆ' => '-', 'ఇ' => '.', 'ఈ' => '/', 'ఉ' => '0', 'ఊ' => '1', 'ఋ' => '2', 'ౠ' => '3', 'ఌ' => '4', 'ౡ' => '5', 'ఎ' => '6', 'ఏ' => '7', 'ఐ' => '8', 'ఒ' => '9', 'ఓ' => ':', 'ఔ' => ';', 'ం' => '<', 'ః' => '=', 'ఁ' => '>', '్' => '?', 'క' => '@', 'ఖ' => 'A', 'గ' => 'B', 'ఘ' => 'C', 'ఙ' => 'D', 'చ' => 'E', 'ఛ' => 'F', 'జ' => 'G', 'ఝ' => 'H', 'ఞ' => 'I', 'ట' => 'J', 'ఠ' => 'K', 'డ' => 'L', 'ఢ' => 'M', 'ణ' => 'N', 'త' => 'O', 'థ' => 'P', 'ద' => 'Q', 'ధ' => 'R', 'న' => 'S', 'ప' => 'T', 'ఫ' => 'U', 'బ' => 'V', 'భ' => 'W', 'మ' => 'X', 'య' => 'Y', 'ర' => 'Z', 'ల' => '[', 'వ' => 'వ', 'శ' => ']', 'ష' => '^', 'స' => '_', 'హ' => '`', 'ళ' => 'a', 'ా' => 'b', 'ి' => 'c', 'ీ' => 'd', 'ు' => 'e', 'ూ' => 'f', 'ృ' => 'g', 'ౄ' => 'h', 'ౢ' => 'i', 'ౣ' => 'j', 'ె' => 'k', 'ే' => 'l', 'ై' => 'm', 'ొ' => 'n', 'ో' => 'o', 'ౌ' => 'p', '౦' => 'q', '౧' => 'r', '౨' => 's', '౩' => 't', '౪' => 'u', '౫' => 'v', '౬' => 'w', '౭' => 'x', '౮' => 'y', '౯' => 'z', 'ఓం' => '{'
		, ',' => 'అ', '-' => 'ఆ', '.' => 'ఇ', '/' => 'ఈ', '0' => 'ఉ', '1' => 'ఊ', '2' => 'ఋ', '3' => 'ౠ', '4' => 'ఌ', '5' => 'ౡ', '6' => 'ఎ', '7' => 'ఏ', '8' => 'ఐ', '9' => 'ఒ', ':' => 'ఓ', ';' => 'ఔ', '<' => 'ం', '=' => 'ః', '>' => 'ఁ', '?' => '్', '@' => 'క', 'A' => 'ఖ', 'B' => 'గ', 'C' => 'ఘ', 'D' => 'ఙ', 'E' => 'చ', 'F' => 'ఛ', 'G' => 'జ', 'H' => 'ఝ', 'I' => 'ఞ', 'J' => 'ట', 'K' => 'ఠ', 'L' => 'డ', 'M' => 'ఢ', 'N' => 'ణ', 'O' => 'త', 'P' => 'థ', 'Q' => 'ద', 'R' => 'ధ', 'S' => 'న', 'T' => 'ప', 'U' => 'ఫ', 'V' => 'బ', 'W' => 'భ', 'X' => 'మ', 'Y' => 'య', 'Z' => 'ర', '[' => 'ల', 'వ' => 'వ', ']' => 'శ', '^' => 'ష', '_' => 'స', '`' => 'హ', 'a' => 'ళ', 'b' => 'ా', 'c' => 'ి', 'd' => 'ీ', 'e' => 'ు', 'f' => 'ూ', 'g' => 'ృ', 'h' => 'ౄ', 'i' => 'ౢ', 'j' => 'ౣ', 'k' => 'ె', 'l' => 'ే', 'm' => 'ై', 'n' => 'ొ', 'o' => 'ో', 'p' => 'ౌ', 'q' => '౦', 'r' => '౧', 's' => '౨', 't' => '౩', 'u' => '౪', 'v' => '౫', 'w' => '౬', 'x' => '౭', 'y' => '౮', 'z' => '౯', '{' => 'ఓం'};
	}
);

method asciimap($string) {
    my @stringsplit = split('', $string);
    my @out;
    for my $c (0..$#stringsplit) {
        if( defined($self->TeMap->{$stringsplit[$c]}) ) {
            push @out, $self->TeMap->{$stringsplit[$c]};
        }
        else {
            push @out, $stringsplit[$c];
        }
    }
    return join("", @out);
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
  my $asciistring = $map->asciimap('రాజ్కుమార్రెడ్డి');	    # use asciimap method to convert telugu text to ascii
  my $telugustring = $map->asciimap($asciistring);  # use the same method to convet back ascii text to telugu
  print $asciistring, "\n", $telugustring, "\n";


=head1 DESCRIPTION

Each Telugu char uses four times the space required for an ascii char.
This module provides a functions to convert Telugu text to ascii text and to convert back that ascii text to Telugu.


=head1 AUTHOR

Rajkumar Reddy, mesg.raj@outlook.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
