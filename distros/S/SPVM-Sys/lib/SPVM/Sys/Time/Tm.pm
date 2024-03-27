package SPVM::Sys::Time::Tm;

1;

=head1 Name

SPVM::Sys::Time::Tm - struct tm in the C language

=head1 Description

The Sys::Time::Tm class represents L<struct tm|https://linux.die.net/man/3/ctime> in the C language.

=head1 Usage
  
  use Sys::Time::Tm;
  
  my $tm = Sys::Time::Tm->new;
  
  my $sec = $tm->tm_sec;
  $tm->set_tm_sec(12);
  
  my $min = $tm->tm_min;
  $tm->set_tm_min(34);
  
  my $hour = $tm->tm_hour;
  $tm->set_tm_hour(12);
  
  my $mday = $tm->tm_mday;
  $tm->set_tm_mday(4);
  
  my $mon = $tm->tm_mon;
  $tm->set_tm_mon(3);
  
  my $year = $tm->tm_year;
  $tm->set_tm_year(1);
  
  my $wday = $tm->tm_wday;
  $tm->set_tm_wday(12);
  
  my $yday = $tm->tm_yday;
  $tm->set_tm_yday(234);
  
  my $isdst = $tm->tm_isdst;
  $tm->set_tm_isdst(1);

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Time::Tm|SPVM::Sys::Time::Tm> ();>

Creates a new L<Sys::Time::Tm|SPVM::Sys::Time::Tm> object.

  my $tm = Sys::Time::Tm->new;

=head1 Instance Methods

=head2 tm_sec

C<method tm_sec : int ();>

Returns C<tm_sec>.

=head2 set_tm_sec

C<method set_tm_sec : void ($tm_sec : int);>

Sets C<tm_sec>.

=head2 tm_min
  
C<method tm_min : int ();>

Returns C<tm_min>.

=head2 set_tm_min

C<method set_tm_min : void ($tm_min : int);>

Sets C<tm_min>.

=head2 tm_hour

C<method tm_hour : int ();>

Returns C<tm_hour>.

=head2 set_tm_hour

C<method set_tm_hour : void ($tm_hour : int);>

Sets C<tm_hour>.

=head2 tm_mday

C<method tm_mday : int ();>

Returns C<tm_mday>.

=head2 set_tm_mday

C<method set_tm_mday : void ($tm_mday : int);>

Sets C<tm_mday>.

=head2 tm_mon

C<method tm_mon : int ();>

Returns C<tm_mon>.

=head2 set_tm_mon

C<method set_tm_mon : void ($tm_mon : int);>

Sets C<tm_mon>.

=head2 tm_year

C<method tm_year : int ();>

Returns C<tm_year>.

=head2 set_tm_year

C<method set_tm_year : void ($tm_year : int);>

Sets C<tm_year>.

=head2 tm_wday

C<method tm_wday : int ();>

Returns C<tm_wday>.

=head2 set_tm_wday

C<method set_tm_wday : void ($tm_wday : int);>

Sets C<tm_wday>.

=head2 tm_yday

C<method tm_yday : int ();>

Returns C<tm_yday>.

=head2 set_tm_yday

C<method set_tm_yday : void ($tm_yday : int);>

Sets C<tm_yday>.

=head2 tm_isdst

C<method tm_isdst : int ();>

Returns C<tm_isdst>.

=head2 set_tm_isdst

C<method set_tm_isdst : void ($tm_isdst : int);>

Sets C<tm_isdst>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
