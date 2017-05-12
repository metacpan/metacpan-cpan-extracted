#!./perl

use strict;
use warnings;

use String::Interpolate;

print "1..28\n";

my $testno;

sub t ($) {
    print "not " unless shift;
    print "ok ",++$testno,"\n";
}

my $i = String::Interpolate->new;

'DOL1,DOL2' =~ /(.*),(.*)/;

local $_ = 'US';
local %_ = ( R => '_R' );

our($A) = 'A';
our(@A) = ( 'A0', 'A1' );
our(%B) = ( X => 'BX', Y => 'BY' ); keys %B;

t( $i->('$_ $_{R} $1 $2 $A $A[0] $A[1] $B{X} $B{Y}\n') eq 
    "US _R DOL1 DOL2 A A0 A1 BX BY\n");	

$i->( { a => \$A, b => 'B' }, { a => \@A, b => \%B } );

t($i->exec('$_ $_{R} $1 $2 $a @a $a[0] $b{X} $b') eq 
    "US _R DOL1 DOL2 A A0 A1 A0 BX B");	

$i->{b}{C} = 'bc';

t( $B{C} eq 'bc');

$i->{REV} = sub ($) { reverse @_ };
$i->{LC} = sub { lc shift };
$i->{L} = sub () { 'lit' };
$i->[1] = 'd1';
$A = 'aa';

t($i->exec('$a $REV{FOO} $LC{BAR} $L $1 $2 $::A $b{C}') eq 
    "aa OOF bar lit d1  aa bc");	

t(@{$i->positionals} == 1 && $i->positionals->[0] eq 'd1');

$i->positionals->[1] = 'd2';

t("$i" eq "aa OOF bar lit d1 d2 aa bc");	

my @p = ('D1');
$i->positionals = \@p;

$i->[2] = 'D2';

t($p[1] eq 'D2');

$i->safe;

t($i eq 'aa OOF bar lit D1 D2  bc');

t($i->({ Z => 1 },'$Z $a') eq '1 ');

undef $i->positionals;

t($i->('$1') eq 'DOL1');

# Test the various ways of specifying package

no warnings 'once';

t($i->(*FOO1,'@{[ __PACKAGE__ ]}') eq 'FOO1');
t($i->(\*FOO2) eq 'FOO2');
t($i->(*FOO3::) eq 'FOO3');
t($i->package('FOO4')->() eq 'FOO4');

# Test the various ways of specifying pragmas

for ( 'symbols', 'underscore' ) {
    my $method = "unsafe_$_";

    t( ! defined $$i->{$method} );

    $i->$method;
    t( $$i->{$method} );
    
    $i->$method(0);
    t( ! $$i->{$method} );
    
    $i->$method(1);
    t( $$i->{$method} );
    
    $i->(\ "SAFE \U$_");
    t( ! $$i->{$method} );
    
    $i->pragma("\U$method");
    t( $$i->{$method} );
    
    $i->pragma("NO UNSAFE \U$_");
    t( ! $$i->{$method} );
}
