# vim:filetype=perl
use strict;
use warnings;
use Test::More qw( no_plan );
use FindBin qw( $Bin );
use Data::Dumper;
use File::Path;
use DBD::SQLite;
use DBI;

use lib 'lib';

my $create_sql = <<EOF;
DROP TABLE IF EXISTS capability;
CREATE TABLE capability (
        name char(255) NOT NULL default '',
        value char(255) default '',
        groupid char(255) NOT NULL default '',
        deviceid char(255) NOT NULL default '',
        ts DATETIME default CURRENT_TIMESTAMP
        );
CREATE INDEX IF NOT EXISTS groupid ON capability (groupid);
CREATE INDEX IF NOT EXISTS name_deviceid ON capability (name,deviceid);
DROP TABLE IF EXISTS device;
CREATE TABLE device (
        user_agent varchar(255) NOT NULL default '',
        actual_device_root char(255),
        id char(255) NOT NULL default '',
        fall_back char(255) NOT NULL default '',
        ts DATETIME default CURRENT_TIMESTAMP
        );
CREATE INDEX IF NOT EXISTS user_agent ON device (user_agent);
CREATE INDEX IF NOT EXISTS id ON device (id);
EOF

my $long_user_agent = {
    string => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; InfoPath.2; Creative ZENcast v2.01.01)",
    canonical => "Mozilla/4.0",
};

$| = 1;
ok ( require Mobile::Wurfl, "require Mobile::Wurfl" ); 
my $wurfl = eval { Mobile::Wurfl->new(
    wurfl_home => "/tmp/",
    db_descriptor => "dbi:SQLite:dbname=/tmp/wurfl.db",
    db_username => '',
    db_password => '',
    # verbose => 2,
); };

ok( $wurfl && ! $@, "create Mobile::Wurfl object: $@" );
exit unless $wurfl;
eval { $wurfl->create_tables( $create_sql ) };
ok( ! $@ , "create db tables: $@" );
my $updated = eval { $wurfl->update(); };
ok( ! $@ , "update: $@" );
ok( $updated, "updated" );
ok( ! $wurfl->update(), "no update if not required" );
ok( ! $wurfl->rebuild_tables(), "no rebuild_tables if not required" );
ok( ! $wurfl->get_wurfl(), "no get_wurfl if not required" );
my @groups = sort $wurfl->groups();
my %capabilities;
for my $group ( @groups )
{
    for ( $wurfl->capabilities( $group ) )
    {
        $capabilities{$_}++;
    }
}
my @capabilities = $wurfl->capabilities();
is_deeply( [ sort @capabilities ], [ sort keys %capabilities ], "capabilities list" );
my @devices = $wurfl->devices();
my $device = $devices[int(rand(@devices))];
my $ua = $wurfl->canonical_ua( $device->{user_agent} );
is( $device->{user_agent}, $ua, "ua lookup" );
my $cua = $wurfl->canonical_ua( "$device->{user_agent}/ random stuff ..." );
is( $device->{user_agent}, $cua, "canonical ua lookup" );
$cua = $wurfl->canonical_ua( $long_user_agent->{string} );
is( $long_user_agent->{canonical}, $cua, "canonical_ua deep recursion" );
my $deviceid = $wurfl->deviceid( $device->{user_agent} );
is( $device->{id}, $deviceid, "deviceid ua lookup" );
for my $cap ( @capabilities )
{
    my $val = $wurfl->lookup( $ua, $cap );
    ok( defined $val, "lookup $cap" );
}
eval { $wurfl->cleanup() };
ok( ! $@ , "cleanup: $@" );
