package SPVM::Sys::Time::Timespec;

1;

=head1 Name

SPVM::Sys::Time::Timespec - struct timespec in the C language

=head1 Description

Sys::Time::Timespec class in L<SPVM> represents L<struct timespec|https://linux.die.net/man/2/clock_gettime> in the C language.

=head1 Usage
  
  use Sys::Time::Timespec;
  
  my $ts = Sys::Time::Timespec->new;
  
  my $ts = Sys::Time::Timespec->new(5, 300_000_000);
  
  my $ts_sec = $ts->tv_sec;
  $ts->set_tv_sec(12);
  
  my $ts_nsec = $ts->tv_nsec;
  $ts->set_tv_nsec(34);

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec> ($tv_sec : long = 0, $tv_nsec : long = 0);>

Creates a new L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec> object.

=head1 Instance Methods

=head2 DESTROY

C<native method DESTROY : void ();>

The destructor.

=head2 tv_sec

C<method tv_sec : long ()>

Returns C<tv_sec>.

=head2 set_tv_sec

C<method set_tv_sec : void ($ts_sec : long);>

Sets C<tv_sec>.

=head2 tv_nsec
  
C<method tv_nsec : long ()>

Returns C<tv_nsec>.

=head2 set_tv_nsec

C<method set_tv_nsec : void ($ts_nsec : long);>

Sets C<tv_nsec>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

