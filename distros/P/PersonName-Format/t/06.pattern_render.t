#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/06.pattern_render.t
##----------------------------------------------------------------------------
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use PersonName::Format::Pattern;
    use PersonName::Format::SimpleName;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'PersonName::Format::Pattern' )    || BAIL_OUT( 'Unable to load PersonName::Format::Pattern' );
    use_ok( 'PersonName::Format::SimpleName' ) || BAIL_OUT( 'Unable to load PersonName::Format::SimpleName' );
};

my $initial_resolver = sub
{
    my( $modifier, $value ) = @_;
    return( substr( $value, 0, 1 ) ) if( $modifier eq 'initial' );
    return( uc( $value ) ) if( $modifier eq 'allCaps' );
    return( ucfirst( $value ) ) if( $modifier eq 'initialCap' );
    return( $value );
};

my $name = PersonName::Format::SimpleName->new(
    given   => 'Foo',
    surname => 'Baz',
);

my $pattern = PersonName::Format::Pattern->new(
    '{given-initial}. ({given2}) {surname}'
);
is(
    $pattern->format( $name, modifier_resolver => $initial_resolver ),
    'F. Baz',
    'Whitespace separates initial punctuation from punctuation belonging to an absent field',
);

$pattern = PersonName::Format::Pattern->new(
    '{given-initial}.({given2}) {surname}'
);
is(
    $pattern->format( $name, modifier_resolver => $initial_resolver ),
    'F Baz',
    'Adjacent punctuation is removed with the absent field as required by CLDR',
);

$pattern = PersonName::Format::Pattern->new(
    '{surname}, {given-initial}'
);
my $mononym = PersonName::Format::SimpleName->new( given => 'Zendaya' );
is(
    $pattern->format( $mononym, modifier_resolver => $initial_resolver ),
    'Zendaya',
    'A mononym is redirected from given to surname for a surname-oriented pattern',
);

$pattern = PersonName::Format::Pattern->new(
    '{given} {surname}'
);
is(
    $pattern->format( $mononym, modifier_resolver => $initial_resolver ),
    'Zendaya',
    'A normal given-name pattern does not redirect a mononym',
);

my $unresolved = PersonName::Format::Pattern->new( '{given-initial}' );
my $rv = $unresolved->format( $name );
ok( !defined( $rv ), 'Unresolved modifiers require a resolver' );
like( $unresolved->error, qr/No modifier resolver/, 'Missing resolver error identifies the modifier' );

done_testing();

__END__
