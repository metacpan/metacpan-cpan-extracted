#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use DateTime;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Module::Generic::HeaderValue' );
};

use strict;
use warnings;

subtest 'parse' => sub
{
    my $tests = 
    [
        { test => q{foo=bar}, expect => [{ value => 'foo=bar' }] },
        { test => q{foo=val; Path=/}, expect => [{ value => q{foo=val}, path => "/" }] },
        { test => q{foo=val; Path=/; Secure}, expect => [{ value => q{foo=val}, path => "/", secure => undef }] },
        { test => q{foo=val; Expires=Mon, 01 Nov 2021 08:12:10 GMT}, expect => [{ value => q{foo=val}, expires => q{Mon, 01 Nov 2021 08:12:10 GMT} }] },
        { test => q{foo=val; Expires=Mon, 01 Nov 2021 08:12:10 GMT, bar=baz; Max-Age=3600}, expect => [{ value => q{foo=val}, expires => q{Mon, 01 Nov 2021 08:12:10 GMT} }, { value => q{bar=baz}, "max-age" => 3600 }] },
        { test => q{text/html; charset=utf-8}, expect => [{ value => q{text/html}, charset => 'utf-8' }] },
        { test => q{application/json; version=1.0; encoding=utf-8}, expect => [{ value => q{application/json}, version => '1.0', encoding => 'utf-8' }] },
    ];

    foreach my $t ( @$tests )
    {
        my $res = Module::Generic::HeaderValue->new_from_multi( $t->{test}, { debug => $DEBUG });
        ok( $res );
        SKIP:
        {
            if( !defined( $res ) )
            {
                diag( "new_from_multi returned an error: ", Module::Generic::HeaderValue->error ) if( $DEBUG );
                skip( "new_from_multi failed", 2 );
            }
            my $fail = ( $res->length == scalar( @{$t->{expect}} ) ) ? 0 : 1;
            ok( !$fail, '# of elements found' );
            skip( "wrong number of elements found", 1 ) if( $fail );
            ELEM: for( my $i = 0; $i < scalar( @{$t->{expect}} ); $i++ )
            {
                my $def = $t->{expect}->[$i];
                my $val = delete( $def->{value} );
                my $elem = $res->[$i];
                diag( "Value as string is '", $elem->value_as_string, "' vs test '$val'" ) if( $DEBUG );
                $elem->value_as_string eq $val or ++$fail, last;
                no warnings 'uninitialized';
                foreach my $att ( sort( keys( %$def ) ) )
                {
                    diag( "Does param '$att' exists? ", $elem->params->exists( $att ) ? 'yes' : 'no' ) if( $DEBUG );
                    $def->{ $att } eq $elem->param( $att ) or ++$fail, last ELEM;
                }
            }
        
            if( $fail )
            {
                fail( $t->{test} );
            }
            else
            {
                pass( $t->{test} );
            }
        };
    }
};

subtest 'stringify' => sub
{
    my $tests = 
    [
    { value => 'site_prefs=lang%3Den-GB', params => { path => '/', expires => 'Monday, 01-Nov-2021 17:12:40 GMT', domain => 'www.example.com', secure => undef }, expect => 'site_prefs=lang%3Den-GB; domain=www.example.com; expires="Monday, 01-Nov-2021 17:12:40 GMT"; path="/"; secure' },
    { value => 'site_prefs=lang%3Den-GB', params => { path => '/', expires => 'Monday, 01-Nov-2021 17:12:40 GMT', domain => 'www.example.com' }, expect => 'site_prefs=lang%3Den-GB; domain=www.example.com; expires="Monday, 01-Nov-2021 17:12:40 GMT"; path="/"', decode => 1, encode => 1 }
    ];
    
    foreach my $t ( @$tests )
    {
        my $expect = delete( $t->{expect} );
        $t->{debug} = $DEBUG;
        my $hv = Module::Generic::HeaderValue->new( delete( $t->{value} ) => $t );
        my $res = $hv->as_string;
        if( !defined( $res ) )
        {
            diag( "Error with as_string: ", $hv->error ) if( $DEBUG );
        }
        is( $res, $expect );
    }
};

done_testing();

__END__

