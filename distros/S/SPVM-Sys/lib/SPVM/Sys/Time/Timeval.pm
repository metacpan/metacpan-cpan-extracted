package SPVM::Sys::Time::Timeval;

1;

=head1 Name

SPVM::Sys::Time::Timeval - struct timeval in C language

=head1 Usage
  
  use Sys::Time::Timeval;
  
  my $tv = Sys::Time::Timeval->new;
  
  my $tv_sec = $tv->tv_sec;
  $tv->set_tv_sec(12);
  
  my $tv_usec = $tv->tv_usec;
  $tv->set_tv_usec(34);

=head1 Description

C<Sys::Time::Timeval> represents C<struct timeval> in C<C language>.

See L<gettimeofday(2) - Linux man page|https://linux.die.net/man/2/gettimeofday> about C<struct timeval> in Linux.

=head1 Class Methods

=head2 new

  static method new : Sys::Time::Timeval ()

Creates a new C<Sys::Time::Timeval> object.

  my $tv = Sys::Time::Timeval->new;

=head1 Instance Methods

=head2 tv_sec

  method tv_sec : long ()

Gets C<tv_sec>.

  my $tv_sec = $tv->tv_sec;

=head2 set_tv_sec

  method set_tv_sec : void ($tv_sec : long)

Sets C<tv_sec>.

  $tv->set_tv_sec(12);

=head2 tv_usec
  
  method tv_usec : long ()

Gets C<tv_usec>.

  my $tv_usec = $tv->tv_usec;

=head2 set_tv_usec

  method set_tv_usec : void ($tv_usec : long)

Sets C<tv_usec>.

  $tv->set_tv_usec(34);
