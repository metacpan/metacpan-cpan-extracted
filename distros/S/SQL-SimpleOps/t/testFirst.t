#!/usr/bin/perl
#
## file t/testFirst.t
#
## CoryRight (C) - Carlos Celso
#

## load external libs

use Getopt::Long;
use SQL::SimpleOps;
use Pod::Usage;
use Test::More;

our $VERSION = "2023.284.1";

BEGIN{ use_ok('SQL::SimpleOps'); };

## defaults values

our $PARM_DB = "test_db";
our $PARM_DBFILE = "/tmp/test_db.db";	# for database im memory use: ":memory:" 
our $PARM_SCHEMA = "test_schema";
our $PARM_SERVER = "localhost";
our $PARM_USER = "user_update";
our $PARM_PASSWORD = "password_update";

## help or doit

(@ARGV) ?
	&my_init() :
	note("$0 -drive=[driver] -db=[db] -schema=[sch] -server=[host] -port=[port] -user=[user] -password=[pwd]");

done_testing();	# test done
exit(0);

## test starter

sub my_init()
{
	  ## parsing options

	  our $get = new Getopt::Long::Parser;
	  $get->configure("pass_through");
	  $get->getoptions
	  (
		 'driver=s' => \$PARM_DRIVER,
		 'db=s' => \$PARM_DB,
		 'dbfile=s' => \$PARM_DBFILE,
		 'schema=s' => \$PARM_SCHEMA,
		 'server=s' => \$PARM_SERVER,
		 'port=s' => \$PARM_PORT,
		 'user=s' => \$PARM_USER,
		 'password=s' => \$PARM_PASSWORD,
	  );

	  ## loading SQL::SimpleOps module
	  ## remember: the defauls values por RaiseError and PrintError is ZERO

	  our $mymod = new SQL::SimpleOps
	  (
		 driver => $PARM_DRIVER,
		 db => $PARM_DB,
		 dbfile => $PARM_DBFILE,
		 schema => $PARM_SCHEMA,
		 server => $PARM_SERVER,
		 port => $PARM_PORT,
		 login => $PARM_USER,
		 password => $PARM_PASSWORD,
		 tables =>
		 {
			my_master =>	## sets aliases entries for master table
			{
			   name => "master",
			   cols =>
			   {
				  my_i_m_id   => 'i_m_id',
				  my_s_m_code => 's_m_code',
				  my_s_m_name => 's_m_name',
				  my_s_m_desc => 's_m_desc',
			   },
			},
			my_slave =>	## sets aliases entries for slave table
			{
			   name => "slave",
			   cols =>
			   {
				  my_i_s_id   => 'i_s_id',
				  my_s_m_code => 's_m_code',
				  my_s_s_code => 's_s_code',
				  my_s_s_name => 's_s_name',
				  my_s_s_desc => 's_s_desc',
			   },
			},
		 }
	  );
	  
	  ## do it

	  &my_upload();		# initialize the tables
	  &my_get_master();	# test master table
	  &my_get_slave();	# test slave table
	  &my_get_merge();	# test merge between master and slave

	  ## finishing test

	  $mymod->Close();	# do not forgot me
}

## my upload data
## remove previous data
## creating dynamic data into the master and slave table

sub my_upload()
{
    ## remove previous data

    $mymod->Delete( table => "my_master", force => 1, notfound => 1 );
    $mymod->Delete( table => "my_slave", force => 1, notfound => 1 );

    ## initializing master/slave table

    foreach my $code(0..9)
    {
        my $er=0;
        my $ok=0;

        ## inserting data into master

        $code = sprintf("%04i",$code);
        $mymod->Insert
        (
           table => "my_master",
           fields =>
           {
              my_s_m_code => "master_".$code,
              my_s_m_name => "name_".$code,
              my_s_m_desc => "description_".$code,
           }
        );

        ($mymod->getRC()) ? $er++ : $ok++;

        ## inserting data into slave based master data

        foreach my $subcode(10..19)
        {
           $subcode = sprintf("%04i",$subcode);
           $mymod->Insert
           (
              table => "my_slave",
              fields =>
              {
                 my_s_m_code => "master_".$code,
                 my_s_s_code => "slave_".$subcode,
                 my_s_s_name => "name_".$subcode,
                 my_s_s_desc => "description_".$subcode,
              }
           );

           ($mymod->getRC()) ? $er++ : $ok++;
        }

        ## shown counters

        fail("Number of ".$er." errors (master+slave), Code ".$code) if ($er);
        pass("Number of ".$ok." successful (master+slave), Code ".$code) if ($ok);
    }
}

## simple test of load master data
## load all master data into buffer

sub my_get_master()
{
    my @buffer;
    $mymod->Select
    (
       table => "my_master",
       buffer => \@buffer,
       order_by => "my_i_m_id",
    );

    ## test number of loaded rows

    ok($mymod->getRows()==10,"Master select, rows ".$mymod->getRows());
}

## simple test of load slave data
## load all slave data into buffer

sub my_get_slave()
{
    my @buffer;
    $mymod->Select
    (
       table => "my_slave",
       buffer => \@buffer,
       order_by => "my_i_s_id",
    );

    ## test number of loaded rows

    ok($mymod->getRows()==100,"Slave select, rows ".$mymod->getRows());
}

## simple test of merge between master and slave tables

sub my_get_merge()
{
    my @buffer;

    $mymod->Select
    (
       table => [ "my_master","my_slave" ],
       buffer => \@buffer,
       fields => [ "my_master.my_s_m_code", "my_slave.my_s_s_code" ],
    );

    ## test number of loaded rows

    ok($mymod->getRows()==1000,"Master/Slave merge-1, rows ".$mymod->getRows());

    $mymod->Select
    (
       table => [ "my_master","my_slave" ],
       buffer => \@buffer,
       fields => [ "my_master.my_s_m_code", "my_slave.my_s_s_code" ],
       where =>
       [
          "my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
       ]
    );

    ## test number of loaded rows

    ok($mymod->getRows()==100,"Master/Slave merge-2, rows ".$mymod->getRows());

    $mymod->Select
    (
       table => [ "my_master","my_slave" ],
       buffer => \@buffer,
       fields => [ "my_master.my_s_m_code", "my_slave.my_s_s_code" ],
       where =>
       [
          "my_master.my_s_m_code" => [ "!", "\\my_slave.my_s_m_code" ],
       ]
    );

    ## test number of loaded rows

    ok($mymod->getRows()==900,"Master/Slave merge-3, rows ".$mymod->getRows());
}

__END__
