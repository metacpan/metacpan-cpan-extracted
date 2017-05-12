use strict;
use warnings;

use DBIx::Connection;
use Test::More tests => 4;

my $class;


BEGIN {
    $class = 'Test::DBUnit::Generator';
    use_ok($class);
}

sub dataset_ok {
    my @args = @_;
    return @args;
}


SKIP: {
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 3)
        unless $ENV{DB_TEST_CONNECTION};
     my $connection = DBIx::Connection->new(
        name     => 'test',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
    );

    my %dataset = lc ($connection->dbms_name) eq  'oracle'
    ? (
    tag1 => q{
        SELECT '1' AS col1, '2' AS col2 FROM DUAL
        UNION
        SELECT 'b' AS col1, '3' AS col2 FROM DUAL
    },
    tag2 => q{
        SELECT 'a' AS col1, 'b' AS col2 FROM DUAL
        UNION
        SELECT 'b' AS col1, 'abc<>ew' AS col2 FROM DUAL
        
    }
    ) : (
    tag1 => q{
        SELECT '1' AS col1, '2' AS col2
        UNION
        SELECT 'b' AS col1, '3' AS col2
    },
    tag2 => q{
        SELECT 'a' AS col1, 'b' AS col2
        UNION
        SELECT 'b' AS col1, 'abc<>ew' AS col2
        
    }
    );
   
    my $gen = $class->new(
       connection => $connection,
       datasets => {%dataset}
        
    );

    like($gen->xml_dataset, qr{col1="1"}, "should generate xml dataset");
    my $perl = $gen->dataset;
    my @data;
    @data = eval("&${perl}");
    is_deeply(\@data, 
    [tag1 => ['col1','1','col2','2'],
    tag1 => ['col1','b','col2','3'],
    tag2 => ['col1','a','col2','b'],
    tag2 => ['col1','b','col2','abc<>ew']] ,'should generate perl dataset');


    ok($gen->schema_validator(
        has_table        => 1,
        has_columns      => 1,
        has_pk           => 1,
        has_fk           => 1,
        has_index        => 1,
    ), 'should generate schema validation');
    
    
}


