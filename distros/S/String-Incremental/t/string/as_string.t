use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental::String;
use Time::Piece ();

sub new {
    my $ch = String::Incremental::String->new( @_ );
    return $ch;
}

my $yyyy = Time::Piece::localtime->year;

my %args1 = (
    format => '%s',
    value  => 'foobar',
);

my %args2 = (
    format => '%04d',
    value  => sub { (localtime)[5] - 100 },
);

subtest 'basic' => sub {
    subtest 'value is-a Str' => sub {
        my $str = new( %args1 );
        is $str->as_string(), 'foobar';
    };

    subtest 'value is-a CodeRef' => sub {
        my ($y) = $yyyy =~ /(\d{2})$/;
        my $str = new( %args2 );
        is $str->as_string(), '0014';
    };
};

subtest 'overload' => sub {
    subtest 'value is-a Str' => sub {
        my $str = new( %args1 );
        is "$str", 'foobar';
    };

    subtest 'value is-a CodeRef' => sub {
        my ($y) = $yyyy =~ /(\d{2})$/;
        my $str = new( %args2 );
        is "$str", '0014';
    };
};

done_testing;

