#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $user = $db->add(
    'user',
    username      => 'test',
    user_id       => 123,
    user_password => 'test',
);

my @sessions = (
    {
        data => {
            session_id      => 12345,
            user_id         => $user->user_id,
            session_started => 12456,
        },
        should_remain => 0,
    },
    {
        data => {
            session_id      => 12346,
            user_id         => $user->user_id,
            session_started => 124567,
        },
        should_remain => 0,
    },
    {
        data => {
            session_id      => 12347,
            user_id         => $user->user_id,
            session_started => time,
        },
        should_remain => 1,
    },
    {
        data => {
            session_id      => 12348,
            user_id         => $user->user_id,
            session_started => time - ($db->session_expires - 2),
        },
        should_remain => 1,
    },
);

_check_sessions();

for my $session ( @sessions ) {
    $db->dbh->db->insert(
        'corbac_user_sessions' => $session->{data}
    );
}

_check_sessions( map{ $_->{data}->{session_id} }@sessions );
$db->clear_sessions;
_check_sessions( map{ $_->{data}->{session_id} }grep{ $_->{should_remain} }@sessions );

unlink $file, $file . '-shm', $file . '-wal';

done_testing;

sub _check_sessions {
    my %session_ids = map{ $_ => 1 }@_;

    my %found_sessions;
    my $iter = $db->dbh->db->select( 'corbac_user_sessions', ['session_id'] );
    while ( my $next = $iter->hash ) {
        $found_sessions{ $next->{session_id} } = 1;
    }

    is_deeply \%session_ids, \%found_sessions;
}