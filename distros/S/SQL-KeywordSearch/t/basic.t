#!/usr/bin/perl

use Test::More 'no_plan';
use SQL::KeywordSearch;


{
    my ($sql,@bind) = 
            sql_keyword_search(
	              keywords   => 'cat,brown',
	              columns    => ['pets','colors']
	        );
    is ("X$sql"."X",'X(
(lower(pets) ~ lower(?)
 OR lower(colors) ~ lower(?)
)
 OR 
(lower(pets) ~ lower(?)
 OR lower(colors) ~ lower(?)
)
)
X',"basic test for SQL");
    is_deeply(\@bind,['cat','cat','brown','brown'], 'basic test for bind params');

}
{
    my $test =  'every_column produces expected change';
    my ($sql,@bind) = 
            sql_keyword_search(
	              keywords     => 'cat brown',
	              columns      => ['pets','colors'],
                  every_column => 1,
	        );
    like($sql, qr/AND lower/,$test);
}
{
    my $test = 'every_word produces expected change';
    my ($sql,@bind) = 
            sql_keyword_search(
	              keywords     => 'cat brown',
	              columns      => ['pets','colors'],
                  every_word => 1,
	        );
    like($sql, qr/AND \n/, $test);
}
{
    my $test = 'operator produces expected change';
    my ($sql,@bind) = 
            sql_keyword_search(
	              keywords     => 'cat brown',
	              columns      => ['pets','colors'],
                  operator     => 'REGEXP',
	        );
    like($sql, qr/REGEXP/, $test);
}
{
    my $test = 'interp produces array of expected length';
    my (@sql_interp) = 
            sql_keyword_search(
	              keywords     => 'cat brown',
	              columns      => ['pets','colors'],
                  interp       => 1,
	        );
    is(scalar @sql_interp, 25, $test);
}
