#!/usr/bin/perl -w

=head1 NAME

config.t

=head1 DESCRIPTION

test Net::Graylog::Client

=head1 AUTHOR

kevin mulholland, moodfarm@cpan.org

=cut

use v5.10;
use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Net::Graylog::Client'); }

# as most people will not have a graylog server to hand, there is not
# much we can test, except that the module compiles and has some of
# the expected methods, esp those that autoload

sub add_data {
    my ( $url, $key ) = @_;
    my $events_created = 0;
    my $du             = Data::UUID->new();
    my $uuid           = $du->create_str();

    my $started = time();
    note("Creating messages with using tag:$uuid and key $key");
    my $graylog = Net::Graylog::Client->new( url => $url );

    foreach my $lvl ( valid_levels() ) {
        my ( $s, $c ) = $graylog->$lvl(
            message  => "a $lvl message with key $key",
            tag      => $uuid,
            counter  => $events_created + 1,
            testmode => 1
        );
        $events_created++ if ($s);
    }
    note( "Creating took " . ( time() - $started ) . "s" );

    return $events_created;
}

# -----------------------------------------------------------------------------
# ready to build the message to send

SKIP: {
    # this is a uniq key for this series of tests
    my $ukey = $$ . "-" . time();

    if ( $ENV{AUTHOR_TESTING} ) {

        subtest 'authors_own' => sub {
            plan tests => 1;    # we need to add some data for the search tests
            my $events_created = add_data( "http://sei:12202/gelf", $ukey );
            ok( $events_created, "Sent $events_created messages" );
        };
    }
    else {
        subtest 'not_author' => sub {
            plan tests => 1;
            my $events_created = add_data( "http://fred.fred.com:12202/gelf", $ukey );
            diag "...$events_created";
            ok( !$events_created, 'Failed to create any events (as expected)' );
        };
    }
}

# -----------------------------------------------------------------------------
# completed all the tests
