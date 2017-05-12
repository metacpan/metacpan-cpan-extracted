package Plack::Middleware::Debug::Mongo::Database;

# ABSTRACT: Mongo database debug panel for Plack::Middleware::Debug

use strict;
use warnings;
use parent 'Plack::Middleware::Debug::Base';
use Plack::Util::Accessor qw/connection mongo_client/;
use MongoDB 0.502;
use Plack::Middleware::Debug::Mongo::ServerStatus 'hashwalk';

our $VERSION = '0.03'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

sub prepare_app {
    my ($self) = @_;

    $self->connection->{db_name} = 'admin' unless exists $self->connection->{db_name};
    $self->mongo_client(MongoDB::MongoClient->new($self->connection));
}

sub run {
    my ($self, $env, $panel) = @_;

    $panel->title('Mongo::Database');
    $panel->nav_title($panel->title);

    my $dbh = $self->mongo_client->get_database($self->connection->{db_name});
    my @collections = sort grep { !/\$/ } $dbh->collection_names;

    $panel->nav_subtitle($self->connection->{db_name});
    my $info= {};

    my @elements = (
        'database: ' . $self->connection->{db_name},
    );

    # collection statistics
    foreach (@collections) {
        my $stats = {};
        hashwalk($dbh->run_command({collStats => $_}), $stats, undef);
        push @elements, 'collection: ' . $_;
        $info->{$elements[-1]} = $stats;
    }

    # database statistics
    $info->{$elements[0]} = $dbh->run_command({dbStats => 1});

    return sub {
        $panel->content($self->render_hash($info, [ @elements ]));
    };
}

1; # End of Plack::Middleware::Debug::Mongo::Database

__END__

=pod

=head1 NAME

Plack::Middleware::Debug::Mongo::Database - Mongo database debug panel for Plack::Middleware::Debug

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    # inside your psgi app
    enable 'Debug',
        panels => [
            [ 'Mongo::Database', connection => $options ],
        ];

=head1 DESCRIPTION

Plack::Middleware::Debug::Mongo::Database extends Plack::Middleware::Debug by adding MongoDB database statistics debug panel
such as number of collections and indexes, average size of each document, total database and index size etc. This information
can be obtained by command I<db.stats()> in the mongo shell. See
L<MongoDB Database Statistics Reference|http://docs.mongodb.org/manual/reference/database-statistics/> for details.

Additionally collection's statistics displayed for each collection of the database. It includes number of documents and indexes,
total index and storage size, number of allocated data file regions, average size of an object in collection etc. More
information and detailed description of the result see
L<MongoDB Collection Statistics Reference|http://docs.mongodb.org/manual/reference/collection-statistics/>.

Sample output

    Database: awl_devel

    Key                     Value
    avgObjSize              643.318918918919
    collections             8
    dataSize                476056
    db                      awl_devel
    fileSize                201326592
    indexSize               81760
    indexes                 6
    nsSizeMB                16
    numExtents              11
    objects                 740
    ok                      1
    storageSize             585728

    Collection: inventory

    Key                     Value
    avgObjSize              171.651090342679
    count                   321
    flags                   1
    indexSizes._id_         24528
    lastExtentSize          49152
    nindexes                1
    ns                      awl_devel.inventory
    numExtents              2
    ok                      1
    paddingFactor           1
    size                    55100
    storageSize             61440
    totalIndexSize          24528

    ...

=head1 METHODS

=head2 prepare_app

See L<Plack::Middleware::Debug>

=head2 run

See L<Plack::Middleware::Debug>

=head2 connection

MongoDB connection options. Passed as HASH reference. Default server to connect is B<mongodb://localhost:27017>.
For additional information please consult L<MongoDB::MongoClient> page. Default database name is B<admin>. You should
change it to get fetch statistics of the desired database and its collections.

=head1 EXPORTED FUNCTIONS AND SUBROUTINES

Plack::Middleware::Debug::Mongo::Database doesn't export any functions and subroutines.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Debug-Mongo/issues>

=head1 SEE ALSO

L<Plack::Middleware::Debug>

L<MongoDB::MongoClient>

L<MongoDB Database Statistics Reference|http://docs.mongodb.org/manual/reference/database-statistics/>

L<MongoDB Collection Statistics Reference|http://docs.mongodb.org/manual/reference/collection-statistics/>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
