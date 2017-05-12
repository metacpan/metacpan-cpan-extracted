use strict;
use warnings;

use Test::More tests => 28;
use Data::Dump qw( dump );

use_ok('SWISH::3');

ok( my $s3 = SWISH::3->new(
        config  => '<swish><MetaNames><foo /></MetaNames></swish>',
        handler => \&getmeta
    ),
    "new parser"
);

my $r = 0;
while ( $r < 10 ) {
    ok( $r += $s3->parse_file("t/test.html"), "parse HTML" );

    #diag("r = $r");
}
$r = 0;
while ( $r < 10 ) {
    ok( $r += $s3->parse_file("t/test.xml"), "parse XML" );

    #diag("r = $r");
}

sub getmeta {
    my $data = shift;

    #diag(dump($data->metanames));

    #$data->tokens->debug;

}

ok( $s3 = SWISH::3->new(
        config  => '<swish><MetaNames><foo /></MetaNames></swish>',
        handler => \&metacheck
    ),
    "new s3"
);
ok( $s3->parse_file("t/bumper.html"), "parse bumper.html" );

sub metacheck {
    my $data = shift;
    my $meta = $data->metanames;
    my $prop = $data->properties;

    #dump $meta;
    #dump $prop;

    cmp_ok( $meta->{'foo'}->[0], 'eq', 'one two',    "first foo meta" );
    cmp_ok( $meta->{'foo'}->[1], 'eq', 'three four', "second foo meta" );
    cmp_ok(
        $meta->{'swishdefault'}->[0],
        'eq',
        'this is para one',
        "first swishdefault meta"
    );
    cmp_ok(
        $meta->{'swishdefault'}->[1],
        'eq',
        'this is para two',
        "second swishdefault meta"
    );

}
