#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/08.field_modifier.t
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
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

BEGIN
{
    use_ok( 'PersonName::Format::FieldModifier' ) || BAIL_OUT( 'Unable to load PersonName::Format::FieldModifier' );
    use_ok( 'PersonName::Format::Pattern' )       || BAIL_OUT( 'Unable to load PersonName::Format::Pattern' );
    use_ok( 'PersonName::Format::SimpleName' )    || BAIL_OUT( 'Unable to load PersonName::Format::SimpleName' );
};

my $modifier = PersonName::Format::FieldModifier->new(
    'en-GB',
    initial_pattern          => '{0}.',
    initial_sequence_pattern => '{0} {1}',
);
isa_ok( $modifier, 'PersonName::Format::FieldModifier' );
is( "$modifier->{locale}", 'en-GB', 'Locale is stored as Locale::Unicode' );
is( $modifier->initial_pattern, '{0}.', 'Explicit initial pattern is retained' );
is( $modifier->initial_sequence_pattern, '{0} {1}', 'Explicit initial sequence pattern is retained' );

is(
    $modifier->resolve( 'allCaps', 'Miyazaki' ),
    'MIYAZAKI',
    'allCaps uses Unicode uppercase',
);

is(
    $modifier->resolve( 'initialCap', 'van den Berg' ),
    'Van den Berg',
    'initialCap changes only the first grapheme and retains the rest',
);

is(
    $modifier->resolve( 'monogram', "e\x{301}mile" ),
    "e\x{301}",
    'monogram returns the first extended grapheme cluster',
);

my $name = PersonName::Format::SimpleName->new(
    given   => 'John',
    given2  => 'Ronald Reuel',
    surname => 'Tolkien',
);
my $pattern = PersonName::Format::Pattern->new(
    '{given-initial-allCaps} {given2-initial-allCaps} {surname}'
);
is(
    $pattern->format( $name, modifier_resolver => $modifier ),
    'J. R. R. Tolkien',
    'initial uses initial and initialSequence CLDR patterns',
);

$pattern = PersonName::Format::Pattern->new(
    '{given-monogram-allCaps}{given2-monogram-allCaps}{surname-monogram-allCaps}'
);
is(
    $pattern->format( $name, modifier_resolver => $modifier ),
    'JRT',
    'monogram returns one grapheme for each field',
);

$name = PersonName::Format::SimpleName->new( surname => 'Anne-Marie' );
$pattern = PersonName::Format::Pattern->new( '{surname-initial}' );
is(
    $pattern->format( $name, modifier_resolver => $modifier ),
    'A. M.',
    'initial discards punctuation by default',
);

$pattern = PersonName::Format::Pattern->new( '{surname-initial-retain}' );
is(
    $pattern->format( $name, modifier_resolver => $modifier ),
    'A.-M.',
    'retain preserves punctuation between initials',
);

$name = PersonName::Format::SimpleName->new( surname => 'Mary   Beth' );
$pattern = PersonName::Format::Pattern->new( '{surname-initial-retain}' );
is(
    $pattern->format( $name, modifier_resolver => $modifier ),
    'M. B.',
    'retain coalesces a whitespace sequence to one space',
);


is(
    $modifier->resolve( 'vocative', 'Kārlis' ),
    'Kārlis',
    'vocative defaults to a no-op when the name object did not consume it',
);
is(
    $modifier->resolve( 'genitive', 'Ozoliņš' ),
    'Ozoliņš',
    'genitive defaults to a no-op when the name object did not consume it',
);

my $bad = PersonName::Format::FieldModifier->new(
    'en',
    initial_pattern          => '{0}{0}',
    initial_sequence_pattern => '{0} {1}',
);
ok( !defined( $bad ), 'Invalid initial pattern is rejected' );
like(
    PersonName::Format::FieldModifier->error,
    qr/exactly one '\{0\}'/,
    'Invalid initial pattern error is explicit',
);

done_testing();

__END__
