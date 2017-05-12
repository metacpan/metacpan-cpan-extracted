use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental::String;

sub new {
    my $ch = String::Incremental::String->new( @_ );
    return $ch;
}

subtest 'call' => sub {
    my $ch =new( format => '%s', value => 'foo' );
    ok $ch->can( 're' );
};

subtest 'return' => sub {
    subtest 'Str' => sub {
        my ($s, $re);

        $s = new( format => '%s', value => 'foobar' );
        $re = $s->re();
        isa_ok $re, 'Regexp';
        like 'foobar', $re;
        unlike 'foo', $re;

        $s = new( format => '%04d', value => '12' );
        $re = $s->re();
        isa_ok $re, 'Regexp';
        like '0012', $re;
        unlike '12', $re;
    };

    # temporary
    subtest 'CodeRef' => sub {
        my ($s, $re);

        $s = new( format => '%s', value => sub { 'foo' } );
        $re = $s->re();
        is $re, qr/.*?/;
    };
};

done_testing;

