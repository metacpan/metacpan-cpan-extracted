package Mojo::InfluxDB::Result;
# ABSTRACT: Result container for queries
$Mojo::InfluxDB::Result::VERSION = '0.1';
use Mojo::Base -base, -signatures;
use Mojo::Collection qw/ c /;
use Mojo::InfluxDB::Row;

has src => sub { die "This result is empty" };
has 'time_zone';

for my $field (qw/ series messages error statement_id /) {
    has $field => sub($self){ $self->src->{$field} };
}

has series => sub($self) {
    c( $self->src->{series}->@* )->map(sub{
        Mojo::InfluxDB::Row->new(
            src       => $_,
            time_zone => $self->time_zone
        )
    })
};

sub points ( $self ) {
    $self->series->map(sub{ $_->points })->flatten;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::InfluxDB::Result - Result container for queries

=head1 VERSION

version 0.1

=head1 DESCRIPTION

You will get this objects form L<InfluxDB> query methods. This is a container of query results.

=head1 ATTRIBUTES

=head2 src

this is where L<InfluxDB::Result> will store the raw data retrieved for this row. Most attributes of this class will read from here.

=head2 time_zone

an optional time_zone that will be passed into every L<Mojo::InfluxDB::Point> returned by points().

=head2 names

=head2 tags

=head2 columns

=head2 values

=head2 partial

=head2 points

A L<Mojo::Collection> of L<Mojo::InfluxDB::Point>.

=head1 AUTHOR

Gonzalo Radio <gonzalo@gnzl.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gonzalo Radio.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
