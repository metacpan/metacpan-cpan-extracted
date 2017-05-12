use strict;
use Test::More;

BEGIN
{
    eval { require Cache::Memcached };
    if ($@) {
        plan(skip_all => "Cache::Memcached not installed");
    } elsif (! $ENV{MVALVE_Q4M_DSN} ) {
        plan(skip_all => "Define MVALVE_Q4M_DSN to run this test");
    } else {
        plan(tests => 6);
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
        timeout => 1,
        queue => \%q_config,
        throttler => {
            module    => 'Data::Valve',
            args => {
                max_items => 100,
                interval  => 100,
            }
        },
    );
    $reader->clear_all;

    my @messages = (
        Mvalve::Message->new(
            headers => {
                &Mvalve::Const::DESTINATION_HEADER => 'test',
            }
        ),
        Mvalve::Message->new(
            headers => {
                &Mvalve::Const::DESTINATION_HEADER => 'test-timed',
                &Mvalve::Const::DURATION_HEADER => 3,
            }
        ),
        Mvalve::Message->new(
            headers => {
                &Mvalve::Const::DESTINATION_HEADER => 'test',
            }
        ),
        Mvalve::Message->new(
            headers => {
                &Mvalve::Const::DESTINATION_HEADER => 'test-timed',
                &Mvalve::Const::DURATION_HEADER => 3,
            }
        ),
        Mvalve::Message->new(
            headers => {
                &Mvalve::Const::DESTINATION_HEADER => 'test-timed',
                &Mvalve::Const::DURATION_HEADER => 3,
            }
        ),
        Mvalve::Message->new(
            headers => {
                &Mvalve::Const::DESTINATION_HEADER => 'test-timed',
                &Mvalve::Const::DURATION_HEADER => 3,
            }
        ),
    );

    my $start = Time::HiRes::time();
    $writer->insert(message => $_) for @messages;

    my $count = 0;
    my $prev = $start;
    while ( $count < @messages ) {
        my $rv = $reader->next;
        next unless $rv;

        $count++;
        my $dest = $rv->header(&Mvalve::Const::DESTINATION_HEADER);
        next if $dest ne 'test-timed';

        my $end = Time::HiRes::time();

        my $diff = $end - $prev;
        $prev = $end;

        # XXX - the first one usually falls short of our expectations
        if ($count == 3) {
            ok( $diff >= 2.8 && $diff <= 4.0, "waited for $diff to get a result" );
        } else {
            ok( $diff >= 2.8 && $diff <= 3.2, "waited for $diff to get a result" );
        }
    }
}
