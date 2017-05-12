package Register::System;
use DBI;
require Exporter;

sub new {
	my $type=shift;
	my %params=@_;
	my $self={};
	my $name="${type}::new";

	$self->{'Type'}=$type;
	my $regpath = Register::checkReq ($name, "regpath", $params{'regpath'});
	my $regname = Register::checkReq ($name, "regname", $params{'regname'});
	($self->{'REGISTER_NAME'}=$regname)=~s/(\W)//g;
	$self->{'DBH'}=DBI->connect("DBI:CSV:f_dir=".$regpath,"","");
	if (!(-d $regpath)) { 
		printf "ERROR:\n";
		printf "LOCATION: \<".$self->{'Type'}."\>\n";
		printf "CAUSE: directory \<".$regpath."\> not found !!!\n";
		exit(1);
	};
	if (!(-f $regpath."/".$self->{'REGISTER_NAME'})) {
		my($sql)=qq {
			CREATE TABLE 
				$self->{'REGISTER_NAME'} 
				(
				R_APPLICATION 	CHAR(255),
				R_SECTION 	CHAR(255),
				R_KEY		CHAR(255),
				R_VALUE		CHAR(255)
				) 
		};
		$self->{DBH}->do($sql);
	};

	bless $self;
}

sub getsettings {
	my $self=shift;
	my ($APP,$SEC,$KEY)=@_;
	my ($row)={};

	$row->{'R_VALUE'}="";
	my ($sql) = qq { 
		  SELECT 
			*	
		  FROM 
			$self->{'REGISTER_NAME'}
		  WHERE
				R_APPLICATION=?
			AND
				R_SECTION=?
			AND
				R_KEY=?
		};
	my($sth)=$self->{DBH}->prepare($sql);
	$sth->execute($APP,$SEC,$KEY);
	$row=$sth->fetchrow_hashref;
	if ($row->{'R_VALUE'} ne "") {
		return $row->{'R_VALUE'};
	} else {
		return "";
	};
}

sub savesettings {
	my $self=shift;
	my ($APP,$SEC,$KEY,$VAL)=@_;
	my ($row)={};

	my($sql) = qq { 
		  SELECT 
			*	
		  FROM 
			$self->{'REGISTER_NAME'}
		  WHERE
				R_APPLICATION=?
			AND
				R_SECTION=?
			AND
				R_KEY=?
		};
	my($sth)=$self->{DBH}->prepare($sql);
	$sth->execute($APP,$SEC,$KEY);
	$row=$sth->fetchrow_hashref;
	if ($row->{'R_APPLICATION'} ne "") {
		$self->updatekey($APP,$SEC,$KEY,$VAL);
	} else {
		$self->addkey($APP,$SEC,$KEY,$VAL);
	};
	$sth->finish();
				
}

sub deletesection {
	my $self=shift;
	my($APP,$SEC)=@_;

	$sql=qq {
		DELETE FROM
			$self->{'REGISTER_NAME'}
		WHERE
				R_APPLICATION=?
			AND
				R_SECTION=?
	};
	$self->{DBH}->do($sql,undef,$APP,$SEC);
}

sub deletesettings {
	my $self=shift;
	my($APP,$SEC,$KEY)=@_;

	my($sql)=qq {
		DELETE FROM
			$self->{'REGISTER_NAME'}
		WHERE
				R_APPLICATION=?
			AND
				R_SECTION=?
			AND
				R_KEY=?
	};
	$self->{DBH}->do($sql,undef,$APP,$SEC,$KEY);
}

sub updatekey {
	my $self=shift;
	my ($APP,$SEC,$KEY,$VAL)=@_;

	my($sql)=qq {
		UPDATE 
			$self->{'REGISTER_NAME'}
		SET
			R_VALUE=?
		WHERE
				R_APPLICATION=?
			AND
				R_SECTION=?
			AND
				R_KEY=? 
	};
	$self->{DBH}->do($sql,undef,$VAL,$APP,$SEC,$KEY);
}

sub addkey {
	my $self=shift;
	my ($APP,$SEC,$KEY,$VAL)=@_;

	my($sql)=qq {
		INSERT INTO 
			$self->{'REGISTER_NAME'}
			(
			R_APPLICATION,
			R_SECTION,
			R_KEY,
			R_VALUE
			)
		VALUES ( ?,?,?,? )
	};

	$self->{DBH}->do($sql,undef,$APP,$SEC,$KEY,$VAL);
}

1;

=head1 NAME

Register::System - Implementation of the Win32 registry in Unix

=head1 SYNOPSIS

	use Register;
	
	$sysreg=new Register::System (
			'regpath' => "/etc",
			'regname' => "SYSREG"
		);

	$sysreg->savesettings("APPLICATION","SECTION","KEY","VALUE");
	$value=$sysreg->getsettings("APPLICATION","SECTION","KEY");
	$sysreg->deletesettings("APPLICATION","SECTION","KEY");
	$sysreg->deletesection("APPLICATION","SECTION");

=head1 DESCRIPTION

The Register::System module permit to create a registry file like 
Windows for save global information about your program.
With the use of CSV dbd , the file created is readable by DBI without
problem.
Here CSV table specifics:

	FIELD_NAME		FIELD_TYPE
	----------------------------------	
	R_APPLICATION		CHAR
	R_SECTION		CHAR
	R_KEY			CHAR
	R_VALUE			CHAR

=head1 FUNCTIONS



=head2 Function <new>

The <new> statament create the Register::System object and return the
reference to him.

	$sysreg=new Register::System (
			'regpath' => "/etc",
			'regname' => "SYSREG"
		);

Parameter :

	regpath		specify the path where new statament search for
			registers.

	regname		specify the name of the register to use.

Finaly if regpath don't exist the program return an error message at compile
time, if the register don't exist it is maked.

=head2 Function <savesettings>

The savesettings function , save the value argument in the key of the 
section of the program.

	$sysreg->savesettings("APPLICATION","SECTION","KEY","VALUE");

If the key don't exist it make (it make also application and section
without specify befor), else if key already exist and value is different
from previous it update value.

=head2 Function <getsettings>

The getsettings function retrieve the value of the specified key.

	$value=$sysreg->getsettings("APPLICATION","SECTION","KEY");

=head2 Function <deletesettings>

The deletesettings function delete the entry key specified.

	$sysreg->deletesettings("APPLICATION","SECTION","KEY");

=head2 Function <deletesection>

The deletesection function delete the entry section specified.

	$sysreg->deletesection("APPLICATION","SECTION");

=head1 AUTHOR

        Vecchio Fabrizio <jacote@tiscalinet.in>

=head1 SEE ALSO

L<Register>,L<DBD::CSV>,L<DBI>

=cut
