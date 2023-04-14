package SPVM::Sys::IO::Utimbuf;

1;

=head1 Name

SPVM::Sys::IO::Utimbuf - struct utimbuf in C language

=head1 Usage

  use Sys::IO::Utimbuf;
  
  my $utimbuf = Sys::IO::Utimbuf->new;
  
  my $actime = $utimbuf->actime;
  my $modtime = $utimbuf->modtime;

  $utimbuf->set_actime($actime);
  $utimbuf->set_modtime($modtime);

=head1 Description

C<Sys::IO::Utimbuf> is the class for the C<struct utimbuf> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Class Methods

=head2 new

  static method new : Sys::IO::Utimbuf ();

Create a new C<Sys::IO::Utimbuf> object.

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

The destructor.

=head2 actime

  method actime : long ();

Get C<actime>.

=head2 set_actime

  method set_actime : long ($actime : long);

Set C<actime>.

=head2 modtime

  method modtime : long ();

Get C<modtime>.

=head2 set_modtime

  method set_modtime : long ($modtime : long);

Set C<modtime>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

