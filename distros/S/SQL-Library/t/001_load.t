#! /usr/bin/perl

use strict ;
use warnings ;
$|++ ;

use Test::More qw( no_plan ) ;

BEGIN { use_ok( 'SQL::Library' ) ; }

my $sql_file = new SQL::Library { lib => 't/sqltest.lib' } ;
ok( defined $sql_file, 'new() returned something' ) ;
ok( $sql_file->isa( 'SQL::Library' ), '...and it\'s the right class' ) ;

my $yaq = <<'EOD' ;
SELECT foo
FROM   bar
WHERE  zoot = 1
EOD

is( $sql_file->retr( 'yet_another_query' ), $yaq,
                     'Retrieved query from library.' ) ;

$sql_file->drop( 'yet_another_query' ) ;
is( $sql_file->retr( 'yet_another_query' ), undef,
                     'Dropped query from library.' ) ;

$sql_file->set( 'foobar_query', $yaq ) ;
is( $sql_file->retr( 'foobar_query' ), $yaq,
                     'Create a new query in the library.' ) ;

$sql_file->set( 'products_in_category', $yaq ) ;
is( $sql_file->retr( 'products_in_category' ), $yaq,
                     'Overwriting query in the library.' ) ;

my @elements = ( 'foobar_query', 'products_in_category' ) ;
is ( join( ':', @elements ), join( ':', sort $sql_file->elements ),
                     'Retrieved list of library entries.' ) ;

my $lib_contents = <<'EOD' ;
[foobar_query]
SELECT foo
FROM   bar
WHERE  zoot = 1

[products_in_category]
SELECT foo
FROM   bar
WHERE  zoot = 1

EOD
is( $sql_file->dump, $lib_contents,
                     'Dumped library contents in INI format.' ) ;

__END__
