#!/usr/bin/env perl -w
use strict;
use Test::More;
use Net::Redmine;
use Regexp::Common;
use Regexp::Common::Email::Address;

require 't/net_redmine_test.pl';
my $r = new_net_redmine();

plan tests => 17;

### Prepare a new ticket with multiple histories
my $t = $r->create(
    ticket => {
        subject => __FILE__ . " 1",
        description => __FILE__ . " (description)"
    }
);

$t->subject( $t->subject . " 2" );
$t->save;

$t->subject( $t->subject . " 3" );
$t->note("it is good. " . time);
$t->save;

# diag "Created a new ticket, id = " . $t->id;

### Examine its histories

use Net::Redmine::TicketHistory;

{
    # The 0th history entry has a specially meaning of "ticket creation".
    my $h = Net::Redmine::TicketHistory->new(
        connection => $r->connection,
        id => 0,
        ticket_id => $t->id
    );
    ok($h->can("ticket"));

    my $prop = $h->property_changes;

    is_deeply(
        $prop->{subject},
        {
            from => "",
            to => __FILE__ . " 1",
        }
    );

    like $h->author->email, qr/^$RE{Email}{Address}$/;
}

{
    my $h = Net::Redmine::TicketHistory->new(
        connection => $r->connection,
        id => 1,
        ticket_id => $t->id
    );
    ok($h->can("ticket"));

    my $prop = $h->property_changes;

    is_deeply(
        $prop->{subject},
        {
            from => __FILE__ . " 1",
            to => __FILE__ . " 1 2",
        }
    );

    like $h->author->email, qr/^$RE{Email}{Address}$/;
}

{
    my $h = Net::Redmine::TicketHistory->new(
        connection => $r->connection,
        id => 2,
        ticket_id => $t->id
    );
    ok($h->can("ticket"));

    like $h->note, qr/it is good. \d+/;

    my $prop = $h->property_changes;

    is_deeply(
        $prop->{subject},
        {
            from => __FILE__ . " 1 2",
            to => __FILE__ . " 1 2 3",
        }
    );

    like $h->author->email, qr/^$RE{Email}{Address}$/;
}

{
    my $histories = $t->histories;
    is(0+@$histories, 3, "This ticket has three history entires");

    foreach my $h (@$histories) {
        like($h->author->email, qr/^$RE{Email}{Address}$/, "examine ticket author email");
    }

    # require YAML;
    # die YAML::Dump($histories->[0]);

    is_deeply(
        $histories->[0]->property_changes->{subject},
        {
            from => "",
            to => __FILE__ . " 1",
        }
    );

    is_deeply(
        $histories->[1]->property_changes->{subject},
        {
            from => __FILE__ . " 1",
            to => __FILE__ . " 1 2",
        }
    );

    is_deeply(
        $histories->[2]->property_changes->{subject},
        {
            from => __FILE__ . " 1 2",
            to => __FILE__ . " 1 2 3",
        }
    );
}
