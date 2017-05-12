use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental::String;

sub new {
    my $str = String::Incremental::String->new( @_ );
    return $str;
}

subtest 'args' => sub {
    dies_ok {
        new();
    } 'nothing';

    subtest 'format' => sub {
        dies_ok {
            new( value => 'foo' );
        } 'missing';

        lives_ok {
            new( format => '%04s',  value => 'foo' );
        };
    };

    subtest 'value' => sub {
        my $fmt = '%04s';

        dies_ok {
            new( format => $fmt );
        } 'missing';

        dies_ok {
            new( format => $fmt, value => undef );
        } 'invalid';

        lives_ok {
            new( format => $fmt, value => 'foo' );
        };

        lives_ok {
            new( format => $fmt, value => sub { (localtime)[5] - 100 } );
        };
    };
};

done_testing;

