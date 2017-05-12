# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 11;
use Qmail::Mysql;
use Cwd;

#my $sql_control_file = '/var/qmail/control/sqlserver';
my $sql_control_file = '/usr/local/qmail/control/sqlserver';
my $mbox_base = getcwd(). "/mbox";

print "Enter the path to qmail sql control file [$sql_control_file]: ";
$sql_control_file_ui 	= <STDIN>; chomp($sql_control_file_ui);
$sql_control_file	= $sql_control_file_ui if ($sql_control_file_ui ne '');


# force autoflush on log file for testing 
my $qmail	= new Qmail::Mysql( sql_control_file => $sql_control_file,
					mailbox_base            => $mbox_base,
       				password_type           => 'Password',
        			multihosting 	        => 0,
					multihosting_join   	=> '@'
							);

ok( defined $qmail,            		'new() returned something' );
ok( $qmail->isa('Qmail::Mysql'),	'  and it\'s the right class' );

$qmail->connect;
ok( defined $qmail->{dbh},		'successfull connecting qmail database' );
$qmail->rcpt_add('rcptdomain.ext');
ok( $qmail->rcpt_exists('rcptdomain.ext'), 
		"successfull added rcpt host");

$qmail->rcpt_del('rcptdomain.ext');
ok( !$qmail->rcpt_exists('rcptdomain.ext'), 
		"successfull deleted rcpt host");

foreach my $vh (0..1) {
		$qmail->{multihosting} 	= $vh;

		$qmail->mail_add('foo','bar.com','mypass');
		ok( $qmail->mail_exists('foo','bar.com'),   
			"successfull added mail box (multihosting => $vh)" );

		$qmail->mail_del('foo','bar.com');
		ok( !$qmail->mail_exists('foo','bar.com'),   
			"successfull deleted mail box (multihosting => $vh)" );
}

$qmail->alias_add('alias@bar.com','real@bar.com');
ok( $qmail->alias_exists('alias@bar.com','real@bar.com'),
			"successful created alias");

$qmail->alias_del('alias@bar.com','real@bar.com');
ok( !$qmail->alias_exists('alias@bar.com','real@bar.com'),
			"successful deleted alias");

rmdir("$mbox_base/bar.com") if (-e "$mbox_base/bar.com");
rmdir($mbox_base) if (-e $mbox_base);

$qmail->disconnect;


#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

