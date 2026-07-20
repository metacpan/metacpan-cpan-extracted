#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/10.format.t
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
    use_ok( 'PersonName::Format' )    || BAIL_OUT( 'Unable to load PersonName::Format' );
};

my $en = PersonName::Format->new(
    'en',
    length      => 'long',
    usage       => 'referring',
    formality   => 'formal',
);
isa_ok( $en, 'PersonName::Format' );

is(
    $en->format(
        title       => 'Dr.',
        given       => 'John',
        given2      => 'Ronald Reuel',
        surname     => 'Tolkien',
        nameLocale  => 'en-GB',
    ),
    'Dr. John Ronald Reuel Tolkien',
    'English long formal referring name is formatted end to end',
);

my $short = PersonName::Format->new(
    'en',
    length      => 'short',
    usage       => 'referring',
    formality   => 'formal',
);

is(
    $short->format(
        given      => 'John',
        given2     => 'Ronald Reuel',
        surname    => 'Tolkien',
        nameLocale => 'en-GB',
    ),
    'J.R.R. Tolkien',
    'Short format applies locale initial patterns',
);

my $preferred = PersonName::Format->new(
    'en',
    length      => 'long',
    usage       => 'referring',
    formality   => 'formal',
);

is(
    $preferred->format(
        given          => 'Jacques',
        surname        => 'Deguest',
        nameLocale     => 'fr-FR',
        preferredOrder => 'surnameFirst',
    ),
    'Deguest Jacques',
    'preferredOrder takes precedence over derived order',
);

my $forced = PersonName::Format->new(
    'en',
    length       => 'long',
    usage        => 'referring',
    formality    => 'formal',
    displayOrder => 'surnameFirst',
);

is(
    $forced->format(
        given      => 'Jacques',
        surname    => 'Deguest',
        nameLocale => 'fr-FR',
    ),
    'Deguest Jacques',
    'explicit displayOrder is applied',
);

my $caps = PersonName::Format->new(
    'en',
    length         => 'long',
    usage          => 'referring',
    formality      => 'formal',
    surnameAllCaps => 1,
);

is(
    $caps->format(
        given      => 'Jacques',
        surname    => 'Deguest',
        nameLocale => 'fr-FR',
    ),
    'Jacques DEGUEST',
    'surnameAllCaps uppercases surname fields',
);

my $ja = PersonName::Format->new(
    'ja-JP',
    length      => 'long',
    usage       => 'referring',
    formality   => 'formal',
);

is(
    $ja->format(
        given      => '駿',
        surname    => '宮崎',
        nameLocale => 'ja-JP',
    ),
    '宮崎駿',
    'Japanese native space replacement is applied',
);

is(
    $ja->format(
        given      => 'アルベルト',
        surname    => 'アインシュタイン',
        nameLocale => 'de-DE',
    ),
    'アルベルト・アインシュタイン',
    'Japanese foreign space replacement is applied with explicit foreign name locale',
);

my $defaults = PersonName::Format->new(
    'en-US',
);
is( $defaults->length, 'medium', 'CLDR default length is inherited' );
is( $defaults->formality, 'informal', 'CLDR default formality is inherited' );
is( $defaults->usage, 'referring', 'usage defaults to referring' );
is_deeply(
    $defaults->resolvedOptions,
    {
        locale         => 'en-US',
        length         => 'medium',
        usage          => 'referring',
        formality      => 'informal',
        displayOrder   => 'default',
        surnameAllCaps => 0,
    },
    'resolvedOptions returns normalised resolved options',
);

is(
    $defaults->format(
        given          => 'John',
        givenInformal  => 'Johnny',
        surname        => 'Doe',
        nameLocale     => 'en-US',
    ),
    'Johnny Doe',
    'Wildcard personName rule is selected for resolved defaults',
);

is(
    $en->format(
        given   => 'John',
        surname => 'Doe',
    ),
    'John Doe',
    'name locale is derived automatically when omitted',
);

done_testing();

__END__
