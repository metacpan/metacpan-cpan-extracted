
use strict;
use warnings;

use Test::More;
use Test::XML;
use File::Slurp;

my @tests = (
    {   name => 'client.list request',
        in   => {
            _method  => 'client.list',
            email    => 'janedoe@freshbooks.com',
            username => 'janedoe',
            page     => 1,
            per_page => 15,
        },
        out => read_file( 't/test_data/client.list.req.xml' ) . '',
    },

    {   name => 'nested request',
        in   => {
            _method => 'test.test',
            foo     => 'bar',
            nesteds => [              #
                { baz => 'bundy1' },    #
                { baz => 'bundy2' },
            ],
        },
        out => read_file( 't/test_data/nested.req.xml' ) . '',
    },

    {   name => 'client.create request',
        in   => {
            _method => 'client.create',
            client  => {
                first_name   => 'Jane',
                last_name    => 'Doe',
                organization => 'ABC Corp',
                email        => 'janedoe@freshbooks.com',
                username     => 'janedoe',
                password     => 'seCret!7',
                work_phone   => '(555) 123-4567',
                home_phone   => '(555) 234-5678',
                p_street1    => '123 Fake St.',
                p_street2    => 'Unit 555',
                p_city       => 'New York',
                p_state      => 'New York',
                p_country    => 'United States',
                p_code       => '553132',
            }
        },
        out => read_file( 't/test_data/client.create.req.xml' ) . '',
    },

);

plan tests => 1 + @tests;

my $class = 'Net::FreshBooks::API::Client';
use_ok $class;

foreach my $test ( @tests ) {
    my $xml = $class->parameters_to_request_xml( $test->{in} );
    is_xml( $xml, $test->{out}, $test->{name} )
        || die;
}
