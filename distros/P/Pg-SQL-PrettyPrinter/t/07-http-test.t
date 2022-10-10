#!perl
use Test::More;
use Test::Exception;

use Pg::SQL::PrettyPrinter;

if ( !$ENV{ 'TEST_HTTP' } ) {
    plan skip_all => 'TEST_HTTP env variable not provided. Skipping. To enable, run before tests: export TEST_HTTP=http://127.0.0.1:15283/';
}
elsif ( $ENV{ 'TEST_HTTP' } !~ m{^http://\d{1,3}(?:\.\d{1,3}){3}:[1-9]\d+/$} ) {
    plan skip_all => "TEST_HTTP env variable doesn't look ok. Skipping. To enable, run before tests: export TEST_HTTP=http://127.0.0.1:15283/";
}
else {
    plan tests => 3;
}

my $pp;
lives_ok {
    $pp = Pg::SQL::PrettyPrinter->new(
        sql     => 'select 1',
        service => $ENV{ 'TEST_HTTP' }
    )
}
'Object build works';
lives_ok { $pp->parse() } 'Parsing via http works';
is( $pp->{ 'statements' }->[ 0 ]->as_text(), 'SELECT 1', 'as_text worked' );

