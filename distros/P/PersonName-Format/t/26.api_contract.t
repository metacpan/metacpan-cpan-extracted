#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/26.api_contract.t
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
    use PersonName::Format::SimpleName;
    use PersonName::Format::Pattern;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

BEGIN
{
    use_ok( 'PersonName::Format::Pattern' )    || BAIL_OUT( 'Unable to load PersonName::Format::Pattern' );
    use_ok( 'PersonName::Format::SimpleName' ) || BAIL_OUT( 'Unable to load PersonName::Format::SimpleName' );
};

my @warnings;
{
    no warnings 'PersonName::Format';
    local $SIG{__WARN__} = sub{ push( @warnings, @_ ) };
    my $bad = PersonName::Format::Pattern->new( '{unknown}' );
    ok( !defined( $bad ), 'Handled validation failure returns undef' );
}
is_deeply( \@warnings, [], 'Handled validation failures do not emit warnings by default' );

my $debug;
{
    local $SIG{__WARN__} = sub{ $debug .= join( '', @_ ) };
    my $bad = PersonName::Format::Pattern->new( '{unknown}', debug => 1 );
    ok( !defined( $bad ), 'Debug validation failure still returns undef' );
}
like( $debug, qr/Unknown person-name field/, 'Debug mode emits the diagnostic warning' );

my $name = PersonName::Format::SimpleName->new(
    given           => 'Johnny',
    given_informal  => 'John',
    surname         => 'Doe',
);
my $modifiers = { informal => 1 };
is( $name->get_field_value( 'given', $modifiers ), 'John', 'Informal field is resolved' );
is_deeply( $modifiers, {}, 'Resolved name-provider modifiers are consumed by contract' );

my $pattern = PersonName::Format::Pattern->new( '{given-initial} {surname}' );
my $parts = $pattern->formatToParts(
    $name,
    modifier_resolver => sub
    {
        my( $modifier, $value ) = @_;
        return( substr( $value, 0, 1 ) ) if( $modifier eq 'initial' );
        return( $value );
    },
);
is( $parts->[0]->{type}, 'given-initial', 'Part type remains the CLDR field expression' );
is( $parts->[0]->{field}, 'given', 'Part field exposes the base CLDR field' );
is_deeply( $parts->[0]->{modifiers}, ['initial'], 'Part modifiers preserve their source order' );

done_testing();

__END__
