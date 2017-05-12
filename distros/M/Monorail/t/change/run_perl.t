#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::RunPerl;

describe 'An run perl change' => sub {
    it 'produces valid perl' => sub {
        my $sut = Monorail::Change::RunPerl->new(function => sub {
            return 'epcot';
        });
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        is ($new->function->(), 'epcot');
    };

    it 'runs perl on database transform' => sub {
        my $ran = 0;
        my $sut = Monorail::Change::RunPerl->new(function => sub {
            $ran++;
        });

        $sut->transform_database;
        ok($ran);
    }
};

runtests;
