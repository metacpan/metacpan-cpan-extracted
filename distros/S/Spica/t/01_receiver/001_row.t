use Test::More;

use Spica;
use Spica::Spec::Declare;
use Spica::Receiver::Row;

my $spica = Spica->new(
    host => 'localhost',
    spec => spec {
        client {
            name 'default';
            columns qw(id name);
        };
    },
);
my $client = $spica->spec->get_client('default');

subtest 'basic' => sub {
    my $row = $spica->spec->get_row_class('default')->new(
        spica       => $spica,
        client      => $client,
        client_name => $client->name,
        data        => +{
            id => 1, name => 'perl',
        },
    );
    
    isa_ok $row => 'Spica::Receiver::Row';
    can_ok $row => qw(id name);

    is $row->id   => 1;
    is $row->name => 'perl';

    is_deeply $row->get_columns => +{
        id   => 1,
        name => 'perl',
    };
};

done_testing;
