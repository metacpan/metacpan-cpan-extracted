package SPVM::Regex::Replacer;

1;

=head1 Name

SPVM::Regex::Replacer - Interface Type for Regex Replacement Callback

=head1 Usage
  
  use Regex::Replacer;
  use Regex;
  
  my $replacer = (Regex::Replacer)method : string ($re : Regex) {
    my $replaced_string_match = "AB" . $re->cap1 . "C";
    return $replaced_string_match;
  });
  
  my $string = "abc";
  my $re = Regex->new("ab(c)");
  my $replaced_string = $re->replace_g($string, $replacer);

=head1 Description

L<Regex::Replacer|SPVM::Regex::Replacer> is the interface type for the regex replacement callback.

=head1 Interface Methods

  required method : string ($re : Regex)

The implementation must receive a L<Regex|SPVM::Regex> object and return the string after the replacement.
