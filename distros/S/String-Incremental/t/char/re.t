use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental::Char;

sub new {
    my $ch = String::Incremental::Char->new( @_ );
    return $ch;
}

subtest 'call' => sub {
    my $ch =new( order => 'abcd' );
    ok $ch->can( 're' );
};

subtest 'return' => sub {
    subtest 'alnum' => sub {
        my ($ch, $re);

        $ch = new( order => 'abcxyz' );
        $re = $ch->re();
        isa_ok $re, 'Regexp';
        for my $i ( @{$ch->order} ) {
            my $memo = sprintf '"%s" should be match %s', $i, $re;
            like $i, qr/^${re}$/, $memo;
        }
    };

    subtest 'symbol' => sub {
        my ($ch, $re);

        $ch = new( order => q{!"#$%&'()=~|@`+*;:[]<>/_\\} . '{}' );
        $re = $ch->re();
        isa_ok $re, 'Regexp';
        for my $i ( @{$ch->order} ) {
            my $memo = sprintf '"%s" should be match %s', $i, $re;
            like $i, qr/^${re}$/, $memo;
        }
    };
};

done_testing;

