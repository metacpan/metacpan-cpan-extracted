use strict;
use warnings;

use Test::More tests => 6;
use Template;

my $tmpl1 = q{
[% USE xkcd %]
Hello [% name %]
[% xkcd.comic %]
};

my $tmpl2 = q{
[% USE xkcd %]
Hello [% name %]
[% xkcd.comic(20) %]
};

my $tt   = Template->new();
my %vars = ( name => 'Sawyer', PRE_CHOMP => 1, POST_CHOMP => 1 );

{
    my $out;
    my $res = $tt->process( \$tmpl1, \%vars, \$out )
        or BAIL_OUT( $tt->error );

    ok( $res, 'Got result' );
    like( $out, qr/Hello Sawyer/, 'Variables work' );
    like( $out, qr/\.png/,        'Found an image' );
}

{
    my $out;
    my $res = $tt->process( \$tmpl2, \%vars, \$out )
        or BAIL_OUT( $tt->error );

    ok( $res, 'Got result' );
    like( $out, qr/Hello Sawyer/, 'Variables work' );
    like(
        $out,
        qr{https?://imgs\.xkcd\.com/comics/ferret\.jpg},
        'Found an image',
    );
}

