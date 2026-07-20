#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/21.pattern_cache.t
##----------------------------------------------------------------------------
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Scalar::Util qw( refaddr );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'PersonName::Format' )             || BAIL_OUT( 'Unable to load PersonName::Format' );
    use_ok( 'PersonName::Format::SimpleName' ) || BAIL_OUT( 'Unable to load PersonName::Format::SimpleName' );
};

my $formatter = PersonName::Format->new(
    'en',
    length      => 'long',
    usage       => 'referring',
    formality   => 'formal',
);
isa_ok( $formatter, 'PersonName::Format' );

my $name = PersonName::Format::SimpleName->new(
    given      => 'Jacques',
    surname    => 'Deguest',
    nameLocale => 'fr-FR',
);
isa_ok( $name, 'PersonName::Format::SimpleName' );

is( $formatter->_pattern_cache_size, 0, 'Pattern cache starts empty' );

my $first = $formatter->_name_context( $name );
ok( defined( $first ), 'First formatting context was derived' );
ok( $formatter->_pattern_cache_size > 0, 'First context populated the pattern cache' );
my $cache_size = $formatter->_pattern_cache_size;
my $first_pattern = refaddr( $first->{pattern} );

my $second = $formatter->_name_context( $name );
ok( defined( $second ), 'Second formatting context was derived' );
is(
    $formatter->_pattern_cache_size,
    $cache_size,
    'Second context did not grow the cache for identical pattern sources',
);
is(
    refaddr( $second->{pattern} ),
    $first_pattern,
    'Second context reused the same parsed Pattern object',
);

is(
    $formatter->format( $name ),
    'Jacques Deguest',
    'Caching does not change the formatted result',
);

done_testing();

__END__
