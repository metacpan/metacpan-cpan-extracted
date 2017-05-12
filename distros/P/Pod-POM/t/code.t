#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib ../lib );
use Pod::POM::Test;
use Pod::POM::View::Text;

my $DEBUG = 1;

my $text;
{  local $/ = undef;
   $text = <DATA>;
}

ntests(17);

my ($parser, $podpom, @warn, @warnings);
my ($h1, $code);
my $textview = Pod::POM::View::Text->new();

$parser = Pod::POM->new( );
$podpom = $parser->parse_text( $text );
assert( $podpom );

$h1 = $podpom->head1();
match( scalar @$h1, 3 );
match( $textview->print($h1->[0]->title()), 'NAME' );

$code = $podpom->code();
ok( ! @$code );

$parser = Pod::POM->new( code => 1 );
$podpom = $parser->parse_text( $text );
assert( $podpom );
ok( $parser->{ CODE } == 1 );

$h1 = $podpom->head1();
match( scalar @$h1, 3 );
match( $textview->print($h1->[0]->title()), 'NAME' );

$code = $podpom->code();
ok( defined $code );
match( scalar @$code, 1 );
match( $textview->print($code->[0]->{ text }), "This is some code\n\n" );
match( $code->[0]->{ text }, "This is some code\n\n" );
match( $code->[0], "This is some code\n\n" );

$h1 = $podpom->head1->[1];
assert( $h1 );
$code = $h1->code();
match( scalar @$code, 2 );
match( $textview->print($code->[0]), "Some more code here\n\n" );
match( $textview->print($code->[1]), "even more code\n\n" );


__DATA__
This is some code

=head1 NAME

A test Pod document.

=head1 DESCRIPTION

This document has mixed code/Pod

=cut

Some more code here

=pod

Some more description

=cut

even more code

=head1 SYNOPSIS

    use Blah;

=cut

The end.
