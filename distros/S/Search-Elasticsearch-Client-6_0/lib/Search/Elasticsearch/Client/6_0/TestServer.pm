package Search::Elasticsearch::Client::6_0::TestServer;
$Search::Elasticsearch::Client::6_0::TestServer::VERSION = '6.81';
use strict;
use warnings;

#===================================
sub command_line {
#===================================
    my ( $class, $ts, $pid_file, $dir, $transport, $http ) = @_;

    return (
        $ts->es_home . '/bin/elasticsearch',
        '-p',
        $pid_file->filename,
        map {"-E$_"} (
            'path.data=' . $dir,
            'network.host=127.0.0.1',
            'cluster.name=es_test',
            'discovery.zen.ping_timeout=1s',
            'discovery.zen.ping.unicast.hosts=127.0.0.1:' . $ts->es_port,
            'transport.tcp.port=' . $transport,
            'http.port=' . $http,
            @{ $ts->conf }
        )
    );
}

1

# ABSTRACT: Client-specific backend for Search::Elasticsearch::TestServer

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Client::6_0::TestServer - Client-specific backend for Search::Elasticsearch::TestServer

=head1 VERSION

version 6.81

=head1 AUTHOR

Enrico Zimuel <enrico.zimuel@elastic.co>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
