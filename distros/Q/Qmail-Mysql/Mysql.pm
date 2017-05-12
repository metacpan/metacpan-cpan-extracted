package Qmail::Mysql;


use 5.006;
use strict;
use warnings;
use Carp;

use DBI;
use File::Path;


$Qmail::Mysql::VERSION	= '0.02';


# Fields that can be set in new method, with defaults
my %fields =(	
	sql_control_file 	=> '/var/qmail/control/sqlserver',
	mailbox_base		=> '/var/spool/pop/users',
	password_type		=> 'Password',
	multihosting		=> 0,
	multihosting_join	=> '@',
);

sub new
{            
    my ($proto,%options) = @_;
    my $class = ref($proto) || $proto;
    my $self = {
        %fields};
    while (my ($key,$value) = each(%options)) {
        if (exists($fields{$key})) {
            $self->{$key} = $value if (defined $value);
        } else {
            die $class . "::new: invalid option '$key'\n";
        }
    }
    foreach (keys(%fields)) {
    	die $class . "::new: must specify value for $_" 
    		if (!defined $self->{$_});
    }
    die $class . "::new: Unable to file sql control file at " .
	$self->{sql_control_file} if (!-e $self->{sql_control_file});
    bless $self, $class;
    $self->_init;
    return $self;
}

sub _init {
	my $self = shift;
	$self->_parse_control();
}

sub _parse_control() {
	my $self = shift;
	open(SQLCTL,$self->{sql_control_file}) 
			or die "Unable to open $self->{sql_control_file}";
	my $line;
	while (<SQLCTL>) {
		$line++;
		s/^\s*//;
		s/\s*^//;
		my ($key,$val) = split(/\s+/);
		die "Invalid control file format in " .
			"$self->{sql_control_file} at line $line"
						if (!defined $key || !defined $val);
		$self->{_db}->{$key} = $val;
	}
	close(SQLCTL);
	# check minimum data
	die "DB Host name not found in $self->{sql_control_file}" 
			if (!exists $self->{_db}->{server});
	die "DB login name not found in $self->{sql_control_file}" 
			if (!exists $self->{_db}->{login});
	die "DB password not found in $self->{sql_control_file}" 
			if (!exists $self->{_db}->{password});
	die "DB name not found in $self->{sql_control_file}" 
			if (!exists $self->{_db}->{db});
}

sub connect {
	my $self = shift;
	my $database 	= $self->{_db}->{db};
	my $hostname	= $self->{_db}->{server};
	
	my $dsn = "DBI:mysql:database=$database;host=$hostname";
        $self->{dbh} = DBI->connect($dsn, $self->{_db}->{login}, 
			$self->{_db}->{password}) or
		die "Unable to connect to qmail database using login " .
				"information in $self->{sql_control_file}";
}

sub disconnect {
	my $self = shift;
	$self->{dbh}->disconnect if defined $self->{dbh};
	}

sub rcpt_add {
	my $self 	= shift;
	my $rcpt_host	= $self->_q(shift);
	my $sql 	= qq|insert into rcpthosts (host) VALUES ($rcpt_host)|;
	$self->_do($sql);
}

sub rcpt_exists {
	my $self 	= shift;
	my $rcpt_host	= $self->_q(shift);
	my $sql 	= qq|select count(*) from rcpthosts where host = $rcpt_host|;
	return $self->{dbh}->selectrow_arrayref($sql)->[0];
}

sub rcpt_del {
	my $self 	= shift;
	my $rcpt_host	= $self->_q(shift);
	my $sql 	= qq|delete from rcpthosts where host = $rcpt_host|;
	$self->_do($sql);
}

sub mail_add {
	my $self 		= shift;
	my $vuser		= shift;
	my $vhost		= shift;
	my $pass		= shift;
	my $mbox		= shift || $self->_mbox($vuser,$vhost);
	my $mbox_path	= shift || $self->_mbox_path($vuser,$vhost);
	my $qmaild_id	= shift || (getpwnam('qmaild'))[2];
	my $qmail_id	= shift || (getpwnam('qmailr'))[3];

	# check existence of mbox_base and virtual base path
	$self->_check_mbox_base($vhost,$qmaild_id,$qmail_id);
	# create user qmail dirs
	foreach (('','Maildir','Maildir/cur','Maildir/new','Maildir/tmp')) {
		my $mask = $_ eq '' ? 0700 : 0711;
		$self->_make_qmail_dir($mbox_path ."/$_",$qmaild_id,$qmail_id,$mask);
	}
	# add user to db
	# add user to virtual table
	$self->_table_virtual_add($mbox,$vuser,$vhost);
	# add user to mailbox table
	$self->_table_mailbox_add($mbox,$qmaild_id,$qmail_id,$mbox_path,$pass);

}

sub mail_exists {
	my $self 	= shift;
	my $vuser	= shift;
	my $vhost	= shift;
	my $mbox	= shift || $self->_mbox($vuser,$vhost);
	$mbox		= $self->_q($mbox);
	my $sql 	= qq|select count(*) from mailbox where username = $mbox|;
	return $self->{dbh}->selectrow_arrayref($sql)->[0];
}

sub mail_del {
	my $self 	= shift;
	my $vuser	= shift;
	my $vhost	= shift;
	my $mbox	= shift || $self->_mbox($vuser,$vhost);
	
	$mbox		= $self->_q($mbox);
	my $sql 	= qq|select home from mailbox where username = $mbox|;
	my $home	=  $self->{dbh}->selectrow_arrayref($sql)->[0];
	$sql 	= qq|delete from mailbox where username = $mbox|;
	$self->_do($sql);
	$sql 	= qq|delete from virtual where username = $mbox|;
	$self->_do($sql);
	rmtree($home);

	
}

sub alias_add {
	my $self 	= shift;
	my $alias	= shift;
	my $mail	= shift;
	my ($au,$ah) 	= split(/\@/,$alias);
	my ($mu,$mh) 	= split(/\@/,$mail);
	$alias		= $self->_q($alias);
	$mu		= $self->_q($mu);
	$mh		= $self->_q($mh);
	# aggiunta utente alla tabella virtual
	$self->_table_virtual_add($self->_mbox($au,$ah),$au,$ah);
	my $sql		= qq|insert into alias (username,alias,alias_username,
				alias_host) VALUES ('alias',$alias,$mu,$mh)|;
	$self->_do($sql);
}

sub alias_exists {
	my $self 	= shift;
	my $alias	= shift;
	my $mail	= shift;
	my ($au,$ah) 	= split(/\@/,$mail);
	$alias		= $self->_q($alias);
	$au		= $self->_q($au);
	$ah		= $self->_q($ah);
	my $sql 	= qq|select count(*) from alias where username = 'alias' 
				and alias = $alias and alias_username = $au
				and alias_host = $ah|;
	return $self->{dbh}->selectrow_arrayref($sql)->[0];
}

sub alias_del {
	my $self 	= shift;
	my $alias	= shift;
	my $mail	= shift;
	my ($au,$ah) 	= split(/\@/,$alias);
	my ($mu,$mh) 	= split(/\@/,$mail);
	$alias		= $self->_q($alias);
	$mu		= $self->_q($mu);
	$mh		= $self->_q($mh);
	my $mbox	= $self->_q($self->_mbox($au,$ah));
	my $sql 	= qq|delete from alias where username = 'alias' 
                                and alias = $alias and alias_username = $mu
                                and alias_host = $mh|;
	$self->_do($sql);
	$sql    = qq|delete from virtual where username = $mbox|;
        $self->_do($sql);
}

sub _table_virtual_add {
	my $self 	= shift;
	my $mbox	= $self->_q(shift);
	my $vuser	= $self->_q(shift);
	my $vhost	= $self->_q(shift);
	my $sql		= qq|insert into virtual 
						(username,virtual_username,virtual_host) VALUES
						($mbox,$vuser,$vhost)|;
	$self->_do($sql);
}

sub _table_mailbox_add {
	my $self	= shift;
	my $mbox	= $self->_q(shift);
	my $qusr	= $self->_q(shift);
	my $qgrp	= $self->_q(shift);
	my $mbox_p	= $self->_q(shift);
	my $pass	= $self->_q(shift);

	my $pass_t	= $self->_q($self->{password_type});
	my $sql		= qq|insert into mailbox 
						(username,uid,gid,home,password,password_type) VALUES
						($mbox,$qusr,$qgrp,$mbox_p,$pass,$pass_t)|;
	$self->_do($sql);
}

sub _mbox {
	my $self 	= shift;
	my $vuser 	= shift;
	my $vhost	= shift;
	return $self->{multihosting} 
			? $vuser . $self->{multihosting_join} . $vhost 
			: $vuser;
}

sub _mbox_path {
	my $self 	= shift;
	my $vuser 	= shift;
	my $vhost	= shift;
	return $self->{multihosting} 
			? $self->{mailbox_base} . "/$vhost/$vuser" 
			: $self->{mailbox_base} . "/$vuser";
}

sub _check_mbox_base {
	my $self	= shift;
	my $vhost	= shift;
	my $quser   = shift;
    my $qgrp    = shift;

	my $dir		= $self->{mailbox_base};
	$self->_make_qmail_dir(	$dir,$quser,$qgrp,0700) if (!-e $dir);
	$dir	 	.= "/$vhost";
	$self->_make_qmail_dir( $dir,$quser,$qgrp,0700) 
								if ($self->{multihosting} && !-e $dir);
}

sub _make_qmail_dir {
	my $self 	= shift;
	my $dir		= shift;
	my $quser	= shift;
	my $qgrp	= shift;
	my $mask	= shift;

	eval { mkpath($dir,0,$mask) };
  	if ($@) { die "Couldn't create $dir: $@"; }
	chown $quser,$qgrp,$dir;

}

sub _q {
	my $self	= shift;
	return $self->{dbh}->quote(shift);
}


sub _do {
	my $self 	= shift;
	my $sql 	= shift;
	$self->{dbh}->do($sql) or die "Unable to execute $sql";
}

sub DESTROY {
	my $self = shift;
	$self->disconnect;
	# Enter here your code
}
