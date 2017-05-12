use strict;
use Test::More;

BEGIN
{
    if (! $ENV{MVALVE_Q4M_DSN} ) {
        plan(skip_all => "Define MVALVE_Q4M_DSN to run this test");
    } else {
        plan(tests => 8);
    }

    use_ok( "Mvalve::Reader" );
    use_ok( "Mvalve::Writer" );
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

    my $reader = Mvalve::Reader->new(
        queue => \%q_config,
        state => { module => "Memory" },
        throttler => {
            args => {
                max_items => 10,
                interval  => 20
            }
        },
    );
    my $writer = Mvalve::Writer->new(queue => \%q_config);

    ok( $writer, "writer ok");
    isa_ok( $writer, "Mvalve::Writer", "writer class ok" );
    ok( $reader, "reader ok");
    isa_ok( $reader, "Mvalve::Reader", "reader class ok" );

    my $message = Mvalve::Message->new(
        headers => {
            'X-Mvalve-Destination' => 'test'
        },
        content => "test"
    );

    $writer->insert( message => $message );

    {
        my $rv = $reader->next();
        ok($rv);
        is( $message->content, $rv->content, "content ok" );
    }
}