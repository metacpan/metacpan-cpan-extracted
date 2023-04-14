package SPVM::Regex::Replacer;

1;

=head1 Name

SPVM::Regex::Replacer - Interface for Regex Replacement Callback

=head1 Description

The Regex::Replacer interface of L<SPVM> has interface methods for the regex replacement callback.

=head1 Usage
  
  use Regex::Replacer;
  use Regex;
  
  my $replacer = (Regex::Replacer)method : string ($re : Regex) {
    my $replace = "AB" . $re->cap1 . "C";
    return $replace;
  });
  
  my $string = "abc";
  my $re = Regex->new("ab(c)");
  my $replaced_string = $re->replace_g($string, $replacer);

=head1 Interface Methods

  required method : string ($re : Regex);

Receives a L<Regex|SPVM::Regex> object and returns a replacement string.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

