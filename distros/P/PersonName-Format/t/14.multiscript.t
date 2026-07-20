#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/14.multiscript.t
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
    use_ok( 'PersonName::Format' )             || BAIL_OUT( 'Unable to load PersonName::Format' );
    use_ok( 'PersonName::Format::SimpleName' ) || BAIL_OUT( 'Unable to load PersonName::Format::SimpleName' );
};

my $formatter = bless( {}, 'PersonName::Format' );

my @cases =
(
    [ 'Петров',  'Иван',   'Cyrl', 'Russian Cyrillic name' ],
    [ 'علي',     'محمد',   'Arab', 'Arabic name' ],
    [ 'رضایی',   'حسین',   'Arab', 'Persian name uses the Arabic script property' ],
    [ '王',       '小明',   'Hani', 'Chinese Han name' ],
    [ 'शर्मा',    'अमित',   'Deva', 'Hindi Devanagari name' ],
    [ '宮崎',     '駿',      'Hani', 'Japanese kanji name is script-ambiguous Han' ],
    [ '김',       '민준',   'Hang', 'Korean Hangul name' ],
);

foreach my $case ( @cases )
{
    my( $surname, $given, $expected, $label ) = @$case;
    my $name = PersonName::Format::SimpleName->new(
        surname => $surname,
        given   => $given,
    );
    is(
        $formatter->_detected_script( $name ),
        $expected,
        $label,
    );
}

done_testing();

__END__
