package Tangram::Driver::mysql::Storage;

use strict;
use Tangram::Driver::mysql::Expr::Date;
use Tangram::Driver::mysql::Expr::Integer;

use Tangram::Storage;
use vars qw(@ISA);
 @ISA = qw( Tangram::Storage );

sub make_id
  {
    my ($storage, $class_id) = @_;

	if ($storage->{layout1}) {
	  my $table = $storage->{schema}{class_table};
	  $storage->sql_do("UPDATE $table SET lastObjectId = LAST_INSERT_ID(lastObjectId + 1) WHERE classId = $class_id");
	} else {
	  my $table = $storage->{schema}{control};
	  $storage->sql_do("UPDATE $table SET mark = LAST_INSERT_ID(mark + 1)");
	}

    return sprintf "%d%0$storage->{cid_size}d", $storage->sql_selectall_arrayref("SELECT LAST_INSERT_ID()")->[0][0], $class_id;
  }

sub tx_start
  {
    my $storage = shift;
    unless (@{ $storage->{tx} }) {
	if ( $storage->{no_tx} ) {
	    $storage->sql_do (q{SELECT GET_LOCK("tx", 10)} ); #})  #cperl-mode--
	}
    }
    $storage->SUPER::tx_start(@_);
  }

sub tx_commit
  {
    my $storage = shift;
    $storage->SUPER::tx_commit(@_);
    unless (@{ $storage->{tx} }) {
	if ( $storage->{no_tx} ) {
	    $storage->sql_do(q/SELECT RELEASE_LOCK("tx")/)
	}
    }
  }

sub tx_rollback
  {
    my $storage = shift;
    if ( $storage->{no_tx} ) {
	$storage->sql_do(q/SELECT RELEASE_LOCK("tx")/);
    }
    $storage->SUPER::tx_rollback(@_);
  }

my %improved_date =
  (
   'Tangram::Type::TimeAndDate' => 'Tangram::Driver::mysql::Expr::Date',
   'Tangram::Type::Date' => 'Tangram::Driver::mysql::Expr::Date',
  );

sub expr
  {
    my $self = shift;
    my $type = shift;
    my ($expr, @remotes) = @_;

	return Tangram::Driver::mysql::Expr::Integer->new($type, $expr, @remotes)
	  if ref($type) eq 'Tangram::Type::Integer';

    my $improved_date = $improved_date{ref($type)};
    return $improved_date->new($type, $expr, @remotes)
	  if $improved_date;

	return $type->expr(@_);
  }

1;
