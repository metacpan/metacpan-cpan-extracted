#!/usr/bin/perl -wT
############################################################
#
#   $Id: probe_machines.pl 976 2007-03-04 20:47:36Z nicolaw $
#   probe_machine.pl - Example script for Parse::DMIDecode
#
#   Copyright 2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################
# vim:ts=4:sw=4:tw=78

# Database credentials
use constant DBI_DSN     => 'DBI:mysql:database:hostname';
use constant DBI_USER    => 'username';
use constant DBI_PASS    => 'password';

# Where and how to generate a list of hosts to probe
use constant HOSTS_REGEX => qr{([a-zA-|0-9\-\_\.]+)};
use constant HOSTS_SKIP  => qw{(localhost|localhost.localdomain)};
use constant HOSTS_SRC   => '/etc/hosts';

# Remote command to gather information
use constant SSH_CMD     => 'ssh';
use constant REMOTE_CMD  => 'export PATH=/bin:/usr/bin:/sbin:/usr/sbin;
	echo ==dmidecode==; dmidecode;
	echo ==biosdecode==; biosdecode;
	echo ==vpddecode==; vpddecode;
	echo ==distribution==; grep . /etc/*debian* /etc/redhat-release /etc/mandrake-release /etc/SuSE-release;
	echo ==netstat==; netstat -ltnup;
	echo ==x86info==; x86info;
	echo ==lspci==; lspci;
	echo ==cpuinfo==; cat /proc/cpuinfo;
	echo ==meminfo==; cat /proc/meminfo;
	echo ==lsmod==; lsmod;
	echo ==modules==; cat /proc/modules;
	echo ==hostname==; hostname;
	echo ==route==; route -n;
	echo ==ifconfig==; ifconfig -a;
	echo ==iptables==; iptables -L -n -v;
	echo ==ethtool==; ethtool eth0; ethtool eth1;
	echo ==ipdiscover==; ipdiscover eth0; ipdiscover eth1;
	echo ==resolv==; cat /etc/resolv.conf;
	echo ==hosts==; cat /etc/hosts;
	echo ==uname==; uname -a;
	echo ==rpm==; rpm -qa --queryformat \"%{NAME} %{VERSION} %{SUMMARY}\n\";
	echo ==dpkg==; dpkg -l;
	echo ==uptime==; uptime;
	echo ==who==; who;
	echo ==w==; w;
	echo ==date==; date;
	echo ==iostat==; iostat;
	echo ==vmstat==; vmstat;
	echo ==free==; free;
	echo ==pstree==; pstree;
	echo ==ps==; ps -ef;
	echo ==last==; last;
	echo ==issue==; cat /etc/issue;
	echo ==dmesg==; dmesg;
	echo ==ide==; grep -r . /proc/ide/;
	echo ==scsi==; grep -r . /proc/scsi/;
	echo ==fdisk==; fdisk -l /dev/hd* /dev/sd*;
	echo ==partitions==; cat /proc/partitions;
	echo ==mounts==; cat /proc/mounts;
	echo ==mount==; mount;
	echo ==df==; df -TP';





#########################################################
#
#
#    No user servicable parts inside past this point
#
#
#########################################################




use 5.6.1;
use strict;
use DBI qw();
use Getopt::Std qw(getopts);
use Parse::DMIDecode 0.02 qw();

%ENV = (PATH => '/bin:/usr/bin');
$|++;

my $opts = {};
Getopt::Std::getopts('hCH:',$opts);
display_help(),exit if defined $opts->{h};

my $dbh = DBI->connect(DBI_DSN,DBI_USER,DBI_PASS,{AutoCommit => 0});
create_tables() if defined $opts->{C};

my $dmi = Parse::DMIDecode->new(nowarnings => 1);
my $skip_regex = HOSTS_SKIP;
my @hosts = defined $opts->{H} ? ($opts->{H}) : get_hostnames();

for my $machine (sort(@hosts)) {
	print "Processing $machine ". "." x (49-length($machine));
	print_result('skipped'), next if $machine =~ /$skip_regex/;

	my $data = probe_server($machine);
	if (defined $data->{NOCONNECT}) {
		print_result('connect failed');
	} elsif (defined $data->{'system-uuid'} && $data->{'system-uuid'} =~ /^[A-F0-9\-]{36}$/) {
		update_database($data);
		print_result('done');
	} else {
		print_result('no uuid');
	}
}

$dbh->disconnect();


exit;


sub print_result {
	my $str = shift;
	my $width = 15;
	my $dots = $width -  length($str) - 1;
	printf("%s %s\n", '.' x $dots, $str);
}


sub probe_server {
	my ($machine) = $_[0] =~ /([a-z0-9\.\-\_]+)/i;
	(my $cmd = sprintf('%s %s "%s" 2>/dev/null', SSH_CMD, $machine, REMOTE_CMD)) =~ s/\n//g;
	my %raw = (HOSTNAME => $machine, NOCONNECT => 1);
	my $group;

	if (open(PH,'-|',$cmd)) {
		while (local $_ = <PH>) {
			if (/^==+(\S+?)==+$/) {
				$group = $1;
				delete $raw{NOCONNECT};
			} elsif (defined $group && $group =~ /\S+/) {
				$raw{$group} .= $_;
			} else {
				print $_;
			}
		}
		close(PH);
	}

	return \%raw if defined $raw{NOCONNECT};
	return parse_raw_data($machine,\%raw);
}


sub parse_raw_data {
	my ($machine,$raw) = @_;

	# ==dmidecode==
	if (defined $raw->{dmidecode}) {
		$dmi->parse($raw->{dmidecode});
		for (qw(system-uuid system-serial-number system-manufacturer system-product-name
			system-vendor system-product baseboard-product-name baseboard-manufacturer
			bios-version bios-vendor chassis-type)) {
			$raw->{$_} = $dmi->keyword($_);
			$raw->{$_} = '' unless defined $raw->{$_};
		}
		$raw->{'physical-cpu-qty'} = 0;
		for my $handle ($dmi->get_handles(group => 'processor')) {
			next unless defined $handle->keyword('processor-type') &&
					$handle->keyword('processor-type') =~ /Central Processor/i;
			$raw->{'physical-cpu-qty'}++;
			for (qw(processor-family processor-manufacturer processor-current-speed processor-id
				processor-type processor-version processor-signature processor-flags)) {
				my $value = $handle->keyword($_);
				if (!defined $value || (defined $value && $value =~ /Not Specified/i)) {
					$raw->{$_} = '';
				} else {
					$raw->{$_} = $value unless defined $raw->{$_} && $raw->{$_} =~ /\S/;
				}
			}
		}

		# Account for older versions of dmidecode output
		if ($raw->{'system-product'} =~ /\S/ && $raw->{'system-product-name'} !~ /\S/) {
			$raw->{'system-product-name'} = $raw->{'system-product'};
		}
		if ($raw->{'system-vendor'} =~ /\S/ && $raw->{'system-manufacturer'} !~ /\S/) {
			$raw->{'system-manufacturer'} = $raw->{'system-vendor'};
		}

		# Bodge together a pretend uuid
		if (!defined($raw->{'system-uuid'}) || $raw->{'system-uuid'} !~ /^[A-F0-9\-]{36}$/) {
			($raw->{'system-uuid'} = uc(join('-',
					($raw->{'processor-id'}||''),
					($raw->{'baseboard-product-name'}||''),
					($raw->{'baseboard-manufacturer'}||''),
					($raw->{'bios-version'}||''),
					($raw->{'bios-vendor'}||''),
					($raw->{'processor-signature'}||''),
					($raw->{'processor-type'}||''),
					($machine x 20),
				))) =~ s/[^A-F0-9]//g;
			$raw->{'system-uuid'} = sprintf('%s-%s-%s-%s-%s',
					substr($raw->{'system-uuid'},0,8),
					substr($raw->{'system-uuid'},7,4),
					substr($raw->{'system-uuid'},11,4),
					substr($raw->{'system-uuid'},15,4),
					substr($raw->{'system-uuid'},19,12),
				);
		}
	}

	# ==ifconfig==
	if (defined $raw->{ifconfig}) {
		$raw->{hwaddr} = [()];
		for (split(/\n/,$raw->{ifconfig})) {
			if (my ($if,$hwaddr) = $_ =~ /^(\S+)\s+.+?\s+HWaddr:?\s+(\S+)\s*$/i) {
				push @{$raw->{hwaddr}}, "$hwaddr $if" if $if !~ /:/;
			}
		}
	}

	# ==distribution==
	if (defined $raw->{distribution}) {
		if ($raw->{distribution} =~ /Red Hat Enterprise Linux/mi) {
			$raw->{distribution} = 'RHEL';
		} elsif ($raw->{distribution} =~ /Slackware/mi) {
			$raw->{distribution} = 'Slackware';
		} elsif ($raw->{distribution} =~ /Mandrake/mi) {
			$raw->{distribution} = 'Mandrake';
		} elsif ($raw->{distribution} =~ /SuSE/mi) {
			$raw->{distribution} = 'SuSE';
		} elsif ($raw->{distribution} =~ /Ubuntu/mi) {
			$raw->{distribution} = 'Ubuntu';
		} elsif ($raw->{distribution} =~ /Red\s*Hat/mi) {
			$raw->{distribution} = 'RedHat';
		} elsif ($raw->{distribution} =~ /Debian/mi) {
			$raw->{distribution} = 'Debian';
		} else {
			$raw->{distribution} = 'Linux';
		}
	}	

	return $raw;
}


sub create_tables {
	my @statements;
	my $statement;

	while (local $_ = <DATA>) {
		chomp;
		next if /^\s*(#|\-\-|;)/ || /^\s*$/;
		last if /^__END__\s*$/;
		s/\t/ /;

		if (/;\s*$/) {
			$statement .= $_;
			push @statements, $statement;
			$statement = '';
		} else {
			$statement .= $_;
		}
	}

	print "Recreating database tables ...";
	for my $statement (@statements) {
		$statement =~ s/;\s*//;
		my $sth = $dbh->prepare($statement);
		$sth->execute;
	}
	$dbh->commit;
	print " done\n";
}


sub get_model_id {
	my ($make,$model,$data) = @_;
	$make ||= 'Unknown';
	$model ||= 'Unknown';

	my $sth = $dbh->prepare('SELECT model_id FROM model WHERE make = ? AND model = ?');
	$sth->execute($make,$model);
	my ($model_id) = $sth->rows == 1 ? $sth->fetchrow_array : undef;

	if (!defined $model_id && $sth->rows <= 1) {
		my $form = (defined $data->{'chassis-type'} ? $data->{'chassis-type'} : undef);
		if ($make =~ /^Dell (Inc\.|Computer Corporation)$/ && $model =~ /^PowerEdge (?:750|([12])\d\d0)$/) {
			$form = defined $1 ? "${1}U" : '1U';
		}
		$sth = $dbh->prepare('INSERT INTO model (make,model,form) VALUES (?,?,?)');
		$sth->execute($make,$model,$form);
		$model_id = $dbh->{'mysql_insertid'};
	}

	$sth->finish;
	return $model_id;
}


sub update_record {
	my $ref = {@_};
	die "No table defined." if !exists $ref->{table};
	die "No column data defined." if !exists $ref->{cols};
	die "No where clause defined." if !exists $ref->{where};

	# Delete or check for existing row
	my @where; my @where_bind;
	while (my ($col,$value) = each %{$ref->{where}}) {
		push @where, sprintf(' %s = ? ',$col);
		push @where_bind, $value;
	}
	my $sql = sprintf('%s FROM %s WHERE %s',
			($ref->{delete_first} ? 'DELETE' : 'SELECT *'),
			$ref->{table},
			join(' AND ',@where),
		);
	my $sth = $dbh->prepare($sql);
	$sth->execute(@where_bind);


	# Update an existing row
	if (!$ref->{delete_first} && $sth->rows >= 1) {
		my @set; my @set_bind;
		while (my ($col,$value) = each %{$ref->{cols}}) {
			if (defined $value && $value eq 'NOW()') {
				push @set, sprintf(' %s = %s ',$col,$value);
			} else {
				push @set, sprintf(' %s = ? ',$col);
				push @set_bind, $value;
			}
		}
		$sql = sprintf('UPDATE %s SET %s WHERE %s',
				$ref->{table},
				join(', ',@set),
				join(' AND ',@where),
			);
		$sth = $dbh->prepare($sql);
		$sth->execute(@set_bind,@where_bind);

	# Insert a new row
	} else {
		my @cols; my @cols_bind; my @placeholders;
		while (my ($col,$value) = each %{$ref->{cols}}) {
			if (defined $value && $value eq 'NOW()') {
				push @cols, $col;
				push @placeholders, $value;
			} else {
				push @cols, $col;
				push @cols_bind, $value;
				push @placeholders, '?';
			}
		}
		$sql = sprintf('INSERT INTO %s (%s) VALUES (%s)',
				$ref->{table},
				join(',',@cols),
				join(',',@placeholders),
			);
		$sth = $dbh->prepare($sql);
		$sth->execute(@cols_bind);
	}

	$sth->finish;
}


sub update_database {
	my $data = shift;

	my $model_id = get_model_id(
			$data->{'system-manufacturer'},
			$data->{'system-product-name'},
			$data
		);

	update_record(	table => 'machine',
			cols => {
				model_id => $model_id,
				serial => $data->{'system-serial-number'},
				uuid => $data->{'system-uuid'},
				last_checked => 'NOW()',
			},
			where => {
				uuid => $data->{'system-uuid'},
			},
		);
	
	update_record(	table => 'host',
			cols => {
				uuid => $data->{'system-uuid'},
				hostname => $data->{HOSTNAME},
				os => $data->{'distribution'},
				last_checked => 'NOW()',
			},
			where => {
				hostname => $data->{HOSTNAME},
			},
		);

	my @probes = REMOTE_CMD =~ /==([a-z0-9\-\_]+)==/g;
	for my $probe (@probes) {
		update_record(	table => 'probe',
				cols => {
					uuid => $data->{'system-uuid'},
					probe => $probe,
					data => $data->{$probe},
				},
				where => {
					uuid => $data->{'system-uuid'},
					probe => $probe,
				},
			);
	}

	my $sth = $dbh->prepare('DELETE FROM host WHERE uuid = ? AND hostname != ?');
	$sth->execute($data->{'system-uuid'},$data->{HOSTNAME});

	my %seen_hwaddr;
	for (@{$data->{hwaddr}}) {
		my ($hwaddr,$interface) = split(/\s+/,$_);
		$hwaddr =~ s/[^0-9a-f]+//gi;
		next if $interface =~ /:/ || exists $seen_hwaddr{$hwaddr};
		$seen_hwaddr{$hwaddr} = 1;
		update_record(	table => 'nic',
				cols => {
					uuid => $data->{'system-uuid'},
					hwaddr => $hwaddr,
					interface => $interface,
				},
				where => {
					uuid => $data->{'system-uuid'},
					hwaddr => $hwaddr,
				},
			);
	}

	my ($cpu_speed) = ($data->{'processor-current-speed'}||'') =~ /(\d+)/;
	my @processor_flags = ();
	if (ref($data->{'processor-flags'}) eq 'ARRAY') {
		for (@{$data->{'processor-flags'}}) {
			if (/^(\S+)/) { push @processor_flags, $1; }
		}
	}

	update_record(	table => 'cpu',
			cols => {
				manufacturer => $data->{'processor-manufacturer'},
				family => $data->{'processor-family'},
				version => $data->{'processor-version'},
				speed => $cpu_speed,
				signature => $data->{'processor-signature'},
				flags => join(',',@processor_flags),
				qty => $data->{'physical-cpu-qty'},
				uuid => $data->{'system-uuid'},
			},
			where => {
				uuid => $data->{'system-uuid'},
			},
		);

	$sth->finish;
	$dbh->commit;
}


sub get_hostnames {
	print "Getting hostnames ...";

	my @data;
	if (-f HOSTS_SRC && -r HOSTS_SRC) {
		if (open(FH,'<',HOSTS_SRC)) {
			@data = <FH>;
			close(FH);
		}
	} else {
		eval {
			require LWP::Simple;
			@data = split(/\n/, LWP::Simple::get(HOSTS_SRC));
		};
		warn $@ if $@;
	}

	my $regex = HOSTS_REGEX;
	my %hosts;
	for (@data) {
		if (/$regex/) {
			$hosts{$1} = 1;
		}
	}

	my $hosts = scalar(keys %hosts) || 0;
	print " found $hosts host".($hosts == 1 ? '' : 's')."\n";
	return sort keys %hosts;
}


sub display_help {
	print qq{Syntax: $0 [-h] [-H <hostname>] [-C]
    -h              Display this help
    -H <hostname>   Only probe <hostname>
    -C              Recreate the database tables
};
}



__DATA__

DROP TABLE IF EXISTS nic;
DROP TABLE IF EXISTS cpu;
DROP TABLE IF EXISTS probe;
DROP TABLE IF EXISTS service;
DROP TABLE IF EXISTS host;
DROP TABLE IF EXISTS machine;
DROP TABLE IF EXISTS model;

#DROP TABLE IF EXISTS contact;
#DROP TABLE IF EXISTS history;

CREATE TABLE model (
		model_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
		make VARCHAR(32),
		model VARCHAR(32),
		form VARCHAR(16)
	) ENGINE=InnoDB;

CREATE TABLE machine (
		uuid CHAR(36) NOT NULL PRIMARY KEY,
		serial VARCHAR(16),
		model_id INT UNSIGNED,
		created DATETIME NOT NULL,
		last_checked TIMESTAMP NOT NULL,
		FOREIGN KEY (model_id) REFERENCES model(model_id)
	) ENGINE=InnoDB;

CREATE TABLE host (
		hostname VARCHAR(32) NOT NULL PRIMARY KEY,
		uuid CHAR(36) NOT NULL,
		os ENUM('Debian','Mandrake','RedHat','RHEL','Ubuntu','Gentoo','Slackware','SuSE','Windows','Linux'),
		created DATETIME NOT NULL,
		last_checked TIMESTAMP NOT NULL,
		FOREIGN KEY (uuid) REFERENCES machine(uuid) ON DELETE CASCADE
	) ENGINE=InnoDB;

CREATE TABLE service (
		hostname VARCHAR(32) NOT NULL,
		servicename VARCHAR(32) NOT NULL,
		description VARCHAR(255),
		type ENUM('Production','Staging','Development','Infrastructure','Research','Other') NOT NULL,
		PRIMARY KEY (hostname,servicename),
		FOREIGN KEY (hostname) REFERENCES host(hostname) ON DELETE CASCADE
	) ENGINE=InnoDB;

CREATE TABLE nic (
		hwaddr CHAR(12) NOT NULL,
		uuid CHAR(36) NOT NULL,
		interface VARCHAR(8),
		PRIMARY KEY (hwaddr,uuid),
		FOREIGN KEY (uuid) REFERENCES machine(uuid) ON DELETE CASCADE
	) ENGINE=InnoDB;

CREATE TABLE cpu (
		uuid CHAR(36) NOT NULL PRIMARY KEY,
		manufacturer VARCHAR(16),
		family VARCHAR(16),
		version VARCHAR(64),
		speed INT(4) UNSIGNED,
		signature VARCHAR(64),
		flags VARCHAR(255),
		qty INT(2) UNSIGNED,
		FOREIGN KEY (uuid) REFERENCES machine(uuid) ON DELETE CASCADE
	) ENGINE=InnoDB;

CREATE TABLE probe (
		uuid CHAR(36) NOT NULL,
		probe VARCHAR(16) NOT NULL,
		data TEXT,
		PRIMARY KEY (uuid,probe),
		FOREIGN KEY (uuid) REFERENCES machine(uuid) ON DELETE CASCADE
	) ENGINE=InnoDB;

__END__

BatchMode yes
CheckHostIP no
ConnectTimeout 6
StrictHostKeyChecking no
PreferredAuthentications publickey
IdentityFile ~/.ssh/id_dsa_root
IdentityFile ~/.ssh/id_dsa
NoHostAuthenticationForLocalhost yes
ConnectionAttempts 1
PasswordAuthentication no
ForwardAgent yes

Host server1.acmecompany.com
        Port 1033

Host server2.acmecompany.com
        User admin

Host *
        User root
        Port 22

