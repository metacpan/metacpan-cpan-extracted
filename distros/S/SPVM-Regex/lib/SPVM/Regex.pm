package SPVM::Regex;

our $VERSION = '0.23';

1;

=encoding utf8

=head1 Name

SPVM::Regex - Regular Expressions

=head1 Description

The Regex class of L<SPVM> has methods for regular expressions.

L<Google RE2|https://github.com/google/re2> is used as the regular expression library.

=head1 Usage
  
  use Regex;
  
  # Pattern match
  {
    my $re = Regex->new("ab*c");
    my $string = "zabcz";
    my $match = $re->match("zabcz");
  }

  # Pattern match - UTF-8
  {
    my $re = Regex->new("あ+");
    my $string = "いあああい";
    my $match = $re->match($string);
  }

  # Pattern match - Character class and the nagation
  {
    my $re = Regex->new("[A-Z]+[^A-Z]+");
    my $string = "ABCzab";
    my $match = $re->match($string);
  }

  # Pattern match with captures
  {
    my $re = Regex->new("^(\w+) (\w+) (\w+)$");
    my $string = "abc1 abc2 abc3";
    my $match = $re->match($string);
    
    if ($match) {
      my $cap1 = $re->cap1;
      my $cap2 = $re->cap2;
      my $cpa3 = $re->cap3;
    }
  }
  
  # Replace
  {
    my $re = Regex->new("abc");
    my $string = "ppzabcz";
    
    # "ppzABCz"
    my $result = $re->replace($string, "ABC");
    
    my $replaced_count = $re->replaced_count;
  }

  # Replace with a callback and capture
  {
    my $re = Regex->new("a(bc)");
    my $string = "ppzabcz";
    
    # "ppzABbcCz"
    my $result = $re->replace($string, method : string ($re : Regex) {
      return "AB" . $re->cap1 . "C";
    });
  }

  # Replace global
  {
    my $re = Regex->new("abc");
    my $string = "ppzabczabcz";
    
    # "ppzABCzABCz"
    my $result = $re->replace_g($string, "ABC");
  }

  # Replace global with a callback and capture
  {
    my $re = Regex->new("a(bc)");
    my $string = "ppzabczabcz";
    
    # "ppzABCbcPQRSzABCbcPQRSz"
    my $result = $re->replace_g($string, method : string ($re : Regex) {
      return "ABC" . $re->cap1 . "PQRS";
    });
  }

  # . - single line mode
  {
    my $re = Regex->new("(.+)", "s");
    my $string = "abc\ndef";
    
    my $match = $re->match($string);
    
    unless ($match) {
      return 0;
    }
    
    unless ($re->cap1 eq "abc\ndef") {
      return 0;
    }
  }

=head1 Dependent Resources

=over 2

=item * L<SPVM::Resource::RE2>

=back

=head1 Regular Expression Syntax

L<Google RE2 Syntax|https://github.com/google/re2/wiki/Syntax>

=head1 Fields

=head2 captures

  has captures : ro string[];

The captured strings.

=head2  match_start

  has match_start : ro int;

The start offset of the matched string.

=head2 match_length

  has match_length : ro int;

The length of the matched string.

=head2 replaced_count

  has replaced_count : ro int;

The replaced count.

=head1 Class Methods

=head2 new

  static method new : Regex ($pattern : string, $flags = undef : string)

Creates a new L<Regex|SPVM::Regex> object and compiles the regex pattern $pattern with the flags $flags, and retruns the created object.

  my $re = Regex->new("^ab+c");
  my $re = Regex->new("^ab+c", "s");

=head1 Instance Methods

=head2 match

  method match : int ($string : string, $offset = 0 : int, $length = -1 : int);

The alias for the following L<match_forward|/"match_forward"> method.

  my $ret = $self->match_forward($string, \$offset, $length);

=head2 match_forward

  method match_forward : int ($string : string, $offset : int*, $length = -1 : int)

Performs pattern matching on the substring from the offset $offset to the length $length of the string $string.

The $offset is updated to the next position.

If the pattern matching is successful, returns 1. Otherwise returns 0.

Exceptions:

The $string must be defined. Otherwise an exception is thrown.

The $offset + the $length must be less than or equal to the length of the $string. Otherwise an exception is thrown.

If the regex is not compiled, an exception is thrown.

=head2 replace

  method replace  : string ($string : string, $replace : object of string|Regex::Replacer, $offset = 0 : int, $length = -1 : int, $options = undef : object[])

The alias for the following L<replace_common|/"replace_common"> method.

  my $ret = $self->replace_common($string, $replace, \$offset, $length, $options);

=head2 replace_g

  method replace_g  : string ($string : string, $replace : object of string|Regex::Replacer, $offset = 0 : int, $length = -1 : int, $options = undef : object[])

The alias for the following L<replace_common|/"replace_common"> method.

  my $new_options_list = List->new($options);
  $new_options_list->push("global");
  $new_options_list->push(1);
  $options = $new_options_list->to_array;
  return $self->replace_common($string, $replace, \$offset, $length, $options);

=head2 replace_common

  method replace_common : string ($string : string, $replace : object of string|Regex::Replacer,
    $offset_ref : int*, $length = -1 : int, $options = undef : object[]);

Replaces the substring from the offset $$offset_ref to the length $length of the string $string with the replacement string or callback $replace with the options $options.

If the $replace is a L<Regex::Replacer|SPVM::Regex::Replacer> object, the return value of the callback is used for the replacement.

Options:

=over 2

=item * global : Int

If the value of the L<Int|SPVM::Int> object is a true value, the global replacement is performed.

=back

Exceptions:

The $string must be defined. Otherwise an exception is thrown.

The $replace must be a string or a L<Regex::Replacer|SPVM::Regex::Replacer> object. Otherwise an exception is thrown.

The $offset must be greater than or equal to 0. Otherwise an exception is thrown.

The $offset + the $length must be less than or equal to the length of the $string. Otherwise an exception is thrown.

Exceptions of the L<match_forward|/"match_forward"> method can be thrown.

=head2 split

  method split : string[] ($string : string, $limit = 0 : int);

The same as the L<split||SPVM::Fn/"split"> method in the L<Fn|SPVM::Fn> class, but the regular expression is used as the separator.

=head2 cap1

  method cap1 : string ();

The alias for C<$re-E<gt>captures-E<gt>[1]>.

=head2 cap2

  method cap2 : string ();

The alias for C<$re-E<gt>captures-E<gt>[2]>.

=head2 cap3

  method cap3 : string ();

The alias for C<$re-E<gt>captures-E<gt>[3]>.

=head2 cap4

  method cap4 : string ();

The alias for C<$re-E<gt>captures-E<gt>[4]>.

=head2 cap5

  method cap5 : string ();

The alias for C<$re-E<gt>captures-E<gt>[5]>.

=head2 cap6

  method cap6 : string ();

The alias for C<$re-E<gt>captures-E<gt>[6]>.

=head2 cap7

  method cap7 : string ();

The alias for C<$re-E<gt>captures-E<gt>[7]>.

=head2 cap8

  method cap8 : string ();

The alias for C<$re-E<gt>captures-E<gt>[8]>.

=head2 cap9

  method cap9 : string ();

The alias for C<$re-E<gt>captures-E<gt>[9]>.

=head2 cap10

  method cap10 : string ();

The alias for C<$re-E<gt>captures-E<gt>[10]>.

=head2 cap11

  method cap11 : string ();

The alias for C<$re-E<gt>captures-E<gt>[11]>.

=head2 cap12

  method cap12 : string ();

The alias for C<$re-E<gt>captures-E<gt>[12]>.

=head2 cap13

  method cap13 : string ();

The alias for C<$re-E<gt>captures-E<gt>[13]>.

=head2 cap14

  method cap14 : string ();

The alias for C<$re-E<gt>captures-E<gt>[14]>.

=head2 cap15

  method cap15 : string ();

The alias for C<$re-E<gt>captures-E<gt>[15]>.

=head2 cap16

  method cap16 : string ();

The alias for C<$re-E<gt>captures-E<gt>[16]>.

=head2 cap17

  method cap17 : string ();

The alias for C<$re-E<gt>captures-E<gt>[17]>.

=head2 cap18

  method cap18 : string ();

The alias for C<$re-E<gt>captures-E<gt>[18]>.

=head2 cap19

  method cap19 : string ();

The alias for C<$re-E<gt>captures-E<gt>[19]>.

=head2 cap20

  method cap20 : string ();

The alias for C<$re-E<gt>captures-E<gt>[20]>.

=head1 Repository

L<SPVM::Regex - Github|https://github.com/yuki-kimoto/SPVM-Regex>

=head1 Author

L<Yuki Kimoto|https://github.com/yuki-kimoto>

=head1 Contributors

=over 2

=item * L<Ryunosuke Murakami|https://github.com/ryun0suke22>

=item * L<greengorcer|https://github.com/greengorcer>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
