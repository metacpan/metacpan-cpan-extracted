use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{ package Local::Dummy1; use Test::Requires 'Moo'; use Test::Requires 'MooX::Tag::TO_HASH'; };

{
    package P1;
    use Moo;
    BEGIN {
        # load prior to Sub::HandlesVia;
        with 'MooX::Tag::TO_HASH';
    }
    use Sub::HandlesVia;
    use Types::Standard qw( ArrayRef Str );

    has cows => (
        is      => 'ro',
        to_hash => 1,
        isa     => ArrayRef [Str],
        default => sub { [] },
        handles_via => 'Array',
        handles => {
            add_cow  => 'push',
            find_cow => 'grep'
        }
    );

}

package P2 {

    use Moo;
    BEGIN {
        # load prior to Sub::HandlesVia;
        with 'MooX::Tag::TO_HASH';
    }

    use Types::Standard qw( ArrayRef Str );
    use Sub::HandlesVia;

    extends 'P1';

    has ducks => (
        is      => 'ro',
        to_hash => 1,
        isa     => ArrayRef [Str],
        default => sub { [] },
        handles_via => 'Array',
        handles => {
            add_duck  => 'push',
            find_duck => 'grep'
        }
    );


}

my $p1 = P1->new;
is_deeply( $p1->TO_HASH, { cows => [] }, "!Moo" );
$p1->add_cow( 'bessie' );
is_deeply( $p1->TO_HASH, { cows => [ 'bessie'] }, "Moo++" );

my $p2 = P2->new;
is_deeply( $p2->TO_HASH, { cows => [], ducks => [] }, "!Moo, !Quacks" );
$p2->add_cow('bessie');
is_deeply( $p2->TO_HASH, { cows => ['bessie'], ducks => [] }, "Moo++, !Quacks" );
$p2->add_duck('donald');
is_deeply( $p2->TO_HASH, { cows => ['bessie'], ducks => ['donald'] }, "Moo++, Quacks++" );

done_testing;
