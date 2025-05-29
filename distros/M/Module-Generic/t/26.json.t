#!/usr/local/bin/perl
# Those unit tests are borrowed from JSON distribution, and adapted for this distribution.
BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    use Config;
    # use open ':std' => ':utf8';
    use Test::More;
    use Module::Generic::JSON qw( new_json );
    local $@;
    eval( 'require JSON' );
    if( $@ )
    {
        plan(skip_all => 'These tests require JSON to be installed.');
    }
    else
    {
        plan();
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    $Module::Generic::JSON::DEBUG = $DEBUG;
};

use strict;
use warnings;
use utf8;

my $class = 'Module::Generic::JSON';
can_ok( 'Module::Generic::JSON', 'new_json' );
can_ok( 'Module::Generic::JSON', 'decode_json' );

subtest "utf8" => sub
{
    my $pilcrow_utf8 = (ord "^" == 0x5E) ? "\xc2\xb6"  # 8859-1
                     : (ord "^" == 0x5F) ? "\x80\x65"  # CP 1024
                     :                     "\x78\x64"; # assume CP 037
    is( new_json->allow_nonref(1)->utf8(1)->encode("¶"), "\"$pilcrow_utf8\"", 'utf8->encode' );
    is( new_json->allow_nonref(1)->encode("¶"), "\"¶\"", 'encode');
    is( new_json->allow_nonref(1)->ascii(1)->utf8(1)->encode(chr 0x8000), '"\u8000"', 'ascii->utf8->encode' );
    is( new_json->allow_nonref(1)->ascii(1)->utf8(1)->pretty(1)->encode(chr 0x10402), "\"\\ud801\\udc02\"\n", 'ascii->utf8->pretty->encode' );

    my $j = new_json->allow_nonref(1)->utf8(1);
    my $rv = $j->decode('"¶"');
    is( $rv, undef, 'error decoding' );
    like( $j->error->message, qr/malformed UTF-8/, 'error message' );

    is( new_json->allow_nonref(1)->decode('"¶"'), "¶", 'allow_nonref' );
    is( new_json->allow_nonref(1)->decode('"\u00b6"'), "¶", 'allow_nonref' );
    is( new_json->allow_nonref(1)->decode('"\ud801\udc02' . "\x{10204}\"" ), "\x{10402}\x{10204}", 'allow_nonref' );

    my $controls = (ord "^" == 0x5E) ? "\012\\\015\011\014\010"
                 : (ord "^" == 0x5F) ? "\025\\\015\005\014\026"  # CP 1024
                 :                     "\045\\\015\005\014\026"; # assume CP 037
    is( new_json->allow_nonref(1)->decode('"\"\n\\\\\r\t\f\b"'), "\"$controls", 'allow_nonref with blackslash' );
};

subtest "error" => sub
{
    new_json->encode([\-1]);
    like( $class->error, qr/cannot encode reference/, 'cannot encode reference' );

    new_json->encode([\undef]);
    like( $class->error->message => qr/cannot encode reference/, 'cannot encode reference' );

    new_json->encode([\2]);
    like( $class->error->message => qr/cannot encode reference/, 'cannot encode reference' );

    new_json->encode([\{}]);
    like( $class->error->message => qr/cannot encode reference/, 'cannot encode reference' );

    new_json->encode([\[]]);
    like( $class->error->message => qr/cannot encode reference/, 'cannot encode reference' );

    new_json->encode([\\1]);
    like( $class->error->message => qr/cannot encode reference/, 'cannot encode reference' );

    new_json->allow_nonref(1)->decode('"\u1234\udc00"');
    like( $class->error->message => qr/missing high /, 'decode error' );

    new_json->allow_nonref->decode('"\ud800"');
    like( $class->error->message => qr/missing low /, 'decode error' );

    new_json->allow_nonref(1)->decode('"\ud800\u1234"');
    like( $class->error->message => qr/surrogate pair /, 'decode error' );

    new_json->allow_nonref(0)->decode('null');
    like( $class->error->message => qr/allow_nonref/, 'decode error' );

    new_json->allow_nonref(1)->decode('+0');
    like( $class->error->message => qr/malformed/, 'decode error' );

    new_json->allow_nonref->decode('.2');
    like( $class->error->message => qr/malformed/, 'decode error' );

    new_json->allow_nonref(1)->decode('bare');
    like( $class->error->message => qr/malformed/, 'decode error' );

    new_json->allow_nonref->decode('naughty');
    like( $class->error->message => qr/null/, 'decode error' );

    new_json->allow_nonref(1)->decode('01');
    like( $class->error->message => qr/leading zero/, 'decode error' );

    new_json->allow_nonref->decode('00');
    like( $class->error->message => qr/leading zero/, 'decode error' );

    new_json->allow_nonref (1)->decode('-0.');
    like( $class->error->message => qr/decimal point/, 'decode error' );

    new_json->allow_nonref->decode('-0e');
    like( $class->error->message => qr/exp sign/, 'decode error' );

    new_json->allow_nonref (1)->decode('-e+1');
    like( $class->error->message => qr/initial minus/, 'decode error' );

    new_json->allow_nonref->decode("\"\n\"");
    like( $class->error->message => qr/invalid character/, 'decode error' );

    new_json->allow_nonref (1)->decode("\"\x01\"");
    like( $class->error->message => qr/invalid character/, 'decode error' );

    new_json->decode('[5');
    like( $class->error->message => qr/parsing array/, 'decode error' );

    new_json->decode('{"5"');
    like( $class->error->message => qr/':' expected/, 'decode error' );

    new_json->decode('{"5":null');
    like( $class->error->message => qr/parsing object/, 'decode error' );

    {
        no warnings;
        new_json->decode(undef);
        like $class->error->message => qr/malformed/, 'decode malformed error';
    }

    new_json->decode(\5);
    # Cannot coerce readonly
    ok( !!$class->error );

    new_json->decode([]);
    like( $class->error->message => qr/malformed/, 'decode malformed error' );

    new_json->decode(\*STDERR);
    like( $class->error->message => qr/malformed/, 'decode malformed error' );

    # new_json->decode(*STDERR);
    # Cannot coerce GLOB
    # ok( !!$class->error );

    decode_json("\"\xa0");
    like( $class->error => qr/malformed.*character/, 'decode malformed error' );

    decode_json("\"\xa0\"");
    like( $class->error => qr/malformed.*character/, 'decode malformed error' );

    SKIP:
    {
        if( ( $JSON::BackendModulePP and eval $JSON::BackendModulePP->VERSION < 3) or
            ( $JSON::BackendModule eq 'Cpanel::JSON::XS' ) or 
            ( $JSON::BackendModule eq 'JSON::XS' and $JSON::BackendModule->VERSION < 4 ) )
        {
            skip( "requires JSON::XS 4 compat backend", 4 );
        }
        decode_json("1\x01");
        like( $class->error => qr/garbage after/ );

        decode_json("1\x00");
        like( $class->error => qr/garbage after/ );

        decode_json("\"\"\x00");
        like( $class->error => qr/garbage after/ );

        decode_json("[]\x00");
        like( $class->error => qr/garbage after/ );
    }

};

subtest "blessed" => sub
{
    my $o1 = bless { a => 3 }, "XX";
    my $o2 = bless \(my $dummy = 1), "YY";

    sub XX::TO_JSON
    {
       {'__',""}
    }

    my $js = new_json();

    $js->encode($o1);
    ok( $js->error => qr/allow_blessed/ );

    $js->encode($o2);
    ok( $js->error => qr/allow_blessed/ );

    $js->allow_blessed;
    ok( $js->encode($o1) eq "null" );
    ok( $js->encode($o2) eq "null" );

    $js->convert_blessed;
    ok( $js->encode($o1) eq '{"__":""}' );
    ok( $js->encode($o2) eq "null" );

    $js->filter_json_object(sub{ 5 });
    $js->filter_json_single_key_object(a => sub { shift });
    $js->filter_json_single_key_object(b => sub { 7 });

    ok( "ARRAY" eq ref( $js->decode("[]") ) );
    ok( 5 eq join( ":", @{ $js->decode('[{}]') } ) );
    ok( 6 eq join( ":", @{ $js->decode('[{"a":6}]') } ) );
    ok( 5 eq join( ":", @{ $js->decode('[{"a":4,"b":7}]') } ) );

    $js->filter_json_object;
    ok( 7 == $js->decode('[{"a":4,"b":7}]')->[0]{b} );
    ok( 3 eq join ":", @{ $js->decode('[{"a":3}]') } );

    $js->filter_json_object(sub { });
    ok( 7 == $js->decode('[{"a":4,"b":7}]')->[0]{b} );
    ok( 9 eq join( ":", @{ $js->decode('[{"a":9}]') } ) );

    $js->filter_json_single_key_object("a");
    ok( 4 == $js->decode('[{"a":4}]')->[0]{a} );

    # sub {} is not suitable for Perl 5.6
    $js->filter_json_single_key_object( a => sub{ return; });
    ok( 4 == $js->decode('[{"a":4}]')->[0]{a} );
};

subtest "relaxed" => sub
{
    my $json = new_json( relaxed => 1 );

    ok( '[1,2,3]' eq encode_json( $json->decode(' [1,2, 3]') ) );
    ok( '[1,2,4]' eq encode_json( $json->decode('[1,2, 4 , ]') ) );
    ok( !$json->decode('[1,2, 3,4,,]') );
    ok( !$json->decode('[,1]') );

    ok( '{"1":2}' eq encode_json( $json->decode(' {"1":2}') ) );
    ok( '{"1":2}' eq encode_json( $json->decode('{"1":2,}') ) );
    ok( !$json->decode('{,}') );

    ok( '[1,2]' eq encode_json( $json->decode("[1#,2\n ,2,#  ]  \n\t]") ) );
};

subtest 'Additional functionality' => sub
{
    no warnings;
    my $data = { a => 1, b => 2 };
    my $json_str = to_json( $data, { pretty => 1, canonical => 1 } );
    ok( defined( $json_str ), 'to_json with pretty option' );
    like( $json_str, qr/^\s*\{\n\s*"a" : 1,\n\s*"b" : 2\n\s*\}\n$/, 'to_json pretty format' );

    my $decoded = from_json( $json_str, { relaxed => 1 } );
    ok( defined( $decoded ), 'from_json with relaxed option' );
    is_deeply( $decoded, $data, 'from_json decoded correctly' );

    my $json = new_json( max_depth => 2 );
    my $nested = { a => { b => { c => 1 } } };
    my $rv = $json->encode( $nested );
    ok( !defined( $rv ), 'max_depth exceeded' );
    like( $json->error->message, qr/maximum nesting level/, 'max_depth error message' );

    $json = new_json( invalid_option => 1 );
    # ok( !defined( $json ), 'invalid option in new' );
    like( Module::Generic::JSON->error->message, qr/Unknown method/, 'invalid option error' );
};

subtest 'Thread-safe JSON operations' => sub
{
    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( 'Threads not available', 3 );
        }

        require threads;
        require threads::shared;

        my @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid();
                my $json = Module::Generic::JSON->new( utf8 => 1, debug => $DEBUG );
                my $encoded = $json->encode( { tid => $tid } );
                if( !defined( $encoded ) )
                {
                    diag( "Thread $tid: Failed to encode: ", $json->error ) if( $DEBUG );
                    return(0);
                }
                my $decoded = $json->decode( $encoded );
                if( !defined( $decoded ) )
                {
                    diag( "Thread $tid: Failed to decode: ", $json->error ) if( $DEBUG );
                    return(0);
                }
                if( $decoded->{tid} != $tid )
                {
                    diag( "Thread $tid: Decoded tid mismatch: ", $decoded->{tid} ) if( $DEBUG );
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

        ok( $success, 'All threads encoded/decoded successfully' );
        my $json = Module::Generic::JSON->new;
        my $encoded = encode_json( { a => 1 } );
        ok( defined( $encoded ), 'encode_json thread-safe' );
        my $decoded = decode_json( $encoded );
        ok( defined( $decoded ), 'decode_json thread-safe' );
    };
};

done_testing();

__END__
