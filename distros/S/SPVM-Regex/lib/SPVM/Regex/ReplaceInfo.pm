package SPVM::Regex::ReplaceInfo;

1;

=head1 Name

SPVM::Regex::ReplaceInfo - Regex Replacement Information

=head1 Description

The Regex::ReplaceInfo class of L<SPVM> has methods to manipulate a regex replacement information.

=head1 Usage

  use Regex::ReplaceInfo;
  
  my $replace_info = Regex::ReplaceInfo->new({replaced_count => 3, match => $match});
  
  my $replaced_count = $replace_info->replaced_count;
  
  my $match = $replace_info->match;
  my $cap1 = $match->cap1;
  my $cap2 = $match->cap2;
  my $cpa3 = $match->cap3;

=head1 Fields

=head2 replaced_count

  has replaced_count : ro int;

Gets the C<replaced_count> field.

This field is set to the number of strings replaced the L<replace|SPVM::Regex/"replace"> and L<replace_g|SPVM::Regex/"replace_g"> method in the L<Regex|SPVM::Regex> class.

=head2 match

  has match : ro Regex::Match;

Gets the C<match> field. The type is L<Regex::Match|SPVM::Regex::Match>.

This field is set to the result of the pattern match performed by the the L<replace|SPVM::Regex/"replace"> and L<replace_g|SPVM::Regex/"replace_g"> method in the L<Regex|SPVM::Regex> class.

=head1 Class Methods

=head2 new

  static method new : Regex::ReplaceInfo ($options : object[] = undef);

Creates a new L<Regex::ReplaceInfo> object.

Options:

The options are key-value pairs. Each key must be a string type. Otherwise an exception is thrown.

If an unsupported option is specified, an exception is thrown.

=over 2

=item * C<replaced_count>

Sets the L</"replaced_count"> field.

The value must be cast to the C<int> type. Otherwise an exception is thrown.

Default:

0

=item * C<match>

Sets the L</"match"> field.

The value must be a L<Regex::Match|SPVM::Regex::Match> object or C<undef>. Otherwise an exception is thrown.

Default:

undef

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
