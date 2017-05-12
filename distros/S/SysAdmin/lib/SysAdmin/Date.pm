
package SysAdmin::Date;
use Moose;

extends 'SysAdmin';

our $VERSION = 0.03;

has 'format'      => (isa => 'Str', is => 'rw', default => '%Y-%m-%d %T');
has 'offset'      => (isa => 'Str', is => 'rw', default => '0');

__PACKAGE__->meta->make_immutable;

## User defined format

sub date {
	my ($self) = @_;
	
	my $format = $self->format();
	my $offset = $self->offset();
	
	my $date = SysAdmin::Date::_date($format,$offset);

	return $date;
}

## Today

sub today {
	
	my ($self) = @_;
	
	my $format = '%m-%d-%Y %r';
	my $offset = $self->offset();
	
	my $today = SysAdmin::Date::_date($format,$offset);
	
	return $today;
}

## Today INT

sub today_int {
	
	my ($self) = @_;
	
	my $format = '%Y-%m-%d %T';
	my $offset = $self->offset();
	
	my $today_int = SysAdmin::Date::_date($format,$offset);
	
	return $today_int;
}

## Year

sub year {
	
	my ($self) = @_;
	
	my $format = '%Y';
	my $offset = $self->offset();
	
	my $year = SysAdmin::Date::_date($format,$offset);
	
	return $year;
}

## Month

sub month {
	
	my ($self) = @_;
	
	my $format = '%m';
	my $offset = $self->offset();
	
	my $month = SysAdmin::Date::_date($format,$offset);
	
	return $month;
}

## Day

sub day {
	
	my ($self) = @_;
	
	my $format = '%d';
	my $offset = $self->offset();	
	
	my $day = SysAdmin::Date::_date($format,$offset);
	
	return $day;
}

## Hour

sub hour {
	
	my ($self) = @_;
	
	my $format = '%I';
	my $offset = $self->offset();		
	
	my $hour = SysAdmin::Date::_date($format,$offset);
	
	return $hour;
}

## Hour24

sub hour24 {
	
	my ($self) = @_;
	
	my $format = '%H';
	my $offset = $self->offset();
	
	my $hour24 = SysAdmin::Date::_date($format,$offset);
	
	return $hour24;
}

## Minutes

sub minutes {
	
	my ($self) = @_;
	
	my $format = '%M';
	my $offset = $self->offset();
	
	my $minutes = SysAdmin::Date::_date($format,$offset);
	
	return $minutes;
}

## Seconds

sub seconds {
	
	my ($self) = @_;
	
	my $format = '%M';
	my $offset = $self->offset();
	
	my $seconds = SysAdmin::Date::_date($format,$offset);
	
	return $seconds;
}

## AMPM

sub ampm {
	
	my ($self) = @_;
	
	my $format = '%p';
	my $offset = $self->offset();	
	
	my $ampm = SysAdmin::Date::_date($format,$offset);
	
	return $ampm;
}

## Month Name

sub month_name {
	
	my ($self) = @_;
	
	my $format = '%B';
	my $offset = $self->offset();		
	
	my $month_name = SysAdmin::Date::_date($format,$offset);
	
	return $month_name;
}

## Weekday

sub weekday {
	
	my ($self) = @_;
	
	my $format = '%A';
	my $offset = $self->offset();	
	
	my $weekday = SysAdmin::Date::_date($format,$offset);
	
	return $weekday;
}

## Epoch
sub epoch {
	
	my ($self) = @_;
	
	my $format = '%s';
	my $offset = $self->offset();
	
	my $epoch = SysAdmin::Date::_date($format,$offset);
	
	return $epoch;
}

sub _date {
	my ($format,$offset) = @_;
	
	my $date = POSIX::strftime("$format", localtime(time - $offset));

	return $date;
}

sub clear {
	my $self = shift;
	$self->format(0);
	$self->offset(0);
}

1;
__END__
