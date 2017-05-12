package Slackware::Slackget::Date;

use warnings;
use strict;
use overload 
	'cmp' => \&compare_ng,
	'<=>' => \&compare_ng,
	'fallback' => 1;

=head1 NAME

Slackware::Slackget::Date - A class to manage date for slack-get.

=head1 VERSION

Version 1.0.1

=cut

our $VERSION = '1.0.1';

=head1 SYNOPSIS

This class is an abstraction of a date. It centralyze all operation you can do on a date (like comparisons)

    use Slackware::Slackget::Date;

    my $date = Slackware::Slackget::Date->new('day-name' => Mon, 'day-number' => 5, 'year' => 2005);
    $date->year ;
    my $status = $date->compare($another_date_object);
    if($date->is_equal($another_date_object))
    {
    	print "Nothing to do : date are the same\n";
    }

=head1 CONSTRUCTOR

=head2 new

The constructor take the followings arguments :

	day-name => the day name in : Mon, Tue, Wed, Thu, Fri, Sat, Sun
	day-number => the day number from 1 to 31. WARNINGS : there is no verification about the date validity !
	month-name  => the month name (Jan, Feb, Apr, etc.)
	month-number => the month number (1 to 12)
	hour => the hour ( a string like : 12:52:00). The separator MUST BE ':'
	year => a chicken name...no it's a joke. The year as integer (ex: 2005).
	use-approximation => in this case the comparisons method just compare the followings : day, month and year. (default: no)

You have to manage by yourself the date validity, because this class doesn't check the date validity. The main reason of this, is that this class is use to compare the date of specials files. 

So I use the predicate that peoples which make thoses files don't try to do a joke by a false date.

	my $date = Slackware::Slackget::Date->new(
		'day-name' => Mon, 
		'day-number' => 5, 
		'year' => 2005,
		'month-number' => 2,
		'hour' => '12:02:35',
		'use-approximation' => undef
	);

=cut

my %equiv_month = (
	'Non' => 0,
	'Jan' => 1,
	'Feb' => 2,
	'Mar' => 3,
	'Apr' => 4,
	'May' => 5,
	'Jun' => 6,
	'Jul' => 7,
	'Aug' => 8,
	'Sep' => 9,
	'Oct' => 10,
	'Nov' => 11,
	'Dec' => 12,
);

my @equiv_month = ('Non','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');


sub new
{
	my ($class,%args) = @_ ;
	my $self={};
	bless($self,$class);
	$self->{DATE}->{'day-name'} = $args{'day-name'} if(defined($args{'day-name'})) ;
	$self->{DATE}->{'day-number'} = $args{'day-number'} if(defined($args{'day-number'})) ;
	$self->{DATE}->{'month-name'} = $args{'month-name'} if(defined($args{'month-name'})) ;
	$self->{DATE}->{'month-number'} = $args{'month-number'} if(defined($args{'month-number'})) ;
	$self->{DATE}->{'hour'} = $args{'hour'} if(defined($args{'hour'})) ;
	$self->{DATE}->{'year'} = $args{'year'} if(defined($args{'year'})) ;
	$self->{'use-approximation'} = $args{'use-approximation'};
	$self->_fill_undef;
	return $self;
}


=head1 FUNCTIONS

=head2 compare

This mathod compare the current date object with a date object passed as parameter.

	my $status = $date->compare($another_date);

The returned status is :

	0 : $another_date is equal to $date
	1 : $date is greater than $another_date
	2 : $date is lesser than $another_date

=cut

sub compare {
	my ($self,$date) = @_;
	return undef if(ref($date) ne 'Slackware::Slackget::Date') ;
	if($self->year > $date->year){
		return 1
	}
	elsif($self->year < $date->year){
		return 2
	}
	elsif($self->monthnumber > $date->monthnumber){
		return 1
	}
	elsif($self->monthnumber < $date->monthnumber){
		return 2
	}
	elsif($self->daynumber > $date->daynumber){
		return 1
	}
	elsif($self->daynumber < $date->daynumber){
		return 2
	}
	elsif(!$self->{'use-approximation'}){
		return 0 unless($self->hour);
		return 0 unless($date->hour);
		my @hour_self = $self->hour =~ /^(\d+):(\d+):(\d+)$/g ;
		my @hour_date = $date->hour =~ /^(\d+):(\d+):(\d+)$/g ;
		if($hour_self[0] > $hour_date[0])
		{
			return 1;
		}
		elsif($hour_self[0] < $hour_date[0])
		{
			return 2;
		}
		elsif($hour_self[1] > $hour_date[1])
		{
			return 1;
		}
		elsif($hour_self[1] < $hour_date[1])
		{
			return 2;
		}
		elsif($hour_self[2] > $hour_date[2])
		{
			return 1;
		}
		elsif($hour_self[2] < $hour_date[2])
		{
			return 2;
		}
		
	}
	return 0;
}

=head2 compare_ng

This method behave exactly the same way than compare() but is compliant with '<=>' and 'cmp' Perl operators.

Instead of returning 2 if left operand is lesser than the right one, it return -1.

The purpose of not modifying compare() directly is the backward compatibility.

=cut

sub compare_ng {
	my $r = compare(@_);
	return -1 if($r == 2);
	return $r;
}

=head2 is_equal

Take another date object as parameter and return TRUE (1) if this two date object are equal (if compare() return 0), and else return false (0).

	if($date->is_equal($another_date)){
		...do something...
	}

WARNING : this method also return undef if $another_date is not a Slackware::Slackget::Date object, so be carefull.

=cut

sub is_equal {
	my ($self,$date) = @_;
	return undef if(ref($date) ne 'Slackware::Slackget::Date') ;
	if($self->compare($date) == 0){
		return 1;
	}
	else{
		return 0;
	}
}

=head2 _fill_undef [PRIVATE]

This method is call by the constructor to resolve the month equivalence (name/number).

This method affect 0 to all undefined numerical values.

=cut

sub _fill_undef {
	my $self = shift;
	unless(defined($self->{DATE}->{'month-number'})){
		if(defined($self->{DATE}->{'month-name'}) && exists($equiv_month{$self->{DATE}->{'month-name'}}))
		{
			$self->{DATE}->{'month-number'} = $equiv_month{$self->{DATE}->{'month-name'}};
		}
		else{
			$self->{DATE}->{'month-number'} = 0;
		}
	}
	unless(defined($self->{DATE}->{'month-name'})){
		if(defined($self->{DATE}->{'month-number'}) && defined($equiv_month[$self->{DATE}->{'month-number'}]))
		{
			$self->{DATE}->{'month-name'} = $equiv_month[$self->{DATE}->{'month-number'}];
		}
		else{
			$self->{DATE}->{'month-name'} = 'Non';
		}
	}
	$self->{DATE}->{'day-number'} = 0 unless(defined($self->{DATE}->{'day-number'}));
	$self->{DATE}->{'year'} = 0 unless(defined($self->{DATE}->{'year'}));
}

=head2 today

This method fill the Slackware::Slackget::Date object with the today parameters. This method fill the followings object value : day-number, year, month-number, 

	$date->today ;
	print "Today date is ",$date->to_string,"\n";

=cut

sub today
{
	my $self = shift;
	my $date_format = '%d/%m/%Y::%H:%M:%S';
	my $date = `date +$date_format`;
	my ($date_tmp,$hour) = split(/::/,$date);
	my ($d,$m,$y) = split(/\//, $date_tmp);
	$self->{DATE}->{'day-number'} = $d;
	$self->{DATE}->{'month-number'} = $m;
	$self->{DATE}->{'year'} = $y;
	$self->{DATE}->{'hour'} = $hour;
}

=head2 to_xml

return the date as an XML encoded string.

	$xml = $date->to_xml();

=cut

sub to_xml
{
	my $self = shift;
	my $xml = "<date ";
	foreach (keys(%{$self->{DATE}})){
		$xml .= "$_=\"$self->{DATE}->{$_}\" " if(defined($self->{DATE}->{$_}));
	}
	$xml .= "/>\n";
	return $xml;
}

=head2 to_XML (deprecated)

same as to_xml() provided for backward compatibility.

=cut

sub to_XML {
	return to_xml(@_);
}


=head2 to_html

return the date as an HTML encoded string.

	$xml = $date->to_html();

=cut

sub to_html
{
	my $self = shift;
	my $xml = "<strong>Date :</strong> $self->{DATE}->{'day-number'}/$self->{DATE}->{'month-number'}/$self->{DATE}->{'year'} $self->{DATE}->{'hour'}<br/>\n";
# 	foreach (keys(%{$self->{DATE}})){
# 		$xml .= "<strong>$_ :</strong> $self->{DATE}->{$_}<br/>" if(defined($self->{DATE}->{$_}));
# 	}
# 	$xml .= "</p>\n";
	return $xml;
}

=head2 to_HTML (deprecated)

same as to_html() provided for backward compatibility.

=cut

sub to_HTML {
	return to_html(@_);
}

=head2 to_string

return the date as a plain text string.

	print "Date of the package is ", $package->date()->to_string,"\n";

=cut

sub to_string
{
	my $self = shift;
	return "$self->{DATE}->{'day-number'}/$self->{DATE}->{'month-number'}/$self->{DATE}->{'year'} $self->{DATE}->{'hour'}";
}

=head1 ACCESSORS

=cut

=head2 year

return the year

	my $string = $date->year;

=cut

sub year {
	my $self = shift;
	return $self->{DATE}->{'year'};
}

=head2 monthname

return the monthname

	my $string = $date->monthname;

=cut

sub monthname {
	my $self = shift;
	return $self->{DATE}->{'month-name'};
}

=head2 dayname

return the 'day-name'

	my $string = $date->'day-name';

=cut

sub dayname {
	my $self = shift;
	return $self->{DATE}->{'day-name'};
}

=head2 hour

return the hour

	my $string = $date->hour;

=cut

sub hour {
	my $self = shift;
	return $self->{DATE}->{'hour'};
}

=head2 daynumber

return the daynumber

	my $string = $date->daynumber;

=cut

sub daynumber {
	my $self = shift;
	return $self->{DATE}->{'day-number'};
}

=head2 monthnumber

return the monthnumber

	my $string = $date->monthnumber;

=cut

sub monthnumber {
	my $self = shift;
	return $self->{DATE}->{'month-number'};
}

=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis@infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Slackware-Slackget@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Slackware-Slackget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Slackware::Slackget


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org/category/slack-get>

=item * slack-get specific website

L<http://slackget.infinityperl.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Slackware-Slackget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Slackware-Slackget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Slackware-Slackget>

=item * Search CPAN

L<http://search.cpan.org/dist/Slackware-Slackget>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Bertrand Dupuis (yes my brother) for his contribution to the documentation.

=head1 SEE ALSO

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Slackware::Slackget::Date
