#!/usr/bin/env perl

package main v0.1.0;

use Pcore;
use Pcore::API::Whois;

sub CLI ($self) {
    return {
        opt => { debug => { desc => 'debug whois query', }, },
        arg => [
            domain => {
                isa => 'Str',
                min => 1,
                max => 1,
            },
        ],
    };
}

my $w = Pcore::API::Whois->new;

my $res = $w->search( $ENV->cli->{arg}->{domain} );

if ( $ENV->cli->{opt}->{debug} ) {
    say $res->content ? $res->content->$* : 'NO CONTENT';

    if ( $res->server ) {
        say 'SERVER: ' . $res->server->host;
        say 'SERVER NOT FOUND RE: ' . ( $res->server->notfound_re // 'not defined' );
        say 'SERVER EXCEED RE: ' .    ( $res->server->exceed_re   // 'not defined' );
        say 'SERVER QUERY: ' . dump $res->server->query;
    }

    say 'REQUEST DOMAIN: ' . $ENV->cli->{arg}->{domain};
    say 'REQUEST QUERY: ' . $res->query;

    say join q[ - ], $res->status, $res->reason;
}
else {
    say $res->content ? $res->content->$* : 'NO CONTENT';

    say join q[ - ], $res->status, $res->reason;
}

1;
__END__
=pod

=encoding utf8

=cut
