#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More; 
use Object::LocalVars qw(); 
use Scalar::Util qw( refaddr );
use t::Common;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

my $getsetclass = "t::Object::Props::AltStyleGetSet";
my $setclass    = "t::Object::Props::AltStyleSet";
my $getclass    = "t::Object::Props::AltStyleGet";
my $sameclass   = "t::Object::Props::AltStyleSame";

my %prefixes_of = (
    $getsetclass => { get => 'grab',    set => 'hurl' },
    $setclass    => { get => q{},       set => 'hurl' },
    $getclass    => { get => 'grab',    set => 'set_' },
    $sameclass   => { get => q{},       set => q{}    },
);

my @props = qw( name color );

plan tests => 1 + keys( %prefixes_of )
                * ( TC() + @props * ( TA() + 3 ) + 2 );

eval { Object::LocalVars->accessor_style( get => "Get", set => "Set" ) };
my $err = $@;
like( $err, qr/\QMethod accessor_style() requires a hash reference/,
    "throwing error on bad args to accessor_style"
);

my %objs = map { $_ => test_constructor($_) } sort keys %prefixes_of;

for my $class ( sort keys %objs ) {
    SKIP: {
        my $o = $objs{ $class };
        ok( $o, "Testing a $class object..." );

        skip "because we don't have a $class object", 
            TA() * @props +7 if not $o;
            
        for my $p ( @props ) {
            no strict 'refs';
            ok( defined *{"${class}::DATA::$p"}{HASH},
                "... registering '$p' in the data hash" );
        }

        test_accessors( $o, $_, $prefixes_of{ $class } ) for @props;

        my $addr = refaddr $o;

        for my $p ( @props ) {
            no strict 'refs';
            ok( exists ${"${class}::DATA::$p"}{$addr}, 
                "... finding '$p' in the data hash" );
        }
        
        $o = undef;
        $objs{$class} = undef;

        ok( ! defined $o, "... releasing object reference" );
        
        for my $p ( @props ) {
            no strict 'refs';
            ok( ! exists ${"${class}::DATA::$p"}{$addr}, 
                "... cleaning up '$p' data" );
        }
    }
}

