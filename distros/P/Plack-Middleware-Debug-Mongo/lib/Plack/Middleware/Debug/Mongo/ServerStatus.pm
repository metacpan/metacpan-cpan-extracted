package Plack::Middleware::Debug::Mongo::ServerStatus;

# ABSTRACT: Server status debug panel for Plack::Middleware::Debug

use strict;
use warnings;
use parent 'Plack::Middleware::Debug::Base';
use Plack::Util::Accessor qw/connection mongo_client/;
use MongoDB 0.502;
use Exporter 'import';

our $VERSION = '0.03'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

our %EXPORT_TAGS = (
    'all' => [ qw(hashwalk) ]
);
our @EXPORT_OK   = (
    @{ $EXPORT_TAGS{'all'} }
);
our @EXPORT      = ();

sub prepare_app {
    my ($self) = @_;

    $self->connection->{db_name} = 'admin' unless exists $self->connection->{db_name};
    $self->mongo_client(MongoDB::MongoClient->new($self->connection));
}

sub run {
    my ($self, $env, $panel) = @_;

    $panel->title('Mongo::ServerStatus');
    $panel->nav_title($panel->title);

    my $status = $self->mongo_client->get_database($self->connection->{db_name})
                                    ->run_command({ serverStatus => 1 });
    $panel->nav_subtitle('Version: ' . $status->{version});
    my $info = {};

    hashwalk($status, $info, undef);

    return sub {
        $panel->content($self->render_hash($info));
    };
}

#
# flatten hash
sub hashwalk {
    my ($status, $info, $prefix) = @_;

    foreach my $key (keys %$status) {
        my $t_ref    = ref($status->{$key});
        my $t_prefix = $prefix ? join('.' => $prefix, $key) : $key;

        if ($t_ref eq 'HASH') {
            # next level
            hashwalk($status->{$key}, $info, $t_prefix);
        }
        elsif ($t_ref eq 'DateTime') {
            # convert DateTime
            $info->{$t_prefix} = $status->{$key}->datetime;
        }
        elsif ($t_ref eq 'boolean') {
            # convert boolean
            $info->{$t_prefix} = "$status->{$key}" ? 'true' : 'false';
        }
        else {
            $info->{$t_prefix} = $status->{$key};
        }
    }
}

1; # End of Plack::Middleware::Debug::Mongo::ServerStatus

__END__

=pod

=head1 NAME

Plack::Middleware::Debug::Mongo::ServerStatus - Server status debug panel for Plack::Middleware::Debug

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    # inside your psgi app
    enable 'Debug',
        panels => [
            [ 'Mongo::ServerStatus', connection => $options ],
        ];

=head1 DESCRIPTION

Plack::Middleware::Debug::Mongo::ServerStatus extends Plack::Middleware::Debug by adding MongoDB server status debug panel.
Panel displays data which available through the I<db.serverStatus()> command issued in mongo CLI. Before displaying info some
tweaks were processed such as flatten several complex structures.

Sample output

    localTime                   2013-02-28T10:00:42
    mem.bits                    64
    mem.mapped                  1056
    mem.mappedWithJournal       2112
    mem.note                    not all mem info support on this platform
    mem.supported               false
    network.bytesIn             46182
    network.bytesOut            9697590320
    network.numRequests         587
    ok                          1

=head1 METHODS

=head2 prepare_app

See L<Plack::Middleware::Debug>

=head2 run

See L<Plack::Middleware::Debug>

=head2 connection

MongoDB connection options. Passed as HASH reference. Default server to connect is B<mongodb://localhost:27017>.
For additional information please consult L<MongoDB::MongoClient> page.

=head1 EXPORTED FUNCTIONS AND SUBROUTINES

Plack::Middleware::Debug::Mongo::ServerStatus doesn't export any subroutines by default. On request available the
following functions and subroutines.

=head2 hashwalk

Subroutine used to convert multidimensional hash references into simple hash reference. As well it converts DateTime and
boolean objects received from MongoDB into human readable format. The L<Plack::Middleware::Debug::Mongo::Database> uses
this subroutine.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Debug-Mongo/issues>

=head1 SEE ALSO

L<Plack::Middleware::Debug::Mongo::Database>

L<Plack::Middleware::Debug>

L<MongoDB::MongoClient>

L<DateTime>

L<boolean>

L<MongoDB Server Status Reference|http://docs.mongodb.org/manual/reference/server-status/>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
