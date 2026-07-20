#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/03.simple_name.t
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
    use_ok( 'PersonName::Format::SimpleName' ) || BAIL_OUT( 'Unable to load PersonName::Format::SimpleName' );
};

my $name = PersonName::Format::SimpleName->new(
    nameLocale       => 'en-GB',
    preferredOrder   => 'givenFirst',
    title            => 'Prof.',
    given            => 'John',
    given2           => 'Ronald Reuel',
    'given-informal' => 'Johnny',
    surname_prefix   => 'van',
    surnameCore      => 'Tolkien',
    generation       => 'Jr.',
);

isa_ok( $name, 'PersonName::Format::SimpleName' );
isa_ok( $name, 'PersonName::Format::Name' );
isa_ok( $name->name_locale, 'Locale::Unicode' );
is( "$name->{name_locale}", 'en-GB', 'nameLocale is normalised to Locale::Unicode' );
is( $name->preferred_order, 'givenFirst', 'preferredOrder alias is accepted' );

my $mods = { informal => 1, initial => 1 };
is(
    $name->get_field_value( 'given', $mods ),
    'Johnny',
    'informal given name is resolved by SimpleName',
);
ok( !exists( $mods->{informal} ), 'informal modifier was consumed' );
ok( exists( $mods->{initial} ),   'unhandled initial modifier remains' );

$mods = { prefix => 1 };
is(
    $name->get_field_value( 'surname', $mods ),
    'van',
    'surname prefix is resolved',
);
is_deeply( $mods, {}, 'prefix modifier was consumed' );

$mods = { core => 1 };
is(
    $name->get_field_value( 'surname', $mods ),
    'Tolkien',
    'surname core is resolved',
);
is_deeply( $mods, {}, 'core modifier was consumed' );

is(
    $name->get_field_value( 'surname', {} ),
    'van Tolkien',
    'plain surname is reconstructed from prefix and core',
);

my $plain = PersonName::Format::SimpleName->new(
    given   => 'Jacques',
    surname => 'Deguest',
);

$mods = { prefix => 1 };
is(
    $plain->get_field_value( 'surname', $mods ),
    '',
    'prefix falls back to an empty string when only plain surname exists',
);

$mods = { core => 1 };
is(
    $plain->get_field_value( 'surname', $mods ),
    'Deguest',
    'core falls back to the plain surname',
);

my $flat = PersonName::Format::SimpleName->new(
    given   => 'Jacques',
    surname => 'Deguest',
);
is( $flat->get_field_value( 'given', {} ), 'Jacques', 'flat list constructor works' );

{
    no warnings 'PersonName::Format';
    my $duplicate = PersonName::Format::SimpleName->new(
        surname_core  => 'One',
        'surname-core' => 'Two',
    );
    ok( !defined( $duplicate ), 'duplicate aliases are rejected' );
    like(
        PersonName::Format::SimpleName->error,
        qr/provided more than once/,
        'duplicate alias error is explicit',
    );
}

# NOTE: preferred_order setter validation.
my $settable = PersonName::Format::SimpleName->new(
    given   => 'John',
    surname => 'Doe',
);
isa_ok( $settable, 'PersonName::Format::SimpleName' );

{
    no warnings 'PersonName::Format';
    ok( !defined( $settable->preferred_order( 'sideways' ) ), 'preferred_order setter rejects an invalid value' );
    like(
        $settable->error,
        qr/Invalid preferred order/,
        'preferred_order setter error message is explicit',
    );
}
ok( !defined( $settable->{preferred_order} ), 'preferred_order is not set after a failed assignment' );

ok( defined( $settable->preferred_order( 'surnameFirst' ) ), 'preferred_order setter accepts surnameFirst' );
is( $settable->preferred_order, 'surnameFirst', 'preferred_order getter returns the assigned value' );

done_testing();

__END__
