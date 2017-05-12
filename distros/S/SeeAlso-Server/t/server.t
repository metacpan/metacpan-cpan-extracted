#!perl -Tw

use strict;

use Test::More qw(no_plan);

use SeeAlso::Server;
use SeeAlso::Response;
use Data::Dumper;
use CGI;

sub UCnormalizedID { my $id = shift; return SeeAlso::Response->new( uc($id->normalized()) ); }
my $cgi;

my $s = SeeAlso::Server->new( cgi => CGI->new() );
my $r = SeeAlso::Response->new();

open XML, "t/listFormats200.xml";
my $xml200 = join('', <XML>);
ok( $s->listFormats($r) eq $xml200, 'listFormats => 200');
close XML;

$r = SeeAlso::Response->new("xyz");

open XML, "t/listFormats404.xml";
my $xml404 = join('', <XML>);
ok( $s->listFormats($r) eq $xml404, 'listFormats => 404');
close XML;

$r->add("test");

open XML, "t/listFormats300.xml";
my $xml300 = join('', <XML>);
ok( $s->listFormats($r) eq $xml300, 'listFormats => 300');
close XML;

$s = SeeAlso::Server->new( formats => { opensearchdescription => 0 } );
$r = SeeAlso::Response->new();
open XML, "t/listFormats200noosd.xml";
my $xml200noosd = join('', <XML>);
ok( $s->listFormats($r) eq $xml200noosd, 'listFormats => 200 without OpenSearch Description');
close XML;

use SeeAlso::Source;
$s = SeeAlso::Server->new( cgi => CGI->new() );
my $source = SeeAlso::Source->new();
my $identifier = SeeAlso::Identifier->new();
my $http = $s->query($source, $identifier, 'seealso');
ok ( $http =~ /^Status: 200[^\[]+\["",\[\],\[\],\[\]\]$/m, 'Empty response' );

$http = $s->query($source, $identifier, 'foo');
ok ( $http eq $xml200, 'List of formats (because no identifier)');

$source = SeeAlso::Source->new(
    sub { my $id = shift; return SeeAlso::Response->new( $id->normalized() ); }
);
$identifier = SeeAlso::Identifier->new("xyz");

$http = $s->query($source, $identifier, 'seealso');
like( $http , qr/^Status: 200[^\[]+\["xyz",\[\],\[\],\[\]\]$/m, 'No results' );

$http = $s->query($source, $identifier, 'foo');
ok ( $http eq $xml404, 'Result but not right format');

sub query_method {
    my $id = shift;
    my $r = SeeAlso::Response->new( $id->normalized );
    $r->add("test");
    return $r;
}
$source = SeeAlso::Source->new( \&query_method );

$http = $s->query($source, $identifier, 'seealso');
ok( ! $s->errors, 'JSON Results (1)' );
like( $http, qr/^Status: 200[^\[]+\["xyz",\["test"\],\[""\],\[""\]\]$/m, 'JSON Results (2)' );

$http = $s->query($source, $identifier, 'foo');
is ( $http, $xml300, 'Result but not right format');

$http = $s->query($source, $identifier, 'seealso', 'a[1].b');
my $res = '^Status: 200[^\[]+a\[1\]\.b\(\["xyz",\["test"\],\[""\],\[""\]\]\);$';
ok( ! $s->errors, 'JSON Result with callback' );
like( $http, qr/$res/m, 'JSON Result with callback' );

$cgi = CGI->new;
$cgi->param('format'=>'seealso');
$cgi->param('callback'=>'a[1].b');
$http = SeeAlso::Server->new( cgi => $cgi )->query( $source, $identifier );
ok ( $http =~ /$res/m, 'JSON Result with callback (query_seealso_server)' );

$http = SeeAlso::Server->new( cgi => $cgi )->query( \&query_method, $identifier );
ok ( $http =~ /$res/m, 'JSON Result with callback (query_seealso_server, sub)' );

$http =  SeeAlso::Server->new( cgi => $cgi, description => ["ShortName"=>"foo"] )->query( \&query_method, $identifier );
ok ( $http =~ /$res/m, 'JSON Result with callback (query_seealso_server, sub and description)' );

$http = $s->query($source, $identifier, 'seealso', '{');
ok ( $http =~ /^Status: 400/, 'invalid callback' );

$s = SeeAlso::Server->new( expires => "+1d" );
$http = $s->query( $source, new SeeAlso::Identifier("abc"), "seealso" );
ok ( $http =~ /Expires:/, 'Expires header');

sub quc {
    my $id = shift;
    return "UC:" . uc($id->value);
}
$s = SeeAlso::Server->new( formats => { "uc" => { type => "text/plain", method => \&quc } } );
$http = $s->query( $source, new SeeAlso::Identifier("abc"), "uc" );
ok ( $http =~ /UC:ABC/, "additional unAPI format" );

# function as identifier validator
$cgi = CGI->new;
$cgi->param('format'=>'seealso');
$cgi->param('id'=>'8');
$s = SeeAlso::Server->new( cgi => $cgi );
$http = $s->query( \&UCnormalizedID, sub { return $_[0] * 2; } );
like( $http, qr/\["16",\[\],\[\],\[\]\]/, "code as id validator (valid)" );
$http = $s->query( \&UCnormalizedID, sub { return undef; } );
like( $http, qr/\["",\[\],\[\],\[\]\]/, "code as id validator (invalid)" );
$cgi->param('id'=>'low');
$http = $s->query( sub { return SeeAlso::Response->new( $_[0] ); }, sub { return uc($_[0]); } );
like( $http, qr/\["LOW",\[\],\[\],\[\]\]/, "code as id validator (valid 2)" );

# check error handler
$source = SeeAlso::Source->new( sub { 1 / int(shift->value); } );

$s->query($source, "a", "seealso");
# Argument "a" isn\'t numeric 
# Illegal division by zero
my @errors = $s->errors;
is( scalar @errors, 2, "error handler (0)" );
like( $errors[0], qr/Argument "a" isn't numeric/, "error handler (1)" );
like( $errors[1], qr/Illegal division by zero/, "error handler (2)" );

$s->query($source, "0", "seealso");
@errors = $s->errors;
like( $errors[0], qr/^Illegal division by zero/, "error handler");

# return empty result with uppercase identifier
$s = SeeAlso::Server->new();
$http = $s->query( \&UCnormalizedID, "abc", "seealso" );
like( $http, qr/\["ABC",\[\],\[\],\[\]\]/, "code as source" );

# use another identifier type
$s = SeeAlso::Server->new( idtype => 'SeeAlso::Identifier::ISBN' );
$r = $s->query( sub { return SeeAlso::Response->new( $_[0] ); }, '978-0-596-52724-2', 'seealso' );
like( $r, qr/urn:isbn:9780596527242/, "idtype" );
