#!/usr/bin/perl -w
use strict;
use warnings;
no warnings 'uninitialized';
use lib qw(t);

use Test::More;
use Params::Util qw(_INSTANCE);
use TestLib qw(connect prove_reqs show_reqs);

my ( $required, $recommended ) = prove_reqs();
my @test_dbds = ( 'SQL::Statement', grep { /^dbd:/i } keys %{$recommended} );

foreach my $test_dbd (@test_dbds)
{
    my $dbh;

    # Test RaiseError for prepare errors
    #
    my %extra_args;
    if ( $test_dbd =~ m/^DBD::/i )
    {
	$extra_args{sql_dialect} = "ANSI";
    }
    $dbh = connect(
                    $test_dbd,
                    {
                       PrintError => 0,
                       RaiseError => 0,
		       %extra_args,
                    }
                  );

    for my $sql(
		split /\n/, <<""
  /* DROP TABLE */
DROP TABLE `foo`
  /* DELETE */
DELETE FROM `foo`
  /* UPDATE */
UPDATE `foo` SET bar = 7
  /* INSERT */
INSERT INTO `foo` (col1,col2,col7) VALUES ( 'baz', 7, NULL )
  /* CREATE TABLE */
CREATE TABLE `foo` ( id INT )
CREATE LOCAL TEMPORARY TABLE `foo` (id INT)
CREATE GLOBAL TEMPORARY TABLE `foo` (id INT)
CREATE TABLE `foo` ( phrase NUMERIC(4,6) )
  /* SELECT COLUMNS */
SELECT id, phrase FROM `foo`
SELECT * FROM `foo`
  /* SET FUNCTIONS */
SELECT MAX(`foo`) FROM bar
  /* ORDER BY */
SELECT * FROM `foo` ORDER BY bar
SELECT * FROM `foo` ORDER BY bar, baz
  /* LIMIT */
SELECT * FROM `foo` LIMIT 5
  /* TABLE NAME ALIASES */
SELECT * FROM `test` as `T1`
  /* PARENS */
SELECT * FROM `ztable` WHERE NOT `data` IN ('one','two')
  /* NOT */
SELECT * FROM `foo` WHERE NOT bar = 'baz' AND bop = 7 OR NOT blat = bar
  /* IN */
SELECT * FROM bar WHERE `foo` IN ('aa','ab','ba','bb')
  /* BETWEEN */
SELECT * FROM bar WHERE `foo` BETWEEN ('aa','bb')

	       ) {
	ok( eval { $dbh->prepare($sql); }, "parse '$sql' using $test_dbd" ) or diag( $dbh->errstr() );
    }
}
done_testing();
