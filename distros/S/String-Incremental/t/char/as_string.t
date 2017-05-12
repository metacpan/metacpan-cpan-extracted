use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental::Char;

sub new {
    my $ch = String::Incremental::Char->new( @_ );
    return $ch;
}

subtest 'basic' => sub {
    my $ch;

    $ch = new( order => 'abcd' );
    is $ch->as_string(), 'a';

    $ch = new( order => [1, 2, 3, 4, 5] );
    is $ch->as_string(), '1';
};

subtest 'overload' => sub {
    my $ch = new( order => 'abcd' );
    is "$ch", 'a';
};

done_testing;

