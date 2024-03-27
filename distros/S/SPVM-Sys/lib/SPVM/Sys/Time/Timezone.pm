package SPVM::Sys::Time::Timezone;

1;

=head1 Name

SPVM::Sys::Time::Timezone - struct timezone in the C language

=head1 Description

The Sys::Time::Timezone class in L<SPVM> represents L<struct timezone|https://linux.die.net/man/2/gettimeofday> in the C language.

=head1 Usage
  
  use Sys::Time::Timezone;
  
  my $tz = Sys::Time::Timezone->new;
  
  my $tz_minuteswest = $tz->tz_minuteswest;
  $tz->set_tz_minuteswest(12);
  
  my $tz_dsttime = $tz->tz_dsttime;
  $tz->set_tz_dsttime(34);

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Time::Timezone|SPVM::Sys::Time::Timezone> ();>

Creates a new L<Sys::Time::Timezone|SPVM::Sys::Time::Timezone> object.

=head1 Instance Methods

=head2 tz_minuteswest

C<method tz_minuteswest : int ();>

Returns C<tz_minuteswest>.

=head2 set_tz_minuteswest

C<method set_tz_minuteswest : void ($tz_minuteswest : int);>

Sets C<tz_minuteswest>.

=head2 tz_dsttime
  
C<method tz_dsttime : int ();>

Returns C<tz_dsttime>.

=head2 set_tz_dsttime

C<method set_tz_dsttime : void ($tz_dsttime : int);>

Sets C<tz_dsttime>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

