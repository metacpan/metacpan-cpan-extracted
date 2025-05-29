#!perl
BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    use Config;
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

subtest 'Additional methods' => sub
{
    my $hv = Module::Generic::HeaderValue->new( "foo=bar", debug => $DEBUG );
    $hv->decode(1);
    is( $hv->decode, 1, 'decode' );
    $hv->encode(1);
    is( $hv->encode, 1, 'encode' );
    $hv->original( "foo=bar; baz=qux" );
    is( $hv->original->scalar, "foo=bar; baz=qux", 'original' );
    $hv->param( baz => "qux" );
    is( $hv->param( "baz" ), "qux", 'param set/get' );
    isa_ok( $hv->params, 'Module::Generic::Hash', 'params class' );
    my $quoted = $hv->qstring( "Mon, 01 Nov 2021" );
    is( $quoted, '"Mon, 01 Nov 2021"', 'qstring' );
    $hv->reset;
    is( $hv->original->scalar, "", 'reset' );
    my $escaped = $hv->token_escape( "foo/bar" );
    is( $escaped, "foo%2Fbar", 'token_escape' );
    $hv->token_max(10);
    is( $hv->token_max, 10, 'token_max' );
    $hv->value_max(20);
    is( $hv->value_max, 20, 'value_max' );
    isa_ok( $hv->value, 'Module::Generic::Array', 'value class' );
    is( $hv->value_as_string, "foo=bar", 'value_as_string' );
    is( $hv->value_data, "bar", 'value_data' );
    is( $hv->value_name, "foo", 'value_name' );
};

subtest 'Edge cases' => sub
{
    no warnings;
    my $hv = Module::Generic::HeaderValue->new( "foo=bar", debug => $DEBUG );
    $hv->token_max(3);
    $hv->param( long_token => "value" );
    my $res = $hv->as_string;
    ok( !defined( $res ), 'Token exceeds max length' );
    $hv->token_max(0);
    $hv->value_max(2);
    $hv->param( short => "long_value" );
    $res = $hv->as_string;
    ok( !defined( $res ), 'Value exceeds max length' );
    $hv->value_max(0);
    my $quoted = $hv->qstring( "invalid\nvalue" );
    ok( !defined( $quoted ), 'Invalid characters in qstring' );
};

subtest 'Thread-safe header operations' => sub
{
    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( 'Threads not available', 2 );
        }

        require threads;
        require threads::shared;

        my @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid();
                my $hv = Module::Generic::HeaderValue->new( "foo=bar; tid=$tid", debug => $DEBUG );
                if( !$hv->param( tid => $tid ) )
                {
                    diag( "Thread $tid: Failed to set param: ", $hv->error ) if( $DEBUG );
                    return(0);
                }
                if( $hv->param( 'tid' ) ne $tid )
                {
                    diag( "Thread $tid: Param 'tid' mismatch: ", $hv->param( 'tid' ) ) if( $DEBUG );
                    return(0);
                }
                return(1);
            });
        } 1..5;

        my $success = 1;
        for my $thr ( @threads )
        {
            $success &&= $thr->join();
        }

        ok( $success, 'All threads processed headers successfully' );
        ok( !defined( $Module::Generic::HeaderValue::DEBUG ) || $Module::Generic::HeaderValue::DEBUG == 0, 'Global $DEBUG unchanged' );
    };
};

done_testing();

__END__

