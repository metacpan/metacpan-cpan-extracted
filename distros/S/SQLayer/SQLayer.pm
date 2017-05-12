package SQLayer;

$SQLayer::VERSION = '1.1';

use strict;
use Carp;
use DBI;

sub new
{
	my ($class, %HKeys) = @_;

	my $self = {DEBUG => '',
		    errstr => ''};	    

	bless $self, $class;

	$self -> _init(%HKeys);

return $self
}

sub DESTROY
{
	shift -> {dbh} -> disconnect;
}

sub errstr
{

return shift -> {errstr}
}

sub DEBUG
{
	my $self = shift;
	my $level = shift;

	return $self -> {DEBUG} unless $level;

	$self -> {DEBUG} = 1 if $level == 1;

	DBI -> trace($level - 1) unless $level == 1;

return 1
}

sub transaction
{
	my $self = shift;
	if ($self -> {'TRANSACTION'} ne 'YES')
	{
		$self -> enable_transactions();
		$self -> proc("BEGIN");
		$self -> {'TRANSACTION'} = 'YES';
	} else { warn "SQLayer: Transaction already in progress!" }
}


sub commit
{
	my $self = shift;
	if ($self -> {'TRANSACTION'} eq 'YES')
	{
		my $dbh = $self -> {'dbh'};
		$dbh -> commit();
		$self -> disable_transactions();
		$self -> {'TRANSACTION'} = 'NO';
	} else { warn "SQLayer: No transaction in progress or method 'begin' never called. Please use methob 'begin' to handle transactions!" }
	
}

sub rollback
{
	my $self = shift;
	if ($self -> {'TRANSACTION'} eq 'YES')
	{
		my $dbh = $self -> {'dbh'};
		$dbh -> rollback();
		$self -> disable_transactions();
		$self -> {'TRANSACTION'} = 'NO';
	} else { warn "SQLayer: No transaction in progress or method 'begin' never called. Please use methob 'begin' to handle transactions!" }
}

sub enable_transactions
{
	my $self = shift;

	my $dbh = $self -> {'dbh'};

	$dbh->{'AutoCommit'} = 0;  # enable transactions, if possible
	$dbh->{'RaiseError'} = 1
}

sub disable_transactions
{
	my $self = shift;

	my $dbh = $self -> {'dbh'};

	$dbh->{'AutoCommit'} = 1;  # enable transactions, if possible
	$dbh->{'RaiseError'} = 1
}
sub connect_status
{
	
return shift -> {connect_status}
}

sub nodebug
{
	shift -> {DEBUG} = ''
}

sub row
{
	my $self = shift;
	my $query = shift;

	warn $query if $self -> DEBUG;

	my $sth;
	my $dbh = $self -> {'dbh'};

	eval
	{
		$sth = $dbh -> prepare($query) || do
		{ 
			warn $dbh -> errstr, " $query\n";
			$self -> {errstr} .= $dbh->errstr;
			return undef;
		};
	};

	eval
	{
		$sth -> execute || do
		{ 
			warn $dbh -> errstr, " $query\n";
			$self -> {errstr} .= $dbh -> errstr;
			return undef;
		};
	};

	my @row = $sth -> fetchrow_array;

	$sth -> finish;

return wantarray ? @row : $row[0];
}

sub proc
{
	my $self = shift;
	my $query = shift;

	warn $query if $self -> DEBUG;

	my $res = $self -> {'dbh'} -> do($query);
	$self -> {errstr} .= $self -> {dbh} -> errstr;

	return $res if $res;

return undef;
}

sub all_rows
{
	my $self = shift;
	my $query = shift;

	my $sth;

	warn $query if $self -> DEBUG;

	my $dbh = $self -> {'dbh'};

	eval
	{
		$sth = $dbh -> prepare($query) || do
		{
			warn $dbh -> errstr, " $query\n";
			$self -> {errstr} .= $dbh -> errstr;
			return undef;
		}
	};

	eval
	{
		$sth -> execute || do
		{
			warn $dbh -> errstr, " $query\n";
			$self -> {errstr} .= $dbh -> errstr;
			return undef;
		}
	};

	my $ret = $sth -> fetchall_arrayref;
	$sth -> finish;

return $ret;
}

sub row_hash
{
	my $self = shift;
	my $query = shift;

	my $sth;

	warn $query if $self->DEBUG;

	my $dbh = $self->{'dbh'};

	eval
	{
		$sth = $dbh->prepare($query) || do
		{
			warn $dbh->errstr, " $query\n";
			$self->{errstr} .= $dbh->errstr;
			return undef;
		}
	};

	eval
	{
		$sth->execute || do
		{
			warn $dbh->errstr, " $query\n";
			$self->{errstr} .= $dbh->errstr;
			return undef;
		}
	};

	my $ret = $sth->fetchall_arrayref({});

	$sth -> finish;

return $ret;
}

sub column
{
	my $self = shift;
	my $query = shift;

	my $ret;

	warn $query if $self -> DEBUG;

	eval
	{
		$ret = $self -> {dbh} -> selectcol_arrayref($query);
	};

	if ($@)
	{
		warn $@;
		$self -> {errstr} .= $self -> {dbh} -> errstr;
		return undef;
	}

	return @$ret;
}

sub hash_all
{
	my $self = shift;
	my $query = shift;

	warn $query if $self->DEBUG;

	my %ret;
	my $sth;
	my $dbh = $self->{dbh};

	eval
	{
		$sth = $dbh->prepare($query) || do
		{
			warn $dbh->errstr, " $query\n";
			$self->{errstr} .= $dbh->errstr;
			return undef;
		}
	};

	eval
	{
		$sth->execute || do
		{
			warn $dbh->errstr, " $query\n";
			$self->{errstr} .= $dbh->errstr;
			return undef;
		}
	};

	my $ret = $sth->fetchall_arrayref;

	foreach (@$ret)
	{
		$ret{$_->[0]} = $_->[1];
	}

return %ret;
}

sub hash_row
{
	my $self = shift;

	my $query = shift;
	warn $query if $self->DEBUG;
 
	my $sth;
	my $dbh = $self->{dbh};

	eval
	{
		$sth = $dbh->prepare($query) || do
		{ 
			warn $dbh->errstr, " $query\n";
			$self->{errstr} .= $dbh->errstr;
			return undef;
		}
	};

	eval
	{
		$sth->execute || do
		{
			warn $dbh->errstr, " $query\n";
			$self->{errstr} .= $dbh->errstr;
			return undef;
		}
	};

	my $ret = $sth->fetchrow_hashref;
	$sth->finish;

return $ret;
}

sub hash_var
{
        my $self = shift;

        my $query = shift;
        warn $query if $self->DEBUG;

        my $sth;
        my $dbh = $self->{dbh};

        eval
        {
                $sth = $dbh->prepare($query) || do
                {
                        warn $dbh->errstr, " $query\n";
                        $self->{errstr} .= $dbh->errstr;
                        return undef;
                }
        };

        eval
        {
                $sth->execute || do
                {
                        warn $dbh->errstr, " $query\n";
                        $self->{errstr} .= $dbh->errstr;
                        return undef;
                }
        };

        my $ret = $sth->fetchrow_hashref;
        $sth->finish;

return ($ret) ? %$ret:undef;
}

sub quote
{
	shift -> {dbh} -> quote(@_);
}

# Private Methods
sub _init
{
	my $self = shift;
	my %HKeys = @_;
	my $BStatus = 1;

	$self -> {'database'} = $HKeys{'database'};
	$self -> {'user'} = $HKeys{'user'};
	$self -> {'password'} = $HKeys{'password'};

	$self -> {'dbh'} = DBI -> connect_cached($self -> {'database'}, $self -> {'user'}, $self -> {'password'}, {ChopBlanks => '1'}) || { $BStatus = 0 };
	$self -> {'connect_status'} = $BStatus;
}


1;

__END__;

=head1 NAME

  SQLayer - Interface to DB

=head1 SYNOPSIS

  use SQLayer;
  my $D = SQLayer -> new(database => 'DBI:mysql:database=phorum;host=localhost;port=3306', user => 'user', passowrd => 'somepass');

  my $PAllRowsArrayRef = $D -> all_rows("SELECT a, b FROM dum"); # pointer to array

  my @AOneColumnArray = $D -> column("SELECT a FROM dum"); # array

  $D -> commit; # is equal to $D -> proc("COMMIT");

  my $NConnectStatus = $D -> connect_status; # returns 1 if connected

  $D -> DEBUG(1);   # warn query only
  $D -> DEBUG($n);  # set trace level to $n-1

  $D -> enable_transactions; # enable transactions if possible
  $D -> errstr; # returns error code

  my %HHashNameById = $D -> hash_all("SELECT id, name FROM dum"); #

  my $PHashOneByFieldsNameRef = $D -> hash_row("SELECT a, b, c FROM dum WHERE id = '1'"); # pointer to hash

  my %HHashOneByFieldsName = $D -> hash_var("SELECT a, b, c FROM dum WHERE id = '1'");  # hash

  $D -> nodebug;    # No warn query and clear tracing

  $NAffectedRowsNum = $D -> proc("DELETE FROM dum WHERE a = b"); # affected rows

  my @AOneRowArray = $D -> row("SELECT a, b, c FROM dum WHERE id = '1'"); # array
  my $NVvalue = $D -> row("SELECT a FROM dum WHERE id = '1' "); # one value
  
  my $PRowOfHashRef = $D -> row_hash("SELECT a, b, c FROM dum"); # pointer to array of hashes
  
  $SQuoted = $D -> quote($SSomeVar); # same as DBI method

=head1 METHODS

  Need to written.


=head1 AUTHOR

  Written 1999 - 2003 (last change: 08.07.2003 11:16) by
    Andrew Gromozdin (ag@df.ru),
    Sergei Kadurin (ky@sema.ru),
    Andrei V. Shetuhin (stellar@akmosoft.comm.

  Please report all bugs to <stellar@akmosoft.com>.

=head1 BUGS

  Nothing known soon :)

=head1 SEE ALSO

  perldoc DBI;

=cut

