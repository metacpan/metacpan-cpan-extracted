package Template::Plugin::Date::FriendlyDelta;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.02';

use base qw( Template::Plugin::Filter );
 
use DateTime;
use Date::Parse;

sub init {
    my $self = shift;
     
    $self->{ _DYNAMIC } = 1;
    $self->install_filter('friendlydelta');
     
    return $self;
}
 
sub filter {
    my ($self, $date2, $args) = @_;
     
    my $date1 = DateTime->now();

    # Default strings
    my $format_text = {
		month => {
			1  => 'January',
			2  => 'February',
			3  => 'March',
			4  => 'April',
			5  => 'May',
			6  => 'June',
			7  => 'July',
			8  => 'August',
			9  => 'September',
			10  => 'October',
			11  => 'November',
			12  => 'December'
		},
		unit => {
			m   => 'minute',
			h   => 'hour',
			d   => 'day',
		},
		return_format      => '$quantity $duration ago'
	};

	$format_text = $args->[0] if ($args->[0]);

    # Parse date from string, and get delta
	my $delta       = str2time($date1->datetime()) - str2time($date2);

	my $unit        = 'n';
	my $returnedTxt = '';

	if($delta < 60){
		$delta = 60;
	}
	if ( $delta <= 3600 ) {
		$delta = $delta / 60;
		$unit  = 'm';
	}
	elsif ( $delta <= 86400 ) {
		$delta = ( $delta / 60 ) / 60;
		$unit  = 'h';
	}
	elsif ( $delta <= 259200 ) {
		$delta = ( ( $delta / 60 ) / 60 ) / 24;
		$unit = 'd';
	}

	if ( $unit ne 'n' ) {
		$delta = int( $delta + 0.5 );
	}

    # Regular date output
	if ( $unit eq 'n' ) {
		my ( $ss, $mm, $hh, $day, $month, $year, $zone ) = strptime($date1);
		my ( $ss_2, $mm_2, $hh_2, $day_2, $month_2, $year_2, $zone_2 ) = strptime($date2);

		my $monthName = $format_text->{'month'}->{$month_2 + 1};
		$returnedTxt = '$day $month $year';

		$day_2 = int($day_2);
		my $yearOutput = '';
		if ( $year != $year_2 ) {
			$yearOutput = $year_2 + 1900;
		}
		$returnedTxt =~ s/\$day/$day_2/g;
		$returnedTxt =~ s/\$month/$monthName/g;
		$returnedTxt =~ s/\$year/$yearOutput/g;
	}
    # Human readable date output
	else {
	
		$returnedTxt = $format_text->{'return_format'};

		my $duration = $format_text->{'unit'}->{$unit};

		# Custom plurals?
		if ($args->[1] && $args->[1] == 1) {
			$duration =~ s/\$delta/$delta/g;
		}
		else {
			$duration .= 's' if ($delta == 0 || $delta > 1);
		}

		$returnedTxt =~ s/\$duration/$duration/g;
		$returnedTxt =~ s/\$quantity/$delta/g;
	}

	return ( $returnedTxt );

}
 
__END__

=head1 NAME

Template::Plugin::FriendlyDelta - A Template Toolkit plugin filter to show a human friendly time delta between a supplied date and now

=head1 SYNOPSIS

  In your template:
  [% USE FriendlyDelta %]
  
  [%  '2014-09-09T12:23:07' | friendlydelta %]
    
    or 
    
  [%  '2014-09-09T12:23:07' | friendlydelta($custom_format_hash) %]
 
 


=head1 DESCRIPTION

See above for use in your templates. You can also pass two arguments: a hash to change the display, and a modifier for
when you want to use custom plurals.

Structure of the format / display hash:
my $format_hash = {
	month => {
		1  => 'January',
		2  => 'February',
		3  => 'March',
		4  => 'April',
		5  => 'May',
		6  => 'June',
		7  => 'July',
		8  => 'August',
		9  => 'September',
		10  => 'October',
		11  => 'November',
		12  => 'December'
	},
	unit => {
		m   => 'minute',
		h   => 'hour',
		d   => 'day',
	},
	return_format      => '$quantity $duration ago'
}

If you do your own string replacement for plurals in $format_hash->{'return_format'}, pass 1 after:
[%  '2014-09-09T12:23:07' | friendlydelta($format_hash, 1) %]
 

=head1 AUTHOR

Albert Cornelissen, E<lt>acorn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Albert Cornelissen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
