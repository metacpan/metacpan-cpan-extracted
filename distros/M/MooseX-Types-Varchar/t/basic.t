use strict;
use warnings;
use Test::More;
{
    package MyClass;
    use Moose;
    use MooseX::Types::Varchar qw/ Varchar /;

    has 'attr1' => (is => 'rw', required => 1, isa => Varchar[20]);
    no Moose;
}

eval {
        my $obj = MyClass->new( attr1 => 'This is over twenty characters long.' );
};
ok $@, 'Got exception';
like($@, qr/Validation failed for/);
like( $@, qr/This is over twenty characters long/,
    'check Varchar[20] is respected');
like( $@, qr/MooseX::Types::Varchar\[20\]/,
    'type parameter passed to message');

eval {
        my $obj = MyClass->new( attr1 => q{This isn't.} );
};
ok(!$@, 'short-enough string')
    or diag $@;

eval {
        my $obj = MyClass->new( attr1 => '' );
};
ok(!$@, 'empty string');

done_testing;
