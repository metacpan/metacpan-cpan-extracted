#!/usr/bin/perl
# File: Pgreet.t
######################################################################
#
#                ** PENGUIN GREETINGS (pgreet) **
#
# Testing script for modules: Pgreet, Pgreet::Config, Pgreet::Error,
#                             Pgreet::CGIUtils, Pgreet::DaemonUtils,
#                             and Pgreet::I18N
#
#  Edouard Lagache, elagache@canebas.org, Copyright (C)  2003-2005
#
# ** This program has been released under GNU GENERAL PUBLIC
# ** LICENSE.  For information, see the COPYING file included
# ** with this code.
#
# For more information and for the latest updates go to the
# Penguin Greetings official web site at:
#
#     http://pgreet.sourceforge.net/
#
# and the SourceForge project page at:
#
#     http://sourceforge.net/projects/pgreet/
#
######################################################################
# $Id: Pgreet.t,v 1.10 2005/04/16 21:48:15 elagache Exp $
#
use Test::More tests => 35;
use File::Temp qw(tempdir);
use File::Basename;
use Cwd 'abs_path';


# Global declarations
our ($TmpDir, $TmpMason, $ErrorMessage, $config_file, $state_file);
our ($template_file, $Pg_config, $Pg_error, $Pg_obj, $Pg_daemon);
our $DateLimit = 90;

our $Test_state_hash = { varstring => "PgTemplateTest=true",
						 hiddenfields =>  "<!-- Templatetest hiddenfields -->",
						 sender_name => "Test Sender Name",
						 sender_email => "test\@PgTemplateTest.org"
					   };

$state_file = "Test_state_file.txt";

# ....... Test setup Subroutines .......

sub make_tmp_dir {
#
# Subroutine to create a temporarily directory
# in which to drop a temporary configuration file
# and create state files.
#
  # Try to create a directory to create test values in.
  unless (($TmpDir = tempdir("PgreetTestingDirXXXX", CLEANUP => 1)) and
		  (-d $TmpDir)
		  ){
	$ErrorMessage = "Cannot create test directory ... Try setting TmpDir";
	return(0);
  }
  return(1);

}

sub create_config_file {
#
# A Perl "here" document containing the bare-bones
# Penguin Greeting configuration file for testing
# the modules.
#
  $config_file = "$TmpDir/pgreet.conf";
  unless (open(CONFIG, ">$config_file")) {
	$ErrorMessage = "Unable to create temporary configuration file";
	return(0);
  }

  print CONFIG << "EOF";
  TestVar = TestValue
  PgreetVar = 3
EOF

	close(CONFIG);
}

sub create_Embperl_file {
#
# A Perl "here" document containing a bare-bones
# Embperl file to be evaluated for testing.
#
  $template_file = "Embperl_template.epl.html";

  unless (open(EMBPERL, ">$TmpDir/$template_file")) {
	$ErrorMessage = "Unable to create temporary configuration file";
	return(0);
  }

  print EMBPERL << "EOF";
  [\$ var \$test \$]
  [- \$test = "A test title" -]
  <html>
  <head>
  <title>[+ \$test +]</title>
  </head>
  <body>
  <h1>[+ \$test +]</h1>
  </body>
  <html>
EOF

	close(EMBPERL);
}

sub create_Mason_file {
#
# A Perl "here" document containing a bare-bones
# Mason file to be evaluated for testing.
#
  $template_file = "Mason_template.mas.html";

  unless (open(MASON, ">$TmpDir/$template_file")) {
	$ErrorMessage = "Unable to create temporary configuration file";
	return(0);
  }

  print MASON << "EOF";
%  my \$test = "A test title";
  <html>
  <head>
  <title><% \$test %></title>
  </head>
  <body>
  <h1><% \$test %></h1>
  </body>
  <html>
EOF

	close(MASON);
}

sub fill_db_file {
#
# Subroutine to fill one Berkeley DB file with a record for testing
# expired cards
#
  my $filename = shift;
  my $old_date = shift;
  my $new_date = shift;
  my %pgreet_DB;

  # Create DB file and fill it with two records
  if ( tie(%pgreet_DB, "DB_File", "$TmpDir/$filename")
	 ) {
	$pgreet_DB{OldRecord} = "datecode=$old_date";
    $pgreet_DB{NewRecord} = "datecode=$new_date";
	untie %pgreet_DB;
  } else {
	  $ErrorMessage = "Cannot create DB file $TmpDir/$filename: $!\n";
	}

}

# Need modules to run this puppy
BEGIN { use_ok( 'Pgreet' ); }
BEGIN { use_ok( 'Pgreet::Config' ); }
BEGIN { use_ok( 'Pgreet::Error' ); }
BEGIN { use_ok( 'Pgreet::CGIUtils'); }
BEGIN { use_ok( 'Pgreet::ExecEmbperl'); } ### Test #05
BEGIN { use_ok( 'Pgreet::DaemonUtils'); }
BEGIN { use_ok ( 'DB_File' ); }

# Create a temporary environment to run tests in
ok(make_tmp_dir() and create_config_file() and create_Embperl_file(),
   "Create temporary Penguin Greetings environment") or
  diag($ErrorMessage);

########## MAIN SCRIPT ###########

{
  my $cgi_script = basename($0);
  my $query = 0;

  ### Create objects for tests
  ok($Pg_config = new Pgreet::Config($config_file),
	 "Create Pgreet::Config object");
  ok($Pg_error = new Pgreet::Error($Pg_config, 'App'), ### Test #10
	 "Create Pgreet::Error object");
  ok($Pg_config->add_error_obj($Pg_error),
	 "Attach Error object to configuration object");
  ok($Pg_obj = new Pgreet($Pg_config, $Pg_error, 'App'),
	 "Create Pgreet object");
  ok($Pg_cgi = new Pgreet::CGIUtils($Pg_config, $cgi_script, $query),
	 "Create Pgreet::CGIUtils object");
  ok($Pg_error->add_cgi_obj($Pg_cgi),
	 "Adding Pgreet::CGIUtils object reference to Pgreet::Error object");
  ok($Pg_daemon = new Pgreet::DaemonUtils($Pg_config, $Pg_error), ### Test #15
	 "Create Pgreet:DaemonUtils object");

  ### Test configuration file access
  is($Pg_config->access('TestVar'), 'TestValue',
	 "Retrieve config variable \'TestVar\'");
  cmp_ok(($Pg_config->access('PgreetVar', 5) and
		  $Pg_config->access('PgreetVar')),
		 '==', 5,
		 "Set \'PgreetVar\' to 5");

  ### Test creation and access of state file
  my $test_file_path = join('/', $TmpDir, $state_file);
  my $data_hash;
  ok($Pg_obj->store_state($Test_state_hash, $test_file_path),
	 "Create state file");
  ok($data_hash = $Pg_obj->read_state($data_hash, $test_file_path),
	 "Read state file");
  is_deeply($Test_state_hash, $data_hash, ### Test #20
			"Compare state file data to original");

  # Testing Embperl execution
  my $Embperl_output;
  my $Trans = {};
  ok($Embperl_output =
             $Pg_cgi->Embperl_Execute(abs_path($TmpDir),
                                      $template_file, $Trans),
     "Executing Embperl");

  # Making sure Embperl intepolated variables
  ok($Embperl_output !~ /\[/,
     "Confirming conversion of Embperl code into HTML");


  ### Test database purging

  # Get some date values to test purge.
  my $date_code;
  ok ( $date_code = $Pg_daemon->GetDateCode(),
      "GetDateCode returns a true value");
  my $old_date = $date_code-($DateLimit+1);

  # Create dummy database records for test
  ok (fill_db_file('NameList.db', $old_date, $date_code),
	  "Creating test 'NameList.db'") or
		diag($ErrorMessage);
  ok (fill_db_file('NamePass.db', $old_date, $date_code), ### Test #25
	  "Creating test 'NamePass.db'") or
		diag($ErrorMessage);
  ok (fill_db_file('CardData.db', $old_date, $date_code),
	  "Creating test 'CardData.db'") or
		diag($ErrorMessage);

  ok ($Pg_daemon->purge_old_cards(abs_path($TmpDir), $DateLimit,
								  'NameList.db', 'NamePass.db',
								  'CardData.db') == 1,
	  "Successfully purged old card database records");


 ### Optionals test for HTML::Mason
 SKIP: {
	eval { require HTML::Mason };

	skip "Optional HTML::Mason not installed", 5 if $@;

	use_ok( 'Pgreet::ExecMason' );

    ok ($TmpMason = tempdir("PgreetTestMasonDatarXXXX", CLEANUP => 1) and
		(-d $TmpMason),
		"Creating Temporary Mason data directory");

	ok(create_Mason_file(), ### Test #30
	   "Create Test Mason template environment") or
		 diag($ErrorMessage);

    # Create test Mason environment
	my $Mason_output;
	my $Trans = {};
    my $Mason_Obj = {comp_root => abs_path($TmpDir),
					 data_dir => abs_path($TmpMason),
					 bypass_object => $template_file,
					};

    # Execute (Intepret) Mason template
	ok($Mason_output =
	     $Pg_cgi->Mason_Execute(abs_path($TmpDir), $template_file,
                                $Trans, $Mason_Obj),
	   "Executing test HTML::Mason template");

	# Confirm that Mason elements were removed from template
	ok($Mason_output !~ /\<\%/,
       "Confirming conversion of Mason template into HTML");
    }

 ### Optional tests for ecard site localization.
 SKIP: {
	eval { require Locale::Maketext };

	skip "Optional Locale::Maketext not installed", 3 if $@;

	use_ok( 'Pgreet::I18N' );

	my $LN = Pgreet::I18N->get_handle('fr-fr');
	ok( $LN, "Created Locale::Maketext localization object" );

	# Use a sample translation from Pgreet::I18N::fr_fr
	my $en_text = "Send this card";
	my $fr_text = "Envoyer cette carte";

	is($LN->maketext($en_text), $fr_text, ### Test #35
	   "Locale::Maketext translation was correct.");
    }
}
