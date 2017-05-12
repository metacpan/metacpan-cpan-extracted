use strict;
use Test::More tests => 19;

BEGIN {
    use_ok( 'Pod::Extract::URI' );
}

my $peu = Pod::Extract::URI->new();
$peu->parse_from_file( 't/pod/details.pod' );
my %details = $peu->uri_details;

my $eg     = 'http://www.example.com/';
my $egport = 'http://www.example.com:80/';
my $goog   = 'http://www.google.com/';

my @uris = sort keys %details;
is_deeply( \@uris, [ $eg, $egport, $goog ] );
is( scalar @{ $details{ $eg } }, 1 );
is( scalar @{ $details{ $egport } }, 1 );
is( scalar @{ $details{ $goog } }, 2 );

$peu = Pod::Extract::URI->new( use_canonical => 1 );
$peu->parse_from_file( 't/pod/details.pod' );
%details = $peu->uri_details;

@uris = sort keys %details;
is_deeply( \@uris, [ $eg, $goog ] );
is( scalar @{ $details{ $eg } }, 2 );
is( scalar @{ $details{ $goog } }, 2 );

my $uri = $details{ $eg }->[ 1 ];
is( ref $uri->{ uri }, "URI::http" );
is( $uri->{ uri }->as_string, "http://www.example.com/" );
is( $uri->{ text }, "http://www.example.com:80/" );
is( $uri->{ original_text }, "http://www.example.com:80/" );
is( $uri->{ line }, 7 );
is( ref $uri->{ para }, "Pod::Paragraph" );

$uri = $details{ $goog }->[ 1 ];
is( $uri->{ text }, "http://www.google.com/" );
is( $uri->{ original_text }, "<URL:http://www.google.com/>" );

$peu = Pod::Extract::URI->new( strip_brackets => 0 );
$peu->parse_from_file( 't/pod/details.pod' );
%details = $peu->uri_details;
@uris = sort keys %details;

is ( scalar keys %details, 4 );
$uri = $details{ "<URL:$goog>" }->[ 0 ];
is( $uri->{ text }, "<URL:http://www.google.com/>" );
is( $uri->{ original_text }, "<URL:http://www.google.com/>" );
