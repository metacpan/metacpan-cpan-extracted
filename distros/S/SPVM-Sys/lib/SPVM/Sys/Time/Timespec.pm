package SPVM::Sys::Time::Timespec;

1;

=head1 Name

SPVM::Sys::Time::Timespec - struct timespec in C language

=head1 Usage
  
  use Sys::Time::Timespec;
  
  my $tv = Sys::Time::Timespec->new;
  
  my $tv_sec = $tv->tv_sec;
  $tv->set_tv_sec(12);
  
  my $tv_nsec = $tv->tv_nsec;
  $tv->set_tv_nsec(34);

=head1 Description

C<Sys::Time::Timespec> represents C<struct timespec> in C<C language>.

See L<gettimeofday(2) - Linux man page|https://linux.die.net/man/2/gettimeofday> about C<struct timespec> in Linux.

=head1 Class Methods

=head2 new

  static method new : Sys::Time::Timespec ()

Creates a new C<Sys::Time::Timespec> object.

  my $tv = Sys::Time::Timespec->new;

=head1 Instance Methods

=head2 DESTROY

  native method DESTROY : void ();

The destructor.

=head2 tv_sec

  method tv_sec : long ()

Gets C<tv_sec>.

  my $tv_sec = $tv->tv_sec;

=head2 set_tv_sec

  method set_tv_sec : void ($tv_sec : long)

Sets C<tv_sec>.

  $tv->set_tv_sec(12);

=head2 tv_nsec
  
  method tv_nsec : long ()

Gets C<tv_nsec>.

  my $tv_nsec = $tv->tv_nsec;

=head2 set_tv_nsec

  method set_tv_nsec : void ($tv_nsec : long)

Sets C<tv_nsec>.

  $tv->set_tv_nsec(34);
