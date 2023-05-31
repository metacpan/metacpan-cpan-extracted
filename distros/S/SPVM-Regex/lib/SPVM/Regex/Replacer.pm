package SPVM::Regex::Replacer;

1;

=head1 Name

SPVM::Regex::Replacer - Interface for Regex Replacement Callback

=head1 Description

The Regex::Replacer interface of L<SPVM> has an interface method for the regex replacement callback.

=head1 Usage
  
  use Regex::Replacer;
  use Regex;
  
  my $replacer = (Regex::Replacer)method : string ($re : Regex, $match : Regex::Match) {
    my $replace = "AB" . $match->cap1 . "C";
    return $replace;
  });
  
  my $string = "abc";
  my $re = Regex->new("ab(c)");
  my $replaced_string = $re->replace_g($string, $replacer);

=head1 Interface Methods

  required method : string ($re : Regex, $match : Regex::Match = undef);

Receives a L<Regex|SPVM::Regex> object and a L<Regex::Match|SPVM::Regex::Match> object, and returns a replacement string.

The $match argument will be required in the future release.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
