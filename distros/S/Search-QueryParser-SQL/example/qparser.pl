#!/usr/bin/perl
use strict;
use warnings;
use Data::Dump qw( dump );
use Getopt::Long;
use Pod::Usage;
use Search::QueryParser::SQL;

my ( $help, $test, $debug, $columns, $implicit_and );
GetOptions(
    'help'         => \$help,
    'test'         => \$test,
    'debug'        => \$debug,
    'columns=s'    => \$columns,
    'implicit_and' => \$implicit_and,
) or pod2usage(2);
pod2usage(1) if $help;

my @q = @ARGV;
$columns ||= 'foo';

my $parser = Search::QueryParser::SQL->new(
    columns => [ split( /[\ \,]+/, $columns ) ], );

my $query = $parser->parse( join( ' ', @q ), $implicit_and );

print "SQL: $query\n";
print "DBI: " . dump( $query->dbi ) . "\n";
print "RDBO: " . dump( $query->rdbo ) . "\n";

