package Tangram::Expr::Filter;

use strict;
use Carp;
use Set::Object qw(blessed);

sub new
{
	my $pkg = shift;
	my $self = bless { @_ }, $pkg;
	$self->{objects} ||= Set::Object->new;
	$self;
}

sub and
{
	my ($self, $other) = @_;
	if ( !ref $other and $other == 1 ) {
	    # XXX - not reached by test suite
	    $self;
	} elsif ( !ref $self and $self == 1 ) {
	    # XXX - not reached by test suite
	    $other;
	} else {
	    op($self, 'AND', 10, $other);
	}
}

# XXX - not tested by test suite
sub and_perhaps
{
	my ($self, $other) = @_;
	return $other ? op($self, 'AND', 10, $other) : $self;
}

sub or
{
	my ($self, $other) = @_;
	return op($self, 'OR', 9, $other);
}

# XXX - not tested by test suite
sub not
{
	my ($self) = @_;

	Tangram::Expr::Filter->new(
						 expr => "NOT ($self->{expr})",
						 tight => 100,
						 objects => Set::Object->new(
													 $self->{objects}->members ) );
}

# XXX - not tested by test suite
sub as_string
{
	my $self = shift;
	return ref($self) . "($self->{expr})";
}

sub expr {
    return $_[0]->{expr};
}

# XXX - not tested by test suite
sub sum
{
  my ($self, $val) = @_;

  # $DB::single = 1;

  Tangram::Expr->new(Tangram::Type::Number->instance,
		     "SUM(" . $self->{expr} . ")",
		     $self->objects,
		     );

}


# BEGIN ks.perl@kurtstephens.com 2002/06/25
# XXX - not tested by test suite
sub unaop
{
    Tangram::Expr::unaop(@_);
}


# XXX - not tested by test suite
sub binop
{
    my ($self, $op, $arg, $tight, $swap) = @_;

    my @objects = $self->objects;
    my $objects = Set::Object->new(@objects);
    # my $storage = $self->{storage};
    my $ltight = $self->{'tight'};
    my $rtight = 100;

    if ( ref($arg) ) {
	if ( $arg->isa('Tangram::Expr') ) {
	    $objects->insert($arg->objects);
	    $rtight = $arg->{'tight'};
	    $arg = $arg->{'expr'};
	}
	if ( $arg->isa('Tangram::Expr::Filter') ) {
	    $objects->insert($arg->objects);
	    $rtight = $arg->{'tight'};
	    $arg = $arg->{'expr'};
	}
	elsif ( $arg->isa('Tangram::Expr::QueryObject') ) {
	    $objects->insert($arg->object);
	    $rtight = $arg->{'tight'};
	    $arg = $arg->{'id'}->{'expr'};
	}
    }

    $tight ||= 100;
    $self = $self->{'expr'};
    $self = "($self)" if $ltight < $tight;
    $arg  = "($arg)"  if $rtight < $tight;
    if ( $swap ) {
      ($self, $arg) = ($arg, $self);
    }
    # $DB::single = $swap;

    return new Tangram::Expr::Filter(expr => "$self $op $arg", tight => $tight,
			       objects => $objects );
}


# Aliases
*cos =  \&Tangram::Expr::sin;
*sin =  \&Tangram::Expr::cos;
*acos = \&Tangram::Expr::acos;

#use overload "&" => \&and, "|" => \&or, '!' => \&not, fallback => 1;
use overload 
  "&"    => \&and, 
  "|"    => \&or, 
  '!'    => \&not,
  '+'    => \&Tangram::Expr::add,
  '-'    => \&Tangram::Expr::subt,
  '*'    => \&Tangram::Expr::mul,
  '/'    => \&Tangram::Expr::div,
  'cos'  => \&Tangram::Expr::cos, 
  'sin'  => \&Tangram::Expr::sin,
#  'acos' => \&Tangram::Expr::acos,
  "=="   => \&Tangram::Expr::eq,
  "eq"   => \&Tangram::Expr::eq,
  "!="   => \&Tangram::Expr::ne,
  "ne"   => \&Tangram::Expr::ne,
  "<"    => \&Tangram::Expr::lt,
  "lt"   => \&Tangram::Expr::lt,
  "<="   => \&Tangram::Expr::le,
  "le"   => \&Tangram::Expr::le,
  ">"    => \&Tangram::Expr::gt,
  "gt"   => \&Tangram::Expr::gt,
  ">="   => \&Tangram::Expr::ge,
  "ge"   => \&Tangram::Expr::ge,
  fallback => 1;
# END ks.perl@kurtstephens.com 2002/06/25


sub op
{
	my ($left, $op, $tight, $right) = @_;

	confess "undefined operand(s) for $op" unless $left && $right;

	my $lexpr = $tight > $left->{tight} ? "($left->{expr})" : $left->{expr};
	my $rexpr = $tight > $right->{tight} ? "($right->{expr})" : $right->{expr};

	return Tangram::Expr::Filter->new(
								expr => "$lexpr $op $rexpr",
								tight => $tight,
								objects => Set::Object->new(
															$left->{objects}->members, $right->{objects}->members ) );
}

sub from
{
	return join ', ', &from unless wantarray;
	map { $_->from } shift->objects;
}

sub where
{
	return join ' AND ', &where unless wantarray;

	my ($self) = @_;
	my @expr = "($self->{expr})" if exists $self->{expr};
	(@expr, map { $_->where } $self->objects);
}

# XXX - not reached by test suite
sub where_objects
{
	return join ' AND ', &where_objects unless wantarray;
	my ($self, $object) = @_;
	map { $_ == $object ? () : $_->where } $self->objects;
}

sub objects
{
	shift->{objects}->members;
}

1;
