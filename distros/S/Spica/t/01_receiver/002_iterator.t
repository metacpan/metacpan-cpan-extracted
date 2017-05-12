{
    package MockBasic::Spec;
    use Spica::Spec::Declare;

    client {
        name 'example';
        columns q(id name);
    };
    client {
        name 'custom';
        columns qw(id name);
        receiver 'MockBasic::Receiver::Iterator';
    };

    package MockBasic::Receiver::Iterator;
    use parent qw(Spica::Receiver::Iterator);
}

use Test::More;

use Spica;
use Spica::Receiver::Iterator;

my $spica = Spica->new(
    host => '127.0.0.1',
    spec => 'MockBasic::Spec',
);
my $client = $spica->spec->get_client('example');

subtest 'basic' => sub {
    my $iterator = Spica::Receiver::Iterator->new(
        spica       => $spica,
        row_class   => $spica->spec->get_row_class('example'),
        client      => $client,
        client_name => $client->name,
        data        => [
            +{id => 1, name => 'perl'},
            +{id => 2, name => 'ruby'},
        ],
    );
    isa_ok $iterator => 'Spica::Receiver::Iterator';

    while (my $row = $iterator->next) {
        isa_ok $row => 'MockBasic::Row::Example';
    }

    is $iterator->position => 0;

    my @rows = $iterator->all;
    is @rows => 2;
};

subtest 'non values case' => sub {
    my $iterator = Spica::Receiver::Iterator->new(
        spica       => $spica,
        row_class   => $spica->spec->get_row_class('example'),
        client      => $client,
        client_name => $client->name,
        data        => [
        ],
    );
    isa_ok $iterator => 'Spica::Receiver::Iterator';
    is $iterator->next => undef;
    my @rows = $iterator->all;
    is @rows => 0;
};

done_testing;
