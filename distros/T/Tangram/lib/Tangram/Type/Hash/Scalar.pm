

use strict;

package Tangram::Type::Hash::Scalar;

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::Abstract::Hash );
use Tangram::Type::Abstract::Hash;

use Tangram::Expr::FlatHash;

$Tangram::Schema::TYPES{flat_hash} = Tangram::Type::Hash::Scalar->new;

sub reschema
{
    my ($self, $members, $class, $schema) = @_;
    
    for my $field (keys %$members)
    {
		my $def = $members->{$field};
		my $refdef = ref($def);

		unless ($refdef)
		{
			# not a reference: field => field
			$def = $members->{$field} = { type => 'string',
						      key_type => 'string'
						    };
		}

		$def->{table} ||= $schema->{normalize}->($class . "_$field", 'tablename');
		$def->{type} ||= 'string';
		$def->{string_type} = $def->{type} eq 'string';
		$def->{sql} ||= $def->{string_type} ? 'VARCHAR(255)' : uc($def->{type});
		$def->{key_type} ||= 'string';
		$def->{key_string_type} = $def->{key_type} eq 'string';
		$def->{key_sql} ||= $def->{key_string_type} ? 'VARCHAR(255)' : uc($def->{key_type});
    }

    return keys %$members;
}

sub demand
{
	my ($self, $def, $storage, $obj, $member, $class) = @_;

	print $Tangram::TRACE "loading $member\n" if $Tangram::TRACE;
   
	my %coll;
	my $id = $storage->export_object($obj);

	if (my $prefetch = $storage->{PREFETCH}{$class}{$member}{$id})
	{
		%coll = %$prefetch;
	}
	else
	{
		my $sth = $storage->sql_prepare(
            "SELECT\n    a.k,\n    a.v\nFROM\n    $def->{table} a\nWHERE\n    coll = $id", $storage->{db});

		$sth->execute();
		
		for my $row (@{ $sth->fetchall_arrayref() })
		{
			my ($k, $v) = @$row;
			$coll{$k} = $v;
		}
	}

	$self->set_load_state($storage, $obj, $member, { %coll } );

	return \%coll;
}

sub get_exporter
  {
	my ($self, $context) = @_;

	return sub {
	  my ($obj, $context) = @_;
	  $self->defered_save($context->{storage}, $obj, $self->{name}, $self);
	  ();
	}
  }

sub hash_diff {
  my ($first,$second,$differ) = @_;
  my (@common,@changed,@only_in_first,@only_in_second);
  foreach (keys %$first) {
    if (exists $second->{$_}) {
      if ($differ->($first->{$_},$second->{$_})) {
	push @changed, $_;
      }
      else {
	push @common, $_;
      }
    }
    else {
      push @only_in_first, $_;
    }
  }

  foreach (keys %$second) {
    push @only_in_second, $_ unless exists $first->{$_};
  }

  (\@common,\@changed,\@only_in_first,\@only_in_second);
}

sub defered_save
  {
	use integer;
	
	my ($self, $storage, $obj, $field, $def) = @_;
	
	return if tied $obj->{$field}; # collection has not been loaded, thus not modified

	my $coll_id = $storage->id($obj);
	
	my ($ne, $modify, $add, $remove) =
	  $self->get_save_closures($storage, $obj, $def, $coll_id);
	
	my $new_state = $obj->{$field} || {};
	my $old_state = $self->get_load_state($storage, $obj, $field) || {};
	
	my ($common, $changed, $to_add, $to_remove) = hash_diff($new_state, $old_state, $ne);
	
	for my $key (@$changed)
	  {
		$modify->($key, $new_state->{$key}, $old_state->{$key});
	  }
	
	for my $key (@$to_add)
	  {
		$add->($key, $new_state->{$key});
	  }
	
	for my $key (@$to_remove)
	  {
		$remove->($key);
	  }
	
	$self->set_load_state($storage, $obj, $field, { %$new_state } );	
	
	$storage->tx_on_rollback(
							 sub { $self->set_load_state($storage, $obj, $field, $old_state) } );
  }

my $no_ref = 'illegal reference in flat hash';

sub get_save_closures
{
	my ($self, $storage, $obj, $def, $id) = @_;

	my $table = $def->{table};

	my ($ne, $quote, $key_quote);

	if ($def->{string_type})
	{
		$ne = sub { my ($a, $b) = @_; defined($a) != defined($b) || $a ne $b };
		$quote = sub { $storage->{db}->quote(shift()) };
	}
	else
	{
	    # XXX - not reached by test suite
		$ne = sub { my ($a, $b) = @_; defined($a) != defined($b) || $a != $b };
		$quote = sub { shift() };
	}

	if ($def->{key_string_type})
	{
		$key_quote = sub { $storage->{db}->quote(shift()) };
	}
	else {
		$key_quote = sub { shift() };
	}
	
	my $eid = $storage->{export_id}->($id);

	my $modify = sub
	{
		my ($k, $v) = @_;
		die $no_ref if (ref($v) or ref($k));
		$v = $quote->($v);
		$k = $key_quote->($k);
		$storage->sql_do("UPDATE\n    $table\nSET\n    v = $v\nWHERE\n    coll = $eid    AND\n    k = $k");
	};

	my $add = sub
	{
		my ($k, $v) = @_;
		die $no_ref if (ref($v) or ref($k));
		$v = $quote->($v);
		$k = $key_quote->($k);
		$storage->sql_do("INSERT INTO\n    $table (coll, k, v)\n    VALUES ($eid, $k, $v)");
	};

	my $remove = sub
	{
		my ($k) = @_;
		die $no_ref if ref($k);
		$k = $key_quote->($k);
		$storage->sql_do("DELETE FROM\n    $table\nWHERE\n    coll = $eid    AND\n    k = $k");
	};

	return ($ne, $modify, $add, $remove);
}

sub erase
{
	my ($self, $storage, $obj, $members, $coll_id) = @_;

	$coll_id = $storage->{export_id}->($coll_id);

	foreach my $def (values %$members)
	{
		$storage->sql_do("DELETE FROM\n    $def->{table}\nWHERE\n    coll = $coll_id");
	}
}

sub coldefs
{
    my ($self, $cols, $members, $schema, $class, $tables) = @_;

    foreach my $member (values %$members)
    {
		$tables->{ $member->{table} }{COLS} =
		{
		 coll => $schema->{sql}{id},
		 k => $member->{key_sql},
		 v => $member->{sql}
		};
    }
}

# XXX - not reached by test suite
sub query_expr
{
	my ($self, $obj, $members, $tid) = @_;
	map { Tangram::Expr::FlatHash->new($obj, $_); } values %$members;
}

sub remote_expr
{
	my ($self, $obj, $tid) = @_;
	Tangram::Expr::FlatHash->new($obj, $self);
}

sub prefetch
{
	my ($self, $storage, $def, $coll, $class, $member, $filter) = @_;

	my $prefetch = $storage->{PREFETCH}{$class}{$member} ||= {};

	my $restrict = $filter ? ",\n    " . $filter->from() . "\nWHERE\n    " . $filter->where() : '';

	my $sth = $storage->sql_prepare(
        "SELECT\n    coll,\n    k,\n    v\nFROM\n    $def->{table}\n$restrict", $storage->{db});
	$sth->execute();
		
	for my $row (@{ $sth->fetchall_arrayref() })
	{
		my ($id, $k, $v) = @$row;
		$prefetch->{$id}{$k} = $v;
	}

	return $prefetch;
}

1;
