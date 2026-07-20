#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/19.first_grapheme.t
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
    use_ok( 'PersonName::Format' )     || BAIL_OUT( 'Unable to load PersonName::Format' );
    use_ok( 'PersonName::Format::PP' ) || BAIL_OUT( 'Unable to load PersonName::Format::PP' );
};

my @cases =
(
    [ undef, '' ],
    [ '', '' ],
    [ 'Albert', 'A' ],
    [ "e\x{301}clair", "e\x{301}" ],
    [ "\x{261D}\x{FE0F}test", "\x{261D}\x{FE0F}" ],
    [ "\x{1F469}\x{200D}\x{1F4BB}Alice", "\x{1F469}\x{200D}\x{1F4BB}" ],
    [ "\x{1F1EF}\x{1F1F5}Japan", "\x{1F1EF}\x{1F1F5}" ],
    [ "\x{928}\x{93F}ति", "\x{928}\x{93F}" ],
    [ "\x{304B}\x{3099}く", "\x{304B}\x{3099}" ],
    [ '宮崎', '宮' ],
);

foreach my $case ( @cases )
{
    my( $value, $expected ) = @$case;
    my $pp = PersonName::Format::PP::_first_grapheme( $value );
    my $backend = PersonName::Format::_first_grapheme( $value );
    is( $pp, $expected, 'Pure-Perl first grapheme matches expected value' );
    is( $backend, $pp, 'Selected backend matches pure Perl' );
}

SKIP:
{
    skip( 'XS backend is not loaded', scalar( @cases ) )
        if( $PersonName::Format::IsPurePerl );

    foreach my $case ( @cases )
    {
        my( $value ) = @$case;
        is(
            PersonName::Format::_first_grapheme( $value ),
            PersonName::Format::PP::_first_grapheme( $value ),
            'XS first grapheme is identical to pure Perl',
        );
    }
}

done_testing();

__END__
