package SPVM::Sys::Time::Timeval;

1;

=head1 Name

SPVM::Sys::Time::Timeval - struct timeval in the C language

=head1 Description

Sys::Time::Timeval class in L<SPVM> represents L<struct timeval|https://linux.die.net/man/2/gettimeofday> in the C language.

=head1 Usage
  
  use Sys::Time::Timeval;
  
  my $tv = Sys::Time::Timeval->new;
  
  my $tv = Sys::Time::Timeval->new(5, 100_000);
  
  my $tv_sec = $tv->tv_sec;
  $tv->set_tv_sec(12);
  
  my $tv_usec = $tv->tv_usec;
  $tv->set_tv_usec(34);

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> ($tv_sec : long = 0, $tv_usec : long = 0);>

Creates a new C<Sys::Time::Timeval> object.

=head1 Instance Methods

=head2 tv_sec

C<method tv_sec : long ();>

Returns C<tv_sec>.

=head2 set_tv_sec

C<method set_tv_sec : void ($tv_sec : long);>

Sets C<tv_sec>.

=head2 tv_usec
  
C<method tv_usec : long ();>

Returns C<tv_usec>.

=head2 set_tv_usec

C<method set_tv_usec : void ($tv_usec : long);>

Sets C<tv_usec>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

