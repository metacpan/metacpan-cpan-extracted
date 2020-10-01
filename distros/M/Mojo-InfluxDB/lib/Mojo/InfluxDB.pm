package Mojo::InfluxDB;
# ABSTRACT: Super simple InfluxDB async cappable client with a nice interface
$Mojo::InfluxDB::VERSION = '0.1';
use Mojo::Base -base, -signatures;
use Mojo::Collection qw/ c /;
use Mojo::UserAgent;

use Mojo::InfluxDB::Result;

has host     => 'localhost';
has port     => 8086;
has database => sub { die "database ir required" };

has ua   => sub { Mojo::UserAgent->new };
has url  => sub ( $self ) {
    Mojo::URL->new( sprintf( 'http://%s:%s', $self->host, $self->port ) );
};

has time_zone => undef;

sub query ( $self, $query ) {
    my ($results, $error);

    $self->query_p( $query )->then(sub {
        $results = shift
    })->catch( sub {
        $error = shift
    })->wait;

    die $error if $error;
    $results;
}

sub query_p ( $self, $query ) {
    $self->raw_query_p( $query )->then(sub($tx){
        c($tx->res->json('/results')->@*)->map(sub($src){
            Mojo::InfluxDB::Result->new(
                time_zone => $self->time_zone,
                src       => $src
            );
        });
    });
}

sub raw_query_p ( $self, $query ) {
    $query = join( ';', @$query ) if $query eq 'ARRAY';
    $self->ua->get_p(
        $self->_url('query')->query({ q => $query, db => $self->database })
    );
}

sub _url ( $self, $action ) {
    $self->url->path("/$action")->clone
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::InfluxDB - Super simple InfluxDB async cappable client with a nice interface

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use Mojo::InfluxDB;

    my $client = Mojo::InfluxDB->new( database => 'telegraf' );

    my $result = $client->query('
        SELECT last(state) AS state
        FROM telegraf.thirty_days.mongodb
        WHERE time > now() - 5h
        GROUP BY time(1h), host
    ');

    $result->first->points;

=head1 DESCRIPTION

We needed to do some async queries on our company InfluxDB instance and with some time this module has been growing. As it's useful for Us, it might also be useful for others so here I am releasing it.

This is not yet a full implementation of an InfluxDB driver. I will be very happy to accept contributions and to modify anything about this group of classes, so be warned that this is "beta" quality and the interface will change if it's needed to implement new features or if me or someone else found a nicer way.

=head1 ATTRIBUTES

=head2 host

Host of your InfluxDB instance: 'localhost' by default.

=head2 port

Port of your InfluxDB instance: 8086 by default.

=head2 database

The name of the database you want this client to send the queries. You can change it at any time.

=head2 time_zone

An optional time_zone to be passed into results which will finally allow L<InfluxDB::Point> to build L<DateTime> objects on your requested time_zone.

=head1 METHODS

=head2 query

will run queries synchronously. See query_p().

=head2 query_p

will run queries asynchronously and return a promise to get a L<Mojo::Collection> of L<Mojo::InfluxDB::Result> objects.

=head2 raw_query_p

will run a query and return a L<Mojo::Transaction::HTTP>.

=head1 BUGS

As in any piece of software there might be bugs around.
If you found one, please report it at the github repo:

L<https://github.com/gonzalo-radio/mojo-influxdb>

Pull requests to fix bugs or add functionality are very welcomed, but please include
an explanation of what you want to achieve.

=head1 TODO

=for :list * Implement writing functionality so we can have real tests

=head1 SEE ALSO

=for :list * L<InfluxDB>
* L<InfluxDB::Writer>
* L<AnyEvent::InfluxDB>
* L<InfluxDB::Client::Simple>

=head1 AUTHOR

Gonzalo Radio <gonzalo@gnzl.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gonzalo Radio.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
