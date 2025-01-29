package SPVM::Unicode::Normalize;

our $VERSION = "0.005";

1;

=encoding utf8

=head1 Name

SPVM::Unicode::Normalize - Normalizing UTF-8

=head1 Description

Unicode::Normalize class in L<SPVM> has methods to normalize UTF-8.

=head1 Usage

  use Unicode::Normalize;
   
  my $NFD_string  = Unicode::Normalize->NFD($string);
  
  my $NFC_string  = Unicode::Normalize->NFC($string);
  
  my $NFKD_string = Unicode::Normalize->NFKD($string);
  
  my $NFKC_string = Unicode::Normalize->NFKC($string);

=head1 Class Methods

=head2 NFC

C<static method NFC : string ($string : string);>

Returns the Normalization Form C (formed by canonical decomposition followed by canonical composition).

This method calls native C<utf8proc_map> function defined in C<ut8proc.h> of L<utf8proc|SPVM::Resource::Utf8proc> library.

Exceptions:

The string $string must be defined. Otherwise an exception is thrown.

If utf8proc_map failed, an exception is thrown.

=head2 NFD

C<static method NFD : string ($string : string);>

Returns the Normalization Form D (formed by canonical decomposition).

This method calls native C<utf8proc_map> function defined in C<ut8proc.h> of L<utf8proc|SPVM::Resource::Utf8proc> library.

Exceptions:

The string $string must be defined. Otherwise an exception is thrown.

If utf8proc_map failed, an exception is thrown.

=head2 NFKC

C<static method NFKC : string ($string : string);>

Returns the Normalization Form KC (formed by compatibility decomposition followed by canonical composition).

This method calls native C<utf8proc_map> function defined in C<ut8proc.h> of L<utf8proc|SPVM::Resource::Utf8proc> library.

Exceptions:

The string $string must be defined. Otherwise an exception is thrown.

If utf8proc_map failed, an exception is thrown.

=head2 NFKD

C<static method NFKD : string ($string : string);>

Returns the Normalization Form KD (formed by compatibility decomposition).

This method calls native C<utf8proc_map> function defined in C<ut8proc.h> of L<utf8proc|SPVM::Resource::Utf8proc> library.

Exceptions:

The string $string must be defined. Otherwise an exception is thrown.

If utf8proc_map failed, an exception is thrown.

=head1 See Also

=over 2

=item * L<Resource::Utf8proc|SPVM::Resource::Utf8proc>

=back

=head1 Porting

L<SPVM::Unicode::Normalize> is a Perl's L<Unicode::Normalize> porting to L<SPVM>.

=head1 Repository

L<SPVM::Unicode::Normalize - Github|https://github.com/yuki-kimoto/SPVM-Unicode-Normalize>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
