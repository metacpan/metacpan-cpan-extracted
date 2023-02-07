package SPVM::Time::Local;

our $VERSION = '0.07';

1;

=head1 Name

SPVM::Time::Local - Reverse Manipulation of localtime and gmtime Functions.

=head1 Description

C<SPVM::Time::Local> is the C<Time::Local> class in L<SPVM> language.

C<Time::Local> provides reverse manipulations of L<localtime|SPVM::Time/"localtime"> and L<gmtime|SPVM::Time/"gmtime"> functions.

=head1 Usage
  
  use Time
  use Time::Local;

  my $epoch = Time->time;
  my $time_info_local = Time->localtime($epoch);
  my $time_info_utc = Time->gmtime($epoch);
  
  # Convert a Time::Info object that is local time to the epoch time
  my $epoch = Time::Local->timelocal($time_info_local);
  
  # Convert a Time::Info object that is UTC to the epoch time
  my $epoch = Time::Local->timegm($time_info_utc);

=head1 Class Methods

=head2 timelocal

  static method timelocal : long ($time_info : Time::Info);

Convert a L<Time::Info|SPVM::Time::Info> object that is local time to the epoch time.

This method is the reverse manipulation of L<localtime|SPVM::Time/"localtime">.

This method is the same as C<timelocal> function of C<Linux>.

  my $epoch = Time::Local->timelocal($time_info_local);

=head2 timegm

  static method timegm : long ($time_info : Time::Info);

Convert a L<Time::Info|SPVM::Time::Info> object that is C<UTC> to the epoch time.

This method is the reverse manipulation of L<gmtime|SPVM::Time/"gmtime">.

This method is the same as C<timegm> function of C<Linux>.

  my $epoch = Time::Local->timegm($time_info_utc);

=head1 Repository

L<SPVM::Time::Local - Github|https://github.com/yuki-kimoto/SPVM-Time-Local>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
