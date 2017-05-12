package Net::Lyskom::Time;
use base qw{Net::Lyskom::Object};
use strict;
use warnings;

use Time::Local;

use strict;
use warnings;

=head1 NAME

Net::Lyskom::Time - object that holds a time value.

=head1 SYNOPSIS

  print scalar localtime($obj->time_t);

=head1 DESCRIPTION

All methods except time_t() and new() are get/set attribute accessors. That
is, they return the attribute's contents if called without an argument and
set the attribute's contents if given an argument. time_t() returns the held
time in seconds since the Unix epoch, and new() creates a new object.

=head2 Methods

=over

=item ->new(seconds => $s, minutes => $m, hours => $h, day => $d, month => $mo, year => $y, day_of_week => $wd, day_of_year => $yd, is_dst => $dst)

All arguments are optional. If not given, they default to the value appropriate
to the current time.

=item ->seconds($s)

=item ->minutes($m)

=item ->hours($h)

=item ->day($d)

=item ->month($mo)

=item ->year($y)

=item ->day_of_week($wd)

=item ->day_of_year($yd)

=item ->is_dst($dst)

=item ->time_t()

=back

=cut

sub new {
    my $s = {};
    my $class = shift;
    my %a = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    $class = ref($class) if ref($class);
    bless $s,$class;

    $s->{seconds}     = exists $a{seconds}     ? $a{seconds}     : $sec;
    $s->{minutes}     = exists $a{minutes}     ? $a{minutes}     : $min;
    $s->{hours}       = exists $a{hours}       ? $a{hours}       : $hour;
    $s->{day}         = exists $a{day}         ? $a{day}         : $mday;
    $s->{month}       = exists $a{month}       ? $a{month}       : $mon;
    $s->{year}        = exists $a{year}        ? $a{year}        : $year;
    $s->{day_of_week} = exists $a{day_of_week} ? $a{day_of_week} : $wday;
    $s->{day_of_year} = exists $a{day_of_year} ? $a{day_of_year} : $yday;
    $s->{is_dst}      = exists $a{is_dst}      ? $a{is_dst}      : $isdst;

    return $s;
}

sub new_from_stream {
    my $s = shift;
    my $arg = $_[0];

    my $res = $s->new(
		      seconds => $arg->[0],
		      minutes => $arg->[1],
		      hours => $arg->[2],
		      day => $arg->[3],
		      month => $arg->[4],
		      year => $arg->[5],
		      day_of_week => $arg->[6],
		      day_of_year => $arg->[7],
		      is_dst => $arg->[8]
		     );
    splice @{$arg},0,9;
    return $res;
}

sub seconds {
    my $s = shift;

    $s->{seconds} = $_[0] if $_[0];
    return $s->{seconds};
}

sub minutes {
    my $s = shift;

    $s->{minutes} = $_[0] if $_[0];
    return $s->{minutes};
}

sub hours {
    my $s = shift;

    $s->{hours} = $_[0] if $_[0];
    return $s->{hours};
}

sub day {
    my $s = shift;

    $s->{day} = $_[0] if $_[0];
    return $s->{day};
}

sub month {
    my $s = shift;

    $s->{month} = $_[0] if $_[0];
    return $s->{month};
}

sub year {
    my $s = shift;

    $s->{year} = $_[0] if $_[0];
    return $s->{year};
}

sub day_of_week {
    my $s = shift;

    $s->{day_of_week} = $_[0] if $_[0];
    return $s->{day_of_week};
}

sub day_of_year {
    my $s = shift;

    $s->{day_of_year} = $_[0] if $_[0];
    return $s->{day_of_year};
}

sub is_dst {
    my $s = shift;

    $s->{is_dst} = $_[0] if $_[0];
    return $s->{is_dst};
}

sub time_t {
    my $s = shift;

    $s->{time_t} = timelocal($s->{seconds},$s->{minutes},$s->{hours},
			     $s->{day},$s->{month},$s->{year})
      unless exists($s->{time_t});

    return $s->{time_t};
}

sub as_string {
    my $s = shift;

    return "Time => { ".scalar(localtime($s->time_t))." }";
}

return 1;
