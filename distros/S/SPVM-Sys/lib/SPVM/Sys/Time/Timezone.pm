package SPVM::Sys::Time::Timezone;

1;

=head1 Name

SPVM::Sys::Time::Timezone - struct timezone in C language

=head1 Usage
  
  use Sys::Time::Timezone;
  
  my $tz = Sys::Time::Timezone->new;
  
  my $tz_minuteswest = $tz->tz_minuteswest;
  $tz->set_tz_minuteswest(12);
  
  my $tz_dsttime = $tz->tz_dsttime;
  $tz->set_tz_dsttime(34);

=head1 Description

C<Sys::Time::Timezone> represents C<struct timezone> in C<C language>.

See L<gettimeofday(2) - Linux man page|https://linux.die.net/man/2/gettimeofday> about C<struct timezone> in Linux.

=head1 Class Methods

=head2 new

  static method new : Sys::Time::Timezone ()

Creates a new C<Sys::Time::Timezone> object.

  my $tz = Sys::Time::Timezone->new;

=head1 Instance Methods

=head2 tz_minuteswest

  method tz_minuteswest : int ()

Gets C<tz_minuteswest>.

  my $tz_minuteswest = $tz->tz_minuteswest;

=head2 set_tz_minuteswest

  method set_tz_minuteswest : void ($tz_minuteswest : int)

Sets C<tz_minuteswest>.

  $tz->set_tz_minuteswest(12);

=head2 tz_dsttime
  
  method tz_dsttime : int ()

Gets C<tz_dsttime>.

  my $tz_dsttime = $tz->tz_dsttime;

=head2 set_tz_dsttime

  method set_tz_dsttime : void ($tz_dsttime : int)

Sets C<tz_dsttime>.

  $tz->set_tz_dsttime(34);
