#!/usr/bin/perl
use warnings;
use strict;

package Foo;
our $OK = 1;

sub bar 
{
    my $self = shift;
    if (scalar @_) { $OK = 0 }
    return $self;
}


sub baz
{
    my $self = shift;
    return $self;
}

package main;
use warnings;
use lib ('lib');
use Test::More;
BEGIN {
    eval "use CGI";
    plan skip_all => "CGI required" if $@;
    plan 'no_plan';
}
use Petal;

$|=1;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;

my $cgi = CGI->new();
$cgi->param ('mbox', 'foo');

my $template = new Petal ('method_param.xml');
my $string = $template->process ( cgi => $cgi, foo => bless {}, 'Foo' );

like( $string, qr/foo/,      'foo' );
like( $string, qr/mbox=foo/, 'mbox=foo' );
like( $string, qr/t=foo/,    't=foo' );
like( $string, qr/b=foo/,    'b=foo' );
like( $string, qr/ta=foo/,   'ta=foo' );
