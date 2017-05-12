use strict;
use warnings;

# PostgreSQL DDL compare tool between pg_dump and O::P::TableInfo->desc()
#
# usage: 
# cp eg/config.pl.sample eg/config.pl
# vi eg/config.pl
# ...(edit config to connect your DB)
# prove -l eg/compare.t
#
# NOTE: to set password for pg_dump, use .pgpass file

use Test::More;
use List::MoreUtils qw(any);
use DBI;
use t::Util;
use Test::Differences;
unified_diff;

use Otogiri;
use Otogiri::Plugin;
Otogiri->load_plugin('TableInfo');

my $config = do("eg/config.pl") or die "can't read config: $!";

my $db = Otogiri->new( connect_info => $config->{connect_info} );

for my $table_name ( $db->show_tables() ) {
    next if ( any{ $table_name eq $_ } @{ $config->{exclude_tables} || [] } );

    my $pg_dump = desc_by_pg_dump($db, $table_name);
    my $inspector = $db->desc($table_name);
    eq_or_diff($pg_dump, $inspector) or fail "error in $table_name";
}

done_testing;

