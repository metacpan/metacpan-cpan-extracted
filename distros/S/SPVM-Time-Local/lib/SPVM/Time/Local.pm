package SPVM::Time::Local;

our $VERSION = '0.10';

1;

=head1 Name

SPVM::Time::Local - Reverse Manipulation of localtime and gmtime Functions.

=head1 Description

The Time::Local class of L<SPVM> has methods for reverse manipulations of L<localtime|SPVM::Sys::Time/"localtime"> and L<gmtime|SPVM::Sys::Time/"gmtime"> functions.

=head1 Usage
  
  use Sys::Time
  use Time::Local;
  
  my $epoch = Sys::Time->time;
  my $time_info_local = Sys::Time->localtime($epoch);
  my $time_info_utc = Sys::Time->gmtime($epoch);
  
  my $epoch = Time::Local->timelocal($time_info_local);
  
  my $epoch = Time::Local->timegm($time_info_utc);

=head1 Class Methods

=head2 timelocal

  static method timelocal : long ($time_info : Sys::Time::Tm);

Converts a L<Sys::Time::Tm|SPVM::Sys::Time::Tm> object that is local time to the epoch time.

This method is the reverse manipulation of L<localtime|SPVM::Sys::Time/"localtime">.

This method is the same as C<timelocal> function of C<Linux>.

  my $epoch = Time::Local->timelocal($time_info_local);

=head2 timegm

  static method timegm : long ($time_info : Sys::Time::Tm);

Converts a L<Sys::Time::Tm|SPVM::Sys::Time::Tm> object that is C<UTC> to the epoch time.

This method is the reverse manipulation of L<gmtime|SPVM::Sys::Time/"gmtime">.

This method is the same as C<timegm> function of C<Linux>.

  my $epoch = Time::Local->timegm($time_info_utc);

=head1 Repository

L<SPVM::Time::Local - Github|https://github.com/yuki-kimoto/SPVM-Time-Local>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

