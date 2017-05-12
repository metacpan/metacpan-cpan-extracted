use Test::More;

use Spica;
use Spica::Spec::Declare;
use Spica::Receiver::Row;

{
    package t::Mock::Name;

    sub new {
        my ($class, %args) = @_;
        return bless \%args => $class;
    }

    sub value { shift->{name}; }

    package t::Mock::Birth;

    sub new {
        my ($class, %args) = @_;
        return bless \%args => $class;
    }

    sub value { shift->{value}; }
}

my $spica = Spica->new(
    host => 'localhost',
    spec => spec {
        client {
            name 'default';
            columns qw(id name birth_year birth_month friend_birth);
            inflate 'name' => sub {
                my $value = shift;
                return t::Mock::Name->new(name => $value);
            };
            inflate qr{^birth} => sub {
                my $value = shift;
                return t::Mock::Birth->new(value => $value);
            };
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
            id => 1,
            name => 'perl',
            birth_year  => 2013,
            birth_month => 1,
            friend_birth => '2013-10-10',
        },
    );
    
    isa_ok $row->name => 't::Mock::Name';
    is $row->name->value => 'perl';
    isa_ok $row->birth_year => 't::Mock::Birth';
    is $row->birth_year->value => 2013;
    isa_ok $row->birth_month => 't::Mock::Birth';
    is $row->birth_month->value => 1;

    is $row->friend_birth => '2013-10-10';
};

done_testing;
