#!perl -Tw

use strict;

use Test::More qw(no_plan);
use SeeAlso::Source qw(serve);
use SeeAlso::Identifier;

use Data::Dumper;

my ($source, $response);

$source = SeeAlso::Source->new;
ok( ! %{ $source->description }, "no description" );
ok( ! defined $source->description("ShortName") , "no description (2)" );

$source->description("ShortName","Foo");
is( $source->description("ShortName") , "Foo", "set description" );
ok( ! defined $source->description("XXX") , "not a description value" );
$source->description("LongName","Foobar");
is( $source->description("LongName"), "Foobar", "set description (2)" );
$source->description("ShortName","doz");
is( $source->description("ShortName"), "doz", "set description (3)" );

$source = SeeAlso::Source->new;
$source->description( "ShortName" => "X", "LongName" => "Y" );
is( $source->description("ShortName"), "X", "set description (4)" );
is( $source->description("LongName"), "Y", "set description (5)" );

my $about = [ $source->about ];
is_deeply( $about, ["X","",""], "about (1)" );

$source = SeeAlso::Source->new( 
    "BaseURL" => "http://example.com", Description => "Hello" 
);
$about = [ $source->about ];
is_deeply( $about, ["","Hello","http://example.com"], "about (2)" );

my $q = sub {
    my $id = shift;
    my $r = SeeAlso::Response->new( $id );
    $r->add("test") if $id->value eq "xxx" or $id->value eq "";
    return $r;
};

$source = SeeAlso::Source->new( $q );

$response = $source->query( SeeAlso::Identifier->new("xxx") );
is( $response->size(), 1, "query method with identifier (1)" );
$response = $source->query( SeeAlso::Identifier->new("yyy") );
is( $response->size(), 0, "query method with identifier (2)" );
$response = $source->query( SeeAlso::Identifier->new("yyy") );
is( $response->size(), 0, "query method with identifier (2)" );
$response = $source->query( SeeAlso::Identifier->new );
is( $response->size(), 1, "query method with empty identifier" );
$response = $source->query( "xxx" );
is( $response->size(), 1, "query method with string as identifier" );

$source = SeeAlso::Source->new( callback => $q, ShortName => "Test" );
is( $source->description("ShortName"), "Test", "ShortName");
is( $source->query( "xxx" )->size, 1, 'callback code' );

$source = SeeAlso::Source->new( callback => $source );
is( $source->query( "xxx" )->size, 1, 'callback object' );

$source = SeeAlso::Source->new( 
    sub { shift }, ("LongName" => "Test source", "ShortName" => "Test") 
);
is( $source->description("ShortName"), "Test", "ShortName");
is( $source->description("LongName"), "Test source", "LongName");

my $descr = $source->description();
is( $descr->{ShortName}, "Test", "ShortName (2)");
is( $descr->{LongName}, "Test source", "LongName (2)");

__END__

# serve
use CGI qw(param);
param('id','xxx');
param('format','seealso');

# TODO: caputure STDOUT and exit
serve( $q );
$source = SeeAlso::Source->new( $q );
my $http = $source->serve;
is_like( $http, qr/^Status.*\["xxx.*/ );
#print $http;
print "---\n";

