package Mojo::InfluxDB::Point;
# ABSTRACT: Data point dynamic container
$Mojo::InfluxDB::Point::VERSION = '0.1';
use Mojo::Base -base, -signatures;
use DateTime;
use DateTime::Format::Strptime;

has [qw/ time_zone fields /];
has time  => sub { die "A point without time is pointless!" };
has at    => sub($self) {
    state $strp = DateTime::Format::Strptime->new( pattern => '%FT%T%Z' );

    my $dt = $strp->parse_datetime( $self->time );
    $dt->set_time_zone( $self->time_zone ) if $self->time_zone;
    $dt;
};

sub inflate($class, $src) {
    my $time = delete $src->{time} || die "A point without time is pointless!";
    my @fields = keys %$src;
    has($_) for @fields;
    $class->new( time => $time, fields => \@fields, %$src );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::InfluxDB::Point - Data point dynamic container

=head1 VERSION

version 0.1

=head1 SYNOPSIS

You won't usually deal with this objects, but get it from L<InfluxDB::Row> or L<InfluxDB::Result> points() methods.

Anyway, given the dynamical nature of this object, if you need to manually contruct one, you need to use the inflate() method:

    use Mojo::InfluxDB::Point;

    my $point = Mojo::InfluxDB::Point->inflate({
        time   => '2020-09-19T07:00:00Z', # required!
        tags   => [qw/ one two seven /],
        status => "SECONDARY"
    });

=head1 DESCRIPTION

This class is a dynamic container of data points coming from L<InfluxDB::Row>. It only requires to have a time and will dinamically create object attributes for the rest of the retrieved columns.

=head1 ATTRIBUTES

=head2 time

this is the string as it comes from InfluxDB and is the only required one.

=head2 time_zone

an optional time zone. See at().

=head2 at

A L<DateTime> object representing the time() on the optionally given time_zone().

=head2 fields

Fields will be filled by inflate() at build time and will contain an array of dynamically added attributes.

=head1 METHODS

=head2 inflate

this is the constructor for this class. Internally it will call new(). This class method handles the "magic" of dinamically detecting fields and adding an attribute for those.

=head1 Methods

=head1 AUTHOR

Gonzalo Radio <gonzalo@gnzl.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gonzalo Radio.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
