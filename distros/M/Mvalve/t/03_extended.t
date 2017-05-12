use strict;
use Test::More;

my $messages;
BEGIN
{
    eval { require Cache::Memcached };
    if ($@) {
        plan(skip_all => "Cache::Memcached not installed");
    } elsif (! $ENV{MVALVE_Q4M_DSN} ) {
        plan(skip_all => "Define MVALVE_Q4M_DSN to run this test");
    } else {
        $messages = $ENV{MVALVE_MESSAGE_COUNT} || 32;
        plan(tests => 3 + 3 * $messages);
    }

    $ENV{MEMCACHED_SERVERS} ||= '127.0.0.1:11211';
    $ENV{MEMCACHED_NAMESPACE} ||= join('_', __FILE__, $$, {}, rand());
    $ENV{MEMCACHED_SERVERS} = [
        split(/\s*,\s*/, $ENV{MEMCACHED_SERVERS}) ];

    use_ok("Mvalve::Reader");
    use_ok("Mvalve::Writer");
}

{
    my %q_config = (
        args => {
            connect_info => [ 
                $ENV{MVALVE_Q4M_DSN},
                $ENV{MVALVE_Q4M_USERNAME},
                $ENV{MVALVE_Q4M_PASSWORD},
                { RaiseError => 1, AutoCommit => 1 },
            ]
        }
    );

    my $writer = Mvalve::Writer->new( queue => \%q_config );
    my $reader = Mvalve::Reader->new(
        timeout   => 1,
        throttler => {
            module    => 'Data::Valve',
            args => {
                max_items => 1,
                interval  => 1.4,
            }
        },
        state => {
            module => 'Memcached',
            args   => {
                memcached => {
                    servers => $ENV{MEMCACHED_SERVERS},
                    namespace => $ENV{MEMCACHED_NAMESPACE},
                }
            }
        },
        queue => \%q_config
    );
    $reader->clear_all;

    my $count = $messages;
    diag( "Generating $count messages...." );
    my %messages;
    for my $i (1..$count) {
        my $message = Mvalve::Message->new(
            headers => {
                'X-Mvalve-Destination' => 'test'
            },
            content => $i,
        );
        ok( $writer->insert( message => $message ), "insert data $i");
        $messages{ $message->id } = $message;
    }

    {
        my $message = $reader->next;
        ok( $message, 'first message should not be throttled' );
        if ($message) {
            delete $messages{ $message->id };
        }

        $count--;
        for my $i (1..$count) {
            my $message = $reader->next;
            ok( ! $message, "subsequent messages should be throttled" );
        }
    }

    diag("Going to receive messages as they are being throttled. This may take a few moments...");

    {
        my $i = 0;
        while ($i < $count) {
            my $message = $reader->next;
            next unless $message;

            ok( delete $messages{ $message->id }, "Deleting a proper (unhandled) message");
            $i++;
            
        }
        is( $i, $count, "count matches" );
        is (keys %messages, 0, "consumed all messages");
    }
}
