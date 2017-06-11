use strict;
use warnings;

use Test::More;
use Test::Moose::More;

my $called = 0;

{
    package Y;
    use Moose;
    sub whee { }
}
{
    package Z;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    has foo => (
        is  => 'ro',
        isa => 'Y',

        handles => {

            our_accessor => sub {
                my $self = shift @_;

                Test::More::pass 'in our_accessor()';
                Test::More::isa_ok $_, 'Moose::Meta::Attribute';
                Test::More::isa_ok $self, 'Z';

                $called++;

                return 6;
            },

            whee => 'whee',
        },
    );
}

validate_class Z => (

    attributes => [ qw{ foo } ],
    methods    => [ qw{ foo our_accessor whee } ],
);

my $tc = Z->new(foo => Y->new());

isa_ok($tc, 'Z');

isa_ok $tc->foo => 'Y';
is $tc->our_accessor, 6, 'our_accessor() is 6';
ok $called => 'custom accessor called';

done_testing;
