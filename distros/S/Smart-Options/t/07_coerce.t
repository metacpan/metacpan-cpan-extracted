use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Smart::Options;

subtest 'type check Multiple' => sub {
    my $opt = Smart::Options->new();
    $opt->type( foo => 'Multiple' );

    $opt->coerce(
        Multiple => 'ArrayRef',
        sub { [ split( qr{,}, ref($_[0]) eq 'ARRAY' ? join( q{,}, @{ $_[0] } ) : $_[0] ) ] }
    );

    is_deeply $opt->parse('--foo=a,b,c')->{foo}, [qw/a b c/];
    is_deeply $opt->parse('--foo=a,b,c','--foo=d')->{foo}, [qw/a b c d/];
};


done_testing;

