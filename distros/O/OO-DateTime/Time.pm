package Date::Time::UnixTime;

# Some methods dealing with Unix timestamps are to be implemented here.

1;

package Date::Time;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require AutoLoader;

@ISA = qw(AutoLoader);
$VERSION = '0.01';

sub new {
    # Class identification:
    my $object_or_class = shift; my $class = ref($object_or_class) || $object_or_class;
    my $self={}; bless $self, $class;

    
}


1;
__END__

=head1 NAME

Date::Time - Lightweight normalised datetime data type

=head1 SYNOPSIS

This is just some suggestions, as nothing is implemented yet.  I'm
open to critisism.  Anyway I don't know if the original name will fit
this module with all my plans....

  use Date::Time;

  my $date=Date::Time->new();

  # Set date
  $date->set; # Set to current time
  $date->set(time-60); # Set to 'one minute ago'

  my $greg=Date::Time::Gregorian->new();
  $greg->parse(source=>'Fri Mar  3 01:20:54 CET 2000');
  $greg->parse(source=>'one month ago', format=>'unknown');
  $greg->set(localtime, {timezone=>'local'});
  $greg->set(gmtime);
  
  my $db_time=new Date::Time::MySQLTimeStamp;
  $db_time->set(200003031859);

  # Output date and date elements
  print $db_time->Gregorian->as_string;
  print $db_time->Gregorian->year;
  print $db_time->Gregorian->strftime('%A');

  # The month operator here will return a Date::Gregorian::Month object.
  print $db_time->Gregorian->month->as_string(LANG=>'en');
  print $db_time->Julian->as_string;
  print $db_time->Maya->as_string;

  my $rel_time=$greg->diff($date);
  # Will print something like "3 hours ago" or "5 weeks ago"
  print $rel_time->Gregorian->as_string;


=head1 DESCRIPTION

See the README as for now.  By the way, I want to be neutral to the
calender system - that's why the SYNOPSIS above looks like it does.
Personally I think Gregorian dates sucks a lot - but I'm living in a
Gregorian world and I'm myself mostly thinking about time in Gregorian
terms anyway.

The same applies to the decimal number system, btw.  I mean, of all
numbers, why on earth did they chose 2*5?  It's really a stupid, ugly
number :) Anyway, I'm always thinking in decimal terms, it's very hard
for me to do calculations in other systems.

=head1 IMPLEMENTATION

I'm intending to write a bit about how I've thought implementing this
one here.  Some thoughts are already in the README.

=head1 SUBCLASSING

I will write a bit on how to do subclassing and how to contribute new
methods here.

=head1 AUTHOR

Tobias Brox <tobix@irctos.org>

All kinds of feedback is welcome - and is probably a prerequisite for
progress on this module.

=cut
