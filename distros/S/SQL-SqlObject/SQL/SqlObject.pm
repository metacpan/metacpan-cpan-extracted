package SQL::SqlObject;

#use 5.006;
use strict;
use warnings;
use Carp;
use DBI;
use SQL::SqlObject::Config;

# 110803 - VERSION incremented to 0.02 for first CPAN release 
# 101903 - fixed argument verification for insert_select
#        - added connection arg cacheing
#        - we now cache db_name, db_dsn and db_pre if they
#          are provided as arguments to connect_string() -cz
# 011003 - arguments for constructor now come from
#          SQL::SqlObject::Config -cz
# 010803 - added constuctor_args/process_contructror args -cz
# 010603 - added AUTOLOAD to pass through method calls -cz
# 052699 - Minor fix to Hashes Sub -cz

our $VERSION     = '0.02';
our %SqlConfig;  # read from SQL::SqlObject::Config

sub new
{

    # install confguration, if necessary
    unless (%SqlConfig)
    {
	no strict 'refs';
	*SQL::SqlObject::SqlConfig = \%SQL::SqlObject::Config::SqlConfig;
    }

    my ($class) = @_;
    my $self;


    # we don't really support clones...
    if (ref $class)
    {
	# clones must have us somwhere in their ancestory
	unless (UNIVERSAL::isa($class, __PACKAGE__))
	{
		Carp::confess (
			       "process_constructor_args: attemp to clone",
			       " from unrelated class: ", ref $class
			      );
	}

	($class) = $class =~ /(.*?)=/;
    }

    $self = bless {}, $class;
    $self->process_constructor_args(@_);
    # post construction initialization
    $self->_init if $self->can('_init');

    return $self;
}

sub clone { shift->new(@_) }

sub DESTROY { $_[0]->disconnect }

sub process_constructor_args
{

    unless (@_>1) {
	Carp::confess "process_constructor_args: wrong number of parameters"
    }

    my $self  = shift;
    my $class = shift;

    # coerse input to hash reference
    my $args = {};
    if ($_ = ref $_[0])
    {
	if (/HASH/)
	{
	    while (my ($k, $v) = each %{ $_[0] })
	    {
	        my $arg_ix = SQL::SqlObject::Config::arg_index($k);
	        $k =~ y/A-Z-/a-z/d;
		$args->{$SqlConfig{ARGS}[ $arg_ix ][0]} = $v;
	    }
	}

	elsif (/ARRAY/)
	{
	    $args = {
		     map { $SqlConfig{ARGS}[$_][0] => $_[0][$_] } 0..$#{$_[0]}
		    };
	}

	else
	{
	    Carp::Confess (q(process_constructor_args encountered ),
			   q(unexpected reference type ), $_);
	}
    }

    elsif (@_)
    {
	if ($_[0] =~ /^-/)
	{
	    # input aleardy in key-value format
	    if (@_ % 2)
	    {
		Carp::confess ('process_constructor_args uneven number ',
			       'of input parameters')
	    }

	    for (my $input_ix = 0; $input_ix < @_; $input_ix += 2 )
	    {
		my $arg_ix = SQL::SqlObject::Config::arg_index($_[$input_ix] );
		$args->{ $SqlConfig{ARGS}[ $arg_ix ][0] } = $_[ $input_ix + 1 ];
	    }
	}

	else
	{
	    # input in ordered list format
	    for (0..$#_)
	    {
		$args->{ $SqlConfig{ARGS}[$_][0] } = $_[$_];
	    }
	}
    }

    # now try to supply values for all args
    ARG: for my $arg_id ( 0..$#{ $SqlConfig{ARGS} })
    {
	my $name = $SqlConfig{ARGS}[$arg_id][0];

	# see value if value was supplied as an argument
	if (exists $args->{$name})
        {
	    $self->$name( $args->{$name} );
	    next ARG;
	}

	# if we're cloning look at the parent object first
	if (ref $class and defined $class->$name)
	{
	    $self->$name($class->$name);
	    next ARG;
	}

	# search env variables if any we're supplied
	if ($SqlConfig{ARGS}[$arg_id][2])
	{
	    my $env = $SqlConfig{ARGS}[$arg_id][2];

	    if (ref $env)
	    {
		ENV: for (@$env)
		{
		    next ENV unless exists $ENV{$_};
		    $self->$name( $ENV{$_} );
		    next ARG;
		}
	    }

	    else
	    {
		if (exists $ENV{$env})
		{
		    $self->$name( $ENV{$env} );
		    next ARG;
		}
	    }
	}

	# use default if one was provided
	if ($SqlConfig{ARGS}[$arg_id][3] and
	    $_ = $SqlConfig{ $SqlConfig{ARGS}[$arg_id][3] })
	{
	    $self->$name( $_ );
	    next ARG;
	}
    }

    return $self;
}

# is_connected: toggled on  by dbh
#                       off by disconnect
sub is_connected : lvalue { $_[0]->{connected_P} }

# primary flock of accessors
sub db_name        : lvalue { delete $_[0]->{__connection_args};
                              $#_ and $_[0]->{name}   = $_[1]; $_[0]->{name}}
sub db_name_prefix : lvalue { delete $_[0]->{__connection_args};
                              $#_ and $_[0]->{pre}    = $_[1]; $_[0]->{pre}}
sub db_dsn         : lvalue { delete $_[0]->{__connection_args};
                              $#_ and $_[0]->{dsn}    = $_[1]; $_[0]->{dsn}}
sub db_user        : lvalue { delete $_[0]->{__connection_args};
                              $#_ and $_[0]->{user}   = $_[1]; $_[0]->{user}}
sub db_password    : lvalue { delete $_[0]->{__connection_args};
                              $#_ and $_[0]->{passwd} = $_[1]; $_[0]->{passwd}}
sub Error          : lvalue { $#_ and $DBI::errstr    = $_[1]; $DBI::errstr}
sub dbh            : lvalue
{
  unless ($_[0]->is_connected) {
    $_[0]->{dbh} = $_[0]->connect;
    $_[0]->is_connected = 1;
  }

  $_[0]->{dbh}
}

sub connect
{

    my $self = shift;

    if (@_)
      # cache the arguments, in case we have to reconnect
      # as seems to be needed for insert_select
      {
	$self->{__connection_args} = [ @_ ];
      }

    elsif ($self->{__connection_args})
      # load the connection args from the cache
      {
	@_ = @{ $self->{__connection_args} }
      }

    my $connect_string = $self->connect_string(@_);

    $self->is_connected and $self->disconnect;

    my $dbh  = DBI->connect($connect_string,$self->db_user,$self->db_password);

    my $err = $self->Error;
    $err and Carp::confess (
			    q(Whoops - couldn\'t connect to ),
			    $_[0] || $self->db_name, "\n",
			    'Error:', $err
			   );

    return $dbh;
}

# build the connect string
sub connect_string
{
    my ($self, $name, $dsn, $pre) = @_;

    $self->db_name        ||= $name if $name;
    $self->db_dsn         ||= $dsn  if $dsn;
    $self->db_name_prefix ||= $pre  if $pre;

    defined $name or $name = $self->db_name;
    defined $dsn  or $dsn  = $self->db_dsn
      or Carp::confess "No data source named for SqlObject connect string";
    defined $pre  or $pre  = $self->db_name_prefix;

    my $other = '';
    if ($SqlConfig{OTHER_ARGS})
    {
        if (ref $SqlConfig{OTHER_ARGS})
	{
	    for (@{$SqlConfig{OTHER_ARGS}})
	    {
	      my $val = $self->$_ or next;
	      my ($key) = (/^(?:.*?_)?(.*)$/);
	      $other .= "$SqlConfig{OTHER_ARG_SEP}$key=$val";
	    }
	}

	else
	{
	    my $meth = $SqlConfig{OTHER_ARGS};
	    my $val  = $self->$meth;
	    $other = "$SqlConfig{OTHER_ARG_SEP}$SqlConfig{OTHER_ARGS}=$val"
	      if defined $val;
	}
    }

    return "$dsn:$pre$name$other";
}

sub disconnect
{
    my $self = shift;

    if(exists $self->{'dbh'})
    {
	$self->dbh->disconnect;
	$self->is_connected = '';
	delete $self->{'dbh'};
    }
}

sub hash
{
    unless (@_==2) {
	Carp::confess qq(SqlObject: wrong number of arguments for hash);
    }

    my ($self,$query) = @_;

    my $sth = $self->prepare($query);
    $sth->execute();

    my $href = $sth->fetchrow_hashref;
    $sth->finish;

    return unless defined $href;
    return wantarray ? %$href : $href;
}

sub hashes
{
    if (@_<2 or @_>3) {
	Carp::confess "SqlObject: wrong number of arguments for hashes"
    }
    my ($self,$query,$cref) = @_;

    my $sth = $self->prepare($query); $sth->execute();

    if($cref)
    {
	my $href;
	$cref->($href) while $href = $sth->fetchrow_hashref;

	$sth->finish();
	return;
    } else
    {
	my @AoH = @{ $sth->fetchall_arrayref( {} ) };
	$sth->finish();

	return wantarray ? @AoH : \@AoH;
    }
}

sub array
{
    unless (@_==2) {
	Carp::confess "SqlObject: wrong number of arguments for array"
    }

    my $self  = shift;
    my $query = shift;

    my $sth = $self->prepare($query);

    if (my $err = $self->Error)
    {
	Carp::confess ("SqlObject: bad SQL for array \n",
		       "Query: '$query'\nError: '$err'")
    }

    $sth->execute();

    my @arr = $sth->fetchrow_array();
    $sth->finish;

    return wantarray ? @arr : \@arr;
}

#
# Execute the query and return a single element
#
sub value
{
    unless (@_==2) {
	Carp::confess "SqlObject: wrong number of arguments for value"
    }

    my $self  = shift;
    my $query = shift;

    my $sth = $self->prepare($query);

    if (my $err = $self->Error)
    {
	Carp::confess ("SqlObject: bad SQL for value \n",
		       "Query: '$query'\nError: '$err'")
    }

    $sth->execute();

    my ($val) = $sth->fetchrow_array;
    $sth->finish;

    return $val;
}

#
# Execute the query and return the first element of each result row
#
sub list {
    unless (@_==2) {
	Carp::confess "SqlObject: wrong number of arguments for list"
    }

  my $self  = shift;
  my $query = shift;

  my $sth = $self->prepare($query);

    if (my $err = $self->Error)
    {
	Carp::confess ("SqlObject: bad SQL for list \n",
		       "Query: '$query'\nError: '$err'")
    }

  $sth->execute();

  my @vals;
  push @vals, $_ while ($_) = $sth->fetchrow_array;
  $sth->finish;

  return wantarray ? @vals : \@vals;
}


sub delete {

    unless (@_>1 and @_<4)
    {
	Carp::confess "SqlObject: wrong number of arguments for delete"
    }

    my ($self,$table,$href) = @_;
    my ($err, $query);

    $self->_sql_quote_hash($href) if defined $href and ref $href;

    $query = $self->_sql_delete_query($table,$href);
    $self->do($query);
    $err = $self->Error();

    if ($err = $self->Error)
    {
	Carp::confess ("SqlObject: delete error\n",
		       "Query: '$query' Error: '$err'")
    }
}

sub insert
{
    unless (@_==3)
    {
	Carp::confess "SqlObject: wrong number of arguments for insert"
    }

    my ($self, $table, $href) = @_;
    my ($err, $query);

    $self->_sql_quote_hash($href);

    $query = $self->_sql_insert_query($table,$href);
    $self->do($query); $err = $self->Error();

    if ($err = $self->Error)
    {
	Carp::confess ("SqlObject: insert error\n",
		       "Query: '$query'\nError: '$err'")
    }
}

sub cond_insert {
    unless (@_>2 and @_<4)
    {
	Carp::confess "SqlObject: wrong number of arguments for insert"
    }

    my ($self, $table, $href, $whref) = @_;
    my ($found,$err, $exists_query);

    $self->_sql_quote_hash($href);

    if ($whref)
    {
	$self->_sql_quote_hash($href);
	$exists_query =
	    $self->_sql_select_query($table,[keys %$whref], $whref);
    } else
    {
	$exists_query =
	    $self->_sql_select_query($table, [keys %$href], $href);
    }

    $found = $self->value($exists_query);
    $err = $self->Error();

    if ($err)
    {
	Carp::confess ("SqlObject cond_insert exists error\n",
		       "Query: $exists_query\nError: $err")
    }

    return if $found;

    my $insert_query = $self->_sql_insert_query($table,$href);
    $self->do($insert_query);
    $err = $self->Error();
    if ($err)
    {
	Carp::confess ("SqlObject insert error\n",
		       "Query: $insert_query\nError: $err")
    }

    return 1;
}


sub insert_select {

    unless (@_>2 and @_ < 5)
    {
	Carp::confess "SqlObject: wrong number of arguments for insert_select"
    }

    my ($self, $table, $href, $column) = @_;
    my ($err, $insert_query);

    $column ||= join '_', $table, 'id';
    $column =~  s/^.*?(\w+)_id$/$1_id/;

    $self->_sql_quote_hash($href);

    $insert_query = $self->_sql_insert_query($table,$href);
    $self->do($insert_query);
    $err = $self->Error();

    if ($err)
    {
	Carp::confess ("SqlObject insert_select insert error\n",
		       "Query: $insert_query\nError: $err")
    }

    my $select_query = $self->_sql_select_query($table,[$column],$href);
    return $self->value($select_query);
}

sub cond_insert_select {

    unless (@_>2 and @_<6)
    {
	Carp::confess "SqlObject: wrong number of arguments for cond_insert_select"
    }

    my ($self, $table, $href, $arg4, $arg5) = splice @_, 0, 3;
    my ($whref,$column, $found, $err, $exists_query);

    $self->_sql_quote_hash($href);

    if (@_ == 1)
    {
	# we have whref or column but not both
	if (ref $_[0])
	{
	    $whref  = shift;
	}

        else
	{
	    $column = shift;
	}
    }
    elsif (@_ ==2) 
    {
	# we have both	$whref = shift;
	$column = shift;
	last;
    }
    else
    {
	# we have neither
	$column = join '_',$table,'id';
    }

    if ($whref)
    {
	$self->_sql_quote_hash($href);
	$exists_query = $self->_sql_select_query($table, [$column], $whref);
    }
    else
    {
	$exists_query = $self->_sql_select_query($table, [$column], $href);
    }

    $found = $self->value($exists_query);
    $err = $self->Error();

    if ($err)
    {
	Carp::confess ("SqlObject cond_insert_select exists error\n",
		       "Query: $exists_query\nError: $err")
    }

    return $found if $found;

    my $insert_query = $self->_sql_insert_query($table,$href);
    my $select_query = $self->_sql_select_query($table,[$column],$href);

    $self->do($insert_query);
    $err = $self->Error();

    if ($err)
    {
	Carp::confess ("SqlObject insert_select insert error\n",
		       "Query: $insert_query\nError: $err")
    }

    return $self->value($select_query);
}

sub update
{

    unless (@_>2 and @_<5)
    {
	Carp::confess "SqlObject: wrong number of arguments for update"
    }

    my ($self, $table, $shref, $whref) = @_;
    my($err, $query);


    $self->_sql_quote_hash($shref);
    $self->_sql_quote_hash($whref) if defined $whref && ref $whref;

    $query  = $self->_sql_update_query($table,$shref,$whref);
    $self->do($query);
    $err = $self->Error();

    if ($err)
    {
	Carp::confess ("SqlObject update error\n",
		       "Query: $query\nError: $err")
    }
}


## Here be the private methods

sub _sql_quote_hash
{
    my $href = pop;

    while ( my ($k,$v) = each %$href)
    {
	$v =~ s|^'||;
	$v =~ s|'$||;
	$v =~ s|'|''|g;
	$v =  qq('') if $v=~/^\s*$/;
	$v =  qq('$v') if $v=~/[^0-9]/ and $v!~/^null$/i;
	$href->{$k}=$v;
    }
}

sub _sql_insert_query
{
    return unless @_ > 2;

    my ($self, $table, $href) = @_;

    my ($columns,$values);
    while (my ($k,$v)=each %$href)
    {
	$columns .= "$k,";
	$values  .= "$v,";
    }
    $columns =~ s|,$||;
    $values  =~ s|,$||;

    return qq(insert into $table ($columns) values($values));
}

sub _sql_select_query {
    return unless @_ > 2;

    my ($self,$table,$aref,$href) = @_;
    my $columns = join ',',@$aref;
    my $where;

    while (my ($k,$v)=each %$href)
    {
	    $where .= qq($k = $v and );
    }
    $where =~ s|\s*and\s*$||;

    return qq(select $columns from $table where $where);
}

sub _sql_delete_query
{
    return unless @_ > 1;

    my ($self, $table, $href) = @_;
    return "delete from $table" if $href == undef;

    my $where;
    while (my ($k,$v)=each %$href) {
	$where .= qq($k = $v and );
    }
    $where =~ s|\s*and\s*$||;

    return qq(delete from $table where $where);
}

sub _sql_update_query {
    return unless @_ > 2;

    my ($self, $table, $shref, $whref) = @_;

    my ($set,$where);
    while (my ($k,$v)=each %$shref)
    {
	$set .= qq($k = $v, );
    }
    $set =~ s|\s*,\s*$||;

    if (ref $whref)
    {
	while (my ($k,$v)=each %$whref)
        {
	    $where .= qq($k = $v and );
	}
	$where=~ s|\s*and\s*$||;
	$where = "where $where";
    }

    return qq(update $table set $set $where);
}

our $AUTOLOAD;
sub AUTOLOAD
{
    $AUTOLOAD =~ /::([a-zA-Z_][a-zA-Z_0-9]+)$/;
    my $func = $1 or do
    {
	my @caller = caller;
	die (qq[Database Handle unable to dispatch.\n],
	     qq[Method $AUTOLOAD called by $caller[1] line $caller[2].\n]);
    };

    my $self = shift;
    my $result;

    if (my $dbh  = eval { $self->dbh })
    {
	$result = eval { $dbh->$func(@_) };
    }

    if ($@)
    {
	# error while calling DBI function
	my @caller = caller;
	my $err = ref $_[0] && UNIVERSAL::isa($_[0],__PACKAGE__) 
	          ? $_[0]->Error
		  : 'no object';
	die (qq[Database Handle encountered an error executing $func.\n],
	     qq[$AUTOLOAD called by $caller[1] line $caller[2].\n],
	     qq[Error: $@.\n],
	     qq[DBI Error: $err.\n]);
    }

    return $result;
}

1;

__END__

=pod

=head1 NAME

SqlObject - Sql module for wrappers around DBI

=head1 SYNOPSIS

    use SQL::SqlObject;

    $dbh = new SQL::SqlObject('my_db','dbi::pg','user','passwd');

    $dbh->db_dsn      = $dsn;    $dsn    = $dbh->db_dsn;
    $dbh->db_name     = $name;   $name   = $dbh->db_name;
    $dbh->db_user     = $user;   $usr    = $dbh->db_user;
    $dbh->db_password = $passwd; $passwd = $dbh->db_password;

    $dbh->connect([$SCALAR]); # Defaults to 'cezb-html'
    $dbh->disconnect();

    $SCALAR          = $dbh->value($SCALAR);
    [@LIST|$LISTREF] = $dbh->list($SCALAR);
    [@LIST|$LISTREF] = $dbh->array($SCALAR);
    [%HASH|$HASHREF] = $dbh->hash($SCALAR);
    [@AOH|$LISTREF]  = $dbh->hashes($SCALAR);

    $SCALAR = $dbh->insert_select($SCALAR,$HASHREF,[$SCALAR]);
    $dbh->insert($SCALAR,$HASHREF);
    $dbh->cond_insert($SCALAR,$HASHREF,[$HASHREF]);
    $SCALAR = $dbh->cond_insert_select($SCALAR,$HASHREF,[$HASHREF],[$SCALAR]);
    $dbh->delete($SCALAR,$HASHREF);
    $dbh->update($SCALAR,$HASHREF,[$HASHREF|$SCALAR]);

=head1 DESCRIPTION

The B<SQL::SqlObject> module allows you to use the B<DBI> module
with a hashref-based interface to the data.

Additionaly, as a wrapper module, calls on the B<SQL::SqlObject> instance
object which refer to a native L<DBI> method are passed through to the
underlying B<DBI> object.

Basicly, this module provides several functions to the underlying
B<DBI> object which are of great practical convience, particularly
when use B<DBI> under B<CGI>.

=head1 ABSTRACT

This program provides a set of utility functions to extend the
functionality of an underlying L<DBI> object around which the
B<SQL::SqlObject> is 'wrapped'.

This is intended to ease the delevopment of SQL intensive
applications.

This is B<not> intended as a replacement for Tim Bunce's L<DBI>
module, nor is it intended to surplant a full understanding of that
module, which the authors of the program consider a B<critical must> for
database programing in perl.

If you have not read the documentation for L<Tim Bunce's DBI
module|DBI>, or are not I<very> familiar with that document please
take take time to read it now.

Each B<SQL::SqlObject> instance object relies on an underly L<DBI>
object, the full functionality of which is available through the
B<SQL::SqlObject> wrapper.

=head1 EXAMPLES

    use SQL::SqlObject;

    # create an instance object connected to my_db
    $dbh = new SQL::SqlObject ("my_db");

    # print the number of rows in the table 'name'.
    print $dbh->value("select count(*) from name");

    # Print all of the first names in the table 'name' separated by
    # HTML line breaks.
    print join '<br>',$dbh->list("select first_name from name");

    # Print a list of all of the columns followed by the appropriate
    # data for a specific last name separated by HTML line breaks.
    %h = $dbh->hash("select * from name where last_name is 'Goff'");
    for (keys %h)) {
      print "$_: $h{$_}<br>";
    }

    # Print all of the names in the table 'name' separated by
    # HTML line breaks.
    for ($dbh->hashes("select first_name,last_name from name")) {
      print "$_->{first_name} $_->{last_name}<br>";
    }
    sub callback { print join '', map { "$_ => $h->{$_}\n" } shift }
    $dbh->hashes('select first_name,last_name from name',\&callback);

    # Insert data into the 'name' table
    %h = (first_name => 'Jeff', last_name => 'Goff');
    $dbh->insert('name',\%h);

    # Insert data into the 'name' table where an exactly
    # matching record doesn't already exist
    %h = (first_name => 'Corwin', last_name => 'Brust');
    if ($dbh->cond_insert('name',\%h)) {
      print "record was inserted"
    } else {
      print "record already existed"
    }

    # don't insert if a partial match is found
    %oh = (first_name => 'Corwin');
    $dbh->cond_insert('name',\%h, \%oh)

    # Insert data into the 'name' table and return
    # the 'name_id' field for the new row
    %h = (first_name => 'Someone' => last_name => 'New');
    $id = $dbh->insert_select('name',\%h);

    # same thing
    $id = $dbh->insert_select('name',\%h, 'name_id');

    # Insert data into the name table unless a matching
    # record is found.  Return 'name_id' for the existing
    # or inserted record
    %h = (first_name => 'Another' last_name => 'Newbie');
    $id = $dbh->cond_insert_select('name',\%h);

    # same thing
    $id = $dbh->cond_insert_select('name',\%h,'name_id');

    # partial match
    %oh = { first_name => 'Another' };
    $id = $dbh->cond_insert_select('name',\%h, \%oh);

    # same thing
    $id = $dbh->cond_insert_select('name',\%h, \%oh, 'name_id');

    # Delete a record from the 'name' table
    %h = (first_name => 'John', last_name => 'Public');
    $dbh->delete('name',\%h);

    # Update the 'Jeff Goff' record with a new business phone number
    %old = (first_name => 'Jeff', last_name => 'Goff');
    %new = (first_name => 'Jeff', last_name => 'Goff', bus_phone => '786-9601');
    $dbh->update('name',\%new,\%old);

=head1 CONSTRUCTOR

  $dbh = new SQL::SqlObject( [ SCALAR, [ SCALAR, [ SCALAR , [ SCALAR ] ] ]);

Creates an instance object of B<SQL::SqlObject> class, connected to
a database.

Arguments are as follows, each having a corrisponding
L<accessor|"ACCESSORS"> method.

=over

=item *
database name

The name of the database to which a connection should be made.

=item *
driver name (dsn)

The name of database driver to be used, in the format specified by the
L<BDI> module.

e.g.  dbi::pg

=item *
user name

The name of the user as which B<SQL::SqlObject> will attempt make it's
database connection.

NOTE: This is for the database's purposes only. This B<does not>
attempt any change in the effective user id under which a program
using B<SQL::SqlObject> is run.

=item *
password

The password for B<user name>, above, to be used in establishing
a database connection.

NOTE: Again, this is the password for the B<database user>, not a
system password.

=back

=head1 ACCESSORS

These methods provide access to the internal data stored by
B<SQL::SqlObject> instance objects.

=head2 dbh

  $dbh->dbh

Provides access to the underlying L<DBI> object.

The database handle (L<DBI>) is created the first time it is used, so
don't try somthing like:

  # This always works, if the module is 
  # properly installed and configured
  print "Connected" if $dbh->dbh;

To test if your B<SQL::SqlObject> instance object is connected the
L<DBI> which it is configured to wrap (eg: it has been used, since
the instance object was created) use this:

  print "Connected" if $dbh->is_connected;

NOTE: This is provided for the sake of completeness, and should not be
assigned to except possably by a program sub-classing this module
(L<See sub-classing|"SUB-CLASSING">).

=head2 db_name

  $name = $dbh->db_name;
  $dbh->db_name = 'my_database';

The name of database to which we'll be connecting.

=head2 db_user

  $user = $dbh->db_user;
  $dbh->db_user = 'perl_db_user';

The name of the database user for us to connect as.

=head2 db_password

  $passwd = $dbh->db_password;
  $dbh->db_password = 'perl_db_user_password';

The database password for the user as which we are connecting.

=head2 db_dsn

  $dsn = $dbh->db_dsn;
  $dbh->db_dsn = 'dbi::Sybase';

=head1 METHODS

The following subrutines are public methods available to instance
objects of the B<SQL::SqlObject> class.

=head2 is_connected

  $bool = $dbh->is_connected

Returns $bool will contain the value C<1> (one) if the database handle
has been invoked since the B<SQL::SqlObject> instance object was
created.

=head2 value

  SCALAR = $dbh->value( SCALAR )

Given a SQL SELECT statement return the first value of the result set
returned by the database after running that SQL.

  $sql = 'select first_name from name order by first_name limit 1';
  $firstfirst = $dbh->value($sql);

=head2 array

  LIST | LISTREF = $dbh->array( SCALAR )

Given a SQL SELECT statement return all values returned by that
statement after running that SQL, as a list or list reference.

This effectivly provides one step access to the C<fetchrow_arrayref>
method provided to B<DBI>'s L<statement handles|DBI/"DBI STATEMENT
HANDLE OBJECTS">. See L<Statement Handle Methods|DBI/"Statement Handle
Methods"> in the L<DBI> documentation for more information on the
C<fetchrow_arrayref> method.

=head2 list

  LIST | LISTREF = $dbh->list( SCALAR )

Given a SQL statement return the first value from all rows returned by
the database after running that SQL.

  $sql = 'select first_name from name order by first_name';
  @list = $dbh->list($sql);
  $listref = $dbh->list($sql);

=head2 hash

  HASH | HASHREF = $dbh->hash( SCALAR )

Given a SQL SELECT statement return all field names and values
returned by the database after running that SQL as a hash or hash
reference.

This effectivly provides one step access to the C<fetchrow_hashref>
method provided to B<DBI>'s L<statement handles|DBI/"DBI STATEMENT
HANDLE OBJECTS">. See L<Statement Handle Methods|DBI/"Statement Handle
Methods"> in the L<DBI> documentation for more information on the
C<fetchrow_hashref> method.

  my $sql = "select * from names where name_id = 1";
  %hash = $dbh->hash($sql);
  while my ($k, $v) (each %hash) {
    print "Field: $k\t";
    print "Value: $v\n";
  }

  $hashref = $dbh->hash($sql);
  printf "Field: %-20s\t%%s\n" $_, $hashref->{$_} for keys %$hashref;

=head2 hashes

  LIST | LISTREF = $dbh->hashes( SCALAR )

Given a SQL SELECT statement return all field names and values
returned by the database after running that SQL as a list of hash
references, or reference to a list of hash references.

Like the L<hash|"hash"> method, above, but returns all database rows
(where L<hash|"hash"> will return data from -at most- one row).

  my $sql = "select * from names order by name_id";
  @AoH = $dbh->hashes($sql);
  for my ($href) (@AoH) {
    print "$href->{last_name}, $href->{first_name}\n";
  }

  $listref = $dbh->hashes($sql);
  print map {
    "$listref->[$_]->{first_name} $listref->[$_]->{last_name}"
  } for 0..$#  $listref;

=head2 insert

  $dbh->insert( SCALAR, HASHREF);

Given a table name and a reference to an hash of field names and
values, perform a SQL INSERT query.

  %data = (first_name => 'Larry', last_name => 'Wall');
  $dbh->insert('name',\%data);

=head2 cond_insert

  SCALAR = $dbh->cond_insert( SCALAR, HASHREF [, HASHREF ])

Given a B<table name> and a reference to an hash of field names and
values, perform a SQL INSERT query unless a record exists already
exists in the specified table matching all values given in the hash
reference.

  %data = (first_name => 'Tim', last_name => 'Bunce');
  $bool_did_insert = $dbh->cond_insert('name',\%data);

If a second hash reference is provided, no C<INSERT QUERY> is
performed if a record can be found which exactly matches the values
provided for the fields listed therein.

  %data = (first_name => 'Tim', last_name => 'Bunce');
  %check = (last_name => 'Bunce');
  $bool_did_insert = $dbh->cond_insert('name',\%data, \%check);

If an C<INSERT QUERY> was performed, B<cond_insert> returns 1,
otherwise no return value is defined.

=head2 insert_select

  SCALAR = $dbh->insert_select( SCALAR, %HREF [, SCALAR] );

Given a B<table name>; a reference to an hash of field names and
values; and (optionaly) a B<field name> to select on success: Perform
a SQL C<INSERT QUERY> and select B<field name> from the newly inserted
row. 

If no B<field name> is provided a value of "<table>_id" is assumed.

  %data = (first_name => 'Bruce', last_name => 'Banner');
  $name_id = $dbh->insert_select('name',\%data);

  # get the 'create_time' field, after insert...
  %data = (first_name => 'Peter' last_name => 'Parker');
  $ctime = $dbh->insert_select('name',\%data,'create_time');

=head2 cond_insert_select

  SCALAR = $dbh->cond_insert_select( SCALAR, HASHREF [, HASHREF] [, SCALAR ])

Given a B<table name>; a reference to an hash of field names and
values; (optionaly) a reference to a second hash of field names and
values; and (optionaly) a B<field name>: Perform a SQL C<INSERT QUERY>
and select B<field name> from the newly inserted row B<only> if a row
matching all values from the second hash reference (or the first, if
only one was provided) cannot be found within the given table, then
return B<field name>.

As with L<cond_insert|"cond_insert">, if no B<field name> is provided
a value of "<table>_id" is assumed.

B<cond_insert_select> returns B<field name>

  %data = (first_name => 'Pappa', last_name => 'Smurf');
  $name_id = $dbh->cond_insert_select('name',\%data);


  # get name.name_id for a record where last_name = 'Ock'
  # or insert a new record for Doc Ock and get the name_id
  # for the new row.
  %data = (first_name => 'Doc', last_name => 'Ock');
  %where = (last_name => 'Ock');
  $name_id = $dbh->cond_insert_select('name',\%data,\%where);

  # insert a record for marilyn mason (unless one already
  # exists).  In either case, get the create_date for
  # marilyn's record in the 'name' table.
  %data = (first_name => 'Marilyn', last_name => 'Mason');
  $cdate = $dbh->cond_insert_select('name',\%data,'create_date');

  # insert a record for Doc Smith (unless there is already a record
  # where first_name = 'Doc').  Return the last_name field of the
  # record matched or inserted.
  %data = (first_name => 'Doc', last_name => 'Smith');
  %where = (first_name => 'Doc');
  $last = $dbh->cond_insert_select('name',\%data,\%where,'last_name');
  if ($last eq 'Smith') { print "inserted Doc Smith !" }
  else                  { print "found Doc $last !"    }

=head2 update

  $dbh->update( SCALAR, HASHREF,  SCALAR | HASHREF)

Given a B<table name>; a reference to a hash of field names and
values; and either a SQL where clause or a reference to a second hash
of field names and values: Update B<table name>.

  # set last_name = 'Smith' where first_name = 'Doc'
  %data = { last_name => 'Smith' };
  $dbh->update('name', \%data, q/where first_name = 'Doc'/);

  # set first_name = 'Bob' where last_name = 'Smith'
  %data = ( first_name => 'Bob' );
  %where = { last_name => 'Smith' };
  $dbh->update('name',\%data, \%where);

=head2 delete

  $dbh->delete (SCALAR, HASHREF)

Given a B<table name> and a reference to a hash of field names and
values, delete records from B<table name> which match hold values
currisponding to those in the provided hash reference for fields
specified by the keys of that hash reference.

  %data = (first_name => 'Bob', last_name => 'Smith');
  $dbh->delete('name',\%data);

=head1 SUB-CLASSING

In using this module, for our own nefarious purposes, we have found
that providing the various server/project specific data is often most
easily accomplished by creating a per server/project subclass of the
B<SQL::SqlObject> module.

This is quite easy to accomplish, and though TMTOWTDI certialy rules
our universe, the following should provide you with a good start to
doing this for your own needs.

  package MySqlProject;

  use strict;
  use warnings;
  use SQL::SqlObject;
  use base 'SQL::SqlObject';

  # post constructor processing
  sub _init {
    my ($self) = @_;
    $self->db_dsn      = 'dbi:mysql';     # DBD drive
    $self->db_name     = 'mysqldatabase'; # db name
    $self->db_name     = 'myclient';      # db username
    $self->db_password = 'mypassword';    # db password
  }

  __END__

  =head1 SEE ALSO

  L<SQL::SqlObject> - our base class

This allows you to write a script like

  #/bin/perl -w
  #
  # List of sometable entries, seperated by a blank line
  #
  use strict;
  use MySqlProject;
  my $dbh = new MySqlProject;
  for my $hashref ($dbh->hashes("select * from sometable"))
  {
      while (my ($col_name, $value) = each %$hashref)
      {
	  print $col_name, '.' x 20 - length $col_name, $value, "\n";
      }
      print "\n";
  }

Compare that to the following exactly equilivent example which doesn't
make use of the subclass.

  #/bin/perl -w
  #
  # List of sometable entries, seperated by a blank line
  #
  use strict;
  use MySqlProject;
  my $dbh = new MySqlProject(
                              --name     => 'mysqldatabase',
                              --user     => 'myclient',
                              --password => 'mypassword'
                             );
  $dbh->db_dsn = 'dbi::mysql';
  for my $hashref ($dbh->hashes("select * from sometable"))
  {
    ...


As you can see, there are only a few lines of difference, however,
consider the need to reapeat this in every script which makes a
database connection the convience of the former approach becomes
clear.

=head1 SEE ALSO

=over

=item *
L<DBI>

=item *
perl(1)

=back

=head1 NOTE

SQL::SqlObject may be redistributed under the same terms as Perl.

=head1 AUTHOR

The SqlObject interface was written by
Jeff Goff (E<lt>jgoff@hargray.comE<gt>) and
Corwin Brust (E<lt>cbrust@mpls.cxE<gt>)

=cut

