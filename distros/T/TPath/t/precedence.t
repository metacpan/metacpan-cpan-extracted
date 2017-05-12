# tests logical precedence

use strict;
use warnings;
use feature 'switch';
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More tests => 10;
use ToyXMLForester;
use ToyXML qw(parse);

my $f = ToyXMLForester->new;

construct(
    vals  => [ 0, 0, 1 ],
    ops   => [qw(& ||)],
    group => 'right',
    expected => [ 1, 0 ],
);

construct(
    vals  => [ 0, 0, 1 ],
    ops   => [qw(& ;)],
    group => 'right',
    expected => [ 1, 0 ],
);

construct(
    vals  => [ 1, 0, 1 ],
    ops   => [qw(; ||)],
    group => 'right',
    expected => [ 1, 0 ],
);
construct(
    vals  => [ 1, 0, 0 ],
    ops   => [qw(|| &)],
    group => 'left',
    expected => [ 1, 0 ],
);

construct(
    vals  => [ 1, 0, 0 ],
    ops   => [qw(; &)],
    group => 'left',
    expected => [ 1, 0 ],
);

done_testing();

sub construct {
    my %opts = @_;
    my $text = construct_xml( $opts{vals} );
    my $xml  = parse($text);
    my $p1   = construct_path( $opts{ops}, 0 );
    my $p2   = construct_path( $opts{ops}, $opts{group} );
    my $e    = $f->path($p1)->select($xml);
    ok(
        ( $opts{expected}[0] ? defined $e : !defined $e ),
        "received expected with $p1 from $text"
    );
    $e = $f->path($p2)->select($xml);
    ok(
        ( $opts{expected}[1] ? defined $e : !defined $e ),
        "received expected with $p2 from $text"
    );
}

sub construct_xml {
    my $vals = shift;
    my $xml  = '<a';
    $xml .= ' b="1"' if $vals->[0];
    $xml .= ' c="1"' if $vals->[1];
    $xml .= ' d="1"' if $vals->[2];
    $xml .= '/>';
    return $xml;
}

sub construct_path {
    my ( $ops, $group ) = @_;
    $group //= '';
    my $path  = '//*[';
    my @parts = (
        ( $group eq 'left' ? '(' : () ), op('b'),
        $ops->[0], ( $group eq 'right' ? '(' : () ),
        op('c'), ( $group eq 'left' ? ')' : () ),
        $ops->[1], op('d'),
        ( $group eq 'right' ? ')' : () ),
    );
    $path .= join ' ', @parts;
    $path .= ']';
    return $path;
}

sub op {
    my $att = shift;
    return '@attr("' . $att . '")';
}
