#!perl

use 5.010;
use warnings;
use strict;

use Test::More tests => 2;

use Template::Plugin::Package;

use Template;

MAIN: {
    my $tt = Template->new;

    # Verify that the class name is not getting sent to the function when it is called.
    my $template = <<'END';
[% USE foo = Package('Foo') %]
<[% foo.echo %]>
<[% foo.echo() %]>
<[% foo.echo( 12 ) %]>
<[% foo.echo( 'bongo', 'bingo', undef, 143 ) %]>
END

    my $expected = <<'END';
<0: >
<0: >
<1: [12]>
<4: [bongo], [bingo], [], [143]>
END

    my $got;
    my $rc = $tt->process( \$template, {}, \$got );

    # Trim whitespace for comparisons.
    for ( $got, $expected ) {
        s/^\s+//sg;
        s/\s+$//sg;
    }

    ok( $rc, 'Processed OK' );
    is( $got, $expected, 'Matches' );
}


exit 0;


package Foo;

sub echo {
    my $nargs = scalar @_;

    return "$nargs: " . join( ', ', map { "[$_]" } @_ );
}
