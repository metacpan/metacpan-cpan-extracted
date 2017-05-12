package Net::Google::Code::DateTime;
use Any::Moose;
extends 'DateTime';

our %MONMAP = (
    Jan => 1,
    Feb => 2,
    Mar => 3,
    Apr => 4,
    May => 5,
    Jun => 6,
    Jul => 7,
    Aug => 8,
    Sep => 9,
    Oct => 10,
    Nov => 11,
    Dec => 12,
);

sub new_from_string {
    my $class     = shift;
    my $base_date = shift;
    if (
        $base_date =~ /\w{3}\s+(\w+)\s+(\d+)\s+(\d\d):(\d\d):(\d\d)\s+(\d{4})/ )
    {
        # Tue Jan  6 19:17:39 2009
        my $mon = $1;
        my $dom = $2;
        my $h   = $3;
        my $m   = $4;
        my $s   = $5;
        my $y   = $6;
        my $date = $class->new(
            year      => $y,
            month     => $MONMAP{$mon},
            day       => $dom,
            hour      => $h,
            minute    => $m,
            second    => $s,
            time_zone => 'US/Pacific',    # google's time zone
        );
        $date->set_time_zone( 'UTC' );
        return $date;
    }
    elsif ( $base_date =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/ )
    {

        #    2009-06-01T13:00:10Z
        return $class->new(
            year      => $1,
            month     => $2,
            day       => $3,
            hour      => $4,
            minute    => $5,
            second    => $6,
            time_zone => 'UTC',
        );
    }
}

no Any::Moose;

1;

__END__

=head1 NAME

Net::Google::Code::DateTime - DateTime with a parsing method for gcode

=head1 DESCRIPTION

=head1 INTERFACE

=head2 new_from_string

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


