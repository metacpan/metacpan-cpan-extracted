package SPVM::Sys::Time::Itimerval;

1;

=head1 Name

SPVM::Sys::Time::Itimerval - struct itimerval in the C language

=head1 Usage

  use Sys::Time::Itimerval;
  
  my $tv = Sys::Time::Itimerval->new;
  
  my $it_interval = $tv->it_interval;
  $tv->set_it_interval(12);
  
  my $it_value = $tv->it_value;
  $tv->set_it_value(34);

=head1 Description

The Sys::Time::Itimerval class represents L<struct itimerval|https://linux.die.net/man/2/setitimer> in the C language.

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Time::Itimerval|SPVM::Sys::Time::Itimerval> ();>

Creates a new L<Sys::Time::Itimerval|SPVM::Sys::Time::Itimerval> object.

=head1 Instance Methods

=head2 it_interval

C<method it_interval : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> ();>

Copies C<it_interval> and creates a L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> object whose pointer is set to the copied value address, and returns it.

=head2 set_it_interval

C<method set_it_interval : void ($it_interval : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>);>

Sets C<it_interval>.

=head2 it_value
  
C<method it_value : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> ();>

Copies C<it_value> and creates a L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> object whose pointer is set to the copied value address, and returns it.

=head2 set_it_value

C<method set_it_value : void ($it_value : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>);>

Sets C<it_value>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

