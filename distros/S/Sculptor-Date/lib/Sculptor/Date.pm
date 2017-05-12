package Sculptor::Date;

use Exporter 'import'; 
@EXPORT_OK = qw(date_to_number number_to_date);

use strict;
use warnings;
use Carp;
use Date::Calc qw/Add_Delta_Days Delta_Days/;

=head1 NAME

Sculptor::Date - Convert Sculptor 4GL dates

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';



=head1 SYNOPSIS

This module converts between ISO dates and Sculptor 4GL day numbers. It has
been tested with dates from Sculptor Release 2.5b.

Sculptor 4GL is a programming language owned by MPD. For more information on
Sculptor, you can visit http://www.sculptor.co.uk/


    use Sculptor::Date qw/date_to_number number_to_date/;

    my $date = '2010-01-30';

    my $day_number = date_to_number($date);

    my $new_date = number_to_date($day_number);


=head1 EXPORT

date_to_number, number_to_date


=head1 FUNCTIONS



=head2 date_to_number

    Converts an ISO 8601 date (YYYY-MM-DD) to a Sculptor day number.

=cut

    sub date_to_number { 

        my $date = shift;
        
        if ( $date =~ /\d\d\d\d-\d\d-\d\d/ ) {

            my ($y,$m,$d) = split /-/, $date;
            my @start = (1970,1,1);
            my $delta = Delta_Days($start[0],$start[1],$start[2],$y,$m,$d);
            my $japfirst = 719163;
            my $dayno = $japfirst + $delta;
            
            return $dayno;
        }

        confess "Malformed date provided to subroutine: [$date].";

    }



=head2 number_to_date

    Converts a Sculptor day number to an ISO date.

=cut

    sub number_to_date {

        my $sculptor_date = shift;
        
        unless ( $sculptor_date =~ m/^\d{1,6}$/ ) {
            croak "Incorrect or implausible day number [$sculptor_date].";
        }
        
        my @start = (1970,1,1);
        my $sculptor_first = 719163;
        my $diff = $sculptor_date - $sculptor_first;
        my @date = Add_Delta_Days(@start,$diff);
        my $date = sprintf("%04d-%02d-%02d", @date);
        
        return $date;

    }



=head1 AUTHOR

Damon Allen Davison, C<< <allolex at cpan.org> >>



=head1 BUGS

Please report any bugs or feature requests to 
C<bug-sculptor-date at rt.cpan.org>, 
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sculptor-Date>.  
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sculptor::Date


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sculptor-Date>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sculptor-Date>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sculptor-Date>

=item * Search CPAN

L<http://search.cpan.org/dist/Sculptor-Date/>

=back



=head1 COPYRIGHT & LICENSE

Copyright 2010 Damon Allen Davison, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Sculptor::Date
