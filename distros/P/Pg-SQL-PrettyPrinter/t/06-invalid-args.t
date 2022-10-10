#!perl
use Test::More tests => 12;
use Test::Exception;

use Pg::SQL::PrettyPrinter;

throws_ok { my $pp = Pg::SQL::PrettyPrinter->new() } qr/SQL query was not provided/, 'No arguments - caught ok.';
throws_ok { my $pp = Pg::SQL::PrettyPrinter->new( sql => 'select 1' ) } qr/You have to provide either service or struct/, 'No service/struct.';
throws_ok { my $pp = Pg::SQL::PrettyPrinter->new( sql => 'select 1', service => '127.0.0.1:80' ) } qr/Invalid syntax for service/,        'Badly formed service';
throws_ok { my $pp = Pg::SQL::PrettyPrinter->new( sql => 'select 1', service => 'http://127.0.0.1:80' ) } qr/Invalid syntax for service/, 'Badly formed service #2';
throws_ok { my $pp = Pg::SQL::PrettyPrinter->new( sql => 'select 1', service => 'http://127.0.0.1:80', struct => {} ) } qr{You should provide only one of service/struct},
    'Both service and struct!';

throws_ok { my $pp = Pg::SQL::PrettyPrinter->new( sql => 'select 1', struct => [] ) } qr{Invalid parse struct}, 'Invalid parse struct!';
throws_ok { my $pp = Pg::SQL::PrettyPrinter->new( sql => 'select 1', struct => '' ) } qr{Invalid parse struct}, 'Invalid parse struct!';
throws_ok { my $pp = Pg::SQL::PrettyPrinter->new( sql => 'select 1', struct => {} ) } qr{Invalid parse struct}, 'Invalid parse struct!';
throws_ok { my $pp = Pg::SQL::PrettyPrinter->new( sql => 'select 1', struct => { 'stmts' => '' } ) } qr{Invalid parse struct}, 'Invalid parse struct!';
throws_ok { my $pp = Pg::SQL::PrettyPrinter->new( sql => 'select 1', struct => { version => 123, 'stmts' => '' } ) } qr{Invalid parse struct}, 'Invalid parse struct!';
throws_ok { my $pp = Pg::SQL::PrettyPrinter->new( sql => 'select 1', struct => { version => 123, 'stmts' => {} } ) } qr{Invalid parse struct}, 'Invalid parse struct!';
throws_ok { my $pp = Pg::SQL::PrettyPrinter->new( sql => 'select 1', struct => { version => 123, 'stmts' => [] } ) } qr{Invalid parse struct}, 'Invalid parse struct!';

