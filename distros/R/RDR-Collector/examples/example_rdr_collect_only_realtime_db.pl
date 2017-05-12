#!/usr/bin/perl

use strict;
use RDR::Collector;
use IO::File;
use DBI;
use Time::localtime;

# This has been tested to support approx 2100 RDRs a second.
# The main issue will be database speed. Testing shows a standard
# MySQL InnoDB with simple one line inserts can do 9000 per second so
# this will be any bottleneck.

# this example collects the SubscriberUsage RDRs and puts them into a table.

# the table is attempted to be create on start up, table name 'subscriber_usage'
# the database IP Is 127.0.0.1 ( localhost )
# the database name is rdr_collection
# the database username is rdr
# the database password is hello

my $current_table_name = "subscriber_usage";
my $db_handle;

eval {
        local $SIG{ALRM} = sub { die "Broken"; };
        alarm (5);
        $db_handle = DBI->connect(
                "DBI:mysql:database=rdr_collection;host=127.0.0.1;port=3306",
                "rdr",
                "hello",
               { RaiseError => 0, PrintError => 1 });
        alarm 0;
    };

if ( !$db_handle ) { print "Database not available.\n"; exit(0); }

&build_accounting_table( $db_handle, $current_table_name);
my ( $find_query, $insert_query, $update_query ) = prepare_sql_handles ( $db_handle, $current_table_name );

my $rdr_client = new RDR::Collector(
			[
			ServerIP => '80.194.79.218',
			ServerPort => '33130',
			Timeout => 2,
			DataHandler => \&collect_data,
			DatabaseHandle => $db_handle,
			DatabaseFind => $find_query,
			DatabaseInsert => $insert_query,
			DatabaseUpdate => $update_query,
			]
			);

# Setup the local RDR listener
my $status = $rdr_client->connect();

# If we could not listen tell us why.
if ( !$status )
	{
	print "Status was '".$rdr_client->return_status()."'\n";
	print "Error was '".$rdr_client->return_error()."'\n";
	exit(0);
	}

# Now just wait for RDR data.
$rdr_client->check_data_available();

exit(0);

# This routine is called from DataHandler when the module
# instance is initialised.
# 4 parameters are returned, internal ref, remote IP, remote Port and 
# the raw data
sub collect_data
{
my ( $glob ) = shift;
my ( $remote_ip ) = shift;
my ( $remote_port ) = shift;
my ( $data ) = shift;

my $debug = 0;

my $attribute_line;
my $data_line;
next unless ${$data}{'RDR_Record'}=~/^SubscriberUsage$/i;

my $find_query = ${$glob}{'DatabaseFind'};
my $insert_query = ${$glob}{'DatabaseInsert'};
my $update_query = ${$glob}{'DatabaseUpdate'};

# This makes the subcriber_id field only be an IP address. It can have
# both a @ and _ seperating the IP from other elements.
if ( ${$data}{'subscriber_id'}=~/\@$+/g )
	{ ${$data}{'subscriber_id'}=(split(/\@/,${$data}{'subscriber_id'}))[0]; }
if ( ${$data}{'subscriber_id'}=~/\_$+/g )
	{ ${$data}{'subscriber_id'}=(split(/\_/,${$data}{'subscriber_id'}))[1]; }


$find_query->execute( ${$data}{'subscriber_id'} , ${$data}{'service_usage_counter_id'},
   		localtime->min(),
		localtime->hour(),
		localtime->mday(),
		localtime->mon(),
		(localtime->year()+1900) );

my ($rows_returned)= $find_query->rows();

if ( $rows_returned==0 )
	{ &create_new_entry ( $db_handle, $data, $insert_query, $debug ); }

if ( $rows_returned>=1 )
	{
	my $information = $find_query->fetchrow_hashref;
	&update_current_entry ( $db_handle, $data, $information, $update_query,$debug );
	}
}

sub prepare_sql_handles
{
my ( $handle, $table_name ) = @_;

my $find_query = qq "
                select
                        subscriber_name,
                        subscriber_group,
                        subscriber_up_octets,
                        subscriber_down_octets
                from
                        `$table_name`
                where
                        subscriber_name=? and
			subscriber_group=? and
			subscriber_minute=? and
			subscriber_hour=? and
			subscriber_day=? and
			subscriber_month=? and
			subscriber_year=?
                        ";

#print "Find query is \n$find_query\n";

my $find_prepared = $handle->prepare($find_query);

my $create_query = qq "
                insert into `$table_name` (
                        subscriber_name,
			subscriber_group,
			subscriber_up_octets,
			subscriber_down_octets,
			subscriber_minute,
			subscriber_hour,
			subscriber_day,
			subscriber_month,
			subscriber_year
                                )
                        values ( ?,?,?,?,?,?,?,?,? )
                        ";

#print "Create query is\n$create_query\n";

my $insert_prepared = $handle->prepare($create_query);

my $update_query = qq "
                update `$table_name`
                        set
                                subscriber_up_octets=?,
                                subscriber_down_octets=?
                        where
                                subscriber_name=? and
                                subscriber_group=? and
				subscriber_minute=? and
				subscriber_hour=? and
				subscriber_day=? and
				subscriber_month=? and
				subscriber_year=?
                                ";

my $update_prepared = $handle->prepare($update_query);

return ( $find_prepared, $insert_prepared, $update_prepared );
}

sub build_accounting_table
{
my ( $handle, $table_name ) = @_;

my $create_table = qq "

 CREATE TABLE `$table_name` (
  `subscriber_name` varchar(255) NOT NULL default '',
  `subscriber_group` bigint(20) unsigned default '0',
  `subscriber_up_octets` bigint(20) unsigned default '0',
  `subscriber_down_octets` bigint(20) unsigned default '0',
  `subscriber_minute` int unsigned default '0',
  `subscriber_hour` int unsigned default '0',
  `subscriber_day` int unsigned default '0',
  `subscriber_month` int unsigned default '0',
  `subscriber_year` int unsigned default '0',
  PRIMARY KEY  (`subscriber_name`,`subscriber_group`,`subscriber_minute`,`subscriber_hour`,`subscriber_day`,`subscriber_month`,`subscriber_year`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1

";

$handle->do($create_table);

return 1;
}

sub create_new_entry
{
my ( $db_handle, $data, $insert_query, $debug ) =@_;

$insert_query->execute( ${$data}{'subscriber_id'},
                        ${$data}{'service_usage_counter_id'},
                        ${$data}{'upstream_volume'},
                        ${$data}{'downstream_volume'},
			localtime->min(),
			localtime->hour(),
			localtime->mday(),
			localtime->mon(),
			(localtime->year()+1900),
                        );
return 1;
}

sub update_current_entry
{
my ( $db_handle, $data, $db_information, $update_query, $debug ) =@_;

my $current_in_pkts = ${$data}{'upstream_volume'};
my $current_out_pkts = ${$data}{'downstream_volume'};

${$db_information}{'subscriber_up_octets'}+=$current_in_pkts;
${$db_information}{'subscriber_down_octets'}+=$current_out_pkts;

$update_query->execute (
			${$db_information}{'subscriber_up_octets'},
			${$db_information}{'subscriber_down_octets'},
                        ${$data}{'subscriber_id'},
			${$data}{'service_usage_counter_id'},
			localtime->min(),
			localtime->hour(),
			localtime->mday(),
			localtime->mon(),
			(localtime->year()+1900),
                        );
return 1;
}


