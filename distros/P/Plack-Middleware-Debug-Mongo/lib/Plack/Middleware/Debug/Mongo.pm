package Plack::Middleware::Debug::Mongo;

# ABSTRACT: Extend Plack::Middleware::Debug with MongoDB panels

use strict;
use warnings;

our $VERSION = '0.03'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

1; # End of Plack::Middleware::Debug::Mongo

__END__

=pod

=head1 NAME

Plack::Middleware::Debug::Mongo - Extend Plack::Middleware::Debug with MongoDB panels

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    # inside your psgi app
    use Plack::Builder;

    my $app = sub {[
        200,
        [ 'Content-Type' => 'text/html' ],
        [ '<html><body>OK</body></html>' ]
    ]};

    my $options = { host => 'mongodb://mongo.example.com:29111', db_name => 'sampledb' };

    builder {
        mount '/' => builder {
            enable 'Debug',
                panels => [
                    [ 'Mongo::ServerStatus', connection => $options ],
                    [ 'Mongo::Database', connection => $options ],
                ];
            $app;
        };
    };

=head1 DESCRIPTION

This distribution extends Plack::Middleware::Debug with some MongoDB panels. At the moment, listed below panels are
available.

=head1 PANELS

=head2 Mongo::ServerStatus

Display panel with MongoDB server status information.
See L<Plack::Middleware::Debug::Mongo::ServerStatus> for additional information.

=head2 Mongo::Database

Display panel with MongoDB database and its collections statistics.
See L<Plack::Middleware::Debug::Mongo::Database> for additional information.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Debug-Mongo/issues>

=head1 SEE ALSO

L<Plack::Middleware::Debug::Mongo::ServerStatus>

L<Plack::Middleware::Debug::Mongo::Database>

L<Plack::Middleware::Debug>

L<MongoDB>

L<MongoDB Server Status Reference|http://docs.mongodb.org/manual/reference/server-status/>

L<MongoDB Database Statistics Reference|http://docs.mongodb.org/manual/reference/database-statistics/>

L<MongoDB Collection Statistics Reference|http://docs.mongodb.org/manual/reference/collection-statistics/>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
