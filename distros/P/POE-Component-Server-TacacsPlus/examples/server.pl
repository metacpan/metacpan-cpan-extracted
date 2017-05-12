#!/usr/bin/perl

=head1 NAME

server.pl - example Tacacs+ server

=head1 SYNOPSIS

	server.pl
		--key KEY
		--port     (optional) default 49
		--userfile (optional) default ./userdb.txt

=head1 DESCRIPTION

Simple example pap auth server.

=cut


use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin.'/../lib';

use Log::Log4perl qw(:nowarn :easy :no_extra_logdie_message);
Log::Log4perl::init($FindBin::Bin.'/log4perl.conf');

use POE::Component::Server::TacacsPlus;
use Net::TacacsPlus::Constants;

use Getopt::Long;
use Pod::Usage;
use File::Slurp qw { read_file };


my %password_of;

exit main();

sub main {
	my $key;
	my $port          = 49;
	my $user_filename = $FindBin::Bin.'/userdb.txt';
	
	GetOptions(
		'key=s'      => \$key,
		'port=s'     => \$port,
		'userfile=s' => \$user_filename,
	) or pod2usage(2);
	pod2usage(2) if (!$key);

	%password_of = fill_password_of($user_filename);

	POE::Component::Server::TacacsPlus->spawn(
		'server_port' => $port,
		'key'         => $key,
		'handler_for' => {
			TAC_PLUS_AUTHEN() => {
				TAC_PLUS_AUTHEN_TYPE_PAP() => \&check_pap_authentication,
			},
		},
	);
	
	POE::Kernel->run();
	
	return 0;
}

sub check_pap_authentication {
	my $username = shift;
	my $password = shift;
	
	if (($password_of{$username} eq $password)) {
		INFO 'successfull auth of '.$username;
		return 1;
	}

	WARN 'failed auth of '.$username;
	return 0;
}

sub fill_password_of {
	my $filename = shift;

	my %password_of;
	foreach my $line (read_file($filename)) {
		#skip comments
		next if $line =~ m{^#};
		
		#get username and password
		my ($username, $password) = split(/\s+/, $line);
		$password_of{$username} = $password;
	}
	
	return %password_of;		
}

