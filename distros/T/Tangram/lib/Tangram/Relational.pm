

package Tangram::Relational;

use Tangram::Relational::Engine;

use Carp qw(cluck);
use strict;

sub new { bless { }, shift }

# XXX - not tested by test suite
sub connect
  {
	my ($pkg, $schema, $cs, $user, $pw, $opt) = @_;
	$opt ||= {};
	$opt->{driver} = $pkg->new();
	my $storage
	    = Tangram::Storage->connect( $schema, $cs, $user, $pw, $opt );
  }

sub schema
  {
	my $self = shift;
	return Tangram::Schema->new( @_ );
  }

sub _with_handle {
    my $self = shift;
  my $method = shift;
  my $schema = shift;

  if (@_) {
	my $arg = shift;

	if (ref $arg) {
	  Tangram::Relational::Engine->new($schema, driver => $self)->$method($arg)
	} else {
	    # try to automatically select the correct driver
	    if ( !ref $self and $self eq __PACKAGE__ ) {
		$self = $self->detect($arg);
	    }
	  my $dbh = DBI->connect($arg, @_);
	  eval { Tangram::Relational::Engine->new($schema, driver => $self)->$method($dbh) };
	  $dbh->disconnect();
  
	  die $@ if $@;
	}
  } else {
	Tangram::Relational::Engine->new($schema, driver => $self)->$method();
  }
}

# XXX - not tested by test suite
sub detect
    {
	my $self = shift;
	my $dbi_cs = shift;
	$dbi_cs =~ m{dbi:(\w+):} or return (ref $self || $self);
	my $pkg = "Tangram::Driver::$1";
	eval "use $pkg";
	if ( !$@ ) {
	    print $Tangram::TRACE
		__PACKAGE__.": using the $pkg driver for $dbi_cs\n"
		    if $Tangram::TRACE;
	    return $pkg;
	} else {
	    return (ref $self || $self);
	}
    }

# XXX - not tested by test suite
sub name
  {
      my $self = shift;
      my $pkg = (ref $self || $self);
      if ( $pkg eq __PACKAGE__ ) {
	  return "vanilla";
      } elsif ( $pkg =~ m{::Driver::(.*)} ) {
	  return $1;
      } else {
	  return $pkg;
      }
  }

sub deploy
  {
      my $self = (shift) || __PACKAGE__;
      $self->_with_handle('deploy', @_);
  }

sub retreat
  {
      my $self = (shift) || __PACKAGE__;
      $self->_with_handle('retreat', @_);
  }

# handle virtual SQL types.  Isn't SQL silly?
our ($sql_t_qr, @sql_t);
BEGIN {
    @sql_t =
	(
	 'VARCHAR\s*(?:\(\s*\d+\s*\))?'     => 'varchar',       # variable width
	 'CHAR\s*(?:\(\s*\d+\s*\))?'        => 'char',          # fixed width
	 'BLOB'        => 'blob',          # generic, large data store
	 'DATE|TIME|DATETIME|TIMESTAMP'
	               => 'date',
	 'BOOL'        => 'bool',
	 'INT(?:EGER)?|SHORTINT|TINYINT|LONGINT|MEDIUMINT|SMALLINT'
                       => 'integer',
	 'DECIMAL|NUMERIC|FLOAT|REAL|DOUBLE|SINGLE|EXTENDED'
	               => 'number',
	 'ENUM|SET'    => 'special',
	 '\w+\s*(?:\(\s*\d+\s*\))?' => 'general',
	);

    # compile the types to a single regexp.
    {
	my $c = 0;
	$sql_t_qr = "^(?:".join("|", map { "($_)" } grep {(++$c)&1}
				@sql_t).")\\s*(?i:(?i:NOT\\s+)?NULL)?\\s*\$";

	$sql_t_qr = qr/$sql_t_qr/i;
    }
}

sub type {
    my $self = shift if ref $_[0] or UNIVERSAL::isa($_[0], __PACKAGE__);
    $self ||= __PACKAGE__;
    my $type = shift;

    my @x = ($type =~ m{$sql_t_qr});

    my $c = @x ? 1 : @sql_t;
    $c+=2 while not defined shift @x and @x;

    my $func = $sql_t[$c] or do {
	cluck "type '$type' didn't match $sql_t_qr";
	return $type;
    };
    my $new_type = $self->$func($type);
    if ( $Tangram::TRACE and $Tangram::DEBUG_LEVEL > 1 ) {
	print $Tangram::TRACE
	    __PACKAGE__.": re-wrote $type to $new_type via "
		.ref($self)."::$func\n";
    }
    return $new_type;
}

# convert a value from an RDBMS format => an internal format
sub from_dbms {
    my $self = ( UNIVERSAL::isa($_[0], __PACKAGE__)
		 ? shift
		 : __PACKAGE__);
    my $type = shift;
    my $value = shift;
    #print STDERR "Relational: converting (TO) $type $value\n";

    my $method = "from_$type";
    if ( $self->can($method) ) {
	return $self->$method($value);
    } else {
	return $value;
    }
}

# convert a value from an internal format => an RDBMS format
sub to_dbms {
    my $self = ( UNIVERSAL::isa($_[0], __PACKAGE__)
		 ? shift
		 : __PACKAGE__);
    my $type = shift;
    my $value = shift;
    #print STDERR "Relational: converting (TO) $type $value\n";

    my $method = "to_$type";
    if ( $self->can($method) ) {
	return $self->$method($value);
    } else {
	return $value;
    }
}

# generic / fallback date handler.  Use Date::Manip to parse
# `anything' and return a full ISO date
sub from_date {
    my $self = shift;
    my $value = shift;
    require 'Date/Manip.pm';
    return Date::Manip::UnixDate($value, '%Y-%m-%dT%H:%M:%S');
}

# an alternate ISO-8601 form that databases are more likely to grok
sub to_date {
    my $self = shift;
    my $value = shift;
    require 'Date/Manip.pm';
    return Date::Manip::UnixDate($value, '%Y-%m-%d %H:%M:%S');
}

# generic / fallback date handler.  Use Date::Manip to parse
# `anything' and return a full ISO date
# XXX - not tested by test suite
sub from_date_hires {
    my $self = shift;
    my $value = shift;
    $value =~ s{ }{T};
    return $value;
}

# this one is a lot more restrictive.  Assume that no DBs understand T
# in a date
# XXX - not tested by test suite
sub to_date_hires {
    my $self = shift;
    my $value = shift;
    $value =~ s{T}{ };
    return $value;
}

use Carp;

# return a query to get a sequence value
# XXX - not tested by test suite
sub sequence_sql {
    my $self = shift;
    my $sequence_name = shift or confess "no sequence name?";
    return "SELECT $sequence_name.nextval";
}

# XXX - not tested by test suite
sub mk_sequence_sql {
    my $self = shift;
    my $sequence_name = shift;
    return "CREATE SEQUENCE $sequence_name";
}

# XXX - not tested by test suite
sub drop_sequence_sql {
    my $self = shift;
    my $sequence_name = shift;
    return "DROP SEQUENCE $sequence_name";
}

# default mappings are no-ops
BEGIN {
    no strict 'refs';
    my $c = 0;
    *{$_} = sub { shift if UNIVERSAL::isa($_[0], __PACKAGE__); shift; }
	foreach grep {($c++)&1} @sql_t;
}

1;
