#!perl

use Test::More tests => 3;
use Slackware::Slackget::Network::Connection;

my $connection = Slackware::Slackget::Network::Connection->new(
	host => 'debug://ftp.riken.jp/Linux/slackware/slackware-12.0/',
	download_directory => "/tmp/",
	InlineStates => {
		progress => \&handle_progress ,
		download_error => \&handle_download_error ,
		download_finished => \&handle_download_finished,
	}
);

isnt($connection, undef, "Create Slackware::Slackget::Network::Connection object with debug:// protocol.");
$connection->object_extra_data('debug-want-success',1);
$connection->fetch_file('TEST');
$connection->fetch_file('TEST','TEST');

sub handle_progress {
	my ($file,$done,$total)=@_;
	print "downloaded $file $done/$total\n";
}

sub handle_download_error{
	my ($file,$status,$co) = @_;
	print "error while downloading $file : ".$status->to_string.".\n";
	ok(0);
}

sub handle_download_finished{
	my ($file,$status,$co) = @_;
	print "file $file successfully downloaded.\n";
	ok(1);
}

