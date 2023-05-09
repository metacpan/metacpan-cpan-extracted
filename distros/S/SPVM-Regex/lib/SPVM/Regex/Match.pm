package SPVM::Regex::Match;

1;

=head1 Name

SPVM::Regex::Match - Regex Matching Result

=head1 Description

The Regex::Match class of L<SPVM> has methods to manipulate a regex matching result.

=head1 Usage

  use Regex::Match;
  
  my $match = Regex::Match->new({success => 1, captures => [(string)"abc", "def"]});
  
  my $cap1 = $match->cap1;
  my $cap2 = $match->cap2;
  my $cpa3 = $match->cap3;

=head1 Fields

=head2 success

  has success : ro byte;

Gets the C<success> field.

If a pattern match is successful, this field is set to 1.

=head2 captures

  has captures : string[];

Gets the C<captures> field.

The captured strings.

  method captures : string ($index : int);

The C<captures> method is the method to get an element of the C<captures> field.

The length of the C<captures> field can be got by the L</"captures_length"> method.

=head2  match_start

  has match_start : ro int;

Gets the C<match_start> field.

The start offset of the matched string.

=head2 match_length

  has match_length : ro int;

Gets the C<match_length> field.

The length of the matched string.

=head1 Class Methods

=head2 new

  static method new : Regex::Match ($options = undef : object[]);

Creates a new L<Regex::Match> object.

Options:

The options are key-value pairs.

Each key must be a string type. Otherwise an exception is thrown.

If an unsupported option is specified, an exception is thrown.

=over 2

=item * C<success>

Sets the C<success> field.

This option must be cast to a L<Int|SPVM::Int> object. Otherwise an exception is thrown.

=item * C<match_start>

Sets the C<match_start> field.

This option must be cast to a L<Int|SPVM::Int> object. Otherwise an exception is thrown.

=item * C<match_length>

Sets the C<match_length> field.

This option must be cast to a L<Int|SPVM::Int> object. Otherwise an exception is thrown.

=item * C<captures>

Sets the C<captures> field.

A new string array with the same length of this option is created and the address of each string is copied.

This option must be cast to a string[] object. Otherwise an exception is thrown.

=back

Examples:

  my $match = Regex::Match->new({success => 1, captures => [(string)"abc", "def"]});

=head1 Instance Methods

=head2 captures_length

  method captures_length : int ();

Gets the length of the L</"captures"> field.

=head2 cap1

  method cap1 : string ();

The same as the L</"captures"> method with 1 as the argument $index.

=head2 cap2

  method cap2 : string ();

The same as the L</"captures"> method with 2 as the argument $index.

=head2 cap3

  method cap3 : string ();

The same as the L</"captures"> method with 3 as the argument $index.

=head2 cap4

  method cap4 : string ();

The same as the L</"captures"> method with 4 as the argument $index.

=head2 cap5

  method cap5 : string ();

The same as the L</"captures"> method with 5 as the argument $index.

=head2 cap6

  method cap6 : string ();

The same as the L</"captures"> method with 6 as the argument $index.

=head2 cap7

  method cap7 : string ();

The same as the L</"captures"> method with 7 as the argument $index.

=head2 cap8

  method cap8 : string ();

The same as the L</"captures"> method with 8 as the argument $index.

=head2 cap9

  method cap9 : string ();

The same as the L</"captures"> method with 9 as the argument $index.

=head2 cap10

  method cap10 : string ();

The same as the L</"captures"> method with 10 as the argument $index.

=head2 cap11

  method cap11 : string ();

The same as the L</"captures"> method with 11 as the argument $index.

=head2 cap12

  method cap12 : string ();

The same as the L</"captures"> method with 12 as the argument $index.

=head2 cap13

  method cap13 : string ();

The same as the L</"captures"> method with 13 as the argument $index.

=head2 cap14

  method cap14 : string ();

The same as the L</"captures"> method with 14 as the argument $index.

=head2 cap15

  method cap15 : string ();

The same as the L</"captures"> method with 15 as the argument $index.

=head2 cap16

  method cap16 : string ();

The same as the L</"captures"> method with 16 as the argument $index.

=head2 cap17

  method cap17 : string ();

The same as the L</"captures"> method with 17 as the argument $index.

=head2 cap18

  method cap18 : string ();

The same as the L</"captures"> method with 18 as the argument $index.

=head2 cap19

  method cap19 : string ();

The same as the L</"captures"> method with 19 as the argument $index.

=head2 cap20

  method cap20 : string ();

The same as the L</"captures"> method with 20 as the argument $index.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
