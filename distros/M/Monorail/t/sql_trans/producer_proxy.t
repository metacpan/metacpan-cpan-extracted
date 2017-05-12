#!perl

use Test::Spec;
use Monorail::SQLTrans::ProducerProxy;

describe 'A Monorail ProducerProxy object' => sub {
    my ($sut);
    before each => sub {
        $sut = Monorail::SQLTrans::ProducerProxy->new;
    };

    it 'loads the default sql producer on demand' => sub {
        $sut->producer_class;

        ok($INC{'SQL/Translator/Producer/PostgreSQL.pm'});
    };

    it 'loads another producer if you ask it to' => sub {
        my $sut = Monorail::SQLTrans::ProducerProxy->new(db_type => 'MySQL');
        $sut->producer_class;
        ok($INC{'SQL/Translator/Producer/MySQL.pm'});
    };

    my @methods = qw/add_field create_table drop_field drop_table alter_field
    alter_create_constraint alter_drop_constraint alter_create_index/;

    foreach my $method (@methods) {
        describe "$method method" => sub {
            it "calls $method on the producer" => sub {
                my $called = SQL::Translator::Producer::PostgreSQL->expects($method)->once;

                $sut->$method;
                ok($called->verify);
            };

            it 'passes arguments' => sub {
                my $called = SQL::Translator::Producer::PostgreSQL->expects($method)->with('epcot');
                $sut->$method('We pass a string here cause Test::Spec only understands methods...', 'epcot');
                ok($called->verify);
            };
        };
    }


};

runtests;
