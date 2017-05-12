#!/usr/bin/perl
use strict;
use warnings;

use Test::InDistDir;

use Test::More tests => 3;

use Template;
use Template::AutoFilter;

my $templ_1 = "[% x = [ 1, 2 ] %]  [% x.join(', ') %]";
my $templ_2 = "[% x = [ 1, 2 ] | html %]  [% x.join(', ') | html %]";
my $templ_3 = "[% SET x = [ 1, 2 ] %]  [% x.join(', ') %]";

for ( $templ_1, $templ_2, $templ_3 ) {
    my $wanted = process( 'Template', $_ );
    my $out = process( 'Template::AutoFilter', $_ );
    is( $out, $wanted );
}

sub process {
    my ( $class, $tmpl ) = @_;
    $class->new->process( \$tmpl, {}, \my $out );
    $out =~ s/0x[\da-f]+/hex/;
    return $out;
}
