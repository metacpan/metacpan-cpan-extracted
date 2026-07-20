#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/05.pattern.t
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

my $pattern = PersonName::Format::Pattern->new(
    '{title} {given} {given2} {surname}, {credentials}'
);
isa_ok( $pattern, 'PersonName::Format::Pattern' );

is_deeply(
    $pattern->tokens,
    [
        { type => 'field', field => 'title', modifiers => [], source => 'title' },
        { type => 'literal', value => ' ' },
        { type => 'field', field => 'given', modifiers => [], source => 'given' },
        { type => 'literal', value => ' ' },
        { type => 'field', field => 'given2', modifiers => [], source => 'given2' },
        { type => 'literal', value => ' ' },
        { type => 'field', field => 'surname', modifiers => [], source => 'surname' },
        { type => 'literal', value => ', ' },
        { type => 'field', field => 'credentials', modifiers => [], source => 'credentials' },
    ],
    'Pattern is parsed into structured literal and field tokens',
);

my $name = PersonName::Format::SimpleName->new(
    given   => 'Jacques',
    surname => 'Deguest',
);

is( $pattern->num_populated_fields( $name ), 2, 'Two fields are populated' );
is( $pattern->num_empty_fields( $name ), 3, 'Three fields are empty' );
is( $pattern->format( $name ), 'Jacques Deguest', 'Leading, middle, and trailing empty fields are removed structurally' );

my $escaped = PersonName::Format::Pattern->new( '\\{literal\\} {given}' );
is( $escaped->format( $name ), '{literal} Jacques', 'Escaped braces remain literal text' );

foreach my $case (
    [ '{given', qr/Unmatched opening brace/ ],
    [ 'given}', qr/Unmatched closing brace/ ],
    [ '{}', qr/No field name/ ],
    [ '{{given}}', qr/Nested braces/ ],
    [ '{unknown}', qr/Unknown person-name field/ ],
    [ '{given-unknown}', qr/Unknown person-name modifier/ ],
    [ '{given-initial-initial}', qr/occurs more than once/ ],
    [ 'literal only', qr/at least one field/ ],
)
{
    my $bad = PersonName::Format::Pattern->new( $case->[0] );
    ok( !defined( $bad ), "Invalid pattern '$case->[0]' is rejected" );
    like( PersonName::Format::Pattern->error, $case->[1], 'The parser reports the precise error' );
}


foreach my $case (
    [ '{given-allCaps-initialCap}', qr/mutually exclusive/ ],
    [ '{given-initial-monogram}', qr/mutually exclusive/ ],
    [ '{surname-prefix-core}', qr/mutually exclusive/ ],
    [ '{given-retain}', qr/requires modifier 'initial'/ ],
)
{
    my( $source, $regexp ) = @$case;
    my $invalid = PersonName::Format::Pattern->new( $source );
    ok( !defined( $invalid ), "Invalid modifier combination '${source}' is rejected" );
    like( PersonName::Format::Pattern->error, $regexp, 'The modifier constraint error is explicit' );
}

my $grammatical = PersonName::Format::Pattern->new(
    '{given-vocative} {surname-genitive}'
);
isa_ok(
    $grammatical,
    'PersonName::Format::Pattern',
    'Current CLDR grammatical modifiers are accepted',
);

done_testing();

__END__
