#!perl -w
use strict;
use constant HAS_LEAKTRACE => eval { require Test::LeakTrace };
use Test::More HAS_LEAKTRACE
    ? ( tests => 205 )
    : ( skip_all => 'require Test::LeakTrace' );
use Test::LeakTrace;

use_ok('SWISH::3');

leaks_cmp_ok {
    my $s3 = SWISH::3->new(
        handler => sub { myhandler(@_) },
        config  => '<swish><foo>bar</foo></swish>'
    );
}
'<', 2, "new parser"; # regex leaks, ok.

ok( my $s3 = SWISH::3->new(
        handler => sub { myhandler(@_) },
        config  => '<swish><foo>bar</foo></swish>'
    ),
    "new s3"
);

#diag( $s3->dump );

my $r = 0;

leaks_cmp_ok {
    while ( $r < 100 ) {
        ok( $r += $s3->parse("t/test.html"), "parse HTML" );

        #diag("r = $r");
    }
}
'<', 1;

leaks_cmp_ok {
    while ( $r < 200 ) {
        ok( $r += $s3->parse("t/test.xml"), "parse XML" );

        #diag("r = $r");
    }
}
'<', 1;

sub myhandler {
    my $data = shift;
    my %doc;
    my $metas = $data->metanames;

    for my $m ( keys %$metas ) {
        $doc{$m} = join( "\n", @{ $metas->{$m} } );
    }

}
