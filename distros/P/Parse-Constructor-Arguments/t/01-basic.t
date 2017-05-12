use warnings;
use strict;

use Test::More('tests', 7);
use Test::Exception;

BEGIN 
{
    sub Parse::Constructor::Arguments::DEBUG () { 0 }
    use_ok('Parse::Constructor::Arguments') 
}

my $hash1 = Parse::Constructor::Arguments->parse(q| arg1 => [ 'one', 'two', 'three' ], arg2 => 'foo', arg3 => { key1 => 'bar1', key2 => 'bar2'} |);
is_deeply($hash1, { arg1 => [ 'one', 'two', 'three' ], arg2 => 'foo', arg3 => { key1 => 'bar1', key2 => 'bar2'} });

my $hash2 = Parse::Constructor::Arguments->parse(q| arg4 => { blat => [ 'arg', { foo2 => [ 'bing', { yarg => [ 'yarp', { 'key', 'value' } ] } ] } ] } |);
is_deeply($hash2, { arg4 => { blat => [ 'arg', { foo2 => [ 'bing', { yarg => [ 'yarp', { 'key', 'value' } ] } ] } ] } });

dies_ok { Parse::Constructor::Arguments->parse(q| arg5 => { [,[ }},  |) };
dies_ok { Parse::Constructor::Arguments->parse(q| arg6 => ( 'foo' ) |) };

my $hash3 = Parse::Constructor::Arguments->parse(q| 'arg7' => [qw/ one two three /] |);
is_deeply($hash3, { arg7 => [ qw/ one two three/] });

dies_ok { Parse::Constructor::Arguments->parse(q| arg8 => qw/ a b c / |) };
