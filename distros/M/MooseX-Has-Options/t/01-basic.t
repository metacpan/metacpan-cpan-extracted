use strict;
use warnings;

use Test::Most;

{
    package TestOptions;

    use Moose;
    use MooseX::Has::Options;
    use namespace::autoclean;

    has 'plain_attribute' =>
    (
        qw(:ro :required),
        isa => 'Str',
    );

    has 'attribute_with_options' =>
    (
        qw(:ro :lazy_build),
        isa => 'Str'
    );

    sub _build_attribute_with_options
    {
        return 'SomeRandomValue';
    }
}

my $to = TestOptions->new( plain_attribute => 'Plain');

is( $to->plain_attribute,        'Plain',           'accessing' );
is( $to->attribute_with_options, 'SomeRandomValue', 'lazy'      );

dies_ok { $to->plain_attribute('Something')                      } 'read only';
dies_ok { my $to_required = TestOptions->new                     } 'required';
dies_ok { my $to_str = TestOptions->new( plain_attribute => [] ) } 'constraint';

done_testing();
