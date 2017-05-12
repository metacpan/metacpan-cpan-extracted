use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Currency;
    use Moose;
    use MooseX::Types::Locale::Currency qw( CurrencyCode );

    has code  => (
        is => 'ro',
        isa => CurrencyCode,
    );

    __PACKAGE__->meta->make_immutable;
}

my $e = exception { Currency->new({ code => 'FOO' }) };

like $e, qr/Attribute/, 'check error';

done_testing;
