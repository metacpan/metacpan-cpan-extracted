package SPVM::Time::Seconds;



1;

=head1 Name

SPVM::Time::Seconds - Seconds

=head1 Description

The Time::Seconds class in L<SPVM> has methods to manipulate seconds to calculate dates and times.

=head1 Usage

  use Time::Piece;
  use Time::Seconds;
  
  my $tp = Time::Piece->localtime;
  $tp = $tp->add(Time::Seconds->ONE_DAY);
  
  my $tp2 = Time::Piece->localtime;
  my $tsec = $tp->subtract_tp($tp2);
  
  say "Difference is: " . $tsec->days;

=head1 Details

The class makes the assumption that there are 24 hours in a day, 7 days in a week, 365.24225 days in a year and 12 months in a year.

=head1 Interfaces

=over 2

=item L<Cloneable|SPVM::Cloneable>

=back

=head1 Fields

=head2 seconds

C<has seconds : ro long;>

Seconds.

=head1 Class Methods

=head2 new

C<static method new : L<Time::Seconds|SPVM::Time::Seconds> ($second : long = 0);>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object given seconds $second, and returns it.

=head2 ONE_MINUTE

C<static method ONE_MINUTE : L<Time::Seconds|SPVM::Time::Seconds> ();>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object given the seconds correspond to 1 minute, and returns it.

=head2 ONE_HOUR

C<static method ONE_HOUR : L<Time::Seconds|SPVM::Time::Seconds> ();>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object given the seconds correspond to 1 hour, and returns it.

=head2 ONE_DAY

C<static method ONE_DAY : L<Time::Seconds|SPVM::Time::Seconds> ();>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object given the seconds correspond to 1 day, and returns it.

=head2 ONE_WEEK

C<static method ONE_WEEK : L<Time::Seconds|SPVM::Time::Seconds> ();>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object given the seconds correspond to 1 week, and returns it.

=head2 ONE_MONTH

C<static method ONE_MONTH : L<Time::Seconds|SPVM::Time::Seconds> ();>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object given the seconds correspond to 1 month, and returns it.

=head2 ONE_YEAR

C<static method ONE_YEAR : L<Time::Seconds|SPVM::Time::Seconds> ();>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object given the seconds correspond to 1 year, and returns it.

=head2 ONE_FINANCIAL_MONTH

C<static method ONE_FINANCIAL_MONTH : L<Time::Seconds|SPVM::Time::Seconds> ();>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object given the seconds correspond to 1 financial day, and returns it.

=head2 LEAP_YEAR

C<static method LEAP_YEAR : L<Time::Seconds|SPVM::Time::Seconds> ();>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object given the seconds correspond to 1 year that is a leap year, and returns it.

=head2 NON_LEAP_YEAR

C<static method NON_LEAP_YEAR : L<Time::Seconds|SPVM::Time::Seconds> ();>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object given the seconds correspond to 1 year that is not a leap year, and returns it.

=head1 Instance Methods

=head2 add

C<method add : Time::Seconds ($seconds : long);>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object with seconds $seconds added to the current seconds, and returns it.

=head2 subtract

C<method subtract : Time::Seconds ($seconds : long);>

Creates a new L<Time::Seconds|SPVM::Time::Seconds> object with seconds $seconds subtracted from the current seconds, and returns it.

=head2 minutes

C<method minutes : double ();>

Calculates the minutes, and returns it.

=head2 hours

C<method hours : double ();>

Calculates the hours, and returns it.

=head2 days

C<method days : double ();>

Calculates the days, and returns it.

=head2 weeks

C<method weeks : double ();>

Calculates the weeks, and returns it.

=head2 months

C<method months : double ();>

Calculates the months, and returns it.

=head2 financial_months

C<method financial_months : double ();>

Calculates the financial months, and returns it.

=head2 years

C<method years : double ();>

Calculates the financial years, and returns it.

=head2 clone

C<method clone : L<Time::Seconds|SPVM::Time::Seconds> ();>

Clones this instance and returns it.

=head2 pretty

C<method pretty : string ();>

Interprets L</"seconds"> as a delta and returns an English expression.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

