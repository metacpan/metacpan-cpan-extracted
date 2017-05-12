#! /usr/bin/perl -wT

use strict;

package Net::DNS::DynDNS::Agent;

use Net::DNS::DynDNS();
use Config::General();
use Getopt::Long();
use FileHandle();
use File::Spec();
use Fcntl();

my ($config_file);
Getopt::Long::GetOptions('file=s', \$config_file);
unless ($config_file) {
	my ($volume, $directories, $file) = File::Spec->splitpath($0);
	if ($volume) {
		$config_file = File::Spec->catfile($volume, $directories, 'dyndnsd.cnf');
	} else {
		$config_file = File::Spec->catfile($directories, 'dyndnsd.cnf');
	}
}

sub new {
	my ($class, $config_file) = @_;
	my ($self) = {};
	if ($config_file) {
		if (-e $config_file) {
			if (-r $config_file) {
				$self->{config_file} = $config_file;
			} else {
				die("Insufficient privileges to read from '$config_file'\n");
			}
		} else {
			die("Config file '$config_file' does not exist\n");
		}
	} else {
		die("Must supply a config file parameter\n");
	}
	bless $self, $class;
	return ($self);	
}

sub options {
	my ($self) = @_;
	my ($options);
	if (-e $self->{config_file}) {
		if (-r _) {
			my ($mtime) = (stat(_))[9]; # get last modified time
			unless ((exists $self->{config}) && (defined $self->{config}) && (ref $self->{config}) && (ref $self->{config} eq 'HASH') &&
							(exists $self->{config_mtime}) && ($self->{config_mtime}) && ($self->{config_mtime} == $mtime))
			{
				$self->{config_mtime} = $mtime;
				my ($config) = new Config::General(
									-ConfigFile     => $self->{config_file},
									-SplitPolicy    => 'whitespace',
									-LowerCaseNames => 1,
									-AutoTrue       => 1,
								);
				$options = { $config->getall() };
				$self->{config} = $options;
				unless ($options->{database}) {
					$options->{database} = File::Spec->catfile(File::Spec->tmpdir(), 'dyndnsd.db');
				}
				unless ($options->{user}) {
					die("'User' option was not found in '" . $self->{config_file} . "'\n");
				}
				unless ($options->{password}) {
					die("'Password' option was not found in '" . $self->{config_file} . "'\n");
				}
				unless ($options->{hosts}) {
					die("'hosts' option was not found in '" . $self->{config_file} . "'\n");
				}
				if ((exists $self->{dyndns}) && ($self->{dyndns})) {
					my ($dyndns) = $self->{dyndns};
					$dyndns->update_allowed(1); # allow updates again after config file has been successfully altered / touched
				}
			} else {
				$options = $self->{config};
			}
		} else {
			die("Insufficient privileges to read from '" . $self->{config_file} . "'\n");
		}
	} else {
		die("Config file '" . $self->{config_file} . "' does not exist\n");
	}
	return ($options);
}

sub allowed_check {
	my ($self) = @_;
	my ($now) = time;
	if ((exists $self->{next_allowed_check}) && ($self->{next_allowed_check})) {
		if ($self->{next_allowed_check} > $now) {
			return 0;
		}
	}
	if ((exists $self->{dyndns}) && ($self->{dyndns})) {
		my ($dyndns) = $self->{dyndns};
		unless ($dyndns->update_allowed()) {
			return 0;
		}
	}
	return 1;
}

sub check {
	my ($self, $options) = @_;
	my ($returned_ip_address);
	my ($now) = time;
	unless ($self->allowed_check()) {
		return ($returned_ip_address);
	}
	unless ((exists $self->{next_allowed_check}) && ($self->{next_allowed_check})) {
		$self->{next_allowed_check} = $now;
	}
	$self->{next_allowed_check} += (20 * 60); # run every 20 minutes
	my ($old_ip_address);
	my ($databaseHandle);
	my ($server_options);
	my ($databasePath) = $options->{database};
	my ($username) = $options->{user};
	my ($password) = $options->{password};
	my ($hosts) = $options->{hosts};
	my ($ip_address);
	if (exists $options->{ipaddress}) {
		$ip_address = $options->{ipaddress};
	}
	my ($params) = {};
	if (exists $options->{wildcard}) {
		$params->{wildcard} = $options->{wildcard};
	}
	if (exists $options->{mx}) {
		$params->{mx} = $options->{mx};
	}
	if (exists $options->{backmx}) {
		$params->{backmx} = $options->{backmx};
	}
	if (exists $options->{offline}) {
		$params->{offline} = $options->{offline};
	}
	if (exists $options->{protocol}) {
		$params->{protocol} = $options->{protocol};
	}
	if (exists $options->{server}) {
		$server_options->{server} = $options->{server};
	}
	if (exists $options->{dns_server}) {
		$server_options->{dns_server} = $options->{dns_server};
	}
	if (exists $options->{check_ip}) {
		$server_options->{check_ip} = $options->{check_ip};
	}
	unless ((exists $self->{dyndns}) && ($self->{dyndns})) {
		$self->{dyndns} = Net::DNS::DynDNS->new($username, $password, $server_options);
	}
	my ($dyndns) = $self->{dyndns};
	my ($current_ip_address) = $dyndns->default_ip_address();
	$self->{current_ip_address} = $current_ip_address;
	if (-e $databasePath) {
		unless (-f $databasePath) {
			die("'$databasePath' is not a normal file\n");
		}
		$databaseHandle = new FileHandle("+< $databasePath");	
		unless ($databaseHandle) {
			die("Failed to open '$databasePath' for reading and writing:$!\n");
		}
		unless (-f $databaseHandle) {
			die("'$databasePath' is not a normal file\n");
		}
		unless (flock($databaseHandle, Fcntl::LOCK_SH())) {
			die("Failed to lock '$databasePath':$!\n");
		}
		unless ($databaseHandle->seek(0,0)) {
			die("Failed to seek to the start of '$databasePath':$!\n");
		}
		unless (defined $databaseHandle->read($old_ip_address, 20)) {
			die("Failed to read from '$databasePath':$!\n");
		}
		chomp($old_ip_address);
	} else {
		# default umask for file
		$databaseHandle = new FileHandle($databasePath, Fcntl::O_CREAT() |
									Fcntl::O_WRONLY() |
									Fcntl::O_TRUNC() |
									Fcntl::O_EXCL());
		unless ($databaseHandle) {
			die("Failed to create '$databasePath':$!\n");
		}
	}
	my ($updated) = 0;
	if (($old_ip_address) && ($old_ip_address eq $current_ip_address)) {
		utime($now, $now, $databasePath);
	} else {
		# host -> current ip address mapping is out of date
		if ($dyndns->update_allowed()) {
			if (flock($databaseHandle, Fcntl::LOCK_EX() | Fcntl::LOCK_NB())) {
				if ($ip_address) {
					$current_ip_address = $dyndns->update($hosts, $ip_address, $params);
				} else {
					$current_ip_address = $dyndns->update($hosts);
				}
				$self->{current_ip_address} = $current_ip_address;
				$returned_ip_address = $current_ip_address;
				$updated = 1;
				unless ($databaseHandle->truncate(0)) {
					die("Failed to truncate '$databasePath':$!\n");
				}
				unless ($databaseHandle->seek(0,0)) {
					die("Failed to seek to the start of '$databasePath':$!\n");
				}
				unless ($databaseHandle->print("$current_ip_address\n")) {
					die("Failed to seek to the start of '$databasePath':$!\n");
				}
			} else {
				die("Failed to exclusively lock '$databasePath':$!\n");
			}
		}
	}
	unless ($databaseHandle->close()) {
		die("Failed to close '$databasePath':$!\n");
	}
	return ($returned_ip_address);
}

sub openlog {
	my ($self, $options) = @_;
	if ((exists $options->{syslog}) && ($options->{syslog})) {
		eval { require Sys::Syslog; };
		if ($@) {
			delete $options->{syslog};
			$self->log($@);
		} else {
			my ($facility) = 'user';
			if ((exists $options->{syslogfacility}) && ($options->{syslogfacility})) {
				$facility = $options->{syslogfacility};
			}
			my ($sock) = 'unix';
			if ((exists $options->{syslogsock}) && ($options->{syslogsock})) {
				$sock = $options->{syslogsock};
			}
			Sys::Syslog::setlogsock($sock);
			Sys::Syslog::openlog('dyndnsd', 'pid,cons', $facility);
		}
	}
}

sub log {
	my ($self, $message, $level, $options) = @_;
	chomp($message);
	if ((exists $options->{syslog}) && ($options->{syslog})) {
		Sys::Syslog::syslog($level, $message);
	} else {
		print STDERR "$message\n";
	}
}

sub closelog {
	my ($self, $options) = @_;
	if ((exists $options->{syslog}) && ($options->{syslog})) {
		Sys::Syslog::closelog();
	}
}

eval {
	my ($previousError);
	if ($config_file) {
		my ($agent) = new Net::DNS::DynDNS::Agent($config_file);
		my ($continue) = 1;
		my ($options) = $agent->options();
		$agent->openlog($options);
		local $SIG{INT} = sub { $continue = 0; };
		while ($continue) {
			eval {
				my ($new) = $agent->options();
				$options = $new;
				my ($updated_ip_address) = $agent->check($options);
				if ($updated_ip_address) { # if dyndns.org was updated
					$agent->log("Got a new ip address of '$updated_ip_address'", 'notice', $options);
				}
			};
			if ($@) {
				if (($previousError) && ($previousError eq $@)) {
					$agent->log($@, 'info', $options);
				} else {
					$agent->log($@, 'err', $options);
					$agent = undef;
					$agent = new Net::DNS::DynDNS::Agent($config_file);
				}
				$previousError = $@;
			} else {
				$previousError = undef;
			}
			unless (($agent->allowed_check()) || (not $continue)) {
				sleep 1;
			}
		}
		unless ($continue) {
			$agent->log('Caught an interrupt', 'info', $options);
		}
		$agent->closelog($options);
	}
};
if ($@) {
	print STDERR $@;
	exit 1;
}
