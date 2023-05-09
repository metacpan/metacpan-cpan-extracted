package SPVM::Regex::ReplaceInfo;

1;

=head1 Name

SPVM::Regex::ReplaceInfo - Regex Replacement Information

=head1 Description

The Regex::ReplaceInfo class of L<SPVM> has methods to manipulate a regex replacement information.

=head1 Usage

  use Regex::ReplaceInfo;
  
  my $match = Regex::ReplaceInfo->new({replaced_count => 3});
  
  my $cap1 = $match->cap1;
  my $cap2 = $match->cap2;
  my $cpa3 = $match->cap3;

=head1 Fields

=head2 replaced_count

  has replaced_count : ro int;

Gets the C<replaced_count> field.

The replacement count.

=head1 Class Methods

=head2 new

  static method new : Regex::ReplaceInfo ($options = undef : object[]);

Creates a new L<Regex::ReplaceInfo> object.

Options:

The options are key-value pairs. Each key must be a string type. Otherwise an exception is thrown.

If an unsupported option is specified, an exception is thrown.

=over 2

=item * C<replaced_count>

Sets the C<replaced_count> field.

This option must be cast to a L<Int|SPVM::Int> object. Otherwise an exception is thrown.

=back

Examples:

  my $match = Regex::ReplaceInfo->new({replaced_count => 3});

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
