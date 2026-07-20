#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/09.field_modifier_data.t
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
    eval{ require Locale::Unicode::Data; };
    plan( skip_all => "Locale::Unicode::Data unavailable: $@" ) if( $@ );
}

BEGIN
{
    use_ok( 'PersonName::Format::FieldModifier' ) || BAIL_OUT( 'Unable to load PersonName::Format::FieldModifier' );
};

my $data = Locale::Unicode::Data->new;
isa_ok( $data, 'Locale::Unicode::Data' );

my $modifier = PersonName::Format::FieldModifier->new(
    'en-US',
    data => $data,
);
isa_ok( $modifier, 'PersonName::Format::FieldModifier' );
is( $modifier->initial_pattern, '{0}.', 'Initial pattern is inherited from en' );
is( $modifier->initial_sequence_pattern, '{0}{1}', 'Initial sequence pattern is inherited from en' );

done_testing();

__END__
