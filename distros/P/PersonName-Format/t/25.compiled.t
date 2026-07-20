#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/25.compiled.t
##----------------------------------------------------------------------------
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use lib './lib';
    use lib 't/lib';
    use vars qw( $DEBUG );
    use open ':std' => ':utf8';
    use utf8;
    use Test::More;
    use Local::PersonNameData;
    use PersonName::Format;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

BEGIN
{
    use_ok( 'Local::PersonNameData' ) || BAIL_OUT( 'Unable to load Local::PersonNameData' );
    use_ok( 'PersonName::Format' )    || BAIL_OUT( 'Unable to load PersonName::Format' );
};

my $formatter = PersonName::Format->new( 'en-US',
    data      => Local::PersonNameData->new,
    length    => 'long',
    formality => 'formal',
);
isa_ok( $formatter, 'PersonName::Format' );

my $compiled = $formatter->compile(
    nameLocale => 'en-US',
    nameScript => 'Latn',
);
isa_ok( $compiled, 'PersonName::Format::Compiled' );

is(
    $compiled->format({
        nameLocale => 'en-US',
        given      => 'John',
        given2     => 'Ronald',
        surname    => 'Tolkien',
    }),
    'John Ronald Tolkien',
    'Compiled formatter renders with its frozen CLDR context',
);

is_deeply(
    $compiled->formatToParts({
        nameLocale => 'en-US',
        given      => 'John',
        surname    => 'Tolkien',
    }),
    [
        { type => 'given', value => 'John', field => 'given' },
        { type => 'literal', value => ' ' },
        { type => 'surname', value => 'Tolkien', field => 'surname' },
    ],
    'Compiled formatter exposes the same stable parts contract',
);

is( $compiled->resolvedOptions->{nameScript}, 'Latn',  'Resolved options expose frozen script' );
is( $compiled->resolvedOptions->{nameLocale}, 'en-US', 'Resolved options expose frozen name locale' );

{
    no warnings 'PersonName::Format';
    my $bad = $compiled->format({
        nameLocale => 'en-US',
        given      => '駿',
        surname    => '宮崎',
    });
    ok( !defined( $bad ), 'Compiled formatter rejects a mismatching script' );
    like( $compiled->error, qr/expects nameScript 'Latn'/, 'Script mismatch is explicit' );
}

# NOTE: Error paths for compile() itself.

{
    no warnings 'PersonName::Format';
    my $no_script = $formatter->compile(
        nameLocale => 'en-US',
    );
    ok( !defined( $no_script ), 'compile() rejects a missing nameScript' );
    like( $formatter->error, qr/requires a valid nameScript/, 'Missing nameScript error is explicit' );
}

{
    no warnings 'PersonName::Format';
    my $bad_script = $formatter->compile(
        nameScript => 'latin',
        nameLocale => 'en-US',
    );
    ok( !defined( $bad_script ), 'compile() rejects a nameScript that does not match the four-letter convention' );
    like( $formatter->error, qr/requires a valid nameScript/, 'Invalid nameScript format error is explicit' );
}

{
    no warnings 'PersonName::Format';
    my $bad_order = $formatter->compile(
        nameScript     => 'Latn',
        preferredOrder => 'randomOrder',
    );
    ok( !defined( $bad_order ), 'compile() rejects an invalid preferredOrder' );
    like( $formatter->error, qr/Invalid preferredOrder/, 'Invalid preferredOrder error is explicit' );
}

{
    no warnings 'PersonName::Format';
    my $unknown_opt = $formatter->compile(
        nameScript  => 'Latn',
        notAnOption => 1,
    );
    ok( !defined( $unknown_opt ), 'compile() rejects unknown options' );
    like( $formatter->error, qr/Unknown compile option/, 'Unknown option error is explicit' );
}

done_testing();

__END__
