package Template::Plugin::DateTime;
use strict;
use warnings;
use DateTime;
use DateTime::Format::Strptime;
use Template::Plugin;

use vars qw($AUTHORITY $VERSION @ISA);
BEGIN
{
    $VERSION   = '0.06002';
    $AUTHORITY = 'cpan:DMAKI';
    @ISA       = (qw(Template::Plugin));
}

sub new
{
    my $class   = shift;
    my $context = shift;

    my %args = ref($_[0]) eq 'HASH' ? %{$_[0]} : ();

    # boolean args: now, today, last_day_of_month
    foreach my $arg (qw(now today last_day_of_month)){
        if (delete $args{$arg}) {
            return DateTime->$arg(%args);
        }
    }

    # args that require to proxy the parameter: from_epoch, from_object
    if (my $epoch = delete $args{from_epoch}) {
        return DateTime->from_epoch(epoch => $epoch, %args);
    } elsif (my $object = delete $args{from_object}) {
        return DateTime->from_object(object => $object, %args);
    } elsif (my $timestr = delete $args{from_string}) {
		my $pattern = delete $args{pattern} || '%Y-%m-%d %H:%M:%S';
		my $parser = DateTime::Format::Strptime->new( pattern => $pattern, %args);
		my $dt = $parser->parse_datetime($timestr);
		return $dt;
	}

    # none of the above, use regular call to new.
    return DateTime->new(%args);
}

1;

__END__

=head1 NAME

Template::Plugin::DateTime - A Template Plugin To Use DateTime Objects

=head1 SYNOPSIS

  [% USE date = DateTime(year = 2004, month = 4, day = 1) %]

  [% USE date = DateTime(today = 1) %]
  Today is [% date.year %]/[% date.month %]/[% date.day %].
  [% date.add(days => 32) %]
  32 days from today is [% date.year %]/[% date.month %]/[% date.day %].

=head1 DESCRIPTION

The basic idea to use a DateTime plugin is as follows:

  USE date = DateTime(year = 2004, month = 4, day = 1);

-OR-

by passing a pattern to parse a date by string using DateTime::Format::Strptime

	USE date = DateTime(from_string => '2008-05-30 00:00:00', pattern => '%Y-%m-%d %H:%M:%S', time_zone => 'America/New_York');


=head1 METHODS

=head2 new

This is used internally. You won't be using it from your templates.

=head1 CONSTRUCTOR

The constructor is exactly the same as that of Datetime.pm, except you
can pass optional parameters to it to toggle between different underlying
DateTime constructors.

=over 4

=item from_epoch

Creates a Datetime object by calling DateTime::from_epoch(). The value for
the from_epoch parameter must be a number representing UNIX epoch.

  [% epoch = ...  %]
  [% USE date = DateTime(from_epoch = epoch) %]

=item now

Creates a DateTime object by calling DateTime::now().
The value for the c<now> parameter is a boolean value.

  [% USE date = DateTime(now = 1) %]
  [% USE date = Datetime(now = 1, time_zone => 'Asia/Tokyo') %]

=item today

Creates a DateTime object by calling DateTime::today().
The value for the c<today> parameter is a boolean value.

  [% USE date = DateTime(today = 1) %]

=item from_object

Creates a DateTime object by calling DateTime::from_object().
The value for the from_object must be an object implementing the utc_rd_values()
method, as described in DateTime.pm

  [% USE date = DateTime(from_object = other_date) %]

=item last_day_of_month

Creates a DateTime object by calling DateTime::last_day_of_month().
The value for the c<last_day_of_month> parameter is a boolean value,
and C<year> and C<month> parameters must be specified.

  [% USE date = DateTime(last_day_of_month = 1, year = 2004, month = 4 ) %]

=item from_string

Creates a DateTime object by calling DateTime::Format::Strptime
The value for the c<from_string> parameter is a string value,
and C<pattern> parameters is optional and defaults to '%Y-%m-%d %H:%M:%S'. 
See L<DateTime::Format::Strptime> for other optional parameters.

  [% USE date = DateTime(from_string => '2008-05-30 10:00:00', pattern => '%Y-%m-%d %H:%M:%S') %]


=back

=head1 SEE ALSO

L<DateTime>
L<DateTime::Format::Strptime>
L<Template>

=head1 AUTHOR

Copyright (c) 2004-2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
