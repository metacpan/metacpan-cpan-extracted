package SPVM::FindBin;

our $VERSION = "0.035";

1;

=head1 Name

SPVM::FindBin - Directory Path Where Program Is Invoked

=head1 Description

FindBin class in L<SPVM> has method to get the absolute path of the directory where the program was invoked.

=head1 Usage

  use FindBin;
  
  my $Bin = FindBin->Bin;
  my $Script = FindBin->Script;

=head1 Class Variables

=head2 Bin

C<our $Bin : ro string;>

The absolute path of the directory where the program was invoked.

Note:

In Windows, every path separator C<\> in the path is replaced with C</>.

=head2 Script

C<our $Script : ro string;>

The base name of the program name.

=head1 Class Methods

=head2 init

C<static method init : void ();>

Initializes L<$Bin|/"Bin"> and L<$Script|/"Script"> class variables.

This method is called in C<INIT> block of this class.

=head2 again

C<static method again : void ();>

The same as L</"init"> method.

=head1 Repository

L<SPVM::FindBin - Github|https://github.com/yuki-kimoto/SPVM-FindBin>

=head1 See Also

=over 2

=item * L<File::Spec|SPVM::File::Spec>

=item * L<File::Basename|SPVM::File::Basename>

=back

=head2 Porting

C<SPVM::FindBin> is a Perl's L<FindBin> porting to L<SPVM>.

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

