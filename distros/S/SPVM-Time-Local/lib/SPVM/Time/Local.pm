package SPVM::Time::Local;

our $VERSION = '0.02';

1;

=head1 NAME

SPVM::Time::Local - Reverse Manipulation of localtime and gmtime Functions.

=head1 SYNOPSYS
  
  use Time
  use Time::Local;

  my $epoch = Time->time;
  my $time_info_local = Time->localtime($epoch);
  my $time_info_utc = Time->gmtime($epoch);
  
  # Convert a Time::Info object that is local time to the epoch time
  my $epoch = Time::Local->timelocal($time_info_local);
  
  # Convert a Time::Info object that is UTC to the epoch time
  my $epoch = Time::Local->timegm($time_info_utc);

=head1 DESCRIPTION

C<Time::Local> provides reverse manipulations of L<localtime|SPVM::Time/"localtime"> and L<gmtime|SPVM::Time/"gmtime"> functions.

=head1 CLASS METHODS

=head2 timelocal

  static method timelocal : long ($time_info : Time::Info)

Convert a L<Time::Info|SPVM::Time::Info> object that is local time to the epoch time.

This method is the reverse manipulation of L<localtime|SPVM::Time/"localtime">.

This method is the same as C<timelocal> function of C<Linux>.

  my $epoch = Time::Local->timelocal($time_info_local);

=head2 timegm

  static method timegm : long ($time_info : Time::Info)

Convert a L<Time::Info|SPVM::Time::Info> object that is C<UTC> to the epoch time.

This method is the reverse manipulation of L<gmtime|SPVM::Time/"gmtime">.

This method is the same as C<timegm> function of C<Linux>.

  my $epoch = Time::Local->timegm($time_info_utc);
