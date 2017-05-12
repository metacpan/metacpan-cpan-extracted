#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR     = './t/data/pass_variables';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;

my $string;
my $vars = { test => bless({}, 'Test'), foo => bless({}, 'Foo') };

$string = Petal->new( 'replace.html' )->process( $vars );
like( $string, qr/Object 0: Foo/, "foo (petal:replace)" );
like( $string, qr/Object 1: Foo/, "foo (petal:replace)" );
like( $string, qr/Object 2: Bar/, "bar (petal:replace)" );
like( $string, qr/Object 3: Foo/, "foo (?var?)" );
like( $string, qr/Object 4: Bar/, "bar (?var?)" );
#diag( $string );

$string = Petal->new( 'content.html' )->process( $vars );
like( $string, qr/Object 0: .+?Foo/, "foo (petal:content)" );
like( $string, qr/Object 1: .+?Foo/, "foo (petal:content)" );
like( $string, qr/Object 2: .+?Bar/, "bar (petal:content)" );
#diag( $string );

$string = Petal->new( 'set.html' )->process( $vars );
like( $string, qr/Object 0: Foo/, "foo (petal:set)" );
like( $string, qr/Object 1: Foo/, "foo (petal:set)" );
like( $string, qr/Object 2: Foo/, "foo (?var set:?)" );
#diag( $string );

$string = Petal->new( 'if.html' )->process( $vars );
like( $string, qr/Object 0: Foo/, "foo (petal:if)" );
like( $string, qr/Object 1: Foo/, "foo (petal:if)" );
like( $string, qr/Object 2: Foo/, "foo (?if?)" );
#diag( $string );

$string = Petal->new( 'attributes.html' )->process( $vars );
like( $string, qr/Object 0: .+?Foo/, "foo (petal:attributes)" );
like( $string, qr/Object 1: .+?Foo/, "foo (petal:attributes)" );
like( $string, qr/Object 2: .+?Bar/, "bar (petal:attributes)" );
#diag( $string );

$string = Petal->new( 'repeat.html' )->process( $vars );
like( $string, qr/Object 1: Foo/, "baz (petal:if)" );
like( $string, qr/Object 2: Foo/, "baz (petal:if)" );
#diag( $string );

$string = Petal->new( 'no_arguments.html' )->process( $vars );
like( $string, qr/No arguments passed/, "no args passed" );
#diag( $string );


package Test;
sub object_type {
    my $self = shift;
    my $obj  = shift;
    return ref($obj);
}

sub sub_test { bless {}, 'Test'; }

sub list {
    return [ shift->object_type( shift ) ];
}

sub no_arguments {
    my $self = shift;
    my $new  = bless {}, 'Test';
    $new->{no_args} = 1 unless (@_);
    return $new;
}

sub got_no_arguments {
    my $self = shift;
    return $self->{no_args};
}

package Foo;
sub bar { bless {}, 'Bar'; }
