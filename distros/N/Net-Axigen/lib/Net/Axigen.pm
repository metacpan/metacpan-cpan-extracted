package Net::Axigen;

use 5.008008;
use strict;
use warnings;

use Net::Telnet ();
use Encode;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.11'; 

#==================================================================
# new()
#==================================================================
sub new
{
  my $this = shift @_;
  my $host = shift @_;
  my $port = shift @_;
  my $login = shift @_;
  my $password = shift @_;
  my $timeout = shift @_;
  my $self = {};
	
  $self->{ host } = $host;
  $self->{ port } = $port;
  $self->{ login } = $login;
  $self->{ password } = $password;

	if($timeout) { $self->{ timeout }=$timeout; } else { $self->{ timeout } = 10; }
  
  $self->{ t } = 0;
  $self->{ version_full } = ''; # Axigen version
  $self->{ version_major } = '';
  $self->{ version_minor } = '';
  $self->{ version_revision } = '';
  $self->{ os_version_full } = '';
  $self->{ os_name } = '';
  $self->{ os_platform } = '';
  $self->{ datadir } = '';

	$self->{ locale } = 'windows-1251'; # encoding for utf-8 convertor, default Cyrillic
  return(bless($self, $this));
}

# ==================================================================
# connect()
# ==================================================================
sub connect
{
  my $this = shift @_;

	$this->{t} = new Net::Telnet(Timeout => $this->{timeout}, Host => $this->{host}, Port => $this->{port});
	my $login=$this->{login};
	my $password=$this->{password};
	
	$this->{t}->waitfor('/<login> *$/i');
	my @result = $this->{t}->cmd(String   => 'GET VERSION', Prompt  => '/<login> *$/i');
	
	# The last string of the array contains result of execution of the command
	my $rc_str = @result[scalar(@result) - 1];
	if(substr($rc_str,0,3) ne '+OK') { die 'Net::Axigen::connect, '.$rc_str; }
	
	# We delete superfluous string from the end of the array
	pop @result; 
	
	# Sample of version full string
	# 7.0.0, (FreeBSD/i386)|FreeBSD|i386
	($this->{version_full}, my $os) = split('\s+', $result[0]);
	($this->{version_major}, $this->{version_minor}, $this->{version_revision}) = split('\.+', $this->{version_full});
	($this->{os_version_full}, $this->{os_name}, $this->{os_version_platform}) = split('\|+', $os);
	
	if($this->{os_name}=~m/bsd/i) { $this->{ datadir } = '/var/axigen'; }
	else	{ $this->{ datadir } = '/var/opt/axigen'; }
	
	$this->{t}->print("USER $login");
	$this->{t}->waitfor('/<password> *$/i');
	$this->{t}->print($password);
	$this->{t}->waitfor('/<#> *$/i');
}

# ==================================================================
# close
# ==================================================================
sub close
{
  my $this = shift @_;
	return($this->{t}->close);
}

# ==================================================================
# get_version()
# ==================================================================
sub get_version
{
  my $this = shift @_;
	return($this->{version_major}, $this->{version_minor}, $this->{version_revision});
}

# ==================================================================
# get_os_version()
# ==================================================================
sub get_os_version
{
  my $this = shift @_;
	return($this->{os_version_full}, $this->{os_name}, $this->{os_version_platform});
}

# ==================================================================
# _cmd
# ==================================================================
sub _cmd
{
  my $this = shift @_;
  my $cmd = shift @_;
  my $context = shift @_; # wait this context after command execution
	my %r; # command execution result
	
	my @result = $this->{t}->cmd(String   => $cmd, Prompt  => '/<'.$context.'#> *$/i');

	# The last string of the array contains result of execution of the command
	my $rc_str = @result[scalar(@result) - 1];
	
	$r{rc_str} = $rc_str; # command execution results string
	$r{result} = \@result; # ref to string array returned by command

	if(substr($rc_str,0,3) eq '+OK') { $r{ rc } = 1; } # success
	else { $r{ rc } = 0; } # error
	return \%r;
}

# ==================================================================
# listDomains
# ==================================================================
sub listDomains
{
  my $this = shift @_;
	
	my $r=$this->_cmd('LIST Domains', '');
	if(!$r->{rc}) { die "Net::Axigen::listDomains: ".$r->{rc_str}; }
	
	my @domain_list;
	my $domains=$r->{result};
	
	# Delete superfluous string from the beginning and the end of the array
	splice(@$domains, 0, 5);
	pop @$domains; pop @$domains;
	
	# Select names of domains, the total and used size
	foreach my $line(@$domains)
	{
		(my $domain, my $size_total, my $size_used) = split('\s+', $line);
		push(@domain_list, $domain);
	}
	return \@domain_list;
}

# ==================================================================
# listDomainsEx
# ==================================================================
sub listDomainsEx
{
  my $this = shift @_;
	my %domain_info=();
	
	my $r=$this->_cmd('LIST Domains', '');
	if(!$r->{rc}) { die "Net::Axigen::listDomainsEx: ".$r->{rc_str};}
	my $domains=$r->{result};
	
	# Delete superfluous string from the beginning and the end of the array
	splice(@$domains, 0, 5);
	pop @$domains; pop @$domains;
	
	# Select names of domains, the total and used size
	foreach my $line(@$domains)
	{
		(my $domain, my $size_total, my $size_used) = split('\s+', $line);
		my %ds = ('total' => $size_total, 'used' => $size_used);
		$domain_info{ $domain }= \%ds;
	} 
	return \%domain_info;
}

# ==================================================================
# _listAccounts
# ==================================================================
sub _listAccounts
{
  my $this = shift @_;
	my $r=$this->_cmd('LIST ACCOUNTS', 'domain');
	if(!$r->{rc}) { die "Net::Axigen::_listAccounts: ".$r->{rc_str}.": ".'LIST ACCOUNTS'; }	
	
	my $accounts=$r->{result};
	
	# Delete superfluous string from the beginning and the end of the accounts array
	splice(@$accounts, 0, 5);
	pop @$accounts; pop @$accounts;

	# Delete CRLF
	foreach my $line(@$accounts) { chomp ($line);	}
	return $accounts;
}

# ==================================================================
# listAccounts
# ==================================================================
sub listAccounts
{
  my $this = shift @_;
  my $domain = shift @_;
	my $r;

	if($this->_hasDomain($domain))
	{
		$r=$this->_cmd("UPDATE DOMAIN NAME $domain", 'domain');
		if(!$r->{rc}) { die "Net::Axigen::listAccounts: ".$r->{rc_str}.": "."UPDATE DOMAIN NAME $domain"; }

		my $accounts_list = $this->_listAccounts($domain);
		$r=$this->_cmd("BACK", '');
		if(!$r->{rc}) { die "Net::Axigen::listAccounts: ".$r->{rc_str}.": "."BACK"; }
		return $accounts_list;
	}
	else
	{
		die 'ERROR Net::Axigen::listAccounts: Domain '.$domain.' does not exist in AXIGEN';
	}
}

# ==================================================================
# listAccountsEx
# ==================================================================
sub listAccountsEx
{
  my $this = shift @_;
  my $domain = shift @_;
	my $r;
	my %accounts_info=();

	if($this->_hasDomain($domain))
	{
		$r=$this->_cmd("UPDATE DOMAIN NAME $domain", 'domain');
		if(!$r->{rc}) { die "Net::Axigen::listAccountsEx: ".$r->{rc_str}.": "."UPDATE DOMAIN NAME $domain"; }

		my $accounts_list = $this->_listAccounts($domain);
		foreach my $ptr(@$accounts_list) 
		{
			my %acc = ('firstName' => $this->_getAccountAttr($ptr, 'firstName'), 'lastName' => $this->_getAccountAttr($ptr, 'lastName'));
			$accounts_info{ $ptr }= \%acc;
		}

		$r=$this->_cmd("BACK", '');
		if(!$r->{rc}) { die "Net::Axigen::listAccountsEx: ".$r->{rc_str}.": "."BACK"; }
		return \%accounts_info;
	}
	else
	{
		die 'ERROR Net::Axigen::listAccountsEx: Domain '.$domain.' does not exist in AXIGEN';
	}
}

# ==================================================================
# _getAccountAttr
# ==================================================================
sub _getAccountAttr
{
  my $this = shift @_;
  my $account = shift @_;
  my $attr = shift @_;
	my $r;
	
	$r=$this->_cmd("UPDATE ACCOUNT $account", 'domain-account');
	if(!$r->{rc}) { die "Net::Axigen::_getAccountAttr: ".$r->{rc_str}.": "."UPDATE ACCOUNT $account"; }
	
	$r=$this->_cmd("CONFIG ContactInfo", 'domain-account-contactInfo');
	if(!$r->{rc}) { die "Net::Axigen::_getAccountAttr: ".$r->{rc_str}.": "."CONFIG ContactInfo"; }
	
	$r=$this->_cmd("SHOW ATTR $attr", 'domain-account-contactInfo');
	if(!$r->{rc}) { die "Net::Axigen::_getAccountAttr: ".$r->{rc_str}.": "."show attr $attr"; }

  (my $atr_name, my $eq, my $attr_val) = split('\s+', $r->{result}[0]);
  $attr_val =~ s/"//g;
	
	$r=$this->_cmd("BACK", 'domain-account');
	if(!$r->{rc}) { die "Net::Axigen::_getAccountAttr: ".$r->{rc_str}.": "."BACK"; }

	$r=$this->_cmd("BACK", 'domain');
	if(!$r->{rc}) { die "Net::Axigen::_getAccountAttr: ".$r->{rc_str}.": "."BACK"; }
	
	return $attr_val;
}

# ==================================================================
# createDomain
# ==================================================================
sub createDomain
{
  my $this = shift @_;
  my $domain = shift @_;
  my $postmaster_pwd = shift @_;
	my $maxFiles = shift @_; # Quantity of files of storage. Storage file size: maxFileSize KByte
	my $maxFileSize=262144; # 256 MByte
	
	my $r;

	if(!$this->_hasDomain($domain))
	{
		# Full path to domain folder
		my $domain_location= $this->{datadir}.'/domains/'.$domain;

		# Axigen cmd sample:
		# 	CREATE DOMAIN NAME ddomain.ru DOMAINLOCATION /var/axigen/domains/ddomain.ru POSTMASTERPASSWD test123
		# 	add messageslocation /var/axigen/domains/ddomain.ru/messages?maxFileSize=262144&maxFiles=128
		
		my $cmd = "CREATE DOMAIN NAME $domain DOMAINLOCATION $domain_location POSTMASTERPASSWD $postmaster_pwd";
		$r=$this->_cmd($cmd, 'domain-create');
		if($r->{rc})
		{
			# GroupWare support
			my $cmd1 = "SET maclSupport yes";
			$r=$this->_cmd($cmd1, 'domain-create'); 			
			if(!$r->{rc}) { die "Net::Axigen::createDomain: ".$r->{rc_str}.": ".$cmd1; }

			# Messages file storage limit - 4 files on 256 Mbyte
			
			if($maxFiles > 128) { $maxFiles=128;}
			if($maxFiles < 1) { $maxFiles=1;}
			
			$cmd1 = "add messageslocation $domain_location".'/messages?maxFileSize='.$maxFileSize.'&maxFiles='.$maxFiles;
			$r=$this->_cmd($cmd1, 'domain-create'); 			
			if(!$r->{rc}) { die "Net::Axigen::createDomain: ".$r->{rc_str}.": ".$cmd1; }
			
			$r=$this->_cmd("COMMIT", '');
			if(!$r->{rc}) { die "Net::Axigen::createDomain: ".$r->{rc_str}.": ".$cmd; }
		}
		else { die "Net::Axigen::createDomain: ".$r->{rc_str}.": ".$cmd; }
		$this->saveConfig();
	}
}

# ==================================================================
# registerDomain
# ==================================================================
sub registerDomain
{
  my $this = shift @_;
  my $domain = shift @_;
	my $r;

	if(!$this->_hasDomain($domain))
	{
		# Full path to domain folder
		my $domain_location= $this->{datadir}.'/domains/'.$domain;

		# REGISTER DOMAIN DOMAINLOCATION /var/axigen/domains/ddomain.ru
		my $cmd = "REGISTER DOMAIN DOMAINLOCATION $domain_location";
		$r=$this->_cmd($cmd, 'domain-register');
		if($r->{rc})
		{
			$r=$this->_cmd("COMMIT", '');
			if(!$r->{rc}) { die "Net::Axigen::registerDomain: ".$r->{rc_str}.": ".$cmd; }
		}
		else { die "Net::Axigen::registerDomain: ".$r->{rc_str}.": ".$cmd; }
		$this->saveConfig();
	}
}

# ==================================================================
# unregisterDomain
# ==================================================================
sub unregisterDomain
{
  my $this = shift @_;
  my $domain = shift @_;
	my $r;

	if($this->_hasDomain($domain))
	{
		my $cmd = "UNREGISTER DOMAIN NAME $domain";
		$r=$this->_cmd($cmd, '');
		if(!$r->{rc}) { die "Net::Axigen::unregisterDomain: ".$r->{rc_str}.": ".$cmd; }
		$this->saveConfig();
	}
}

# ==================================================================
# _hasDomain
# ==================================================================
sub _hasDomain
{
  my $this = shift @_;
  my $domain = shift @_;
	my $domain_list = $this->listDomains();
	return grep { $_ eq $domain } @$domain_list;
}

# ==================================================================
# _hasAccount
# ==================================================================
sub _hasAccount
{
  my $this = shift @_;
  my $domain = shift @_;
  my $account = shift @_;
	my $accounts_list = $this->_listAccounts($domain);
	return grep { $_ eq $account } @$accounts_list;
}

# ==================================================================
# addAccount
# ==================================================================
sub addAccount
{
  my $this = shift @_;
  my $domain = shift @_;
  my $user = shift @_;
  my $pwd = shift @_;
	
	my $r;
	my $cmd;
	
	# The domain exists
	if($this->_hasDomain($domain))
	{
		$r=$this->_cmd("UPDATE DOMAIN NAME $domain", 'domain');
		
		# The account does not exist
		if(!$this->_hasAccount($domain, $user))
		{
		  $cmd="ADD ACCOUNT NAME $user PASSWD $pwd";
			$r=$this->_cmd($cmd, 'domain-account');
			$r=$this->_cmd('COMMIT', 'domain'); 
			if(!$r->{rc}) { die "Net::Axigen::addAccount: ".$r->{rc_str}.": ".$cmd; }
			
			$r=$this->_cmd('COMMIT', ''); 
			if(!$r->{rc}) { die "Net::Axigen::addAccount: ".$r->{rc_str}.": ".$cmd; }
		}
		else
		{
			$r=$this->_cmd('BACK', ''); 
			if(!$r->{rc}) { die "Net::Axigen::addAccount: ".$r->{rc_str}.": ".$cmd; }
		}
	}
	else
	{
		die 'ERROR Net::Axigen::addAccount: Domain '.$domain.' does not exist in AXIGEN';
	}
}

# ==================================================================
# removeAccount
# ==================================================================
sub removeAccount
{
  my $this = shift @_;
  my $domain = shift @_;
  my $user = shift @_;
	
	my $r;
	my $cmd;
	
	if($this->_hasDomain($domain))
	{
		$cmd="UPDATE DOMAIN NAME $domain";
		$r=$this->_cmd($cmd, 'domain');
		
		if($this->_hasAccount($domain, $user))
		{
		  $cmd="REMOVE ACCOUNT NAME $user";
			$r=$this->_cmd($cmd, 'domain');
			$r=$this->_cmd('COMMIT', ''); 
			if(!$r->{rc}) { die "Net::Axigen::removeAccount: ".$r->{rc_str}.": ".$cmd; }
		}
		else
		{
			$r=$this->_cmd('BACK', ''); 
			if(!$r->{rc}) { die "Net::Axigen::removeAccount: ".$r->{rc_str}.": ".$cmd; }
		}
	}
	else
	{
		die 'ERROR Net::Axigen::removeAccount: Domain '.$domain.' does not exist in AXIGEN';
	}
}

# ==================================================================
# setAccountContactData
# ==================================================================
sub setAccountContactData
{
  my $this = shift @_;
  my $domain = shift @_;
  my $user = shift @_;
  my $firstName = shift @_;
  my $lastName = shift @_;

	my $r;
	my $cmd;

	$firstName=$this->to_utf8($firstName);
	$lastName=$this->to_utf8($lastName);
	
	if($this->_hasDomain($domain))
	{
		$cmd="UPDATE DOMAIN NAME $domain";
		$r=$this->_cmd($cmd, 'domain');
		if(!$r->{rc}) { die "Net::Axigen::setAccountContactData: ".$r->{rc_str}.": ".$cmd; }
		
		if($this->_hasAccount($domain, $user))
		{
			$cmd="UPDATE ACCOUNT NAME $user";
			$r=$this->_cmd($cmd, 'domain-account');
			$r=$this->_cmd("CONFIG CONTACTINFO", 'domain-account-contactInfo');
			
			$r=$this->_cmd("set firstName \"$firstName\"", 'domain-account-contactInfo');
			if(!$r->{rc}) { die "Net::Axigen::setAccountContactData: ".$r->{rc_str}.": ".$cmd; }
			$r=$this->_cmd("set lastName \"$lastName\"", 'domain-account-contactInfo');
			if(!$r->{rc}) { die "Net::Axigen::setAccountContactData: ".$r->{rc_str}.": ".$cmd; }
			
			$r=$this->_cmd('DONE', 'domain-account'); 
			if(!$r->{rc}) { die "Net::Axigen::setAccountContactData: ".$r->{rc_str}.": ".$cmd; }
			$r=$this->_cmd('COMMIT', 'domain');
			if(!$r->{rc}) { die "Net::Axigen::setAccountContactData: ".$r->{rc_str}.": ".$cmd; }
			$r=$this->_cmd('COMMIT', '');
			if(!$r->{rc}) { die "Net::Axigen::setAccountContactData: ".$r->{rc_str}.": ".$cmd; }
		}
		else
		{
			$r=$this->_cmd('BACK', '');
			if(!$r->{rc}) { die "Net::Axigen::setAccountContactData: ".$r->{rc_str}.": ".'BACK'; }
		}
	}
	else
	{
		die 'ERROR: Net::Axigen::setAccountContactData Domain '.$domain.' does not exist in AXIGEN';
	}
}

# ==================================================================
# setQuotaLimitNotification 
# ==================================================================
sub setQuotaLimitNotification
{
  my $this = shift @_;
  my $domain = shift @_;
  my $user = shift @_;
  my $notificationSubject = shift @_;
  my $notificationMsg = shift @_;

	my $r;
	my $cmd;

	$notificationMsg=$this->to_utf8($notificationMsg);
	$notificationSubject=$this->to_utf8($notificationSubject);
	
	if($this->_hasDomain($domain))
	{
		$cmd="UPDATE DOMAIN NAME $domain";
		$r=$this->_cmd($cmd, 'domain');
		if(!$r->{rc}) { die "Net::Axigen::setQuotaLimitNotification: ".$r->{rc_str}.": ".$cmd; }
		
		if($this->_hasAccount($domain, $user))
		{
			$cmd="UPDATE ACCOUNT NAME $user";
			$r=$this->_cmd($cmd, 'domain-account');
			$r=$this->_cmd("CONFIG Quotas", 'domain-account-quotas');
			
			$r=$this->_cmd("SET quotaLimitNotificationSubject \"$notificationSubject\"", 'domain-account-quotas');

			$this->{t}->print("ESET quotaLimitNotificationBody");
			$this->{t}->print("$notificationMsg");
			$this->{t}->print(".");
			$this->{t}->waitfor('/<domain-account-quotas#> *$/i');
			
			$r=$this->_cmd('DONE', 'domain-account'); 
			if(!$r->{rc}) { die "Net::Axigen::setQuotaLimitNotification: ".$r->{rc_str}.": ".$cmd; }
			$r=$this->_cmd('COMMIT', 'domain');
			if(!$r->{rc}) { die "Net::Axigen::setQuotaLimitNotification: ".$r->{rc_str}.": ".$cmd; }
			$r=$this->_cmd('COMMIT', '');
			if(!$r->{rc}) { die "Net::Axigen::setQuotaLimitNotification: ".$r->{rc_str}.": ".$cmd; }
		}
		else
		{
			$r=$this->_cmd('BACK', '');
			if(!$r->{rc}) { die "Net::Axigen::setQuotaLimitNotification: ".$r->{rc_str}.": ".'BACK'; }
		}
	}
	else
	{
		die 'ERROR: Net::Axigen::setQuotaLimitNotification Domain '.$domain.' does not exist in AXIGEN';
	}
}


# ==================================================================
# setAccountPassword
# ==================================================================
sub setAccountPassword
{
  my $this = shift @_;
  my $domain = shift @_;
  my $user = shift @_;
  my $passwd = shift @_;

	my $r;
	my $cmd;

	if($this->_hasDomain($domain))
	{
		$r=$this->_cmd("UPDATE DOMAIN NAME $domain", 'domain');
		if($this->_hasAccount($domain, $user))
		{
			$r=$this->_cmd("UPDATE ACCOUNT NAME $user", 'domain-account');
			$r=$this->_cmd("set password $passwd", 'domain-account');
			$r=$this->_cmd('COMMIT', 'domain');
			if(!$r->{rc}) { die "Net::Axigen::setAccountPassword: ".$r->{rc_str}.": ".'COMMIT'; }
			$r=$this->_cmd('COMMIT', ''); 
			if(!$r->{rc}) { die "Net::Axigen::setAccountPassword: ".$r->{rc_str}.": ".'COMMIT'; }
		}
		else
		{
			$r=$this->_cmd('BACK', '');
			if(!$r->{rc}) { die "Net::Axigen::setAccountPassword: ".$r->{rc_str}.": ".'BACK'; }
		}
	}
	else
	{
		die 'ERROR: Net::Axigen::setAccountPassword Domain '.$domain.' does not exist in AXIGEN';
	}
}

# ==================================================================
# setAccountWebMailLanguage
# ==================================================================
sub setAccountWebMailLanguage
{
  my $this = shift @_;
  my $domain = shift @_;
  my $user = shift @_;
  my $lang = shift @_;

	my $r;
	my $cmd;
	if($this->_hasDomain($domain))
	{
		$r=$this->_cmd("UPDATE DOMAIN NAME $domain", 'domain');
		if($this->_hasAccount($domain, $user))
		{
			$r=$this->_cmd("UPDATE ACCOUNT NAME $user", 'domain-account');
			$r=$this->_cmd("CONFIG WebmailData", 'domain-account-webmaildata');
			$r=$this->_cmd("set language $lang", 'domain-account-webmaildata');
			
			$r=$this->_cmd('DONE', 'domain-account');
			if(!$r->{rc}) { die "Net::Axigen::setAccountWebMailLanguage: ".$r->{rc_str}.": ".'DONE'; }
			$r=$this->_cmd('COMMIT', 'domain');
			if(!$r->{rc}) { die "Net::Axigen::setAccountWebMailLanguage: ".$r->{rc_str}.": ".'COMMIT'; }
			$r=$this->_cmd('COMMIT', '');
			if(!$r->{rc}) { die "Net::Axigen::setAccountWebMailLanguage: ".$r->{rc_str}.": ".'COMMIT'; }
		}
		else
		{
			$r=$this->_cmd('BACK', '');
			if(!$r->{rc}) { die "Net::Axigen::setAccountWebMailLanguage: ".$r->{rc_str}.": ".'BACK'; }
		}
	}
	else
	{
		die 'ERROR: Net::Axigen::setAccountWebMailLanguage Domain '.$domain.' does not exist in AXIGEN';
	}
}

# ==================================================================
# setDomainQuotas
# ==================================================================
sub setDomainQuotas
{
  my $this = shift @_;
  my $domain = shift @_;
  my $q = shift @_;
	
	my $r;
	
	if($this->_hasDomain($domain))
	{
		$r=$this->_cmd("UPDATE DOMAIN NAME $domain", 'domain');
		$r=$this->_cmd('CONFIG adminLimits', 'domain-adminLimits');
		$r=$this->_cmd('set maxAccounts '.$q->{ maxAccounts }, 'domain-adminLimits');
		$r=$this->_cmd('set maxAccountMessageSizeQuota '.$q->{ maxAccountMessageSizeQuota }, 'domain-adminLimits');
		$r=$this->_cmd('set maxPublicFolderMessageSizeQuota '.$q->{ maxPublicFolderMessageSizeQuota }, 'domain-adminLimits');
		$r=$this->_cmd('COMMIT', 'domain'); 		
		if(!$r->{rc}) { die "Net::Axigen::setDomainQuotas: ".$r->{rc_str}.": ".$domain; }
			
		$r=$this->_cmd('CONFIG accountDefaultQuotas', 'domain-accountDefaultQuotas');
		$r=$this->_cmd('set quotaLimitNotificationEnabled yes', 'domain-accountDefaultQuotas');

		# Default maximum size in KB of messages in a folder
		$r=$this->_cmd('set messageSize '.$q->{ messageSize }, 'domain-accountDefaultQuotas');
		
		# Maximum size in KB of all messages in all folders
		$r=$this->_cmd('set totalMessageSize '.$q->{ totalMessageSize }, 'domain-accountDefaultQuotas');

		$r=$this->_cmd('DONE', 'domain'); 
		if(!$r->{rc}) { die "Net::Axigen::setDomainQuotas: ".$r->{rc_str}.": ".$domain; }
		$r=$this->_cmd('COMMIT', ''); 		
		if(!$r->{rc}) { die "Net::Axigen::setDomainQuotas: ".$r->{rc_str}.": ".$domain; }
	}
	else
	{
		die 'ERROR: Net::Axigen::setDomainQuotas Domain '.$domain.' does not exist in AXIGEN';
	}
}

# ==================================================================
# saveConfig
# ==================================================================
sub saveConfig
{
  my $this = shift @_;
	my $r=$this->_cmd('SAVE CONFIG', '');
	if(!$r->{rc}) { die "Net::Axigen::saveConfig: ".$r->{rc_str}; }
}

# ==================================================================
# compactAll
# ==================================================================
sub compactAll
{
  my $this = shift @_;
	my $domain = shift @_; # compacted domain
	my $forced = shift @_; # force compacting
	
	my $r;
	
	if($this->_hasDomain($domain))
	{
		$r=$this->_cmd("UPDATE DOMAIN NAME $domain", 'domain');
	
		my $cmd='COMPACT ALL';
		if($forced) { $cmd=$cmd.' FORCED'; }
		my $r=$this->_cmd($cmd, 'domain');
		
		$r=$this->_cmd('COMMIT', ''); 		
		if(!$r->{rc}) { die "Net::Axigen::compactAll: ".$r->{rc_str}.": ".$domain; }
	}
	else
	{
		die 'ERROR: Net::Axigen::compactAll Domain '.$domain.' does not exist in AXIGEN';
	}
}

# ==================================================================
# compactAllDomains
# ==================================================================
sub compactAllDomains
{
  my $this = shift @_;
	my $forced = shift @_;
	
	my $domain_list = $this->listDomains();
	foreach my $domain(@$domain_list) 
	{ 
		$this->compactAll($domain, $forced);
	}	
}

# ================================================
# to_utf8
# Преобразовать из win1251 в UTF8
# ================================================
sub to_utf8($)
{
  my $this = shift @_;
  my $str = shift @_;
  Encode::from_to($str, $this->{ locale }, 'utf-8');
  return $str;
}

1;

__END__

=pod
=head1 NAME

Net::Axigen - Perl extension for Gecad Technologies Axigen Mail Server (www.axigen.com).
This module use Axigen CLI interface.

=head1 DESCRIPTION

Module Net::Axigen is intended for creation and removal of domains, accounts, handle of quotas, 
and also execution of other necessary operations on handle of a Gecad Technologies Axigen Mail Server.

Operation with a mail server is carried out by means of Telnet protocol with Net::Telnet module usage.

Note: Gecad Technologies do not offer support and should not be contacted for support regarding the Perl module Net::Axigen.
Gecad Technologies and the author of the Net::Axigen module do not take full responsibility 
in case of miss-usage of the Perl module or for any damage caused in this matter.

=head1 SYNOPSIS

=head2 Connections

	use Net::Axigen;
	my $axi = Net::Axigen->new('127.0.0.1', 7000, 'admin', 'password', 10);
	$axi->connect();
	...
	my $rc=$axi->close();

=head2 Axigen Mail Server and OS version

	my ($version_major, $version_minor, $version_revision)=$axi->get_version();
	my ($os_version_full, $os_name, $os_version_platform)=$axi->get_os_version();

=head2 Domains
	
	$axi->createDomain($domain, $postmaster_password, $maxFiles);
	$axi->unregisterDomain('my-domain.com');
	$axi->registerDomain('my-domain.com');

	my $domain_list = $axi->listDomains();
	foreach my $ptr(@$domain_list) { print "$ptr\n"; }

	my $domain_info = $axi->listDomainsEx();
	print "Domain \t\tUsed\tTotal\n";
	foreach my $domain( sort keys %$domain_info) 
	{
	  print "$domain:\t".$domain_info->{ $domain }->{used}."\t".$domain_info->{ $domain }->{total}."\n"; 
	}

=head2 Accounts
	
	my $account_list = $axi->listAccounts('my-domain.com');
	foreach my $ptr(@$account_list) { print "$ptr\n"; }

  my $account_list = $axi->listAccountsEx($domain);
  print "Account \t\tFirst Name\tSecond Name\n";
  foreach my $acc( sort keys %$account_list) 
  {
     print "$acc\t".$account_list->{ $acc }->{firstName}."\t".$account_list->{ $acc }->{lastName}."\n"; 
  }
	
	$axi->addAccount($domain, $user, $password);
	$axi->removeAccount($domain, $user);

	$axi->setAccountContactData($domain, $user, $firstName, $lastName);
	$axi->setQuotaLimitNotification($domain, $user, $notificationSubject, $notificationMsg);
	$axi->setAccountPassword($domain, $user, $password);

=head2 Quotas

	my $quota = 
	{ 
	  maxAccounts => 10, # admin limits
	  maxAccountMessageSizeQuota => 200000, # admin limits
	  maxPublicFolderMessageSizeQuota => 300000, # admin limits
	  messageSize => 20000, # domain quota
	  totalMessageSize => 200000 # domain quota
	};
	$axi->setDomainQuotas($domain, $quota);
	
	# $domain - the domain in which the account will be removed;
	# $quota - quota hash ptr

=head2 Storage Files

	$axi->compactAll($domain);
	$axi->compactAllDomains();

=head1 SAMPLES

Samples of usage of the Net::Axigem module are in folder Net-Axigen\samples

	samples/domain_create.pl
	samples/domain_unregister.pl
	samples/domain_register.pl
	samples/add_account.pl
	samples/remove_account.pl
	samples/compact_domains.pl
	samples/accounts_info.pl
	samples/io_exception_dbg.pl

=head1 METHODS

=over

=item new()

Instantiates a new instance of a Net::Axigen.

 my $axi = Net::Axigen->new($host, $port, $user, $password, $timeout);
 
 # $host - Mail Server host
 # $port - CLI connection port
 # $user - CLI admin user
 # $password - admin password
 # $timeout - Telnet timeout

=item connect()

Connect to Axigen Mail Server

 $axi->connect();

=item close()

Close Axigen Mail Server connection

 my $rc=$axi->close();

=item get_version()

Get Axigen mail Server Version

 my ($version_major, $version_minor, $version_revision)=$axi->get_version();

=item get_os_version()

Get OS Version

 my ($os_version_full, $os_name, $os_version_platform)=$axi->get_os_version();

=item listDomains()

List all domains, registered on Axigen Mail Server
	
 my $domain_list = $axi->listDomains();
 foreach my $ptr(@$domain_list) { print "$ptr\n"; }

=item listDomainsEx()

List all domains, registered on Axigen Mail Server, get the total and used size

 my $domain_info = $axi->listDomainsEx();
 print "Domain \t\tUsed\tTotal\n";
 foreach my $domain( sort keys %$domain_info)
 {
  print "$domain:\t".$domain_info->{ $domain }->{used}."\t".$domain_info->{ $domain }->{total}."\n"; 
 }

=item createDomain()

Create domain.

 $axi->createDomain($domain, $postmaster_password, $maxFiles);
 
 # $domain - created domain name;
 # $postmaster_password - password for postmaster@domain account;
 # $maxFiles - Max quantity of domain storage files (filesize 256 Mbyte)

=item registerDomain()

Register unregistered domain.

 $axi->registerDomain($domain);
 # $domain - registered domain name;

=item unregisterDomain()

Unregister domain.

 $axi->unregisterDomain($domain);
 # $domain - unregistered domain name;

=item setDomainQuotas()

Set domain quotas.

 my $quota = 
 { 
   # Maximum quantity of mail boxes (admin limit)
   maxAccounts => 10, 
	
   # The maximum size of mail boxes (admin limit)
   maxAccountMessageSizeQuota => 20000,
	
   # The maximum size of Public Folders (admin limit)
   maxPublicFolderMessageSizeQuota => 30000,
	 
   # The maximum size mail messages (domain quota)
   messageSize => 20000,
	 
   # The maximum size of mail boxes (domain quota)
   totalMessageSize => 200000
 };
 $axi->setDomainQuotas($domain, $quota);
 
 # $domain - the domain in which the account will be removed;
 # $quota - quota hash ptr

=item setQuotaLimitNotification()

Set account quota limit notification - subject and message.

 $axi->setQuotaLimitNotification($domain, $user, $firstName, $lastName);
 
 # $domain - the domain in which the account will be removed;
 # $user - account name;
 # $notificationSubject - subject; 
 # $notificationMsg - message
 

=item listAccounts()

List all domain accounts.

 my $account_list = $axi->listAccounts('my-domain.com');
 foreach my $ptr(@$account_list) { print "$ptr\n"; }

=item listAccountsEx()

List all domain accounts whith contact information.

 my $account_list = $axi->listAccountsEx($domain);
 print "Account \t\tFirst Name\tSecond Name\n";
 foreach my $acc( sort keys %$account_list) 
 {
   print "$acc\t".$account_list->{ $acc }->{firstName}."\t".$account_list->{ $acc }->{lastName}."\n"; 
 }
 
=item addAccount()

Add account.

 $axi->addAccount($domain, $user, $password);
 
 # $domain - the domain in which the account will be added;
 # $user - account name;
 # $password - account password

=item removeAccount()

Remove account.

 $axi->removeAccount($domain, $user);
 
 # $domain - the domain in which the account will be removed;
 # $user - account name

=item setAccountContactData()

Set account contact data - first name, last name.

 $axi->setAccountContactData($domain, $user, $firstName, $lastName);
 
 # $domain - the domain in which the account will be removed;
 # $user - account name;
 # $firstName - first name; 
 # $lastName - last name

=item setAccountPassword()

Set account password.

 $axi->setAccountPassword($domain, $user, $password);
 
 # $domain - the domain in which the account will be removed;
 # $user - account name;
 # $password - new password 

=item setAccountWebMailLanguage()

Set account WebMail Language.

 $axi->setAccountWebMailLanguage($domain, $user, $lang);
 
 # $domain - the domain in which the account will be removed;
 # $user - account name;
 # $lang - language 

=item saveConfig()

Save Axigen config file.

 $axi->saveConfig();

=item compactAll()

Compact domain storage files.

 $axi->compactAll($domain);

=item compactAllDomains()

Compact all domains storage files.

 $axi->compactAllDomains();

=item to_utf8()

Convert to utf-8.

 $axi->to_utf8($src);

=back

=head1 SEE ALSO

Gecad Technologies Axigen Mail Server Site: http://www.axigen.com

=head1 AUTHOR

Alexandre Frolov, E<lt>alexandre@frolov.pp.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Alexandre Frolov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
