#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/11.format_data.t
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

eval
{
    require Locale::Unicode::Data;
};
if( $@ )
{
    plan( skip_all => "Locale::Unicode::Data unavailable: $@" );
}

my $data = Locale::Unicode::Data->new;
if( !defined( $data ) )
{
    plan( skip_all => 'Unable to instantiate Locale::Unicode::Data: ' . Locale::Unicode::Data->error );
}

use_ok( 'PersonName::Format' ) || BAIL_OUT( 'Unable to load PersonName::Format' );

my $formatter = PersonName::Format->new(
    'en',
    data      => $data,
    length    => 'long',
    usage     => 'referring',
    formality => 'formal',
);
isa_ok( $formatter, 'PersonName::Format' );

is(
    $formatter->format(
        given      => 'Jacques',
        surname    => 'Deguest',
        nameLocale => 'fr-FR',
    ),
    'Jacques Deguest',
    'Real Locale::Unicode::Data provider formats an English person name',
);

my $ja = PersonName::Format->new(
    'ja-JP',
    data      => $data,
    length    => 'long',
    usage     => 'referring',
    formality => 'formal',
);

is(
    $ja->format(
        given      => '駿',
        surname    => '宮崎',
        nameLocale => 'ja-JP',
    ),
    '宮崎駿',
    'Real Locale::Unicode::Data provider applies Japanese native spacing',
);

done_testing();

__END__
