#!perl

use Test::Spec;
use Test::Deep;

{
    package My::Sut;

    use Moose;

    has name => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has table => (
        is       => 'ro',
        isa      => 'Str',
        required => 0,
    );

    has attr => (
        is       => 'ro',
        isa      => 'Str',
        required => 0,
    );

    with 'Monorail::Role::Change';

    sub as_hashref_keys {
        return qw/name table attr/;
    }

    sub transform_schema {
        return;
    }

    sub transform_database {
        return;
    }
}


describe 'The change role' => sub {
    my ($sut);

    it 'requires an as_hashref_keys method' => sub {
        ok(Monorail::Role::Change->meta->requires_method('as_hashref_keys'));
    };

    it 'requires a transform_database method' => sub {
        ok(Monorail::Role::Change->meta->requires_method('transform_database'));
    };

    it 'requires a transform_schema method' => sub {
        ok(Monorail::Role::Change->meta->requires_method('transform_schema'));
    };

    describe 'as_hashref method' => sub {
        it 'returns a hashref representation' => sub {
            $sut = My::Sut->new(name => 'epcot', table => 'mk');
            cmp_deeply($sut->as_hashref, {name => 'epcot', table => 'mk'});
        };

        it 'skips optional attributes that are undef' => sub {
            $sut = My::Sut->new(name => 'epcot');
            cmp_deeply($sut->as_hashref, {name => 'epcot'});
        };
    };

    describe 'as_perl method' => sub {
        it 'retuns the object as a perl string' => sub {
            $sut = My::Sut->new(name => 'epcot');

            my $perl = $sut->as_perl;

            my $new = eval $perl;

            cmp_deeply($new, all(
                isa('My::Sut'),
                methods(name => 'epcot'),
            ));
        };

        it 'returns the keys in table, name, then alpha order' => sub {
            $sut = My::Sut->new(name => 'epcot', table => 'mk', attr => 'dhs');
            my $perl = $sut->as_perl;

            $perl =~ s/^My::Sut->new//;
            my @args = eval $perl;
            cmp_deeply(\@args, [qw/table mk name epcot attr dhs/]);
        };
    };
};

runtests;
