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

my $meta = TestOptions->new( plain_attribute => 'Plain')->meta;
my $plain_attribute        = $meta->get_attribute('plain_attribute');
my $attribute_with_options = $meta->get_attribute('attribute_with_options');

ok( !$plain_attribute->has_write_method,    'meta read only'  );
ok( $plain_attribute->is_required,          'meta required'   );
ok( $attribute_with_options->is_lazy_build, 'meta lazy build' );

done_testing();
