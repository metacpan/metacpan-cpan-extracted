#!perl

use Test::More tests => 8;

use strict;
use warnings;

BEGIN { use_ok( 'String::Interpolate::Shell', 'strinterp' ); }




{
    eval { strinterp( '${q:?Frau Blucher}', {} ) };
    my $err = $@;
    ok ( length($err), '${q:?}' );
    like ( $err, qr/^Frau Blucher/, 'error message' );
}

{
    eval { strinterp( '${a:?Frau Blucher}', { a => 1 } ) };
    my $err = $@;
    is ( $err, '', '${a:?}' );
}

{
    my $tpl = '${q}';
    my $text = strinterp( $tpl, {},
			{
			 undef_value => 'ignore'
			} );
    is( $text, $tpl, 'value ignore' );
}

{
    my $tpl = 'here lies ${q}';
    my $text = strinterp( $tpl, {},
			{
			 undef_value => 'remove'
			} );
    is( $text, 'here lies ', 'value remove' );
}

{
    eval {
	strinterp( '$q', {},
		 {
		  undef_verbosity => 'fatal'
		 } );
    };
    ok( $@ ne '', 'verbosity fatal' );
}

{
    my $error;

    open my $olderr, ">&STDERR"
      or die( "error duping stderr\n" );

    close STDERR;

    open STDERR, '>', \$error
      or die( "error reopening stderr\n" );

    eval {
	strinterp( '$q', {},
		 {
		  undef_verbosity => 'warn'
		 } );
    };
    close STDERR;

    open STDERR, '>&', $olderr;

    like( $error, qr/undefined variable: \$q/, 'verbosity warn' );

}
