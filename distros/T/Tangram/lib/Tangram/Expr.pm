package Tangram::Expr;

use strict;
use Tangram::Expr::Table;
use Tangram::Expr::CursorObject;
use Tangram::Expr::RDBObject;
use Tangram::Expr::Filter;
use Tangram::Expr;
use Tangram::Expr::QueryObject;
use Tangram::Expr::Select;

use Set::Object qw(blessed);
use Carp;

# WARNING - many 'core' functions are redefined in this namespace.

sub new
{
	my ($pkg, $type, $expr, @objects) = @_;
	return bless { expr => $expr, type => $type,
				   objects => Set::Object->new(@objects),
				   storage => $objects[0]->{storage} }, $pkg;
}

sub expr
{
	return shift->{expr};
}

# XXX - not tested by test suite
sub storage
{
	return ((shift->{objects}->members)[0] or confess 'no storage')->storage;
}

# XXX - not tested by test suite
sub type
{
	return shift->{type};
}

sub objects
{
	return shift->{objects}->members;
}

sub eq
{
	my ($self, $arg) = @_;
	return $self->binop('=', $arg);
}

sub ne
{
	my ($self, $arg) = @_;
	return $self->binop('<>', $arg);
}

# BEGIN ks.perl@kurtstephens.com 2002/06/25
# XXX - not tested by test suite
sub lt
{
	my ($self, $arg, $swap) = @_;
	return $self->binop('<', $arg, undef, $swap);
}

sub le
{
	my ($self, $arg, $swap) = @_;
	return $self->binop('<=', $arg, undef, $swap);
}

sub gt
{
	my ($self, $arg, $swap) = @_;
	return $self->binop('>', $arg, undef, $swap);
}

# XXX - not tested by test suite
sub ge
{
	my ($self, $arg, $swap) = @_;
	return $self->binop('>=', $arg, undef, $swap);
}

# XXX - not tested by test suite
sub add
{
    my ($self, $arg) = @_;
    $self->binop('+', $arg, 90);
}


# XXX - not tested by test suite
sub subt
{
    my ($self, $arg, $swap) = @_;
    $self->binop('-', $arg, 90, $swap);
}


# XXX - not tested by test suite
sub mul
{
    my ($self, $arg) = @_;
    $self->binop('*', $arg, 95);
}


# XXX - not tested by test suite
sub div
{
    my ($self, $arg, $swap) = @_;
    $self->binop('/', $arg, 95, $swap);
}


# XXX - not tested by test suite
sub cos
{
    my ($self) = @_;
    $self->unaop('COS', 100);
}


# XXX - not tested by test suite
sub sin
{
    my ($self) = @_;
    $self->unaop('SIN', 100);
}

# XXX - not tested by test suite
sub acos
{
    my ($self) = @_;
    $self->unaop('ACOS', 100);
}

# XXX - not tested by test suite
sub not
{
    my ($self) = @_;
    $self->unaop('NOT', 100);
}

# XXX - not tested by test suite
sub unaop
{
    my ($self, $op, $tight) = @_;
    
    my @objects = $self->objects;
    my $objects = Set::Object->new(@objects);
    my $storage = $self->{storage};
    
    return new Tangram::Expr::Filter
	(expr => "$op($self->{expr})",
	 tight => $tight || 100,
	 objects => $objects );
}


sub binop
{
	my ($self, $op, $arg, $tight, $swap) = @_;

	my @objects = $self->objects;
	my $objects = Set::Object->new(@objects);
	my $storage = $self->{storage};

	if (defined $arg)
	{
		if (my $type = ref($arg))
		{
			if ($arg->isa('Tangram::Expr'))
			{
				$objects->insert($arg->objects);
				$arg = $arg->expr;
			}
   
			elsif ($arg->isa('Tangram::Expr::QueryObject'))
			{
				$objects->insert($arg->object);
				$arg = $arg->{id}->expr;
			}
   
			elsif (exists $storage->{schema}{classes}{$type})
			{
				$arg = $storage->export_object($arg) or Carp::confess "$arg is not persistent";
			}

			else
			{
			    # XXX - not reached by test suite
			    $arg = $self->{type}->literal($arg, $storage);
			}
		}
		else
		{
			$arg = $self->{type}->literal($arg, $storage);
		}
	}
	else
	{
                # XXX - not wholly tested by test suite
		$op = $op eq '=' ? 'IS' : $op eq '<>' ? 'IS NOT' : Carp::confess("unknown op $op");
		$arg = 'NULL';
	}

	my ($l, $r) = $swap ? ($arg, $self->{expr}) : ($self->{expr}, $arg);
	$tight ||= 100;

	return new Tangram::Expr::Filter(expr => "$l $op $r", tight => $tight,
							   objects => $objects );
}
# END ks.perl@kurtstephens.com 2002/06/25


sub like
{
	my ($self, $val) = @_;
	$val =~ s{'}{''}g;
	return new Tangram::Expr::Filter(expr => "$self->{expr} like '$val'", tight => 100,
				   objects => Set::Object->new($self->objects) );
}


# XXX - not tested by test suite - MySQL specific
sub regexp_like
{
	my ($self, $val) = @_;
	$val =~ s{'}{''}g;
	return new Tangram::Expr::Filter(expr => "regexp_like($self->{expr}, '$val')", tight => 0,
				   objects => Set::Object->new($self->objects) );
}

sub match
{
       my ($self, $oper, $val) = @_;
       return Tangram::Expr::Filter->new(expr => "$self->{expr} $oper '$val'", tight => 100,
                                  objects => Set::Object->new($self->objects) );
}

sub is_null
{
       my ($self) = @_;
       return Tangram::Expr::Filter->new(expr => "$self->{expr} IS NULL", tight => 100,
                                  objects => Set::Object->new($self->objects) );
}

sub count
{
	my ($self, $val) = @_;
	$self->{storage}
		->expr(Tangram::Type::Integer->instance, "COUNT($self->{expr})",
				$self->objects );
}

# XXX - not tested by test suite
sub as_string
{
	my $self = shift;
	return ref($self) . "($self->{expr})";
}

sub in
{
	my $self = shift;

	my $storage = $self->{storage};

	my @items;
	while ( defined(my $item = shift) ) {
	    if ( ref $item eq "ARRAY" ) {
		push @items, @$item;
	    } elsif ( UNIVERSAL::isa($item, "Set::Object") ) {
		push @items, $item->members;
	    } else {
		push @items, $item;
	    }
	}

	my $expr;
	if ( @items ) {
	    $expr = ("$self->{expr} IN ("
		     . join(', ',
			    # FIXME - what about table aliases?  Hmm...
			    map {( blessed($_)
				   ? $storage->export_object($_)
				   : $storage->{db}->quote($_) )}
			    @items )
		     . ')');
	} else {
	    # hey, you never know :)
	    $expr = ("$self->{expr} IS NULL");
	}

	Tangram::Expr::Filter->new(
			     expr => $expr,
			     tight => 100,
			     objects => $self->{objects},
			    );

}

# XXX - not tested by test suite
sub log {
    my $self = shift;
    my $base = shift || exp(1);

    my $expr = $self->expr(); # the SQL string for this Expr
    $self->{type}->expr("log($base, $expr)", $self->objects);
}

sub DESTROY { }

use vars qw( $AUTOLOAD );

sub AUTOLOAD {
  my $fun = $AUTOLOAD;
  $fun =~ s/.*:://;
  
  my $self = shift;
  my $expr = $self->expr(); # the SQL string for this Expr
  $self->{type}->expr("$fun($expr)", $self->objects);
}

use overload
# BEGIN ks.perl@kurtstephens.com 2002/06/25
        '+'    => \&add,
        '-'    => \&subt,
        '*'    => \&mul,
        '/'    => \&div,
        'cos'  => \&cos, 
        'sin'  => \&sin,
#        'acos' => \&acos,
# END ks.perl@kurtstephens.com 2002/06/25
	"==" => \&eq,
	"eq" => \&eq,
	"!=" => \&ne,
	"ne" => \&ne,
	"<" => \&lt,
	"lt" => \&lt,
	"<=" => \&le,
	"le" => \&le,
	">" => \&gt,
	"gt" => \&gt,
	">=" => \&ge,
	"ge" => \&ge,
	"!"  => \&not,
	'""' => \&as_string,
	fallback => 1;

1;
