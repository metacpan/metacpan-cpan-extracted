#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/16.icu4j.t
##----------------------------------------------------------------------------
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG $fixture );
    use open ':std' => ':utf8';
    use utf8;
    use Test::More;
    use File::Spec;
    use JSON::PP;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

BEGIN
{
    $fixture = File::Spec->catfile( 't', 'data', 'icu4j-person-names.json' );
    if( !$ENV{AUTHOR_TESTING} )
    {
        plan( skip_all => 'Set AUTHOR_TESTING=1 to run ICU4J differential fixtures.' );
    }
    if( !-f( $fixture ) )
    {
        plan( skip_all => "Generate $fixture with ./dev/icu4j/generate-fixtures.sh" );
    }

    use_ok( 'PersonName::Format' ) || BAIL_OUT( 'Unable to load PersonName::Format' );
};

SKIP:
{
    my $fh;
    if( !open( $fh, '<', $fixture ) )
    {
        diag( "Unable to open $fixture: $!" );
        skip( "Unable to open $fixture", 2 );
    }
    binmode( $fh, ':encoding(UTF-8)' );
    # NOTE: Use do { local $/ } to scope the input record separator change.
    # On Perl 5.10.1, 'local $/' at file scope under 'use open :utf8' corrupts the
    # internal filehandle used by Unicode::UCD, causing charscript() to return undef
    # for all subsequent calls. Scoping it in a do{} block avoids the bug. Likewise, do
    # not call close() explicitly on an encoding handle for the same reason: let $fh go
    # out of scope naturally.
    my $json = do{ local $/; <$fh> };

    my $data;
    {
        local $@;
        $data = eval{ JSON::PP->new->decode( $json ); };
        if( !ok( !$@, "Loaded fixtures JSON data" ) )
        {
            diag( "Fixtures JSON data could not be loaded: $@" );
            skip( "Fixtures JSON data could not be loaded", 2 );
        }
        elsif( !ok( ref( $data ) eq 'HASH', "Fixtures data is an hash reference" ) )
        {
            skip( "Fixtures data (" . overload::StrVal( $data ) . " is not an hash reference.", 2 );
        }
    }
    ok( ref( $data->{cases} ) eq 'ARRAY', 'Loaded ICU4J fixture cases' );
    diag( "ICU4J fixture version: " . ( $data->{icu_version} // 'unknown' ) );
    
    foreach my $case ( @{$data->{cases}} )
    {
        subtest $case->{id} => sub
        {
            my $formatter = PersonName::Format->new(
                $case->{formatter_locale},
                length          => $case->{length},
                usage           => $case->{usage},
                formality       => $case->{formality},
                display_order   => $case->{display_order},
                surname_all_caps => $case->{surname_all_caps},
            );
            isa_ok( $formatter, 'PersonName::Format' );
    
            my %name;
            foreach my $field ( qw(
                title given given_informal given2 surname surname_prefix
                surname_core surname2 generation credentials
            ) )
            {
                $name{$field} = $case->{$field}
                    if( defined( $case->{$field} ) && length( $case->{$field} ) );
            }

            if( defined( $case->{name_locale} ) &&
                length( $case->{name_locale} ) )
            {
                $name{name_locale} = $case->{name_locale};
            }
            if( defined( $case->{preferred_order} ) &&
                length( $case->{preferred_order} ) &&
                $case->{preferred_order} ne 'default' )
            {
                $name{preferred_order} = $case->{preferred_order};
            }
    
            my $actual = $formatter->format( \%name );
            is( $actual, $case->{result}, 'Perl result matches ICU4J fixture' ) ||
                diag( $formatter->error // '' );
        };
    }
};

done_testing();

__END__
