use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental::FormatParser;

sub f {
    return String::Incremental::FormatParser::_parse_format( @_ );
}

subtest 'args' => sub {
    dies_ok {
        f();
    } 'missing';
};

subtest 'return' => sub {
    {
        my $p = f( 'foobar' );
        is_deeply $p, +{
            format     => 'foobar',
            item_count => 0,
            items      => [],
        };
    }

    {
        #           +1   +1     +1   +1   +1    +1
        my $p = f( '%sfoo%dbar%04sbaz%%%4.2fhoge%c' );
        is_deeply $p, +{
            format     => '%sfoo%dbar%04sbaz%%%4.2fhoge%c',
            item_count => 6,
            items => [
                { type => 'String', format => '%s',    pos => 0 },
                { type => 'String', format => '%d',    pos => 1 },
                { type => 'String', format => '%04s',  pos => 2 },
                { type => 'String', format => '%%',    pos => undef },
                { type => 'String', format => '%4.2f', pos => 3 },
                { type => 'String', format => '%c',    pos => 4 },
            ],
        };
    }

    {
        #           +1    +3    +2
        my $p = f( '%=foo%3=bar%2=baz' );
        is_deeply $p, +{
            format     => '%sfoo%s%s%sbar%s%sbaz',
            item_count => 6,
            items => [
                { type => 'Char', pos => 0 },
                { type => 'Char', pos => 1 },
                { type => 'Char', pos => 1 },
                { type => 'Char', pos => 1 },
                { type => 'Char', pos => 2 },
                { type => 'Char', pos => 2 },
            ],
        };
    }

    {
        #           +1    +2  +1+1
        my $p = f( '%dfoo%2=%04s%%bar' );
        is_deeply $p, +{
            format     => '%dfoo%s%s%04s%%bar',
            item_count => 5,
            items => [
                { type => 'String', format => '%d', pos => 0 },
                { type => 'Char', pos => 1 },
                { type => 'Char', pos => 1 },
                { type => 'String', format => '%04s', pos => 2 },
                { type => 'String', format => '%%', pos => undef },
            ],
        };
    }
};

done_testing;
