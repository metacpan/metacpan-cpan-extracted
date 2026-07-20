#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/04.format_input.t
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
    use_ok( 'PersonName::Format' )             || BAIL_OUT( 'Unable to load PersonName::Format' );
    use_ok( 'PersonName::Format::SimpleName' ) || BAIL_OUT( 'Unable to load PersonName::Format::SimpleName' );
};

my $formatter = PersonName::Format->new(
    'en-GB',
    length       => 'long',
    usage        => 'referring',
    formality    => 'formal',
    displayOrder => 'default',
);

isa_ok( $formatter, 'PersonName::Format' );

{
    no warnings 'PersonName::Format';
    my $bad_data = PersonName::Format->new(
        'en-GB',
        data => {},
    );
    ok( !defined( $bad_data ), 'unblessed data provider is rejected' );
    like(
        PersonName::Format->error,
        qr/data option must be an object/,
        'data provider error is explicit',
    );
}

my $name = $formatter->_coerce_name(
    given      => 'Jacques',
    surname    => 'Deguest',
    nameLocale => 'fr-FR',
);
isa_ok( $name, 'PersonName::Format::SimpleName' );
is( $name->get_field_value( 'given', {} ), 'Jacques', 'flat input is accepted' );

$name = $formatter->_coerce_name({
    given   => 'John',
    surname => 'Doe',
});
isa_ok( $name, 'PersonName::Format::SimpleName' );

my $simple = PersonName::Format::SimpleName->new(
    given   => 'Jane',
    surname => 'Doe',
);
is( $formatter->_coerce_name( $simple ), $simple, 'SimpleName object is retained' );

{
    package Local::Name;

    sub new { return( bless( {}, shift ) ); }
    sub get_field_value { return( 'value' ); }
    sub name_locale { return( 'en' ); }
    sub preferred_order { return; }
}

my $custom = Local::Name->new;
is( $formatter->_coerce_name( $custom ), $custom, 'duck-typed name object is accepted' );

{
    no warnings 'PersonName::Format';
    my $bad = $formatter->_coerce_name( bless( {}, 'Local::BadName' ) );
    ok( !defined( $bad ), 'object without contract is rejected' );
    like( $formatter->error, qr/does not implement/, 'contract error is explicit' );
}

is_deeply(
    $formatter->resolved_options,
    {
        locale         => 'en-GB',
        length         => 'long',
        usage          => 'referring',
        formality      => 'formal',
        displayOrder   => 'default',
        surnameAllCaps => 0,
    },
    'resolved_options returns current initial options',
);

done_testing();

__END__
