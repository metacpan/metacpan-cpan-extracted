package RPC::Oracle;

our $VERSION = '1.3';

sub new {
	my ($self, $class, $dbh, $schema) = ({}, @_);
	$self = bless $self, $class;

    $self->schema($schema);

	$self->dbh($dbh);
	return $self;
}

sub dbh {
	my ($self, $dbh) = @_;
	if(@_ == 2) {
		$self->{dbh} = $dbh;
		return $self;
	}
	return $self->{dbh};
}

sub schema {
	my ($self, $schema) = @_;
	if(@_ == 2) {
		$self->{schema} = $schema;
		return $self;
	}
	return $self->{schema};
}

sub call {
	my ($self, $method, @args) = @_;

	die "Invalid identifier: $method"
		unless $self->_check_identifier($method);

	if(! $self->dbh) {
		die "No database handle";
	}

	my $sql = "BEGIN ";
	my @bind = ();
	my $return;

	# if not called in void context (list or scalar), call as function
	if(defined wantarray) {
		$sql .= " ? := ";
		push @bind, \$return;
	}

	# prefix the schema name if set
	if($self->schema) {
		$method = $self->schema . ".$method";
	}

    $sql .= "$method";
    if(@args > 0) {
        $sql .= "(";

        # bind as name-based parameters
        if(@args == 1 && ref $args[0] eq 'HASH') {
            my $first = 1;
            while(my($var_name, $var_value) = each(%{ $args[0] })) {
                $sql .= $first ? "" : ", ";
                $sql .= "$var_name => ?";
                push @bind, $var_value;
                
                $first = 0;
            }
        }
        else {
            $sql .= join(', ', ('?') x scalar(@args));
            push @bind, @args;
        }
        $sql .= ")";
    }
	$sql .= "; END;";

	my $sth = $self->dbh->prepare($sql);
	my $i = 1;
	for my $bindvar (@bind) {
		if(ref $bindvar) {
			$sth->bind_param_inout($i, $bindvar, $self->dbh->{LongReadLen});
		}
		else {
			$sth->bind_param($i, $bindvar);
		}
		$i++;
	}

	$sth->execute;

	return $return;
}

sub constant {
	my ($self, $constant_name) = @_;

	die "Usage: constant('constant_name')" unless $constant_name;

	die "Invalid identifier: $constant_name"
		unless $self->_check_identifier($constant_name);

	# return from cache if available
	if($self->{uc $schema}->{uc $constant_name}) {
		return $self->{uc $schema}->{uc $constant_name};
	}

	die "No database handle"
		unless $self->dbh;

	my $sql = "BEGIN ? := ";
	my $schema = $self->schema;
	$sql .= $schema ? "$schema.$constant_name" : $constant_name;
	$sql .= "; END;";

	my $sth = $self->dbh->prepare($sql);
	my $value;
	$sth->bind_param_inout(1, \$value, $self->dbh->{LongReadLen});

	$sth->execute;

	# cache this for later
	$self->{uc $schema}->{uc $constant_name} = $value;

	return $value;
}

sub _check_identifier {
	my ($self, $ident) = @_;
	return $ident =~ /^[a-z][a-z0-9\$\#\_\.]*$/i;
}

sub AUTOLOAD {
	my ($self, @args) = @_;
	my $sub = $AUTOLOAD;
	$sub =~ s/.*:://;
	return if $sub eq 'DESTROY';

	return $self->call($sub, @args);
}

1;

__END__

=pod

=head1 NAME

RPC::Oracle - Provide seemless interface into Oracle procedures and functions.

=head1 SYNOPSIS

	use RPC::Oracle;
	my $oracle = RPC::Oracle->new($dbh);

	$oracle->call('package.procedure', 'arg1', 'arg2');
	my $return = $oracle->call('function', 'arg1', 'arg2');

	$oracle->schema('SCOTT');
	$oracle->my_procedure('arg1', 'arg2'); # calls procedure scott.my_procedure

	# call myschema.mypackage.my_function()
	$oracle->schema('myschema.mypackage');
	my $return = $oracle->my_function();

	# binds $arg2 as an "IN OUT" parameter
	$oracle->call("myproc", $arg1, \$arg2);
	print "I got $arg2!\n";

	# get the value of my_package.my_constant
	$oracle->schema("my_package");
	print $oracle->constant("my_constant");

	# call procedure with long form
	$oracle->my_procedure({
		var1 => 'value of var1',
		var2 => 'value of var2',
		var3 => \$outbound_variable
	});

  # get package variable
  $oracle->schema("dbms_stats");
  my $auto_sample_size = $oracle->auto_sample_size;

=head1 DESCRIPTION

=head2 Class Methods

=over

=item C<new>

	use RPC::Oracle;
	my $oracle = new RPC::Oracle($dbh, [$schema]);

Instantiates RPC::Oracle object with the given database handle. $dbh should be
a valid DBI::db object, but no type checking is done.

=item C<dbh>

	$oracle->dbh($dbh);

Set the internal database handle. $dbh should be a vaild DBI::db object, but no
type checking is done. A database handle is required to make use of this tool.

=item C<schema>

	$oracle->schema("myschema");
	$oracle->schema("myschema.mypackage");

Set the prefix for calling functions or procedures. Handy for saving typing.

=item C<call>

	$oracle->call("myprocedure", $arg1, $arg2);
	my $return = $oracle->call("myschema.myfunction", $arg1, $arg2);

	# binds $arg2 as an "IN OUT" parameter
	$oracle->call("myproc", $arg1, \$arg2);
	print "I got $arg2!\n";

	# call procedure with long form
	$oracle->my_procedure({
		var1 => 'value of var1',
		var2 => 'value of var2',
		var3 => \$outbound_variable
	});

Translates the requested function/procedure name into a PL/SQL block and
executes it. If called in void context, RPC::Oracle assumes you are calling
a procedure. In scalar/array context, RPC::Oracle assumes you want a function.

If any parameters are references, RPC::Oracle will bind them as "IN OUT"
parameters. Oracle treats "IN OUT" parameters and "OUT" parameters the same.

=item C<AUTOLOAD>

	$oracle->my_procedure($arg1, $arg2);
	my $return = $oracle->my_function($arg1, $arg2);

The AUTOLOAD method treats the sub name as the target procedure/function name.
Note, that since perl disallows periods (.) in function names, you should use
L<schema> to set the schema beforehand.

=item C<constant>

	$oracle->schema("my_package");
	my $var = $oracle->constant("my_constant");

Retrieves the PL/SQL constant from a package.

=back

=head1 CAVEATS

This package does not correctly handle outbound cursor refs. Doing such would
require foreknowledge that a cursor object was coming back so the call to
bind_param_inout() can be adjusted accordingly.

In addition, the AUTOLOAD method will not be called if the target procedure is
named new, dbh, schema, call, constant or autoload, since these are class 
methods.

=head1 AUTHOR

Warren Smith L<wsmith@cpan.org>

=cut

