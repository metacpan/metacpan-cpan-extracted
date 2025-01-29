package SPVM::Time::Local;

our $VERSION = '0.112';

1;

=head1 Name

SPVM::Time::Local - Reverse Operations of localtime and gmtime.

=head1 Description

Time::Local class in L<SPVM> has methods to do reverse operations of L<localtime|SPVM::Sys/"localtime"> and L<gmtime|SPVM::Sys/"gmtime"> functions.

=head1 Usage
  
  use Sys;
  use Time::Local;
  
  # timegm
  {
    my $epoch = Sys::Time->time;
    
    my $tm = Sys->gmtime($epoch);
    
    my $epoch_again = Time::Local->timegm($tm);
  }
  
  # timelocal
  {
    my $epoch = Sys::Time->time;
    
    my $tm_local = Sys->localtime($epoch);
    
    my $epoch_again = Time::Local->timelocal($tm_local);
  }
  
=head1 Class Methods

=head2 timelocal

C<static method timelocal : long ($tm : L<Sys::Time::Tm|SPVM::Sys::Time::Tm>);>

Converts a L<Sys::Time::Tm|SPVM::Sys::Time::Tm> object to the epoch time.

This method does the reverse operation of the L<localtime|SPVM::Sys/"localtime"> method in the Sys class.

Exceptions:

$tm must be defined. Otherwise an exception is thrown.

=head2 timegm

C<static method timegm : long ($tm : L<Sys::Time::Tm|SPVM::Sys::Time::Tm>);>

Converts a L<Sys::Time::Tm|SPVM::Sys::Time::Tm> object that is C<UTC> to the epoch time.

This method does the reverse operation of the L<gmtime|SPVM::Sys/"gmtime"> method in the Sys class.

Exceptions:

$tm must be defined. Otherwise an exception is thrown.

=head1 Repository

L<SPVM::Time::Local - Github|https://github.com/yuki-kimoto/SPVM-Time-Local>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

