package Storm::SQL::Fragment::Where::Comparison;
{
  $Storm::SQL::Fragment::Where::Comparison::VERSION = '0.240';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

use MooseX::Types::Moose qw( ArrayRef Str );

use Storm::SQL::Parameter;
use Storm::SQL::Placeholder;

has '_left_arg' => (
    is => 'ro',
    required => 1,
);

has '_operator' => (
    is => 'ro' ,
    isa => Str,
    required => 1,
);

has '_right_args' => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
);

sub BUILDARGS
{
    my $class             = shift;
    my $lhs               = shift;
    my $operator          = shift;
    my @rhs               = @_;
    
    my @bind;
    
    return {
        _left_arg     => $lhs,
        _operator     => $operator,
        _right_args   => \@rhs,
    };
}

sub sql  {
    my $self = shift;
    my $sql = '';
    
    # standard operators = != < <= => >
    if ($self->_operator =~ /^(?:([!<>]?=)|<|>)$/){
        $sql .= $self->_left_arg->sql;
        
        # handle null checks
        if (! defined $self->_right_args->[0]) {
            $sql .= $self->_operator eq '=' ? ' IS NULL' : ' IS NOT NULL';
        }
        else {
            $sql .= ' ' . $self->_operator;
            $sql .= ' ' . $self->_right_args->[0]->sql;
        }
    }
    elsif ($self->_operator eq 'between') {
        $sql .= $self->_left_arg->sql;
        $sql .= ' BETWEEN ';
        $sql .= $self->_right_args->[0]->sql;
        $sql .= ' AND ';
        $sql .= $self->_right_args->[1]->sql;
    }
    elsif ($self->_operator eq 'not_between') {
        $sql .= $self->_left_arg->sql;
        $sql .= ' NOT BETWEEN ';
        $sql .= $self->_right_args->[0]->sql;
        $sql .= ' AND ';
        $sql .= $self->_right_args->[1]->sql;
    }
    elsif ($self->_operator eq 'like') {
        $sql .= $self->_left_arg->sql;
        $sql .= ' LIKE ';
        $sql .= $self->_right_args->[0]->sql;
    }
    elsif ($self->_operator =~ /^not(_| )like$/) {
        $sql .= $self->_left_arg->sql;
        $sql .= ' NOT LIKE ';
        $sql .= $self->_right_args->[0]->sql;
    }
    elsif ($self->_operator eq 'in') {
        $sql .= $self->_left_arg->sql;
        $sql .= ' IN (';
        $sql .= join q[, ], map {$_->sql} @{$self->_right_args};
        $sql .= ')';
    }
    elsif ($self->_operator =~ /^not(_| )in$/) {
        $sql .= $self->_left_arg->sql;
        $sql .= ' NOT IN (';
        $sql .= join q[, ], map {$_->sql} @{$self->_right_args};
        $sql .= ')';
    }
    else {
        use Carp qw(cluck);
        confess 'could not generate sql for this operator ' . $self->_operator .
              ': no implementation';
    }

    return $sql;
}

sub bind_params {
    my $self = shift;
    return
        ( map { $_->bind_params() } grep { defined $_ && $_->can('bind_params') } $self->_left_arg, @{$self->_right_args}
        );
}


no Moose;
__PACKAGE__->meta()->make_immutable();
1;
