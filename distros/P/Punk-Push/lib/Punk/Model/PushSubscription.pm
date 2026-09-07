package Punk::Model::PushSubscription;

use 5.010;
use strict;
use warnings;
use Punk::Model;

our $VERSION = '0.02';

table 'push_subscriptions';

field id       => { type => 'integer', primary => 1 };
field user_id  => { type => 'integer' };
field endpoint => { type => 'string' };
field p256dh   => { type => 'string' };
field auth     => { type => 'string' };
field user_agent   => { type => 'string' };
field created_at   => { type => 'integer' };  # epoch
field last_seen_at => { type => 'integer' };  # epoch, refreshed on re-subscribe
field last_status  => { type => 'integer' };  # what the push service last said

1;

__END__

=head1 NAME

Punk::Model::PushSubscription - the subscriptions table

=head1 DESCRIPTION

Shipped so an application does not have to declare a model to use
L<Punk::Plugin::Push>. Declare your own under the same name and the plugin
uses yours instead.

The DDL, for an application that manages its schema by hand:

    CREATE TABLE push_subscriptions (
        id           SERIAL PRIMARY KEY,
        user_id      BIGINT NOT NULL,
        endpoint     TEXT NOT NULL UNIQUE,
        p256dh       TEXT NOT NULL,
        auth         TEXT NOT NULL,
        user_agent   TEXT,
        created_at   BIGINT NOT NULL,
        last_seen_at BIGINT,
        last_status  INTEGER
    );
    CREATE INDEX push_subscriptions_user ON push_subscriptions (user_id);

C<endpoint> is unique and that is load-bearing: a browser re-subscribing
produces the same endpoint, and without the constraint every re-subscribe adds
a row and a single send fans out across the duplicates.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
