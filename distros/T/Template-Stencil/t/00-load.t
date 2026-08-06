#!perl
use 5.016;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Template::Stencil' ) || print "Bail out!\n";
}

diag( "Testing Template::Stencil $Template::Stencil::VERSION, Perl $], $^X" );

my $caps = Template::Stencil::_stencil_built();
my @have;
push @have, 'computed-goto'  if $caps & 0x01;
push @have, 'builtin-expect' if $caps & 0x02;
push @have, 'sse2'           if $caps & 0x04;
push @have, 'sse4.2'         if $caps & 0x08;
push @have, 'avx2'           if $caps & 0x10;
push @have, 'neon'           if $caps & 0x20;
diag( sprintf 'stencil built: 0x%02x (%s)', $caps,
    @have ? join(', ', @have) : 'portable fallbacks only' );
