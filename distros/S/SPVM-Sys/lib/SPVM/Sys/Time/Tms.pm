package SPVM::Sys::Time::Tms;

1;

=head1 Name

SPVM::Sys::Time::Tms - struct tms in C language

=head1 Usage
  
  use Sys::Time::Tms;
  
  my $tv = Sys::Time::Tms->new;
  
  my $tv_sec = $tv->tv_sec;
  $tv->set_tv_sec(12);
  
  my $tv_nsec = $tv->tv_nsec;
  $tv->set_tv_nsec(34);

=head1 Description

C<Sys::Time::Tms> represents C<struct tms> in C<C language>.

See L<times(2) - Linux man page|https://linux.die.net/man/2/times> about C<struct tms> in Linux.

=head1 Class Methods

=head2 new

  static method new : Sys::Time::Tms ()

Creates a new C<Sys::Time::Tms> object.

  my $tv = Sys::Time::Tms->new;

=head1 Instance Methods

=head2 DESTROY

  native method DESTROY : void ();

The destructor.

=head2 tms_utime

  method tms_utime : long ()

Gets C<tms_utime>.

  my $tms_utime = $tv->tms_utime;

=head2 set_tms_utime

  method set_tms_utime : void ($tms_utime : long)

Sets C<tms_utime>.

  $tv->set_tms_utime(12);

=head2 tms_stime

  method tms_stime : long ()

Gets C<tms_stime>.

  my $tms_stime = $tv->tms_stime;

=head2 set_tms_stime

  method set_tms_stime : void ($tms_stime : long)

Sets C<tms_stime>.

  $tv->set_tms_stime(12);

=head2 tms_cutime

  method tms_cutime : long ()

Gets C<tms_cutime>.

  my $tms_cutime = $tv->tms_cutime;

=head2 set_tms_cutime

  method set_tms_cutime : void ($tms_cutime : long)

Sets C<tms_cutime>.

  $tv->set_tms_cutime(12);

=head2 tms_cstime

  method tms_cstime : long ()

Gets C<tms_cstime>.

  my $tms_cstime = $tv->tms_cstime;

=head2 set_tms_cstime

  method set_tms_cstime : void ($tms_cstime : long)

Sets C<tms_cstime>.

  $tv->set_tms_cstime(12);

