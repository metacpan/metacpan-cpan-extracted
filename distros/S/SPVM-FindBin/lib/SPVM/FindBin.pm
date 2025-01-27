package SPVM::FindBin;

our $VERSION = "0.032";

1;

=head1 Name

SPVM::FindBin - The Directory Path Where The Program Is Located

=head1 Description

FindBin class in L<SPVM> has method to get the directory path where the program is located.

Locates the full path to the script bin directory to allow the use of paths relative to the bin directory.

=head1 Usage

  use FindBin;
  
  FindBin->init;
  
  my $Bin = FindBin->Bin;
  my $Script = FindBin->Script;
  my $RealBin = FindBin->RealBin;
  my $RealScript = FindBin->RealScript;

=head1 Class Variables

=head2 Bin

  our $Bin : ro string;

The path to bin directory from where script was invoked.

=head2 Script

  our $Script : ro string;

The basename of script from which perl was invoked

=head2 RealBin

  our $RealBin : ro string;

L</"Bin"> with all links resolved

=head2 RealScript

  our $RealScript : ro string;

L</"Script"> with all links resolved

=head1 Class Methods

=head2 init

  static method init : void ();

Initializes the L<$Bin/"Bin">, L<$Script/"Script">, L<$RealBin/"RealBin">, L<$RealScript/"RealScript"> class variables.

=head2 again

  static method again : void ();

The same as L</"init">.

=head1 Repository

L<SPVM::FindBin - Github|https://github.com/yuki-kimoto/SPVM-FindBin>

=head1 See Also

=head2 FindBin

C<SPVM::FindBin> is the Perl's L<FindBin> porting to L<SPVM>.

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

