#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/13.format_to_parts.t
##----------------------------------------------------------------------------
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use open ':std' => ':utf8';
    use utf8;
    use Test::More;
};

use strict;
use warnings;
use utf8;

BEGIN
{
    use_ok( 'PersonName::Format::Pattern' )    || BAIL_OUT( 'Unable to load PersonName::Format::Pattern' );
    use_ok( 'PersonName::Format::SimpleName' ) || BAIL_OUT( 'Unable to load PersonName::Format::SimpleName' );
};

my $name = PersonName::Format::SimpleName->new(
    given   => 'Jacques',
    surname => 'Deguest',
);
my $pattern = PersonName::Format::Pattern->new(
    '{title} {given} {given2} {surname}, {credentials}'
);

is_deeply(
    $pattern->format_to_parts( $name ),
    [
        {
            type  => 'given',
            value => 'Jacques',
            field => 'given',
        },
        {
            type  => 'literal',
            value => ' ',
        },
        {
            type  => 'surname',
            value => 'Deguest',
            field => 'surname',
        },
    ],
    'Missing fields are pruned structurally in format_to_parts',
);

my $resolver = sub
{
    my( $modifier, $value ) = @_;
    return( substr( $value, 0, 1 ) )
        if( $modifier eq 'initial' );
    return( $value );
};

$pattern = PersonName::Format::Pattern->new(
    '{given-initial}. ({given2}) {surname}'
);

is_deeply(
    $pattern->format_to_parts(
        PersonName::Format::SimpleName->new(
            given   => 'Foo',
            surname => 'Baz',
        ),
        modifier_resolver => $resolver,
    ),
    [
        {
            type      => 'given-initial',
            value     => 'F',
            field     => 'given',
            modifiers => ['initial'],
        },
        {
            type  => 'literal',
            value => '. ',
        },
        {
            type  => 'surname',
            value => 'Baz',
            field => 'surname',
        },
    ],
    'Parts preserve the normative literal coalescing result',
);

done_testing();

__END__
