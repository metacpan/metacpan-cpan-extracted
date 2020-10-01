package Mojo::InfluxDB::Row;
# ABSTRACT: Result row container
$Mojo::InfluxDB::Row::VERSION = '0.1';
use Mojo::Base -base, -signatures;
use Mojo::InfluxDB::Point;
use Mojo::Collection qw/ c /;
use List::MoreUtils qw/ zip /;

has 'time_zone';

has src => sub { die "This result is empty" };

for my $field (qw/ names tags columns values partial /) {
    has $field => sub($self){ $self->src->{$field} };
}

has points => sub($self) {
    c( $self->values->@* )->map(sub {
        Mojo::InfluxDB::Point->inflate(+{
            zip( $self->columns->@*, $_->@* ),
            ( $self->tags ? $self->tags->%* : () )
        });
    })
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::InfluxDB::Row - Result row container

=head1 VERSION

version 0.1

=head1 SYNOPSIS

See L<InfluxDB> and L<InfluxDB::Result>.

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
