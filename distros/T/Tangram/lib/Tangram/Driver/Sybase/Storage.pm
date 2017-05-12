
package Tangram::Driver::Sybase::Storage;

use strict;
use Tangram::Storage;
use vars qw(@ISA);
 @ISA = qw( Tangram::Storage );

use Tangram::Driver::Sybase::Expr::Date;
use Tangram::Driver::Sybase::Statement;

sub prepare
  {
	my ($self, $sql) = @_;
	#print "prepare: $sql\n";
	bless [ $self, $sql ], 'Tangram::Driver::Sybase::Statement';
  }

*prepare_update = \*prepare;
*prepare_insert = \*prepare;

sub prepare_select
  {
	my ($self, $sql) = @_;
	return $self->prepare($sql);
  }

sub make_1st_id_in_tx
  {
    my ($self) = @_;
	my $table = $self->{schema}{control};
	$self->sql_do("UPDATE $table SET mark = mark + 1");
	return $self->{db}->selectall_arrayref("SELECT mark from $table")->[0][0];
  }

sub update_id_in_tx
  {
	my ($self, $mark) = @_;
	$self->sql_do("UPDATE $self->{schema}{control} SET mark = $mark");
  }

my %improved =
  (
   'Tangram::Type/TimeAndDate' => 'Tangram::Driver::Sybase::Expr::Date',
   'Tangram::Type/Date' => 'Tangram::Driver::Sybase::Expr::Date',
  );

sub expr
  {
    my $self = shift;
    my $type = shift;
    my ($expr, @remotes) = @_;
    
    # is $type related to dates? if not, return default
    my $improved = $improved{ref($type)} or return $type->expr(@_);
    
    # $type is a Date; return a DateExpr
    return $improved->new($type, $expr, @remotes);
}

1;
