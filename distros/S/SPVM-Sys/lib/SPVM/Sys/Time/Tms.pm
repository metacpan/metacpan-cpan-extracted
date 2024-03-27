package SPVM::Sys::Time::Tms;

1;

=head1 Name

SPVM::Sys::Time::Tms - struct tms in the C language

=head1 Description

The Sys::Time::Tms class in L<SPVM> represents L<struct tms|https://linux.die.net/man/2/times> in the C language.

=head1 Usage
  
  use Sys::Time::Tms;
  
  my $tms = Sys::Time::Tms->new;

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Time::Tms|SPVM::Sys::Time::Tms> ();>

Creates a new L<Sys::Time::Tms|SPVM::Sys::Time::Tms> object.

  my $tms = Sys::Time::Tms->new;

=head1 Instance Methods

=head2 DESTROY

C<native method DESTROY : void ();>

The destructor.

=head2 tms_utime

C<method tms_utime : long ();>

Returns C<tms_utime>.

=head2 set_tms_utime

C<method set_tms_utime : void ($tms_utime : long);>

Sets C<tms_utime>.

=head2 tms_stime

C<method tms_stime : long ();>

Returns C<tms_stime>.

=head2 set_tms_stime

C<method set_tms_stime : void ($tms_stime : long);>

Sets C<tms_stime>.

=head2 tms_cutime

C<method tms_cutime : long ();>

Returns C<tms_cutime>.

=head2 set_tms_cutime

C<method set_tms_cutime : void ($tms_cutime : long);>

Sets C<tms_cutime>.

=head2 tms_cstime

C<method tms_cstime : long ();>

Returns C<tms_cstime>.

=head2 set_tms_cstime

C<method set_tms_cstime : void ($tms_cstime : long);>

Sets C<tms_cstime>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

