# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

## the test plan:
##	0.  load the module
##	1.  new: connect to remedy server
##	2.  ImportDefinition: install the test form
##	3.  CreateTicket: on test form
##	4.  Query: record from test form
##	5.  check enum conversion
##		5a. sequential
##		5b. custom non-sequential
##	6.  check time field conversion
##		6a. with no GMT offset
##		6b. with GMT offset specified
##	7.  check date conversion
##	8.  check time_of_day conversion
##		8a. with 12 hour format
##		8b. with 24 hour format
##	9.  ModifyTicket: check inbound conversions
##		9a. set time field
##		9b. set time_of_day field
##		9c. set custom enum
##		9d. set standard enum
##	10. Query: check output with date conversions disabled
##		10a. time_field
##		10b. date_field
##		10c. time_of_day field
##	11. TunnelSQL: query raw diary field from merged ticket
##	12. ParseDiary: parse diary from test 12
##	13. EncodeDBDiary: encode Query output
##      14. MergeTicket: check with date conversions enabled
##	15. ExportDefinition: retrieve definition for test form (test #2)
## 	16. DeleteTicket: delete ticket from test form
##	17. DeleteObjectFromServer: delete test form (test #2)
##	18. Destroy: log out of remedy

use Test;
use Date::Parse;
BEGIN { plan tests => 27 };

################################################################################
## configuration
################################################################################
my %config = (
	RemedyUser 	=> {'value' => '', 'help' => "user to connect to remedy server (admin account)"},
	RemedyPass 	=> {'value' => '', 'help' => "password to connect to remedy server"},
	RemedyHost 	=> {'value' => '', 'help' => "remedy server hostname or ip address"},
	RemedyPort 	=> {'value' => '', 'help' => "tcp port number to connect to remedy server"},
	RemedyCfgFile 	=> {'value' => "./ARSToolsCache.xml", 'help' => "file to use for ARS field data cache"},
	Log		=> {'value' => "./Remedy_ARSTools_post_install_test_" . time() . ".log", 
	                    'help' => "file to write test log into", '_skip' => 1},
        Debug		=> {'value' => 1, 'help' => "debug mode (1 = on = reccommended)", '_skip' => 1 }
);

################################################################################
## subroutines
################################################################################

## Log #################################
## an oldie but a goodie. 
## global $Log must be defined
sub Log {
	my $message = $_[0];
	open (LOG, ">>" . $Log) || do {
		warn("[Log]: cannot open logfile for writing: " . $!);
		die();
	};
	my $v = time();
	print LOG "[" . $v . "]: " . $message . "\n";
	print "[" . $v . "]: " . $message . "\n" if ($Debug);
	close(LOG);

}

## GetUserInput ########################
## query the user with the given string, return user's input
sub GetUserInput {
	my ($query) = $_[0];
	print "\n>>" . $query . "\n";
	my $str = <STDIN>;
	chomp ($str);
	return ($str);
}

END {
	## clean up as best we can if we're exiting early
	
	## DeleteObjectFromServer
	if ($created_test_form > 0){
		Log ("removing test form form from server ...");
		$Remedy->DeleteObjectFromServer(
			ObjectName	=> "Remedy::ARSTools:Test Form",
			ObjectType	=> "schema"
		) || do {
			Log ("[TEST 17 - fail]: can't delete test form from server: " . $Remedy->{'errstr'});
			die();
		};
	}

	## Log out of remedy
	$Remedy->Destroy() if (defined($Remedy));
}

################################################################################
## runtime
################################################################################

#test 0: load the module
use Remedy::ARSTools;
ok(1);

## get set up to do the whole shebang ...
print "\n>> NOTICE IS HEREBY GIVEN\n";
print ">> The Remedy::ARSTools test suite requires an administrator login to a running remedy server.\n";
print ">> The test suite will install a test form, insert, modify and delete data on that test form, then\n";
print ">> delete that test form. THERE IS ALWAYS THE CHANCE THIS COULD GO WRONG. That is, in fact a DISTINCT\n";
print ">> POSSIBILILTY, given that this is a test suite. Probably this test suite won't hork your remedy server\n";
print ">> however it might. I STRONGLY ADVISE you NOT to point this test suite at a running production server.\n";
print ">> -Andy\n";
print "\n";

my $swt = GetUserInput("do you wish to run the Remedy::ARSTools test suite? [y/N]");
if ($swt =~/^y/i){

	print "\n>> the test suite will now prompt you for required data ...\n\n";
	
	foreach (keys %config){
		
		#skip ones we don't want to ask about
		next if ($config{$_}->{'_skip'});
		
		#ask if the current value is ok, if we have one
		if ($config{$_}->{'value'} !~/^\s*$/){
			my $swt = GetUserInput("[" . $_ . "]: " . $config{$_}->{'help'} . "\nhas a current value of: " . $config{$_}->{'value'} . "\n>> is this ok? [Y/n]\n");
			if ($swt =~/^n/i){
				$config{$_}->{'value'} = GetUserInput("enter a new value for: " . $_);
			}else{
				next;
			}
		}else{
			$config{$_}->{'value'} = GetUserInput("[" . $_ . "]: " . $config{$_}->{'help'} . "\nplease enter a value for this option: \n");
		}
	}
	#some things are just easier this way
	$Log = $config{'Log'}->{'value'};
	$Debug = $config{'Debug'}->{'value'};


}else{
	exit();
}

Log ("beginning Remedy::ARSTools " . $Remedy::ARSTools::VERSION . " test suite ...");


## 1. log into remedy
Log ("[TEST 1]: log into Remedy on: " . $config{'RemedyUser'}->{'value'} . "/" . $config{'RemedyHost'}->{'value'} . ":" . $config{'RemedyPort'}->{'value'} . " ...");
$Remedy = new Remedy::ARSTools(
	Server		=> $config{'RemedyHost'}->{'value'},
	Port		=> $config{'RemedyPort'}->{'value'},
	User		=> $config{'RemedyUser'}->{'value'},
	Pass		=> $config{'RemedyPass'}->{'value'},
	ConfigFile	=> $config{'RemedyCfgFile'}->{'value'},
        Debug		=> $Debug,
	Schemas		=> [ "User" ]
) || do {
	Log ("[TEST 1 - FAIL]: failed to load ARSTools object / " . $Remedy::ARSTools::errstr);
	ok(0);
	die();
};
Log ("[TEST 1 - pass]: successfully logged into remedy");
ok(1);


## 2. import the test form
Log ("[TEST 2]: create test form Remedy::ARSTools:Test Form ...");
open (DEF, "./remedy_arstools_test_form_def.xml") || do {
	Log ("[TEST 2 - fail]: can't open definition file!: " . $!);
	ok (0);
	die();
};
my $def = join('', <DEF>);
close (DEF);

$Remedy->ImportDefinition(
	Definition	=> $def,
	DefinitionType	=> "xml",
	ObjectName	=> "Remedy::ARSTools:Test Form",
	ObjectType	=> "schema",
	UpdateCache	=> 1
) || do {
	Log ("[TEST 2 - fail]: can't import schema definition: " . $Remedy->{'errstr'});
	ok(0);
	die();
};
Log ("[TEST 2 - pass]: successfully imported schema definition");
ok(1);
$created_test_form = 1;

## 3. create a ticket on the test form with some interesting fields
my %tmp = (
	'Submitter'			=> $config{'RemedyUser'}->{'value'},
	'Assigned To'			=> $config{'RemedyUser'}->{'value'},
	'Status'			=> "Assigned",
	'Short Description'		=> "this is a test from Remedy::ARSTools version: " . $Remedy::ARSTools::VERSION,
	'time_field'			=> "10/03/1974 2:15:36 PM CDT",
	'date_field'			=> "10/03/1974",
	'time_of_day_field'		=> "2:15:36 PM",,
	'custom_enum_field'		=> "four",
	'Remedy::ARSTools::VERSION'	=> $Remedy::ARSTools::VERSION,
	'diary_field'			=> "diary entry #1"	
);
my %copy_of_tmp = %tmp;
Log ("[TEST 3]: create ticket on test form ...");
my $ticket_number = $Remedy->CreateTicket(
	Schema	=> "Remedy::ARSTools:Test Form",
	Fields	=> \%copy_of_tmp
) || do {
	Log ("[TEST 3 - fail]: failed CreateTicket on Remedy::ARSTools::Test Form -- " . $Remedy->{'errstr'});
	ok(0);
	die();
};
Log ("[TEST 3 - pass]: created " . $ticket_number . " on test form");
ok(1);


## 4. query for created record with translations on
Log ("[TEST 4]: query for record created on TEST 3 ...");
my @fields = keys(%tmp);
my $data = $Remedy->Query(
	Schema	=> "Remedy::ARSTools:Test Form",
	Fields	=> \@fields,
	QBE	=> "'Request ID' = ". '"' . $ticket_number . '"'
) || do {
	Log ("[TEST 4 - fail]: failed Query on Remedy::ARSTools::Test Form -- " . $Remedy->{'errstr'});
	ok(0);
	die();
};
Log ("[TEST 4 - pass]: Query succeeded");
ok(1);

## 5a. check sequential enum conversion on Query output
Log ("[TEST 5a]: check sequential enum translation ...");
if ($data->[0]->{'Status'} ne $tmp{'Status'}){
	Log ("[TEST 5a - fail]: retrieved 'Status' value is not " . $tmp{'Status'} . ": " . $data->[0]->{'Status'});
	ok(0);
	die();
}else{
	Log ("[TEST 5a - pass]: retrieved 'Status' value matches input");
	ok(1);
}

## 5b. check non-sequential custom enum translation
Log ("[TEST 5b]: check non-sequential custom enum translation ...");
if ($data->[0]->{'custom_enum_field'} ne $tmp{'custom_enum_field'}){
	Log ("[TEST 5b - fail]: retrieved 'custom_enum_field' value is not " . $tmp{'custom_enum_field'} . ": " . $data->[0]->{'custom_enum_field'});
	ok(0);
	die();
}else{
	Log ("[TEST 5b - pass]: retrieved 'custom_enum_field' matches input");
	ok(1);
}

## 6a. check GMT time field conversion
Log ("[TEST 6a]: check default GMT time field conversion ...");
my $in_epoch = str2time($tmp{'time_field'});
my $out_epoch = str2time($data->[0]->{'time_field'});
if ($in_epoch != $out_epoch){
	Log ("[TEST 6a - fail]: GMT date conversion error [INPUT]: " . $tmp{'time_field'} . " [OUTPUT]: " . $data->[0]->{'time_field'});
	ok(0);
	die();
}else{
	Log ("[TEST 6a - pass]: GMT date conversion");
	ok(1);
}

## 6b. check GMT offset time field conversion
Log ("[TEST 6b]: check GMT offset time field conversion ...");
my $data2 = $Remedy->Query(
	Schema			=> "Remedy::ARSTools:Test Form",
	Fields			=> ["time_field"],
	QBE			=> "'Request ID' = ". '"' . $ticket_number . '"',
	DateConversionTimeZone	=> "-6"
) || do {
	Log ("[TEST 6b - fail]: failed Query on Remedy::ARSTools::Test Form -- " . $Remedy->{'errstr'});
	ok(0);
	die();
};
#perl trickeration
my ($blah, $caca) = split(/GMT/, $data2->[0]->{'time_field'});
$out_epoch = str2time($blah . " GMT");
if (abs($out_epoch - $in_epoch) != (60 * 60 * 6)){
	Log ("[TEST 6b - fail]: time translation with GMT offset does not compute [INPUT]: " . $tmp{'time_field'} . " [OUTPUT]: " . $data2->[0]->{'time_field'});
	ok(0);
	die();
}else{
	Log ("[TEST 6b - pass]: time translation with GMT offset looks ok");
	ok(1);
}

## 7. check date field conversion
Log ("[TEST 7]: date_field conversion ...");
$in_epoch = str2time($tmp{'date_field'} . " 00:00:00 GMT");
$out_epoch = str2time($data->[0]->{'date_field'} . " 00:00:00 GMT");
if ($in_epoch != $out_epoch){
	Log ("[TEST 7 - fail]: date translation failed [INPUT]: " . $tmp{'date_field'} . " [OUTPUT]: " . $data->[0]->{'date_field'});
	ok(0);
	die();
}else{
	Log ("[TEST 7 - pass]: date translation looks ok");
	ok(1);
}

## 8a. check time_of_day conversion in 12 hour format
Log ("[TEST 8a]: time_of_day conversion in 12 hour format ...");
if ($tmp{'time_of_day_field'} ne $data->[0]->{'time_of_day_field'}){
	Log ("[TEST 8a - fail]: time_of_day conversion failed: [INPUT]: " . $tmp{'time_of_day_field'} . " [OUTPUT]: " . $data->[0]->{'time_of_day_field'});
	ok(0);
	die();
}else{
	Log ("[TEST 8a - pass]: time_of day (12 hour format) looks good");
	ok(1);
}

## 8b. check time_of_day conversion in 24 hour format
Log ("[TEST 8b]: time_of_day conversion in 24 hour format ...");
$Remedy->{'TwentyFourHourTimeOfDay'} = 1;
$data2 = $Remedy->Query(
	Schema			=> "Remedy::ARSTools:Test Form",
	Fields			=> ["time_of_day_field"],
	QBE			=> "'Request ID' = ". '"' . $ticket_number . '"'
) || do {
	Log ("[TEST 8b - fail]: failed Query on Remedy::ARSTools::Test Form -- " . $Remedy->{'errstr'});
	ok(0);
	die();
};
if ($data2->[0]->{'time_of_day_field'} eq "14:15:36"){
	Log ("[TEST 8b - pass]: 24 hour time_of_day conversion looks ok");
	ok(1);
}else{
	Log ("[TEST 8b - fail]: 24 hour time_of_day conversion failure [INPUT]: " . $tmp{'time_of_day_field'} . " [OUTPUT]: " . $data2->[0]->{'time_of_day_field'});
	ok(0);
	die();
}


## 9. ModifyTicket with some interesting fields
Log ("[TEST 9]: modify ticket ...");
$Remedy->ModifyTicket(
	Schema	=> "Remedy::ARSTools:Test Form",
	Ticket	=> $ticket_number,
	Fields	=> {
		'custom_enum_field'	=> "two",
		'Status'		=> "Closed",
		'date_field'		=> "10/14/1971",
		'time_field'		=> "10/14/1971 01:45:15 EST",
		'time_of_day_field'	=> "01:45:15 AM",
		'diary_field'		=> "diary entry #2"
	}
) || do {
	Log ("[TEST 9 - fail]: can't modify ticket: " . $Remedy->{'errstr'});
	ok(0);
	die();
};
Log ("[TEST 9 - pass]: modified ticket: " . $ticket_number);
ok(1);


## 9a. verify time_field
Log ("[TEST 9a]: verify time field modify and translation ...");
$Remedy->{'DateTranslate'} = 1;
$Remedy->{'TwentyFourHourTimeOfDay'} = 0;
$data = $Remedy->Query(
	Schema	=> "Remedy::ARSTools:Test Form",
	Fields	=> ["custom_enum_field", "time_of_day_field", "time_field", "date_field", "Status"],
	QBE	=> "'Request ID' = ". '"' . $ticket_number . '"'
) || do {
	Log ("[TEST 9a - fail]: failed Query on Remedy::ARSTools::Test Form -- " . $Remedy->{'errstr'});
	ok(0);
	die();
};
$in_epoch = str2time("10/14/1971 01:45:15 EST");
$out_epoch = str2time($data->[0]->{'time_field'});
if ($in_epoch != $out_epoch){
	Log ("[TEST 9a - fail]: time conversion error on modify [INPUT]: 10/14/1971 01:45:15 EST [OUTPUT]: " . $data->[0]->{'time_field'});
	ok(0);
	die();
}else{
	Log ("[TEST 9a - pass]: time conversion on modify looks ok");
	ok(1);
}


## 9b. verify time_of_day on modify
Log ("[TEST 9b]: time_of_day conversion on modify ...");
if ($data->[0]->{'time_of_day_field'} ne "01:45:15 AM"){
	Log ("[TEST 9b - fail]: time_of_day conversion error on modify [INPUT]: 01:45:15 AM [OUTPUT]: " . $data->[0]->{'time_of_day_field'});
	ok(0);
	die();
}else{
	Log ("[TEST 9b - pass]: time_of_day conversion on modify looks ok");
	ok(1);
}


## 9c. verify date on modify
Log ("[TEST 9c]: date conversion on modify ...");
if ($data->[0]->{'date_field'} !~/Oct 14 1971$/){
	Log ("[TEST 9c - fail]: date conversion error on modify [INPUT]: 10/14/1971 [OUTPUT]: " . $data->[0]->{'date_field'});
	ok(0);
	die();
}else{
	Log ("[TEST 9c - pass]: date conversion on modify looks ok");
	ok(1);
}

## 9d. verify custom enum on modify
Log ("[TEST 9d]: custom enum translation on modify ...");
if ($data->[0]->{'custom_enum_field'} ne "two"){
	Log ("[TEST 9d - fail]: custom enum translation error on modify [INPUT]: two [OUTPUT]: " . $data->[0]->{'custom_enum_field'});
	ok(0);
	die();
}else{
	Log ("[TEST 9d - pass]: custom enum translation on modify looks ok");
	ok(1);
}

## 9e. verify standard enum on modify
Log ("[TEST 9e]: standard enum translation on modify ...");
if ($data->[0]->{'Status'} ne "Closed"){
	Log ("[TEST 9e - fail]: standard enum translation error on modify [INPUT]: Closed [OUTPUT]: " . $data->[0]->{'Status'});
	ok(0);
	die();
}else{
	Log ("[TEST 9e - pass]: standard enum translation on modify looks ok");
	ok(1);
}


## 10. check query output with date translations disabled
Log ("[TEST 10]: check query output with date translations turned off ...");
$Remedy->{'DateTranslate'} = 0;
$data = $Remedy->Query(
	Schema	=> "Remedy::ARSTools:Test Form",
	Fields	=> ["time_of_day_field", "time_field", "date_field"],
	QBE	=> "'Request ID' = ". '"' . $ticket_number . '"'
) || do {
	Log ("[TEST 10 - fail]: failed Query on Remedy::ARSTools::Test Form -- " . $Remedy->{'errstr'});
	ok(0);
	die();
};
foreach my $field (keys %{$data->[0]}){
	if ($data->[0]->{$field} !~/^\d{1,10}$/){
		Log ("[TEST 10 - fail]: '" . $field . "' returned a non-integer value with date translation turned off: " . $data->[0]->{$field});
		ok(0);
		die();
	}
}
Log ("[TEST 10 - pass]: query output with date translations deactivated looks good");
ok(1);

## 11. TunnelSQL
Log ("[TEST 11]: Tunnel SQL Query on API ...");
$data = $Remedy->TunnelSQL(
	SQL => "select viewname from arschema where name = 'Remedy::ARSTools:Test Form'"
) || do {
	Log ("[TEST 11 - fail]: tunneled sql query failure: " . $Remedy->{'errstr'});
	ok(0);
	die();
};

Log ("[TEST 11 - pass]: sql query looks ok: " . $data->[0]->[0]);
ok(1);

## 12. ParseDiary
Log ("[TEST 12]: Parse raw DB diary field ...");
$data2 = $Remedy->TunnelSQL(
	SQL => "select diary_field from " . $data->[0]->[0] . " where request_id = '" . $ticket_number . "'"
) || do {
	Log ("[TEST 12 - fail]: failed query for raw DB field: " . $Remedy->{'errstr'});
	ok(0);
	die();
};
my $diary = $Remedy->ParseDBDiary(
	Diary	=> $data2->[0]->[0]
) || do {
	Log ("[TEST 12 - fail]: failed ParseDBDiary: " . $Remedy->{'errstr'});
	ok(0);
	die();
};

if (ref($diary) ne "ARRAY"){
	Log ("[TEST 12 - fail]: ParseDBDiary output invalid");
	ok(0);
	die();
}else{
	foreach my $entry (@{$diary}){
		if (ref($entry) ne "HASH"){
			Log ("[TEST 12 - fail]: ParseDBDiary output invalid");
			ok(0);
			die();
		}
	}
}

Log ("[TEST 12 - pass]: ParseDBDiary output looks ok");
ok(1);

## 13. test EncodeDBDiary
Log ("[TEST 13]: EncodeDBDiary ...");
my $diary_skrang = $Remedy->EncodeDBDiary(
	Diary	=> $diary
) || do {
	Log ("[TEST 13 - fail]: cannot encode diary field: " . $Remedy->{'errstr'});
	ok(0);
	die();
};
## there be funny business afoot?
my @tmp1 = split(//, $data2->[0]->[0]);
my @tmp2 = split(//, $diary_skrang);
my $pos = 0;
Log("\n>> [D (length)]: " . length($data2->[0]->[0]));
Log("\n>> [P (length)]: " . length($diary_skrang) . "\n");
foreach my $chr (@tmp1){
	if ($chr ne $tmp2[$pos]){
		Log("\n>>mismatch at position: " . $pos . " [D]: " . ord($chr) . " [P]: " . ord($tmp2[$pos]) . "\n");
		ok(0);
		die();
	}
	$pos ++;
}

Log ("[TEST 13 - pass]: \n[D]: " . $data2->[0]->[0] . "\n[P]: " . $diary_skrang);
ok(1);

## 14. test merge ticket
Log ("[TEST 14]: MergeTicket on test form ...");
%copy_of_tmp = %tmp;
$copy_of_tmp{'diary_field'} = $diary_skrang;
my $merge_ticket_number = $Remedy->MergeTicket(
	Schema		=> "Remedy::ARSTools:Test Form",
	Fields		=> \%copy_of_tmp,
	MergeCreateMode	=> "Overwrite"
) || do {
	Log ("[TEST 14 - fail]: MergeTicket failed: " . $Remedy->{'errstr'});
	ok(0);
	die();
};

Log ("[TEST 14 - pass]: created ticket: " . $merge_ticket_number . " on merge transaction");
ok(1);

## 15. ExportDefinition
Log ("[TEST 15]: export definition ...");
my $def = $Remedy->ExportDefinition(
	ObjectName	=> "Remedy::ARSTools:Test Form",
	ObjectType	=> "schema",
	DefinitionType	=> "xml"
) || do {
	Log ("[TEST 15 - fail]: export definition failure: " . $Remedy->{'errstr'});
	ok(0);
	die();
};
if (length($def) > 0){
	Log ("[TEST 15 - pass]: exported " . length($def) . " bytes ... OK");
	ok(1);
}else{
	Log ("[TEST 15 - fail]: ExportDefinition returned 0 bytes!");
	ok(0);
	die();
}

## 16. DeleteTicket
Log ("[TEST 16]: delete ticket from test form ...");
$Remedy->DeleteTicket(
	Schema	=> "Remedy::ARSTools:Test Form",
	Ticket	=> $ticket_number
) || do {
	Log ("TEST 16 - fail]: can't delete " . $ticket_number . " from test from: " . $Remedy->{'errstr'});
	ok(0);
	die();
};

Log ("[TEST 16 - pass]: deleted ticket " . $ticket_number);
ok(1);

## 17. delete test form
Log ("[TEST 17]: delete test form from server ...");
$Remedy->DeleteObjectFromServer(
	ObjectName	=> "Remedy::ARSTools:Test Form",
	ObjectType	=> "schema"
) || do {
	Log ("[TEST 17 - fail]: can't delete test form from server: " . $Remedy->{'errstr'});
	ok(0);
	die();
};

Log ("[TEST 17 - pass]: deleted 'Remedy::ARSTools:Test Form' from " . $RemedyHost);
$created_test_form = 0;
ok(1);

## 17. Log out of remedy
Log ("[TEST 18]: log out of remedy ...");
$Remedy->Destroy() if (defined($Remedy));

Log ("[TEST 18 - pass]");
ok(1);
