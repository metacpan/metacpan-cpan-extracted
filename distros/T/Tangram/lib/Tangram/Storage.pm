package Tangram::Storage;

use strict;

use Tangram::Storage::Statement;

use DBI;
use Carp;

use Tangram::Util qw(pretty);
use Scalar::Util qw(weaken refaddr);

use vars qw( %storage_class );

sub new
{
    my $pkg = shift;
    return bless { @_ }, $pkg;
}

# XXX - not tested by test suite
sub schema
{
    shift->{schema}
}

sub export_object
  {
    my ($self, $obj) = @_;
    my $oid = $self->{get_id}->($obj);
    return ($oid ? $self->{export_id}->($oid) : undef);
  }

sub split_id
  {
	carp unless wantarray;
	my ($self, $id) = @_;
	my $cid_size = $self->{cid_size};
	return ( substr($id, 0, -$cid_size), substr($id, -$cid_size) );
  }

use Scalar::Util qw(looks_like_number);

# Given a row's ID and a class's ID
# Computes its OID and returns it
sub combine_ids
  {
	my $self = shift;
	looks_like_number(my $id = shift) or confess "no id";
	looks_like_number(my $cid = shift) or confess "no cid";
	defined($self->{cid_size}) or die "no CID size in schema";
	return ( $self->{layout1}
		 ? shift
		 : sprintf("%d%0$self->{cid_size}d", $id, $cid) );
  }

sub from_dbms
    {
	my $self = shift;
	my $driver = $self->{driver} or confess "no driver";
	return $self->{driver}->from_dbms(@_);
    }

sub to_dbms
    {
	my $self = shift;
	my $driver = $self->{driver} or confess "no driver";
	return $self->{driver}->to_dbms(@_);
    }

# XXX - not tested by test suite
sub get_sequence {
    my $self = shift;
    my $sequence_name = shift;

    # this is currently relying on the convenient co-incidence that
    # the only database that has a non-trivial sequence sql fragment
    # also doesn't use " FROM DUAL"
    my $query = $self->sequence_sql($sequence_name).$self->from_dual;
    my ($id) = (map { @{$_} }
		map { @{$_} }
		$self->{db}->selectall_arrayref($query));

    return $id;
}

# XXX - not tested by test suite
sub sequence_sql
    {
	my $self = shift;
	my $driver = $self->{driver} or confess "no driver";
	return $self->{driver}->sequence_sql(shift);
    }

# XXX - not tested by test suite
sub limit_sql {
    my $self = shift;

    my $driver = $self->{driver} or confess "no driver";
    return $self->{driver}->limit_sql(@_);
}

sub _open
  {
    my ($self, $schema) = @_;

	my $dbh = $self->{db};

    $self->{table_top} = 0;
    $self->{free_tables} = [];

    $self->{tx} = [];

    $self->{schema} = $schema;

	{
	  local $dbh->{PrintError} = 0;
	  my $control;
	  if ( $schema->{sql}{oid_sequence} ) {
	      # XXX - not tested by test suite
	      $control = "dummy";
	  } else {
	      $control = $dbh->selectall_arrayref
		  ("SELECT * FROM $schema->{control}")
		  or die $DBI::errstr;
	  }

	  $self->{id_col} = $schema->{sql}{id_col};

	  if ($control) {
		$self->{class_col} = $schema->{sql}{class_col} || 'type';
		$self->{import_id} = sub { shift() . sprintf("%0$self->{cid_size}d", shift()) };
		$self->{export_id} = sub { substr shift(), 0, -$self->{cid_size} };
	  } else {
	      # XXX - layout1
	      $self->{class_col} = 'classId';
	      $self->{layout1} = 1;
	      $self->{import_id} = sub { shift() };
	      $self->{export_id} = sub { shift() };
	  }
	}

	my %id2class;

	if ($self->{layout1}) {
	    # XXX - layout1
	  %id2class = map { @$_ } @{ $self->{db}->selectall_arrayref("SELECT classId, className FROM $schema->{class_table}") };
	} else {
	  my $classes = $schema->{classes};
	  %id2class = map { $classes->{$_}{id}, $_ } keys %$classes;
	}

	$self->{id2class} = \%id2class;
	@{ $self->{class2id} }{ values %id2class } = keys %id2class;

    $self->{set_id} = $schema->{set_id} ||
      sub
	{
	  my ($obj, $id) = @_;

	  if ($Tangram::TRACE && ($Tangram::DEBUG_LEVEL > 2)) {
		if ($id) {
		   print $Tangram::TRACE "Tangram: welcoming $obj as $id\n";
		} else {
		   print $Tangram::TRACE "Tangram: un-welcoming $obj\n";
		}
	  }
	  if ($id) {
	    $self->{ids}{refaddr($obj)} = [$id, \$self->{objects}{$id}];
	  } else {
	    delete $self->{ids}{refaddr($obj)};
	  }
	};

    $self->{get_id} = $schema->{get_id} || sub {
	  my $obj = shift or warn "no object passed to get_id";
	  ref $obj or return undef;
	  my $address = refaddr($obj)
	      or do { warn "Object $obj has no refaddr(?)";
		      return undef };
	  my $id = $self->{ids}{$address};
	  # refaddr's can be re-used, but weakrefs are magic :-)
	  if ( $id and !defined ${$id->[1]} ) {
	      delete $self->{ids}{$address};
	      delete $self->{objects}{$id->[0]};
	      $id = undef;
	  } elsif ( $id and refaddr($self->{objects}{$id->[0]}) != $address ) {
	      delete $self->{ids}{$address};
	      $id = undef;
	  }
	  if ($Tangram::TRACE && ($Tangram::DEBUG_LEVEL > 2)) {
		print $Tangram::TRACE "Tangram: $obj is ".($id?"oid $id->[0]" : "not in storage")."\n";
	  }
	  return $id->[0];
	};

    return $self;
  }

sub alloc_table
{
    my ($self) = @_;

    return @{$self->{free_tables}} > 0
	? pop @{$self->{free_tables}}
	    : ++$self->{table_top};
}

# XXX - not reached by test suite
sub free_table
{
    my $self = shift;
    push @{$self->{free_tables}}, grep { $_ } @_;
}

sub open_connection
{
    # private - open a new connection to DB for read

    my $self = shift;
    my $attr = {};
    if (defined $self->{no_tx}) {
	$attr->{AutoCommit} = ($self->{no_tx} ? 1 : 0);
	print $Tangram::TRACE __PACKAGE__.": setting AutoCommit to $attr->{AutoCommit}\n"
	    if $Tangram::TRACE;
    }
    my $db = DBI->connect($self->{-cs}, $self->{-user}, $self->{-pw},
			  $attr)
	or die;

    return $db;
}

# XXX - not reached by test suite
sub close_connection
  {
    # private - close read connection to DB unless it's the default one
	
    my ($self, $conn) = @_;

	return unless $conn &&  $self->{db};
	
    if ($conn == $self->{db})
	  {
		$conn->commit unless $self->{no_tx} || @{ $self->{tx} };
	  }
    else
	  {
		$conn->disconnect;
	  }
  }

sub cursor
{
    my ($self, $class, @args) = @_;

    my $cursor = Tangram::Cursor->new($self, $class, #$self->open_connection());
				      $self->{db});
    $cursor->select(@args);

    return $cursor;
}

sub my_cursor
{
    my ($self, $class, @args) = @_;
    my $cursor = Tangram::Cursor->new($self, $class, $self->{db});
    $cursor->select(@args);
    return $cursor;
}

# XXX - not reached by test suite
sub select_data
{
    my $self = shift;
    Tangram::Expr::Select->new(@_)->execute($self, $self->open_connection());
}

# XXX - not reached by test suite
sub selectall_arrayref
{
    shift->select_data(@_)->fetchall_arrayref();
}

sub my_select_data
{
    my $self = shift;
    Tangram::Expr::Select->new(@_)->execute($self, $self->{db});
}

my $psi = 1;

sub prepare
  {
	my ($self, $sql) = @_;
	
	print $Tangram::TRACE "Tangram::Storage: "
	    ."preparing: [@{[ $psi++ ]}] >-\n$sql\n...\n"
	    if $Tangram::TRACE && ($Tangram::DEBUG_LEVEL > 1);
	$self->{db}->prepare($sql);
  }

*prepare_insert = \&prepare;
*prepare_update = \&prepare;
*prepare_select = \&prepare;

# XXX - lots of options here not tested by test suite
sub make_id
  {
    my ($self, $class_id, $o) = @_;

    # see if the class has its own ID generator
    my $cname = $self->{id2class}{$class_id};
    my $classdef = $self->{schema}{classes}{$cname};

    my $id;
    if ( $classdef->{make_id} ) {
	$id = $classdef->{make_id}->($class_id, $self, $o);
	print $Tangram::TRACE "Tangram: custom per-class ($cname) make ID function returned ".(pretty($id))."\n" if $Tangram::TRACE;
    } elsif ( $classdef->{oid_sequence} ) {
	eval { $id = $self->get_sequence($classdef->{oid_sequence}) };
	die "Failed to get sequence for Class `$cname'; $@" if $@;
    }

    # maybe the entire schema has its own ID generator
    if ( !defined($id) and $self->{schema}{sql}{make_id} ) {
	$id = $self->{schema}{sql}{make_id}->($class_id, $self, $o);
	print $Tangram::TRACE "Tangram: custom schema make ID function returned "
	    .(pretty($id))."\n" if $Tangram::TRACE;
    } elsif ( !defined($id) &&
	      (my $seq = $self->{schema}{sql}{oid_sequence}) ) {
	eval { $id = $self->get_sequence($seq) };
	die "Failed to get sequence for Class `$cname' via fallback $seq; $@"
	    if $@;
    }
    if (defined($id)) {
	return $self->combine_ids($id, $class_id);
    }

	unless ($self->{layout1}) {

	  if (exists $self->{mark}) {
		$id = $self->{mark}++;
		$self->{set_mark} = 1;	# cleared by tx_start
	  } else {
		$id = $self->make_1st_id_in_tx();
		$self->{mark} = $id+1;
 		$self->{set_mark} = 1;
	  }

	  return sprintf "%d%0$self->{cid_size}d", $id, $class_id;
	}

    # XXX - layout1

	# ------------------------------
	# compatibility with version 1.x

    my $alloc_id = $self->{alloc_id} ||= {};
    
    $id = $alloc_id->{$class_id};
    
    if ($id)      {
		$id = -$id if $id < 0;
		$alloc_id->{$class_id} = ++$id;
      } else {
		my $table = $self->{schema}{class_table};
		$self->sql_do("UPDATE $table SET lastObjectId = lastObjectId + 1 WHERE classId = $class_id");
		$id = $self
		  ->sql_selectall_arrayref("SELECT lastObjectId from $table WHERE classId = $class_id")->[0][0];
		$alloc_id->{$class_id} = -$id;
      }
    
    return sprintf "%d%0$self->{cid_size}d", $id, $class_id;
  }

sub make_1st_id_in_tx
  {
    my ($self) = @_;
    
	unless ($self->{make_id}) {
	  my $table = $self->{schema}{control};
	  my $dbh = $self->{db};
	  $self->{make_id}{inc} = $self->prepare("UPDATE $table SET mark = mark + 1");
	  $self->{make_id}{set} = $self->prepare("UPDATE $table SET mark = ?");
	  $self->{make_id}{get} = $self->prepare("SELECT mark from $table");
	}
	
	my $sth;
	
	$sth = $self->{make_id}{inc};
	$sth->execute();
	$sth->finish();
	
	$sth = $self->{make_id}{get};
	$sth->execute();
    my $row = $sth->fetchrow_arrayref() or
	die "`Tangram' table corrupt; insert a valid row!";
	my $id = $row->[0];
    while ($row =  $sth->fetchrow_arrayref()) {
	warn "Eep!  More than one row in `Tangram' table!";
	$id = $row->[0] if ($row->[0] > $id);
    }
	$sth->finish();

	return $id;
  }

sub update_id_in_tx
  {
	my ($self, $mark) = @_;
	my $sth = $self->{make_id}{set};
	$sth->execute($mark);
	$sth->finish();
  }

sub unknown_classid
{
    my $class = shift;
    confess "class '$class' doesn't exist in this storage"
}

{
    no strict 'refs';
# Given a class name ('Foo::Bar'), returns its Class ID.
sub class_id
{
    my $self = shift;
    $self->{class2id}{$_[0]} or do {
	# crawl ISA tree...
	my @stack = \%{$_[0]."::"};
	my $seen = Set::Object->new(@stack);
	while ( my $stash = pop @stack ) {
            defined $stash or next;
            my @supers = @{ *{$stash->{ISA}}{ARRAY} }
		if exists $stash->{ISA};
	    for my $super ( @supers ) {
		if ( defined $self->{class2id}{$super} ) {
		    $self->{class2id}{$_[0]}
			= $self->{class2id}{$super};
		    $self->{schema}{classes}{$_[0]}
			= $self->{schema}{classes}{$super};
		    goto OK
		}
		else {
		    $super = \%{$super."::"};
		}
	    }
	    push @stack, grep { $seen->insert($_) } @supers;
	}
    OK:
	$self->{class2id}{$_[0]};
    } or
	unknown_classid $_[0];
}
}

#############################################################################
# Transaction

my $error_no_transaction = 'no transaction is currently active';

sub tx_start
{
    my $self = shift;

	unless (@{ $self->{tx} }) {
	  delete $self->{set_mark};
	  delete $self->{mark};
	  print $Tangram::TRACE "Tangram: ".("-"x 10)." START TRANSACTION; "
	      .("-"x 10)."\n"
	      if $Tangram::TRACE && ($Tangram::DEBUG_LEVEL > 0);
	  unless ($self->{no_tx}) {
	      $self->{db}->{AutoCommit} = 1;
	      $self->{db}->{AutoCommit} = 0;
	      #eval { $self->{db}->rollback(); };
	      #$self->{db}->begin_work();
	  }
	} else {
	  print $Tangram::TRACE "Tangram: START TRANSACTION; (virtual)\n"
	      if $Tangram::TRACE && ($Tangram::DEBUG_LEVEL > 1);
	}

    push @{ $self->{tx} }, [];
}

sub tx_commit
  {
    # public - commit current transaction
    
    my $self = shift;
    
    carp $error_no_transaction unless @{ $self->{tx} };
    
    # update lastObjectId's
    
    if ($self->{set_mark}) {
	  $self->update_id_in_tx($self->{mark});
	}

	# ------------------------------
	# compatibility with version 1.x

    if (my $alloc_id = $self->{alloc_id}) {
	  my $table = $self->{schema}{class_table};
	
	  for my $class_id (keys %$alloc_id)
		{
		  my $id = $alloc_id->{$class_id};
		  next if $id < 0;
		  $self->sql_do("UPDATE $table SET lastObjectId = $id WHERE classId = $class_id");
		}
	  
	  delete $self->{alloc_id};
	}
	
    # XXX - layout1
	# compatibility with version 1.x
	# ------------------------------
    
    unless ($self->{no_tx} || @{ $self->{tx} } > 1) {
	  # committing outer tx: commit to db
	  print $Tangram::TRACE "Tangram: ".("-"x 10)." COMMIT; ".("-"x 10)."\n"
	      if $Tangram::TRACE && ($Tangram::DEBUG_LEVEL > 0);
	  $self->{db}->commit;
	} else {
	  print $Tangram::TRACE "COMMIT; (virtual)\n"
	      if $Tangram::TRACE && ($Tangram::DEBUG_LEVEL > 1);
	}
	
    pop @{ $self->{tx} };		# drop rollback subs
  }

sub tx_rollback
  {
    my $self = shift;

    my $num;
    if ( defined ($num = (shift))) {
	$self->tx_rollback() while (@{ $self->{tx} } and $num--);
	return;
    }

    carp $error_no_transaction unless @{ $self->{tx} };


    if ($self->{no_tx})
      {
		pop @{ $self->{tx} };
      }
    else
      {
		$self->{db}->rollback if @{ $self->{tx} } == 1; # don't rollback db if nested tx

		# execute rollback subs in reverse order

		if (my $rb = pop @{ $self->{tx} }) {
		    foreach my $rollback ( @$rb )
			{
			    $rollback->($self);
			}
		}
	  }
}

sub tx_do
{
    # public - execute subroutine inside tx

    my ($self, $sub, @params) = @_;

    $self->tx_start();

    my ($results, @results);
    my $wantarray = wantarray();

    eval
    {
		if ($wantarray)
		{
			@results = $sub->(@params);
		}
		else
		{
			$results = $sub->(@params);
		}
    };

    if ($@)
    {
		$self->tx_rollback();
		die $@;
    }
    else
    {
		$self->tx_commit();
    }

    return wantarray ? @results : $results;
}

sub tx_on_rollback
{
    # private - register a sub that will be called if/when the tx is rolled back

    my ($self, $rollback) = @_;
    carp $error_no_transaction if $^W && !@{ $self->{tx} };
    unshift @{ $self->{tx}[0] }, $rollback; # rollback subs are executed in reverse order
}

#############################################################################
# insertion

sub insert
{
    # public - insert objects into storage; return their assigned ids

    my ($self, @objs) = @_;

    my @ids = $self->tx_do(
	   sub
	   {
		   my ($self, @objs) = @_;
		   map
		   {
			   local $self->{defered} = [];
			   my $id = $self->_insert($_, Set::Object->new() );
			   $self->do_defered;
			   $id;
		   } @objs;
	   }, $self, @objs );

    return wantarray ? @ids : shift @ids;
}

sub _insert
{
    my ($self, $obj, $saving) = @_;

	die unless $saving;

    my $schema = $self->{schema};

    return $self->id($obj)
      if $self->id($obj);

    $saving->insert($obj);

    my $class_name = ref $obj;
    my $classId = $self->class_id($class_name);

    my $class = $self->{schema}->classdef($class_name);

    my $id = $self->make_id($classId, $obj);

    $self->welcome($obj, $id);
    $self->tx_on_rollback( sub { $self->goodbye($obj, $id) } );

	my $dbh = $self->{db};
	my $engine = $self->{engine};

	my $sths = $self->{INSERT_STHS}{$class_name} ||=
	  [ map { $self->prepare($_) } $engine->get_insert_statements($class) ];

	my $context =
	    { storage => $self,
	      dbh => $dbh,
	      id => $id,
	      SAVING => $saving };

	my @state = (
		     $self->{export_id}->($id),
		     $classId,
		     $class->get_exporter({layout1 => $self->{layout1} })
		         ->($obj, $context)
		    );

	my @fields = $engine->get_insert_fields($class);

	use integer;

	for my $i (0..$#$sths) {

	  if ($Tangram::TRACE) {
		my @sql = $engine->get_insert_statements($class);
		printf $Tangram::TRACE ">-\n%s\n".(@{$fields[$i]}?"-- with:\n    /* (%s) */\n":"%s")."...\n",
		$sql[$i],
		join(', ', map { defined($_)?$dbh->quote($_):"NULL" }
		     @state[ @{ $fields[$i] } ] )
	  }

	  my $sth = $sths->[$i];


	  my @args = (map {( ref $_ ? "$_" : $_ )} @state[ @{ $fields[$i] } ]);
	  #print STDERR "args are: ".Data::Dumper::Dumper(\@args);
	  #kill 2, $$;
	  $sth->execute(@args)
	      or die $dbh->errstr;

	  $sth->finish();
	}

    return $id;
  }

#############################################################################
# update

sub update
{
    # public - write objects to storage

    my ($self, @objs) = @_;

    $self->tx_do(
		 sub
		 {
		     my ($self, @objs) = @_;
		     foreach my $obj (@objs)
		     {
			   local $self->{defered} = [];

			   $self->_update($obj, Set::Object->new() );
			   $self->do_defered;
		     }
		   }, $self, @objs);
  }

sub _update
  {
    my ($self, $obj, $saving) = @_;

	die unless $saving;

    my $id = $self->id($obj) or confess "$obj must be persistent";

    $saving->insert($obj);

    my $class = $self->{schema}->classdef(ref $obj);
	my $engine = $self->{engine};
	my $dbh = $self->{db};
	my $context =
	    { storage => $self,
	      dbh => $dbh,
	      id => $id,
	      SAVING => $saving };

	my @state = ( $self->{export_id}->($id), substr($id, -$self->{cid_size}), $class->get_exporter({ layout1 => $self->{layout1} })->($obj, $context) );
	my @fields = $engine->get_update_fields($class);

	my $sths = $self->{UPDATE_STHS}{$class->{name}} ||=
	  [ map {
		print $Tangram::TRACE ">-\n$_\n...\n"
		    if ( $Tangram::TRACE && ( $Tangram::DEBUG_LEVEL > 1 ) );
		$self->prepare($_)
	  } $engine->get_update_statements($class) ];

	use integer;

	for my $i (0..$#$sths) {

	  if ($Tangram::TRACE) {
		my @sql = $engine->get_update_statements($class);
		printf $Tangram::TRACE ">-\n%s\n-- with\n    /* (%s) */\n...\n",
		$sql[$i],
		join(', ', map { defined($_)?$dbh->quote($_):"NULL" }
		     @state[ @{ $fields[$i] } ] )
	  }

	  my $sth = $sths->[$i];
	  $sth->execute(@state[ @{ $fields[$i] } ]);
	  $sth->finish();
	}
  }

#############################################################################
# save

# XXX - not documented / tested
sub save
  {
    my $self = shift;
	
    foreach my $obj (@_) {
	  if ($self->id($obj)) {
	    $self->update($obj)
	  }	else {
	    $self->insert($obj)
	  }
    }
  }

sub _save
  {
	my ($self, $obj, $saving) = @_;
	
	if ($self->id($obj)) {
	  $self->_update($obj, $saving)
	} else {
	  $self->_insert($obj, $saving)
	}
  }


#############################################################################
# erase

sub erase
  {
    my ($self, @objs) = @_;

    $self->tx_do(
		 sub
		 {
		   my ($self, @objs) = @_;
		   my $schema = $self->{schema};
		   my $classes = $self->{schema}{classes};

		   foreach my $obj (@objs)
		     {
		       my $id = $self->id($obj) or confess "object $obj is not persistent";
			   my $class = $schema->classdef(ref $obj);

		       local $self->{defered} = [];
			   
		       $schema->visit_down(ref($obj),
					   sub
					   {
					     my $class = shift;
					     my $classdef = $classes->{$class};

					     foreach my $typetag (keys %{$classdef->{members}}) {
					       my $members = $classdef->{members}{$typetag};
					       my $type = $schema->{types}{$typetag};
					       $type->erase($self, $obj, $members, $id);
					     }
					   } );

			   my $sths = $self->{DELETE_STHS}{$class->{name}} ||=
				 [ map { $self->prepare($_) } $self->{engine}->get_deletes($class) ];
		   
		       my $eid = $self->{export_id}->($id);

			   for my $sth (@$sths) {
			       $sth->execute($eid) or die "execute failed; ".$DBI::errstr;
			       $sth->finish();
			   }

		       $self->do_defered;

		       $self->goodbye($obj, $id);
		       $self->tx_on_rollback( sub { $self->welcome($obj, $id) } );
		     }
		 }, $self, @objs );
  }

sub do_defered
{
    my ($self) = @_;

    foreach my $defered (@{$self->{defered}})
    {
		$defered->($self);
    }

    $self->{defered} = [];
}

sub defer
{
    my ($self, $action) = @_;
    push @{$self->{defered}}, $action;
}

# Given a class' name and a row's ID (or more than one,)
# computes the OIDs and returns them.
# XXX - not tested by test suite
sub make_oid
{
  my $self = shift;
  my $class_name = shift;
  my @ids = @_;
	
  my $class_id = $self->class_id($class_name);
  
  my @oids = map {$self->combine_ids($_,$class_id)} @ids;
  
  if ( wantarray ) {
	return @oids;
  } else {
	return $oids[0];
  }
}

# Given a class' name and a row's ID (or more than one,)
# loads the object(s) from the DB and returns them.
sub import_object
{
    my $self = shift;
    my $class = shift;
    my @oids = @_;

    my $r_thing = $self->remote($class);

    my %objs = map { $self->export_object($_) => $_ }
	$self->select ($r_thing, $r_thing->{id}->in(@oids));

    my @objs = map { delete $objs{$_} } @oids;

    if ( wantarray ) {
	return @objs
    } else {
	return $objs[0];
    }
}

# XXX - not documented or tested by test suite
sub dummy_object
{
    my $self = shift;
    my ($class, $id, $oid);
    if ( @_ == 2 ) {
	$class = shift;
	$id = shift;
	my $cid = $self->class_id($class);
	$oid = $self->combine_ids($id, $cid);
    } else {
	$oid = shift;
    }

    $self->{objects}{$oid} ||= do {
	my $obj = bless \$oid, "Tangram::DummyObj";
	$self->welcome($obj, $oid);
	$obj;
    };
}

sub load
{
    my $self = shift;

    return map { scalar $self->load( $_ ) } @_ if wantarray;

    my $id = shift;
    die if @_;

    return $self->{objects}{$id}
      if exists $self->{objects}{$id} && defined $self->{objects}{$id};

    my $class = $self->{schema}->classdef( $self->{id2class}{ int(substr($id, -$self->{cid_size})) } );

	my $row = _fetch_object_state($self, $id, $class);

    my $obj = $self->read_object($id, $class->{name}, $row);

    # ??? $self->{-residue} = \@row;

    return $obj;
}

sub reload
{
    my $self = shift;

    return map { scalar $self->load( $_ ) } @_ if wantarray;

	my $obj = shift;
    my $id = $self->id($obj) or die "'$obj' is not persistent";
    my $class = $self->{schema}->classdef( $self->{id2class}{ int(substr($id, -$self->{cid_size})) } );

	my $row = _fetch_object_state($self, $id, $class);
    _row_to_object($self, $obj, $id, $class->{name}, $row);

    return $obj;
}

sub welcome
  {
    my ($self, $obj, $id) = @_;
    delete $self->{objects}{$id};
    weaken( $self->{objects}{$id} = $obj );
    $self->{set_id}->($obj, $id);
  }

sub goodbye
  {
    my ($self, $obj, $id) = @_;
    $self->{set_id}->($obj, undef) if $obj;
    delete $self->{objects}{$id};
    delete $self->{PREFETCH}{$id};
  }

# XXX - not documented or tested by test suite
sub shrink
  {
    my ($self) = @_;

    my $objects = $self->{objects};
    my $prefetch = $self->{PREFETCH};

    for my $id (keys %$objects)
      {
	next if $objects->{$id};
	delete $objects->{$id};
	delete $prefetch->{$id};
      }
  }

sub read_object
  {
    my ($self, $id, $class, $row, @parts) = @_;

    my $schema = $self->{schema};

    my ($obj, $target, $is_dummy);

    if (exists $self->{objects}{$id} && defined $self->{objects}{$id}) {
	# it's already in the cache, just return it.
	$obj = $self->{objects}{$id};

	# XXX - we are only doing this because we don't have an easy
	# way of knowing how many columns each of the importers for
	# this column type are returning.  It would be better to
	# improve the importer protocol, and then just shift off the
	# unneeded columns.

	# the only reason we need to shift them off is for
	# $cursor->residue(), which would otherwise return a variable
	# number of items depending on whether we already had the row
	# hot or not.

	$target = bless {}, "dummy";
	if ( $Tangram::TRACE ) {
	    print $Tangram::TRACE __PACKAGE__.": made dummy object "
		."$target\n";
	}
	$is_dummy = 1;
    } else {
	# do this only if object is not loaded yet
	$obj = $schema->{make_object}->($class);
	$self->welcome($obj, $id);
	$target = $obj;
    }

    _row_to_object($self, $target, $id, $class, $row, @parts);
    CORE::bless $target, "dummy" if $is_dummy;
    return $obj;
  }
{
package dummy;
sub AUTOLOAD { }
}

sub _row_to_object
  {
    my ($self, $obj, $id, $class, $row) = @_;
	my $context = { storage => $self, id => $id, layout1 => $self->{layout1} };
	$self->{schema}->classdef($class)->get_importer($context)->($obj, $row, $context);
    # XXX - not documented, probably badly named.
    if (my $x=$obj->can("T2_import")) {
	$x->($obj);
    }
	return $obj;
}

sub _fetch_object_state
{
    my ($self, $id, $class) = @_;

	my $sth = $self->{LOAD_STH}{$class->{name}} ||=
	  $self->prepare($self->{engine}->get_instance_select($class));

    if ( $Tangram::TRACE ) {
	print $Tangram::TRACE
	    (__PACKAGE__.": fetching $class->{name}($id) with: >-\n"
	     .$self->{engine}->get_instance_select($class)
	     ."\n...\n");
    }

    my $row;
    $sth->execute($self->{export_id}->($id)) &&
	($row = $sth->fetchrow_arrayref())
	    or croak "could not find $class->{name} object "
		.$self->{export_id}->($id)." (oid $id) in storage";

    my $state = [ @$row ] if $row;
    $sth->finish();

    return $state;
}

sub get_polymorphic_select
  {
	my ($self, $class) = @_;
	if ( $class ) {
	    return $self->{engine}->get_polymorphic_select
		($self->{schema}->classdef($class), $self);
	}
	else {
	    return Tangram::Relational::PolySelectTemplate
		->new([],[],[],[],{});
	}
  }

sub select {
  croak "valid only in list context" unless wantarray;
  
  my ($self, $target, @args) = @_;
  
  unless (ref($target) eq 'ARRAY') {
	my $cursor = Tangram::Cursor->new($self, $target, $self->{db});
	return $cursor->select(@args);
  }
  
  # XXX - not tested by test suite
  my ($first, @others) = @$target;
  
  my @cache = map { $self->select( $_, @args ) } @others;
  
  my $cursor = Tangram::Cursor->new($self, $first, $self->{db});
  $cursor->retrieve( map { $_->{_IID_}, $_->{_TYPE_ } } @others );
  
  my $obj = $cursor->select( @args );
  my @results;
  
  while ($obj) {
	my @tuple = $obj;
	my @residue = $cursor->residue;
	
	while (my $id = shift @residue) {
	  push @tuple, $self->load($self->combine_ids($id, shift @residue));
	}
	
	push @results, \@tuple;
	$obj = $cursor->next;
  }
  
  return @results;
}

# XXX - not tested by test suite
sub cursor_object
  {
    my ($self, $class) = @_;
    $self->{IMPLICIT}{$class} ||= Tangram::Expr::RDBObject->new($self, $class)
}

sub query_objects
{
    my ($self, @classes) = @_;
    map { Tangram::Expr::QueryObject->new(Tangram::Expr::RDBObject->new($self, $_)) } @classes;
}

sub remote
{
    my ($self, @classes) = @_;
    wantarray ? $self->query_objects(@classes) : (&remote)[0]
}

sub expr
  {
    my $self = shift;
    return shift->expr( @_ );
  }

# XXX - not tested by test suite
sub object
{
    carp "cannot be called in list context; use objects instead" if wantarray;
    my $self = shift;
    my ($obj) = $self->query_objects(@_);
    $obj;
}

sub aggregate
{
    my $self = shift;
    my $function = shift;
    my $expr = shift;
    my $filter = shift;
    do {
	$filter = $expr;
	$expr = Tangram::Expr->new
	    (Tangram::Type::Number->instance,
	     '*', $filter->objects);
    } if $expr->isa("Tangram::Expr::Filter");

    my @data = $self->select(undef,
			     ($filter ? (filter => $filter) : ()),
			      retrieve => [ map { $_->$function() }
						(ref ($expr) eq "ARRAY"
						 ? @$expr : $expr) ],
			    );

    return $data[0]
}

sub count
{
    my $self = shift;
    $self->aggregate("count", @_);
}

sub sum
{
    my $self = shift;
    $self->aggregate("sum", @_);
}

sub id
{
    my $self = shift;
    return map { $self->{get_id}->($_) } @_ if wantarray;
    $self->{get_id}->(shift());
}

sub id_maybe_insert
{
    my $self = shift;
    return map { scalar($self->id_maybe_insert($_)) }
	@_ if wantarray;

    my $object = shift;
    if ( my $id = $self->{get_id}->($object) ) {
	return $id;
    } else {
	my $class = ref $object;
	if ( eval { $self->class_id($class) } ) {
	    print $Tangram::TRACE "id_maybe_insert: inserting $object\n"
		if $Tangram::TRACE;
	    return $self->insert($object);
	}
    }
}

sub disconnect
{
    my ($self) = @_;

    return unless defined $self->{db};

    $self->{db}->{RaiseError} = 0;

    unless ($self->{no_tx} or $self->{db}->{AutoCommit})
    {
	$self->{db}->rollback;
    }

    if ($self->{db_owned}) {
	print $Tangram::TRACE __PACKAGE__.": disconnecting\n"
	    if $Tangram::TRACE;
	$self->{db}->disconnect;
    } else {
	print $Tangram::TRACE __PACKAGE__.": disconnecting (no handle)\n"
	    if $Tangram::TRACE;
    }

    %$self = ();
}

sub _kind_class_ids
{
    my ($self, $class) = @_;

    my $schema = $self->{schema};
    my $classes = $self->{schema}{classes};
    my $class2id = $self->{class2id};

    my @ids;

    push @ids, $self->class_id($class) unless $classes->{$class}{abstract};

    $schema->for_each_spec($class,
			   sub { my $spec = shift; push @ids, $class2id->{$spec} unless $classes->{$spec}{abstract} } );

    return @ids;
}

# XXX - not tested by test suite
sub is_persistent
{
    my ($self, $obj) = @_;
    return $self->{schema}->is_persistent($obj) && $self->id($obj);
}

sub prefetch
{
	my ($self, $remote, $member, $filter) = @_;

	my $class;

	if (ref $remote)
	{
		$class = $remote->class();
	}
	else
	{
		$class = $remote;
		$remote = $self->remote($class);
	}

	my $schema = $self->{schema};

	my $member_class = $schema->find_member_class($class, $member)
		or die "no member '$member' in class '$class'";

	my $classdef = $schema->{classes}{$member_class};
	my $type = $classdef->{member_type}{$member};
	my $memdef = $classdef->{MEMDEFS}{$member};

	$type->prefetch($self, $memdef, $remote, $class, $member, $filter);
}

sub connect
{
    my ($pkg, $schema, $cs, $user, $pw, $opts) = @_;

    my $self = $pkg->new;

	$opts ||= {};

    if (exists $opts->{no_tx}) {
	$self->{no_tx} = $opts->{no_tx};
    } elsif ( $self->can("has_tx") ) {
	$self->{no_tx} = !($self->has_tx);
    }

    @$self{ -cs, -user, -pw } = ($cs, $user, $pw);

    $self->{driver} = $opts->{driver} || Tangram::Relational->detect($cs);

    my $db = $opts->{dbh};
    unless ( $db ) {
	$db = $self->open_connection;
	$self->{db_owned} = 1;
    }

    unless ( exists $self->{no_tx} ) {
	eval { $db->{AutoCommit} = 0 };
	$self->{no_tx} = $db->{AutoCommit};
    }

    if (exists $opts->{no_subselects}) {
	$self->{no_subselects} = $opts->{no_subselects};
    } elsif ( $self->can("has_subselects") ) {
	$self->{no_subselects} = ! $self->has_subselects;
    } else {
	local($SIG{__WARN__})=sub{};
	eval {
	    my $sth = $db->prepare("select * from (select 1+1"
				   .$self->from_dual.") test");
	    $sth->execute() or die;
	};
	if ($@ or $DBI::errstr) {
	    $self->{no_subselects} = 1;
	}
    }

    $self->{db} = $db;

    $self->{cid_size} = $schema->{sql}{cid_size};

    $self->_open($schema);

    $self->{engine} = Tangram::Relational::Engine->new
	( $schema,
	  layout1 => $self->{layout1},
	  driver => $self->{driver}
	);

    return $self;
}

sub connection { shift->{db} }

sub sql_do
{
    my ($self, $sql, @placeholders) = @_;

    print $Tangram::TRACE ">-\n$sql\n"
	.(@placeholders?"-- with: \n    /* (@placeholders) */\n":"")."...\n"
	    if $Tangram::TRACE;

    my $rows_affected = $self->{db}->do($sql, {}, @placeholders);
    return defined($rows_affected) ? $rows_affected
	  : croak $DBI::errstr;
}

# XXX - not tested by test suite
sub sql_selectall_arrayref
{
    my ($self, $sql, $dbh) = @_;
    print $Tangram::TRACE ">-\n$sql\n...\n" if $Tangram::TRACE;
	($dbh || $self->{db})->selectall_arrayref($sql);
}

sub sql_prepare
{
    my ($self, $sql, $connection) = @_;
    confess unless $connection;
    print $Tangram::TRACE ">-\n$sql\n...\n" if $Tangram::TRACE;
    my $sth = $connection->prepare($sql);
    die "prepare failed; $DBI::errstr - SQL >-\n$sql\n...\n" unless $sth;
    return $sth;
}

sub sql_cursor
{
    my ($self, $sql, $connection) = @_;

    confess unless $connection;

    print $Tangram::TRACE ">-\n$sql\n...\n" if $Tangram::TRACE;

    my $sth = $connection->prepare($sql) or die;
    $sth->execute() or confess;

    Tangram::Storage::Statement->new( statement => $sth, storage => $self,
				     connection => $connection );
}

sub unload
  {
    my $self = shift;
    my $objects = $self->{objects};

    if (@_) {
      for my $item (@_) {
	if (ref $item) {
	  $self->goodbye($item, $self->{get_id}->($item));
	} else {
	  $self->goodbye($objects->{$item}, $item);
	}
      }
    } else {
      for my $id (keys %$objects) {
	$self->goodbye($objects->{$id}, $id);
      }
    }
  }

# XXX - not tested by test suite
sub unload_all {
    my $self = shift;
    my $send_method = shift;

    if ( $send_method ) {
	my $objects = $self->{objects};
	if ($objects and ref $objects eq "HASH") {
	    while (my $oid = each %$objects) {
		if (defined $objects->{$oid}) {
		    if (my $x = UNIVERSAL::can($objects->{$oid},
					       $send_method)) {
			$x->($objects->{$oid});
		    }
		    $self->goodbye($objects->{$oid}, $oid);
		}
	    }
	}
	while (my $oid = each %$objects) {
	    next unless defined $objects->{$oid};
	    warn __PACKAGE__."::unload_all: cached ref to oid $oid "
		."is not weak"
		    if (!$Tangram::no_weakrefs and
			!Scalar::Util::isweak($objects->{$oid}));
	    my $x;
	    warn __PACKAGE__."::unload_all: refcnt of oid $oid is $x"
		if (!$Tangram::no_weakrefs and
		    $x = Set::Object::rc($objects->{$oid}));
	}
    }
    $self->{ids} = {};
    $self->{objects} = {};
    $self->{PREFETCH} = {};
    $self->{scratch} = {};
    print $Tangram::TRACE __PACKAGE__.": cache dumped\n"
	if $Tangram::TRACE && ($Tangram::DEBUG_LEVEL > 0) ;

    #$self->SUPER::unload_all();
}

# XXX - not reached (?)
sub from_dual { "" }

# XXX - not tested by test suite
sub ping {
    my $self = shift;

    $self->{db}->ping or die "ping failed; DB down?  $DBI::errstr"

    #my $answer =
	##$self->sql_selectall_arrayref("select 1+1".$self->from_dual);
#
    #if ( $answer ) {
	#if ( $answer->[0][0] == 2 ) {
	    #return 1;
	#} else {
	    #die "Database can't add";
	#}
    #} else {
	## will probably never get here...
	#return undef;
    #}
}

# XXX - not tested by test suite
sub recycle {
    my $self = shift;
    my $send_method = shift;

    $self->unload_all($send_method);
    $self->tx_rollback(-1);
    $self->ping or die "DB not connected on recycle";
    print $Tangram::TRACE "Tangram: connection recycled\n"
	if $Tangram::TRACE;
}

# XXX - wtf?
sub clear_stats {
    my $self = shift;
    $self->{stats} = undef;
}

# XXX - wtf?
sub add_stat {
    my $self = shift;
    my $stat = shift;
    $self->{stats}{$stat}++;
}

# checks to see if an object ID ->isa the correct type, based on its
# classtype
sub oid_isa
    {
	my $self = shift;
	my $oid = shift;
	croak(pretty($oid)." is not an Object ID")
	    unless defined ($oid) and $oid + 0 eq $oid;

	my $class = shift;
	my $classes = $self->{schema}->{classes};
	carp "Class ".pretty($class)." is not defined in the schema",
	    return undef
		unless defined($class) and exists $classes->{$class};

	my @bases = $self->{id2class}->{ ($self->split_id($oid))[1] + 0 };

	my $seen = Set::Object->new();
	while (my $base = shift @bases) {
	    $seen->insert($classes->{$base}) or next;
	    return 1 if $base eq $class;
	    push @bases, @{ $classes->{$base}->{bases} }
		if exists $classes->{$base}->{bases};
	}

	return undef;
    }

*reset = \&unload; # deprecated, use unload() instead

sub DESTROY
{
    my $self = shift;
    if ($self->{db}) {
	if ( $self->{db_owned} ) {
	    print $Tangram::TRACE __PACKAGE__.": destroyed; disconnecting\n"
		if $Tangram::TRACE;
	    $self->{db}->disconnect;
	} else {
	    print $Tangram::TRACE __PACKAGE__.": destroyed; leaving handle open\n"
		if $Tangram::TRACE;
	}
    } else {
	print $Tangram::TRACE __PACKAGE__.": destroyed; no active handle\n"
	    if $Tangram::TRACE;
    }
}

1;
