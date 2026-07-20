#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/02.name.t
##----------------------------------------------------------------------------
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'PersonName::Format::Name' ) || BAIL_OUT( 'Unable to load PersonName::Format::Name' );
};

my $name = PersonName::Format::Name->new;
isa_ok( $name, 'PersonName::Format::Name' );

is(
    $name->internal_field_name( 'surname-core' ),
    'surname_core',
    'CLDR surname-core maps to internal surname_core',
);

is(
    $name->internal_field_name( 'surnameCore' ),
    'surname_core',
    'camelCase surnameCore maps to internal surname_core',
);

is(
    $name->external_field_name( 'surname_core' ),
    'surname-core',
    'internal surname_core maps to CLDR surname-core',
);

ok(
    !$name->implements_name_contract( bless( {}, 'Local::IncompleteName' ) ),
    'Incomplete object does not implement the name contract',
);

{
    package Local::CompleteName;

    sub get_field_value { return; }
    sub name_locale { return; }
    sub preferred_order { return; }
}

ok(
    $name->implements_name_contract( bless( {}, 'Local::CompleteName' ) ),
    'Duck-typed object implements the name contract',
);

done_testing();

__END__
